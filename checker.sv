
// Interfaz del bus
module  bus_if_emu #(parameter pckg_sz = 40, parameter Fif_Size=10, bit id = 0, parameter id_r =0, parameter id_c = 0, parameter columns=4, parameter rows=4) (
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
module arbiter #(parameter pckg_sz = 40, parameter Fif_Size=10, bit id = 0, parameter id_r =0, parameter id_c = 0, parameter columns=4, parameter rows=4) (
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
		if (Cnt_en) cont++;
		if (cont == 4) cont = 0;

	end
endmodule

// Definición del router individual
module router #()(
	input clk,    // Clock
	input rst,  // Asynchronous reset active high
);

endmodule