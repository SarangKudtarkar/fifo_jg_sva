module fifo #(
    parameter DATA_W = 8,
    parameter DEPTH  = 8,
    parameter PTR_W  = $clog2(DEPTH),
    parameter CNT_W  = $clog2(DEPTH+1)
)(
    input  logic              clk,
    input  logic              rst_n,
    input  logic              wr_en,
    input  logic              rd_en,
    input  logic [DATA_W-1:0] wr_data,
    output logic [DATA_W-1:0] rd_data,
    output logic              full,
    output logic              empty
);

    logic [DATA_W-1:0] mem [0:DEPTH-1];

    logic [PTR_W-1:0] wr_ptr;
    logic [PTR_W-1:0] rd_ptr;
    logic [CNT_W-1:0] count;

    logic write_accept;
    logic read_accept;

    assign full  = (count == DEPTH);
    assign empty = (count == 0);

    assign write_accept = wr_en && !full;
    assign read_accept  = rd_en && !empty;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr  <= '0;
            rd_ptr  <= '0;
            count   <= '0;
            rd_data <= '0;
        end
        else begin

            if (write_accept) begin
                mem[wr_ptr] <= wr_data;

                if (wr_ptr == DEPTH-1)
                    wr_ptr <= '0;
                else
                    wr_ptr <= wr_ptr + 1'b1;
            end

            if (read_accept) begin
                rd_data <= mem[rd_ptr];

                if (rd_ptr == DEPTH-1)
                    rd_ptr <= '0;
                else
                    rd_ptr <= rd_ptr + 1'b1;
            end

            case ({write_accept, read_accept})
                2'b10: count <= count + 1'b1;
                2'b01: count <= count - 1'b1;
                default: count <= count;
            endcase

        end
    end

endmodule
