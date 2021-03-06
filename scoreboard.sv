class scoreboard #(parameter pckg_sz);
	// Mailboxes
	mlbx_aGENte_sb from_agnt_mlbx; 		// Agente - scoreboard
	
	mlbx_mntr_chckr from_chckr_mlbx; 	// Checker - scoreboard

	Trans_in #(.pckg_sz(pckg_sz)) from_agnt_item;  // Item del agente

	Trans_out #(.pckg_sz(pckg_sz)) from_chckr_item; // Item del checker

	real av_delay;
	// Transacciones recibidas del agente/gen 
	// Cada transacción generada por el agente se guarda en un queue según el destino de la transacción
	Trans_in sb_generadas [16][$]; 	// Se crea un queue para cada dispositivo

	Trans_out sb_completadas [$];  	// Este queue guardará las transacciones que se completen con éxito

	bit [7:0] dir [15:0] = {8'b00000001, 8'b00000010,8'b00000011,8'b00000100,8'b00010000,8'b00100000,8'b00110000,8'b01000000,8'b01010001,8'b01010010,8'b01010011,8'b01010100,8'b00010101,8'b00100101,8'b00110101,8'b01000101};
	// {{8'b00000001}, {8'b00000010}, {8'b00000011}, {8'b00000100}, {8'b00010000}, {8'b00100000}, {8'b00110000}, {8'b01000000}, {8'b01010001}, {8'b01010010}, {8'b01010011}, {8'b01010100}, {8'b00010101}, {8'b00100101}, {8'b00110101}, {8'b01000101}};
	
	string d_env;
	string destino;
	string origen;
	string t_envio;
	string t_recib;
    string lat;
    string linea_csv;
    string muestra;
    string modo;

	function new ();

		foreach(sb_generadas[i]) begin
			this.sb_generadas[i] = {};
		end

		this.sb_completadas = {};

	endfunction

	task run(event fin, event sb_done);

		$display("[T=%g] El scoreboard fue inicializado.",$time);
		$system("echo 'Muestra, Dato enviado, Dato recibdo, Terminal de procedencia, Terminal de destino, Tiempo de envío, Tiempo de recibido, Latencia, Modo, Tipo de transacción' > output.csv");
		fork
			run_sb_gen;
			run_sb_chckr;
		join_none
		wait (fin.triggered);
		$display("%g",av_delay);
		// Generar reportes
		$display("[T=%g] [Scoreboard] Reporte generado", $time);
		-> sb_done;
	endtask : run

	// Este recibe las transacciones del generador, las guarda en sb_generadas y se las envía al checker
	task run_sb_gen();
		forever begin
			
			from_agnt_mlbx.get(from_agnt_item);
			// Se guarda el item recibido del generador en la lista correspondiente al destino del item
			from_agnt_item.print("[Scoreboard] Transaccion recibida del Generador.");
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
		int cont=0;
		av_delay=0;
		forever begin
			from_chckr_mlbx.get(from_chckr_item);
			from_chckr_item.print("[Scoreboard] Transaccion completada recibida del Checker.");
			
			cont=cont+1;
			av_delay=av_delay*(cont-1);
			av_delay=(av_delay+from_chckr_item.latencia)/cont;
			// Se guarda la transacción completada en sb_completadas
			sb_completadas.push_front(from_chckr_item);
			newRowOut(from_chckr_item, cont);

		end
	endtask : run_sb_chckr

	function void newRowOut(const ref Trans_out from_chckr_item, int cont);
	    d_env.hextoa(from_chckr_item.payloadO);
	    destino.itoa(from_chckr_item.dvc);
	    origen.itoa(from_chckr_item.Origen);
	    t_envio.itoa(from_chckr_item.tiempo_envio);
	    t_recib.itoa(from_chckr_item.delayO);
        lat.itoa(from_chckr_item.latencia);
        muestra.itoa(cont);
        modo.hextoa(from_chckr_item.modeO);
        linea_csv = {muestra,",",d_env,",",origen,",",destino,",",t_envio,",",t_recib,",",lat,",",modo};
        $system($sformatf("echo %0s, %0s >> output.csv",linea_csv,from_chckr_item.tipo));
    endfunction

endclass : scoreboard