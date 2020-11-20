///////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////Verificación de Circuitos Integrados////////////////////////////
/////////////////////////////////////Proyecto 2////////////////////////////////////////////
/////////////////////////Felipe Rojas, Agustín Degado, Alonso Vega/////////////////////////


//****************************DEFINICION DE TIPOS DE ORIGEN********************************
typedef enum{orin_aleat,orin_espec} tipos_orin;

//****************************DEFINICION DE TIPOS DE DESTINO********************************
typedef enum{dtnt_aleat,dtny_espec, broadcast } tipos_dtny;

//***************************DEFINICION DE TIPOS DE LLENADO DE PAYLOAD**********************
typedef enum{pyld_aleat,pyld_espec} tipos_pyld;

//****************************DEFINICION DE TIPOS DE MODO***********************************
//typedef enum{modo_filas,modo_colum} tipos_modo;

//**************************************INTERFACE*******************************************
interface intfz#(parameter pckg_sz, drivers,bits)(input bit clk);
      bit pndng;                                                //output
      bit [pckg_sz-1:0] data_out;                               //output
      bit popin;                                                //output
      bit pop;                                                  //input
      bit [pckg_sz-1:0]data_out_i_in;                           //input
      bit pndng_i_in;                                           //input
endinterface

//*********************************TRANSACCION LADO DRIVER***********************************
class Trans_in#(parameter pckg_sz=32);//transaccion del mensaje que entra al DUT
  rand  bit [pckg_sz-1:pckg_sz-8] Nxt_jump;
  rand  bit [pckg_sz-9:pckg_sz-16] Target; 
  rand  bit [pckg_sz-9:pckg_sz-16] Origen; 
  
  rand  bit [pckg_sz-17:pckg_sz-17] mode;
  rand  bit [pckg_sz-18:0] payload;
  rand  bit [2:0] delay;

  // Valores válidos de direcciones de los dispositivos
  bit dir={8'b00000001, 8'b00000010,8'b00000011,8'b00000100,8'b00010000,8'b00100000,8'b00110000,8'b01000000,8'b01010001,8'b01010010,8'b01010011,8'b01010100,8'b00010101,8'b00100101,8'b00110101,8'b01000101};
  // Restringir las direcciones al aleatorizar
  constraint limitdir {Target inside {dir};}


  // FUNCIÓN INCOMPLETA
  function print  (string tag); // Funcion para imprimir datos
    $display("[T=%g] %s dato=%b", 
             $time,
             tag, 
             this.Target);
  endfunction
  
endclass

//*********************************TRANSACCION LADO MONITOR**********************************


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