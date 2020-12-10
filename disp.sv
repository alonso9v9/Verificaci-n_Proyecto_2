
// Curso: EL-5811 Verificación Funcional de Circuitos integrados
// Tecnologico de Costa Rica (www.tec.ac.cr)
// Profesor: Ronny García Ramírez 
// Desarrolladores:
// Felipe Josue Rojas-Barrantes (fjrojas.cr@gmail.com)
// José Agustín Delgado-Sancho (ahusjads@gmail.com)
// Luis Alonso Vega-Badilla (alonso9v9@gmail.com)
// Este script esta estructurado en System Verilog


class disp #(parameter pckg_sz=40,parameter Fif_Size=10);
	
    virtual intfz #(.pckg_sz(pckg_sz)) vif;

    bit [pckg_sz-1:0] Data;

    mlbx_drv_disp drv_disp_mbx;

    // Para enviar las transacciones ejecutadas al checker
    // Primero van al driver y de ahí al chekcer
    mlbx_drv_disp disp_chckr_mbx;
    Trans_in #(.pckg_sz(pckg_sz)) to_chckr;
    bit [pckg_sz-1:0] pickup;

    bit [pckg_sz-1:0] Fifo_in[$:Fif_Size-1];
    int espera;

    int id=0;

    string s;
	
	bit on_off_fifodepth;


	task run();
		vif.pndng_i_in[id]=0;	
		vif.data_out_i_in[id]=0; 
   		if(on_off_fifodepth)begin
        	bit [pckg_sz-1:0] Fifo_in[$:Fif_Size-1];
      	end else begin
          	bit [pckg_sz-1:0] Fifo_in[$]; end


		$display("[T=%g] [Dispositivo=%g] inicializado.",$time,id);
		fork
			begin
				forever begin
					@(posedge vif.clk);
					if(vif.popin[id])begin
						Fifo_in.pop_back();
						if (!Fifo_in.size()) begin
							vif.pndng_i_in[id]=0;
						end
					end
				end
			end
			begin
				forever begin 
					Trans_in #(.pckg_sz(pckg_sz)) transaction=new(); 
					vif.reset=0;
					espera = 0;

					to_chckr = new();

		      		//@(posedge vif.clk);
		      		$display("[T=%g] [Dispositivo=%g] Esperando transaccion.",$time,id);				
		      		drv_disp_mbx.get(transaction);
		      		$display("[T=%g] [Dispositivo=%g] Recibio la transaccion:",$time,id);
		      		s.itoa(id);
		      		transaction.print({"[Dispositivo=",s,"]"});

		      		$display("[T=%g] [Dispositivo] Transacciones pendientes en el mbx drv_disp %g = %g",$time,id,drv_disp_mbx.num());

		      		Data={8'b0, transaction.Target, transaction.mode, transaction.payload};

		      		while(espera < transaction.delay)begin
		        		@(posedge vif.clk);
		          			espera = espera+1;
					end

					case(transaction.tipo)
						
						normal:begin
		      				Fifo_in.push_front(Data);
		      				vif.data_out_i_in[transaction.Origen]=Fifo_in[$]; 	
							vif.pndng_i_in[transaction.Origen]=1;
							transaction.tiempo = $time;
			     			transaction.print({"[Dispositivo=",s,"] Transaccion ejecutada."});
			     			// Envío al checker
			     			pickup = vif.data_out_i_in[transaction.Origen];
			     			to_chckr.Target = pickup[pckg_sz-9:pckg_sz-16];
			     			to_chckr.Origen = transaction.Origen;
			     			to_chckr.mode = pickup[pckg_sz-17:pckg_sz-17];
			     			to_chckr.payload = pickup[pckg_sz-18:0];
			     			to_chckr.tiempo = $time;
			     			to_chckr.tipo = transaction.tipo;
			     			to_chckr.print("[Dispositivo] Transaccion al checker.");
			     			disp_chckr_mbx.put(to_chckr);
						end

						reset:begin
							vif.reset=1;
							transaction.tiempo = $time;
							transaction.print({"[Dispositivo=",s,"] Transaccion ejecutada."});
							// Envío al checker
							// to_chckr = transaction;
			     			disp_chckr_mbx.put(transaction);
						end

						default:begin
							$display("[T=%g] [Dispositivo=%g Error] la transaccion recibida no tiene tipo valido.",$time,id);
			   	 			$finish;
						end

					endcase // transaction.tipo
					@(posedge vif.clk);
				end
			end
		join_none
	endtask
endclass