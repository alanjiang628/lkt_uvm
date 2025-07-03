`ifndef __LK_TABLE_NEG_MULTI_HOT_SEQ_SV__
`define __LK_TABLE_NEG_MULTI_HOT_SEQ_SV__

class lk_table_neg_multi_hot_seq extends base_sequence;
    `uvm_object_utils(lk_table_neg_multi_hot_seq)

    // Number of lookups to apply multi-hot to
    rand int unsigned num_multi_hot = 1;

    function new(string name = "lk_table_neg_multi_hot_seq");
        super.new(name);
    endfunction

    task body();
        req = lkt_transaction::type_id::create("req");
        start_item(req); // This calls pre_body, which gets the cfg object
        
        // Allocate memory for dynamic arrays now that cfg is available
        req.input_i = new[cfg.NUM_LOOKUPS * cfg.NUM_CHOICES];
        req.lookup_table_i = new[cfg.NUM_LOOKUPS * cfg.NUM_CHOICES * cfg.RESULT_WIDTH];
        req.output_o = new[cfg.NUM_LOOKUPS * cfg.RESULT_WIDTH];

        // Randomize the transaction first
        assert(req.randomize());

        // Now, programmatically create the desired number of multi-hot vectors.
        // This avoids any local variable declarations with non-constant ranges.
        for (int i = 0; i < num_multi_hot; i++) begin
            int lookup_idx;
            int bit1, bit2;
            int base_idx;

            // Ensure we pick a unique lookup index to corrupt
            lookup_idx = i % cfg.NUM_LOOKUPS; 
            base_idx = lookup_idx * cfg.NUM_CHOICES;
            
            // Pick two different random bits to set, guaranteeing a multi-hot vector
            // (assuming NUM_CHOICES >= 2, which is a reasonable assumption for this test)
            if (cfg.NUM_CHOICES >= 2) begin
                // Generate two random bits, ensuring they are different.
                // This avoids do-while loops which can confuse some compilers.
                bit1 = $urandom_range(0, cfg.NUM_CHOICES - 1);
                bit2 = $urandom_range(0, cfg.NUM_CHOICES - 1);
                if (bit1 == bit2) begin
                    bit2 = (bit1 + 1) % cfg.NUM_CHOICES;
                end

                // Manually clear the slice to avoid illegal part-select syntax
                for (int j = 0; j < cfg.NUM_CHOICES; j++) begin
                    req.input_i[base_idx + j] = 1'b0;
                end

                // Set the two chosen bits
                req.input_i[base_idx + bit1] = 1'b1;
                req.input_i[base_idx + bit2] = 1'b1;
            end
        end
        
        finish_item(req);
    endtask

    constraint c_num_multi_hot {
        soft num_multi_hot == 1;
        num_multi_hot > 0;
    }

endclass

`endif
