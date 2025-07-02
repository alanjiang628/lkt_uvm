`ifndef __LKT_TRANSACTION_SV__
`define __LKT_TRANSACTION_SV__

class lkt_transaction extends uvm_sequence_item;

    // DUT Parameters (will be set by config or sequence)
    int RESULT_WIDTH;
    int NUM_LOOKUPS;
    int NUM_CHOICES;

    // Stimulus and monitored fields are now dynamic arrays.
    // They MUST be sized in the sequence before randomization.
    rand logic lookup_table_i[];
    rand logic input_i[];
    logic output_o[];

    // ==============================================
    // UVM 注册与字段自动化
    // ==============================================
    `uvm_object_utils_begin(lkt_transaction)
        `uvm_field_int(RESULT_WIDTH, UVM_ALL_ON | UVM_NOCOMPARE)
        `uvm_field_int(NUM_LOOKUPS,  UVM_ALL_ON | UVM_NOCOMPARE)
        `uvm_field_int(NUM_CHOICES,  UVM_ALL_ON | UVM_NOCOMPARE)
    // Use `uvm_field_array_*` for dynamic arrays
    `uvm_field_array_int(lookup_table_i, UVM_ALL_ON)
    `uvm_field_array_int(input_i,        UVM_ALL_ON)
    `uvm_field_array_int(output_o,       UVM_ALL_ON)
    `uvm_object_utils_end

    // ==============================================
    // 构造函数
    // ==============================================
    function new(string name = "lkt_transaction");
        super.new(name);
    endfunction

    // ==============================================
    // 约束
    // ==============================================
    // Control knob for post_randomize one-hot enforcement.
    // By default, we ensure the input is valid (one-hot or zero-hot).
    rand bit enforce_one_hot = 1;

    // ==============================================
    // Post Randomization Hook
    // ==============================================
    // The pre_body/post_body methods are no longer needed here,
    // as sizing must be done in the sequence.

    // post_randomize is still valid for correcting data after randomization.
    function void post_randomize();
        int set_bits[$];
        int keep_idx;

        if (enforce_one_hot) begin
            // Check if arrays have been sized
            if (input_i.size() == 0) begin
                `uvm_fatal("TR_SIZE_ERR", "input_i dynamic array has not been sized before randomize()")
                return;
            end

            for (int i = 0; i < NUM_LOOKUPS; i++) begin
                int base_idx = i * NUM_CHOICES;
                int bit_count = 0;

                // Manually count the set bits
                for (int j = 0; j < NUM_CHOICES; j++) begin
                    if (input_i[base_idx + j]) bit_count++;
                end

                if (bit_count > 1) begin
                    set_bits.delete(); // Clear queue for this iteration
                    // Find all set bits
                    for (int j = 0; j < NUM_CHOICES; j++) begin
                        if (input_i[base_idx + j]) set_bits.push_back(j);
                    end
                    
                    // Pick one to keep and clear the others
                    keep_idx = set_bits[$urandom_range(0, set_bits.size() - 1)];
                    for (int j = 0; j < NUM_CHOICES; j++) begin
                        input_i[base_idx + j] = (j == keep_idx);
                    end
                end
            end
        end
    endfunction

    // ==============================================
    // 自定义方法 (可选)
    // ==============================================
    function string convert2string();
        return $sformatf("input_i=0x%h output_o=0x%h",
                        input_i, output_o);
    endfunction

endclass

`endif
