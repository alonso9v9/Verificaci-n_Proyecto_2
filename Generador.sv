
// Curso: EL-5811 Verificación Funcional de Circuitos integrados
// Tecnologico de Costa Rica (www.tec.ac.cr)
// Profesor: Ronny García Ramírez 
// Desarrolladores:
// Felipe Josue Rojas-Barrantes (fjrojas.cr@gmail.com)
// José Agustín Delgado-Sancho (ahusjads@gmail.com)
// Luis Alonso Vega-Badilla (alonso9v9@gmail.com)
// Este script esta estructurado en System Verilog

//**************************************GENERADOR_AGENTE*******************************************
class Generador_Agent#(parameter pckg_sz=32);
   mlbx_aGENte_drv   mlbx_aGENte_drv0;  //buzon que va hacia el driver


   //mlbx_aGENte_chckr mlbx_aGENte_chckr0; //buzon que va hacia el Checker
   mlbx_top_aGENte   mlbx_top_aGENte0;   //buzon que se ocupa para tener las transacciones especificas
   Trans_top #(.pckg_sz(pckg_sz)) item_top;//creamos una nueva transacción de un escenario
   rand int iter;
  constraint cons_iter{3<=iter;iter<=300;}
  tipos_llenado tipo_llenado; //handler del tipo llenado de la transaccion
   

  task run();//task donde corre el generador
    $display("[T=%0t] [Geneeeeee] iter = %p", $time,iter);
    case(tipo_llenado) //case para decidir si llenar la transaccion con datos aleatorios o con datos especificador por el usuario
        llenado_aleat: //genera una transaccion aleatoria
          begin 
            $display("[T=%0t] [Generador] Se ha escogido la transaccion de llenado aleatorio", $time);
            for (int i = 0; i < iter; i++) begin//en este ciclo se crean las transacciones
              Trans_in #(.pckg_sz(pckg_sz)) item = new;//creamos una nueva transacción
               item.randomize();//generamos los valores aleatorios
                    $display ("[T=%0t] [Generator] Loop:%0d/%0d create next item", $time, i+1, iter);
                    //mlbx_aGENte_chckr0.put(item);//manda el item hacia el checker

                    mlbx_aGENte_drv0.put(item) ; //manda el item hacia el driver
                    item.print("[Generator] Transaccion enviada al driver");

            end
                $display ("[T=%0t] [Generator] Done generation of %0d items", $time, iter);
          end
      
        
        llenado_espec: //genera una transaccion con algunos datos especificos
          begin 
            $display("[T=%0t] [Generador] Se ha escogido la transaccion de llenado especifico", $time);
            for (int i = 0; i < iter; i++) begin//en este ciclo se crean las transacciones

              Trans_in #(.pckg_sz(pckg_sz)) item = new;//creamos una nueva transacción
                item.randomize();//generamos los valores aleatorios        {{{{{PROBAR}}}}}
                //aquí le caemos encima a lo que especifique el usuario
                    mlbx_top_aGENte0.get(item_top) ;
                        item.Target   =  item_top.dstny_espec;
                        item.Origen   =  item_top.orgn_espec;
                        item.payload  =  item_top.pyld_espec;
                        item.mode     =  item_top.mode_espec;
                        item.delay    =  item_top.delay_espec;
             
                    $display ("[T=%0t] [Generator] Loop:%0d/%0d create next item", $time, i+1, iter);
                    //mlbx_aGENte_chckr0.put(item);//manda el item hacia el checker
                    mlbx_aGENte_drv0.put(item) ; //manda el item hacia el driver
					item.print("[Generator] Transaccion enviada al driver");
            end
                $display ("[T=%0t] [Generator] Done generation of %0d items", $time, iter);
          end
      
     endcase       
  endtask
endclass