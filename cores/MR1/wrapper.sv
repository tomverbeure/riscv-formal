module rvfi_wrapper (
	input         clock,
	input         reset,
	`RVFI_OUTPUTS
);
	(* keep *) wire trap;


`ifdef DUMMY
	(* keep *) wire        iBus_cmd_valid;
	(* keep *) wire [31:0] iBus_cmd_payload_pc;
	(* keep *) `rvformal_rand_reg iBus_cmd_ready;
	(* keep *) `rvformal_rand_reg iBus_rsp_ready;
	(* keep *) `rvformal_rand_reg [31:0] iBus_rsp_inst;


	(* keep *) wire  dBus_cmd_valid;
	(* keep *) wire  dBus_cmd_payload_wr;
	(* keep *) wire [31:0] dBus_cmd_payload_address;
	(* keep *) wire [31:0] dBus_cmd_payload_data;
	(* keep *) wire [1:0] dBus_cmd_payload_size;
	(* keep *) `rvformal_rand_reg dBus_cmd_ready;
	(* keep *) `rvformal_rand_reg    dBus_rsp_ready;
	(* keep *) `rvformal_rand_reg   [31:0] dBus_rsp_data;
`endif

    (* keep *) wire instr_req_valid;
    (* keep *) wire instr_req_ready;
    (* keep *) wire [31:0] instr_req_addr;
    (* keep *) wire instr_rsp_valid;
    (* keep *) wire [31:0]  instr_rsp_data;

    (* keep *) wire data_req_valid;
    (* keep *) wire data_req_ready;
    (* keep *) wire [1:0] data_req_wr;
    (* keep *) wire [31:0] data_req_addr;
    (* keep *) wire [1:0] data_req_size;
    (* keep *) wire [31:0] data_req_data;

    (* keep *) wire data_rsp_valid;
    (* keep *) wire [31:0]  data_rsp_data;


	MR1 uut (
		.clk      (clock    ),
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

    integer instr_in_flight = 0;
    always @(posedge clock) begin
        if (reset) begin
            instr_in_flight <= 0;
        end
        else begin
            instr_in_flight <= instr_in_flight + (inst_req_valid && instr_req_ready) - instr_rsp_valid;
        end
    end

    rand reg instr_req_ready_rand;
    assign instr_req_ready = instr_req_ready_rand && instr_req_valid;

    rand reg instr_rsp_valid_rand;
    assign instr_rsp_valid = instr_rsp_valid_rand && instr_in_flight > 0;


    integer data_in_flight = 0;
    always @(posedge clock) begin
        if (reset) begin
            data_in_flight <= 0;
        end
        else begin
            data_in_flight <= data_in_flight + (!data_req_wr ? (inst_req_valid && data_req_ready) - data_rsp_valid : 0);
        end
    end

    rand reg data_req_ready_rand;
    assign data_req_ready = data_req_ready_rand && data_req_valid;

    rand reg data_rsp_valid_rand;
    assign data_rsp_valid = data_rsp_valid_rand && data_in_flight > 0;


`ifdef VEXRISCV_FAIRNESS
	(* keep *) reg [2:0] iBusCmdPendingCycles = 0;
	(* keep *) reg [2:0] iBusRspPendingCycles = 0;
	(* keep *) reg       iBusRspPendingValid = 0;
	(* keep *) reg [2:0] dBusCmdPendingCycles = 0;
	(* keep *) reg [2:0] dBusRspPendingCycles = 0;
	(* keep *) reg       dBusRspPendingValid = 0;
	always @(posedge clock) begin
		if(iBus_cmd_valid && !iBus_cmd_ready) begin
			iBusCmdPendingCycles <= iBusCmdPendingCycles + 1;
		end else begin
			iBusCmdPendingCycles <= 0;
		end

		if(iBusRspPendingValid <= 1) begin
			iBusRspPendingCycles <= iBusRspPendingCycles + 1;
		end
		if(iBus_rsp_ready) begin
			iBusRspPendingValid <= 0;
			iBusRspPendingCycles <= 0;
		end
		if(iBus_cmd_valid && iBus_cmd_ready && !iBus_cmd_payload_wr) begin
			iBusRspPendingValid <= 1;
		end

		if(dBus_cmd_valid && !dBus_cmd_ready) begin
			dBusCmdPendingCycles <= dBusCmdPendingCycles + 1;
		end else begin
			dBusCmdPendingCycles <= 0;
		end

		if(dBusRspPendingValid <= 1) begin
			dBusRspPendingCycles <= dBusRspPendingCycles + 1;
		end
		if(dBus_rsp_ready) begin
			dBusRspPendingValid <= 0;
			dBusRspPendingCycles <= 0;
		end
		if(dBus_cmd_valid && dBus_cmd_ready && !dBus_cmd_payload_wr) begin
			dBusRspPendingValid <= 1;
		end
		restrict(~rvfi_trap && dBusCmdPendingCycles < 4 && dBusRspPendingCycles < 4 && iBusCmdPendingCycles < 4 && iBusRspPendingCycles < 4);
	end
`endif

endmodule

