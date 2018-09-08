module rvfi_wrapper (
	input         clock,
	input         reset,
	`RVFI_OUTPUTS
);
	(* keep *) wire trap;

    (* keep *) wire instr_req_valid;
    (* keep *) wire instr_req_ready;
    (* keep *) wire [31:0] instr_req_addr;
    (* keep *) wire instr_rsp_valid;
    (* keep *) `rvformal_rand_reg [31:0]  instr_rsp_data;

    (* keep *) wire data_req_valid;
    (* keep *) `rvformal_rand_reg data_req_ready;
    (* keep *) wire data_req_wr;
    (* keep *) wire [31:0] data_req_addr;
    (* keep *) wire [1:0] data_req_size;
    (* keep *) wire [31:0] data_req_data;

    (* keep *) `rvformal_rand_reg data_rsp_valid;
    (* keep *) `rvformal_rand_reg [31:0]  data_rsp_data;


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
            instr_in_flight <= instr_in_flight + (instr_req_valid && instr_req_ready) - instr_rsp_valid;
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
            data_in_flight <= data_in_flight + (!data_req_wr ? (instr_req_valid && data_req_ready) - data_rsp_valid : 0);
        end
    end

`ifdef VEXRISCV_FAIRNESS
	(* keep *) reg [2:0] instr_req_pending_cycles = 0;
	(* keep *) reg [2:0] instr_rsp_pending_cycles = 0;
	(* keep *) reg       instr_rsp_pending_valid = 0;
	(* keep *) reg [2:0] data_req_pending_cycles = 0;
	(* keep *) reg [2:0] data_rsp_pending_cycles = 0;
	(* keep *) reg       data_rsp_pending_valid = 0;
	always @(posedge clock) begin
		if(instr_req_valid && !instr_req_ready) begin
			instr_req_pending_cycles <= instr_req_pending_cycles + 1;
		end else begin
			instr_req_pending_cycles <= 0;
		end

		if(instr_rsp_pending_valid <= 1) begin
			instr_rsp_pending_cycles <= instr_rsp_pending_cycles + 1;
		end
		if(instr_rsp_valid) begin
			instr_rsp_pending_valid <= 0;
			instr_rsp_pending_cycles <= 0;
		end
		if(instr_req_valid && instr_req_ready) begin
			instr_rsp_pending_valid <= 1;
		end

		if(data_req_valid && !data_req_ready) begin
			data_req_pending_cycles <= data_req_pending_cycles + 1;
		end else begin
			data_req_pending_cycles <= 0;
		end

		if(data_rsp_pending_valid <= 1) begin
			data_rsp_pending_cycles <= data_rsp_pending_cycles + 1;
		end
		if(data_rsp_valid) begin
			data_rsp_pending_valid <= 0;
			data_rsp_pending_cycles <= 0;
		end
		if(data_req_valid && data_req_ready && !data_req_wr) begin
			data_rsp_pending_valid <= 1;
		end
		restrict(~rvfi_trap && data_req_pending_cycles < 4 && data_rsp_pending_cycles < 4 && instr_req_pending_cycles < 4 && instr_rsp_pending_cycles < 4);
	end
`endif

endmodule

