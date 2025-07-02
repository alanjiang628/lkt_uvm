`ifndef __BASE_SEQUENCE_SV__
`define __BASE_SEQUENCE_SV__

class base_sequence extends uvm_sequence #(lkt_transaction);
    `uvm_object_utils(base_sequence)

    function new(string name = "base_sequence");
        super.new(name);
    endfunction

    virtual task body();
        // Base sequence has no specific behavior
    endtask

endclass

`endif
