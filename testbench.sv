
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

`include "rand.sv"

import Rand_Parameters::*;


////////////////////////// Módulo superior para correr la prueba //////////////////////////

/// Módulo para hacer pruebas sencillas de cada bloque
/*
module prueba;
  Trans_in pruebaa;
  
  initial begin
    pruebaa=new();
    pruebaa.randomize();
    pruebaa.print("[T]");
  end
  
endmodule  
*/