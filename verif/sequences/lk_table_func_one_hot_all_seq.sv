`ifndef __LK_TABLE_FUNC_ONE_HOT_ALL_SEQ_SV__
`define __LK_TABLE_FUNC_ONE_HOT_ALL_SEQ_SV__

class lk_table_func_one_hot_all_seq extends base_sequence;
    `uvm_object_utils(lk_table_func_one_hot_all_seq)

    rand int unsigned choice_index; // 0 for first, -1 for last

    function new(string name = "lk_table_func_one_hot_all_seq");
        super.new(name);
    endfunction

    task body();
        // Declare all local variables at the top of the task
        lkt_config cfg;
        int final_choice_index;

        // 1. Get config from sequencer to know DUT dimensions
        if(!uvm_config_db#(lkt_config)::get(m_sequencer, "", "config", cfg))
           `uvm_fatal("SEQ_CFG_ERR", "Could not get config object in sequence")

        // 2. Create and size the transaction object
        req = lkt_transaction::type_id::create("req");
        start_item(req);
        
        req.RESULT_WIDTH = cfg.RESULT_WIDTH;
        req.NUM_LOOKUPS  = cfg.NUM_LOOKUPS;
        req.NUM_CHOICES  = cfg.NUM_CHOICES;

        req.lookup_table_i = new[cfg.RESULT_WIDTH * cfg.NUM_LOOKUPS * cfg.NUM_CHOICES];
        req.input_i        = new[cfg.NUM_LOOKUPS * cfg.NUM_CHOICES];
        req.output_o       = new[cfg.RESULT_WIDTH * cfg.NUM_LOOKUPS];

        // 3. Randomize the transaction (lookup_table_i will be random)
        assert(req.randomize());

        // 4. Manually construct the specific input_i pattern for this test
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
