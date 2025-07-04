`ifndef __LKT_TRANSACTION_SV__
`define __LKT_TRANSACTION_SV__

class lkt_transaction extends uvm_sequence_item;
    `uvm_object_utils(lkt_transaction)

    // --- Data Fields ---
    // These are dynamic arrays. The sequence that creates this transaction
    // is responsible for sizing them before randomization.
    rand logic lookup_table_i[];
    rand logic input_i[];
    logic output_o[];

    function new(string name = "lkt_transaction");
        super.new(name);
    endfunction

endclass

`endif
