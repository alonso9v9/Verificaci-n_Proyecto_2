// Curso: EL-5811 Taller de Comunicaciones Electricas
// Tecnologico de Costa Rica (www.tec.ac.cr)
// Código consultado y adaptado: https://estudianteccr.sharepoint.com/sites/VerificacinFuncional/Documentos%20compartidos/General/Test_CR_fifo.zip -Realizado por: RONNY GARCIA RAMIREZ 
// Desarrolladores:
// José Agustín Delgado-Sancho (ahusjads@gmail.com)
// Alonso Vega-Badilla (alonso9v9@gmail.com)
// Este script esta estructurado en System Verilog
// Proposito General:
// Modulo Driver del testbench de un bus serial
//
//

class driver #(parameter pckg_sz=16,parameter disps=16,parameter Fif_Size=10);
	
	virtual intfz #(.pckg_sz(pckg_sz)) vif;

    mlbx_agte_drv agnt_drv_mbx;
    mlbx_drv_disp drv_disp_mbx [disps];

    Trans_in #(.pckg_sz(pckg_sz)) transaction;

    int espera;   
	
    disp #(.pckg_sz(pckg_sz),.Fif_Size(Fif_Size)) Dispositivos [disps];


	task run();
		$display("[T=%g] [Driver] Inicializado",$time);
		
		$display("[T=%g] [Driver] Inizializando todos los dispositivos",$time);

		foreach (Dispositivos[i]) begin
    		automatic int var_i = i;
    		fork
    			Dispositivos.id=var_i;
      			Dispositivos[var_i].run();
    		join_none 
  		end

  		$display("[T=%g] [Driver] Todos los dispositivos han sido inicializados",$time);
		//Reset del sistema en el primer ciclo de reloj
		@(posedge vif.clk);
		vif.reset=1;

		@(posedge vif.clk);
		forever begin
			
			vif.reset=0;

      		$display("[T=%g] [Driver] Esperando por una transacción",$time);				
      		@(posedge vif.clk);
      		agnt_drv_mbx.get(transaction);
      		transaction.print("[Driver] Transaccion recibida del agente");

      		$display("[T=%g] [Driver]Transacciones pendientes en el mbx agnt_drv = %g",$time,agnt_drv_mbx.num());
			
			drv_disp_mbx[transaction.Origen].put(transaction);
      		transaction.print("[Driver] Transaccion enviada al dispositivo");

			@(posedge vif.clk);
		end
	endtask


endclass