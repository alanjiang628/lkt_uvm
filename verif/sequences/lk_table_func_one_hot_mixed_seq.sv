`ifndef __LK_TABLE_FUNC_ONE_HOT_MIXED_SEQ_SV__
`define __LK_TABLE_FUNC_ONE_HOT_MIXED_SEQ_SV__

class lk_table_func_one_hot_mixed_seq extends base_sequence;
    `uvm_object_utils(lk_table_func_one_hot_mixed_seq)

    // Random variables to control the mix
    rand bit [31:0] lookup_selector_type[]; // 0 = all-zero, 1 = one-hot
    rand int unsigned choice_index[];       // which choice to select for one-hot items

    function new(string name = "lk_table_func_one_hot_mixed_seq");
        super.new(name);
    endfunction

    task body();
        req = lkt_transaction::type_id::create("req");
        start_item(req); // This calls pre_body, which gets the cfg object
        
        // Allocate dynamic arrays now that cfg is available
        req.input_i = new[cfg.NUM_LOOKUPS * cfg.NUM_CHOICES];
        req.lookup_table_i = new[cfg.NUM_LOOKUPS * cfg.NUM_CHOICES * cfg.RESULT_WIDTH];
        req.output_o = new[cfg.NUM_LOOKUPS * cfg.RESULT_WIDTH];

        // Allocate and randomize control arrays
        lookup_selector_type = new[cfg.NUM_LOOKUPS];
        choice_index = new[cfg.NUM_LOOKUPS];
        
        // Randomize the transaction first
        assert(req.randomize());
        
        // Randomize our control variables
        assert(this.randomize());

        // Post-randomization: manually set the mixed pattern
        for (int i = 0; i < cfg.NUM_LOOKUPS; i++) begin
            int base_idx = i * cfg.NUM_CHOICES;
            
            if (lookup_selector_type[i] == 0) begin
                // All-zero selector for this lookup item
                for (int j = 0; j < cfg.NUM_CHOICES; j++) begin
                    req.input_i[base_idx + j] = 0;
                end
            end else begin
                // One-hot selector for this lookup item
                for (int j = 0; j < cfg.NUM_CHOICES; j++) begin
                    req.input_i[base_idx + j] = (j == choice_index[i]);
                end
            end
        end
        
        finish_item(req);
    endtask

    // Constraints to ensure a good mix of selector types
    constraint c_selector_mix {
        // Ensure we have at least one of each type if we have enough lookups
        if (cfg.NUM_LOOKUPS >= 2) {
            lookup_selector_type.sum() > 0;           // At least one one-hot
            lookup_selector_type.sum() < cfg.NUM_LOOKUPS; // At least one all-zero
        }
        
        // Valid choice indices
        foreach (choice_index[i]) {
            choice_index[i] < cfg.NUM_CHOICES;
        }
    }

endclass

`endif
