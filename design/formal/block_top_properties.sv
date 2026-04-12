module block_top_formal;
  logic        clk_i;
  logic        rst_ni;
  logic [7:0]  data_i;
  logic        valid_i;
  logic [7:0]  data_o;
  logic        ready_o;

  block_top dut (
    .clk_i   (clk_i),
    .rst_ni  (rst_ni),
    .data_i  (data_i),
    .valid_i (valid_i),
    .data_o  (data_o),
    .ready_o (ready_o)
  );

  default clocking cb @(posedge clk_i); endclocking

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      assert (ready_o == 1'b0);
    end else begin
      assert (ready_o == valid_i);
    end
  end
endmodule

