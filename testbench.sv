
// Curso: EL-5811 Verificación Funcional de Circuitos integrados
// Tecnologico de Costa Rica (www.tec.ac.cr)
// Profesor: Ronny García Ramírez 
// Desarrolladores:
// Felipe Josue Rojas-Barrantes (fjrojas.cr@gmail.com)
// José Agustín Delgado-Sancho (ahusjads@gmail.com)
// Luis Alonso Vega-Badilla (alonso9v9@gmail.com)
// Este script esta estructurado en System Verilog


`include "fifo.sv"
`include "Library.sv"
`include "Router_library.sv"

`include "transacciones.sv"
`include "disp.sv"
`include "driver.sv"
`include "monitor.sv"

`include "Rand_Parameters.sv"

`include "transacciones.sv"

import Rand_Parameters::*;


////////////////////////// Módulo superior para correr la prueba //////////////////////////

/// Módulo para hacer pruebas sencillas de cada bloque

module test_bench;
  reg clk;

  intfz #(.pckg_sz(pckg_sz))_if (.clk(clk));

  always #5 clk=~clk;

  mesh_gnrtr #(.ROWS(ROWS),.COLUMS(COLUMS),.pckg_sz(pckg_sz),.fifo_depth(fifo_depth),.bdcst(bdcst)) uut 
  (.pndng(_if.pndng),.data_out(_if.data_out), .popin(_if.popin),.pop(_if.pop),
  	.data_out_i_in(_if.data_out_i_in),.pndng_i_in(_if.pndng_i_in),.clk(clk),.reset(_if.reset));


  initial begin
  	clk = 0;
    pruebaa=new();
    pruebaa.randomize();
    pruebaa.print("[T]");
  end
  


  always@(posedge clk) begin
    if ($time > 100000)begin
      $display("Test_bench: Tiempo límite de prueba en el test_bench alcanzado");
      $finish;
    end
  end
endmodule  

