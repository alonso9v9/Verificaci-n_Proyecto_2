
// Curso: EL-5811 Verificación Funcional de Circuitos integrados
// Tecnologico de Costa Rica (www.tec.ac.cr)
// Profesor: Ronny García Ramírez 
// Desarrolladores:
// Felipe Josue Rojas-Barrantes (fjrojas.cr@gmail.com)
// José Agustín Delgado-Sancho (ahusjads@gmail.com)
// Luis Alonso Vega-Badilla (alonso9v9@gmail.com)
// Este script esta estructurado en System Verilog

//**************************************GENERADOR_AGENTE*******************************************
class Generador_Agent#(parameter pckg_sz=40);
   mlbx_aGENte_drv   mlbx_aGENte_drv0;      //buzon que va hacia el Driver
   Trans_in #(.pckg_sz(pckg_sz)) item;
   mlbx_aGENte_sb mlbx_aGENte_sb0;          //buzon que va hacia el Scoreboard
   mlbx_top_aGENte   mlbx_top_aGENte0;      //buzon que se ocupa para tener las transacciones especificas
   Trans_top #(.pckg_sz(pckg_sz)) item_top; //creamos una nueva transacción de un escenario
   bit posible_error;
   bit dstn_eq_orin;
   rand int iter;
   constraint cons_iter{3<=iter;iter<=300;}
   tipos_llenado tipo_llenado;               //handler del tipo llenado de la transaccion
   

  task run();//task donde corre el generador
    $display("[T=%0t] [Geneeeeee] iter = %p", $time,iter);
    case(tipo_llenado) //case para decidir si llenar la transaccion con datos aleatorios o con datos especificador por el usuario
        llenado_aleat: //genera una transaccion aleatoria
          begin 
            $display("[T=%0t] [Generador] Se ha escogido la transaccion de llenado aleatorio", $time);
            for (int i = 0; i < iter; i++) begin//en este ciclo se crean las transacciones
                item=new();  
                if(posible_error)begin
                  item.dtny_error.constraint_mode(1);       //Se enciende el constraint de mensajes con errores
                  item.limittar.constraint_mode(0);         //Se apaga el constraint de mensajes sin errores
                  $display("Posible errror");
                end else begin
                  item.dtny_error.constraint_mode(0);          //Se apaga el constraint destino != origen 
                  item.limittar.constraint_mode(1);         //Se enciende el constraint destino =origen     
                  $display("Mensaje sin errores");
                end

                if (dstn_eq_orin)begin
                  item.orin_dist_dtny.constraint_mode(0);          //Se apaga el constraint destino != origen 
                  item.orin_equal_dtny.constraint_mode(1);         //Se enciende el constraint destino =origen
                  item.limitorin.constraint_mode(0);         //apago constraint
                  $display("Destino = origen");
                end else begin
                  item.orin_dist_dtny.constraint_mode(1);          //Se enciende el constraint destino != origen 
                  item.orin_equal_dtny.constraint_mode(0);         //Se apaga el constraint destino =origen  
                  item.limitorin.constraint_mode(1);         //apago constraint                
                  $display("Dest != orin");
                end                           
               item.randomize();//generamos los valores aleatorios
                    $display ("[T=%0t] [Generator] Loop:%0d/%0d create next item", $time, i+1, iter);
                    
                    mlbx_aGENte_sb0.put(item);//manda el item hacia el scoreboard

                    mlbx_aGENte_drv0.put(item) ; //manda el item hacia el driver
                    item.print("[Generator] Transaccion enviada al driver");
            end
                $display ("[T=%0t] [Generator] Done generation of %0d items", $time, iter);
          end
      
        
        llenado_pld_espec: //genera una transaccion con algunos datos especificos
          begin 
            $display("[T=%0t] [Generador] Se ha escogido la transaccion de llenado especifico", $time);
            for (int i = 0; i < iter; i++) begin//en este ciclo se crean las transacciones
                item=new();
                if(posible_error)begin
                  item.dtny_error.constraint_mode(1);       //Se enciende el constraint de mensajes con errores
                  item.limittar.constraint_mode(0);         //Se apaga el constraint de mensajes sin errores
                  $display("Posible errror");
                end else begin
                  item.dtny_error.constraint_mode(0);          //Se apaga el constraint destino != origen 
                  item.limittar.constraint_mode(1);         //Se enciende el constraint destino =origen     
                  $display("Mensaje sin errores");
                end

                if (dstn_eq_orin)begin
                  item.orin_dist_dtny.constraint_mode(0);          //Se apaga el constraint destino != origen 
                  item.orin_equal_dtny.constraint_mode(1);         //Se enciende el constraint destino =origen
                  $display("Destino = origen");
                end else begin
                  item.orin_dist_dtny.constraint_mode(1);          //Se enciende el constraint destino != origen 
                  item.orin_equal_dtny.constraint_mode(0);         //Se apaga el constraint destino =origen     
                  $display("Dest != orin");
                end               

                item.randomize();//generamos los valores aleatorios       
                //aquí le caemos encima a lo que especifique el usuario
                    mlbx_top_aGENte0.get(item_top) ;
                        item.payload  =  item_top.pyld_espec;
                    $display ("[T=%0t] [Generator] Loop:%0d/%0d create next item", $time, i+1, iter);
                    mlbx_aGENte_sb0.put(item);//manda el item hacia el scoreboard
                    mlbx_aGENte_drv0.put(item) ; //manda el item hacia el driver
					         item.print("[Generator] Transaccion enviada al driver");
            end
                $display ("[T=%0t] [Generator] Done generation of %0d items", $time, iter);
          end
  
        llenado_dtny_espec: //genera una transaccion con algunos datos especificos
          begin 
            $display("[T=%0t] [Generador] Se ha escogido la transaccion de llenado especifico", $time);
            for (int i = 0; i < iter; i++) begin//en este ciclo se crean las transacciones
                item=new();
                if(posible_error)begin
                  item.dtny_error.constraint_mode(1);       //Se enciende el constraint de mensajes con errores
                  item.limittar.constraint_mode(0);         //Se apaga el constraint de mensajes sin errores
                  $display("Posible errror");
                end else begin
                  item.dtny_error.constraint_mode(0);          //Se apaga el constraint destino != origen 
                  item.limittar.constraint_mode(1);         //Se enciende el constraint destino =origen     
                  $display("Mensaje sin errores");
                end

                if (dstn_eq_orin)begin
                  item.orin_dist_dtny.constraint_mode(0);          //Se apaga el constraint destino != origen 
                  item.orin_equal_dtny.constraint_mode(1);         //Se enciende el constraint destino =origen
                  $display("Destino = origen");
                end else begin
                  item.orin_dist_dtny.constraint_mode(1);          //Se enciende el constraint destino != origen 
                  item.orin_equal_dtny.constraint_mode(0);         //Se apaga el constraint destino =origen     
                  $display("Dest != orin");
                end               

                item.randomize();//generamos los valores aleatorios        
                //aquí le caemos encima a lo que especifique el usuario
                    mlbx_top_aGENte0.get(item_top) ;
                        item.Target   =  item_top.dstny_espec;
                    $display ("[T=%0t] [Generator] Loop:%0d/%0d create next item", $time, i+1, iter);
                    mlbx_aGENte_sb0.put(item);    //manda el item hacia el scoreboard
                    mlbx_aGENte_drv0.put(item) ;  //manda el item hacia el driver
					         item.print("[Generator] Transaccion enviada al driver");
            end
                $display ("[T=%0t] [Generator] Done generation of %0d items", $time, iter);
          end
      

      
     endcase       
  endtask
endclass