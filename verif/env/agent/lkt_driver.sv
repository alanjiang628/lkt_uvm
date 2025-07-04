`ifndef __LKT_DRIVER_SV__
`define __LKT_DRIVER_SV__

class lkt_driver extends uvm_driver #(lkt_transaction);
    lkt_config cfg;
    lkt_vif vif; // Use the centralized virtual interface typedef
    `uvm_component_utils(lkt_driver)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(lkt_config)::get(this, "", "config", cfg))
            `uvm_fatal("NO_CONFIG", "Config object not found in driver")
        
        // Get the virtual interface using the centralized typedef
        if(!uvm_config_db#(lkt_vif)::get(this, "", "vif", vif))
            `uvm_fatal("NO_VIF", "Virtual interface not found in driver")
    endfunction

    task run_phase(uvm_phase phase);
        forever begin
            seq_item_port.get_next_item(req);
            drive_trans(req);
            seq_item_port.item_done();
        end
    endtask

    virtual task drive_trans(lkt_transaction trans);
        // Use the streaming operator to pack the dynamic array into the fixed-size vector
        vif.lookup_table_i <= {<<{trans.lookup_table_i}};
        vif.input_i        <= {<<{trans.input_i}};
        // Add a small delay for signal propagation
        #1;
    endtask

endclass

`endif
