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
        start_item(req);
        
        // Randomize the transaction, but disable the one-hot enforcement
        // so we can create an illegal multi-hot stimulus.
        assert(req.randomize() with { enforce_one_hot == 0; });

        // Now, programmatically create the desired number of multi-hot vectors.
        // This avoids any local variable declarations with non-constant ranges.
        for (int i = 0; i < num_multi_hot; i++) begin
            int lookup_idx;
            int bit1, bit2;
            int base_idx;

            // Ensure we pick a unique lookup index to corrupt
            lookup_idx = i % req.NUM_LOOKUPS; 
            base_idx = lookup_idx * req.NUM_CHOICES;
            
            // Pick two different random bits to set, guaranteeing a multi-hot vector
            // (assuming NUM_CHOICES >= 2, which is a reasonable assumption for this test)
            if (req.NUM_CHOICES >= 2) begin
                // Generate two random bits, ensuring they are different.
                // This avoids do-while loops which can confuse some compilers.
                bit1 = $urandom_range(0, req.NUM_CHOICES - 1);
                bit2 = $urandom_range(0, req.NUM_CHOICES - 1);
                if (bit1 == bit2) begin
                    bit2 = (bit1 + 1) % req.NUM_CHOICES;
                end

                // Manually clear the slice to avoid illegal part-select syntax
                for (int j = 0; j < req.NUM_CHOICES; j++) begin
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
