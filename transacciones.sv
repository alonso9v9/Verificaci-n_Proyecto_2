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
typedef enum{llenado_aleat,llenado_pld_espec,llenado_dtny_espec,llenado_orin_espec} tipos_llenado;


//********************************DEFINICION DE ACCION *************************************
typedef enum{normal,reset} tipos_accion;



//**************************************INTERFACE*******************************************
interface intfz#(parameter pckg_sz)(input clk);
      logic pndng[16];                                                //output
      logic [pckg_sz-1:0] data_out[16];                               //output
      logic popin[16];                                                //output
      logic pop[16];                                                  //input
      logic [pckg_sz-1:0]data_out_i_in[16];                           //input
      logic pndng_i_in[16];                                           //input
      logic reset;													                          //input
endinterface

//*********************************TRANSACCION LADO DRIVER***********************************
class Trans_in#(parameter pckg_sz=40);//transaccion del mensaje que entra al DUT
  rand  bit [pckg_sz-9:pckg_sz-16] Target; 
  //randc  bit [7:0] Origen; 
  rand int Origen;
  rand int Origen_alternativo;
  rand   bit [pckg_sz-17:pckg_sz-17] mode;
  rand   bit [pckg_sz-18:0] payload;
  rand   int delay;
  tipos_accion tipo;
  int tiempo;

  // Restringir las direcciones al aleatorizar
  constraint limittar {Target inside {8'b00000001, 8'b00000010,8'b00000011,8'b00000100,8'b00010000,8'b00100000,8'b00110000,8'b01000000,8'b01010001,8'b01010010,8'b01010011,8'b01010100,8'b00010101,8'b00100101,8'b00110101,8'b01000101};}
  constraint limitorin {0<=Origen;Origen<=15;}
  constraint limitorin_alter {0<=Origen_alternativo;Origen_alternativo<=15;}
  constraint orin_alter_distinto {Origen_alternativo!=Origen;}
  constraint limitdly {0<=delay;delay<=10;}
  
  
  constraint dtny_error {Target dist {
    8'b00000001:=10,                                   
    8'b00000010:=10,
    8'b00000011:=10,
    8'b00000100:=10,
    8'b00010000:=10,
    8'b00100000:=10,
    8'b00110000:=10,
    8'b01000000:=10,
    8'b01010001:=10,
    8'b01010010:=10,
    8'b01010011:=10,
    8'b01010100:=10,
    8'b00010101:=10,
    8'b00100101:=10,
    8'b00110101:=10,
    8'b01000101:=10,
    8'b11110000:=100,            //Direccion no existente
    8'b00001111:=100,            //Direccion no existente
    8'b11111111:=100,            //Direccion no existente
    8'b00000000:=100};}          //Direccion no existente
   
//Esto para que el origen no sea igual al destino

  constraint orin_dist_dtny {
    if(Target == 8'b00000001 && Origen == 0  )Origen <=Origen_alternativo;
    if(Target == 8'b00000010 && Origen == 1  )Origen <=Origen_alternativo;
    if(Target == 8'b00000011 && Origen == 2  )Origen <=Origen_alternativo;
    if(Target == 8'b00000100 && Origen == 3  )Origen <=Origen_alternativo;
    if(Target == 8'b00010000 && Origen == 4  )Origen <=Origen_alternativo;
    if(Target == 8'b00100000 && Origen == 5  )Origen <=Origen_alternativo;
    if(Target == 8'b00110000 && Origen == 6  )Origen <=Origen_alternativo;
    if(Target == 8'b01000000 && Origen == 7  )Origen <=Origen_alternativo;
    if(Target == 8'b01010001 && Origen == 8  )Origen <=Origen_alternativo;
    if(Target == 8'b01010010 && Origen == 9  )Origen <=Origen_alternativo;
    if(Target == 8'b01010011 && Origen == 10 )Origen <=Origen_alternativo;
    if(Target == 8'b01010100 && Origen == 11 )Origen <=Origen_alternativo;
    if(Target == 8'b00010101 && Origen == 12 )Origen <=Origen_alternativo;
    if(Target == 8'b00100101 && Origen == 13 )Origen <=Origen_alternativo;
    if(Target == 8'b00110101 && Origen == 14 )Origen <=Origen_alternativo;
    if(Target == 8'b01000101 && Origen == 15 )Origen <=Origen_alternativo;}
  
//Esto para que el origen  sea igual al destino

  constraint orin_equal_dtny {
    if(Target == 8'b00000001 )Origen <=0;
    if(Target == 8'b00000010 )Origen <=1;
    if(Target == 8'b00000011 )Origen <=2;
    if(Target == 8'b00000100 )Origen <=3;
    if(Target == 8'b00010000 )Origen <=4;
    if(Target == 8'b00100000 )Origen <=5;
    if(Target == 8'b00110000 )Origen <=6;
    if(Target == 8'b01000000 )Origen <=7;
    if(Target == 8'b01010001 )Origen <=8;
    if(Target == 8'b01010010 )Origen <=9;
    if(Target == 8'b01010011 )Origen <=10;
    if(Target == 8'b01010100 )Origen <=11;
    if(Target == 8'b00010101 )Origen <=12;
    if(Target == 8'b00100101 )Origen <=13;
    if(Target == 8'b00110101 )Origen <=14;
    if(Target == 8'b01000101 )Origen <=15;}




  function print  (string tag); // Funcion para imprimir datos
    $display("[T=%g] %s, Target=%b, Modo=%b, Payload=%b, Origen=%b, Delay= %0d",
             $time,
             tag, 
             this.Target,
             this.mode,
             this.payload,
             this.Origen,
             this.delay
             );
  endfunction
  
  

  
endclass

//*********************************TRANSACCION LADO MONITOR**********************************
class Trans_out#(parameter pckg_sz=40);//transaccion del mensaje que entra al DUT
    bit [pckg_sz-9:pckg_sz-16] TargetO; 
    bit [pckg_sz-17:pckg_sz-17] modeO;
    bit [pckg_sz-18:0] payloadO;
    int delayO;
    int dvc;
    tipos_accion tipo;

  function print  (string tag); // Funcion para imprimir datos
    $display("[T=%g] %s, Recibido en dvc %g, Target=%b, Modo=%b, Payload=%0b, Delay= %0d, Tipo = %0s",
             $time,
             tag,
             this.dvc,
             this.TargetO,
             this.modeO,
             this.payloadO,
             this.delayO,
             this.tipo
             );
  endfunction
  
endclass


//*********************************TRANSACCION DEL TOP***************************************

class Trans_top#(parameter pckg_sz=40);

    bit  [pckg_sz-9:pckg_sz-16] dstny_espec;
    int  orgn_espec;
    bit  [pckg_sz-18:0] pyld_espec;
    bit  [pckg_sz-17:pckg_sz-17] mode_espec;
    int  delay_espec;

      function print  (string tag); // Funcion para imprimir datos
        $display("[T=%g] %s, Destino=%0b, Origen=%d, Payload=%b, Mode=%0b, Delay= %d",
             $time,
             tag, 
             this.dstny_espec,
             this.orgn_espec,
             this.pyld_espec,
             this.mode_espec,
             this.delay_espec
             );
      endfunction

endclass




//********************************DEFINICION DE MAILBOXES***********************************

typedef mailbox #(Trans_in)mlbx_aGENte_drv;                  //MAILBOX GENERADOR_AGENTE-DRIVER

typedef mailbox #(Trans_in)mlbx_drv_disp;                  //MAILBOX DRIVER-DISPOSITIVO

typedef mailbox #(Trans_in)mlbx_aGENte_sb;                //MAILBOX GENERADOR_AGENTE-CHECKER

typedef mailbox #(Trans_out)mlbx_mntr_chckr;               //MAILBOX MONITOR-CHECKER

typedef mailbox #(Trans_top)mlbx_top_aGENte;               //MAILBOX TOP-GENERADOR_AGENTE

//********************************DEFINICION DE LOS ESCENARIOS**********************************

typedef enum{esc1_pru1, esc1_pru2,esc1_pru3, esc1_pru4, esc2_pru1, esc2_pru2, esc2_pru3} tipos_pruebas;


//********************************DEFINICION DE LAS PRUEBAS**************************************


//***********************************************************************************************