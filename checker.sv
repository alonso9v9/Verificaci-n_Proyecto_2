

// Interfaz del bus
module  bus_if_emu #(parameter pckg_sz = 40, parameter Fif_Size=10, parameter [7:0] id = 0, parameter id_r =0, parameter id_c = 0, parameter columns=4, parameter rows=4) (
	input clk,    // Clock
	input rst,  // Asynchronous reset active high
	
	input [pckg_sz-1:0] Data_out_i_in,
	input pndng_i_in,
	input pop,
	output reg Popin,
	output reg [pckg_sz-1:0] Data_out,
	output reg pndng,

	output [pckg_sz-1:0] Data_out_i,
	output pndng_i,
	input pop_i,
	input [1:0] Trn,
	input [pckg_sz-1:0] Data_in_i,
	input push_i
);

	bit Fifo_out[$:Fif_Size-1];

	// DECO (por ahora usa el mismo código del DUT)
	s_routing_table #(.id_r(id_r), .id_c(id_c), .pckg_sz(pckg_sz), .columns(columns), .rows(rows)) deco (.Data_in(Data_out_i_in), .Data_out_i(Data_out_i));

	// Bloques combinacionales
	assign pndng_i = pndng_i_in;
	
	always_comb begin
		if (pop_i && (Trn == id)) begin
			Popin <= 1;
		end else
		begin
			Popin <= 0;
		end
	end

	// FIFO
	always @(posedge clk or posedge rst) begin
		if(rst) begin
			Data_out <= 0;
			pndng <= 0;
		end else if (clk) begin
			// pndng
			if (Fifo_out.size()) begin
				pndng <= 1;
			end else begin
				pndng <= 0;
			end
			// pop
			if (pop) begin
				Data_out <= Fifo_out[$];
				Fifo_out.pop_back();
			end
			// push
			if ((Data_in_i[pckg_sz-1:pckg_sz-8] == id) && push_i) begin
				Fifo_out.push_front(Data_in_i);
			end
		end
	end

endmodule


// Árbitro del router
module arbiter #(parameter pckg_sz = 40, parameter Fif_Size=10, parameter id_r =0, parameter id_c = 0, parameter columns=4, parameter rows=4) (
	input clk,    // Clock
	input rst,	  // Asynchronous reset active high

	input pndng_i [4],
	input [pckg_sz-1:0] Data_out_i [4],

	output reg [1:0] Trn,
	output reg push_i,
	output reg pop_i,
	output reg [pckg_sz-1:0] Data_in_i

);
	wire clk_en; // Clock enable
	int estado = 0; // Estado de la máquina de Mealy
	int estado_sig;
	int cont = 0; // Contador
	bit Cnt_en;
	
	assign clk_en = pndng_i[0] | pndng_i[1] | pndng_i[2] | pndng_i[3];

	always @(posedge clk & clk_en) begin 
		Trn = cont;
		case (estado)
			0:begin // rst
				// Señales
				Cnt_en <= 1;
				push_i <= 0;
				pop_i <= 0;
				if (!pndng_i[cont]) begin
					estado_sig = estado; // Estado siguiente: rst
				end else begin
					estado_sig = 1; 	//Estado siguiente: psh1
				end
			end
			1:begin // psh1
				estado_sig = 3; // Estado siguiente: pop1
				// Señales
				Cnt_en <= 0;
				push_i <= 1;
				pop_i <= 0;
			end
			3:begin // pop1
				estado_sig = 0; // Estado siguiente: rst
				// Señales
				Cnt_en <= 0;
				push_i <= 0;
				pop_i <= 1;
			end
			default : $display("[Emulador: arbiter] Estado inválido");
		endcase
		estado = estado_sig;
		Data_in_i <= Data_out_i[cont];
		// Contador para el siguiente ciclo
		if (Cnt_en) cont++;
		if (cont == 4) cont = 0;

	end
endmodule

// Definición del router individual
module router #(parameter pckg_sz = 40, parameter Fif_Size=10, parameter id_r =0, parameter id_c = 0, parameter columns=4, parameter rows=4)(
	input clk,    // Clock
	input rst,  // Asynchronous reset active high

	input [pckg_sz-1:0] Data_out_i_in [4], 
	input pndng_i_in [4], 
	input pop [4],
	output Popin [4],
	output [pckg_sz-1:0] Data_out [4],
	output pndng [4]
);

wire [pckg_sz-1:0] Data_out_i [4];
wire pndng_i [4];

wire [1:0] Trn;
wire push_i;
wire pop_i;
wire [pckg_sz-1:0] Data_in_i;

genvar i;

generate
	for (i = 0; i < 4; i++) begin : _rtr_
		bus_if_emu #(.pckg_sz(pckg_sz), .Fif_Size(Fif_Size), .id(i), .id_r(id_r), .id_c(id_c), .columns(columns), .rows(rows)) intfc (
			.clk(clk),
			.rst(rst),
			.Data_out_i_in(Data_out_i_in[i]), 
			.pndng_i_in(pndng_i_in[i]), 
			.pop(pop[i]),
			.Popin(Popin[i]),
			.Data_out(Data_out[i]),
			.pndng(pndng[i]),

			.Data_out_i(Data_out_i[i]), 
			.pndng_i(pndng_i[i]), 
			.pop_i(pop_i),
			.Trn(Trn),
			.Data_in_i(Data_in_i),
			.push_i(push_i)
		);
	end
endgenerate

arbiter #(.pckg_sz(pckg_sz), .Fif_Size(Fif_Size), .id_r(id_r), .id_c(id_c), .columns(columns), .rows(rows)) rbtr_inst(
	.clk       (clk),
	.rst       (rst),
	.pndng_i   (pndng_i),
	.Data_out_i(Data_out_i),
	.Trn       (Trn),
	.push_i    (push_i),
	.pop_i     (pop_i),
	.Data_in_i (Data_in_i)
);

endmodule

// Definición del emulador del mesh
module mesh_emu #(parameter ROWS = 4, parameter COLUMS =4, parameter pckg_sz =40, parameter fifo_depth = 4)(
	input clk,    // Clock
	input rst,  // Asynchronous reset active high
	output logic pndng[ROWS*2+COLUMS*2],
  	output logic [pckg_sz-1:0] data_out[ROWS*2+COLUMS*2],
  	output logic popin[ROWS*2+COLUMS*2],
  	input pop[ROWS*2+COLUMS*2],
  	input [pckg_sz-1:0]data_out_i_in[ROWS*2+COLUMS*2],
  	input pndng_i_in[ROWS*2+COLUMS*2]
);

//// Conexiones entre routers

/// Conexiones horizontales
// Datos hacia la derecha
logic pndng_der [ROWS:1][COLUMS:0];
logic [pckg_sz-1:0] data_der [ROWS:1][COLUMS:0];
logic pop_der [ROWS:1][COLUMS:0];
// Datos hacia la izquierda
logic pndng_iz [ROWS:1][COLUMS:0];
logic [pckg_sz-1:0] data_iz [ROWS:1][COLUMS:0];
logic pop_iz [ROWS:1][COLUMS:0];

/// Conexiones verticales
// Datos hacia arriba
logic pndng_ar [ROWS:0][COLUMS:1];
logic [pckg_sz-1:0] data_ar [ROWS:0][COLUMS:1];
logic pop_ar [ROWS:0][COLUMS:1];
// Datos hacia abajo
logic pndng_ab [ROWS:0][COLUMS:1];
logic [pckg_sz-1:0] data_ab [ROWS:0][COLUMS:1];
logic pop_ab [ROWS:0][COLUMS:1];

genvar R;
genvar C;
int i;
int ii;

initial begin
	// I/O dispositivos 0 a 3
	for (i = 0; i < 4; i++) begin

		ii = i + 1; // Para acomodar al índice de las columnas (inicia en columna 1 = i+1 = 0+1)

		// I
		pop_ab[0][ii] = pop[i];
		data_ab[0][ii] = data_out_i_in[i];
		pndng_ab[0][ii] = pndng_i_in[i];

		// O
		popin[i] = pop_ar[0][ii];
		data_out[i] = data_ar[0][ii];
		pndng[i] = pndng_ar[0][ii];
	end

	// I/O dispositivos 4 a 7
	for (i = 4; i < 8; i++) begin

		ii = i - 3; // Para acomodar el índice de las filas (inicia en fila 1 = i-3 = 4-3)

		// I
		pop_der[ii][0] = pop[i];
		data_der[ii][0] = data_out_i_in[i];
		pndng_der[ii][0] = pndng_i_in[i];

		// O
		popin[i] = pop_iz[ii][0];
		data_out[i] = data_iz[ii][0];
		pndng[i] = pndng_iz[ii][0];
	end

	// I/O dispositivos 8 a 11
	for (i = 8; i < 12; i++) begin

		ii = i - 7; // Para acomodar el índice de las columnas (inicia en columna 1 = i-7 = 8-7)

		// I
		pop_ar[4][ii] = pop[i];
		data_ar[4][ii] = data_out_i_in[i];
		pndng_ar[4][ii] = pndng_i_in[i];

		// O
		popin[i] = pop_ab[4][ii];
		data_out[i] = data_ab[4][ii];
		pndng[i] = pndng_ab[4][ii];
	end

	// I/O dispositivos 12 a 15
	for (int i = 12; i < 16; i++) begin

		ii = i - 11; // Para acomodar el índice de las filas (inicia en fila 1 = i-11 = 12-11)

		// I
		pop_iz[ii][4] = pop[i];
		data_iz[ii][4] = data_out_i_in[i];
		pndng_iz[ii][4] = pndng_i_in[i];

		// O
		popin[i] = pop_der[ii][4];
		data_out[i] = data_der[ii][4];
		pndng[i] = pndng_der[ii][4];
	end
end

// Interconexiones de los routers
generate
	for (R = 1; R < 5; R++) begin
		for (C = 1; C < 5; C++) begin : _n_
			router # (.pckg_sz(pckg_sz), .Fif_Size(fifo_depth), .id_r(R), .id_c(C), .columns(COLUMS), .rows(ROWS)) rtr_ (
				.clk(clk),
				.rst(rst),
				
				.Data_out_i_in('{data_ab[R-1][C], data_iz[R][C], data_ar[R][C], data_der[R][C-1]}),
				.pndng_i_in('{pndng_ab[R-1][C], pndng_iz[R][C], pndng_ar[R][C], pndng_der[R][C-1]}),
				.pop('{pop_ab[R-1][C], pop_iz[R][C], pop_ar[R][C], pop_der[R][C-1]}),

				.Popin('{pop_ar[R-1][C], pop_der[R][C], pop_ab[R][C], pop_iz[R][C-1]}),
				.Data_out('{data_ar[R-1][C], data_der[R][C], data_ab[R][C], data_iz[R][C-1]}),
				.pndng('{pndng_ar[R-1][C], pndng_der[R][C], pndng_ab[R][C], pndng_iz[R][C-1]})
				);
		end
	end
endgenerate

endmodule

class checker #(parameter ROWS = 4, parameter COLUMS =4, parameter pckg_sz =40, parameter fifo_depth = 4);
	// Mailboxes
	mlbx_mntr_chckr from_mntr_mlbx[16]; 	// Monitor - Checker
	mlbx_aGENte_chckr from_sb_mlbx; 		// Scoreboard - checker
	mlbx_mntr_chckr to_sb_mlbx; 			// Checker - scoreboard

	// Transacciones
	Trans_out #(.pckg_sz(pckg_sz)) from_mntr_item; 	// Del monitor
	Trans_in #(.pckg_sz(pckg_sz)) from_sb_item;  	// Del scoreboard
	Trans_out #(.pckg_sz(pckg_sz)) to_sb_item; 		// Hacia el scoreboard

	// Interfaz virtual para conectar el emulador del mesh al driver
	virtual intfz #(.pckg_sz(pckg_sz)) vif;

	// Transacciones recibidas del scoreboard
	// Cada transacción generada por el agente se guarda en un queue según el destino de la transacción
	Trans_in sb_generadas [16][$]; 	// Se crea un queue para cada dispositivo


	Trans_out sb_rec_inc [$]; 	   	// Este queue guardará las transacciones recibidas en el monitor que no se generaron por el test

	// Instancia del emulador del mesh
	// mesh_emu #(.ROWS(ROWS), .COLUMS(COLUMS), .pckg_sz(pckg_sz), .fifo_depth(fifo_depth)) mesh(
	// 	.clk          (vif.clk),
	// 	.rst          (vif.reset),
	// 	.pndng        (vif.pndng),
	// 	.data_out     (vif.data_out),
	// 	.popin        (vif.popin),
	// 	.pop          (vif.pop),
	// 	.data_out_i_in(vif.data_out_i_in),
	// 	.pndng_i_in   (vif.pndng_i_in)
	// );

	// Direcciones de los paquetes
	bit dir={8'b00000001, 8'b00000010,8'b00000011,8'b00000100,8'b00010000,8'b00100000,8'b00110000,8'b01000000,8'b01010001,8'b01010010,8'b01010011,8'b01010100,8'b00010101,8'b00100101,8'b00110101,8'b01000101};

	function new ();

		foreach(sb_generadas[i]) begin
			this.sb_generadas[i] = {};
		end

		this.sb_rec_inc = {};
	endfunction

	task run(event fin);
		fork
			begin
				$display("[T = %g] El checker fue inicializado.", $time);
				forever begin
					from_sb_mlbx.get(from_sb_item);
					from_sb_item.print("[Checker] Transacción recibida del Scoreboard.");
					foreach(dir[i]) begin
						if (dir[i] == from_sb_item.Target) begin
							sb_generadas[i].push_front(from_sb_item);
						end
					end
				end
			end
			begin
				forever begin
					from_mntr_mlbx.get(from_mntr_item);
					from_mntr_item.print("[Checker] Transacción recibida del Monitor");
					
					// Recibo del monitor y reviso que sea consistente con el modelo del mesh
					if ((from_mntr_item.TargetO == vif.data_out[pckg_sz-9:pckg_sz-16]) & (from_mntr_item.modeO == vif.data_out[pckg_sz-17:pckg_sz-17]) & (from_mntr_item.payloadO == vif.data_out[pckg_sz-18:0])) begin
						// Busco la transacción en la lista de transacciones generadas por el aGENt
						foreach(sb_generadas[i]) begin
							if (from_mntr_item.TargetO == dir[i]) begin
								if (sb_generadas[i].size()) begin
									int j = (sb_generadas[i].size()-1);
									while (j >= 0) begin
										if ((from_mntr_item.TargetO == sb_generadas[i][j].Target) & (from_mntr_item.modeO == sb_generadas[i][j].mode) & (from_mntr_item.payloadO == sb_generadas[i][j].payload) & (from_mntr_item.tipo == sb_generadas[i][j].tipo)) begin
											to_sb_item = new;
											// Igualo el item recibido del mntr al que se va a enviar al sb para evitar modificar el item recibido
											to_sb_item = from_mntr_item;
											// Se calcula el delay de la transacción
											to_sb_item.delayO = from_mntr_item.delayO - sb_generadas[i][j].tiempo;
											// Se envía la transacción completada al sb								
											to_sb_mlbx.put(to_sb_item);
											$display("[T = %g] [Checker] Transacción correcta.",$time);
											// Saca la transacción de la lista de generadas
											sb_generadas[i].pop_back();
											j = -2;
										end else j = j-1;
									end
									if (j = -1) begin
										$display("[T = %g] [Checker] ERROR: Se recibió una transacción no generada por el test para el dispositivo %g", $time, i);
										sb_rec_inc.push_front(from_mntr_item); 
									end
								end else begin
									$display("[T = %g] [Checker] ERROR: Se recibió una transacción no generada por el test para el dispositivo %g", $time, i);
									sb_rec_inc.push_front(from_mntr_item); 
								end
							end
						end
					end else begin 
						$display("[T = %g] [Checker] ERROR: La transacción recibida no coincide con el modelo", $time);
					end
				end
			end
		join_none
		wait (fin.triggered);
		// Se verifica que todas las transacciones se hayan completado
		foreach(sb_generadas[i]) begin
			if (sb_generadas[i].size()) begin
				$display("[T = %g] [Checker] ERROR: %g transacciones no llegaron al dispositivo %g.", $time, sb_generadas[i].size(), i);
			end else begin 
				$display("[T = %g] [Checker] PASS: Todas las transacciones generadas se recibieron con éxito en el dispositivo %g", $time, i);
			end
		end
		// Se verifica si se recibieron transacciones incorrectas
		if (sb_rec_inc.size()) begin
			$display("[T = %g] [Checker] ERROR: Se recibieron %g transacciones incorrectas en el monitor.", $time, sb_rec_inc.size());
		end else begin 
			$display("[T = %g] [Checker] PASS: No se recibieron transaccione incorrectas en el monitor.", $time);
		end
	endtask : run

endclass : checker 