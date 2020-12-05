// Curso: EL-5811 Verificación Funcional de Circuitos integrados
// Tecnologico de Costa Rica (www.tec.ac.cr)
// Profesor: Ronny García Ramírez 
// Desarrolladores:
// Felipe Josue Rojas-Barrantes (fjrojas.cr@gmail.com)
// José Agustín Delgado-Sancho (ahusjads@gmail.com)
// Luis Alonso Vega-Badilla (alonso9v9@gmail.com)
// Este script esta estructurado en System Verilog





class Top#(parameter pckg_sz =40,parameter disps =16,parameter fifo_depth=10);
   
        ambiente #(.pckg_sz(pckg_sz),.disps(16),.fifo_depth(fifo_depth)) inst_amb;  //Definicion del ambiente de la prueba.
       Trans_top #(.pckg_sz(pckg_sz)) item_top=new; //creamos una nueva transaccion de un escenario


       virtual intfz #(.pckg_sz(pckg_sz))_if; //Definicion a la interface que se conecta el DUT.

       event llen_espc_done;
 
  	   tipos_pruebas tipo_prueba;
       mlbx_top_aGENte top_aGENte_mbx;
       tipos_llenado tipo_llenado;
  
 


  
    function new;
    top_aGENte_mbx = new(); //creo el mailbox top-agente
    inst_amb       = new(); //creo la instancia del ambiente
    inst_amb.top_aGENte_mbx = top_aGENte_mbx;  //igualo los mailboxes
    inst_amb.aGen_inst.mlbx_top_aGENte0 = top_aGENte_mbx;  //igualo los mailboxes
      
     // inst_amb.aGen_inst.tipo_llenado=tipo_llenado;
      
    endfunction

    task run();
    inst_amb._if   = _if;    //igualo la interfaz virtual
    $display("[T=%0t] [Test] El test fue inicializado", $time);
      fork
         inst_amb.run(); 
      join_none

/////////////////////////////////////////////////////////////////////////////////////////
//         AQUI SE SETTEA EL NUMERO DE PRUEBA QUE SE DESEA CORRER EN EL TEST           //
                           tipo_prueba    =    esc1_pru2;
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////
    
        case(tipo_prueba)
            esc1_pru1:
            begin
                tipo_llenado = llenado_aleat;
                inst_amb.aGen_inst.iter=3; 
              for(int i=0; i<disps; i++)
                inst_amb.disp_inst[i].on_off_fifodepth=1'b0;
               
            end
        
            esc1_pru2:
     
            begin
                inst_amb.aGen_inst.tipo_llenado = llenado_espec;
                inst_amb.aGen_inst.iter=8; 
                for(int i=0; i<inst_amb.aGen_inst.iter;i++)
                  begin
                        if(i%4==0)begin
                          item_top.pyld_espec='h0; 
                         // top_aGENte_mbx.put(item_top) ;
                          $display("[T=%0t]ceros",$time);
                              end else
                        if(i%4==1)begin
                          item_top.pyld_espec='hf;
                        //  top_aGENte_mbx.put(item_top) ;
                          $display("[T=%0t]unos",$time);
                              end else
                        if(i%4==2)begin
                          item_top.pyld_espec='hA;
                        //  top_aGENte_mbx.put(item_top) ;
                          $display("[T=%0t]unosceros",$time);
                              end else
                        if(i%4==3)begin
                          item_top.pyld_espec='h5;
                        //  top_aGENte_mbx.put(item_top) ;
                          $display("[T=%0t]cerosunos",$time);
                           
                        end
                    top_aGENte_mbx.put(item_top) ;
                  end

            end
        /*
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
            end*/
        endcase

    endtask
endclass