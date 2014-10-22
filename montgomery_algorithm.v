module montgomery_algorithm(
    A, B, N, clk, beg,
    out, out_ready, reset
);
//==============parameter definition==================
    parameter O_READY   = 0;
    parameter O_PROCESS = 1;
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
    reg[257:0]    q_i256;
    wire          q_i;
    reg[8:0]      iter_n;
    reg[8:0]     next_iter_n;
    wire [255:0]  first_qi;
//===============combinational part===================
    
    // assign next_iter_n = (iter_n == 9'd258) ?  iter_n : iter_n + 1;
    // assign next_AA = AA;
    // assign next_BB = BB;
    // assign next_NN = NN;
    assign first_qi = {256{AA[0]}}&BB;
    always@(*)begin
        if(AA[iter_n] == 1) q_i256 = tmp_out + BB;
        else q_i256 = tmp_out;
    end
    assign q_i = q_i256[0];
    
    always@(*) begin
        //next_out = out;
        /*if(iter_n == 0)
            next_out = ({256{AA[iter_n]}}&BB + {256{first_qi[0]}}&NN) >> 1;
        else begin
            if(iter_n < 9'd256)
                next_out = (out + {256{AA[iter_n]}}&BB + {256{q_i}}&NN) >> 1;
            else begin
                if(out > NN)
                    next_out = out - NN;
                else
                    next_out = out;
            end
        end*/
        if (beg == 0) begin
            next_tmp_out   = 0;
        end
        else if(iter_n == 0) begin
                if(AA[0] == 0) begin
                    if(first_qi[0] == 0) begin
                        next_tmp_out = 0;
                    end
                    else begin
                        next_tmp_out = NN >> 1;
                    end
                end
                else begin
                    if(first_qi[0] == 0) begin
                        next_tmp_out = BB >> 1;
                    end
                    else begin
                        next_tmp_out = (BB + NN) >> 1;
                    end
                end
            end
        else begin
            if(iter_n < 9'd256) begin
                case ({AA[iter_n],q_i})
                    2'b00: next_tmp_out = tmp_out >> 1;
                    2'b01: next_tmp_out = (tmp_out + NN) >> 1;
                    2'b10: next_tmp_out = (tmp_out + BB) >> 1;
                    2'b11: next_tmp_out = (tmp_out + BB + NN) >> 1;
                    default: next_tmp_out = 256'bx;
                endcase
                /*if(AA[iter_n] == 0) begin
                    if(first_qi[0] == 0) begin
                        next_out = out >> 1;
                    end
                    else begin
                        next_out = (out + NN) >> 1;
                    end
                end
                else begin
                    if(first_qi[0] == 0) begin
                        next_out = (out + BB) >> 1;
                    end
                    else begin
                        next_out = (out + BB + NN) >> 1;
                    end
                end*/
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
            next_iter_n    = (iter_n == 9'd258) ?  iter_n : iter_n + 1;
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
            // out_ready <= O_PROCESS;
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
            // if(next_iter_n == 9'd258)
                // out_ready <= O_READY;
            // else
                // out_ready <= O_PROCESS;
        end
    end
endmodule
