module testbench (
	input clk,

	input         instr_valid,
    input  [31:0] instr

);
	reg reset = 1;

	always @(posedge clk)
		reset <= 0;

	`RVFI_WIRES

	MR1 uut (
		.clk            (clk           ),
		.reset          (reset         ),

		.instr_valid    (instr_valid   ),
		.instr          (instr         ),

		`RVFI_CONN
	);

	integer count_dmemrd = 0;
	integer count_dmemwr = 0;
	integer count_longinsn = 0;
	integer count_comprinsn = 0;

	always @(posedge clk) begin
		if (reset  && rvfi_valid) begin
			if (rvfi_mem_rmask)
				count_dmemrd <= count_dmemrd + 1;
			if (rvfi_mem_wmask)
				count_dmemwr <= count_dmemwr + 1;
			if (rvfi_insn[1:0] == 3)
				count_longinsn <= count_longinsn + 1;
			if (rvfi_insn[1:0] != 3)
				count_comprinsn <= count_comprinsn + 1;
		end
	end

	cover property (count_dmemrd);
	cover property (count_dmemwr);
	cover property (count_longinsn);
	cover property (count_comprinsn);

	cover property (count_dmemrd >= 1 && count_dmemwr >= 1 && count_longinsn >= 1 && count_comprinsn >= 1);
	cover property (count_dmemrd >= 2 && count_dmemwr >= 2 && count_longinsn >= 2 && count_comprinsn >= 2);
	cover property (count_dmemrd >= 3 && count_dmemwr >= 2 && count_longinsn >= 2 && count_comprinsn >= 2);
	cover property (count_dmemrd >= 2 && count_dmemwr >= 3 && count_longinsn >= 2 && count_comprinsn >= 2);
	cover property (count_dmemrd >= 2 && count_dmemwr >= 2 && count_longinsn >= 3 && count_comprinsn >= 2);
	cover property (count_dmemrd >= 2 && count_dmemwr >= 2 && count_longinsn >= 2 && count_comprinsn >= 3);
endmodule
