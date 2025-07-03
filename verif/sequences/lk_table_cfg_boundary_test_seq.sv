`ifndef __LK_TABLE_CFG_BOUNDARY_TEST_SEQ_SV__
`define __LK_TABLE_CFG_BOUNDARY_TEST_SEQ_SV__

class lk_table_cfg_boundary_test_seq extends base_sequence;
    `uvm_object_utils(lk_table_cfg_boundary_test_seq)

    function new(string name = "lk_table_cfg_boundary_test_seq");
        super.new(name);
    endfunction

    virtual task body();
        // The base sequence now handles config lookup and memory allocation.
        // We can directly create and randomize the transaction.
        `uvm_do(req)
    endtask

endclass

`endif
