`ifndef __LKT_COVERAGE_SV__
`define __LKT_COVERAGE_SV__

class lkt_coverage extends uvm_subscriber #(lkt_transaction);
    `uvm_component_utils(lkt_coverage)

    // Configuration object
    lkt_config cfg;

    // Covergroup to sample transaction properties
    covergroup lkt_transaction_cg(int lookup_idx, int choice_vec);
        option.per_instance = 1;
        
        // cp_all_choices_per_lookup
        cp_choice: coverpoint choice_vec {
            bins choices[] = {[0:$]};
        }

        // cp_sel_all_zero, cp_illegal_multi_hot
        cp_selection_type: coverpoint $countones(choice_vec) {
            bins zero_hot  = {0};
            bins one_hot   = {1};
            bins multi_hot = {2,3}; // Assuming max 2 choices for simplicity
        }
    endgroup

    // An array of covergroups, one for each lookup item
    lkt_transaction_cg cgs[];

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(lkt_config)::get(this, "", "config", cfg))
            `uvm_fatal("CONFIG", "Cannot get config object")
        
        // Create an instance of the covergroup for each lookup
        cgs = new[cfg.NUM_LOOKUPS];
        foreach(cgs[i]) begin
            cgs[i] = new(i, 0);
        end
    endfunction

    function void write(lkt_transaction t);
        for (int i = 0; i < cfg.NUM_LOOKUPS; i++) begin
            logic [cfg.NUM_CHOICES-1:0] slice;
            for (int j = 0; j < cfg.NUM_CHOICES; j++) begin
                slice[j] = t.input_i[i*cfg.NUM_CHOICES + j];
            end
            cgs[i].sample(i, slice);
        end
    endfunction

endclass

`endif
