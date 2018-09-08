module testbench (
	input clk,

	output         instr_req_valid,
	input          instr_req_ready,
	output [31:0]  instr_req_addr,

    input          instr_rsp_valid,
    input  [31:0]  instr_rsp_data,

	output         data_req_valid,
	input          data_req_ready,
	output         data_req_wr,
	output [1:0]   data_req_size,
	output [31:0]  data_req_data,
	output [31:0]  data_req_addr,

    input          data_rsp_valid,
    input  [31:0]  data_rsp_data

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

		.data_req_valid     (data_req_valid   ),
		.data_req_ready     (data_req_ready   ),
		.data_req_wr        (data_req_wr      ),
		.data_req_addr      (data_req_addr    ),
		.data_req_addr      (data_req_addr    ),
		.data_req_size      (data_req_size    ),
		.data_req_data      (data_req_data    ),

		.data_rsp_valid     (data_rsp_valid   ),
		.data_rsp_data      (data_rsp_data    ),

		`RVFI_CONN
	);

    integer count_cycles = 0;
	integer count_dmemrd = 0;
	integer count_dmemwr = 0;
	integer count_longinsn = 0;
	integer count_comprinsn = 0;

	always @(posedge clk) begin
		if (!reset && rvfi_valid) begin
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
    integer count_instr_rsps = 0;
    always @(posedge clk) begin
        if (!reset) begin
            if (instr_req_valid && instr_req_ready) begin
                count_instr_reqs <= count_instr_reqs + 1;
            end
        end
    end

    cover property (count_longinsn == 4 ||  count_cycles == 20);

    assume property(count_instr_reqs != 1 || instr_rsp_data == 32'b0000000_00000_00000_010_00001_0000011);  // LW
    assume property(count_instr_reqs != 2 || instr_rsp_data == 32'b0000000_00001_00001_000_00001_0110011);  // ADD
    assume property(count_instr_reqs != 3 || instr_rsp_data == 32'b0000000_00001_00001_000_00001_0110011);  // ADD
    assume property(count_instr_reqs != 4 || instr_rsp_data == 32'b0000000_00001_00001_000_00001_0110011);  // ADD
    assume property(count_instr_reqs != 5 || instr_rsp_data == 32'b0000000_00001_00001_000_00001_0110011);  // ADD

    assume property(data_rsp_data == 1);

    assume property(instr_req_ready);
    assume property(instr_rsp_valid);

endmodule
