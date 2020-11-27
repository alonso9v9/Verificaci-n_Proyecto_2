
// Curso: EL-5811 Verificación Funcional de Circuitos integrados
// Tecnologico de Costa Rica (www.tec.ac.cr)
// Profesor: Ronny García Ramírez 
// Desarrolladores:
// Felipe Josue Rojas-Barrantes (fjrojas.cr@gmail.com)
// José Agustín Delgado-Sancho (ahusjads@gmail.com)
// Luis Alonso Vega-Badilla (alonso9v9@gmail.com)
// Este script esta estructurado en System Verilog


class driver #(parameter pckg_sz=16,parameter disps=16,parameter Fif_Size=10);
	
	virtual intfz #(.pckg_sz(pckg_sz)) vif;

    mlbx_aGENte_drv aGENte_drv_mbx0;
    mlbx_drv_disp drv_disp_mbx [disps];

    Trans_in #(.pckg_sz(pckg_sz)) transaction;   //Se define un item

    int espera;   
	

	task run();
		$display("[T=%g] [Driver] Inicializado",$time);
		
		//Reset del sistema en el primer ciclo de reloj
		@(posedge vif.clk);
		vif.reset=1;

		@(posedge vif.clk);
		forever begin
			
			vif.reset=0;

      		$display("[T=%g] [Driver] Esperando por una transacción",$time);				
      		@(posedge vif.clk);
      		aGENte_drv_mbx0.get(transaction);
      		transaction.print("[Driver] Transaccion recibida del agente");

      		$display("[T=%g] [Driver]Transacciones pendientes en el mbx agnt_drv = %g",$time,aGENte_drv_mbx0.num());
			
      		case(transaction.tipo)
				
				normal:begin
					drv_disp_mbx[transaction.Origen].put(transaction);
	     			transaction.print("[Driver] Transaccion enviada al dispositivo específico");
				end

				reset:begin
					vif.reset=1;
					transaction.tiempo = $time;
					transaction.print("[Driver] Transaccion ejecutada");
				end

				default:begin
					$display("[T=%g] [Driver Error] la transacción recibida no tiene tipo valido",$time);
	   	 			$finish;
				end
				
			endcase // transaction.tipo



			@(posedge vif.clk);
		end
	endtask


endclass