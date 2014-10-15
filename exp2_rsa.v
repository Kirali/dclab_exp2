module exp2_rsa (
    clk,
    reset,
    ready,
    we,
    oe,
    start,
    reg_sel,
    addr,
    data_i,
    data_o,
    
    // observation
    state , 
    //counter,
    pre_ready,
    beg_pre,
    pre_state
    
    // signals below are inputs of LA (for observation)
    /*clk_o, 
    reset_o,
    ready_o,
    we_o,
    oe_o,
    start_o,
    reg_sel_o,
    addr_o,
    data_i_o*/
);

//==== parameter definition ===============================
    //state
    parameter   we_state = 2'b00;
    parameter   cal_state= 2'b01;
    parameter   oe_state = 2'b10;
    
//==== in/out declaration ==================================
    //-------- input ---------------------------
    input clk;
    input reset;
    input we;
    input oe;
    input start;
    input [1:0] reg_sel;
    input [4:0] addr;
    input [7:0] data_i;
    
    //-------- output --------------------------------------
    output reg ready;
    output reg [7:0] data_o;
    
    //-------------observation-----------
    output [1:0]state;
    //output [8:0]counter;
    output pre_ready;
    output beg_pre;
    output [1:0]pre_state;
    
    
    // signals below are inputs of LA (for observation)
    /*output clk_o;
    output reset_o;
    output ready_o;
    output we_o;
    output oe_o;
    output start_o;
    output [1:0] reg_sel_o;
    output [4:0] addr_o;
    output [7:0] data_i_o;*/

//==== reg/wire declaration ================================
    
    
    //wire   [7:0] cal_result1 [31:0];
    //wire   [7:0] cal_result2 [31:0];
    //wire   [7:0] cal_result3 [31:0];
    wire   [255:0] next_cal_t;
    wire   [255:0] next_cal_s;
    wire   next_MA_beg;
    wire   [255:0] MA_sA     ;
    wire   [255:0] MA_sB     ;
    wire   [255:0] MA_tA     ;
    wire   [255:0] MA_tB     ;
    wire   [255:0] cal_pret  ;
    wire   pre_ready;
    wire   MA_sready;
    wire   MA_tready;
    
    reg    [255:0] cal_t;
    reg    [255:0] cal_s;
    reg    MA_beg;
    reg    [8:0] counter;
    reg    [8:0] next_counter;
    reg    beg_pre;
    
    reg   [7:0] cal_result0 [31:0];
    
    reg    [7:0] next_a0 [31:0];
    reg    [7:0] next_a1 [31:0];
    reg    [7:0] next_a2 [31:0];
    reg    [7:0] next_a3 [31:0];
    
    
    reg     [1:0]state;
    reg     [1:0]next_state;
    
    reg     [7:0] a0    [31:0];
    reg     [7:0] a1    [31:0];
    reg     [7:0] a2    [31:0];
    reg     [7:0] a3    [31:0];
    
    
    reg     f_cal; 
    reg     done;
    
    integer i;
    
//==== combinational part ==================================
    //finite state machine
    always@(*) begin
        case(state)
            we_state:begin
                if(we == 0 && start == 1)begin
                    ready = 0;
                    next_state = cal_state;
                    beg_pre = 0;
                end
                else begin
                    ready = 1;
                    next_state = we_state;
                    beg_pre = 1;
                end
            end        
            cal_state:begin
                if(done == 0)begin
                    ready = 0;
                    next_state = cal_state;
                    beg_pre = 1;
                end
                else begin
                    ready = 1;
                    next_state = oe_state;
                    beg_pre = 1;
                end
            end
            oe_state:begin
                if(oe == 0 && we == 1)begin
                    ready = 1;
                    next_state = we_state;
                    beg_pre = 1;
                end
                else begin
                    ready = 1;
                    next_state = oe_state;
                    beg_pre = 1;
                end
            end
            default: begin
                ready = 1'bX;
                next_state = 2'bX;
                beg_pre = 1;
            end
        endcase
    end
    
    //256bit reg 
    always@(*) begin
        case(state)
            we_state:begin
                for ( i=0; i < 32; i=i+1 )begin
                next_a0[i] = a0[i];
                next_a1[i] = a1[i];
                next_a2[i] = a2[i];
                next_a3[i] = a3[i];
                end
                
                case(reg_sel)
                    2'b00: next_a0[addr] = data_i;  
                    2'b01: next_a1[addr] = data_i;
                    2'b10: next_a2[addr] = data_i;
                    2'b11: next_a3[addr] = data_i;
                endcase
            end
            
            cal_state:begin
                for ( i=0; i < 32; i=i+1 )begin
                next_a0[i] = cal_result0[i];
                next_a1[i] = a1[i];
                next_a2[i] = a2[i];
                next_a3[i] = a3[i];
                end
            end
            
            oe_state:begin
                for ( i=0; i < 32; i=i+1 )begin
                next_a0[i] = a0[i];
                next_a1[i] = a1[i];
                next_a2[i] = a2[i];
                next_a3[i] = a3[i];
                end
            end
            
            default:begin
                for ( i=0; i < 32; i=i+1 )begin
                next_a0[i] = a0[i];
                next_a1[i] = a1[i];
                next_a2[i] = a2[i];
                next_a3[i] = a3[i];
                end
            end
        endcase
    end
    
    //data_o
    always@(*) begin
        if (state == oe_state)begin
            case(reg_sel)
                2'b00: data_o = a0[addr];  
                2'b01: data_o = a1[addr];
                2'b10: data_o = a2[addr];
                2'b11: data_o = a3[addr];
            endcase
        end
        else data_o = 8'bx;
    end
    
    //calculate
    pre_processing  pre1 (.M({a1[31],a1[30],a1[29],a1[28],a1[27],a1[26],a1[25],a1[24],
                           a1[23],a1[22],a1[21],a1[20],a1[19],a1[18],a1[17],a1[16],
                           a1[15],a1[14],a1[13],a1[12],a1[11],a1[10],a1[9] ,a1[8] ,
                           a1[7] ,a1[6] ,a1[5] ,a1[4] ,a1[3] ,a1[2] ,a1[1] ,a1[0]}),
                          .N({a3[31],a3[30],a3[29],a3[28],a3[27],a3[26],a3[25],a3[24],
                           a3[23],a3[22],a3[21],a3[20],a3[19],a3[18],a3[17],a3[16],
                           a3[15],a3[14],a3[13],a3[12],a3[11],a3[10],a3[9] ,a3[8] ,
                           a3[7] ,a3[6] ,a3[5] ,a3[4] ,a3[3] ,a3[2] ,a3[1] ,a3[0]}),
                           .clk(clk),.beg(beg_pre),.out(cal_pret),.out_ready(pre_ready)
                           
                           //observation
                           ,.state(pre_state));
    
    montgomery_algorithm    MA_s(.A(MA_sA), .B(MA_sB), .clk(clk), .beg(MA_beg), .out(next_cal_t), .out_ready(MA_sready)); // for S
    montgomery_algorithm    MA_t(.A(MA_tA), .B(MA_tB), .clk(clk), .beg(MA_beg), .out(next_cal_s), .out_ready(MA_tready)); // for T
                                  
    assign  next_MA_beg = ( (MA_sready && MA_tready) == 0 || pre_ready == 1)? 0 : 1;    
    
    assign  MA_sA = pre_ready == 1? cal_pret : cal_t ; 
    assign  MA_sB = pre_ready == 1? 1 : cal_s ;
    assign  MA_tA = pre_ready == 1? cal_pret : cal_t ;
    assign  MA_tB = pre_ready == 1? cal_pret : cal_t ;
    
    
    // put cal_s result into cal_result0
    
     
    always@(*) begin
        if (counter == 9'd256) begin
            {cal_result0[31],cal_result0[30],cal_result0[29],cal_result0[28],cal_result0[27],cal_result0[26],cal_result0[25],cal_result0[24],
             cal_result0[23],cal_result0[22],cal_result0[21],cal_result0[20],cal_result0[19],cal_result0[18],cal_result0[17],cal_result0[16],
             cal_result0[15],cal_result0[14],cal_result0[13],cal_result0[12],cal_result0[11],cal_result0[10],cal_result0[9], cal_result0[8],
             cal_result0[7] ,cal_result0[6], cal_result0[5], cal_result0[4], cal_result0[3], cal_result0[2], cal_result0[1], cal_result0[0]}= cal_s;
             done = 1;
             next_counter = 0;
        end
        else begin
            for ( i=0; i < 32; i=i+1 )begin
                cal_result0[i] = 0;
                end
            done = 0;
            next_counter = (MA_sready == 0 && MA_tready == 0 && MA_beg == 1)? counter + 1: counter;
        end
    end
    
//==== sequential part =====================================  
    always@(posedge clk or posedge reset)
        if (reset == 1) begin
            for ( i=0; i < 32; i=i+1 )begin
                a0[i] <= 8'b0;
                a1[i] <= 8'b0;
                a2[i] <= 8'b0;
                a3[i] <= 8'b0;
                end
            cal_t <= 255'b0;
            cal_s <= 255'b0;
            MA_beg<= 1;
            counter <= 0;
            state <= 0;
        end
        else begin
            for ( i=0; i < 32; i=i+1 )begin
                a0[i] <= next_a0[i];
                a1[i] <= next_a1[i];
                a2[i] <= next_a2[i];
                a3[i] <= next_a3[i];
                end
            cal_t <= next_cal_t;
            cal_s <= next_cal_s;
            MA_beg<= next_MA_beg;
            counter <= next_counter;
            state <= next_state;
        end
    
endmodule
