class scoreboard #(parameter pckg_sz);
	// Mailboxes
	mlbx_aGENte_sb from_agnt_mlbx; 		// Agente - scoreboard
	
	mlbx_mntr_chckr from_chckr_mlbx; 	// Checker - scoreboard

	Trans_in #(.pckg_sz(pckg_sz)) from_agnt_item;  // Item del agente

	Trans_out #(.pckg_sz(pckg_sz)) from_chckr_item; // Item del checker

	// Transacciones recibidas del agente/gen 
	// Cada transacción generada por el agente se guarda en un queue según el destino de la transacción
	Trans_in sb_generadas [16][$]; 	// Se crea un queue para cada dispositivo

	Trans_out sb_completadas [$];  	// Este queue guardará las transacciones que se completen con éxito

	bit [7:0] dir [15:0] = {8'b00000001, 8'b00000010,8'b00000011,8'b00000100,8'b00010000,8'b00100000,8'b00110000,8'b01000000,8'b01010001,8'b01010010,8'b01010011,8'b01010100,8'b00010101,8'b00100101,8'b00110101,8'b01000101};
	// {{8'b00000001}, {8'b00000010}, {8'b00000011}, {8'b00000100}, {8'b00010000}, {8'b00100000}, {8'b00110000}, {8'b01000000}, {8'b01010001}, {8'b01010010}, {8'b01010011}, {8'b01010100}, {8'b00010101}, {8'b00100101}, {8'b00110101}, {8'b01000101}};
	function new ();

		foreach(sb_generadas[i]) begin
			this.sb_generadas[i] = {};
		end

		this.sb_completadas = {};

	endfunction

	task run(event fin, event sb_done);

		$display("[T=%g] El scoreboard fue inicializado.",$time);
		 $system("echo 'Dato enviado, Dato recibdo, Terminal de procedencia, Terminal de destino, Tiempo de envío, Tiempo de recibido, Latencia, Modo, Tipo de transacción' > output.csv");
		fork
			run_sb_gen;
			run_sb_chckr;
		join_none
		wait (fin.triggered);
		// Generar reportes
		$display("[T=%g] [Scoreboard] Reporte generado", $time);
		-> sb_done;
	endtask : run

	// Este recibe las transacciones del generador, las guarda en sb_generadas y se las envía al checker
	task run_sb_gen();
		forever begin
			
			from_agnt_mlbx.get(from_agnt_item);
			// Se guarda el item recibido del generador en la lista correspondiente al destino del item
			from_agnt_item.print("[Scoreboard] Transacción recibida del Generador.");
			foreach(dir[i]) begin
				if (dir[i] == from_agnt_item.Target) begin
					sb_generadas[i].push_front(from_agnt_item);
				end
			end
		end
	endtask : run_sb_gen

	// Este task se encarga de recibir los reportes del checker y guardarlos en el archivo .csv
	////////////////////////////////////////////////////////////////////////
	// FALTA LO DEL .CSV ///////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////////
	task run_sb_chckr();
		forever begin
			
			from_chckr_mlbx.get(from_chckr_item);
			from_chckr_item.print("[Scoreboard] Transacción completada recibida del Checker.");

			// Se guarda la transacción completada en sb_completadas
			sb_completadas.push_front(from_chckr_item);

		end
	endtask : run_sb_chckr
endclass : scoreboard