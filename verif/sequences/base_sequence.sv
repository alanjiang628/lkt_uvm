`ifndef __BASE_SEQUENCE_SV__
`define __BASE_SEQUENCE_SV__

class base_sequence extends uvm_sequence #(lkt_transaction);
    `uvm_object_utils(base_sequence)

    // Configuration object handle
    lkt_config cfg;

    function new(string name = "base_sequence");
        super.new(name);
    endfunction

    virtual task pre_body();
        // Get the config object from the config_db. This is the correct place for this.
        if (!uvm_config_db#(lkt_config)::get(m_sequencer, "", "config", cfg))
            `uvm_fatal("CONFIG", "Cannot get config object in sequence")
    endtask

    virtual task post_body();
        // post_body should not be used for req allocation.
    endtask

    virtual task body();
        // Base sequence has no specific behavior
    endtask

endclass

`endif
