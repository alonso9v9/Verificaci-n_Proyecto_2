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


class read_dvc #(parameter pckg_sz=40);
	mlbx_mntr_chckr to_chckr_mlbx;
	Trans_out #(.pckg_sz(pckg_sz)) to_chckr;
	virtual intfz #(.pckg_sz(pckg_sz)) vif;
	int tag = 0;
	bit [pckg_sz-1:0]data;

	task run();
		$display("[T=%g] [Monitor] Dispositivo %g inicializado.", $time, tag);
		@(posedge vif.clk);
		$display("[T=%g] [Monitor] Clock recibido por el dispositivo %g.", $time, tag);
		vif.pop[tag] = 0;
		forever begin
			// $display("[T=%g] [Monitor] Pending %b",$time, vif.pndng[tag]);
			@(posedge vif.pndng[tag]);
				to_chckr=new;

				data = vif.data_out[tag];
				to_chckr.TargetO 	= data[pckg_sz-9:pckg_sz-16];
				to_chckr.modeO 		= data[pckg_sz-17];
				to_chckr.payloadO 	= data[pckg_sz-18:0];
				vif.pop[tag] = 1;
				if (vif.reset) begin
					to_chckr.tipo = reset;
				end else
				begin
					to_chckr.tipo = normal;
				end
				to_chckr.delayO=$time;
				to_chckr.dvc = tag;
				to_chckr_mlbx.put(to_chckr);
				to_chckr.print("[Monitor] Tansaccion leida");
				@(posedge vif.clk);
					vif.pop[tag] = 0;
			@(posedge vif.clk);
		end
	endtask

endclass

class monitor #(parameter pckg_sz=40);
	virtual intfz #(.pckg_sz(pckg_sz)) vif; // Interfaz virtual
	mlbx_mntr_chckr to_chckr_mlbx_p; 		// Mailboxe hacia el checker
	mlbx_mntr_chckr mlbx_dvc[16];			// Mailboxes para cada dispositivo
	read_dvc #(.pckg_sz(pckg_sz)) dvcs [16];

	Trans_out #(.pckg_sz(pckg_sz)) item;

	// Para sincronizar la comunicacion con el checker
	// semaphore sem;

	function new();

		foreach(dvcs[i]) begin

		   this.dvcs[i] = new();
		   this.dvcs[i].to_chckr_mlbx=new();
		   this.mlbx_dvc[i]=new();
		   this.dvcs[i].tag = i;
		   this.dvcs[i].to_chckr_mlbx = mlbx_dvc[i];
		   $display("todos los dvcs inicializados");
		end
	endfunction 

	task run();
		// sem = new(1);

		begin 
			$display("[T=%g] El monitor fue inicializado.", $time);
			foreach(this.dvcs[i]) begin
				automatic int auto_i = i;
				mlbx_dvc[auto_i] = new();
				fork
					begin
						this.dvcs[auto_i].run();
					end
				join_none
			end
			foreach(this.dvcs[i]) begin
				automatic int auto_i = i;
				fork
					forever begin 
						item = new();
						this.dvcs[auto_i].to_chckr_mlbx.get(item);
						to_chckr_mlbx_p.put(item);
						item.print("[Monitor] Transaccion enviada al checker");
					end
				join_none
			end
		end
	endtask

endclass