// Curso: EL-5811 Verificación Funcional de Circuitos integrados
// Tecnologico de Costa Rica (www.tec.ac.cr)
// Profesor: Ronny García Ramírez 
// Desarrolladores:
// Felipe Josue Rojas-Barrantes (fjrojas.cr@gmail.com)
// José Agustín Delgado-Sancho (ahusjads@gmail.com)
// Luis Alonso Vega-Badilla (alonso9v9@gmail.com)
// Este script esta estructurado en System Verilog



// Definición de transacciones e interfaces del test


//****************************DEFINICION DE TIPOS DE LLENADO********************************
typedef enum{llenado_aleat,llenado_espec} tipos_llenado;


//********************************DEFINICION DE ACCION *************************************
typedef enum{normal,reset} tipos_accion;



//**************************************INTERFACE*******************************************
interface intfz#(parameter pckg_sz)(input bit clk);
      bit pndng[16];                                                //output
      bit [pckg_sz-1:0] data_out[16];                               //output
      bit popin[16];                                                //output
      bit pop[16];                                                  //input
      bit [pckg_sz-1:0]data_out_i_in[16];                           //input
      bit pndng_i_in[16];                                           //input
      bit reset;													                          //input
endinterface

//*********************************TRANSACCION LADO DRIVER***********************************
class Trans_in#(parameter pckg_sz=32);//transaccion del mensaje que entra al DUT
  rand   bit [pckg_sz-1:pckg_sz-8] Nxt_jump;
  randc  bit [pckg_sz-9:pckg_sz-16] Target; 
  //randc  bit [7:0] Origen; 
  randc int Origen;
  
  rand   bit [pckg_sz-17:pckg_sz-17] mode;
  rand   bit [pckg_sz-18:0] payload;
  rand   int delay;
  tipos_accion tipo;

  // Valores válidos de direcciones de los dispositivos
  bit dir={8'b00000001, 8'b00000010,8'b00000011,8'b00000100,8'b00010000,8'b00100000,8'b00110000,8'b01000000,8'b01010001,8'b01010010,8'b01010011,8'b01010100,8'b00010101,8'b00100101,8'b00110101,8'b01000101};
  // Restringir las direcciones al aleatorizar
  constraint limittar {Target inside {dir};}
  //constraint limitorin {Origen inside {dir};}
  constraint limitorin {0<=Origen;Origen<=15;}
  constraint limitnxtjump {Nxt_jump inside {dir};}
  constraint limitdly {0<=delay;delay<=3;}
  
  function print  (string tag); // Funcion para imprimir datos
    $display("[T=%g] %s Nxt_jump=%b, Target=%b, Modo=%b, Payload=%0d, Origen=%b, Delay= %0d",
             $time,
             tag, 
             this.Nxt_jump,
             this.Target,
             this.mode,
             this.payload,
             this.Origen,
             this.delay
             );
  endfunction
  
endclass

//*********************************TRANSACCION LADO MONITOR**********************************
class Trans_out#(parameter pckg_sz=32);//transaccion del mensaje que entra al DUT
    bit [pckg_sz-1:pckg_sz-8] Nxt_jumpO;
    bit [pckg_sz-9:pckg_sz-16] TargetO; 
    bit [pckg_sz-17:pckg_sz-17] modeO;
    bit [pckg_sz-18:0] payloadO;
    int  delayO;
    tipos_accion tipo;

  function print  (string tag); // Funcion para imprimir datos
    $display("[T=%g] %s Nxt_jump=%b, Target=%b, Modo=%b, Payload=%0d, Delay= %0d, Tipo = %0s",
             $time,
             tag, 
             this.Nxt_jumpO,
             this.TargetO,
             this.modeO,
             this.payloadO,
             this.delayO,
             this.tipo
             );
  endfunction
  
endclass

//********************************DEFINICION DE MAILBOXES***********************************

typedef mailbox #(Trans_in)mlbx_aGENte_drv;                  //MAILBOX GENERADOR_AGENTE-DRIVER

//typedef mailbox #(Trans_in)mlbx_agte_drv;                  //MAILBOX AGENTE-DRIVER

typedef mailbox #(Trans_in)mlbx_drv_disp;                  //MAILBOX DRIVER-DISPOSITIVO

typedef mailbox #(Trans_in)mlbx_aGENte_chckr;                //MAILBOX GENERADOR_AGENTE-CHECKER

typedef mailbox #(Trans_out)mlbx_mntr_chckr;               //MAILBOX MONITOR-CHECKER

//*******************************************************************************************