`ifndef __LK_TABLE_FUNC_ONE_HOT_ALL_SEQ_SV__
`define __LK_TABLE_FUNC_ONE_HOT_ALL_SEQ_SV__

class lk_table_func_one_hot_all_seq extends base_sequence;
    `uvm_object_utils(lk_table_func_one_hot_all_seq)

    rand int unsigned choice_index; // 0 for first, -1 for last

    function new(string name = "lk_table_func_one_hot_all_seq");
        super.new(name);
    endfunction

    task body();
        int final_choice_index;

        req = lkt_transaction::type_id::create("req");
        start_item(req); // This calls pre_body, which gets the cfg object
        
        // Allocate memory for dynamic arrays now that cfg is available
        req.input_i = new[cfg.NUM_LOOKUPS * cfg.NUM_CHOICES];
        req.lookup_table_i = new[cfg.NUM_LOOKUPS * cfg.NUM_CHOICES * cfg.RESULT_WIDTH];
        req.output_o = new[cfg.NUM_LOOKUPS * cfg.RESULT_WIDTH];

        // Randomize the transaction first
        assert(req.randomize());

        // Post-randomization: manually set the one-hot pattern
        final_choice_index = (choice_index == -1) ? (cfg.NUM_CHOICES - 1) : choice_index;
        for (int i = 0; i < cfg.NUM_LOOKUPS; i++) begin
            int base_idx = i * cfg.NUM_CHOICES;
            for (int j = 0; j < cfg.NUM_CHOICES; j++) begin
                req.input_i[base_idx + j] = (j == final_choice_index);
            end
        end
        
        finish_item(req);
    endtask

    constraint c_choice_index {
        choice_index inside {0, -1}; // 0 or last
    }

endclass

`endif
