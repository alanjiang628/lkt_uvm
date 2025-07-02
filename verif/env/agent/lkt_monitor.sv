`ifndef __LKT_MONITOR_SV__
`define __LKT_MONITOR_SV__

class lkt_monitor extends uvm_monitor;
    virtual lkt_if vif;
    uvm_analysis_port #(lkt_transaction) ap;

    `uvm_component_utils(lkt_monitor)

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual lkt_if)::get(this, "", "vif", vif))
            `uvm_fatal("NO_IF", "Virtual interface not found!")
    endfunction

    task run_phase(uvm_phase phase);
        lkt_transaction tr;
        forever begin
            @(posedge vif.clk);
            #1; // Wait for combinatorial logic to settle
            tr = lkt_transaction::type_id::create("tr");

            // Set DUT parameters in transaction for context
            tr.RESULT_WIDTH = vif.RESULT_WIDTH;
            tr.NUM_LOOKUPS  = vif.NUM_LOOKUPS;
            tr.NUM_CHOICES  = vif.NUM_CHOICES;

            // Size the dynamic arrays before unpacking into them
            tr.lookup_table_i = new[vif.RESULT_WIDTH * vif.NUM_LOOKUPS * vif.NUM_CHOICES];
            tr.input_i        = new[vif.NUM_LOOKUPS * vif.NUM_CHOICES];
            tr.output_o       = new[vif.RESULT_WIDTH * vif.NUM_LOOKUPS];

            // Use the streaming operator to unpack the fixed-size vector into the dynamic array
            {>>{tr.lookup_table_i}} = vif.lookup_table_i;
            {>>{tr.input_i}}        = vif.input_i;
            {>>{tr.output_o}}       = vif.output_o;

            ap.write(tr);
        end
    endtask
endclass

`endif
