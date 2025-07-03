`ifndef __LK_TABLE_FUNC_RANDOMIZED_SEQ_SV__
`define __LK_TABLE_FUNC_RANDOMIZED_SEQ_SV__

class lk_table_func_randomized_seq extends base_sequence;
    `uvm_object_utils(lk_table_func_randomized_seq)

    function new(string name = "lk_table_func_randomized_seq");
        super.new(name);
    endfunction

    task body();
        req = lkt_transaction::type_id::create("req");
        start_item(req); // This calls pre_body, which gets the cfg object
        
        // Allocate memory for dynamic arrays now that cfg is available
        req.input_i = new[cfg.NUM_LOOKUPS * cfg.NUM_CHOICES];
        req.lookup_table_i = new[cfg.NUM_LOOKUPS * cfg.NUM_CHOICES * cfg.RESULT_WIDTH];
        req.output_o = new[cfg.NUM_LOOKUPS * cfg.RESULT_WIDTH];

        // Now that memory is allocated, we can randomize.
        if (!req.randomize()) begin
            `uvm_error("RAND_FAIL", "Transaction randomization failed")
        end
        
        finish_item(req);
    endtask

endclass

`endif
