bind fifo fifo_sva #(
    .DATA_W (DATA_W),
    .DEPTH  (DEPTH)
) u_fifo_sva (
    .clk     (clk),
    .rst_n   (rst_n),
    .wr_en   (wr_en),
    .rd_en   (rd_en),
    .wr_data (wr_data),
    .rd_data (rd_data),
    .full    (full),
    .empty   (empty),
    .count   (count)
);
