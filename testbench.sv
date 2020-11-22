`include "fifo.sv"
`include "Library.sv"
`include "Router_library.sv"

`include "transacciones.sv"
`include "disp.sv"
`include "driver.sv"
`include "monitor.sv"

///////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////Verificación de Circuitos Integrados////////////////////////////
/////////////////////////////////////Proyecto 2////////////////////////////////////////////
/////////////////////////Felipe Rojas, Agustín Degado, Alonso Vega/////////////////////////
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