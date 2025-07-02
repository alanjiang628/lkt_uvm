`ifndef __LK_TABLE_FUNC_NO_CHOICE_SEQ_SV__
`define __LK_TABLE_FUNC_NO_CHOICE_SEQ_SV__

class lk_table_func_no_choice_seq extends base_sequence;
    `uvm_object_utils(lk_table_func_no_choice_seq)

    function new(string name = "lk_table_func_no_choice_seq");
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

        // Randomize the lookup table first
        assert(req.randomize() with { input_i.size() == 0; }); // Avoid randomizing input_i yet

        // Set input_i to all zeros
        foreach (req.input_i[i]) begin
            req.input_i[i] = 0;
        end
        
        finish_item(req);
    endtask

endclass

`endif
