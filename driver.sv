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

class disp #(parameter pckg_sz=16,parameter disps=16,parameter Fif_Size=10);
	
    virtual Mesh_if #(.width(width)) vif;
    Trans_in_mbx agnt_drv_mbx;
    Trans_Mesh_mbx drv_mesh_mbx [disps];

    Trans_in #(.pckg_sz(pckg_sz)) transaction;

    int espera;   
	

	task run();
		$display("[%g] El driver fue inicializado",$time);
		
		//Reset del sistema en el primer ciclo de reloj
		@(posedge vif.clk);
		vif.reset=1;

		foreach(vif.pndng[i]) begin
			vif.pndng[i]=0;
			vif.D_pop[i]=0;
		end

		@(posedge vif.clk);
		forever begin
			
			vif.reset=0;
			espera = 0;

      		
      		$display("[%g] el Driver espera por una transacción",$time);				
      		@(posedge vif.clk);
      		agnt_drv_mbx.get(transaction);
      		transaction.print("Driver: Transaccion recibida del agente");
      		$display("Transacciones pendientes en el mbx agnt_drv = %g",agnt_drv_mbx.num());

      		while(espera < transaction.retardo)begin
        		@(posedge vif.clk);
          			espera = espera+1;
			end

			case(transaction.tipo)
				normal:begin
					drv_mesh_mbx[transaction.Target].put(transaction)

                  	vif.D_pop[0][transaction.Origen]=D_out[transaction.Origen][0];
					vif.pndng[0][transaction.Origen]=1;
					transaction.tiempo = $time;
	     			transaction.print("Driver: Transaccion ejecutada");
				end

				reset:begin
					vif.reset=1;
					transaction.tiempo = $time;
					transaction.print("Driver: Transaccion ejecutada");
				end

				default:begin
					$display("[%g] Driver Error: la transacción recibida no tiene tipo valido",$time);
	   	 			$finish;
				end
			endcase // transaction.tipo
			@(posedge vif.clk);
		end
	endtask
endclass