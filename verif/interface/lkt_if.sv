`ifndef __LKT_IF_SV__
`define __LKT_IF_SV__

interface lkt_if (input bit clk, input bit rst_n);

    parameter RESULT_WIDTH = 3;
    parameter NUM_LOOKUPS  = 8;
    parameter NUM_CHOICES  = 2;

    logic [NUM_LOOKUPS * NUM_CHOICES * RESULT_WIDTH - 1 : 0] lookup_table_i;
    logic [NUM_LOOKUPS * NUM_CHOICES - 1 : 0]                input_i;
    logic [RESULT_WIDTH * NUM_LOOKUPS - 1 : 0]                   output_o;

    clocking drv_cb @(posedge clk);
        default input #1step output #1;
        output lookup_table_i;
        output input_i;
    endclocking

    clocking mon_cb @(posedge clk);
        default input #1step output #1;
        input lookup_table_i;
        input input_i;
        input output_o;
    endclocking

    modport tb (clocking drv_cb, input clk, input rst_n);
    modport dut (input clk, input rst_n, input lookup_table_i, input input_i, output output_o);

endinterface

`endif
