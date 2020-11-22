///////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////Verificación de Circuitos Integrados////////////////////////////
/////////////////////////////////////Proyecto 2////////////////////////////////////////////
/////////////////////////Felipe Rojas, Agustín Degado, Alonso Vega/////////////////////////


class disp #(parameter pckg_sz=16,parameter Fif_Size=10,parameter id=0);
	
    virtual Mesh_if #(.width(width)) vif;

    bit [pckg_sz-1,0] Data;

    mlbx_drv_disp drv_disp_mbx;
    Trans_in #(.pckg_sz(pckg_sz)) transaction;

    bit Fifo_in[$:Fif_Size-1];
    int espera;   


	task run();
		
		$display("[%g] [Dispositivo=%g] inicializado",$time,id);

		@(posedge vif.clk);
		forever begin
			
			vif.reset=0;
			espera = 0;

      		@(posedge vif.clk);
      		$display("[T=%g] [Dispositivo=%g] Esperando transaccion",$time,id);				
      		drv_disp_mbx.get(transaction);
      		transaction.print("[Dispositivo] Recibio la transaccion");

      		$display("[T=%g] [Dispositivo] Transacciones pendientes en el mbx drv_disp %g = %g",id,drv_disp_mbx.num());

      		Data={transaction.Nxt_jump, transaction.Target, transaction.mode, transaction.payload};
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
	     			transaction.print("[Dispositivo] Transaccion ejecutada");
				end

				reset:begin
					vif.reset=1;
					transaction.tiempo = $time;
					transaction.print("[Dispositivo] Transaccion ejecutada");
				end

				default:begin
					$display("[T=%g] [Dispositivo Error] la transacción recibida no tiene tipo valido",$time);
	   	 			$finish;
				end
			endcase // transaction.tipo
			@(posedge vif.clk);
		end
	endtask
endclass