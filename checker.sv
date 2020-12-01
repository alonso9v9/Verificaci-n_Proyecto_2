
// Interfaz del bus
// Broadcast ??????????????????????????????????????????
// ????????????????????????????????????????????????????
// ????????????????????????????????????????????????????
module  bus_if_emu #(parameter pckg_sz = 40, parameter Fif_Size=10, parameter [7:0] id = 0, parameter id_r =0, parameter id_c = 0, parameter columns=4, parameter rows=4) (
	input clk,    // Clock
	input rst,  // Asynchronous reset active high
	
	input [pckg_sz-1:0] Data_out_i_in, 
	input pndng_i_in, 
	input pop,
	output Popin,
	output [pckg_sz-1:0] Data_out,
	output pndng,

	output [pckg_sz-1:0] Data_out_i, 
	output pndng_i, 
	input pop_i,
	input [1:0] Trn,
	input [pckg_sz-1:0] Data_in_i,
	input push_i
);

	bit Fifo_out[$:Fif_Size-1];

	// DECO (por ahora usa el mismo código del DUT)
	s_routing_table #(.id_r(id_r), .id_c(id_c), .pckg_sz(pckg_sz), .columns(columns), .rows(rows)) deco (Data_out_i_in, Data_out_i);

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
			if (size(Fifo_out)) begin
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
	input Data_out_i [4],

	output [1:0] Trn,
	output push_i,
	output pop_i,
	output [pckg_sz-1:0] Data_in_i

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
	output pndng [4],
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
module mesh_emu #(parameter ROWS = 4, parameter COLUMS =4, parameter pckg_sz =40, parameter fifo_depth = 4, parameter bdcst= {8{1'b1}})(
	input clk,    // Clock
	input rst,  // Asynchronous reset active high
	output logic pndng[ROWS*2+COLUMS*2],
  	output [pckg_sz-1:0] data_out[ROWS*2+COLUMS*2],
  	output logic popin[ROWS*2+COLUMS*2],
  	input pop[ROWS*2+COLUMS*2],
  	input [pckg_sz-1:0]data_out_i_in[ROWS*2+COLUMS*2],
  	input pndng_i_in[ROWS*2+COLUMS*2],
);

//// Conexiones entre routers

/// Conexiones horizontales
// Datos hacia la derecha
wire pndng_der [ROWS][COLUMS-1];
wire [pckg_sz-1:0] data_der [ROWS][COLUMS-1];
wire popin_der [ROWS][COLUMS-1];
// Datos hacia la izquierda
wire pndng_iz [ROWS][COLUMS-1];
wire [pckg_sz-1:0] data_iz [ROWS][COLUMS-1];
wire pop_iz [ROWS][COLUMS-1];

/// Conexiones verticales
// Datos hacia arriba
wire pndng_ar [ROWS][COLUMS-1];
wire [pckg_sz-1:0] data_ar [ROWS][COLUMS-1];
wire popin_ar [ROWS][COLUMS-1];
// Datos hacia la izquierda
wire pndng_ab [ROWS][COLUMS-1];
wire [pckg_sz-1:0] data_ab [ROWS][COLUMS-1];
wire pop_ab [ROWS][COLUMS-1];

genvar i;
generate
	// Routers
endgenerate

endmodule