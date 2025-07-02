`ifndef __LK_TABLE_FUNC_RANDOMIZED_SEQ_SV__
`define __LK_TABLE_FUNC_RANDOMIZED_SEQ_SV__

class lk_table_func_randomized_seq extends base_sequence;
    `uvm_object_utils(lk_table_func_randomized_seq)

    function new(string name = "lk_table_func_randomized_seq");
        super.new(name);
    endfunction

    task body();
        lkt_config cfg;
        if(!uvm_config_db#(lkt_config)::get(m_sequencer, "", "config", cfg))
           `uvm_fatal("SEQ_CFG_ERR", "Could not get config object in sequence")

        req = lkt_transaction::type_id::create("req");
        start_item(req);
        
        req.RESULT_WIDTH = cfg.RESULT_WIDTH;
        req.NUM_LOOKUPS  = cfg.NUM_LOOKUPS;
        req.NUM_CHOICES  = cfg.NUM_CHOICES;

        req.lookup_table_i = new[cfg.RESULT_WIDTH * cfg.NUM_LOOKUPS * cfg.NUM_CHOICES];
        req.input_i        = new[cfg.NUM_LOOKUPS * cfg.NUM_CHOICES];
        req.output_o       = new[cfg.RESULT_WIDTH * cfg.NUM_LOOKUPS];

        // Now that arrays are sized, we can randomize.
        // The post_randomize hook will ensure input_i is valid.
        assert(req.randomize());
        
        finish_item(req);
    endtask

endclass

`endif
