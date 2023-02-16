module smi_ctrl (	input               i_rst_b,
					input               i_sys_clk,        // FPGA Clock
					input 				i_fast_clk,

					input [4:0]         i_ioc,
					input [7:0]         i_data_in,
					output reg [7:0]    o_data_out,
					input               i_cs,
					input               i_fetch_cmd,
					input               i_load_cmd,
                    
                    // FIFO INTERFACE
					output              o_fifo_pull,
					input [31:0]        i_fifo_pulled_data,
					input               i_fifo_full,
					input               i_fifo_empty,

					// SMI INTERFACE
					input               i_smi_soe_se,
					input               i_smi_swe_srw,
					output reg [7:0]    o_smi_data_out,
					input [7:0]         i_smi_data_in,
					output              o_smi_read_req,
					output              o_smi_write_req,
					input               i_smi_test,
                    output              o_channel,
                    
					// Errors
					output reg          o_address_error);



    // MODULE SPECIFIC IOC LIST
    // ------------------------
    localparam
        ioc_module_version  = 5'b00000,     // read only
        ioc_fifo_status     = 5'b00001,     // read-only
        ioc_channel_select  = 5'b00010;

    // MODULE SPECIFIC PARAMS
    // ----------------------
    localparam
        module_version  = 8'b00000001;

    always @(posedge i_sys_clk or negedge i_rst_b)
    begin
        if (i_rst_b == 1'b0) begin
            o_address_error <= 1'b0;
            w_channel <= 1'b0;
        end else begin
            if (i_cs == 1'b1) begin
                //=============================================
                // READ OPERATIONS
                //=============================================
                if (i_fetch_cmd == 1'b1) begin
                    case (i_ioc)
                        //----------------------------------------------
                        ioc_module_version: o_data_out <= module_version; // Module Version

                        //----------------------------------------------
                        ioc_fifo_status: begin
                            o_data_out[0] <= i_fifo_empty;
                            o_data_out[1] <= r_channel;
                            o_data_out[7:2] <= 6'b000000;
                        end
                    endcase
                end
                //=============================================
                // WRITE OPERATIONS
                //=============================================
                else if (i_load_cmd == 1'b1) begin
                    case (i_ioc)
                        //----------------------------------------------
                        ioc_channel_select: begin
                            r_channel <= i_data_in[0];
                        end
                    endcase
                end
            end
        end
    end

    // Tell the RPI that data is pending in either of the two fifos
    assign o_smi_read_req = (!i_fifo_empty) || i_smi_test;
    reg [4:0] int_cnt;
    reg r_fifo_pull;
    reg r_fifo_pull_1;
    wire w_fifo_pull_trigger;
    reg r_channel;
    assign o_channel = r_channel;
    reg [7:0] r_smi_test_count;
    reg [31:0] r_fifo_pulled_data;

    wire soe_and_reset;
    assign soe_and_reset = i_rst_b & i_smi_soe_se;

    always @(negedge soe_and_reset)
    begin
        if (i_rst_b == 1'b0) begin
            int_cnt <= 5'd31;
            r_smi_test_count <= 8'h56;
            r_fifo_pulled_data <= 32'h00000000;
        end else begin
            // trigger the fifo pulling on the second byte
            w_fifo_pull_trigger <= (int_cnt == 5'd23) && !i_smi_test;

            if ( i_smi_test ) begin
                if (r_smi_test_count == 0) begin
                    r_smi_test_count <= 8'h56;
                end else begin
                    o_smi_data_out <= r_smi_test_count;
                    r_smi_test_count <= {((r_smi_test_count[2] ^ r_smi_test_count[3]) & 1'b1), r_smi_test_count[7:1]};
                end
            end else begin
                int_cnt <= int_cnt - 8;
                o_smi_data_out <= r_fifo_pulled_data[int_cnt:int_cnt-7];
                
                // update the internal register as soon as we reach the fourth byte
                if (int_cnt == 5'd7) begin
                    r_fifo_pulled_data <= i_fifo_pulled_data;
                end
            end

        end
    end

    always @(posedge i_sys_clk)
    begin
        if (i_rst_b == 1'b0) begin
            r_fifo_pull <= 1'b0;
            r_fifo_pull_1 <= 1'b0;
        end else begin
            r_fifo_pull <= w_fifo_pull_trigger;
            r_fifo_pull_1 <= r_fifo_pull;
        end
    end

    assign o_fifo_pull = !r_fifo_pull_1 && r_fifo_pull && !i_fifo_empty;

endmodule // smi_ctrl