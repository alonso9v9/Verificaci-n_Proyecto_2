`ifndef FIFOS
   `include "fifo.sv"
    `define FIFOS
`endif

//////////////////////////////////////////////////////////
// Definition of a third state buffer  //
/////////////////////////////////////////////////////////

module tri_buf (a,b,en);
    input a;
    output b;
    input en;
    wire a,en;
    wire b;
    
   assign b = (en) ? a : 1'bz;
     	  	 
endmodule

///////////////////////////////////////////////////////////////
// Definition of a serial to parallel signal converter block // 
//////////////////////////////////////////////////////////////

module parallel_serial (
  input S_in,
  input P_in,
  input sel_P_S,
  output S_out,
  output P_out   
  );

  tri_buf serial(.a(S_in),.b(S_out),.en(~sel_P_S));
  tri_buf parallel_in (.a(P_in),.b(S_out),.en(sel_P_S));
//to send Pot to hiz when sel_p_s = 0 enable the line below and disable the
//line after that one
//  tri_buf parallel_out (.a(S_in),.b(P_out),.en(sel_P_S)); 
  assign P_out = S_in;

endmodule

//////////////////////////////////////////////////////////////////////////////
// Definition of a register block which can be readed and writed either in //
// parallel or in series                                                   //
/////////////////////////////////////////////////////////////////////////////

module serializer #(parameter pckg_sz = 32) (
  input sel_p_s,
  input s_in,
  input rst,
  input clk,
  input [pckg_sz-1:0] P_in,
  output s_out,
  output [pckg_sz-1:0] P_out
  );
  wire [pckg_sz-1:0] q;
  wire [pckg_sz-1:0] d;

  genvar i;
  generate
    for ( i = 0; i < pckg_sz; i = i+1 )
      begin : _bit
        dff_async_rst dff (.data(d[i]),.clk(clk),.reset(rst),.q(q[i]));
      end
    for( i = 0; i < pckg_sz-1; i = i+1 )
      begin: bt
        parallel_serial pts (.S_in(q[i]),.P_in(P_in[i+1]),.sel_P_S(sel_p_s),.S_out(d[i+1]),.P_out(P_out[i]));
      end
  endgenerate
  assign d[0] = (sel_p_s)?P_in[0]:s_in;
  assign s_out =(~sel_p_s)?q[pckg_sz-1]:1'bz;
  assign P_out[pckg_sz-1] = q[pckg_sz-1];
endmodule

////////////////////////////////////////////////////////////////////////
// Definition of an in order counter from 0 to a parametrized number //
////////////////////////////////////////////////////////////////////////

module Counter#(parameter mx_cnt = 32) (count, clk, rst);
  output reg [$clog2(mx_cnt)-1:0] count;
  input clk;
  input rst;
 
     

  always @(posedge clk or posedge rst)
       if (rst)
           count = 0;
       else
         count = count + 1;
endmodule

//////////////////////////////////////////////////////////////////////////////
// Definition of the read state machine for the bus interconnect controller //
//////////////////////////////////////////////////////////////////////////////

module Read_st_Mchn (
  input condition_r,
  output reg rdi,
  input reset,
  input clk,
  output reg [1:0] s_ds_r,
  output reg s_cmp,
  output reg rst_cntr_r,
  output reg rst_r,
  output reg p_s_r,
  output reg en_r,
  output reg push
  );
  
  reg [2:0] nxt_st;
  wire [2:0] cur_st;
  //state registers
  dff_async_rst st0(.data(nxt_st[0]),.clk(clk),.reset(reset),.q(cur_st[0]));
  dff_async_rst st1(.data(nxt_st[1]),.clk(clk),.reset(reset),.q(cur_st[1]));
  dff_async_rst st2(.data(nxt_st[2]),.clk(clk),.reset(reset),.q(cur_st[2])); 
  
  //nextstate decoder
 always@(*) begin
  case ({cur_st,condition_r})
      4'b0001:  nxt_st = {3'b001}; 
      4'b0000:  nxt_st = {3'b001}; 
      4'b0011:  nxt_st = {3'b011}; 
      4'b0010:  nxt_st = {3'b001}; 
      4'b0111:  nxt_st = {3'b111}; 
      4'b0110:  nxt_st = {3'b011}; 
      4'b1011:  nxt_st = {3'b000}; 
      4'b1010:  nxt_st = {3'b000}; 
      4'b1101:  nxt_st = {3'b000}; 
      4'b1100:  nxt_st = {3'b000}; 
      4'b1111:  nxt_st = {3'b110}; 
      4'b1110:  nxt_st = {3'b101}; 
      default:  nxt_st = {3'b000};  
    endcase
  //Output Logic
  case(cur_st)
    3'b000: begin
            rdi = 1'b0;
            s_ds_r = 2'b00;
            s_cmp = 1'b1;
            rst_cntr_r = 1'b1;
            rst_r = 1'b1;
            p_s_r = 1'b0;
            en_r = 1'b0;
            push = 1'b0;
    end
    3'b001: begin
            rdi = 1'b1;
            s_ds_r = 2'b00;
            s_cmp = 1'b1;
            rst_cntr_r = 1'b0;
            rst_r = 1'b0;
            p_s_r = 1'b0;
            en_r = 1'b0;
            push = 1'b0;
    end
    3'b011: begin
            rdi = 1'b0;
            s_ds_r = 2'b10;
            s_cmp = 1'b1;
            rst_cntr_r = 1'b0;
            rst_r = 1'b0;
            p_s_r = 1'b0;
            en_r = 1'b1;
            push = 1'b0;
    end
    3'b111: begin
            rdi = 1'b0;
            s_ds_r = 2'b01;
            s_cmp = 1'b0;
            rst_cntr_r = 1'b0;
            rst_r = 1'b0;
            p_s_r = 1'b1;
            en_r = 1'b0;
            push = 1'b0;
    end
    3'b110: begin
            rdi = 1'b0;
            s_ds_r = 2'b00;
            s_cmp = 1'b0;
            rst_cntr_r = 1'b0;
            rst_r = 1'b0;
            p_s_r = 1'b1;
            en_r = 1'b0;
            push = 1'b1;
    end
    3'b101: begin
            rdi = 1'b0;
            s_ds_r = 2'b00;
            s_cmp = 1'b0;
            rst_cntr_r = 1'b0;
            rst_r = 1'b0;
            p_s_r = 1'b1;
            en_r = 1'b0;
            push = 1'b0;
    end
    default: begin
            rdi = 1'b0;
            s_ds_r = 2'b00;
            s_cmp = 1'b1;
            rst_cntr_r = 1'b1;
            rst_r = 1'b1;
            p_s_r = 1'b0;
            en_r = 1'b0;
            push = 1'b0;
    end
    endcase
    end
endmodule

///////////////////////////////////////////////////////////////////////////////
// Definition of the Write state machine for the bus interconnect controller //
///////////////////////////////////////////////////////////////////////////////

module  Write_st_Mchn(
  input clk,
  input reset,
  input condition_w,
  output reg bs_bsy,
  output reg bs_rqst,
  output reg [1:0] s_ds_w,
  output reg rst_cntr_w,
  output reg rst_w,
  output reg p_s_w,
  output reg en_w,
  output reg pop 
  );
 
  //state registers
  reg [2:0] nxt_st;
  wire [2:0] cur_st;
  
  dff_async_rst st0(.data(nxt_st[0]),.clk(clk),.reset(reset),.q(cur_st[0]));
  dff_async_rst st1(.data(nxt_st[1]),.clk(clk),.reset(reset),.q(cur_st[1]));
  dff_async_rst st2(.data(nxt_st[2]),.clk(clk),.reset(reset),.q(cur_st[2])); 

  //nextstate decoder
   always@(*) begin 
   case ({cur_st,condition_w})
      4'b0001:  nxt_st = 3'b001;
      4'b0000:  nxt_st = 3'b001;
      4'b0101:  nxt_st = 3'b100;
      4'b0100:  nxt_st = 3'b100;
      4'b0011:  nxt_st = 3'b011;
      4'b0010:  nxt_st = 3'b001;
      4'b0111:  nxt_st = 3'b111;
      4'b0110:  nxt_st = 3'b111;
      4'b1011:  nxt_st = 3'b010;
      4'b1010:  nxt_st = 3'b101;
      4'b1001:  nxt_st = 3'b000;
      4'b1000:  nxt_st = 3'b100;
      4'b1111:  nxt_st = 3'b101;
      4'b1110:  nxt_st = 3'b101;
      default:  nxt_st = 3'b000; 
    endcase
  //Output Logic
  case(cur_st)
    3'b000: begin
            bs_bsy = 1'b0;
            bs_rqst = 1'b0;
            s_ds_w  = 2'b10;
            rst_cntr_w = 1'b1;
            rst_w = 1'b1;
            p_s_w = 1'b1;
            en_w = 1'b0;
            pop = 1'b0;
    end
    3'b001: begin
            bs_bsy = 1'b0;
            bs_rqst = 1'b0;
            s_ds_w  = 2'b10;
            rst_cntr_w = 1'b0;
            rst_w = 1'b0;
            p_s_w = 1'b1;
            en_w = 1'b0;
            pop = 1'b0;
    end
    3'b010: begin
            bs_bsy = 1'b1;
            bs_rqst = 1'b1;
            s_ds_w  = 2'b00;
            rst_cntr_w = 1'b0;
            rst_w = 1'b0;
            p_s_w = 1'b0;
            en_w = 1'b0;
            pop = 1'b0;
    end
    3'b011: begin
            bs_bsy = 1'b0;
            bs_rqst = 1'b0;
            s_ds_w  = 2'b00;
            rst_cntr_w = 1'b1;
            rst_w = 1'b0;
            p_s_w = 1'b1;
            en_w = 1'b1;
            pop = 1'b0;
    end
    3'b111: begin
            bs_bsy = 1'b0;
            bs_rqst = 1'b1;
            s_ds_w  = 2'b00;
            rst_cntr_w = 1'b1;
            rst_w = 1'b0;
            p_s_w = 1'b0;
            en_w = 1'b0;
            pop = 1'b1;
    end
    3'b101: begin
            bs_bsy = 1'b0;
            bs_rqst = 1'b1;
            s_ds_w  = 2'b00;
            rst_cntr_w = 1'b0;
            rst_w = 1'b0;
            p_s_w = 1'b0;
            en_w = 1'b0;
            pop = 1'b0;
    end
    3'b100: begin
            bs_bsy = 1'b1;
            bs_rqst = 1'b1;
            s_ds_w  = 2'b01;
            rst_cntr_w = 1'b0;
            rst_w = 1'b0;
            p_s_w = 1'b0;
            en_w = 1'b1;
            pop = 1'b0;
    end
    default: begin
            bs_bsy = 1'b0;
            bs_rqst = 1'b0;
            s_ds_w  = 2'b10;
            rst_cntr_w = 1'b1;
            rst_w = 1'b1;
            p_s_w = 1'b1;
            en_w = 1'b0;
            pop = 1'b0;
    end
    endcase
    end
endmodule

//////////////////////////////////////////////////////////////////////////////
// Definition of Control block for the Bus controller 
/////////////////////////////////////////////////////////////////////////////

module ntrfs_cntrl #(parameter pckg_sz = 32, parameter ntrfs_id = 0, parameter broadcast = {8{1'b1}}) (
  input clk,
  input reset,
  input [pckg_sz-1:0] D_in,
  input bs_grnt,
  input pndng,
  inout bs_bsy,
  output bs_rqst,
  output rst_w,
  output rst_r,
  output p_s_w,
  output p_s_r,
  output en_w,
  output en_r,
  output push,
  output pop
  );
    wire [$clog2(pckg_sz):0] count_w;
    wire [$clog2(pckg_sz):0] count_r;
    wire [1:0] s_ds_r;
    wire [1:0] s_ds_w;
    reg cond_r;
    reg cond_w;
    wire rst_cntr_w;
    wire rst_cntr_r;
    wire rdi;
    wire clk_cntr_w = en_w && clk;
    wire clk_cntr_r = en_r && clk;
    wire cnt_eq_w = (count_w == pckg_sz)?{1'b1}:{1'b0};
    wire s_cmp;
    reg rd_cmp_out;
    reg bdcst;
    wire bs_bsy_pre;
    localparam aux = (pckg_sz > 256)?$clog2(pckg_sz)-1:7;
    reg [aux:0]  rd_cmp_a;
    reg [aux:0]  rd_cmp_b;

    always @(*) begin
       rd_cmp_a = (s_cmp)?count_r:D_in[pckg_sz-1:pckg_sz-8];
       rd_cmp_b = (s_cmp)?pckg_sz-1:ntrfs_id;
 
     rd_cmp_out = (rd_cmp_a == rd_cmp_b)?{1'b1}:{1'b0};   
     bdcst = (D_in[pckg_sz-1:pckg_sz-8]=={8{1'b1}})?{1'b1}:{1'b0};

    case(s_ds_r)
       2'b00:  cond_r = ~bs_grnt && bs_bsy;
       2'b01:  cond_r = rd_cmp_out || bdcst;
       2'b10:  cond_r = rd_cmp_out;
       default:  cond_r = 0;
    endcase

   case(s_ds_w)
       2'b00:  cond_w = bs_grnt && rdi;
       2'b01:  cond_w = cnt_eq_w;
       2'b10:  cond_w = pndng;
       default: cond_w = 0;
    endcase
    
//     bs_bsy_aux = (bs_grnt)?bs_bsy_pre:{1'bz};
end
    tri_buf bs_bsy_tri_buf (bs_bsy_pre,bs_bsy,bs_grnt);
    Counter #(pckg_sz*2) counter_w (.count(count_w), .clk(clk_cntr_w), .rst(rst_cntr_w));
    Counter #(pckg_sz*2) counter_r (.count(count_r), .clk(clk_cntr_r), .rst(rst_cntr_r));
  
    Read_st_Mchn rdstmchn (.condition_r(cond_r),
                           .rdi(rdi),
                           .reset(reset),
                           .clk(clk),
                           .s_ds_r(s_ds_r),
                           .s_cmp(s_cmp),
                           .rst_cntr_r(rst_cntr_r),
                           .rst_r(rst_r),
                           .p_s_r(p_s_r),
                           .en_r(en_r),
                           .push(push));

   Write_st_Mchn wtstmchn (.clk(clk),
                           .reset(reset),
                           .condition_w(cond_w),
                           .bs_bsy(bs_bsy_pre),
                           .bs_rqst(bs_rqst),
                           .s_ds_w(s_ds_w),
                           .rst_cntr_w(rst_cntr_w),
                           .rst_w(rst_w),
                           .p_s_w(p_s_w),
                           .en_w(en_w),
                           .pop(pop));
endmodule


//////////////////////////////////////////////////////////////////////////////
// Definition of a signle bus Interface 
/////////////////////////////////////////////////////////////////////////////

module bs_ntrfs #(parameter pckg_sz = 32, parameter ntrfs_id = 0, parameter broadcast = {8{1'b1}}) (
  input clk,
  input reset,
  input bs_grnt,
  input pndng,
  input [pckg_sz-1:0] D_pop,
  output [pckg_sz-1:0] D_push,
  output push,
  output pop,
  output bs_rqst,
  inout bus,
  inout bs_bsy
);

  wire clk_rd;
  wire clk_wt;
  wire en_r;
  wire en_w;
  assign clk_rd = clk && en_r;
  assign clk_wt = clk && en_w;
  wire rst_r;
  wire rst_w;
  wire p_s_w;
  wire p_s_r;
  wire bus_pre_wd;
  assign bus = (bs_grnt)?bus_pre_wd:1'bz;

  ntrfs_cntrl #(pckg_sz,ntrfs_id,broadcast) cntrl(
   .clk(clk),
   .reset(reset),
   .D_in(D_push),
   .bs_grnt(bs_grnt),
   .pndng(pndng),
   .bs_bsy(bs_bsy),
   .bs_rqst(bs_rqst),
   .rst_w(rst_w),
   .rst_r(rst_r),
   .p_s_w(p_s_w),
   .p_s_r(p_s_r),
   .en_w(en_w),
   .en_r(en_r),
   .push(push),
   .pop(pop)
  );

serializer #(pckg_sz) srlzr_wt(
   .sel_p_s(p_s_w),
   .s_in({1'b0}),
   .rst(rst_w),
   .clk(clk_wt),
   .P_in(D_pop),
   .s_out(bus_pre_wd),
   .P_out()
  );
serializer #(pckg_sz) srlzr_rd(
   .sel_p_s(p_s_r),
   .s_in(bus),
   .rst(rst_r),
   .clk(clk_rd),
   .P_in({pckg_sz{1'b0}}),
   .s_out(),
   .P_out(D_push)
  );
endmodule

///////////////////////////////////////////////////////////////////////
// Definition of an in order counter from 0 to a parametrized number //
// The difference from the module Counter is that this one will stop //
// at m-1 and reset to 0 while the other will keep counting until the//
// count bits overflow                                               //
///////////////////////////////////////////////////////////////////////

module Counter_arb#(parameter mx_cnt = 32) (count, clk, rst);
  output reg [$clog2(mx_cnt)-1:0] count;
  input clk;
  input rst;

 
     always @(posedge clk or posedge rst)begin
       if (rst)begin
           count <= 0;
       end else begin
         if(count == mx_cnt-1)begin
           count <= 0;
         end else begin
           count <= count + 1;
         end
       end
     end
endmodule


///////////////////////////////////////////////////////////////////////
// Definition of the Arbiter block 
///////////////////////////////////////////////////////////////////////

module Arbiter#(parameter M = 4)(
 input reset,
 input clk,
 input [M-1:0] bs_rqst,
 output reg  [M-1:0] bs_grnt,
 output reg bs_bsy
);

  wire [$clog2(M)-1:0] count;
  reg cntr_clk;
  reg cntr_clk_en;
  reg rqst_xst;
  reg [M-1:0] bs_rqst_flg;

  Counter_arb #(M) cntr_arb (.count(count), .clk(cntr_clk), .rst(reset));

//int i =0;
  genvar i;
  generate
//    for(i=0;i<M; i=i+1)
//    begin// : _bit
//      always @(*)
//      begin
      for(i=0;i<M; i=i+1)begin:_nu_
         always@(*)begin
         bs_rqst_flg[i] = (i == count)?{1'b1}:{1'b0};
         bs_grnt[i] = bs_rqst_flg[i] && bs_rqst[i];
      end
      end    
//    end
  endgenerate

  always @(*)
  begin
     rqst_xst <= (bs_rqst == 0)?{1'b0}:{1'b1};
     cntr_clk_en <= (bs_grnt == 0 )?{1'b1}:{1'b0}; 
     bs_bsy <=(bs_grnt == 0)?{1'b0}:{1'bz};
     cntr_clk <= clk && cntr_clk_en && rqst_xst;
  end
endmodule


///////////////////////////////////////////////////////////////////////
// Definition of the Top Bus System 
///////////////////////////////////////////////////////////////////////

module bs_gnrtr #(parameter drvrs = 4, parameter pckg_sz = 16, parameter broadcast = {8{1'b1}}) (
  input clk,
  input reset,
  input [drvrs-1:0] pndng,
  output [drvrs-1:0] push,
  output [drvrs-1:0] pop,
  input [drvrs-1:0][pckg_sz-1:0] D_pop,
  output [drvrs-1:0][pckg_sz-1:0] D_push
);
  wire bus;
  wire bs_bsy;
  wire [drvrs-1:0] bs_rqst;
  wire [drvrs-1:0] bs_grnt;
  
  genvar i;
  generate
    for (i=0; i < drvrs; i=i+1)
    begin: ID
      bs_ntrfs #(pckg_sz,i,broadcast) ntrfs (
        .clk(clk),
        .reset(reset),
        .bs_grnt(bs_grnt[i]),
        . pndng(pndng[i]),
        .D_pop(D_pop[i]),
        .D_push(D_push[i]),
        .push(push[i]),
        .pop(pop[i]),
        .bs_rqst(bs_rqst[i]),
        .bus(bus),
        .bs_bsy(bs_bsy)
      );
    end
  endgenerate
 
  Arbiter#(drvrs) arb_inst (.reset(reset),.clk(clk),.bs_rqst(bs_rqst),.bs_grnt(bs_grnt),.bs_bsy(bs_bsy));
endmodule


///////////////////////////////////////////////////////////////////////
// Libraries intendedn for the version of the bus with no central arbiter
// n_rbtr 
///////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// Definition of the arbiter state machine
///////////////////////////////////////////////////////////////////////////////

module  Arbiter_st_Mchn(
  input clk,
  input reset,
  input condition_a,
  output trn_chng_nthng_t_snd 
  );
 
  //state registers
  reg  nxt_st;
  
  dff_async_rst st0(.data(nxt_st),.clk(clk),.reset(reset),.q(trn_chng_nthng_t_snd));

  //nextstate decoder
   always@(*) begin 
     case ({trn_chng_nthng_t_snd,condition_a})
      2'b00:  nxt_st = 1'b0;
      2'b01:  nxt_st = 1'b1;
      2'b10:  nxt_st = 1'b0;
      2'b11:  nxt_st = 1'b0;
     endcase
   end
endmodule

//////////////////////////////////////////////////////////////////////////////
// Definition of Control block for the Bus controller no central arbiter
// version 
/////////////////////////////////////////////////////////////////////////////

module ntrfs_cntrl_n_rbtr #(parameter pckg_sz = 32, 
                            parameter ntrfs_id = 0, 
                            parameter broadcast = {8{1'b1}},
                            parameter drvrs = 4) (
  input clk,
  input reset,
  input [pckg_sz-1:pckg_sz-8] D_in,
  output  bs_grnt,
  input pndng,
  inout  bs_bsy,
  inout trn_chng,
  output rst_w,
  output rst_r,
  output p_s_w,
  output p_s_r,
  output en_w,
  output en_r,
  output push,
  output pop
  );
    wire bs_rqst;
    reg trn_chng_pre;
    wire [$clog2(drvrs)-1:0] cnt_rbtr;
    wire [$clog2(pckg_sz):0] count_w;
    wire [$clog2(pckg_sz):0] count_r;
    wire [1:0] s_ds_r;
    wire [1:0] s_ds_w;
    reg cond_r;
    reg cond_w;
    wire rst_cntr_w;
    wire rst_cntr_r;
    wire rdi;
    wire clk_cntr_w = en_w && clk;
    wire clk_cntr_r = en_r && clk;
    wire cnt_eq_w = (count_w == pckg_sz)?{1'b1}:{1'b0};
    wire s_cmp;
    reg rd_cmp_out;
    reg bdcst;
    wire bs_bsy_pre;
    localparam aux = (pckg_sz > 256)?$clog2(pckg_sz)-1:7;
    reg [aux:0]  rd_cmp_a;
    reg [aux:0]  rd_cmp_b;
    reg c_a;    
    wire trn_chng_nthng_t_snd;
    reg bs_grnt_pre;

    always @(posedge clk)begin
      bs_grnt_pre = (cnt_rbtr == ntrfs_id)?{1'b1}:{1'b0};
    end
    
   dff_async_rst bs_grnt_dly(.data(bs_grnt_pre),.clk(clk),.reset(reset),.q(bs_grnt));

    always @(*) begin
       trn_chng_pre = rst_w|| trn_chng_nthng_t_snd;
       c_a = bs_grnt && ~bs_rqst;
       rd_cmp_a = (s_cmp)?count_r:D_in[pckg_sz-1:pckg_sz-8];
       rd_cmp_b = (s_cmp)?pckg_sz-1:ntrfs_id;
 
     rd_cmp_out = (rd_cmp_a == rd_cmp_b)?{1'b1}:{1'b0};   
     bdcst = (D_in[pckg_sz-1:pckg_sz-8]=={8{1'b1}})?{1'b1}:{1'b0};

    case(s_ds_r)
       2'b00:  cond_r = ~bs_grnt && bs_bsy;
       2'b01:  cond_r = rd_cmp_out || bdcst;
       2'b10:  cond_r = rd_cmp_out;
       default:  cond_r = 0;
    endcase

   case(s_ds_w)
       2'b00:  cond_w = bs_grnt && rdi;
       2'b01:  cond_w = cnt_eq_w;
       2'b10:  cond_w = pndng;
       default:  cond_w = 0;
    endcase
    
   //  bs_bsy_aux = (bs_grnt)?bs_bsy_pre:{1'bz};
   end
    tri_buf bs_bsy_tri_buf(.a(bs_bsy_pre),.b(bs_bsy),.en(bs_grnt));

    Counter_arb#(drvrs) arb_cntr(.count(cnt_rbtr),.clk(trn_chng),.rst(reset));
    Arbiter_st_Mchn arb_st_mchn (.clk(clk),.reset(reset),.condition_a(c_a),.trn_chng_nthng_t_snd(trn_chng_nthng_t_snd));
    Counter #(pckg_sz*2) counter_w (.count(count_w), .clk(clk_cntr_w), .rst(rst_cntr_w));
    Counter #(pckg_sz*2) counter_r (.count(count_r), .clk(clk_cntr_r), .rst(rst_cntr_r));
    tri_buf buf_trn_chng(.a(trn_chng_pre),.b(trn_chng),.en(bs_grnt));
  
    Read_st_Mchn rdstmchn (.condition_r(cond_r),
                           .rdi(rdi),
                           .reset(reset),
                           .clk(clk),
                           .s_ds_r(s_ds_r),
                           .s_cmp(s_cmp),
                           .rst_cntr_r(rst_cntr_r),
                           .rst_r(rst_r),
                           .p_s_r(p_s_r),
                           .en_r(en_r),
                           .push(push));

   Write_st_Mchn wtstmchn (.clk(clk),
                           .reset(reset),
                           .condition_w(cond_w),
                           .bs_bsy(bs_bsy_pre),
                           .bs_rqst(bs_rqst),
                           .s_ds_w(s_ds_w),
                           .rst_cntr_w(rst_cntr_w),
                           .rst_w(rst_w),
                           .p_s_w(p_s_w),
                           .en_w(en_w),
                           .pop(pop));
endmodule
//////////////////////////////////////////////////////////////////////////////
// Definition of a signle bus Interface No central arbiter version n_rbtr 
/////////////////////////////////////////////////////////////////////////////

module bs_ntrfs_n_rbtr #(parameter pckg_sz = 32, parameter ntrfs_id = 0, parameter broadcast = {8{1'b1}},parameter drvrs = 4)(
  input clk,
  input reset,
  input pndng,
  input [pckg_sz-1:0] D_pop,
  output [pckg_sz-1:0] D_push,
  output push,
  output pop,
  inout bus,
  inout bs_bsy,
  inout trn_chng
);
  wire bs_grnt;
  wire clk_rd;
  wire clk_wt;
  wire en_r;
  wire en_w;
  assign clk_rd = clk && en_r;
  assign clk_wt = clk && en_w;
  wire rst_r;
  wire rst_w;
  wire p_s_w;
  wire p_s_r;
  wire bus_pre_wd;
  assign bus = (bs_grnt)?bus_pre_wd:1'bz;

  ntrfs_cntrl_n_rbtr #(pckg_sz,ntrfs_id,broadcast,drvrs) cntrl(
   .clk(clk),
   .reset(reset),
   .D_in(D_push[pckg_sz-1:pckg_sz-8]),
   .bs_grnt(bs_grnt),
   .pndng(pndng),
   .bs_bsy(bs_bsy),
   .trn_chng(trn_chng),
   .rst_w(rst_w),
   .rst_r(rst_r),
   .p_s_w(p_s_w),
   .p_s_r(p_s_r),
   .en_w(en_w),
   .en_r(en_r),
   .push(push),
   .pop(pop)
  );

serializer #(pckg_sz) srlzr_wt(
   .sel_p_s(p_s_w),
   .s_in({1'b0}),
   .rst(rst_w),
   .clk(clk_wt),
   .P_in(D_pop),
   .s_out(bus_pre_wd),
   .P_out()
  );
serializer #(pckg_sz) srlzr_rd(
   .sel_p_s(p_s_r),
   .s_in(bus),
   .rst(rst_r),
   .clk(clk_rd),
   .P_in({pckg_sz{1'b0}}),
   .s_out(),
   .P_out(D_push)
  );
endmodule

///////////////////////////////////////////////////////////////////////
// Definition of the Top Bus System 
///////////////////////////////////////////////////////////////////////

module bs_gnrtr_n_rbtr #(parameter bits = 1,parameter drvrs = 4, parameter pckg_sz = 16, parameter broadcast = {8{1'b1}}) (
  input clk,
  input reset,
  input  pndng[bits-1:0][drvrs-1:0],
  output push[bits-1:0][drvrs-1:0],
  output pop[bits-1:0][drvrs-1:0],
  input  [pckg_sz-1:0] D_pop[bits-1:0][drvrs-1:0],
  output [pckg_sz-1:0] D_push[bits-1:0][drvrs-1:0]
);
  wire bus[bits-1:0];
  wire bs_bsy[bits-1:0];
  wire trn_chng[bits-1:0];
  
  genvar b;
  genvar i;
  generate
    for(b=0; b < bits; b=b+1)
    begin: BUS
      for (i=0; i < drvrs; i=i+1)
      begin: ID
        bs_ntrfs_n_rbtr #(pckg_sz,i,broadcast,drvrs) ntrfs (
          .clk(clk),
          .reset(reset),
          .pndng(pndng[b][i]),
          .D_pop(D_pop[b][i]),
          .D_push(D_push[b][i]),
          .push(push[b][i]),
          .pop(pop[b][i]),
          .bus(bus[b]),
          .trn_chng(trn_chng[b]),
          .bs_bsy(bs_bsy[b])
        );
      end
    end
  endgenerate
endmodule

///////////////////////////////////////////////////////////////////////
// Definition of a parallel bus 
///////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////
// Definition of a simple parallel n bits bus 
///////////////////////////////////////////////////////////////////////

module prll_rgstr #(parameter bits =32) (
  input clk,
  input [bits-1:0] D,
  input reset,
  output [bits-1:0] Q
);
  genvar i;
  generate
    for(i = 0 ;i < bits;i = i+1) begin: bit_
      dff_async_rst flop (.data(D[i]),.clk(clk),.reset(reset),.q(Q[i])); 
    end
  endgenerate
endmodule

///////////////////////////////////////////////////////////////////////
// Definition of the control state machine for the read of the parallel
// interfase 
///////////////////////////////////////////////////////////////////////

module prll_rd_st_mchn (
  input c_r,
  input reset,
  input clk,
  output reg rst_r,
  output reg push,
  output reg rdi,
  output reg s_ds_r
);
  wire [2:0] st; 
  reg [2:0] ft_st;

  dff_async_rst st_flop_0 (.data(ft_st[0]),.clk(clk),.reset(reset),.q(st[0]));
  dff_async_rst st_flop_1 (.data(ft_st[1]),.clk(clk),.reset(reset),.q(st[1]));
  dff_async_rst st_flop_2 (.data(ft_st[2]),.clk(clk),.reset(reset),.q(st[2]));
 
  always@(*)begin
    case({st,c_r})
      4'b0000: ft_st = {3'b001};
      4'b0001: ft_st = {3'b001};
      4'b0010: ft_st = {3'b001};
      4'b0011: ft_st = {3'b011};
      4'b0110: ft_st = {3'b010};
      4'b0111: ft_st = {3'b111};
      4'b1110: ft_st = {3'b000};
      4'b1111: ft_st = {3'b000};
      4'b0100: ft_st = {3'b000};
      4'b0101: ft_st = {3'b000};
      default: ft_st = {3'b000};
    endcase
    
    push = (st==7)?{1'b1}:{1'b0};
    rst_r = (st==0)?{1'b1}:{1'b0};
    rdi = (st==1)?{1'b1}:{1'b0};
    s_ds_r = (st==3)?{1'b1}:{1'b0};
    
  end
endmodule

///////////////////////////////////////////////////////////////////////
// Definition of the control state machine for the write of the parallel
// interfase 
///////////////////////////////////////////////////////////////////////

module prll_wt_st_mchn (
  input c_w,
  input reset,
  input clk,
  output reg rst_w,
  output reg pop,
  output reg wrt_pre,
  output reg s_ds_w,
  output reg bs_rqst,
  output reg ld_w
);
  wire [2:0] st; 
  wire c_r;
  reg [2:0] ft_st;

  dff_async_rst st_flop_0 (.data(ft_st[0]),.clk(clk),.reset(reset),.q(st[0]));
  dff_async_rst st_flop_1 (.data(ft_st[1]),.clk(clk),.reset(reset),.q(st[1]));
  dff_async_rst st_flop_2 (.data(ft_st[2]),.clk(clk),.reset(reset),.q(st[2]));
 
  always@(*)begin
    case({st,c_w})
      4'b0000: ft_st = {3'b001};
      4'b0001: ft_st = {3'b001};
      4'b0010: ft_st = {3'b001};
      4'b0011: ft_st = {3'b011};
      4'b0110: ft_st = {3'b111};
      4'b0111: ft_st = {3'b111};
      4'b1110: ft_st = {3'b101};
      4'b1111: ft_st = {3'b101};
      4'b1010: ft_st = {3'b101};
      4'b1011: ft_st = {3'b100};
      4'b1000: ft_st = {3'b000};
      4'b1001: ft_st = {3'b000};
      default: ft_st = {3'b000};
    endcase
    
    pop = (st==7)?{1'b1}:{1'b0};
    rst_w = (st==0)?{1'b1}:{1'b0};
    s_ds_w = (st==1)?{1'b1}:{1'b0};
    wrt_pre = (st==4)?{1'b1}:{1'b0};
    bs_rqst = ((st==4)||(st==5)||(st==7))?{1'b1}:{1'b0};
    ld_w = (st==3)?{1'b1}:{1'b0};
    
  end
endmodule

///////////////////////////////////////////////////////////////////////
// Definition of the control interfase for the prll bus 
///////////////////////////////////////////////////////////////////////

module prll_intrfs_cntrl #(parameter id = 0, parameter bdcst = 255, parameter drvrs = 4) (
  input clk,
  input reset,
  input [7:0] D_in,
  input pndng,
  output ld_w,
  output rst_w,
  output rst_r,
  output bs_grnt,
  output push,
  output pop,
  inout trn_chng,
  inout wrt
);
  reg c_r;
  reg bs_grnt_pre;
  reg c_w;
  reg sv_flg;
  reg c_a;
  wire s_ds_r;
  wire s_ds_w;
  reg  trn_chng_pre;
  reg  wt_flg;
  reg rd_flg;
  wire trn_chng_nthng_t_snd;
  wire wrt_pre;
  wire bs_rqst;
  wire rdi;
  wire [$clog2(drvrs)-1:0] cnt_rbtr;
  
  dff_async_rst bs_grnt_dly (.data(bs_grnt_pre),.clk(clk),.reset(reset),.q(bs_grnt));
  Counter_arb#(drvrs) arb_cntr(.count(cnt_rbtr),.clk(trn_chng),.rst(reset));
  Arbiter_st_Mchn arb_st_mchn (.clk(clk),.reset(reset),.condition_a(c_a),.trn_chng_nthng_t_snd(trn_chng_nthng_t_snd));
   prll_wt_st_mchn wt_st_mchn(.c_w(c_w),.reset(reset),.clk(clk),.rst_w(rst_w),.pop(pop),.wrt_pre(wrt_pre),.s_ds_w(s_ds_w),.bs_rqst(bs_rqst),.ld_w(ld_w));
   prll_rd_st_mchn rd_st_mchn(.c_r(c_r),.reset(reset),.clk(clk),.rst_r(rst_r),.push(push),.rdi(rdi),.s_ds_r(s_ds_r));
   tri_buf trn_chng_buf(.a(trn_chng_pre),.b(trn_chng),.en(bs_grnt_pre));
   tri_buf wrt_buf(.a(wrt_pre),.b(wrt),.en(bs_grnt_pre));

  always@(*)begin
    wt_flg = rdi && bs_grnt;
    c_w = (s_ds_w)?pndng:wt_flg;
    trn_chng_pre = trn_chng_nthng_t_snd || rst_w;
    rd_flg = wrt && ~bs_grnt;
    sv_flg = ((D_in==id)||(D_in==bdcst))?{1'b1}:{1'b0};
    c_r = (s_ds_r)?sv_flg:rd_flg;
    bs_grnt_pre = (cnt_rbtr == id)?{1'b1}:{1'b0};
    c_a = bs_grnt && ~bs_rqst;
  end
endmodule


///////////////////////////////////////////////////////////////////////
// Definition of the prll bus interface 
///////////////////////////////////////////////////////////////////////

module prll_bs_ntrfs #(parameter drvrs = 4, parameter bits = 32, parameter id = 0,parameter bdcst = 255)(
  output [bits-1:0] D_push,
  input pndng,
  input clk,
  input reset,
  inout [bits-1:0] bus,
  inout trn_chng,
  inout wrt,
  output pop,
  output push,
  input [bits-1:0] D_pop
);
  wire rst_r;
  wire rst_w;
  wire ld_w;
  wire bs_grnt;
  wire [bits-1:0] bus_pre_w;
  reg ld_r;

  prll_d_reg #(bits) D_reg_rd(.clk(ld_r),.reset(rst_r),.D_in(bus),.D_out(D_push));
  prll_d_reg #(bits) D_reg_wt(.clk(ld_w),.reset(rst_w),.D_in(D_pop),.D_out(bus_pre_w));
  prll_intrfs_cntrl #(id,bdcst,drvrs) prll_cntrl(.clk(clk),
						 .reset(reset),
						 .D_in(D_push[bits-1:bits-8]),
						 .pndng(pndng),
 						 .ld_w(ld_w),
						 .rst_w(rst_w),
   						 .rst_r(rst_r),
						 .bs_grnt(bs_grnt),
						 .push(push),
						 .pop(pop),
						 .trn_chng(trn_chng),
						 .wrt(wrt));
  genvar i;
  generate
    for(i=0;i<bits;i=i+1) begin:bit_
     tri_buf bus_buf (.a(bus_pre_w[i]),.b(bus[i]),.en(bs_grnt)); 
    end
  endgenerate

  always@(*)begin
    ld_r <= ~bs_grnt && wrt;
    
  end
endmodule

///////////////////////////////////////////////////////////////////////
// Definition of the prll bus system
///////////////////////////////////////////////////////////////////////
  
module prll_bs_gnrtr_n_rbtr #(parameter buses = 1,parameter bits = 1,parameter drvrs = 4, parameter broadcast = {8{1'b1}}) (
  input clk,
  input reset,
  input  pndng[buses-1:0][drvrs-1:0],
  output push[buses-1:0][drvrs-1:0],
  output pop[buses-1:0][drvrs-1:0],
  input  [bits-1:0] D_pop[buses-1:0][drvrs-1:0],
  output [bits-1:0] D_push[buses-1:0][drvrs-1:0]
);
  wire [bits-1:0] bus[buses-1:0];
  wire trn_chng[buses-1:0];
  wire wrt[buses-1:0];
  
  genvar b;
  genvar i;
  generate
    for(b=0; b < buses; b=b+1)begin:_bus_ 
      for(i=0;i<drvrs;i=i+1)begin:ntrfs 
        prll_bs_ntrfs #(drvrs,bits,i,broadcast) prll_bus_instance (
        .D_push(D_push[b][i]),
        .pndng(pndng[b][i]),
        .clk(clk),
        .reset(reset),
        .bus(bus[b]),
        .trn_chng(trn_chng[b]),
        .wrt(wrt[b]),
        .pop(pop[b][i]),
        .push(push[b][i]),
        .D_pop(D_pop[b][i])
        );
      end
//        always@(*) begin
          assign bus[b]= reset?{bits{1'b0}}:{bits{1'bz}};
//          assign trn_chng[b] = reset?{bits{1'b0}}:{bits{1'bz}};
//          assign wrt[b] = reset?{bits{1'b0}}:{bits{1'bz}};
//        end
    end
  endgenerate
endmodule

///////////////////////////////////////////////////////////////////////
// Definition of the prll bus system with homogeneus fifos
///////////////////////////////////////////////////////////////////////
  
module prll_bs_gnrtr_n_rbtr_fifo #(parameter buses = 1,parameter bits = 1,parameter drvrs = 4, parameter broadcast = {8{1'b1}},parameter depth = 2) (
  input clk,
  input reset,
  output pndng[buses-1:0][drvrs-1:0],
  input  push[buses-1:0][drvrs-1:0],
  input  pop[buses-1:0][drvrs-1:0],
  output [bits-1:0] D_pop[buses-1:0][drvrs-1:0],
  input  [bits-1:0] D_push[buses-1:0][drvrs-1:0],
  output full_in[buses-1:0][drvrs-1:0],
  output full_out[buses-1:0][drvrs-1:0]
);
  wire  pndng_int[buses-1:0][drvrs-1:0];
  wire  push_int[buses-1:0][drvrs-1:0];
  wire  pop_int[buses-1:0][drvrs-1:0];
  wire  [bits-1:0] D_in_int [buses-1:0][drvrs-1:0];
  wire  [bits-1:0] D_out_int [buses-1:0][drvrs-1:0];

  
  genvar b;
  genvar i;
  generate
    for(b=0; b < buses; b=b+1)begin:_bus_ 
      for(i=0;i<drvrs;i=i+1)begin:ntrfs 
        fifo_flops #(.depth(depth),.bits(bits)) fifo_in(
          .Din(D_push[b][i]),
          .Dout(pop_int[b][i]),
          .push(push[b][i]),
          .pop(pop_int[b][i]),
          .full(full_in[b][i]),
          .pndng(pndng_int[b][i]),
          .rst(reset),
          .clk(clk)
        );
     
        fifo_flops #(.depth(depth),.bits(bits)) fifo_out(
          .Din(D_in_int[b][i]),
          .Dout(D_pop[b][i]),
          .push(push_int[b][i]),
          .pop(pop[b][i]),
          .full(full_out[b][i]),
          .pndng(pndng[b][i]),
          .rst(reset),
          .clk(clk)
        );
        
      end
    end
  endgenerate

   prll_bs_gnrtr_n_rbtr #(.buses(buses),.bits(bits),.drvrs(drvrs),.broadcast(broadcast)) bus_interfase (
    .clk(clk),
    .reset(reset),
    .pndng(pndng_int),
    .push(push_int),
    .pop(pop_int),
    .D_pop(D_out_int),
    .D_push(D_in_int)
  );
endmodule

