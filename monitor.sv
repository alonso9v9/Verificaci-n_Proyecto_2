///////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////Verificación de Circuitos Integrados////////////////////////////
/////////////////////////////////////Proyecto 2////////////////////////////////////////////
/////////////////////////Felipe Rojas, Agustín Degado, Alonso Vega/////////////////////////
// Definición de la clase del monitor

// Esta clase monitorea cada dispositivo individualmente
class read_dvc #(parameter pckg_sz=32, int tag = 0);
	mlbx_mntr_chckr to_chckr_mlbx;
	Trans_out #(.pckg_sz(pckg_sz)) to_chckr;
	virtual intfz #(.pckg_sz(pckg_sz)) vif;

	task run();
		$display("[%t] Monitor %d inicializado", $time, tag);
		@(posedge vif.clk);
		forever begin
			if (vif.pndng) begin
				to_chckr.Nxt_jumpO 	= vif.data_out[tag][pckg_sz-1:pckg_sz-8];
				to_chckr.TargetO 	= vif.data_out[tag][pckg_sz-9:pckg_sz-16];
				to_chckr.modeO 		= vif.data_out[tag][pckg_sz-17];
				to_chckr.payloadO 	= vif.data_out[tag][pckg_sz-18:0];
				vif.pop = 1;
				if (vif.reset) begin
					to_chckr.tipo = reset;
				end else
				begin
					to_chckr.tipo = normal;
				end
				to_chckr_mlbx.put(to_chckr);
				to_chckr.print("[Monitor] Tansacción leída")
			end
			@(posedge vif.clk);
		end
	endtask

endclass

class monitor #(parameter pckg_sz=32);
	virtual intfz #(.pckg_sz(pckg_sz)) vif; // Interfaz virtual
	mlbx_mntr_chckr to_chckr_mlbx_p [15:0]; // Mailboxes para cada dispositivo

	task run();
		for (int i = 0; i < 16; i++) begin : _n
			read_dvc #(.pckg_sz(pckg_sz),.tag(i)) mntr;
			mntr.vif = vif;
			$display("Monitor número %d",mntr.tag);
		end		
	endtask

endclass