`ifndef __LKT_MONITOR_SV__
`define __LKT_MONITOR_SV__

class lkt_monitor extends uvm_monitor;
    lkt_vif vif; // Use the centralized virtual interface typedef
    uvm_analysis_port #(lkt_transaction) ap;
    lkt_config cfg;

    `uvm_component_utils(lkt_monitor)

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(lkt_config)::get(this, "", "config", cfg))
            `uvm_fatal("NO_CONFIG", "Config object not found in monitor")
        
        // Get the virtual interface using the centralized typedef
        if(!uvm_config_db#(lkt_vif)::get(this, "", "vif", vif))
            `uvm_fatal("NO_VIF", "Virtual interface not found in monitor")
    endfunction

    task run_phase(uvm_phase phase);
        lkt_transaction tr;
        forever begin
            @(posedge vif.clk);
            #1; // Wait for combinatorial logic to settle
            tr = lkt_transaction::type_id::create("tr");

            // Size the dynamic arrays based on the monitor's config object
            tr.lookup_table_i = new[cfg.RESULT_WIDTH * cfg.NUM_LOOKUPS * cfg.NUM_CHOICES];
            tr.input_i        = new[cfg.NUM_LOOKUPS * cfg.NUM_CHOICES];
            tr.output_o       = new[cfg.RESULT_WIDTH * cfg.NUM_LOOKUPS];

            // Use the streaming operator to unpack the fixed-size vector into the dynamic array
            {>>{tr.lookup_table_i}} = vif.lookup_table_i;
            {>>{tr.input_i}}        = vif.input_i;
            {>>{tr.output_o}}       = vif.output_o;

            ap.write(tr);
        end
    endtask
endclass

`endif
