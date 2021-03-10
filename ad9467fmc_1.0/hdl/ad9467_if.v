
module ad9467_if(
    input wire adc_clk_p,
    input wire adc_clk_n,
    input wire adc_or_p,
    input wire adc_or_n,
    input wire [7:0] adc_data_p,
    input wire [7:0] adc_data_n, 
    
    input wire iodelay_reset,
    input wire iodelay_clk,
    input wire [63:0] iodelay_data,
    output wire iodelay_ready,

    output wire clk, 
    output reg [15:0] data = 0, 
    output reg ovr = 0
);
    
    localparam DIFF_TERM = "TRUE";
    localparam LOW_POWER = "FALSE";         // Low power="TRUE", Highest performance="FALSE" 
    localparam IOSTANDARD = "DEFAULT";
    localparam DDR_CLK_EDGE = "SAME_EDGE_PIPELINED";  // "OPPOSITE_EDGE", "SAME_EDGE" or "SAME_EDGE_PIPELINED" 
    localparam IF_DELAY_GROUP = "if_delay_group";

    wire adc_or;
    wire [7:0] adc_data;
    wire [7:0] adc_data_delayed;
    wire [7:0] adc_data_pos;
    wire [7:0] adc_data_neg;
    wire [7:0] iodelay_load = {
        iodelay_data[63], iodelay_data[55], iodelay_data[47], iodelay_data[39], 
        iodelay_data[31], iodelay_data[23], iodelay_data[15], iodelay_data[7]
    };
    wire [4:0] iodelay_values[0:7];
    assign iodelay_values[0] = iodelay_data[4:0];
    assign iodelay_values[1] = iodelay_data[12:8];
    assign iodelay_values[2] = iodelay_data[20:16];
    assign iodelay_values[3] = iodelay_data[28:24];
    assign iodelay_values[4] = iodelay_data[36:32];
    assign iodelay_values[5] = iodelay_data[44:40];
    assign iodelay_values[6] = iodelay_data[52:48];
    assign iodelay_values[7] = iodelay_data[60:56];

    reg adc_ovr = 0;
    reg adc_ovr0 = 0;
    reg [7:0] adc_data_pos0 = 0;
    reg [7:0] adc_data_neg0 = 0;
    reg [7:0] adc_data_neg1 = 0;

    wire adc_clk;
    IBUFDS #(
        .DIFF_TERM(DIFF_TERM),
        .IBUF_LOW_PWR(LOW_POWER), 
        .IOSTANDARD(IOSTANDARD)
    ) IBUFDS_clk (
        .O(adc_clk),
        .I(adc_clk_p),
        .IB(adc_clk_n)
    );
   
    BUFG BUFG_clk (
        .O(clk),
        .I(adc_clk) 
    );

    IBUFDS #(
        .DIFF_TERM(DIFF_TERM),
        .IBUF_LOW_PWR(LOW_POWER),
        .IOSTANDARD(IOSTANDARD)
    ) IBUFDS_or (
        .O(adc_or),
        .I(adc_or_p),
        .IB(adc_or_n)
    );

    IBUFDS #(
        .DIFF_TERM(DIFF_TERM),
        .IBUF_LOW_PWR(LOW_POWER),
        .IOSTANDARD(IOSTANDARD)
    ) IBUFDS_data [7:0] (
        .O(adc_data),
        .I(adc_data_p),
        .IB(adc_data_n)
    );

    IDDR #(
        .DDR_CLK_EDGE(DDR_CLK_EDGE), // "OPPOSITE_EDGE", "SAME_EDGE" or "SAME_EDGE_PIPELINED" 
        .INIT_Q1(1'b0),
        .INIT_Q2(1'b0),
        .SRTYPE("SYNC")
    ) IDDR_data [7:0] (
        .Q1(adc_data_pos),
        .Q2(adc_data_neg),
        .C(clk),
        .CE(1'b1),
        .D(adc_data_delayed),
        .R(1'b0),
        .S(1'b0)
    );
    
    (* IODELAY_GROUP = IF_DELAY_GROUP *)
    IDELAYCTRL IDELAYCTRL0 (
        .RDY(iodelay_ready),    // 1-bit output: Ready output
        .REFCLK(iodelay_clk),   // 1-bit input: Reference clock input
        .RST(iodelay_reset)     // 1-bit input: Active high reset input
    );

    genvar i;
    generate
    for (i = 0; i < 8; i = i + 1) begin
        (* IODELAY_GROUP = IF_DELAY_GROUP *)
        IDELAYE2 #(
            .CINVCTRL_SEL("FALSE"),          // Enable dynamic clock inversion (FALSE, TRUE)
            .DELAY_SRC("IDATAIN"),           // Delay input (IDATAIN, DATAIN)
            .HIGH_PERFORMANCE_MODE("FALSE"), // Reduced jitter ("TRUE"), Reduced power ("FALSE")
            .IDELAY_TYPE("VAR_LOAD"),        // FIXED, VARIABLE, VAR_LOAD, VAR_LOAD_PIPE
            .IDELAY_VALUE(26),               // Input delay tap setting (0-31)
            .PIPE_SEL("FALSE"),              // Select pipelined mode, FALSE, TRUE
            .REFCLK_FREQUENCY(200.0),        // IDELAYCTRL clock input frequency in MHz (190.0-210.0, 290.0-310.0).
            .SIGNAL_PATTERN("DATA")          // DATA, CLOCK input signal
        )
        IDELAYE2_data (
            .CNTVALUEOUT(),
            .DATAOUT(adc_data_delayed[i]),
            .C(iodelay_clk),
            .CE(1'b0),
            .CINVCTRL(1'b0),
            .CNTVALUEIN(iodelay_values[i]),
            .DATAIN(1'b0),
            .IDATAIN(adc_data[i]),
            .INC(1'b0),
            .LD(iodelay_load[i]),
            .LDPIPEEN(1'b0),
            .REGRST(1'b0)
        );
    end
    endgenerate

    always @(posedge clk) begin
        adc_ovr <= adc_or;
        adc_ovr0 <= adc_ovr;
        ovr <= adc_ovr0;

        adc_data_pos0 <= adc_data_pos;
        adc_data_neg0 <= adc_data_neg;
        adc_data_neg1 <= adc_data_neg0;
        data <= {
            adc_data_neg1[7], adc_data_pos0[7], 
            adc_data_neg1[6], adc_data_pos0[6], 
            adc_data_neg1[5], adc_data_pos0[5], 
            adc_data_neg1[4], adc_data_pos0[4], 
            adc_data_neg1[3], adc_data_pos0[3], 
            adc_data_neg1[2], adc_data_pos0[2], 
            adc_data_neg1[1], adc_data_pos0[1], 
            adc_data_neg1[0], adc_data_pos0[0]
        };
    end

endmodule