module montgomery_algorithm(
    A, B, N, clk, beg,
    out, out_ready, reset
);
//==============parameter definition==================
    parameter O_READY   = 1'b0;
    parameter O_PROCESS = 1'b1;
//===============in/out declaration===================
    input[255:0]  A;
    input[255:0]  B;
    input[255:0]  N;
    input         clk;
    input         beg;
    input         reset;
    output [255:0]        out;
    output        out_ready;
    integer       i;
//==============reg/wire declaration==================
    reg[257:0]    tmp_out;
    reg[257:0]    next_tmp_out;
    reg           out_ready;
    reg[255:0]    AA;
    reg[255:0]    BB;
    reg[255:0]    NN;
    reg[255:0]   next_AA;
    reg[255:0]   next_BB;
    reg[255:0]   next_NN;
    wire[257:0]    q_i256_0;
    wire[257:0]    q_i256_1;
    reg          q_i;
    reg[8:0]      iter_n;
    reg[8:0]     next_iter_n;
//===============combinational part===================
    
    assign q_i256_1 = tmp_out + BB;
    assign q_i256_0 = tmp_out;
    always@(*)begin
        if(AA[iter_n] == 1) q_i = q_i256_1[0];
        else q_i = q_i256_0[0];
    end
    
    always@(*) begin
        
        if (beg == 0) begin
            next_tmp_out   = 0;
        end
        else begin
            if(iter_n < 9'd256) begin
                case ({AA[iter_n],q_i})
                    2'b00: next_tmp_out = q_i256_0 >> 1;
                    2'b01: next_tmp_out = (q_i256_0 + NN) >> 1;
                    2'b10: next_tmp_out = (q_i256_1 ) >> 1;
                    2'b11: next_tmp_out = (q_i256_1 + NN) >> 1;
                endcase
            end
            else begin
                if(tmp_out >= NN)
                    next_tmp_out = tmp_out - NN;
                else
                    next_tmp_out = tmp_out;
            end
        end
        
    end
    
    always@(*) begin
        if (beg == 0) begin
            next_iter_n    = 0;
            next_AA = A;
            next_BB = B;
            next_NN = N;
            out_ready = O_PROCESS;
        end
        else begin
            next_iter_n    = (iter_n == 9'd258) ?  iter_n : iter_n + 9'b1;
            next_AA = AA;
            next_BB = BB;
            next_NN = NN;
            if(iter_n == 9'd258)
                 out_ready = O_READY;
            else                                 
                 out_ready = O_PROCESS;
        end
    end
    
    assign out = tmp_out[255:0];
//================sequential part=====================
    always@( posedge clk or posedge reset ) begin
        if(reset == 1) begin
            tmp_out   <= 0;
            iter_n    <= 0;
            AA <= 0;
            BB <= 0;
            NN <= 0;
            
        end
        else begin
            iter_n  <= next_iter_n;
            tmp_out <= next_tmp_out;
            AA <= next_AA;
            BB <= next_BB;
            NN <= next_NN;
        end
    end
endmodule
