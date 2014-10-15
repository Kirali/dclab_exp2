module pre_processing (
    M,
    N,
    clk,
    beg,
    out,
    out_ready,
    
    //observation
    state
);

// this module do the following things:
// 1) take 256-bit M & N
// 2) count the digit of M = n
// 3) use recursive to calculate (2^n)*M mod N
// 4) output the outcome

// ================= parameter definition ===================
    parameter count_n = 2'b00;
    parameter recursive = 2'b01;
    parameter done = 2'b10;
// ================= in/out declaration =====================
    // ---------------- input ----------------------------------
    input [255:0] M;
    input [255:0] N;
    input clk;
    input beg;
        
    // ---------------- output --------------------------------- 
    output [255:0] out;
    output out_ready;
    
    //observation
    output [1:0] state;

// ================= reg/wire declaration ===================
    reg  [7:0] digit_n;
    reg  [7:0] next_digit_n;
    reg  [1:0] state;
    reg  [1:0] next_state;
    reg  counting;
    reg  next_counting;
    reg  recur;
    reg  next_recur;
    reg  firstMod;
    reg  next_firstMod;
    reg  [255:0] MM;
    reg  [255:0] next_MM; 
    reg  out_ready;
    reg  recurtime;
    reg  next_recurtime;

// ================= combinational part =====================

    // finite state machine
    always@(*) begin
        case (state)
            count_n: begin
                if (counting) begin
                    next_state = count_n; 
                    out_ready = 0;
                end
                else begin
                    next_state = recursive;
                    out_ready = 0;
                end
            end
            
            recursive: begin
                if (recur) begin
                    next_state = recursive;
                    out_ready = 0;
                end
                else begin
                    next_state = done;
                    out_ready = 1;
                end
            end
            
            done: begin
                next_state = done;
                out_ready = 0;
            end
            default: begin
                next_state = done;
                out_ready = 0;
            end
        endcase
    end

    // (1) count digit_n
    // (2) the first time mod N
    // (3) recursive 2M mod N
    always@(*) begin
        if (counting == 1) begin // count digit nember n
            if ( M[digit_n] == 0 ) begin // countung
                next_digit_n = digit_n - 1;
                next_counting = 1;
                next_MM = MM;
                next_firstMod = 1;
                next_recur = 0;
                next_recurtime = recurtime;
            end
            else begin // finish counting
                next_digit_n = digit_n;
                next_counting = 0;
                next_MM = MM;
                next_firstMod = 1;
                next_recur = 1;
                next_recurtime = recurtime;
            end
        end
        else if (counting == 0 && recur == 1 && firstMod == 1) begin  // first time mod N
            if (MM >= N) begin // mod ing
                next_digit_n = digit_n;
                next_counting = 0;
                next_MM = MM - N;
                next_firstMod = 1;
                next_recur = 1;
            end
            else begin // finish mod
                next_digit_n = digit_n;
                next_counting = 0;
                next_MM = MM;
                next_firstMod = 0;
                next_recur = 1;
            end
        end
        else if (counting == 0 && recur == 1 && firstMod == 0) begin // recursive 2M mod N
                if (recurtime < digit_n) begin // recursuve ing
                    if ((MM+MM) >= N) begin // case 1
                        next_digit_n = digit_n;
                        next_counting = 0;
                        next_MM = MM + MM - N;
                        next_firstMod = 0;
                        next_recur = 1;
                        next_recurtime = recurtime + 1;
                    end
                    else begin // case 2
                        next_digit_n = digit_n;
                        next_counting = 0;
                        next_MM = MM + MM;
                        next_firstMod = 0;
                        next_recur = 1;
                        next_recurtime = recurtime + 1;
                    end
                end
                else begin // finish recursive
                    next_digit_n = digit_n;
                    next_counting = 0;
                    next_MM = MM;
                    next_firstMod = 0;
                    next_recur = 0;
                    next_recurtime = recurtime;
                end
        end
        else begin // all finished
            next_digit_n = digit_n;
            next_counting = 0;
            next_MM = MM;
            next_firstMod = 0;
            next_recur = 0;
            next_recurtime = recurtime;
        end
    end
    
    // out
    assign out = MM;
    
// ================= sequentail part ========================
always@( posedge clk or negedge beg ) begin

    // reset
    if ( beg == 0 ) begin
        state <= count_n;
        counting <= 1'b1;
        digit_n <= 8'd255;
        firstMod <= 1'b1;
        MM <= M;
        recur <= 0;
        recurtime <= 0;
    end
    // run
    else begin
        state <= next_state;
        counting <= next_counting;
        digit_n <= next_digit_n;
        firstMod <= next_firstMod;
        MM <= next_MM;
        recur <= next_recur;
        recurtime <= next_recurtime;
    end

end

endmodule
