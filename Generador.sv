//**************************************GENERADOR*******************************************
class Generador#(parameter pckg_sz=32);
  mailbox mlbx_gen_agte;  //buzon que va hacia el agente
  //event agen_listo;
  tipos_pyld type_payload=pyld_aleat; //handler del tipo de payload
  tipos_dtny type_destiny=dtnt_aleat; //handler del tipo de 
  tipos_orin type_origin=orin_aleat;

  task run();//task donde corre el generador
    case(tipo_llenado)//un case para saber si genera una transacción completamente aleatoria o con un caso de esquina
        llenado_aleatorio: //genera una transaccion aleatoria
          begin 
            $display("[T=%0t] [Generador] Se ha escogido la transaccion de llenado aleatorio", $time);
            for (int i = 0; i < iter; i++) begin//en este ciclo se crean las transacciones
              Bus_trans #(.pckg_sz(pckg_sz),.drivers(drivers),.tipocaso(tipocaso),.esquina(esquina)) item = new;//creamos una nueva transacción
               item.randomize();//generamos los valores aleatorios
                  for ( int h=0; h<item.delay;h++)//un ciclo para generar el delay aleatorio entre mensajes
                      begin
                        #1ns;
                      end
              $display ("[T=%0t] [Generator] Loop:%0d/%0d create next item", $time, i+1, iter);
              gen_agen.put(item);//manda el item hacia la capa inferior
              @(agen_listo);//espera a que el agente avise que ya tomo la transacción
                end
                $display ("[T=%0t] [Generator] Done generation of %0d items", $time, iter);
          end
        
        llenado_especifico: //genera una transaccion con algunos datos especificos
          begin
            $display("[T=%0t] [Generador] Se ha escogido la transaccion de llenado especifico", $time);
            for (int i = 0; i < iter; i++) begin
              Bus_trans #(.pckg_sz(pckg_sz),.drivers(drivers),.tipocaso(tipocaso),.esquina(esquina)) item = new;//creamos una nueva transacción
              item.randomize();
              case (corner)//en el case se asignan algunos valores que no sean aleatorios, dependiendo del caso elegido
                ceros:
                  begin
                    $display("[T=%0t] [Ambiente] Se ha escogido el caso de esquina con un payload de ceros", $time);
            		item.payload = {8{1'b0}};
                  end

        	    unos:
          		  begin
            		$display("[T=%0t] [Ambiente] Se ha escogido el caso de esquina con un payload de unos", $time);
            		item.payload = 8'b11111111;
          		  end

        		cerounos:
          		  begin
            		$display("[T=%0t] [Ambiente] Se ha escogido el caso de esquina con un payload de ceros-unos", $time);
            		item.payload= 8'b01010101;
          		  end

        		fakeaddress:
          		 begin
            		$display("[T=%0t] [Ambiente] Se ha escogido el caso de esquina con una direccion incorrecta", $time);
          		 end
        
        		brdcst:
          		  begin
            		$display("[T=%0t] [Ambiente] Se ha escogido mandar mensajes con broadcast",$time);
            		item.destino=broadcast;
          		  end
        
        		cero_lejos:
          		 begin
            		$display("[T=%0t] [Ambiente] Se ha escogido mandar mensajes con ceros a dispositivo más lejano",$time);
            		item.destino=drivers-1;
            		item.payload=8'b00000000;
            		item.Fifo_id=0;
          		 end
        
        		uno_cerca:
          		 begin
            		$display("[T=%0t] [Ambiente] Se ha escogido mandar mensajes con unos a un dispositivo adyacente",$time);
            		item.destino=drivers-1;
            		item.payload=8'b11111111;
            		item.Fifo_id=drivers-2;
          		 end
        
      		endcase
              for ( int h=0; h<item.delay;h++)//un ciclo para generar el delay aleatorio entre mensajes
                      begin
                        #1ns;
                      end
                  $display ("[T=%0t] [Generator] Loop:%0d/%0d create next item", $time, i+1, iter);
                  gen_agen.put(item);//manda el item hacia la capa inferior
                  @(agen_listo);//espera a que el agente avise que ya tomo la transacción
              end
              $display ("[T=%0t] [Generator] Done generation of %0d items", $time, iter);
          end
    endcase
  endtask
endclass

