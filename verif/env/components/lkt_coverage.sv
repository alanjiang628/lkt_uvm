`ifndef __LKT_COVERAGE_SV__
`define __LKT_COVERAGE_SV__

class lkt_coverage extends uvm_subscriber #(lkt_transaction);
    `uvm_component_utils(lkt_coverage)

    // Configuration object
    lkt_config cfg;

    // --- Covergroup Definition and Instantiation ---
    covergroup cg;
        option.per_instance = 1;
        
        // Coverpoint for the lookup index itself
        cp_lookup_index: coverpoint lookup_idx;

        // Coverpoint for the value of the choice vector
        cp_choice_value: coverpoint choice_vec;

        // Coverpoint for the type of selection (zero, one, multi-hot)
        cp_selection_type: coverpoint selection_type;

        // Cross coverage to ensure every choice is covered for every lookup
        cross_all_choices: cross cp_lookup_index, cp_choice_value;
    endgroup

    // Variables to be sampled
    int lookup_idx;
    int choice_vec;
    int selection_type;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        cg = new();
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(lkt_config)::get(this, "", "config", cfg))
            `uvm_fatal("CONFIG", "Cannot get config object")
        
        // Configure the covergroup options now that 'cfg' is valid.
        // Note: This may cause warnings but is necessary as cfg is not available in new()
        cg.cp_lookup_index.option.auto_bin_max = cfg.NUM_LOOKUPS;
        cg.cp_choice_value.option.auto_bin_max = (1 << cfg.NUM_CHOICES);
    endfunction

    function void write(lkt_transaction t);
        // Loop through each lookup item in the transaction
        for (int i = 0; i < cfg.NUM_LOOKUPS; i++) begin
            int slice_value = 0;
            int ones_count = 0;
            
            // Extract the choice vector for the current lookup item
            for (int j = 0; j < cfg.NUM_CHOICES; j++) begin
                if (t.input_i[i*cfg.NUM_CHOICES + j]) begin
                    slice_value |= (1 << j);
                    ones_count++;
                end
            end
            
            // Assign to sampling variables
            this.lookup_idx = i;
            this.choice_vec = slice_value;
            this.selection_type = ones_count;

            // Sample the covergroup
            cg.sample();
        end
    endfunction

endclass

`endif
