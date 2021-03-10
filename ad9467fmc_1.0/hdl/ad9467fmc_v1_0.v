
`timescale 1 ns / 1 ps

module ad9467fmc_v1_0 # (
    parameter integer C_M_AXI_DATA_WIDTH = 64,
    parameter integer C_S00_AXI_DATA_WIDTH	= 32,
    parameter integer C_S00_AXI_ADDR_WIDTH	= 7
) (
    input wire adc_clk_p, 
    input wire adc_clk_n, 
    input wire adc_or_p, 
    input wire adc_or_n, 
    input wire [7:0] adc_data_p, 
    input wire [7:0] adc_data_n, 
    output wire [7:0] dbg, 
    output wire adc_clk, 

    input wire m_axis_tready,
    output wire [C_M_AXI_DATA_WIDTH-1:0] m_axis_tdata,
    output wire m_axis_tlast,
    output wire m_axis_tvalid,
    input wire m_aclk, 
    input wire m_aresetn,

    input wire iodelay_resetn,
    input wire iodelay_clk,

    input wire fifo_overflow,
    input wire fifo_underflow,

    input wire  s00_axi_aclk,
    input wire  s00_axi_aresetn,
    input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
    input wire [2 : 0] s00_axi_awprot,
    input wire  s00_axi_awvalid,
    output wire  s00_axi_awready,
    input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
    input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
    input wire  s00_axi_wvalid,
    output wire  s00_axi_wready,
    output wire [1 : 0] s00_axi_bresp,
    output wire  s00_axi_bvalid,
    input wire  s00_axi_bready,
    input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
    input wire [2 : 0] s00_axi_arprot,
    input wire  s00_axi_arvalid,
    output wire  s00_axi_arready,
    output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
    output wire [1 : 0] s00_axi_rresp,
    output wire  s00_axi_rvalid,
    input wire  s00_axi_rready
);

    wire iodelay_ready;
    wire ovr;
    wire signed [15:0] adc_data;
    wire [63:0] iodelay_data;
    wire [15:0] dds_code;
    wire [3:0] adc_gain;
    wire [3:0] ddc_gain;
    wire [3:0] mux;

    ad9467fmc_v1_0_S00_AXI # ( 
        .C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
        .C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
    ) ad9467fmc_v1_0_S00_AXI_inst (
        .iodelay_data(iodelay_data), 
        .dds_code(dds_code),
        .adc_gain(adc_gain),
        .ddc_gain(ddc_gain),
        .mux(mux), 
        .S_AXI_ACLK(s00_axi_aclk),
        .S_AXI_ARESETN(s00_axi_aresetn),
        .S_AXI_AWADDR(s00_axi_awaddr),
        .S_AXI_AWPROT(s00_axi_awprot),
        .S_AXI_AWVALID(s00_axi_awvalid),
        .S_AXI_AWREADY(s00_axi_awready),
        .S_AXI_WDATA(s00_axi_wdata),
        .S_AXI_WSTRB(s00_axi_wstrb),
        .S_AXI_WVALID(s00_axi_wvalid),
        .S_AXI_WREADY(s00_axi_wready),
        .S_AXI_BRESP(s00_axi_bresp),
        .S_AXI_BVALID(s00_axi_bvalid),
        .S_AXI_BREADY(s00_axi_bready),
        .S_AXI_ARADDR(s00_axi_araddr),
        .S_AXI_ARPROT(s00_axi_arprot),
        .S_AXI_ARVALID(s00_axi_arvalid),
        .S_AXI_ARREADY(s00_axi_arready),
        .S_AXI_RDATA(s00_axi_rdata),
        .S_AXI_RRESP(s00_axi_rresp),
        .S_AXI_RVALID(s00_axi_rvalid),
        .S_AXI_RREADY(s00_axi_rready)
    );

    ad9467_if ad9467_if0(
        .adc_clk_p(adc_clk_p),
        .adc_clk_n(adc_clk_n),
        .adc_or_p(adc_or_p),
        .adc_or_n(adc_or_n),
        .adc_data_p(adc_data_p),
        .adc_data_n(adc_data_n),

        .iodelay_reset(!iodelay_resetn),
        .iodelay_clk(iodelay_clk),
        .iodelay_data(iodelay_data), 
        .iodelay_ready(iodelay_ready),

        .clk(adc_clk), 
        .data(adc_data), 
        .ovr(ovr) 
    );

    reg [15:0] adc_shifted = 0;
    reg [15:0] adc_shifted0 = 0;
    reg [15:0] adc_shifted1 = 0;
    reg signed [7:0] adc_out = 0;
    reg signed [7:0] adc_out0 = 0;
    reg signed [8:0] adc_i0 = 0;
    reg signed [8:0] adc_q0 = 0;
    reg signed [8:0] adc_i1 = 0;
    reg signed [8:0] adc_q1 = 0;
    wire [15:0] dds_data;
    wire signed [7:0] dds_sin = dds_data[7:0];
    wire signed [7:0] dds_cos = dds_data[15:8];
    (* use_dsp = "yes" *)
    wire signed [15:0] adc_i = adc_out0 * dds_sin;
    (* use_dsp = "yes" *)
    wire signed [15:0] adc_q = adc_out0 * dds_cos;

    always @(posedge adc_clk) begin
        adc_out <= adc_data >>> adc_gain;
        adc_out0 <= adc_out;//round2zero(adc_out);
        adc_i0 <= adc_i[15:7];
        adc_q0 <= adc_q[15:7];
        adc_i1 <= adc_i0;
        adc_q1 <= adc_q0;
        adc_shifted <= {round2zero(adc_q1), round2zero(adc_i1)};
        adc_shifted0 <= adc_shifted;
        adc_shifted1 <= adc_shifted0; // TODO: remove adc_shifted1
    end

    dds_compiler_0 dds_compiler0 (
        .aclk(adc_clk),
        .s_axis_config_tvalid(1'b1),
        .s_axis_config_tdata(dds_code),
        .m_axis_data_tvalid(),
        .m_axis_data_tdata(dds_data)
    );

    reg [15:0] cic_data0 = 0;
    reg [15:0] cic_data1 = 0;
    reg cic_valid = 0;
    reg signed [15:0] cic_i0;
    reg signed [15:0] cic_q0;
    reg cic_valid0 = 0;
    reg cic_valid1 = 0;
    wire signed [15:0] cic_i;
    wire signed [15:0] cic_q;
    wire cic_tvalid;

    cic_compiler_0 cic_compiler_i (
        .aclk(adc_clk),
        .s_axis_data_tdata(adc_shifted0[7:0]),
        .s_axis_data_tvalid(1'b1),
        .s_axis_data_tready(),
        .m_axis_data_tdata(cic_i),
        .m_axis_data_tvalid(cic_tvalid)
    );
    cic_compiler_0 cic_compiler_q (
        .aclk(adc_clk),
        .s_axis_data_tdata(adc_shifted0[15:8]),
        .s_axis_data_tvalid(1'b1),
        .s_axis_data_tready(),
        .m_axis_data_tdata(cic_q),
        .m_axis_data_tvalid()
    );

    always @(posedge adc_clk) begin
        cic_valid <= cic_tvalid;
        cic_i0 <= cic_i >>> ddc_gain;
        cic_q0 <= cic_q >>> ddc_gain;
        case (mux)
            'h0: begin
                cic_data0 <= {cic_q0[7:0], cic_i0[7:0]};
                cic_valid0 <= cic_valid;
            end
            'h1: begin
                cic_data0 <= adc_data;
                cic_valid0 <= 1'b1;
            end
            'h2: begin
                cic_data0 <= adc_shifted1;
                cic_valid0 <= 1'b1;
            end
            'h3: begin
                cic_data0 <= adc_data;
                cic_valid0 <= 1'b1;
            end
            default: begin
                cic_data0 <= {round2zero(cic_q0), round2zero(cic_i0)};
                cic_valid0 <= cic_valid;
            end
        endcase
        cic_data1 <= cic_data0;
        cic_valid1 <= cic_valid0;
    end

    reg fifo_en = 0;
    reg fifo_overflow0 = 0;
    reg fifo_overflow1 = 0;
    reg fifo_underflow0 = 0;
    reg fifo_underflow1 = 0;

    always @(posedge adc_clk) begin
        if (fifo_overflow1) begin
            fifo_en <= 0;
        end else if (fifo_underflow1) begin
            fifo_en <= 1;
        end
        fifo_overflow0 <= fifo_overflow;
        fifo_overflow1 <= fifo_overflow0;
        fifo_underflow0 <= fifo_underflow;
        fifo_underflow1 <= fifo_underflow0;
    end

    reg [27:0] c = 0;
    reg done_c0 = 0;
    reg done_c1 = 0;
    wire done_c = (c == 0);

    always @(posedge adc_clk) begin
        c <= c + 1;
        if (done_c) begin
            done_c0 <= !done_c0;
        end
        done_c1 <= done_c0;
    end

    reg [2:0] index = 0;
    wire done = (index == 0);
    reg done_a = 0;
    reg done_b = 0;
    reg done_b0 = 0;
    reg done_b1 = 0;
    reg done_b2 = 0;
    reg done_b3 = 0;
    wire ce_hi = done_b1 && !done_b2;
    wire ce_lo = done_b2 && !done_b3;
    
    reg [C_M_AXI_DATA_WIDTH*2-1:0] data_full_a = 0;
    reg [C_M_AXI_DATA_WIDTH*2-1:0] data_full_b = 0;
    reg [C_M_AXI_DATA_WIDTH*2-1:0] data_full_b0 = 0;
    reg [C_M_AXI_DATA_WIDTH*2-1:0] data_full_b1 = 0;
    reg [C_M_AXI_DATA_WIDTH-1:0] stream_data_out = 0;
    reg [15:0] data[0:7];
    reg [15:0] counter = 0;
    reg m_axis_tvalid0 = 0;

    initial begin
        data[0] = 0;
        data[1] = 0;
        data[2] = 0;
        data[3] = 0;
        data[4] = 0;
        data[5] = 0;
        data[6] = 0;
        data[7] = 0;
    end
    
    always @(posedge adc_clk) begin                                            
        if(!fifo_en) begin                                        
            data[0] = 0;
            data[1] = 0;
            data[2] = 0;
            data[3] = 0;
            data[4] = 0;
            data[5] = 0;
            data[6] = 0;
            data[7] = 0;
            index <= 0;
            counter <= 0;
        end else if (cic_valid1) begin
            index <= index + 1;
            counter <= counter + 1;
            data[index] <= cic_data1;
        end
        if (done) begin
            data_full_a <= {
                data[7], data[6], data[5], data[4], 
                data[3], data[2], data[1], data[0]
            };
        end
        done_a <= ~index[2];
    end                                              
    
    always @(posedge m_aclk) begin                                            
        if(!m_aresetn) begin                                        
            data_full_b <= 0;
            data_full_b0 <= 0;
            data_full_b1 <= 0;
        end else begin
            data_full_b <= data_full_a;
            data_full_b0 <= data_full_b;
            data_full_b1 <= data_full_b0;
        end
        if(!m_aresetn) begin                                        
            stream_data_out <= 0;
        end else if (ce_hi) begin
            stream_data_out <= data_full_b1[C_M_AXI_DATA_WIDTH-1:0];
        end else if (ce_lo) begin
            stream_data_out <= data_full_b1[C_M_AXI_DATA_WIDTH*2-1:C_M_AXI_DATA_WIDTH];
        end
        done_b <= done_a;
        done_b0 <= done_b;
        done_b1 <= done_b0;
        done_b2 <= done_b1;
        done_b3 <= done_b2;
        m_axis_tvalid0 <= ce_hi | ce_lo;
    end

    assign dbg[0] = done_c1;
    assign dbg[1] = fifo_en;
    assign dbg[2] = fifo_overflow;
    assign dbg[3] = fifo_underflow;
    assign dbg[4] = iodelay_ready;
    assign dbg[7:5] = 0;
    
    assign m_axis_tdata = stream_data_out;
    assign m_axis_tlast = 0;
    assign m_axis_tvalid = m_axis_tvalid0;

    localparam integer W = 8;
    function [W-1:0] round2zero;
        input [W:0] din;
        begin
            if (din[W]) begin
                round2zero = din[W:1] + din[0];
            end
            else begin
                round2zero = din[W:1];
            end
        end
    endfunction

endmodule
