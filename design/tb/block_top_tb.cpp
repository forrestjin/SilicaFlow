#include "Vblock_top.h"
#include "verilated.h"

static void tick(Vblock_top& dut) {
  dut.clk_i = 0;
  dut.eval();
  dut.clk_i = 1;
  dut.eval();
}

int main(int argc, char** argv) {
  Verilated::commandArgs(argc, argv);
  Vblock_top dut;

  dut.rst_ni = 0;
  dut.valid_i = 0;
  dut.data_i = 0;
  tick(dut);

  dut.rst_ni = 1;
  dut.valid_i = 1;
  dut.data_i = 0x10;
  tick(dut);

  if (dut.ready_o != 1 || dut.data_o != 0x11) {
    return 1;
  }

  dut.valid_i = 0;
  tick(dut);
  return 0;
}

