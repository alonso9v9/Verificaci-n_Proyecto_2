
// Curso: EL-5811 Verificación Funcional de Circuitos integrados
// Tecnologico de Costa Rica (www.tec.ac.cr)
// Profesor: Ronny García Ramírez 
// Desarrolladores:
// Felipe Josue Rojas-Barrantes (fjrojas.cr@gmail.com)
// José Agustín Delgado-Sancho (ahusjads@gmail.com)
// Luis Alonso Vega-Badilla (alonso9v9@gmail.com)
// Este script esta estructurado en System Verilog

`include "Router_library.sv"
`include "transacciones.sv"
`include "Generador.sv"
`include "disp.sv"
`include "driver.sv"
`include "monitor.sv"
`include "checker.sv"
`include "scoreboard.sv"
`include "ambiente.sv"
`include "Top.sv"
`include "Rand_Parameters.sv"


import Rand_Parameters::*;


////////////////////////// Módulo superior para correr la prueba //////////////////////////

/// Módulo para hacer pruebas sencillas de cada bloque

module test_bench;
  reg clk;
  int seed;

  event fin;      //// Evento utilizado por el checker y el sb para generar reportes finales
  event sb_done;  //// Indica cuando el sb termina de generar el reporte final
  intfz #(.pckg_sz(pckg_sz))_if (.clk(clk));

  intfz #(.pckg_sz(pckg_sz))emu_if (.clk(clk));

  always #5 clk=~clk;

  mesh_gnrtr #(.ROWS(ROWS),.COLUMS(COLUMS),.pckg_sz(pckg_sz),.fifo_depth(fifo_depth),.bdcst(bdcst)) uut 
  (.pndng(_if.pndng),.data_out(_if.data_out), .popin(_if.popin),.pop(_if.pop),
  	.data_out_i_in(_if.data_out_i_in),.pndng_i_in(_if.pndng_i_in),.clk(_if.clk),.reset(_if.reset));

  // Instancia del emulador del mesh
  /*
  mesh_emu #(.ROWS(ROWS), .COLUMS(COLUMS), .pckg_sz(pckg_sz), .fifo_depth(fifo_depth)) mesh(
   .clk          (emu_if.clk),
   .rst          (emu_if.reset),
   .pndng        (emu_if.pndng),
   .data_out     (emu_if.data_out),
   .popin        (emu_if.popin),
   .pop          (emu_if.pop),
   .data_out_i_in(emu_if.data_out_i_in),
   .pndng_i_in   (emu_if.pndng_i_in)
  );
  */


  assign emu_if.reset = _if.reset;
  assign emu_if.data_out_i_in = _if.data_out_i_in;
  assign emu_if.pndng_i_in = _if.pndng_i_in;
  assign emu_if.pop = _if.pop;
  

  Top #(.pckg_sz(pckg_sz),.disps(16), .fifo_depth(fifo_depth)) inst_top;
  
  initial begin
  	clk = 0;
    _if.reset = 1;
    #10
    _if.reset = 0;
    inst_top=new();
    inst_top._if=_if;
    
    seed=10; //Seed a utilizar en el test

    fork
       inst_top.run(fin, sb_done,seed);
    join_none
  end
  
  always@(posedge clk) begin
    if ($time > 500000)begin
      $display("Test_bench: Tiempo límite de prueba en el test_bench alcanzado");
      -> fin;
      wait (sb_done.triggered);
      $finish;
    end
  end



  // aserciones de la interfaz

  property pnd_pop(pndng,pop,clk);
    @(posedge clk) $rose (pndng) |-> ##[0:50] $rose (pop);
  endproperty

  property pndi_popi(pndi,popi,clk);
    @(posedge clk) $rose (pndi) |-> ##[0:50] $rose (popi);
  endproperty  

  property res(reset,pndng,pop,pndi,popi,dato,dati,clk);
    @(posedge clk) $rose (reset) |-> ##[1:50] (pndng==0&& pop==0&& pndi==0&& popi==0&& dato==0&& dati==0);
  endproperty

  generate
    for (genvar i = 0; i < 16; i++) begin :assert_if_array
      a_pnd_pop: assert property (pnd_pop(.pndng(_if.pndng[i]),.pop(_if.pop[i]),.clk(_if.clk))) else $display("pnd_pop FAIL[%g]",i);
      c_pnd_pop: cover property (pnd_pop(.pndng(_if.pndng[i]),.pop(_if.pop[i]),.clk(_if.clk))) $display("pnd_pop PASS[%g]",i);

      a_pndi_popi: assert property (pndi_popi(.pndi(_if.pndng_i_in[i]),.popi(_if.popin[i]),.clk(_if.clk))) else $display("pndi_popi FAIL[%g]",i);
      c_pndi_popi: cover property (pndi_popi(.pndi(_if.pndng_i_in[i]),.popi(_if.popin[i]),.clk(_if.clk))) $display("pndi_popi PASS[%g]",i);

      a_res: assert property (res(.reset(_if.reset),.pndng(_if.pndng[i]),.pop(_if.pop[i]),.pndi(_if.pndng_i_in[i]),.popi(_if.popin[i]),.dato(_if.data_out[i]),.dati(_if.data_out_i_in[i]),.clk(_if.clk))) else $display("res FAIL[%g]",i);
      c_res: cover property (res(.reset(_if.reset),.pndng(_if.pndng[i]),.pop(_if.pop[i]),.pndi(_if.pndng_i_in[i]),.popi(_if.popin[i]),.dato(_if.data_out[i]),.dati(_if.data_out_i_in[i]),.clk(_if.clk))) $display("res PASS[%g]",i);
    end
  endgenerate


endmodule  



