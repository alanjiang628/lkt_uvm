// Author         : stephenl.wang
// Created On     : 2025-06-04 10:22
// Last Modified  : 2025/06/09 15:40
//-------------------------------------------------------------------
module zh_1hot_lookup_table(
  lookup_table_i,input_i,output_o);

  parameter RESULT_WIDTH = 3;
  parameter NUM_LOOKUPS = 8;
  parameter NUM_CHOICES = 2;

  input logic [NUM_LOOKUPS*NUM_CHOICES*RESULT_WIDTH-1:0] lookup_table_i;
  input logic [NUM_LOOKUPS*NUM_CHOICES-1:0] input_i;
  output logic [RESULT_WIDTH*NUM_LOOKUPS-1:0] output_o;

  genvar f;
  genvar g;
  genvar h;
  logic [RESULT_WIDTH*NUM_LOOKUPS-1:0] output_nxt;

  generate
    for (f=0; f<NUM_LOOKUPS; f=f+1)
    begin : g_per_lookup
      logic [NUM_CHOICES-1:0] lookup_table_t [RESULT_WIDTH-1:0];
      for (g=0; g<NUM_CHOICES; g=g+1)
      begin : g_lookup_table_region_transpose
        for (h=0; h<RESULT_WIDTH; h=h+1)
        begin : g_lookup_table_region_result_transpose
          assign lookup_table_t[h][g] = lookup_table_i[f*NUM_CHOICES*RESULT_WIDTH+g*RESULT_WIDTH+h];
        end
      end

      for (h=0; h<RESULT_WIDTH; h=h+1)
      begin : g_output_nxt
        assign output_nxt[(f*RESULT_WIDTH)+h] = |(lookup_table_t[h] & input_i[(f+1)*NUM_CHOICES-1:f*NUM_CHOICES]);
      end
    end
  endgenerate

  assign output_o = output_nxt;

`ifdef BLNC_ASSERTION_ON
  `include "zh_1hot_lookup_table_sva.sv"
`endif

endmodule
