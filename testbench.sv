///////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////Verificación de Circuitos Integrados////////////////////////////
/////////////////////////////////////Proyecto 2////////////////////////////////////////////
/////////////////////////Felipe Rojas, Agustín Degado, Alonso Vega/////////////////////////

//****************************DEFINICION DE TIPOS DE ORIGEN********************************
typedef enum{orin_aleat,orin_espec} tipos_orin;

//****************************DEFINICION DE TIPOS DE DESTINO********************************
typedef enum{dtnt_aleat,dtny_espec, broadcast } tipos_dtny;

//****************************DEFINICION DE TIPOS DE ORIGEN********************************
typedef enum{orin_aleat,orin_espec} tipos_orin;

//***************************DEFINICION DE TIPOS DE LLENADO DE PAYLOAD**********************
typedef enum{orin_aleat,orin_espec} tipos_orin;

//****************************DEFINICION DE TIPOS DE MODO***********************************
typedef enum{modo_filas,modo_colum} tipos_orin;

//**************************************INTERFACE*******************************************
interface intfz#(parameter pckg_sz, drivers,bits)(input bit clk);
      bit pndng[16];                                                //output
      bit [pckg_sz-1:0] data_out[16];                               //output
      bit popin[16];                                                //output
      bit pop[16];                                                  //input
      bit [pckg_sz-1:0]data_out_i_in[16];                           //input
      bit pndng_i_in[16];                                           //input
endinterface