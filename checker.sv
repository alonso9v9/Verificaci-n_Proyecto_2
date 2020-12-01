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

endmodule