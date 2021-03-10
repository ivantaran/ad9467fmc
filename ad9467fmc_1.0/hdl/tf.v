`timescale 1ns / 1ps


module tf;
    reg m_aclk = 0;
    reg adc_clk_p = 1;
    reg adc_clk_n = 0;
    reg overflow = 1;
    reg underflow = 0;
    reg test = 0;

    always @(*) begin
        #5 m_aclk <= !m_aclk;
    end
    always @(*) begin
        #2;
        adc_clk_p <= !adc_clk_p;
        adc_clk_n <= !adc_clk_n;
    end

    initial begin
        #10;
        overflow <= 0;
        #10;
        underflow <= 1;
        #10;
        underflow <= 0;
    end

    always @(posedge adc_clk_p) begin
        test <= m_aclk;
    end

    ad9467fmc_v1_0 ad9467fmc(
        .adc_clk_p(adc_clk_p), 
        .adc_clk_n(adc_clk_n), 
        .adc_or_p(), 
        .adc_or_n(), 
        .adc_data_p(), 
        .adc_data_n(), 
        .dbg(), 
        .resetn(1'b1),
        .m_axis_tready(),
        .m_axis_tdata(),
        .m_axis_tlast(),
        .m_axis_tvalid(),
        .m_aclk(m_aclk), 
        .m_aresetn(1'b1),
        .fifo_overflow(overflow),
        .fifo_underflow(underflow), 
        // .s00_axi_aclk(),
        // .s00_axi_aresetn(),
        // .s00_axi_awaddr(),
        // .s00_axi_awprot(),
        // .s00_axi_awvalid(),
        // .s00_axi_awready(),
        // .s00_axi_wdata(),
        // .s00_axi_wstrb(),
        // .s00_axi_wvalid(),
        // .s00_axi_wready(),
        // .s00_axi_bresp(),
        // .s00_axi_bvalid(),
        // .s00_axi_bready(),
        // .s00_axi_araddr(),
        // .s00_axi_arprot(),
        // .s00_axi_arvalid(),
        // .s00_axi_arready(),
        // .s00_axi_rdata(),
        // .s00_axi_rresp(),
        // .s00_axi_rvalid(),
        .s00_axi_rready()
    );

endmodule
