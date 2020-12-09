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
  //creamos una nueva transaccion de un escenario

  Trans_top #(.pckg_sz(pckg_sz)) item_top;
  virtual intfz #(.pckg_sz(pckg_sz))_if; //Definicion a la interface que se conecta el DUT.

  event llen_espc_done;
 
  tipos_pruebas tipo_prueba;
  mlbx_top_aGENte top_aGENte_mbx;
  tipos_llenado tipo_llenado;  
 
  parameter py_size=pckg_sz-17;

  
  function new;
  top_aGENte_mbx = new(); //creo el mailbox top-agente
  inst_amb       = new(); //creo la instancia del ambiente
  inst_amb.top_aGENte_mbx = top_aGENte_mbx;  //igualo los mailboxes
  inst_amb.aGen_inst.mlbx_top_aGENte0 = top_aGENte_mbx;  //igualo los mailboxes

   // inst_amb.aGen_inst.tipo_llenado=tipo_llenado;
    
  endfunction

  task run(event fin, event sb_done);
    inst_amb._if   = _if;    //igualo la interfaz virtual
    $display("[T=%0t] [Test] El test fue inicializado", $time);

    fork
       inst_amb.run(fin, sb_done); 
    join_none

/////////////////////////////////////////////////////////////////////////////////////////
//         AQUI SE SETTEA EL NUMERO DE PRUEBA QUE SE DESEA CORRER EN EL TEST           //
                           tipo_prueba    =    esc1_pru4;
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////
    
    case(tipo_prueba)
        esc1_pru1:
        begin
            inst_amb.aGen_inst.tipo_llenado = llenado_aleat;
            inst_amb.aGen_inst.iter=10; 
            inst_amb.aGen_inst.posible_error = 0;                   //Para que no se envien mensajes con errores
            inst_amb.aGen_inst.dstn_eq_orin  = 0;                   //Para que el destino sea distinto al origen
          for(int i=0; i<disps; i++)begin
            inst_amb.disp_inst[i].on_off_fifodepth=1'b0;            //Para poner la profundidad de los Fifos infinita
            end
        end
    
        esc1_pru2:
 
        begin
            inst_amb.aGen_inst.tipo_llenado = llenado_pld_espec;
            inst_amb.aGen_inst.iter=8; 
            inst_amb.aGen_inst.posible_error = 0;                   //Para que no se envien mensajes con errores
            inst_amb.aGen_inst.dstn_eq_orin  = 0;                   //Para que el destino sea distinto al origen                 
            for(int i=0; i<disps; i++)begin
              inst_amb.disp_inst[i].on_off_fifodepth=1'b0;          //Para poner la profundidad de los Fifos infinita
              end          
            for(int i=0; i<inst_amb.aGen_inst.iter;i++)
              begin
                item_top=new;
                if(i%4==0)begin
                  item_top.pyld_espec={py_size{4'h0}}; 
                  end else
                if(i%4==1)begin
                  item_top.pyld_espec={py_size{4'hf}};
                  end else
                if(i%4==2)begin
                  item_top.pyld_espec={py_size{4'hA}};
                  end else
                if(i%4==3)begin
                  item_top.pyld_espec={py_size{4'h5}};
                end
                top_aGENte_mbx.put(item_top) ;
              end
        end
    
        esc1_pru3:
          
        begin
            inst_amb.aGen_inst.tipo_llenado = llenado_dtny_espec;
            inst_amb.aGen_inst.iter=32; 
            inst_amb.aGen_inst.posible_error = 0;                   //Para que no se envien mensajes con errores
            inst_amb.aGen_inst.dstn_eq_orin  = 0;                   //Para que el destino sea distinto al origen                  
            for(int i=0; i<disps; i++)begin
              inst_amb.disp_inst[i].on_off_fifodepth=1'b0;          //Para poner la profundidad de los Fifos infinita
              end          
            for(int i=0; i<inst_amb.aGen_inst.iter;i++)
              begin
                item_top=new;
                if(i%4==0)begin
                  item_top.dstny_espec=8'b00000001; 
                  end else
                if(i%4==1)begin
                  item_top.dstny_espec=8'b00000010;
                  end else
                if(i%4==2)begin
                  item_top.dstny_espec=8'b00000011;
                  end else
                if(i%4==3)begin
                  item_top.dstny_espec=8'b00000100;
                  end else
                if(i%4==2)begin
                  item_top.dstny_espec=8'b00010000;
                  end else
                if(i%4==2)begin
                  item_top.dstny_espec=8'b00100000;
                  end else
                if(i%4==2)begin
                  item_top.dstny_espec=8'b00110000;
                  end else
                if(i%4==2)begin
                  item_top.dstny_espec=8'b01000000;
                  end else
                if(i%4==2)begin
                  item_top.dstny_espec=8'b01010001;
                  end else
                if(i%4==2)begin
                  item_top.dstny_espec=8'b01010010;
                  end else
                if(i%4==2)begin
                  item_top.dstny_espec=8'b01010011;
                  end else
                if(i%4==2)begin
                  item_top.dstny_espec=8'b01010100;
                  end else
                if(i%4==2)begin
                  item_top.dstny_espec=8'b00010101;
                  end else
                if(i%4==2)begin
                  item_top.dstny_espec=8'b00100101;
                  end else
                if(i%4==2)begin
                  item_top.dstny_espec=8'b00110101;
                  end else
                if(i%4==2)begin
                  item_top.dstny_espec=8'b01000101;
                  end 
                
                top_aGENte_mbx.put(item_top) ;
              end
        end
      
      
      esc1_pru4:                                                    //Prueba con Fifos de profundidad finita aleatoria.
        begin
            inst_amb.aGen_inst.tipo_llenado = llenado_aleat;
            inst_amb.aGen_inst.iter=10; 
            inst_amb.aGen_inst.posible_error = 0;                   //Para que se envien mensajes con errores
            inst_amb.aGen_inst.dstn_eq_orin  = 0;                   //Para que el destino sea distinto al origen          
          for(int i=0; i<disps; i++)begin
            inst_amb.disp_inst[i].on_off_fifodepth=1'b1;            //Para poner la profundidad de los Fifos finita y aleatoria
            end          
        end
       
        esc2_pru1:                                                  //Prueba para ingresar mensajes con errores.
        begin
            inst_amb.aGen_inst.tipo_llenado = llenado_aleat;
            inst_amb.aGen_inst.iter=8;
          $display("[T=%0t] Corriendo Escenario 2 prueba 1",$time);
            inst_amb.aGen_inst.posible_error = 1;                   //Para que se envien mensajes con errores
            inst_amb.aGen_inst.dstn_eq_orin  = 0;                   //Para que el destino sea distinto al origen          
            for(int i=0; i<disps; i++)
              inst_amb.disp_inst[i].on_off_fifodepth=1'b0;           //Para poner la profundiodad de las Fifos infinita
        end

        esc2_pru2:
        begin
            inst_amb.aGen_inst.tipo_llenado = llenado_aleat;
            inst_amb.aGen_inst.iter=10; 
            inst_amb.aGen_inst.posible_error = 0;                   //Para que no se envien mensajes con errores
            inst_amb.aGen_inst.dstn_eq_orin  = 1;                   //Para que el destino sea igual al origen             
          for(int i=0; i<disps; i++)begin
            inst_amb.disp_inst[i].on_off_fifodepth=1'b0;            //Para poner la profundidad de los Fifos infinita
            end
        end
      

        


        
    endcase

  endtask
endclass