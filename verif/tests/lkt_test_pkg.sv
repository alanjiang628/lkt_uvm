`ifndef __LKT_TEST_PKG_SV__
`define __LKT_TEST_PKG_SV__

package lkt_test_pkg;
    import uvm_pkg::*;
    import lkt_config_pkg::*; // Import the new config package
    import lkt_env_pkg::*;
    import lkt_seq_pkg::*;

    // =================================================================
    // Base Test
    // =================================================================
    class base_test extends uvm_test;
        `uvm_component_utils(base_test)

        lkt_env   env;
        lkt_config cfg;
        bit test_pass = 1;
        int error_count = 0;

        function new(string name = "base_test", uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            cfg = lkt_config::type_id::create("cfg");
            
            // Set config fields from the central config package
            cfg.RESULT_WIDTH = lkt_config_pkg::RESULT_WIDTH;
            cfg.NUM_LOOKUPS  = lkt_config_pkg::NUM_LOOKUPS;
            cfg.NUM_CHOICES  = lkt_config_pkg::NUM_CHOICES;

            // Allow test-specific overrides
            configure_test(cfg);

            if(!uvm_config_db#(virtual lkt_if)::get(this, "", "vif", cfg.vif))
                `uvm_fatal("NO_IF", "Virtual interface not found")

            uvm_config_db#(lkt_config)::set(this, "*", "config", cfg);
            env = lkt_env::type_id::create("env", this);
        endfunction

        virtual function void configure_test(lkt_config cfg);
            // Default test-level configuration
            cfg.enable_coverage = 1;
            cfg.enable_sb = 1;
        endfunction

        task run_phase(uvm_phase phase);
            phase.raise_objection(this);
            `uvm_info("TEST", "Default base test running", UVM_MEDIUM)
            #100ns;
            phase.drop_objection(this);
        endtask
        
        function void report_phase(uvm_phase phase);
            super.report_phase(phase);

            // 自动检查错误
            error_count = uvm_report_server::get_server().get_severity_count(UVM_ERROR);
            if(error_count > 0) test_pass = 0;

            // 打印酷炫结果
            print_test_result();
        endfunction

        function void print_test_result();
            string pass_art = {
                "\n",
                "  ██████╗  █████╗ ███████╗███████╗\n",
                "  ██╔══██╗██╔══██╗██╔════╝██╔════╝\n",
                "  ██████╔╝███████║███████╗███████╗\n",
                "  ██╔═══╝ ██╔══██║╚════██║╚════██║\n",
                "  ██║     ██║  ██║███████║███████║\n",
                "  ╚═╝     ╚═╝  ╚═╝╚══════╝╚══════╝\n",
                "  (•̀ᴗ•́)و ̑̑ TEST PASSED!\n"
            };

            string fail_art = {
                "\n",
                "  ███████╗ █████╗ ██╗██╗     \n",
                "  ██╔════╝██╔══██╗██║██║     \n",
                "  █████╗  ███████║██║██║     \n",
                "  ██╔══╝  ██╔══██║██║██║     \n",
                "  ██║     ██║  ██║██║███████╗\n",
                "  ╚═╝     ╚═╝  ╚═╝╚═╝╚══════╝\n",
                "  (╯°□°)╯︵ ┻━┻ TEST FAILED!\n",
                $sformatf("  Found %0d errors!", error_count)
            };

            // 彩色打印
            if(test_pass) begin
                $write("%c[1;32m", 27); // 绿色
                $display(pass_art);
            end else begin
                $write("%c[1;31m", 27); // 红色
                $display(fail_art);
            end
            $write("%c[0m", 27); // 重置颜色

            // 标准报告
            $display("\n=== UVM Report Summary ===");
            $display("Fatal:   %0d", uvm_report_server::get_server().get_severity_count(UVM_FATAL));
            $display("Error:   %0d", error_count);
            $display("Warning: %0d", uvm_report_server::get_server().get_severity_count(UVM_WARNING));
            $display("Sim Time: %0t ns", $time);
        endfunction
    endclass

    // =================================================================
    // Configuration Tests
    // =================================================================
    class lk_table_cfg_basic_test extends base_test;
        `uvm_component_utils(lk_table_cfg_basic_test)
        function new(string name = "lk_table_cfg_basic_test", uvm_component parent); super.new(name, parent); endfunction
        
        task run_phase(uvm_phase phase);
            lk_table_func_randomized_seq seq;
            phase.raise_objection(this);
            seq = lk_table_func_randomized_seq::type_id::create("seq");
            repeat(10) seq.start(env.agent.sequencer);
            phase.drop_objection(this);
        endtask
    endclass

    class lk_table_cfg_boundary_test extends base_test;
        `uvm_component_utils(lk_table_cfg_boundary_test)
        function new(string name = "lk_table_cfg_boundary_test", uvm_component parent); super.new(name, parent); endfunction
        
        virtual function void configure_test(lkt_config cfg);
            super.configure_test(cfg);
            // Example of boundary config
            if ($urandom_range(0,1)) begin
                cfg.NUM_LOOKUPS = 1; cfg.NUM_CHOICES = 1; cfg.RESULT_WIDTH = 1;
            end else begin
                cfg.NUM_LOOKUPS = 16; cfg.NUM_CHOICES = 16; cfg.RESULT_WIDTH = 8; // Max example
            end
        endfunction

        task run_phase(uvm_phase phase);
            lk_table_func_randomized_seq seq;
            phase.raise_objection(this);
            seq = lk_table_func_randomized_seq::type_id::create("seq");
            repeat(5) seq.start(env.agent.sequencer);
            phase.drop_objection(this);
        endtask
    endclass

    // =================================================================
    // Core Functionality Tests
    // =================================================================
    class lk_table_func_one_hot_all_test extends base_test;
        `uvm_component_utils(lk_table_func_one_hot_all_test)
        function new(string name = "lk_table_func_one_hot_all_test", uvm_component parent); super.new(name, parent); endfunction
        
        task run_phase(uvm_phase phase);
            lk_table_func_one_hot_all_seq seq;
            phase.raise_objection(this);
            seq = lk_table_func_one_hot_all_seq::type_id::create("seq");
            // Test selecting first choice
            seq.randomize() with { choice_index == 0; };
            seq.start(env.agent.sequencer);
            // Test selecting last choice
            seq.randomize() with { choice_index == -1; };
            seq.start(env.agent.sequencer);
            phase.drop_objection(this);
        endtask
    endclass

    class lk_table_func_randomized_test extends base_test;
        `uvm_component_utils(lk_table_func_randomized_test)
        function new(string name = "lk_table_func_randomized_test", uvm_component parent); super.new(name, parent); endfunction
        
        task run_phase(uvm_phase phase);
            lk_table_func_randomized_seq seq;
            phase.raise_objection(this);
            seq = lk_table_func_randomized_seq::type_id::create("seq");
            repeat(20) seq.start(env.agent.sequencer);
            phase.drop_objection(this);
        endtask
    endclass

    class lk_table_func_no_choice_test extends base_test;
        `uvm_component_utils(lk_table_func_no_choice_test)
        function new(string name = "lk_table_func_no_choice_test", uvm_component parent); super.new(name, parent); endfunction
        
        task run_phase(uvm_phase phase);
            lk_table_func_no_choice_seq seq;
            phase.raise_objection(this);
            seq = lk_table_func_no_choice_seq::type_id::create("seq");
            seq.start(env.agent.sequencer);
            phase.drop_objection(this);
        endtask
    endclass

    class lk_table_func_one_hot_mixed_test extends base_test;
        `uvm_component_utils(lk_table_func_one_hot_mixed_test)
        function new(string name = "lk_table_func_one_hot_mixed_test", uvm_component parent); super.new(name, parent); endfunction
        
        task run_phase(uvm_phase phase);
            lk_table_func_one_hot_mixed_seq seq;
            phase.raise_objection(this);
            seq = lk_table_func_one_hot_mixed_seq::type_id::create("seq");
            repeat(10) seq.start(env.agent.sequencer);
            phase.drop_objection(this);
        endtask
    endclass

    // =================================================================
    // Negative Tests
    // =================================================================
    class lk_table_neg_multi_hot_test extends base_test;
        `uvm_component_utils(lk_table_neg_multi_hot_test)
        function new(string name = "lk_table_neg_multi_hot_test", uvm_component parent); super.new(name, parent); endfunction
        
        virtual function void configure_test(lkt_config cfg);
            super.configure_test(cfg);
            cfg.enable_sb = 0; // Disable scoreboard for negative test
        endfunction

        task run_phase(uvm_phase phase);
            lk_table_neg_multi_hot_seq seq;
            phase.raise_objection(this);
            seq = lk_table_neg_multi_hot_seq::type_id::create("seq");
            // Test one multi-hot
            seq.randomize() with { num_multi_hot == 1; };
            seq.start(env.agent.sequencer);
            // Test all multi-hot
            seq.randomize() with { num_multi_hot == cfg.NUM_LOOKUPS; };
            seq.start(env.agent.sequencer);
            phase.drop_objection(this);
        endtask
    endclass

endpackage
`endif
