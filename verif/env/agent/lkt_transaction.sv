`ifndef __LKT_TRANSACTION_SV__
`define __LKT_TRANSACTION_SV__

class lkt_transaction extends uvm_sequence_item;
    `uvm_object_utils(lkt_transaction)

    // --- Data Fields ---
    // The transaction is a pure data container.
    // It has no knowledge of the environment's configuration.
    rand logic lookup_table_i[];
    rand logic input_i[];
    logic output_o[];

    function new(string name = "lkt_transaction");
        super.new(name);
    endfunction

endclass

`endif
