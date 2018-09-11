`define RISCV_FORMAL
`define RISCV_FORMAL_NRET 1
`define RISCV_FORMAL_XLEN 32
`define RISCV_FORMAL_ILEN 32
`define RISCV_FORMAL_ALIGNED_MEM
`include "rvfi_macros.vh"
`include "rvfi_channel.sv"
`include "rvfi_dmem_check.sv"

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

	(* keep *) wire [31:0] dmem_addr;
	(* keep *) reg  [31:0] dmem_data;

	rvfi_dmem_check checker_inst (
		.clock     (clk      ),
		.reset     (reset  ),
		.enable    (1'b1     ),
		.dmem_addr (dmem_addr),
		`RVFI_CONN
	);

	(* keep *) reg dmem_last_valid;
	(* keep *) wire [3:0] data_req_mask;

	assign data_req_mask = ((1 << (1 << data_req_size))-1) << data_req_addr[1:0];

	always @(posedge clk) begin
		if (reset) begin
			dmem_last_valid <= 0;
		end else begin
			if(dmem_last_valid) begin
				assume(data_rsp_data == dmem_data);
			end
			if(data_rsp_valid) begin
				dmem_last_valid <= 0;
			end
			if(data_req_valid && data_req_ready) begin
				if((data_req_addr >> 2) == (dmem_addr >> 2)) begin
					if(!data_req_wr) begin
						dmem_last_valid <= 1;
					end else begin
						if (data_req_mask[0]) dmem_data[ 7: 0] <= data_req_data[ 7: 0];
						if (data_req_mask[1]) dmem_data[15: 8] <= data_req_data[15: 8];
						if (data_req_mask[2]) dmem_data[23:16] <= data_req_data[23:16];
						if (data_req_mask[3]) dmem_data[31:24] <= data_req_data[31:24];
					end
				end
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

