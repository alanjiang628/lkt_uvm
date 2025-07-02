`ifndef __LKT_AGENT_SV__
`define __LKT_AGENT_SV__

class lkt_agent extends uvm_agent;
    `uvm_component_utils(lkt_agent)

    lkt_driver    driver;
    lkt_monitor   monitor;
    lkt_sequencer sequencer;

    uvm_active_passive_enum is_active = UVM_ACTIVE;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        monitor = lkt_monitor::type_id::create("monitor", this);
        if (is_active == UVM_ACTIVE) begin
            driver = lkt_driver::type_id::create("driver", this);
            sequencer = lkt_sequencer::type_id::create("sequencer", this);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        if (is_active == UVM_ACTIVE) begin
            driver.seq_item_port.connect(sequencer.seq_item_export);
        end
    endfunction

endclass

`endif
