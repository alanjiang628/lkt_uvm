`ifndef __LKT_SCOREBOARD_SV__
`define __LKT_SCOREBOARD_SV__

class lkt_scoreboard extends uvm_scoreboard;
    uvm_analysis_imp #(lkt_transaction, lkt_scoreboard) mon_imp;
    `uvm_component_utils(lkt_scoreboard)

    int error_count = 0;
    int pass_count = 0;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        mon_imp = new("mon_imp", this);
    endfunction

    function void write(lkt_transaction tr);
        // Declare local variables as dynamic arrays
        logic expected_output[];
        logic choice_vector[];
        logic lookup_result[];

        // Size the local dynamic arrays based on the incoming transaction
        expected_output = new[tr.RESULT_WIDTH * tr.NUM_LOOKUPS];
        choice_vector   = new[tr.NUM_CHOICES];
        lookup_result   = new[tr.RESULT_WIDTH];

        // Reference Model
        for (int i = 0; i < tr.NUM_LOOKUPS; i++) begin
            // Manually extract the choice vector for this lookup
            for (int k = 0; k < tr.NUM_CHOICES; k++) begin
                choice_vector[k] = tr.input_i[i * tr.NUM_CHOICES + k];
            end
            
            // Default result is 0
            for (int k = 0; k < tr.RESULT_WIDTH; k++) begin
                lookup_result[k] = 0;
            end

            if ($countones(choice_vector) == 1) begin
                for (int j = 0; j < tr.NUM_CHOICES; j++) begin
                    if (choice_vector[j] == 1'b1) begin
                        int start_idx = (i * tr.NUM_CHOICES + j) * tr.RESULT_WIDTH;
                        // Manually extract the lookup result
                        for (int k = 0; k < tr.RESULT_WIDTH; k++) begin
                            lookup_result[k] = tr.lookup_table_i[start_idx + k];
                        end
                        break;
                    end
                end
            end
            
            // Manually place the result into the expected_output array
            for (int k = 0; k < tr.RESULT_WIDTH; k++) begin
                expected_output[i * tr.RESULT_WIDTH + k] = lookup_result[k];
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
