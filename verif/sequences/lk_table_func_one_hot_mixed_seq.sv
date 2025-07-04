`ifndef __LK_TABLE_FUNC_ONE_HOT_MIXED_SEQ_SV__
`define __LK_TABLE_FUNC_ONE_HOT_MIXED_SEQ_SV__

class lk_table_func_one_hot_mixed_seq extends base_sequence;
    `uvm_object_utils(lk_table_func_one_hot_mixed_seq)

    // Controls how many lookup items will have an all-zero selector
    rand int unsigned num_zero_selectors;
    
    // Intermediate array to simplify constraints. 1 means all-zero, 0 means one-hot.
    rand bit is_zero_selector[];

    function new(string name = "lk_table_func_one_hot_mixed_seq");
        super.new(name);
    endfunction

    task body();
        int num_lookups;
        int num_choices;
        int result_width;

        req = lkt_transaction::type_id::create("req");
        start_item(req); // This calls pre_body, which gets the cfg object
        
        // Copy config values to local variables to avoid potential scope issues with the solver.
        num_lookups  = cfg.NUM_LOOKUPS;
        num_choices  = cfg.NUM_CHOICES;
        result_width = cfg.RESULT_WIDTH;

        // Randomize the sequence's control knobs using the local config variables.
        // This is done inside the body task to resolve the run-time dependency on cfg.
        if (!std::randomize(num_zero_selectors, is_zero_selector) with {
            num_zero_selectors > 0;
            num_zero_selectors < num_lookups;
            is_zero_selector.size() == num_lookups;
            is_zero_selector.sum()  == num_zero_selectors;
        }) `uvm_fatal(get_name(), "Failed to randomize sequence controls")

        // Manually size the transaction's dynamic arrays using the local variables.
        req.lookup_table_i = new[num_lookups * result_width];
        req.input_i        = new[num_lookups * num_choices];

        // Randomize the transaction first to get values for other fields like lookup_table_i.
        // We will overwrite input_i procedurally, so we don't constrain it here.
        if (!req.randomize()) `uvm_fatal(get_name(), "Initial transaction randomization failed")

        // Now, procedurally construct the input_i vector based on is_zero_selector,
        // bypassing the constraint solver for this complex part.
        foreach (is_zero_selector[k]) begin
            int base_idx = k * num_choices;
            if (is_zero_selector[k] == 1) begin // All-zero case
                for (int j = 0; j < num_choices; j++) begin
                    req.input_i[base_idx + j] = 1'b0;
                end
            end else begin // One-hot case
                int one_hot_pos;
                // Clear the slice first
                for (int j = 0; j < num_choices; j++) begin
                    req.input_i[base_idx + j] = 1'b0;
                end
                // Pick a random position to set the '1'
                one_hot_pos = $urandom_range(0, num_choices - 1);
                req.input_i[base_idx + one_hot_pos] = 1'b1;
            end
        end
        
        finish_item(req);
    endtask

endclass

`endif
