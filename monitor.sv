///////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////Verificación de Circuitos Integrados////////////////////////////
/////////////////////////////////////Proyecto 2////////////////////////////////////////////
/////////////////////////Felipe Rojas, Agustín Degado, Alonso Vega/////////////////////////
// Definición de la clase del monitor
`include "transacciones.sv"

class read_dvc #(parameter pckg_sz=32, int tag = 0);
	mlbx_mntr_chckr to_chckr_mlbx;
	Trans_out #(.pckg_sz(pckg_sz)) to_chckr;
	virtual intfz #(.pckg_sz(pckg_sz)) vif;


	task run();
		$display("[%t] Monitor %d inicializado", $time, tag);
		@(posedge vif.clk);
		forever begin
			if (vif.pndng) begin
				to_chckr.Nxt_jumpO 	= vif.data_out[pckg_sz-1:pckg_sz-8][tag];
				to_chckr.TargetO 	= vif.data_out[pckg_sz-9:pckg_sz-16][tag];
				to_chckr.modeO 		= vif.data_out[pckg_sz-17][tag];
				to_chckr.payloadO 	= vif.data_out[pckg_sz-18:0];
				vif.pop = 1;
				if (vif.reset) begin
					/* code */
				end

			end
			@(posedge vif.clk);
		end
		
	endtask


endclass

class monitor();
	
endclass