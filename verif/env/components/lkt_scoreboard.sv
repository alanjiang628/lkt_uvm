`ifndef __LKT_SCOREBOARD_SV__
`define __LKT_SCOREBOARD_SV__

class lkt_scoreboard extends uvm_scoreboard;
    uvm_analysis_imp #(lkt_transaction, lkt_scoreboard) mon_imp;
    `uvm_component_utils(lkt_scoreboard)

    lkt_config cfg;
    int error_count = 0;
    int pass_count = 0;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        mon_imp = new("mon_imp", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(lkt_config)::get(this, "", "config", cfg))
            `uvm_fatal("CONFIG", "Cannot get config object in scoreboard")
    endfunction

    function void write(lkt_transaction tr);
        // Declare local variables as dynamic arrays
        logic expected_output[];
        logic choice_vector[];
        logic lookup_result[];
        logic transposed_lut[]; // Moved declaration to function scope

        // Size the local dynamic arrays based on the scoreboard's config object
        expected_output = new[cfg.RESULT_WIDTH * cfg.NUM_LOOKUPS];
        choice_vector   = new[cfg.NUM_CHOICES];
        lookup_result   = new[cfg.RESULT_WIDTH];
        transposed_lut  = new[cfg.RESULT_WIDTH * cfg.NUM_CHOICES]; // Size it once

        // Reference Model
        for (int i = 0; i < cfg.NUM_LOOKUPS; i++) begin
            // Manually extract the choice vector for this lookup
            for (int k = 0; k < cfg.NUM_CHOICES; k++) begin
                choice_vector[k] = tr.input_i[i * cfg.NUM_CHOICES + k];
            end
            
            // --- New Reference Model to match RTL ---
            // The RTL transposes the lookup table. We mimic that using a 1D dynamic array
            // with manual 2D indexing to ensure maximum simulator compatibility.
            for (int h=0; h<cfg.RESULT_WIDTH; h=h+1) begin
                for (int g=0; g<cfg.NUM_CHOICES; g=g+1) begin
                    int index_1d = h * cfg.NUM_CHOICES + g;
                    int index_tr = i*cfg.NUM_CHOICES*cfg.RESULT_WIDTH + g*cfg.RESULT_WIDTH + h;
                    transposed_lut[index_1d] = tr.lookup_table_i[index_tr];
                end
            end

            // Now, calculate the result for each bit of the output, mimicking the RTL's OR-reduction
            for (int h=0; h<cfg.RESULT_WIDTH; h=h+1) begin
                logic temp_bit = 0;
                for (int k=0; k<cfg.NUM_CHOICES; k++) begin
                    int index_1d = h * cfg.NUM_CHOICES + k;
                    temp_bit = temp_bit | (transposed_lut[index_1d] & choice_vector[k]);
                end
                lookup_result[h] = temp_bit;
            end
            // --- End of New Reference Model ---
            
            // Manually place the result into the expected_output array
            for (int k = 0; k < cfg.RESULT_WIDTH; k++) begin
                expected_output[i * cfg.RESULT_WIDTH + k] = lookup_result[k];
            end
        end

        // Comparison
        if (tr.output_o.size() != expected_output.size() || tr.output_o != expected_output) begin
            `uvm_error("SCOREBOARD_ERR", $sformatf("Output mismatch!\n\tInput: %p\n\tExpected: %p\n\tActual: %p",
                                                 tr.input_i, expected_output, tr.output_o))
            error_count++;
        end else begin
            `uvm_info("SCOREBOARD_PASS", "Output match!", UVM_LOW)
            pass_count++;
        end

    endfunction

endclass

`endif
