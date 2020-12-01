
// Curso: EL-5811 Verificación Funcional de Circuitos integrados
// Tecnologico de Costa Rica (www.tec.ac.cr)
// Profesor: Ronny García Ramírez 
// Desarrolladores:
// Felipe Josue Rojas-Barrantes (fjrojas.cr@gmail.com)
// José Agustín Delgado-Sancho (ahusjads@gmail.com)
// Luis Alonso Vega-Badilla (alonso9v9@gmail.com)
// Este script esta estructurado en System Verilog


class disp #(parameter pckg_sz=16,parameter Fif_Size=10);
	
    virtual intfz #(.pckg_sz(pckg_sz)) vif;

    bit [pckg_sz-1:0] Data;

    mlbx_drv_disp drv_disp_mbx;

    bit [pckg_sz-1:0] Fifo_in[$:Fif_Size-1];
    int espera;

    int id;

    string s;


	task run();
		
		$display("[T=%g] [Dispositivo=%g] inicializado.",$time,id);

		@(posedge vif.clk);
		forever begin
			Trans_in #(.pckg_sz(pckg_sz)) transaction; 
			vif.reset=0;
			espera = 0;

      		//@(posedge vif.clk);
      		$display("[T=%g] [Dispositivo=%g] Esperando transaccion.",$time,id);				
      		drv_disp_mbx.get(transaction);
      		$display("[T=%g] [Dispositivo=%g] Recibio la transaccion:",$time,id);
      		s.itoa(id);
      		transaction.print({"[Dispositivo=",s,"]"});

      		$display("[T=%g] [Dispositivo] Transacciones pendientes en el mbx drv_disp %g = %g",$time,id,drv_disp_mbx.num());

      		Data={8'b0, transaction.Target, transaction.mode, transaction.payload};
      		vif.data_out_i_in[transaction.Origen]=Fifo_in[$];


      		while(espera < transaction.delay)begin
        		@(posedge vif.clk);
          			espera = espera+1;
			end

			case(transaction.tipo)
				
				normal:begin
      				Fifo_in.push_front(Data); 	
					vif.pndng_i_in[transaction.Origen]=1;
					transaction.tiempo = $time;
	     			transaction.print("[Dispositivo] Transaccion ejecutada.");
				end

				reset:begin
					vif.reset=1;
					transaction.tiempo = $time;
					transaction.print("[Dispositivo] Transaccion ejecutada.");
				end

				default:begin
					$display("[T=%g] [Dispositivo Error] la transaccion recibida no tiene tipo valido.",$time);
	   	 			$finish;
				end

			endcase // transaction.tipo
			@(posedge vif.clk);
		end
	endtask
endclass