
//////////////////////////////////////////////////////////
// Definition of a D flip flop with asyncronous reset  //
/////////////////////////////////////////////////////////

module dff_async_rst (
  input data,
  input clk,
  input reset,
  output reg q);

  always @ ( posedge clk or posedge reset)    
    if (reset) begin
      q <= 1'b0;
    end  else begin
      q <= data;
    end

endmodule

//////////////////////////////////////////////////////////
// Definition of a D Latch  with asyncronous reset  //
/////////////////////////////////////////////////////////

module dltch_async_rst (
  input data,
  input clk,
  input reset,
  output reg q);

  always @ (clk or reset or data)    
    if (reset) begin
      q <= 1'b0;
    end  else if (clk) begin
      q <= data;
    end

endmodule

//////////////////////////////////////////////////////////
// Definition of a D Latch  without  reset  //
/////////////////////////////////////////////////////////

module dltch (
  input data,
  input clk,
  output reg q);

  always @ (clk or data)    
    if (clk) begin
      q <= data;
    end

endmodule

///////////////////////////////////////////////////////////////////////
// Definition of the prll D register with flops
///////////////////////////////////////////////////////////////////////

module prll_d_reg #(parameter bits = 32)(
  input clk,
  input reset,
  input [bits-1:0] D_in,
  output [bits-1:0] D_out
);
  genvar i;
  generate
    for(i = 0; i < bits; i=i+1) begin:bit_
      dff_async_rst prll_regstr_(.data(D_in[i]),.clk(clk),.reset(reset),.q(D_out[i]));
    end
  endgenerate

endmodule

///////////////////////////////////////////////////////////////////////
// Definition of the prll D register with Lathces 
///////////////////////////////////////////////////////////////////////

module prll_d_ltch_no_rst #(parameter bits = 32)(
  input clk,
  input [bits-1:0] D_in,
  output [bits-1:0] D_out
);
  genvar i;
  generate
    for(i = 0; i < bits; i=i+1) begin:bit_
      dltch prll_regstr_(.data(D_in[i]),.clk(clk),.q(D_out[i]));
    end
  endgenerate

endmodule

///////////////////////////////////////////////////////////////////////
// Definition of the prll D register with Lathces 
///////////////////////////////////////////////////////////////////////

module prll_d_ltch #(parameter bits = 32)(
  input clk,
  input reset,
  input [bits-1:0] D_in,
  output [bits-1:0] D_out
);
  genvar i;
  generate
    for(i = 0; i < bits; i=i+1) begin:bit_
      dltch_async_rst prll_regstr_(.data(D_in[i]),.clk(clk),.reset(reset),.q(D_out[i]));
    end
  endgenerate

endmodule

///////////////////////////////////////////////////////////////////////
// Definition of a positve edge detector 
///////////////////////////////////////////////////////////////////////

module pos_edge(
 input clk,
 `ifdef COMP_TEST
    input deleteme,
 `endif
 output out
);
 `ifdef COMP_TEST
    wire neg_clk;
    not #(0,3) inv_clk(neg_clk,clk);
    and  and_posdg (out,deleteme,neg_clk);
 `else
    wire neg_clk;
    not #(0,3) inv_clk(neg_clk,clk);
    and  and_posdg (out,clk,neg_clk);
 `endif
endmodule


///////////////////////////////////////////////////////////////////////
// Definition of a negative edge detector 
///////////////////////////////////////////////////////////////////////

module neg_edge(
 input clk,
 `ifdef COMP_TEST
    input deleteme,
 `endif
 output out
);
 `ifdef COMP_TEST
    wire neg_clk;
    not #(3,0) inv_clk(neg_clk,clk);
    nor nor_ngdg (out,deleteme,neg_clk);
 `else
    wire neg_clk;
    not #(3,0) inv_clk(neg_clk,clk);
    nor nor_ngdg (out,clk,neg_clk);
 `endif
endmodule

///////////////////////////////////////////////////////////////////////
// Definition of the FIFO with Flip_Flops 
///////////////////////////////////////////////////////////////////////
module fifo_flops #(parameter depth = 16,parameter bits = 32)(
  input [bits-1:0] Din,
  output reg [bits-1:0] Dout,
  input push,
  input pop,
  input clk,
  output reg full,
  output reg pndng,
  input rst
);
  wire [bits-1:0] q[depth-1:0];
  reg [$clog2(depth):0] count;
  reg [bits-1:0] aux_mux [depth-1:0];
  reg [bits-1:0] aux_mux_or [depth-2:0];

  genvar i;
  generate
    for(i=0;i<depth;i=i+1)begin:_dp_
       if(i==0)begin: _dp2_
         prll_d_reg #(bits) D_reg(.clk(push),.reset(rst),.D_in(Din),.D_out(q[i]));
         always@(*)begin
           aux_mux[i]=(count==i+1)?q[i]:{bits{1'b0}};
         end    
       end else begin: _dp3_
         prll_d_reg #(bits) D_reg(.clk(push),.reset(rst),.D_in(q[i-1]),.D_out(q[i]));
         always@(*)begin
           aux_mux[i]=(count==i+1)?q[i]:{bits{1'b0}};
         end    
       end
    end
  endgenerate

  generate
  for(i=0;i<depth-2;i=i+1)begin:_nu_
    always@(*)begin
      aux_mux_or[i]=aux_mux[i] | aux_mux_or[i+1];
    end
  end
  endgenerate

  always@(*)begin
    aux_mux_or[depth-2] = aux_mux [depth-1]|aux_mux[depth-2];
    Dout=aux_mux_or[0];  
  end

  always@(posedge clk)begin
  if(rst) begin
    count <= 0;
  end else begin
  
    case({push,pop})
      2'b00: count <= count;
      2'b01: begin
        if(count == 0) begin
          count <= 0;
        end else begin
          count <=count - 1;
        end
      end
      2'b10:begin
         if(count == depth)begin
           count <= count;
         end else begin
           count <= count+1;
        end
      end
      2'b11: count <= count;
    endcase
  end
  pndng <= (count==0)?{1'b0}:{1'b1};
  full <=(count == depth)?{1'b1}:{1'b0};
end
endmodule


///////////////////////////////////////////////////////////////////////
// Definition of the FIFO with Flip_Flops no full
///////////////////////////////////////////////////////////////////////
module fifo_flops_no_full #(parameter depth = 16,parameter bits = 32)(
  input [bits-1:0] Din,
  output reg [bits-1:0] Dout,
  input push,
  input pop,
  input clk,
  //output reg full,
  output reg pndng,
  input rst
);
  wire [bits-1:0] q[depth-1:0];
  reg [$clog2(depth):0] count;
  reg [$clog2(depth):0] nxt_count;
  reg [bits-1:0] aux_mux [depth-1:0];
  reg [bits-1:0] aux_mux_or [depth-2:0];
  reg clk_gen;

  assign clk_gen = ~clk & push;

  genvar i;
  generate
    for(i=0;i<depth;i=i+1)begin:_dp_
       if(i==0)begin: _dp2_
         prll_d_reg #(bits) D_reg(.clk(clk_gen),.reset(rst),.D_in(Din),.D_out(q[i]));
         always@(*)begin
           aux_mux[i]=(count==i+1)?q[i]:{bits{1'b0}};
         end    
       end else begin: _dp3_
         prll_d_reg #(bits) D_reg(.clk(clk_gen),.reset(rst),.D_in(q[i-1]),.D_out(q[i]));
         always@(*)begin
           aux_mux[i]=(count==i+1)?q[i]:{bits{1'b0}};
         end    
       end
    end
  endgenerate

  generate
  for(i=0;i<depth-2;i=i+1)begin:_nu_
    always@(*)begin
      aux_mux_or[i]=aux_mux[i] | aux_mux_or[i+1];
    end
  end
  endgenerate

  always@(*)begin
    aux_mux_or[depth-2] = aux_mux [depth-1]|aux_mux[depth-2];
    Dout=aux_mux_or[0];  
  end

  always@(*)begin
    case({push,pop})
      2'b00: nxt_count <= count;
      2'b01: begin
        if(count == 0) begin
          nxt_count <= 0;
        end else begin
          nxt_count <=count - 1;
        end
      end
      2'b10:begin
         if(count == depth)begin
           nxt_count <= count;
         end else begin
           nxt_count <= count+1;
        end
      end
      2'b11: nxt_count <= count;
    endcase
    pndng <= (count==0)?{1'b0}:{1'b1};
end
  always@(posedge clk or posedge rst)begin
    if(rst) begin
      count = 0;
    end else begin
      count = nxt_count;
    end
  end
   `ifdef DEBUG
      always@(posedge push)begin
        if(count == depth)begin
          $display ("Fifo overflow at time %g:",$time,$sformatf("%m"));
        end 
      end
    `endif  

endmodule

///////////////////////////////////////////////////////////////////////
// Definition of the FIFO with Latches
///////////////////////////////////////////////////////////////////////
module fifo_ltch #(parameter depth = 16,parameter bits = 32)(
  input [bits-1:0] Din,
  output reg [bits-1:0] Dout,
  input push,
  input pop,
  input clk,
  output reg full,
  output reg pndng,
  input rst
);
  wire [bits-1:0] q[depth-1:0];
  wire gen_clk[depth-1:0];
  logic  enbld_clk;
  reg [$clog2(depth):0] count;
  reg [bits-1:0] aux_mux [depth-1:0];
  reg [bits-1:0] aux_mux_or [depth-2:0];

    
     wire gen_clk_hld[depth-1:1];
     wire clk_dlyd;
     buf #(3,3) buf_dly_clk(clk_dlyd,clk); 
     buf #(2,2) buf_hld_n (gen_clk_hld[depth-1],gen_clk[depth-1]);
     pos_edge posedg_dtct (.clk(enbld_clk),.out(gen_clk[depth-1]));
     always@(*) begin
       enbld_clk <= clk_dlyd & push;
     end
   
  genvar i;
  generate
    for(i=0;i<depth;i=i+1)begin:_dp_
       if(i==0)begin: _dp2_
             neg_edge neg_edg_dtct(.clk(gen_clk_hld[i+1]),.out(gen_clk[i])); 
             prll_d_ltch #(bits) D_reg(.clk(gen_clk[i]),.reset(rst),.D_in(Din),.D_out(q[i]));
             always@(*)begin
               aux_mux[i]=(count==i+1)?q[i]:{bits{1'b0}};
             end
       end else begin: _dp3_
          if(i==(depth-1))begin: _dp4_
             prll_d_ltch #(bits) D_reg(.clk(gen_clk[i]),.reset(rst),.D_in(q[i-1]),.D_out(q[i]));
             always@(*)begin
               aux_mux[i]=(count==i+1)?q[i]:{bits{1'b0}};
             end 
          end else begin: _dp5_
               buf #(2,2) buf_hld (gen_clk_hld[i],gen_clk[i]);
               neg_edge neg_edg_dtct (.clk(gen_clk_hld[i+1]),.out(gen_clk[i])); 
               prll_d_ltch #(bits) D_reg(.clk(gen_clk[i]),.reset(rst),.D_in(q[i-1]),.D_out(q[i]));
               always@(*)begin
                 aux_mux[i]=(count==i+1)?q[i]:{bits{1'b0}};
               end 
          end
       end
    end
  endgenerate

  generate
  for(i=0;i<depth-2;i=i+1)begin:_nu_
    always@(*)begin
      aux_mux_or[i]=aux_mux[i] | aux_mux_or[i+1];
    end
  end
  endgenerate

  always@(*)begin
    aux_mux_or[depth-2] = aux_mux [depth-1]|aux_mux[depth-2];
    Dout=aux_mux_or[0];  
  end

  always@(posedge clk)begin
  if(rst) begin
    count <= 0;
  end else begin
  
    case({push,pop})
      2'b00: count <= count;
      2'b01: begin
        if(count == 0) begin
          count <= 0;
        end else begin
          count <=count - 1;
        end
      end
      2'b10:begin
         if(count == depth)begin
           count <= count;
         end else begin
           count <= count+1;
        end
      end
      2'b11: count <= count;
    endcase
  end
  pndng <= (count==0)?{1'b0}:{1'b1};
  full <=(count == depth)?{1'b1}:{1'b0};
end
endmodule

///////////////////////////////////////////////////////////////////////
// Definition of the FIFO with Latches and no reset
///////////////////////////////////////////////////////////////////////
module fifo_ltch_no_rst #(parameter depth = 16,parameter bits = 32)(
  input [bits-1:0] Din,
`ifdef COMP_TEST
  input [depth-1:0] deleteme,
`endif
  output reg [bits-1:0] Dout,
  input push,
  input pop,
  input clk,
//  output reg full,
  output reg pndng,
  input rst
);
  wire [bits-1:0] q[depth-1:0];
  wire gen_clk[depth-1:0];
  logic  enbld_clk;
  reg [$clog2(depth):0] count;
  reg [bits-1:0] aux_mux [depth-1:0];
  reg [bits-1:0] aux_mux_or [depth-2:0];

     wire gen_clk_hld[depth-1:1];
     wire clk_dlyd;
     buf #(3,3) buf_dly_clk(clk_dlyd,clk); 
     buf #(2,2) buf_hld_n (gen_clk_hld[depth-1],gen_clk[depth-1]);
     `ifdef COMP_TEST
       pos_edge posedg_dtct (.deleteme(deleteme[depth-1]),.clk(enbld_clk),.out(gen_clk[depth-1]));
     `else
       pos_edge posedg_dtct (.clk(enbld_clk),.out(gen_clk[depth-1]));
     `endif
     and gen_enbl_clk(enbld_clk,clk_dlyd,push);
   
  genvar i;
  generate
    for(i=0;i<depth;i=i+1)begin:_dp_
       if(i==0)begin: _dp2_
            `ifdef COMP_TEST
               neg_edge neg_edg_dtct (.deleteme(deleteme[i]),.clk(gen_clk_hld[i+1]),.out(gen_clk[i]));
            `else
               neg_edge neg_edg_dtct(.clk(gen_clk_hld[i+1]),.out(gen_clk[i])); 
            `endif
             prll_d_ltch_no_rst #(bits) D_reg(.clk(gen_clk[i]),.D_in(Din),.D_out(q[i]));
             always@(*)begin
               aux_mux[i]=(count==i+1)?q[i]:{bits{1'b0}};
             end
       end else begin: _dp3_
          if(i==(depth-1))begin: _dp4_
             prll_d_ltch_no_rst #(bits) D_reg(.clk(gen_clk[i]),.D_in(q[i-1]),.D_out(q[i]));
             always@(*)begin
               aux_mux[i]=(count==i+1)?q[i]:{bits{1'b0}};
             end 
          end else begin: _dp5_
               buf #(2,2) buf_hld (gen_clk_hld[i],gen_clk[i]);
              `ifdef COMP_TEST
                 neg_edge neg_edg_dtct (.deleteme(deleteme[i]),.clk(gen_clk_hld[i+1]),.out(gen_clk[i]));
               `else
                 neg_edge neg_edg_dtct (.clk(gen_clk_hld[i+1]),.out(gen_clk[i])); 
               `endif
               prll_d_ltch_no_rst #(bits) D_reg(.clk(gen_clk[i]),.D_in(q[i-1]),.D_out(q[i]));
               always@(*)begin
                 aux_mux[i]=(count==i+1)?q[i]:{bits{1'b0}};
               end 
          end
       end
    end
  endgenerate

  generate
  for(i=0;i<depth-2;i=i+1)begin:_nu_
    always@(*)begin
      aux_mux_or[i]=aux_mux[i] | aux_mux_or[i+1];
    end
  end
  endgenerate

  always@(*)begin
    aux_mux_or[depth-2] = aux_mux [depth-1]|aux_mux[depth-2];
    Dout=aux_mux_or[0];  
  end

  always@(posedge clk)begin
  if(rst) begin
    count <= 0;
  end else begin
  
    case({push,pop})
      2'b00: count <= count;
      2'b01: begin
        if(count == 0) begin
          count <= 0;
        end else begin
          count <=count - 1;
        end
      end
      2'b10:begin
         if(count == depth)begin
           count <= count;
         end else begin
           count <= count+1;
        end
      end
      2'b11: count <= count;
    endcase
  end
  pndng <= (count==0)?{1'b0}:{1'b1};
// full <=(count == depth)?{1'b1}:{1'b0};
end
endmodule

///////////////////////////////////////////////////////////////////////
// Definition of the reset logic requiered by the ntrpt_cam_fifo
///////////////////////////////////////////////////////////////////////
module rst_lgc #(parameter N=0, parameter depth = 16) (
  input [$clog2(depth):0] count,
  input pop,
  input rst,
  output reg rst_out
);
    reg equal;
 `ifdef TESTING
    reg [$clog2(depth):0] delay_count;
    genvar i;
    generate
      for(i=0;i<$clog2(depth);i=i+1)begin:_dp_
        buf #(2,2) buf_dly_count(delay_count[i],count[i]);
      end
    endgenerate
    always@(*) begin
      equal <= (count == N)?{1'b1}:{1'b0};
      rst_out <= (rst ||(pop && equal));
    end
  `else
    always@(*) begin
      equal <= (count == N)?{1'b1}:{1'b0};
      rst_out <= (rst ||(pop && equal));
    end
  `endif
endmodule


///////////////////////////////////////////////////////////////////////
// Definition of the cam FIFO with Latches for the interrupt controller
///////////////////////////////////////////////////////////////////////
module ntrpt_cam_fifo #(parameter depth = 16,parameter bits = 32)(
  input [bits-1:0] Din,
  output reg [bits-1:0] Dout,
  input push,
  input pop,
  input clk,
//  output reg full,
  output reg pndng,
  output reg MTIP,
  input reset
);
  wire [bits-1:0] q[depth-1:0];
  wire gen_clk[depth-1:0];
  wire rst[depth-1:0];
  reg [depth-1:0] MTIP_partial;
  logic  enbld_clk;
  reg [$clog2(depth):0] count;
  reg [bits-1:0] aux_mux [depth-1:0];
  reg [bits-1:0] aux_mux_or [depth-2:0];
  

    
  `ifdef TESTING
     wire gen_clk_hld[depth-1:1];
     wire clk_dlyd;
     buf #(3,3) buf_dly_clk(clk_dlyd,clk); 
     buf #(2,2) buf_hld_n (gen_clk_hld[depth-1],gen_clk[depth-1]);
     pos_edge posedg_dtct (.clk(enbld_clk),.out(gen_clk[depth-1]));
     always@(*) begin
       enbld_clk <= clk_dlyd & push;
     end
  `else
    pos_edge posedg_dtct (.clk(enbld_clk),.out(gen_clk[depth-1]));
    always@(*) begin
      enbld_clk <= clk & push;
    end
  `endif
   
  genvar i;
  generate
    for(i=0;i<depth;i=i+1)begin:_dp_
       rst_lgc #(.N(i),.depth(depth)) rst_lgc_lvl(.count(count),.pop(pop),.rst(reset),.rst_out(rst[i]));

       if(i==0)begin: _dp2_
         `ifdef TESTING
             neg_edge neg_edg_dtct(.clk(gen_clk_hld[i+1]),.out(gen_clk[i])); 
             prll_d_ltch #(bits) D_reg(.clk(gen_clk[i]),.reset(rst[i]),.D_in(Din),.D_out(q[i]));
             always@(*)begin
               MTIP_partial[i] = (q[i][15:0] == {16'h0080})? {1'b1}: {1'b0};
               aux_mux[i]=(count==i+1)?q[i]:{bits{1'b0}};
             end
           `else
             neg_edge neg_edg_dtct(.clk(gen_clk[i+1]),.out(gen_clk[i])); 
             prll_d_ltch #(bits) D_reg(.clk(gen_clk[i]),.reset(rst[i]),.D_in(Din),.D_out(q[i]));
             always@(*)begin
               MTIP_partial[i] = (q[i][15:0] == {16'h0080})? {1'b1}: {1'b0};
               aux_mux[i]=(count==i+1)?q[i]:{bits{1'b0}};
             end
           `endif    
       end else begin: _dp3_
          if(i==(depth-1))begin: _dp4_
             prll_d_ltch #(bits) D_reg(.clk(gen_clk[i]),.reset(rst[i]),.D_in(q[i-1]),.D_out(q[i]));
             always@(*)begin
               MTIP_partial[i] = (q[i][15:0] == {16'h0080})? {1'b1}: {1'b0};
               aux_mux[i]=(count==i+1)?q[i]:{bits{1'b0}};
             end 
          end else begin: _dp5_
           `ifdef TESTING
               buf #(2,2) buf_hld (gen_clk_hld[i],gen_clk[i]);
               neg_edge neg_edg_dtct (.clk(gen_clk_hld[i+1]),.out(gen_clk[i])); 
               prll_d_ltch #(bits) D_reg(.clk(gen_clk[i]),.reset(rst[i]),.D_in(q[i-1]),.D_out(q[i]));
               always@(*)begin
                 MTIP_partial[i] = (q[i][15:0] == {16'h0080})? {1'b1}: {1'b0};
                 aux_mux[i]=(count==i+1)?q[i]:{bits{1'b0}};
               end 
           `else
             neg_edge neg_edg_dtct(.clk(gen_clk[i+1]),.out(gen_clk[i])); 
             prll_d_ltch #(bits) D_reg(.clk(gen_clk[i]),.reset(rst[i]),.D_in(q[i-1]),.D_out(q[i]));
             always@(*)begin
               MTIP_partial[i] = (q[i][15:0] == {16'h0080})? {1'b1}: {1'b0};
               aux_mux[i]=(count==i+1)?q[i]:{bits{1'b0}};
             end 
           `endif  
          end
       end
    end
  endgenerate

  generate
  for(i=0;i<depth-2;i=i+1)begin:_nu_
    always@(*)begin
      aux_mux_or[i]=aux_mux[i] | aux_mux_or[i+1];
    end
  end
  endgenerate

  always@(*)begin
    aux_mux_or[depth-2] <= aux_mux [depth-1]|aux_mux[depth-2];
    Dout <=aux_mux_or[0];  
    MTIP <= (MTIP_partial == 0)?{1'b0}: {1'b1};
  end

  always@(posedge clk)begin
  if(reset) begin
    count <= 0;
  end else begin
  
    case({push,pop})
      2'b00: count <= count;
      2'b01: begin
        if(count == 0) begin
          count <= 0;
        end else begin
          count <=count - 1;
        end
      end
      2'b10:begin
         if(count == depth)begin
           count <= count;
         end else begin
           count <= count+1;
        end
      end
      2'b11: count <= count;
    endcase
  end
  pndng <= (count==0)?{1'b0}:{1'b1};
//  full <=(count == depth)?{1'b1}:{1'b0};
end
endmodule


module mem_latch #(parameter bits= 32, parameter entradas = 10)(
  input [$clog2(entradas-1)-1:0] direcciones,
  input [bits-1:0]datos_in,
  input write,
  output [bits-1:0]datos_out
  ); 
  
  wire [bits-1:0]datos_out_entrada[entradas]; 
  wire [bits-1:0]datos_in_entrada[entradas]; 
  wire clk_entrada[entradas];
  wire [entradas-1:0] select_entrada;
    
  genvar b,d;
  generate
    for(d = 0; d < entradas; d=d+1) begin:_depth_
      for(b = 0; b < bits; b=b+1) begin:_bit_
        dltch Ram_latch(.data(datos_in[b]),.clk(clk_entrada[d]),.q(datos_out_entrada[d][b]));
      end
      assign select_entrada[d] = (direcciones == d)?1:0;
      assign clk_entrada[d] = select_entrada[d]&write;
      assign datos_out = (select_entrada[d])?datos_out_entrada[d]:{bits{1'bz}};
    end
  endgenerate

endmodule
