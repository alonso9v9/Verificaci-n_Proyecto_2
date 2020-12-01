// Curso: EL-5811 Verificación Funcional de Circuitos integrados
// Tecnologico de Costa Rica (www.tec.ac.cr)
// Profesor: Ronny García Ramírez 
// Desarrolladores:
// Felipe Josue Rojas-Barrantes (fjrojas.cr@gmail.com)
// José Agustín Delgado-Sancho (ahusjads@gmail.com)
// Luis Alonso Vega-Badilla (alonso9v9@gmail.com)
// Este script esta estructurado en System Verilog

class Top#(parameter pckg_sz=32);
mlbx_top_aGENte mlbx_top_aGENte0; //defino mailbox del top al Gen.
tipos_pruebas tipo_prueba; //handler para definir el escenario y la prueba
Trans_top  #(.pckg_sz(pckg_sz)) item_top;//creamos una nueva transacción de un escenario
task run();
    case(tipo_prueba);
        esc1_pru1:
         begin
         end
        esc1_pru2:
         begin
         end
        esc1_pru3:
         begin
         end
        esc1_pru4:
         begin
         end
        esc2_pru1:
         begin
         end
        esc2_pru2:
         begin
         end
        esc2_pru3:
         begin
         end
    endcase

endtask
endclass