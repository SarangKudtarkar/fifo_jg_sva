module fifo_sva #(
    parameter DATA_W = 8,
    parameter DEPTH  = 8,
    parameter CNT_W  = $clog2(DEPTH+1)
)(
    input logic              clk,
    input logic              rst_n,
    input logic              wr_en,
    input logic              rd_en,
    input logic [DATA_W-1:0] wr_data,
    input logic [DATA_W-1:0] rd_data,
    input logic              full,
    input logic              empty,
    input logic [CNT_W-1:0]  count
);

    default clocking cb @(posedge clk); endclocking
    default disable iff (!rst_n);

    // ----------------------------------------------
    // Helper signals
    // ----------------------------------------------
    logic write_accept;
    logic read_accept;

    assign write_accept = wr_en && !full;
    assign read_accept  = rd_en && !empty;

    // ----------------------------------------------
    // Structural / flag properties
    // ----------------------------------------------
    a_not_full_and_empty: assert property (!(full && empty));

    a_count_range:        assert property (count <= DEPTH);

    a_full_def:           assert property (full  == (count == DEPTH));
    a_empty_def:          assert property (empty == (count == 0));

    a_count_inc: assert property (
        write_accept && !read_accept |=> count == $past(count) + 1'b1
    );

    a_count_dec: assert property (
        !write_accept && read_accept |=> count == $past(count) - 1'b1
    );

    a_count_hold: assert property (
        (write_accept == read_accept) |=> $stable(count)
    );

    // No overflow / underflow
    a_no_overflow: assert property (
        full && wr_en && !rd_en |=> $stable(count)
    );

    a_no_underflow: assert property (
        empty && rd_en && !wr_en |=> $stable(count)
    );

    // rd_data only changes on an accepted read
    a_rd_data_hold: assert property (
        !read_accept |=> $stable(rd_data)
    );

    // ----------------------------------------------
    // Data integrity / ordering scoreboard
    //
    // sym_data is a free (undriven) signal, which JasperGold treats as
    // a primary input. The $stable assume makes it a symbolic constant.
    // We track the FIRST write of sym_data and count how many entries
    // are ahead of it. When it reaches the head and is read, the
    // registered rd_data must equal sym_data on the next cycle.
    // This covers both data integrity and FIFO order for any value.
    // ----------------------------------------------
    logic [DATA_W-1:0] sym_data;

    m_sym_data_stable: assume property ($stable(sym_data));

    logic              tracking;
    logic              done;
    logic [CNT_W-1:0]  ahead;

    logic tag_push;
    logic tag_pop;

    assign tag_push = write_accept && (wr_data == sym_data) && !tracking && !done;
    assign tag_pop  = tracking && read_accept && (ahead == '0);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tracking <= 1'b0;
            done     <= 1'b0;
            ahead    <= '0;
        end
        else if (tag_push) begin
            tracking <= 1'b1;
            // entries ahead of the tagged one; a simultaneous read removes one
            ahead    <= count - read_accept;
        end
        else if (tracking && read_accept) begin
            if (ahead == '0) begin
                tracking <= 1'b0;
                done     <= 1'b1;
            end
            else begin
                ahead <= ahead - 1'b1;
            end
        end
    end

    // Helper invariant (aids convergence): tagged entry is inside the FIFO
    a_tracking_ahead_lt_count: assert property (
        tracking |-> (ahead < count)
    );

    // The tagged value comes out in order, one cycle after the read
    a_fifo_data_order: assert property (
        tag_pop |=> (rd_data == sym_data)
    );

    // ----------------------------------------------
    // Cover properties (reachability / vacuity checks)
    // ----------------------------------------------
    c_full:            cover property (full);
    c_empty:           cover property (empty);
    c_write_when_full: cover property (wr_en && full);
    c_read_when_empty: cover property (rd_en && empty);
    c_simul_rd_wr:     cover property (write_accept && read_accept);
    c_tag_pushed:      cover property (tag_push);
    c_tag_popped:      cover property (tag_pop);
    c_tag_popped_deep: cover property (tag_push ##1 tracking [*1:$] ##0 tag_pop);

endmodule
