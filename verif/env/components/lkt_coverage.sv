`ifndef __LKT_COVERAGE_SV__
`define __LKT_COVERAGE_SV__

class lkt_coverage extends uvm_subscriber #(lkt_transaction);
    `uvm_component_utils(lkt_coverage)

    // Configuration object
    lkt_config cfg;

    // --- Sampled variables for coverpoints ---
    // These variables capture the state of an entire transaction.
    // They are calculated in the write method before being sampled.
    bit is_min_config;
    bit is_max_config;
    bit is_typical_config;
    bit is_first_choice_all;
    bit is_last_choice_all;
    bit is_all_zero_all;
    bit is_mixed_onehot_zero;
    bit has_multi_hot;
    bit is_multi_hot_all;
    int unsigned per_lookup_choice[]; // To cover all choices for each lookup

    // --- Covergroup Definition ---
    // This covergroup is designed to match the test plan exactly.
    covergroup cg with function sample(int lookup_idx);
        option.per_instance = 1;
        option.name = "lkt_coverage";

        // CP for parameter configurations
        cp_params_boundary: coverpoint is_max_config { bins hit = {1}; }
        cp_params_basic:    coverpoint is_typical_config { bins hit = {1}; }
        cp_params_min_config: coverpoint is_min_config { bins hit = {1}; }

        // CP for one-hot selection patterns
        cp_sel_first_choice: coverpoint is_first_choice_all { bins hit = {1}; }
        cp_sel_last_choice:  coverpoint is_last_choice_all { bins hit = {1}; }
        
        // CP for all-zero and mixed selection patterns
        cp_sel_all_zero:          coverpoint is_all_zero_all { bins hit = {1}; }
        cp_sel_mixed_onehot_zero: coverpoint is_mixed_onehot_zero { bins hit = {1}; }

        // CP for ensuring all choices are tested for each lookup
        cp_all_choices_per_lookup: coverpoint per_lookup_choice[lookup_idx];

        // CP for illegal multi-hot scenarios
        cp_illegal_multi_hot:     coverpoint has_multi_hot { bins hit = {1}; }
        cp_illegal_multi_hot_all: coverpoint is_multi_hot_all { bins hit = {1}; }
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        cg = new();
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(lkt_config)::get(this, "", "config", cfg))
            `uvm_fatal("CONFIG", "Cannot get config object")
        
        // Size the dynamic array for the coverpoint now that cfg is available
        per_lookup_choice = new[cfg.NUM_LOOKUPS];
    endfunction

    function void write(lkt_transaction t);
        int num_ones, num_zeros, num_multi_hot;
        int first_choice_count, last_choice_count;

        // 1. Analyze the transaction and calculate coverage metrics
        num_ones = 0;
        num_zeros = 0;
        num_multi_hot = 0;
        first_choice_count = 0;
        last_choice_count = 0;

        for (int i = 0; i < cfg.NUM_LOOKUPS; i++) begin
            int slice_ones = 0;
            int choice = -1;
            for (int j = 0; j < cfg.NUM_CHOICES; j++) begin
                if (t.input_i[i*cfg.NUM_CHOICES + j]) begin
                    slice_ones++;
                    choice = j;
                end
            end

            per_lookup_choice[i] = choice; // Store choice for this lookup

            if (slice_ones == 0) num_zeros++;
            else if (slice_ones == 1) begin
                num_ones++;
                if (choice == 0) first_choice_count++;
                if (choice == cfg.NUM_CHOICES - 1) last_choice_count++;
            end else begin
                num_multi_hot++;
            end
        end

        // 2. Set the boolean sampling variables based on the analysis
        // Config checks (simplified: assumes specific values for min/max/typical)
        is_min_config = (cfg.NUM_LOOKUPS == 1 || cfg.NUM_CHOICES == 1);
        is_max_config = (cfg.NUM_LOOKUPS == 16 && cfg.NUM_CHOICES == 8); // As per BOUNDARY_TEST
        is_typical_config = (cfg.NUM_LOOKUPS == 8 && cfg.NUM_CHOICES == 2); // As per default

        // Selection pattern checks
        is_first_choice_all = (first_choice_count == cfg.NUM_LOOKUPS);
        is_last_choice_all  = (last_choice_count == cfg.NUM_LOOKUPS);
        is_all_zero_all     = (num_zeros == cfg.NUM_LOOKUPS);
        is_mixed_onehot_zero = (num_ones > 0 && num_zeros > 0);
        
        // Illegal case checks
        has_multi_hot    = (num_multi_hot > 0);
        is_multi_hot_all = (num_multi_hot == cfg.NUM_LOOKUPS);

        // 3. Sample the covergroup
        // We sample once per lookup to hit the per_lookup_choice bins correctly.
        for (int i = 0; i < cfg.NUM_LOOKUPS; i++) begin
            cg.sample(i);
        end
    endfunction

endclass

`endif
