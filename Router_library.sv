`ifndef FIFOS
   `include "fifo.sv"
    `define FIFOS
`endif

`ifndef LIB
   `include "Library.sv"
    `define LIB
`endif

module conector #(parameter size = 40) (
  input  [size-1:0] in,
  output [size-1:0] out
);

  genvar i;
  generate
    for(i=0;i<size;i=i+1) begin
      buf(out[i],in[i]);
    end
  endgenerate
endmodule

module router_bus_gnrtr #(parameter pck_sz = 40, parameter num_ntrfs=4, parameter broadcast = {8{1'b1}}, parameter fifo_depth=4,parameter id_c = 0,parameter id_r = 0,parameter columns= 4, parameter rows = 4)(
  input clk,
  input reset,
  input[pck_sz-1:0] data_out_i_in[num_ntrfs-1:0],
  input pndng_i_in[num_ntrfs-1:0],
  input pop[num_ntrfs-1:0],
  output popin[num_ntrfs-1:0],
  output pndng[num_ntrfs-1:0],
  output [pck_sz-1:0] data_out[num_ntrfs-1:0]
);
  wire pop_i;
  wire push_i;
  wire [num_ntrfs-1:0]pndng_i;
  wire [pck_sz-1:0] data_out_i[num_ntrfs-1:0];
  wire [$clog2(num_ntrfs)-1:0]trn;
  wire [pck_sz-1:0] data_in_i;
  
  genvar i;
  generate
    for(i=0;i<num_ntrfs; i=i+1)begin:_nu_
      router_bus_interface #(.pck_sz(pck_sz),.num_ntrfs(num_ntrfs), .ntrfs_id(i),.broadcast(broadcast),.fifo_depth(fifo_depth),.id_c(id_c),.id_r(id_r),.rows(rows), .columns(columns)) rtr_ntrfs_ (
        .clk(clk),
        .reset(reset),
        .data_in_i(data_in_i),
        .trn(trn),
        .pop(pop[i]),
        .pop_i(pop_i),
        .push_i(push_i),
        .data_out_i(data_out_i[i]),
        .data_out_i_in(data_out_i_in[i]),
        .data_out(data_out[i]),
        .pndng(pndng[i]),
        .pndng_i(pndng_i[i]),
        .popin(popin[i]),
        .pndng_i_in(pndng_i_in[i])
    );
    end
  endgenerate
  Router_arbiter #(.num_ntrfs(num_ntrfs),.pck_sz(pck_sz)) arbitro(
  .reset(reset),
  .clk(clk),
  .pndng_i(pndng_i),
  .data_out_i(data_out_i),
  .trn(trn),
  .push_i(push_i),
  .pop_i(pop_i),
  .data_in_i(data_in_i)
);
endmodule 


module router_bus_interface #(parameter pck_sz = 40, parameter num_ntrfs=4, parameter [7:0]ntrfs_id = 0, parameter broadcast = {8{1'b1}}, parameter fifo_depth=4, parameter id_c=0,parameter id_r=0, parameter rows= 4, parameter columns=4) (
  input clk,
  input reset,
  input [pck_sz-1:0]data_in_i,
  input [$clog2(num_ntrfs)-1:0]trn,
  input pop_i,
  input push_i,
  input pop,
  output [pck_sz-1:0]data_out_i,
  input [pck_sz-1:0]data_out_i_in,
  output [pck_sz-1:0]data_out,
  output pndng,
  output pndng_i,
  output logic popin,
  input pndng_i_in
  );
  logic pre_psh;
  logic pre_pop;
  logic psh;

  fifo_flops_no_full #(.depth(fifo_depth),.bits(pck_sz))fifo_out (
    .Din(data_in_i),
    .Dout(data_out),
    .push(psh),
    .pop(pop),
    .clk(clk),
    .pndng(pndng),
    .rst(reset)
  );
  
  s_routing_table #(.id_r(id_r),.id_c(id_c),.pckg_sz(pck_sz), .rows(rows),.columns(columns)) rt (
  .Data_in(data_out_i_in),
  .Data_out_i(data_out_i)
);

`ifdef DEBUG
  always@(posedge pop) begin
    $display("ntrfs: Message send in terminal: %g router ID: %g %g at time %g", ntrfs_id,id_r,id_c,$time );
    $display("trgt_r: %g", data_out[pck_sz-9:pck_sz-12]);
    $display("trgt_c: %g", data_out[pck_sz-13:pck_sz-16]);
    $display("mode: %g",data_out[pck_sz-17]);
    $display("src: %g",data_out[pck_sz-18:pck_sz-25]);
    $display("id: %g",data_out[pck_sz-26:pck_sz-33]);
    $display("pyld: %h",data_out[pck_sz-34:0]);
  end
  always@(posedge popin) begin
    $display("ntrfs: Message received  in terminal: %g router ID: %g %g at time %g", ntrfs_id,id_r,id_c,$time );
    $display("trgt_r: %g", data_out_i_in[pck_sz-9:pck_sz-12]);
    $display("trgt_c: %g", data_out_i_in[pck_sz-13:pck_sz-16]);
    $display("mode: %g",data_out_i_in[pck_sz-17]);
    $display("src: %g",data_out_i_in[pck_sz-18:pck_sz-25]);
    $display("id: %g",data_out_i_in[pck_sz-26:pck_sz-33]);
    $display("pyld: %h",data_out_i_in[pck_sz-34:0]);
  end
`endif

  assign psh = pre_psh & push_i;
  assign popin = pre_pop & pop_i;
  assign pre_psh = ((ntrfs_id == data_in_i[pck_sz-1:pck_sz-8])|(data_in_i[pck_sz-1:pck_sz-8]== broadcast))?1:0; 
  assign pre_pop = (ntrfs_id == trn)?1:0;
  assign pndng_i = pndng_i_in;
  
endmodule

module rtr_rbtr_cntrl (
  input clk,
  input rst,
  input pndng,
  output logic cnt_en,
  output logic push_i,
  output logic pop_i
);
 reg [1:0]cur_st;
 logic [1:0]nxt_st;
 parameter rst_st = 0;
 parameter psh1_st = 1;
 parameter cnt1_st = 2;
 parameter pop1_st = 3;
 
 //lógica de siguiente estado
 always_comb begin
   case(cur_st)
     rst_st: begin
       nxt_st <= pndng?psh1_st:cnt1_st;
     end 
     psh1_st: nxt_st <= pop1_st;
     pop1_st: nxt_st <= cnt1_st;
     cnt1_st: nxt_st <= rst_st;
     default: nxt_st <= rst;
  endcase
 end
 //refrescamiento de la máquina de estados
 always@(posedge clk or posedge rst) begin
   cur_st <= rst?rst_st:nxt_st;
 end
 // lógica de salida
 always_comb begin
  case(cur_st)
    rst_st: begin
      cnt_en <= 0;
      push_i <= 0;
      pop_i <= 0;
    end
    psh1_st: begin
      cnt_en <= 0;
      push_i <= 1;
      pop_i <= 0;
    end
    pop1_st: begin
      cnt_en <= 0;
      push_i <= 0;
      pop_i <= 1;
    end
    cnt1_st: begin
      cnt_en <=1;
      push_i <= 0;
      pop_i <= 0;
    end
  endcase
 end

endmodule

module tri_buf_mux #(parameter size =8) (
    input [size-1:0]a,
    output [size-1:0]b,
    input en
);
    
   assign b = (en)?a:{size{1'bz}};
     	  	 
endmodule

module param_mux #(parameter num_slct_lns = 2, parameter pck_sz = 4) (
  input  [num_slct_lns-1:0] select,
  input  [pck_sz-1:0]input_signal[(2**num_slct_lns)-1:0],
  output [pck_sz-1:0] out
);
  logic hot_bit_slct[(2**num_slct_lns)-1:0];
  genvar i;
  generate
      for(i=0;i<(2**num_slct_lns); i=i+1)begin:_nu_
         always_comb begin
           hot_bit_slct[i] <= (i == select)?{1'b1}:{1'b0};
         end
           tri_buf_mux #(.size(pck_sz)) buf_select (.a(input_signal[i]),.b(out),.en(hot_bit_slct[i])); 
      end    
  endgenerate
endmodule

module param_mux_single_bit #(parameter num_slct_lns = 2) (
  input  [num_slct_lns-1:0] select,
  input  [(2**num_slct_lns)-1:0]input_signal,
  output out
);
  logic hot_bit_slct[(2**num_slct_lns)-1:0];
  genvar i;
  generate
      for(i=0;i<(2**num_slct_lns); i=i+1)begin:_nu_
         always_comb begin
           hot_bit_slct[i] <= (i == select)?{1'b1}:{1'b0};
         end
           tri_buf buf_select (.a(input_signal[i]),.b(out),.en(hot_bit_slct[i])); 
      end    
  endgenerate
endmodule

module Router_arbiter #(parameter num_ntrfs=4, parameter pck_sz = 32) (
  input reset,
  input clk,
  input [num_ntrfs-1:0]pndng_i,
  input [pck_sz-1:0]data_out_i[num_ntrfs-1:0],
  output [$clog2(num_ntrfs)-1:0]trn,
  output push_i,
  output pop_i,
  output [pck_sz-1:0]data_in_i
);
  logic clk_cntr;
  logic clk_rtr_rbtr_cntrl;
  logic clk_en;
  logic cnt_en;
  wire pndng;

Counter_arb #(.mx_cnt(num_ntrfs)) contador(
  .count(trn), 
  .clk(clk_cntr), 
  .rst(reset)
 );

  always_comb begin
    clk_cntr <= clk_rtr_rbtr_cntrl & cnt_en;
    clk_rtr_rbtr_cntrl <= clk & clk_en;
    clk_en <= (pndng_i == 0)?0:1;
  end

 
param_mux_single_bit #(.num_slct_lns($clog2(num_ntrfs))) pndng_mx(
 .select(trn),
 .input_signal(pndng_i),
 .out(pndng)
);

param_mux #(.num_slct_lns($clog2(num_ntrfs)),.pck_sz(pck_sz)) data_mx(
 .select(trn),
 .input_signal(data_out_i),
 .out(data_in_i)
);
  
rtr_rbtr_cntrl arbitro (
  .clk(clk_rtr_rbtr_cntrl),
  .rst(reset),
  .pndng(pndng),
  .cnt_en(cnt_en),
  .push_i(push_i),
  .pop_i(pop_i)
);
endmodule

module s_routing_table #(parameter id_r =0, parameter id_c = 0, parameter pckg_sz =32, parameter columns=4, parameter rows=4) (
  input [pckg_sz-1:0] Data_in,
  output logic [pckg_sz-1:0] Data_out_i
);
  always_comb begin
    Data_out_i[pckg_sz-9:0] <= Data_in[pckg_sz-9:0];
    if((id_r != rows)&(id_r != 1)&(id_c != columns)&(id_c != 1)) begin // si se trata de un router que no está en el marco limítrofe
      if(Data_in[pckg_sz-17]) begin //si el modo es 1 entonces rutea primero fila
        if(Data_in[pckg_sz-9:pckg_sz-12] < id_r) begin
          Data_out_i[pckg_sz-1:pckg_sz-8] <= 8'd0;
        end
        if(Data_in[pckg_sz-9: pckg_sz-12] > id_r) begin
          Data_out_i[pckg_sz-1:pckg_sz-8] <= 8'd2;
        end
        if(Data_in[pckg_sz-9: pckg_sz-12] == id_r) begin
          if(Data_in[pckg_sz-13: pckg_sz-16] < id_c) begin
            Data_out_i[pckg_sz-1:pckg_sz-8] <= 8'd3;
          end
          if(Data_in[pckg_sz-13: pckg_sz-16] > id_c) begin
            Data_out_i[pckg_sz-1:pckg_sz-8] <= 8'd1;
          end
          if(Data_in[pckg_sz-13: pckg_sz-16]== id_c) begin
            Data_out_i[pckg_sz-1:pckg_sz-8] <= 8'd4;
          end
        end
      end else begin // si el modo es 0 rutea primero columna
        if(Data_in[pckg_sz-13: pckg_sz-16] < id_c) begin
          Data_out_i[pckg_sz-1:pckg_sz-8] <= 8'd3;
        end
        if(Data_in[pckg_sz-13: pckg_sz-16] > id_c) begin
          Data_out_i[pckg_sz-1:pckg_sz-8] <= 8'd1;
        end
        if(Data_in[pckg_sz-13: pckg_sz-16] == id_c) begin
          if(Data_in[pckg_sz-9: pckg_sz-12] < id_r) begin
            Data_out_i[pckg_sz-1:pckg_sz-8] <= 8'd0;
          end
          if(Data_in[pckg_sz-9: pckg_sz-12] > id_r) begin
            Data_out_i[pckg_sz-1:pckg_sz-8] <= 8'd2;
          end
          if(Data_in[pckg_sz-9: pckg_sz-12] == id_r) begin
            Data_out_i[pckg_sz-1:pckg_sz-8] <= 8'd4;
          end
        end
      end
    end else begin // si se trata de un router que está en el marco limítrofe
      if(((Data_in[pckg_sz-9:pckg_sz-12] < id_r)&(id_r == 1))| 
         ((Data_in[pckg_sz-9:pckg_sz-12] > id_r)&(id_r == rows))| 
         ((Data_in[pckg_sz-13:pckg_sz-16] < id_c)&(id_c == 1))| 
         ((Data_in[pckg_sz-13:pckg_sz-16] > id_c)&(id_c == columns))) begin // si es un caso de salida del mesh

        if((Data_in[pckg_sz-9:pckg_sz-12] < id_r)&(id_r == 1)) begin // si está en el borde superior y la fila es menor
          if(Data_in[pckg_sz-13: pckg_sz-16] == id_c) begin // si está en la columna correcta
            Data_out_i[pckg_sz-1:pckg_sz-8] <= 8'd0;
          end
          if(Data_in[pckg_sz-13: pckg_sz-16] < id_c)begin // si está en una columna mayor
            Data_out_i[pckg_sz-1:pckg_sz-8] <= 8'd3;
          end
          if(Data_in[pckg_sz-13: pckg_sz-16] > id_c)begin // si está en una columna menor
            Data_out_i[pckg_sz-1:pckg_sz-8] <= 8'd1;
          end
        end
        if((Data_in[pckg_sz-9:pckg_sz-12] > id_r)&(id_r == rows)) begin // si está en el borde inferior y la fila es mayor
          if(Data_in[pckg_sz-13: pckg_sz-16] == id_c) begin // si está en la columna correcta
            Data_out_i[pckg_sz-1:pckg_sz-8] <= 8'd2;
          end
          if(Data_in[pckg_sz-13: pckg_sz-16] < id_c)begin // si está en una columna mayor
            Data_out_i[pckg_sz-1:pckg_sz-8] <= 8'd3;
          end
          if(Data_in[pckg_sz-13: pckg_sz-16] > id_c)begin // si está en una columna menor
            Data_out_i[pckg_sz-1:pckg_sz-8] <= 8'd1;
          end
        end
        if((Data_in[pckg_sz-13:pckg_sz-16] < id_c)&(id_c == 1)) begin // si está en el borde izquierdo y la columna es menor
          if(Data_in[pckg_sz-9: pckg_sz-12] == id_r) begin // si está en la fila correcta
            Data_out_i[pckg_sz-1:pckg_sz-8] <= 8'd3;
          end
          if(Data_in[pckg_sz-9: pckg_sz-12] < id_r)begin // si está en una fila mayor
            Data_out_i[pckg_sz-1:pckg_sz-8] <= 8'd0;
          end
          if(Data_in[pckg_sz-9: pckg_sz-12] > id_r)begin // si está en una fila menor
            Data_out_i[pckg_sz-1:pckg_sz-8] <= 8'd2;
          end
        end
        if((Data_in[pckg_sz-13:pckg_sz-16] > id_c)&(id_c == columns)) begin // si está en el borde derecho y la columna es mayor
          if(Data_in[pckg_sz-9: pckg_sz-12] == id_r) begin // si está en la fila correcta
            Data_out_i[pckg_sz-1:pckg_sz-8] <= 8'd1;
          end
          if(Data_in[pckg_sz-9: pckg_sz-12] < id_r)begin // si está en una fila mayor
            Data_out_i[pckg_sz-1:pckg_sz-8] <= 8'd0;
          end
          if(Data_in[pckg_sz-9: pckg_sz-12] > id_r)begin // si está en una fila menor
            Data_out_i[pckg_sz-1:pckg_sz-8] <= 8'd2;
          end
        end
      end else begin // si no es un caso de salida
        if(Data_in[pckg_sz-17]) begin //si el modo es 1 entonces rutea primero fila
          if(Data_in[pckg_sz-9:pckg_sz-12] < id_r) begin
            Data_out_i[pckg_sz-1:pckg_sz-8] <= 8'd0;
          end
          if(Data_in[pckg_sz-9: pckg_sz-12] > id_r) begin
            Data_out_i[pckg_sz-1:pckg_sz-8] <= 8'd2;
          end
          if(Data_in[pckg_sz-9: pckg_sz-12] == id_r) begin
            if(Data_in[pckg_sz-13: pckg_sz-16] < id_c) begin
              Data_out_i[pckg_sz-1:pckg_sz-8] <= 8'd3;
            end
            if(Data_in[pckg_sz-13: pckg_sz-16] > id_c) begin
              Data_out_i[pckg_sz-1:pckg_sz-8] <= 8'd1;
            end
            if(Data_in[pckg_sz-13: pckg_sz-16]== id_c) begin
              Data_out_i[pckg_sz-1:pckg_sz-8] <= 8'd4;
            end
          end
        end else begin // si el modo es 0 rutea primero columna
          if(Data_in[pckg_sz-13: pckg_sz-16] < id_c) begin
            Data_out_i[pckg_sz-1:pckg_sz-8] <= 8'd3;
          end
          if(Data_in[pckg_sz-13: pckg_sz-16] > id_c) begin
            Data_out_i[pckg_sz-1:pckg_sz-8] <= 8'd1;
          end
          if(Data_in[pckg_sz-13: pckg_sz-16] == id_c) begin
            if(Data_in[pckg_sz-9: pckg_sz-12] < id_r) begin
              Data_out_i[pckg_sz-1:pckg_sz-8] <= 8'd0;
            end
            if(Data_in[pckg_sz-9: pckg_sz-12] > id_r) begin
              Data_out_i[pckg_sz-1:pckg_sz-8] <= 8'd2;
            end
            if(Data_in[pckg_sz-9: pckg_sz-12] == id_r) begin
              Data_out_i[pckg_sz-1:pckg_sz-8] <= 8'd4;
            end
          end
        end
      end
    end 
  end 
endmodule

module mesh_gnrtr #(parameter ROWS = 4, parameter COLUMS =4, parameter pckg_sz =40, parameter fifo_depth = 4, parameter bdcst= {8{1'b1}})(
  output logic pndng[ROWS*2+COLUMS*2],
  output [pckg_sz-1:0] data_out[ROWS*2+COLUMS*2],
  output logic popin[ROWS*2+COLUMS*2],
  input pop[ROWS*2+COLUMS*2],
  input [pckg_sz-1:0]data_out_i_in[ROWS*2+COLUMS*2],
  input pndng_i_in[ROWS*2+COLUMS*2],
  input clk,
  input reset
);
// vertical connections (not including connections to agents) 
  wire pndng_ver_2_0 [ROWS-1][COLUMS];
  wire [pckg_sz-1:0] data_out_ver_2_0 [ROWS-1][COLUMS];
  wire pop_ver_2_0 [ROWS-1][COLUMS];
  wire popin_ver_2_0 [ROWS-1][COLUMS];

  wire pndng_ver_0_2 [ROWS-1][COLUMS];
  wire [pckg_sz-1:0] data_out_ver_0_2 [ROWS-1][COLUMS];
  wire pop_ver_0_2 [ROWS-1][COLUMS];
  wire popin_ver_0_2 [ROWS-1][COLUMS];
// horizontal connections (not including connections to agents) 
  wire pndng_hor_1_3 [ROWS][COLUMS-1];
  wire [pckg_sz-1:0] data_out_hor_1_3 [ROWS][COLUMS-1];
  wire pop_hor_1_3 [ROWS][COLUMS-1];
  wire popin_hor_1_3 [ROWS][COLUMS-1];

  wire pndng_hor_3_1 [ROWS][COLUMS-1];
  wire [pckg_sz-1:0] data_out_hor_3_1 [ROWS][COLUMS-1];
  wire pop_hor_3_1 [ROWS][COLUMS-1];
  wire popin_hor_3_1 [ROWS][COLUMS-1];
 
  genvar R, C;
  generate
    for(R=1;R <= ROWS; R=R+1)begin:_rw_
      for(C=1;C <= COLUMS; C=C+1)begin:_clm_
        wire [pckg_sz-1:0] data_out_connected[3:0];
        wire [pckg_sz-1:0]data_out_i_in_connected [3:0];
        wire pndng_i_in_connected[3:0];
        wire pndng_connected[3:0];
        wire pop_connected[3:0];
        wire popin_connected[3:0];
        if(R == 1) begin
          if(C == 1) begin //upper left corner
              //UP
              conector #(.size(pckg_sz)) buf_data_out_0 (.out(data_out[0]),.in(data_out_connected[0]));
              conector #(.size(1)) buf_pndng_0 (.out(pndng[0]),.in(pndng_connected[0]));
              conector #(.size(1)) buf_popin_0 (.out(popin[0]),.in(popin_connected[0]));

              conector #(.size(1)) buf_pop_0 (.out(pop_connected[0]),.in(pop[0]));
              conector #(.size(pckg_sz)) buf_data_out_i_in_0 (.out(data_out_i_in_connected[0]),.in(data_out_i_in[0]));
              conector #(.size(1)) buf_pndng_i_in_0 (.out(pndng_i_in_connected[0]),.in(pndng_i_in[0]));
              //LEFT
              conector #(.size(pckg_sz)) buf_data_out_3 (.out(data_out[COLUMS]),.in( data_out_connected[3]));
              conector #(.size(1)) buf_pndng_3 (.out(pndng[COLUMS]),.in(pndng_connected[3]));
              conector #(.size(1)) buf_popin_3 (.out(popin[COLUMS]),.in(popin_connected[3]));

              conector #(.size(1)) buf_pop_3 (.out(pop_connected[3]),.in(pop[COLUMS]));
              conector #(.size(pckg_sz)) buf_data_out_i_in_3 (.out(data_out_i_in_connected[3]),.in(data_out_i_in[COLUMS]));
              conector #(.size(1)) buf_pndng_i_in_3 (.out(pndng_i_in_connected[3]),.in(pndng_i_in[COLUMS]));
              //RIGHT
              conector #(.size(pckg_sz)) buf_data_out_1 (.out(data_out_hor_1_3[R-1][C-1]),.in(data_out_connected[1]));
              conector #(.size(1)) buf_pndng_1 (.out(pndng_hor_1_3[R-1][C-1]),.in(pndng_connected[1]));
              conector #(.size(1)) buf_popin_1 (.out(popin_hor_1_3[R-1][C-1]),.in(popin_connected[1]));

              conector #(.size(1)) buf_pop_1 (.out(pop_connected[1]),.in(popin_hor_3_1[R-1][C-1]));
              conector #(.size(pckg_sz)) buf_data_out_i_in_1 (.out(data_out_i_in_connected[1]),.in(data_out_hor_3_1[R-1][C-1]));
              conector #(.size(1)) buf_pndng_i_in_1 (.out(pndng_i_in_connected[1]),.in(pndng_hor_3_1[R-1][C-1]));
              //DOWN
              conector #(.size(pckg_sz)) buf_data_out_2 (.out(data_out_ver_2_0[R-1][C-1]),.in(data_out_connected[2]));
              conector #(.size(1)) buf_pndng_2 (.out(pndng_ver_2_0[R-1][C-1]),.in(pndng_connected[2]));
              conector #(.size(1)) buf_popin_2 (.out(popin_ver_2_0[R-1][C-1]),.in(popin_connected[2]));

              conector #(.size(1)) buf_pop_2 (.out(pop_connected[2]),.in(popin_ver_0_2[R-1][C-1]));
              conector #(.size(pckg_sz)) buf_data_out_i_in_2 (.out(data_out_i_in_connected[2]),.in(data_out_ver_0_2[R-1][C-1]));
              conector #(.size(1)) buf_pndng_i_in_2 (.out(pndng_i_in_connected[2]),.in(pndng_ver_0_2[R-1][C-1]));
          end
          if(C ==COLUMS) begin //upper rigth corner
              //UP
              conector #(.size(pckg_sz)) buf_data_out_0 (.out(data_out[COLUMS-1]),.in(data_out_connected[0]));
              conector #(.size(1)) buf_pndng_0 (.out(pndng[COLUMS-1]),.in(pndng_connected[0]));
              conector #(.size(1)) buf_popin_0 (.out(popin[COLUMS-1]),.in(popin_connected[0]));

              conector #(.size(1)) buf_pop_0 (.out(pop_connected[0]),.in(pop[COLUMS-1]));
              conector #(.size(pckg_sz)) buf_data_out_i_in_0 (.out(data_out_i_in_connected[0]),.in(data_out_i_in[COLUMS-1]));
              conector #(.size(1)) buf_pndng_i_in_0 (.out(pndng_i_in_connected[0]),.in( pndng_i_in[COLUMS-1]));
              //RIGHT
              conector #(.size(pckg_sz)) buf_data_out_1 (.out(data_out[2*COLUMS+ROWS] ),.in( data_out_connected[1]));
              conector #(.size(1)) buf_pndng_1 (.out(pndng[2*COLUMS+ROWS] ),.in( pndng_connected[1]));
              conector #(.size(1)) buf_popin_1 (.out(popin[2*COLUMS+ROWS] ),.in(popin_connected[1]));

              conector #(.size(1)) buf_pop_1 (.out(pop_connected[1] ),.in(pop[2*COLUMS+ROWS]));
              conector #(.size(pckg_sz)) buf_data_out_i_in_1 (.out(data_out_i_in_connected[1]),.in(data_out_i_in[2*COLUMS+ROWS]));
              conector #(.size(1)) buf_pndng_i_in_1 (.out(pndng_i_in_connected[1]),.in( pndng_i_in[2*COLUMS+ROWS]));
              //LEFT
              conector #(.size(pckg_sz)) buf_data_out_3 (.out(data_out_hor_3_1[R-1][C-2] ),.in( data_out_connected[3]));
              conector #(.size(1)) buf_pndng_3 (.out(pndng_hor_3_1[R-1][C-2] ),.in( pndng_connected[3]));
              conector #(.size(1)) buf_popin_3 (.out(popin_hor_3_1[R-1][C-2] ),.in(popin_connected[3]));

              conector #(.size(1)) buf_pop_3 (.out(pop_connected[3] ),.in(popin_hor_1_3[R-1][C-2]));
              conector #(.size(pckg_sz)) buf_data_out_i_in_3 (.out(data_out_i_in_connected[3]),.in(data_out_hor_1_3[R-1][C-2]));
              conector #(.size(1)) buf_pndng_i_in_3 (.out(pndng_i_in_connected[3]),.in( pndng_hor_1_3[R-1][C-2]));
              //DOWN
              conector #(.size(pckg_sz)) buf_data_out_2 (.out(data_out_ver_2_0[R-1][C-1] ),.in( data_out_connected[2]));
              conector #(.size(1)) buf_pndng_2 (.out(pndng_ver_2_0[R-1][C-1] ),.in( pndng_connected[2]));
              conector #(.size(1)) buf_popin_2 (.out(popin_ver_2_0[R-1][C-1] ),.in(popin_connected[2]));

              conector #(.size(1)) buf_pop_2 (.out(pop_connected[2] ),.in(popin_ver_0_2[R-1][C-1]));
              conector #(.size(pckg_sz)) buf_data_out_i_in_2 (.out(data_out_i_in_connected[2]),.in(data_out_ver_0_2[R-1][C-1]));
              conector #(.size(1)) buf_pndng_i_in_2 (.out(pndng_i_in_connected[2]),.in( pndng_ver_0_2[R-1][C-1]));
          end
          if((C != COLUMS)&&(C != 1)) begin // First row (not corners)
              //UP
              conector #(.size(pckg_sz)) buf_data_out_0 (.out(data_out[C-1] ),.in( data_out_connected[0]));
              conector #(.size(1)) buf_pndng_0 (.out(pndng[C-1] ),.in( pndng_connected[0]));
              conector #(.size(1)) buf_popin_0 (.out(popin[C-1] ),.in(popin_connected[0]));

              conector #(.size(1)) buf_pop_0 (.out(pop_connected[0] ),.in(pop[C-1]));
              conector #(.size(pckg_sz)) buf_data_out_i_in_0 (.out(data_out_i_in_connected[0]),.in(data_out_i_in[C-1]));
              conector #(.size(1)) buf_pndng_i_in_0 (.out(pndng_i_in_connected[0]),.in( pndng_i_in[C-1]));
              //LEFT
              conector #(.size(pckg_sz)) buf_data_out_3 (.out(data_out_hor_3_1[R-1][C-2] ),.in( data_out_connected[3]));
              conector #(.size(1)) buf_pndng_3 (.out(pndng_hor_3_1[R-1][C-2] ),.in( pndng_connected[3]));
              conector #(.size(1)) buf_popin_3 (.out(popin_hor_3_1[R-1][C-2] ),.in(popin_connected[3]));

              conector #(.size(1)) buf_pop_3 (.out(pop_connected[3] ),.in(popin_hor_1_3[R-1][C-2]));
              conector #(.size(pckg_sz)) buf_data_out_i_in_3 (.out(data_out_i_in_connected[3]),.in(data_out_hor_1_3[R-1][C-2]));
              conector #(.size(1)) buf_pndng_i_in_3 (.out(pndng_i_in_connected[3]),.in( pndng_hor_1_3[R-1][C-2]));
              //RIGHT
              conector #(.size(pckg_sz)) buf_data_out_1 (.out(data_out_hor_1_3[R-1][C-1] ),.in( data_out_connected[1]));
              conector #(.size(1)) buf_pndng_1 (.out(pndng_hor_1_3[R-1][C-1] ),.in( pndng_connected[1]));
              conector #(.size(1)) buf_popin_1 (.out(popin_hor_1_3[R-1][C-1] ),.in(popin_connected[1]));

              conector #(.size(1)) buf_pop_1 (.out(pop_connected[1] ),.in(popin_hor_3_1[R-1][C-1]));
              conector #(.size(pckg_sz)) buf_data_out_i_in_1 (.out(data_out_i_in_connected[1]),.in(data_out_hor_3_1[R-1][C-1]));
              conector #(.size(1)) buf_pndng_i_in_1 (.out(pndng_i_in_connected[1]),.in( pndng_hor_3_1[R-1][C-1]));
              //DOWN
              conector #(.size(pckg_sz)) buf_data_out_2 (.out(data_out_ver_2_0[R-1][C-1] ),.in( data_out_connected[2]));
              conector #(.size(1)) buf_pndng_2 (.out(pndng_ver_2_0[R-1][C-1] ),.in( pndng_connected[2]));
              conector #(.size(1)) buf_popin_2 (.out(popin_ver_2_0[R-1][C-1] ),.in(popin_connected[2]));

              conector #(.size(1)) buf_pop_2 (.out(pop_connected[2] ),.in(popin_ver_0_2[R-1][C-1]));
              conector #(.size(pckg_sz)) buf_data_out_i_in_2 (.out(data_out_i_in_connected[2]),.in(data_out_ver_0_2[R-1][C-1]));
              conector #(.size(1)) buf_pndng_i_in_2 (.out(pndng_i_in_connected[2]),.in( pndng_ver_0_2[R-1][C-1]));
          end
        end
        if(R == ROWS) begin
          if(C == 1) begin //bottom left corner
              //UP
              conector #(.size(pckg_sz)) buf_data_out_0 (.out(data_out_ver_0_2[R-2][C-1] ),.in( data_out_connected[0]));
              conector #(.size(1)) buf_pndng_0 (.out(pndng_ver_0_2[R-2][C-1] ),.in( pndng_connected[0]));
              conector #(.size(1)) buf_popin_0 (.out(popin_ver_0_2[R-2][C-1] ),.in(popin_connected[0]));

              conector #(.size(1)) buf_pop_0 (.out(pop_connected[0] ),.in(popin_ver_2_0[R-2][C-1]));
              conector #(.size(pckg_sz)) buf_data_out_i_in_0 (.out(data_out_i_in_connected[0]),.in(data_out_ver_2_0[R-2][C-1]));
              conector #(.size(1)) buf_pndng_i_in_0 (.out(pndng_i_in_connected[0]),.in( pndng_ver_2_0[R-2][C-1]));
              //LEFT
              conector #(.size(pckg_sz)) buf_data_out_3 (.out(data_out[COLUMS+ROWS-1] ),.in( data_out_connected[3]));
              conector #(.size(1)) buf_pndng_3 (.out(pndng[COLUMS+ROWS-1] ),.in( pndng_connected[3]));
              conector #(.size(1)) buf_popin_3 (.out(popin[COLUMS+ROWS-1] ),.in(popin_connected[3]));
              conector #(.size(1)) buf_pop_3 (.out(pop_connected[3] ),.in(pop[COLUMS+ROWS-1]));
              conector #(.size(pckg_sz)) buf_data_out_i_in_3 (.out(data_out_i_in_connected[3]),.in(data_out_i_in[COLUMS+ROWS-1]));
              conector #(.size(1)) buf_pndng_i_in_3 (.out(pndng_i_in_connected[3]),.in( pndng_i_in[COLUMS+ROWS-1]));
              //RIGHT
              conector #(.size(pckg_sz)) buf_data_out_1 (.out(data_out_hor_1_3[R-1][C-1] ),.in( data_out_connected[1]));
              conector #(.size(1)) buf_pndng_1 (.out(pndng_hor_1_3[R-1][C-1] ),.in( pndng_connected[1]));
              conector #(.size(1)) buf_popin_1 (.out(popin_hor_1_3[R-1][C-1] ),.in(popin_connected[1]));

              conector #(.size(1)) buf_pop_1 (.out(pop_connected[1] ),.in(popin_hor_3_1[R-1][C-1]));
              conector #(.size(pckg_sz)) buf_data_out_i_in_1 (.out(data_out_i_in_connected[1]),.in(data_out_hor_3_1[R-1][C-1]));
              conector #(.size(1)) buf_pndng_i_in_1 (.out(pndng_i_in_connected[1]),.in( pndng_hor_3_1[R-1][C-1]));
              //DOWN
              conector #(.size(pckg_sz)) buf_data_out_2 (.out(data_out[COLUMS+ROWS] ),.in( data_out_connected[2]));
              conector #(.size(1)) buf_pndng_2 (.out(pndng[COLUMS+ROWS] ),.in( pndng_connected[2]));
              conector #(.size(1)) buf_popin_2 (.out(popin[COLUMS+ROWS] ),.in(popin_connected[2]));

              conector #(.size(1)) buf_pop_2 (.out(pop_connected[2] ),.in(pop[COLUMS+ROWS]));
              conector #(.size(pckg_sz)) buf_data_out_i_in_2 (.out(data_out_i_in_connected[2]),.in(data_out_i_in[COLUMS+ROWS]));
              conector #(.size(1)) buf_pndng_i_in_2 (.out(pndng_i_in_connected[2]),.in( pndng_i_in[COLUMS+ROWS]));
          end
          if(C == COLUMS) begin //bottom rigth corner
              //UP
              conector #(.size(pckg_sz)) buf_data_out_0 (.out(data_out_ver_0_2[R-2][C-1] ),.in( data_out_connected[0]));
              conector #(.size(1)) buf_pndng_0 (.out(pndng_ver_0_2[R-2][C-1] ),.in( pndng_connected[0]));
              conector #(.size(1)) buf_popin_0 (.out(popin_ver_0_2[R-2][C-1] ),.in(popin_connected[0]));

              conector #(.size(1)) buf_pop_0 (.out(pop_connected[0] ),.in(popin_ver_2_0[R-2][C-1]));
              conector #(.size(pckg_sz)) buf_data_out_i_in_0 (.out(data_out_i_in_connected[0]),.in(data_out_ver_2_0[R-2][C-1]));
              conector #(.size(1)) buf_pndng_i_in_0 (.out(pndng_i_in_connected[0]),.in( pndng_ver_2_0[R-2][C-1]));
              //LEFT
              conector #(.size(pckg_sz)) buf_data_out_3 (.out(data_out_hor_3_1[R-1][C-2] ),.in( data_out_connected[3]));
              conector #(.size(1)) buf_pndng_3 (.out(pndng_hor_3_1[R-1][C-2] ),.in( pndng_connected[3]));
              conector #(.size(1)) buf_popin_3 (.out(popin_hor_3_1[R-1][C-2] ),.in(popin_connected[3]));

              conector #(.size(1)) buf_pop_3 (.out(pop_connected[3] ),.in(popin_hor_1_3[R-1][C-2]));
              conector #(.size(pckg_sz)) buf_data_out_i_in_3 (.out(data_out_i_in_connected[3]),.in(data_out_hor_1_3[R-1][C-2]));
              conector #(.size(1)) buf_pndng_i_in_3 (.out(pndng_i_in_connected[3]),.in( pndng_hor_1_3[R-1][C-2]));
              //RIGHT
              conector #(.size(pckg_sz)) buf_data_out_1 (.out(data_out[2*COLUMS+2*ROWS-1] ),.in( data_out_connected[1]));
              conector #(.size(1)) buf_pndng_1 (.out(pndng[2*COLUMS+2*ROWS-1] ),.in( pndng_connected[1]));
              conector #(.size(1)) buf_popin_1 (.out(popin[2*COLUMS+2*ROWS-1] ),.in(popin_connected[1]));
              conector #(.size(1)) buf_pop_1 (.out(pop_connected[1] ),.in(pop[2*COLUMS+2*ROWS-1]));
              conector #(.size(pckg_sz)) buf_data_out_i_in_1 (.out(data_out_i_in_connected[1]),.in(data_out_i_in[2*COLUMS+2*ROWS-1]));
              conector #(.size(1)) buf_pndng_i_in_1 (.out(pndng_i_in_connected[1]),.in( pndng_i_in[2*COLUMS+2*ROWS-1]));
              //DOWN
              conector #(.size(pckg_sz)) buf_data_out_2 (.out(data_out[2*COLUMS+ROWS-1] ),.in( data_out_connected[2]));
              conector #(.size(1)) buf_pndng_2 (.out(pndng[2*COLUMS+ROWS-1] ),.in( pndng_connected[2]));
              conector #(.size(1)) buf_popin_2 (.out(popin[2*COLUMS+ROWS-1] ),.in(popin_connected[2]));
              conector #(.size(1)) buf_pop_2 (.out(pop_connected[2] ),.in(pop[2*COLUMS+ROWS-1]));
              conector #(.size(pckg_sz)) buf_data_out_i_in_2 (.out(data_out_i_in_connected[2]),.in(data_out_i_in[2*COLUMS+ROWS-1]));
              conector #(.size(1)) buf_pndng_i_in_2 (.out(pndng_i_in_connected[2]),.in( pndng_i_in[2*COLUMS+ROWS-1]));
          end
          if((C != COLUMS)&&(C != 1)) begin //Last row (not corners)
              //UP
              conector #(.size(pckg_sz)) buf_data_out_0 (.out(data_out_ver_0_2[R-2][C-1] ),.in( data_out_connected[0]));
              conector #(.size(1)) buf_pndng_0 (.out(pndng_ver_0_2[R-2][C-1] ),.in( pndng_connected[0]));
              conector #(.size(1)) buf_popin_0 (.out(popin_ver_0_2[R-2][C-1] ),.in(popin_connected[0]));

              conector #(.size(1)) buf_pop_0 (.out(pop_connected[0] ),.in(popin_ver_2_0[R-2][C-1]));
              conector #(.size(pckg_sz)) buf_data_out_i_in_0 (.out(data_out_i_in_connected[0]),.in(data_out_ver_2_0[R-2][C-1]));
              conector #(.size(1)) buf_pndng_i_in_0 (.out(pndng_i_in_connected[0]),.in( pndng_ver_2_0[R-2][C-1]));
              //LEFT
              conector #(.size(pckg_sz)) buf_data_out_3 (.out(data_out_hor_3_1[R-1][C-2] ),.in( data_out_connected[3]));
              conector #(.size(1)) buf_pndng_3 (.out(pndng_hor_3_1[R-1][C-2] ),.in( pndng_connected[3]));
              conector #(.size(1)) buf_popin_3 (.out(popin_hor_3_1[R-1][C-2] ),.in(popin_connected[3]));

              conector #(.size(1)) buf_pop_3 (.out(pop_connected[3] ),.in(popin_hor_1_3[R-1][C-2]));
              conector #(.size(pckg_sz)) buf_data_out_i_in_3 (.out(data_out_i_in_connected[3]),.in(data_out_hor_1_3[R-1][C-2]));
              conector #(.size(1)) buf_pndng_i_in_3 (.out(pndng_i_in_connected[3]),.in( pndng_hor_1_3[R-1][C-2]));
              //RIGHT
              conector #(.size(pckg_sz)) buf_data_out_1 (.out(data_out_hor_1_3[R-1][C-1] ),.in( data_out_connected[1]));
              conector #(.size(1)) buf_pndng_1 (.out(pndng_hor_1_3[R-1][C-1] ),.in( pndng_connected[1]));
              conector #(.size(1)) buf_popin_1 (.out(popin_hor_1_3[R-1][C-1] ),.in(popin_connected[1]));

              conector #(.size(1)) buf_pop_1 (.out(pop_connected[1] ),.in(popin_hor_3_1[R-1][C-1]));
              conector #(.size(pckg_sz)) buf_data_out_i_in_1 (.out(data_out_i_in_connected[1]),.in(data_out_hor_3_1[R-1][C-1]));
              conector #(.size(1)) buf_pndng_i_in_1 (.out(pndng_i_in_connected[1]),.in( pndng_hor_3_1[R-1][C-1]));
              //DOWN
              conector #(.size(pckg_sz)) buf_data_out_2 (.out(data_out[COLUMS+ROWS-1+C] ),.in( data_out_connected[2]));
              conector #(.size(1)) buf_pndng_2 (.out(pndng[COLUMS+ROWS-1+C] ),.in( pndng_connected[2]));
              conector #(.size(1)) buf_popin_2 (.out(popin[COLUMS+ROWS-1+C] ),.in(popin_connected[2]));

              conector #(.size(1)) buf_pop_2 (.out(pop_connected[2] ),.in(pop[COLUMS+ROWS-1+C]));
              conector #(.size(pckg_sz)) buf_data_out_i_in_2 (.out(data_out_i_in_connected[2]),.in(data_out_i_in[COLUMS+ROWS-1+C]));
              conector #(.size(1)) buf_pndng_i_in_2 (.out(pndng_i_in_connected[2]),.in( pndng_i_in[COLUMS+ROWS-1+C]));
          end
        end 
        if((C == 1)&&(R != 1)&&(R != ROWS))begin //First colum (Not corners)
            //UP
            conector #(.size(pckg_sz)) buf_data_out_0 (.out(data_out_ver_0_2[R-2][C-1] ),.in( data_out_connected[0]));
            conector #(.size(1)) buf_pndng_0 (.out(pndng_ver_0_2[R-2][C-1] ),.in( pndng_connected[0]));
            conector #(.size(1)) buf_popin_0 (.out(popin_ver_0_2[R-2][C-1] ),.in(popin_connected[0]));

            conector #(.size(1)) buf_pop_0 (.out(pop_connected[0] ),.in(popin_ver_2_0[R-2][C-1]));
            conector #(.size(pckg_sz)) buf_data_out_i_in_0 (.out(data_out_i_in_connected[0]),.in(data_out_ver_2_0[R-2][C-1]));
            conector #(.size(1)) buf_pndng_i_in_0 (.out(pndng_i_in_connected[0]),.in( pndng_ver_2_0[R-2][C-1]));
            //LEFT
            conector #(.size(pckg_sz)) buf_data_out_3 (.out(data_out[COLUMS+R-1] ),.in( data_out_connected[3]));
            conector #(.size(1)) buf_pndng_3 (.out(pndng[COLUMS+R-1] ),.in( pndng_connected[3]));
            conector #(.size(1)) buf_popin_3 (.out(popin[COLUMS+R-1] ),.in(popin_connected[3]));

            conector #(.size(1)) buf_pop_3 (.out(pop_connected[3] ),.in(pop[COLUMS+R-1]));
            conector #(.size(pckg_sz)) buf_data_out_i_in_3 (.out(data_out_i_in_connected[3]),.in(data_out_i_in[COLUMS+R-1]));
            conector #(.size(1)) buf_pndng_i_in_3 (.out(pndng_i_in_connected[3]),.in( pndng_i_in[COLUMS+R-1]));
            //RIGHT
            conector #(.size(pckg_sz)) buf_data_out_1 (.out(data_out_hor_1_3[R-1][C-1] ),.in( data_out_connected[1]));
            conector #(.size(1)) buf_pndng_1 (.out(pndng_hor_1_3[R-1][C-1] ),.in( pndng_connected[1]));
            conector #(.size(1)) buf_popin_1 (.out(popin_hor_1_3[R-1][C-1] ),.in(popin_connected[1]));

            conector #(.size(1)) buf_pop_1 (.out(pop_connected[1] ),.in(popin_hor_3_1[R-1][C-1]));
            conector #(.size(pckg_sz)) buf_data_out_i_in_1 (.out(data_out_i_in_connected[1]),.in(data_out_hor_3_1[R-1][C-1]));
            conector #(.size(1)) buf_pndng_i_in_1 (.out(pndng_i_in_connected[1]),.in( pndng_hor_3_1[R-1][C-1]));
            //DOWN
            conector #(.size(pckg_sz)) buf_data_out_2 (.out(data_out_ver_2_0[R-1][C-1] ),.in( data_out_connected[2]));
            conector #(.size(1)) buf_pndng_2 (.out(pndng_ver_2_0[R-1][C-1] ),.in( pndng_connected[2]));
            conector #(.size(1)) buf_popin_2 (.out(popin_ver_2_0[R-1][C-1] ),.in(popin_connected[2]));

            conector #(.size(1)) buf_pop_2 (.out(pop_connected[2] ),.in(popin_ver_0_2[R-1][C-1]));
            conector #(.size(pckg_sz)) buf_data_out_i_in_2 (.out(data_out_i_in_connected[2]),.in(data_out_ver_0_2[R-1][C-1]));
            conector #(.size(1)) buf_pndng_i_in_2 (.out(pndng_i_in_connected[2]),.in( pndng_ver_0_2[R-1][C-1]));
        end
        if((C == COLUMS)&&(R != 1)&&(R != ROWS))begin //Last colum (Not corners)
            //UP
            conector #(.size(pckg_sz)) buf_data_out_0 (.out(data_out_ver_0_2[R-2][C-1] ),.in( data_out_connected[0]));
            conector #(.size(1)) buf_pndng_0 (.out(pndng_ver_0_2[R-2][C-1] ),.in( pndng_connected[0]));
            conector #(.size(1)) buf_popin_0 (.out(popin_ver_0_2[R-2][C-1] ),.in(popin_connected[0]));

            conector #(.size(1)) buf_pop_0 (.out(pop_connected[0] ),.in(popin_ver_2_0[R-2][C-1]));
            conector #(.size(pckg_sz)) buf_data_out_i_in_0 (.out(data_out_i_in_connected[0]),.in(data_out_ver_2_0[R-2][C-1]));
            conector #(.size(1)) buf_pndng_i_in_0 (.out(pndng_i_in_connected[0]),.in( pndng_ver_2_0[R-2][C-1]));
            //DOWN
            conector #(.size(pckg_sz)) buf_data_out_2 (.out(data_out_ver_2_0[R-1][C-1] ),.in( data_out_connected[2]));
            conector #(.size(1)) buf_pndng_2 (.out(pndng_ver_2_0[R-1][C-1] ),.in( pndng_connected[2]));
            conector #(.size(1)) buf_popin_2 (.out(popin_ver_2_0[R-1][C-1] ),.in(popin_connected[2]));

            conector #(.size(1)) buf_pop_2 (.out(pop_connected[2] ),.in(popin_ver_0_2[R-1][C-1]));
            conector #(.size(pckg_sz)) buf_data_out_i_in_2 (.out(data_out_i_in_connected[2]),.in(data_out_ver_0_2[R-1][C-1]));
            conector #(.size(1)) buf_pndng_i_in_2 (.out(pndng_i_in_connected[2]),.in( pndng_ver_0_2[R-1][C-1]));
            //LEFT
            conector #(.size(pckg_sz)) buf_data_out_3 (.out(data_out_hor_3_1[R-1][C-2] ),.in( data_out_connected[3]));
            conector #(.size(1)) buf_pndng_3 (.out(pndng_hor_3_1[R-1][C-2] ),.in( pndng_connected[3]));
            conector #(.size(1)) buf_popin_3 (.out(popin_hor_3_1[R-1][C-2] ),.in(popin_connected[3]));

            conector #(.size(1)) buf_pop_3 (.out(pop_connected[3] ),.in(popin_hor_1_3[R-1][C-2]));
            conector #(.size(pckg_sz)) buf_data_out_i_in_3 (.out(data_out_i_in_connected[3]),.in(data_out_hor_1_3[R-1][C-2]));
            conector #(.size(1)) buf_pndng_i_in_3 (.out(pndng_i_in_connected[3]),.in( pndng_hor_1_3[R-1][C-2]));
            //RIGHT
            conector #(.size(pckg_sz)) buf_data_out_1 (.out(data_out[2*COLUMS+ROWS-1+R] ),.in( data_out_connected[1]));
            conector #(.size(1)) buf_pndng_1 (.out(pndng[2*COLUMS+ROWS-1+R] ),.in( pndng_connected[1]));
            conector #(.size(1)) buf_popin_1 (.out(popin[2*COLUMS+ROWS-1+R] ),.in(popin_connected[1]));

            conector #(.size(1)) buf_pop_1 (.out(pop_connected[1] ),.in(pop[2*COLUMS+ROWS-1+R]));
            conector #(.size(pckg_sz)) buf_data_out_i_in_1 (.out(data_out_i_in_connected[1]),.in(data_out_i_in[2*COLUMS+ROWS-1+R]));
            conector #(.size(1)) buf_pndng_i_in_1 (.out(pndng_i_in_connected[1]),.in( pndng_i_in[2*COLUMS+ROWS-1+R]));
        end
        if((C != COLUMS)&&(C != 1)&&(R != 1)&&(R != ROWS))begin //Every router not connected to an agent
            //UP
            conector #(.size(pckg_sz)) buf_data_out_0 (.out(data_out_ver_0_2[R-2][C-1] ),.in( data_out_connected[0]));
            conector #(.size(1)) buf_pndng_0 (.out(pndng_ver_0_2[R-2][C-1] ),.in( pndng_connected[0]));
            conector #(.size(1)) buf_popin_0 (.out(popin_ver_0_2[R-2][C-1] ),.in(popin_connected[0]));

            conector #(.size(1)) buf_pop_0 (.out(pop_connected[0] ),.in(popin_ver_2_0[R-2][C-1]));
            conector #(.size(pckg_sz)) buf_data_out_i_in_0 (.out(data_out_i_in_connected[0] ),.in(data_out_ver_2_0[R-2][C-1]));
            conector #(.size(1)) buf_pndng_i_in_0 (.out(pndng_i_in_connected[0]),.in( pndng_ver_2_0[R-2][C-1]));
            //DOWN
            conector #(.size(pckg_sz)) buf_data_out_2 (.out(data_out_ver_2_0[R-1][C-1] ),.in( data_out_connected[2]));
            conector #(.size(1)) buf_pndng_2 (.out(pndng_ver_2_0[R-1][C-1] ),.in( pndng_connected[2]));
            conector #(.size(1)) buf_popin_2 (.out(popin_ver_2_0[R-1][C-1] ),.in(popin_connected[2]));

            conector #(.size(1)) buf_pop_2 (.out(pop_connected[2] ),.in(popin_ver_0_2[R-1][C-1]));
            conector #(.size(pckg_sz)) buf_data_out_i_in_2 (.out(data_out_i_in_connected[2]),.in(data_out_ver_0_2[R-1][C-1]));
            conector #(.size(1)) buf_pndng_i_in_2 (.out(pndng_i_in_connected[2]),.in( pndng_ver_0_2[R-1][C-1]));
            //LEFT
            conector #(.size(pckg_sz)) buf_data_out_3 (.out(data_out_hor_3_1[R-1][C-2] ),.in( data_out_connected[3]));
            conector #(.size(1)) buf_pndng_3 (.out(pndng_hor_3_1[R-1][C-2] ),.in( pndng_connected[3]));
            conector #(.size(1)) buf_popin_3 (.out(popin_hor_3_1[R-1][C-2] ),.in(popin_connected[3]));

            conector #(.size(1)) buf_pop_3 (.out(pop_connected[3] ),.in(popin_hor_1_3[R-1][C-2]));
            conector #(.size(pckg_sz)) buf_data_out_i_in_3 (.out(data_out_i_in_connected[3]),.in(data_out_hor_1_3[R-1][C-2]));
            conector #(.size(1)) buf_pndng_i_in_3 (.out(pndng_i_in_connected[3]),.in( pndng_hor_1_3[R-1][C-2]));
            //RIGHT
            conector #(.size(pckg_sz)) buf_data_out_1 (.out(data_out_hor_1_3[R-1][C-1] ),.in( data_out_connected[1]));
            conector #(.size(1)) buf_pndng_1 (.out(pndng_hor_1_3[R-1][C-1] ),.in( pndng_connected[1]));
            conector #(.size(1)) buf_popin_1 (.out(popin_hor_1_3[R-1][C-1] ),.in(popin_connected[1]));

            conector #(.size(1)) buf_pop_1 (.out(pop_connected[1] ),.in(popin_hor_3_1[R-1][C-1]));
            conector #(.size(pckg_sz)) buf_data_out_i_in_1 (.out(data_out_i_in_connected[1]),.in(data_out_hor_3_1[R-1][C-1]));
            conector #(.size(1)) buf_pndng_i_in_1 (.out(pndng_i_in_connected[1]),.in( pndng_hor_3_1[R-1][C-1]));
        end
          router_bus_gnrtr #(.pck_sz(pckg_sz),.num_ntrfs(4),.broadcast(bdcst),.fifo_depth(fifo_depth),.id_c(C),.id_r(R),.columns(COLUMS),.rows(ROWS)) rtr(
            .clk(clk),
            .reset(reset),
            .data_out_i_in(data_out_i_in_connected),
            .pndng_i_in(pndng_i_in_connected),
            .pop(pop_connected),
            .popin(popin_connected),
            .pndng(pndng_connected),
            .data_out(data_out_connected)
          );
          
      end
    end
  endgenerate
endmodule

/////////////////////////////////////////////////
// Implementación del bus paralelo con arbitro //
/////////////////////////////////////////////////

module prll_bus_interface_cn_rbtr #(parameter pck_sz = 40, parameter num_ntrfs=4, parameter [7:0]ntrfs_id = 0, parameter broadcast = {8{1'b1}}) (
  input clk,
  input reset,
  input [pck_sz-1:0]data_in_i,
  input [$clog2(num_ntrfs)-1:0]trn,
  input pop_i,
  input push_i,
  output logic [pck_sz-1:0]data_out_i,
  input [pck_sz-1:0]D_pop,
  output [pck_sz-1:0]D_push,
  output logic pndng_i,
  output logic pop,
  input pndng,
  output logic push
  );
  logic pre_psh;
  logic pre_pop;

  assign push = pre_psh & push_i;
  assign pop = pre_pop & pop_i;
  assign pre_psh = ((ntrfs_id == data_in_i[pck_sz-1:pck_sz-8])|(data_in_i[pck_sz-1:pck_sz-8]== broadcast))?1:0; 
  assign pre_pop = (ntrfs_id == trn)?1:0;
  assign pndng_i = pndng;
  assign data_out_i = D_pop;
  assign D_push = data_in_i;
  
endmodule


module prll_bus_gnrtr_cn_rbtr #(parameter pck_sz = 40, parameter num_ntrfs=4, parameter broadcast = {8{1'b1}})(
  input clk,
  input reset,
  input[pck_sz-1:0]D_pop[num_ntrfs-1:0],
  input pndng[num_ntrfs-1:0],
  output pop[num_ntrfs-1:0],
  output push[num_ntrfs-1:0],
  output [pck_sz-1:0] D_push[num_ntrfs-1:0]
);
  wire pop_i;
  wire push_i;
  wire [num_ntrfs-1:0]pndng_i;
  wire [pck_sz-1:0] data_out_i[num_ntrfs-1:0];
  wire [$clog2(num_ntrfs)-1:0]trn;
  wire [pck_sz-1:0] data_in_i;
  
  genvar i;
  generate
    for(i=0;i<num_ntrfs; i=i+1)begin:_nu_
    prll_bus_interface_cn_rbtr #(.pck_sz(pck_sz),.num_ntrfs(num_ntrfs),.ntrfs_id(i),.broadcast(broadcast)) rtr_ntrfs(
    .clk(clk),
    .reset(reset),
    .data_in_i(data_in_i),
    .trn(trn),
    .pop_i(pop_i),
    .push_i(push_i),
    .data_out_i(data_out_i[i]),
    .D_pop(D_pop[i]),
    .D_push(D_push[i]),
    .pndng_i(pndng_i[i]),
    .pop(pop[i]),
    .pndng(pndng[i]),
    .push(push[i])
    );
    end
  endgenerate
  Router_arbiter #(.num_ntrfs(num_ntrfs),.pck_sz(pck_sz)) arbitro(
  .reset(reset),
  .clk(clk),
  .pndng_i(pndng_i),
  .data_out_i(data_out_i),
  .trn(trn),
  .push_i(push_i),
  .pop_i(pop_i),
  .data_in_i(data_in_i)
);
endmodule 
