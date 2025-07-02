`ifndef __LKT_ENV_SV__
`define __LKT_ENV_SV__

class lkt_env extends uvm_env;
    `uvm_component_utils(lkt_env)

    lkt_config    cfg;
    lkt_agent     agent;
    lkt_scoreboard scoreboard;
    // lkt_coverage coverage; // Placeholder for future coverage component

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(lkt_config)::get(this, "", "config", cfg))
            `uvm_fatal("CFG", "Config not found")

        agent = lkt_agent::type_id::create("agent", this);
        uvm_config_db#(uvm_active_passive_enum)::set(this, "agent", "is_active", UVM_ACTIVE);

        if(cfg.enable_sb) begin
            scoreboard = lkt_scoreboard::type_id::create("scoreboard", this);
        end

        // if(cfg.enable_coverage) begin
        //     coverage = lkt_coverage::type_id::create("coverage", this);
        // end
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if(cfg.enable_sb) begin
            agent.monitor.ap.connect(scoreboard.mon_imp);
        end

        // if(cfg.enable_coverage) begin
        //     agent.monitor.ap.connect(coverage.analysis_export);
        // end
    endfunction

endclass

`endif
