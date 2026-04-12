module block_top (
  input  logic        clk_i,
  input  logic        rst_ni,
  input  logic [7:0]  data_i,
  input  logic        valid_i,
  output logic [7:0]  data_o,
  output logic        ready_o
);

  logic [7:0] data_q;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      data_q  <= '0;
      ready_o <= 1'b0;
    end else begin
      ready_o <= valid_i;
      if (valid_i) begin
        data_q <= data_i + 8'h01;
      end
    end
  end

  assign data_o = data_q;

endmodule

