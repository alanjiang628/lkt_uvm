`ifndef __LK_TABLE_FUNC_NO_CHOICE_SEQ_SV__
`define __LK_TABLE_FUNC_NO_CHOICE_SEQ_SV__

class lk_table_func_no_choice_seq extends base_sequence;
    `uvm_object_utils(lk_table_func_no_choice_seq)

    function new(string name = "lk_table_func_no_choice_seq");
        super.new(name);
    endfunction

    task body();
        req = lkt_transaction::type_id::create("req");
        start_item(req); // This calls pre_body, which gets the cfg object
        
        // Allocate memory for dynamic arrays now that cfg is available
        req.lookup_table_i = new[cfg.NUM_LOOKUPS * cfg.RESULT_WIDTH];
        req.input_i        = new[cfg.NUM_LOOKUPS * cfg.NUM_CHOICES];

        // Randomize with constraints
        if (!req.randomize() with {
            foreach (input_i[i]) input_i[i] == 0;
        }) begin
            `uvm_error("RAND_FAIL", "Transaction randomization failed")
        end
        
        finish_item(req);
    endtask

endclass

`endif
