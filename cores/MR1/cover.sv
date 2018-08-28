module testbench (
	input clk,

	output         instr_req_valid,
	input          instr_req_ready,
	output [31:0]  instr_req_addr,
    input          instr_rsp_valid,
    input  [31:0]  instr_rsp_data

);
	reg reset = 1;

	always @(posedge clk)
		reset <= 0;

	`RVFI_WIRES

	MR1 uut (
		.clk            (clk           ),
		.reset          (reset         ),

		.instr_req_valid    (instr_req_valid   ),
		.instr_req_ready    (instr_req_ready   ),
		.instr_req_addr     (instr_req_addr    ),

		.instr_rsp_valid    (instr_rsp_valid   ),
		.instr_rsp_data     (instr_rsp_data    ),

		`RVFI_CONN
	);

    integer count_cycles = 0;
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

        count_cycles <= count_cycles + 1;
	end

    integer count_instr_reqs = 0;
    always @(posedge clk) begin
        if (!reset) begin
            if (instr_req_valid && instr_req_ready) begin
                count_instr_reqs <= count_instr_reqs + 1;
            end
        end
    end

    cover property (count_instr_reqs == 1 || count_cycles == 20);
    cover property (count_instr_reqs == 5 || count_cycles == 20);

//    assume property(instr_rsp_data == 32'b0000000_00010_00001_000_00011_0110011);  // ADD
//    assume property(instr_rsp_data == 32'b0000000_00000_00000_000_01000_1100011);  // BEQ
    assume property(instr_rsp_data == 32'b0000000_00000_00000_010_01000_0000011);  // LW
//    assume property((instr_rsp_data == 32'b0000000_00000_00000_000_01000_1100011) || (instr_rsp_data == 32'b0000000_00010_00001_000_00011_0110011));
    assume property(instr_req_ready);
    assume property(instr_rsp_valid);

`ifdef BLAH
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
`endif

endmodule
