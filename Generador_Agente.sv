
// Curso: EL-5811 Verificación Funcional de Circuitos integrados
// Tecnologico de Costa Rica (www.tec.ac.cr)
// Profesor: Ronny García Ramírez 
// Desarrolladores:
// Felipe Josue Rojas-Barrantes (fjrojas.cr@gmail.com)
// José Agustín Delgado-Sancho (ahusjads@gmail.com)
// Luis Alonso Vega-Badilla (alonso9v9@gmail.com)
// Este script esta estructurado en System Verilog

//**************************************GENERADOR*******************************************
class Generador#(parameter pckg_sz=32, pyld_espec, orgn_espec, dstny_espec, mode_espec);
  mailbox mlbx_gen_agte;  //buzon que va hacia el agente
  //event agen_listo;
  tipos_llenado tipo_llnado=llenado_aleat; //handler del tipo de payload
  int iter=10;


  task run();//task donde corre el generador
    case(tipo_llnado) //case para decidir si llenar la transaccion con datos aleatorios o con datos especificador por el usuario
        llenado_aleat: //genera una transaccion aleatoria
          begin 
            $display("[T=%0t] [Generador] Se ha escogido la transaccion de llenado aleatorio", $time);
            for (int i = 0; i < iter; i++) begin//en este ciclo se crean las transacciones
              Trans_in #(.pckg_sz(pckg_sz)) item = new;//creamos una nueva transacción
               item.randomize();//generamos los valores aleatorios
                    $display ("[T=%0t] [Generator] Loop:%0d/%0d create next item", $time, i+1, iter);
                    mlbx_gen_agte.put(item);//manda el item hacia la capa inferior
            end
                $display ("[T=%0t] [Generator] Done generation of %0d items", $time, iter);
          end
      
        
        llenado_espec: //genera una transaccion con algunos datos especificos
          begin 
            $display("[T=%0t] [Generador] Se ha escogido la transaccion de llenado especifico", $time);
            iter=1;
            for (int i = 0; i < iter; i++) begin//en este ciclo se crean las transacciones
              Trans_in #(.pckg_sz(pckg_sz)) item = new;//creamos una nueva transacción
               item.randomize();//generamos los valores aleatorios
                //aquí le caemos encima a lo que especifique el usuario
                    item.Target  = dstny_espec;
                    item.Origen  = orgn_espec;
                    item.payload = pyld_espec;
                    item.mode    = mode_espec;
                    $display ("[T=%0t] [Generator] Loop:%0d/%0d create next item", $time, i+1, iter);
                    mlbx_gen_agte.put(item);//manda el item hacia la capa inferior
            end
                $display ("[T=%0t] [Generator] Done generation of %0d items", $time, iter);
          end
      
     endcase       
  endtask
endclass