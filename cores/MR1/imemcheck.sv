`define RISCV_FORMAL
`define RISCV_FORMAL_NRET 1
`define RISCV_FORMAL_XLEN 32
`define RISCV_FORMAL_ILEN 32
`include "rvfi_macros.vh"
`include "rvfi_channel.sv"
`include "rvfi_imem_check.sv"

module testbench (
	input clk
);
	reg reset = 1;

	always @(posedge clk)
		reset <= 0;

	(* keep *) wire trap;

    (* keep *) wire                         instr_req_valid;
    (* keep *) `rvformal_rand_reg           instr_req_ready;
    (* keep *) wire [31:0]                  instr_req_addr;
    (* keep *) `rvformal_rand_reg           instr_rsp_valid;
    (* keep *) `rvformal_rand_reg [31:0]    instr_rsp_data;

    (* keep *) wire                         data_req_valid;
    (* keep *) `rvformal_rand_reg           data_req_ready;
    (* keep *) wire                         data_req_wr;
    (* keep *) wire [31:0]                  data_req_addr;
    (* keep *) wire [1:0]                   data_req_size;
    (* keep *) wire [31:0]                  data_req_data;

    (* keep *) `rvformal_rand_reg           data_rsp_valid;
    (* keep *) `rvformal_rand_reg [31:0]    data_rsp_data;

	`RVFI_WIRES

	(* keep *) wire [31:0] imem_addr;
	(* keep *) wire [15:0] imem_data;

	rvfi_imem_check checker_inst (
		.clock     (clk      ),
		.reset     (reset  ),
		.enable    (1'b1     ),
		.imem_addr (imem_addr),
		.imem_data (imem_data),
		`RVFI_CONN
	);

	(* keep *) wire         imem_last_valid;
	(* keep *) wire [31:0]  imem_last_addr;

	always @(posedge clk) begin
		if (reset) begin
			imem_last_valid <= 0;
		end else begin
			if(imem_last_valid) begin
				if (imem_last_addr == imem_addr)
					assume(instr_rsp_data[15:0] == imem_data);
				if (imem_last_addr+2 == imem_addr)
					assume(instr_rsp_data[31:16] == imem_data);
			end
			if(instr_rsp_valid) begin
				imem_last_valid <= 0;
			end
			if(instr_req_valid && instr_req_ready) begin
				imem_last_valid <= 1;
				imem_last_addr <= instr_req_addr;
			end
		end
	end

	MR1 uut (
		.clk      (clk    ),
		.reset    (reset   ),

        .instr_req_valid(instr_req_valid),
        .instr_req_ready(instr_req_ready),
        .instr_req_addr(instr_req_addr),

        .instr_rsp_valid(instr_rsp_valid),
        .instr_rsp_data(instr_rsp_data),

        .data_req_valid(data_req_valid),
        .data_req_ready(data_req_ready),
        .data_req_wr(data_req_wr),
        .data_req_addr(data_req_addr),
        .data_req_size(data_req_size),
        .data_req_data(data_req_data),

        .data_rsp_valid(data_rsp_valid),
        .data_rsp_data(data_rsp_data),

		`RVFI_CONN
	);

endmodule

