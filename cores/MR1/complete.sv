module testbench (
	input clk,

	output         instr_req_valid,
	input          instr_req_ready,
	output [31:0]  instr_req_addr,
    input          instr_rsp_valid,
    input  [31:0]  instr_rsp_data

);
	reg reset  = 1;

	always @(posedge clk)
		reset  <= 0;

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


	(* keep *) wire                                spec_valid;
	(* keep *) wire                                spec_trap;
	(* keep *) wire [                       4 : 0] spec_rs1_addr;
	(* keep *) wire [                       4 : 0] spec_rs2_addr;
	(* keep *) wire [                       4 : 0] spec_rd_addr;
	(* keep *) wire [`RISCV_FORMAL_XLEN   - 1 : 0] spec_rd_wdata;
	(* keep *) wire [`RISCV_FORMAL_XLEN   - 1 : 0] spec_pc_wdata;
	(* keep *) wire [`RISCV_FORMAL_XLEN   - 1 : 0] spec_mem_addr;
	(* keep *) wire [`RISCV_FORMAL_XLEN/8 - 1 : 0] spec_mem_rmask;
	(* keep *) wire [`RISCV_FORMAL_XLEN/8 - 1 : 0] spec_mem_wmask;
	(* keep *) wire [`RISCV_FORMAL_XLEN   - 1 : 0] spec_mem_wdata;

	rvfi_isa_rv32im isa_spec (
		.rvfi_valid    (rvfi_valid    ),
		.rvfi_insn     (rvfi_insn     ),
		.rvfi_pc_rdata (rvfi_pc_rdata ),
		.rvfi_rs1_rdata(rvfi_rs1_rdata),
		.rvfi_rs2_rdata(rvfi_rs2_rdata),
		.rvfi_mem_rdata(rvfi_mem_rdata),

		.spec_valid    (spec_valid    ),
		.spec_trap     (spec_trap     ),
		.spec_rs1_addr (spec_rs1_addr ),
		.spec_rs2_addr (spec_rs2_addr ),
		.spec_rd_addr  (spec_rd_addr  ),
		.spec_rd_wdata (spec_rd_wdata ),
		.spec_pc_wdata (spec_pc_wdata ),
		.spec_mem_addr (spec_mem_addr ),
		.spec_mem_rmask(spec_mem_rmask),
		.spec_mem_wmask(spec_mem_wmask),
		.spec_mem_wdata(spec_mem_wdata)
	);

	always @* begin
		if (!reset && rvfi_valid && !rvfi_trap) begin
			if (rvfi_insn[6:0] != 7'b1110011)
				assert(spec_valid && !spec_trap);
		end
	end
endmodule
