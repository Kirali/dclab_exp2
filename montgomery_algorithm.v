module montgomery_algorithm(
    A, B, N, clk, beg,
    out, out_ready
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
    output        out;
    output        out_ready;
    integer       i;
//==============reg/wire declaration==================
    reg[255:0]    out;
    reg[255:0]    next_out;
    reg           out_ready;
    wire          q_i;
    reg[8:0]      iter_n;
    wire[8:0]     next_iter_n;
//===============combinational part===================
    assign q_i = out[0];
    assign next_iter_n = (iter_n == 9'd256) ?  iter_n : iter_n + 1;
    
    always@(*) begin
        next_out = out;
        if(iter_n == 0)
            next_out = ({256{A[iter_n]}}&B + {256{q_i}}&N)/2;
        else begin
            if(iter_n < 9'd256)
                next_out = (out + {256{A[iter_n]}}&B + {256{q_i}}&N)/2;
            else begin
                if(out > N)
                    next_out = out - N;
                else
                    next_out = out;
            end
        end
    end
//================sequential part=====================
    always@( posedge clk or negedge beg ) begin
        if(beg == 0) begin
            out       <= 0;
            iter_n    <= 0;
            out_ready <= O_PROCESS;
        end
        else begin
            iter_n <= next_iter_n;
            out    <= next_out;
            if(next_iter_n == 9'd256)
                out_ready <= O_READY;
            else
                out_ready <= O_PROCESS;
        end
    end
endmodule
