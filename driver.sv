
// Curso: EL-5811 Verificación Funcional de Circuitos integrados
// Tecnologico de Costa Rica (www.tec.ac.cr)
// Profesor: Ronny García Ramírez 
// Desarrolladores:
// Felipe Josue Rojas-Barrantes (fjrojas.cr@gmail.com)
// José Agustín Delgado-Sancho (ahusjads@gmail.com)
// Luis Alonso Vega-Badilla (alonso9v9@gmail.com)
// Este script esta estructurado en System Verilog


class driver #(parameter pckg_sz=40,parameter disps=16,parameter Fif_Size=10);
	
	virtual intfz #(.pckg_sz(pckg_sz)) vif;

    mlbx_aGENte_drv aGENte_drv_mbx0;
    mlbx_drv_disp drv_disp_mbx [disps];

    // Para comunicar con el checker:
    mlbx_aGENte_drv drvr_chckr_mbx0;
    mlbx_drv_disp disp_drv_mbx [disps];

    Trans_in #(.pckg_sz(pckg_sz)) to_chckr;
      //Se define un item

    int espera;   
	

	task run();
		$display("[T=%g] [Driver] Inicializado",$time);
		
		//Reset del sistema en el primer ciclo de reloj
		@(posedge vif.clk);
		vif.reset=1;

		@(posedge vif.clk);
		forever begin
			Trans_in #(.pckg_sz(pckg_sz)) transaction; 
			vif.reset=0;

      		$display("[T=%g] [Driver] Esperando por una transaccion",$time);				
      		@(posedge vif.clk);
      		aGENte_drv_mbx0.get(transaction);
      		transaction.print("[Driver] Transaccion recibida del agente");

      		$display("[T=%g] [Driver] Transacciones pendientes en el mbx agnt_drv = %g",$time,aGENte_drv_mbx0.num());
			
      		case(transaction.tipo)
				
				normal:begin
					string s;
					s.itoa(transaction.Origen);
					drv_disp_mbx[transaction.Origen].put(transaction);
	     			transaction.print({"[Driver] Transaccion enviada al dispositivo ",s});
				end

				reset:begin
					vif.reset=1;
					transaction.tiempo = $time;
					transaction.print("[Driver] [Reset] Transaccion ejecutada");
				end

				default:begin
					$display("[T=%g] [Driver Error] la transaccion recibida no tiene tipo valido",$time);
	   	 			$finish;
				end
				
			endcase // transaction.tipo



			@(posedge vif.clk);
		end
	endtask

	task drvr_chckr_com();
		$display("[T=%g] [Driver] Comunicando con el checker", $time); 
		foreach(disp_drv_mbx[i]) begin
			automatic int auto_i = i;
			fork
				disp_drv_mbx[i] = new();
				forever begin
					disp_drv_mbx[i].get(to_chckr);
					drvr_chckr_mbx0.put(to_chckr);
				end
			join_none
		end
	endtask : drvr_chckr_com

endclass