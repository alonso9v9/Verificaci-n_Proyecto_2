// Curso: EL-5811 Verificación Funcional de Circuitos integrados
// Tecnologico de Costa Rica (www.tec.ac.cr)
// Profesor: Ronny García Ramírez 
// Desarrolladores:
// Felipe Josue Rojas-Barrantes (fjrojas.cr@gmail.com)
// José Agustín Delgado-Sancho (ahusjads@gmail.com)
// Luis Alonso Vega-Badilla (alonso9v9@gmail.com)
// Este script esta estructurado en System Verilog

// Definición de la clase del monitor

// Esta clase monitorea cada dispositivo individualmente


class read_dvc #(parameter pckg_sz=32);
	mlbx_mntr_chckr to_chckr_mlbx;
	Trans_out #(.pckg_sz(pckg_sz)) to_chckr;
	virtual intfz #(.pckg_sz(pckg_sz)) vif;
	int tag = 0;

	task run();
		$display("[T=%g] Monitor %g inicializado", $time, tag);
		@(posedge vif.clk);
		forever begin
			vif.pop[tag] <= 0;
			if (vif.pndng[tag]) begin  
				to_chckr.TargetO 	= vif.data_out[tag][pckg_sz-9:pckg_sz-16];
				to_chckr.modeO 		= vif.data_out[tag][pckg_sz-17];
				to_chckr.payloadO 	= vif.data_out[tag][pckg_sz-18:0];
				vif.pop[tag] <= 1;
				if (vif.reset) begin
					to_chckr.tipo = reset;
				end else
				begin
					to_chckr.tipo = normal;
				end
				to_chckr_mlbx.put(to_chckr);
				to_chckr.print("[Monitor] Tansacción leída");
			end
			@(posedge vif.clk);
		end
	endtask

endclass

class monitor #(parameter pckg_sz=32);
	virtual intfz #(.pckg_sz(pckg_sz)) vif; // Interfaz virtual
	mlbx_mntr_chckr to_chckr_mlbx_p [15:0]; // Mailboxes para cada dispositivo
	read_dvc #(.pckg_sz(pckg_sz)) dvcs [15:0];

	task run();
		for (int i = 0; i < 16; i++) begin
			automatic int auto_i = i;
			fork
				dvcs[auto_i].tag = auto_i;
				dvcs[auto_i].to_chckr_mlbx = to_chckr_mlbx_p;
				dvcs[auto_i].vif = vif;
				dvcs[auto_i].run();
			join_none
		end		
	endtask

endclass