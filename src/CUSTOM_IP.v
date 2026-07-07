module CUSTOM_IP(
	input	wire			CLK,
	input 	wire			RSTN,
	input	wire	[31:0]	IPIN,
	input	wire	[31:0]	CON,	
	output	wire	[31:0]	IPOUT
);


wire        start      = CON[15];
reg         start_d;
reg [31:0]  ipin_d;
wire        ipin_change = (IPIN != ipin_d);

reg         busy;
wire        start_pulse = (start & ~start_d) | (start & ipin_change & ~busy);

reg  [2:0]  rd_cnt;
reg         read_done;
reg read_done_q;
wire read_pulse = read_done & ~read_done_q;


// Hardcoded H values
wire signed [15:0] h11_re = 16'h170A; wire signed [15:0] h11_im = 16'h0385;
wire signed [15:0] h12_re = 16'hF5C3; wire signed [15:0] h12_im = 16'h0CCD;
wire signed [15:0] h21_re = 16'h04CD; wire signed [15:0] h21_im = 16'hF000;
wire signed [15:0] h22_re = 16'h1C29; wire signed [15:0] h22_im = 16'h023D;

// Pre-calculated G values (G = H^H * H)
localparam signed [47:0] G11_CONST    = 48'sd53885862;
localparam signed [47:0] G22_CONST    = 48'sd69906380;
localparam signed [47:0] G21_RE_CONST = -48'sd5993228;
localparam signed [47:0] G21_IM_CONST = -48'sd51921548;

reg signed [15:0] y1_re,  y1_im;
reg signed [15:0] y2_re,  y2_im;

// noise: unsigned Q1.9 (10bit)
reg [9:0] noise_q19;

// 최종 출력값: Q2.13 → 16bit signed
reg signed [15:0] x1_re,  x1_im;
reg signed [15:0] x2_re,  x2_im;

reg [31:0] ipout_reg;
reg        calc_done_reg;

always @(posedge CLK or negedge RSTN) begin
    if (!RSTN) begin
        start_d   <= 1'b0;
        ipin_d    <= 32'd0;
        busy      <= 1'b0;
        rd_cnt    <= 3'd0;
        read_done <= 1'b0;
        read_done_q <= 1'b0;

        y1_re  <= 0; y1_im  <= 0;
        y2_re  <= 0; y2_im  <= 0;
        noise_q19 <= 10'd0;
    end

    else begin
            start_d <= start;
            ipin_d  <= IPIN;
            read_done_q <= read_done;

            if (start_pulse) begin
                busy      <= 1'b1;
                read_done <= 1'b0;
                noise_q19 <= CON[9:0]; 

                y1_re <= IPIN[15:0]; 
                rd_cnt <= 3'd1;
            end

            if (busy) begin
                rd_cnt <= rd_cnt + 3'd1;
                case (rd_cnt)
                    3'd0: y1_re <= IPIN[15:0]; 
                    3'd1: y1_im <= IPIN[15:0]; 
                    3'd2: y2_re <= IPIN[15:0];
                    3'd3: y2_im <= IPIN[15:0];
                    3'd4: begin  
                        busy      <= 1'b0;
                        read_done <= 1'b1; 
                        rd_cnt    <= 3'd0;
                    end
                    default: rd_cnt <= 3'd0;
                endcase
            end
            else begin read_done <= 1'b0; end
        end
    end
// Q2.13 입력 → 내부 Q4.26 / Q2.16 → 출력 Q2.13
//--------------------------------------------

// G, b, A, d, u: 48bit signed ≈ Q4.26로 사용
reg signed [47:0] b1_re, b1_im;
reg signed [47:0] b2_re, b2_im;

reg signed [47:0] A11_re;
// reg signed [47:0] A12_re, A12_im;
reg signed [47:0] A21_re, A21_im;
reg signed [47:0] A22_re;

// Q4.28 -> Q2.16 (frac 28 -> 16, 12비트 줄이기)
reg signed [31:0] d11_inv_q216;
reg signed [31:0] d22_inv_q216;

// l21, v: Q2.16 개념의 32bit signed
reg signed [31:0] l21_re, l21_im;  // l21 ≈ Q2.16
reg signed [31:0] v1_re,  v1_im;   // v1 ≈ Q2.16
reg signed [31:0] v2_re,  v2_im;   // v2 ≈ Q2.16

// u: 여전히 Q4.26 → 48bit
reg signed [47:0] u1_re, u1_im;
reg signed [47:0] u2_re, u2_im;

// |l21|^2 : Q4.32 정도 → 64bit
reg signed [63:0] l21_abs2;

// d11 * |l21|^2 : Q8.58 정도 → 96bit

// l21 * u1 (Q2.16 × Q4.26 = Q6.42) → 80bit
// reg signed [79:0] l21u1_re, l21u1_im;

// l21* cong(z2) 곱 (Q2.16 × Q2.16 = Q4.32) → 64bit
// reg signed [63:0] l21z2_re, l21z2_im;

// z1: 백섭에서 사용하는 Q2.16
reg signed [31:0] z1_re, z1_im;

// noise scaled: Q1.9 → <<17 → Q18.26, 48bit 양수
reg signed [47:0] noise_q426;

// rounding, sat 시 사용
reg signed [31:0] q_rnd_re;
reg signed [31:0] q_rnd_im;
reg signed [31:0] q_tmp_re;
reg signed [31:0] q_tmp_im;

reg signed [15:0] q_sat_re;
reg signed [15:0] q_sat_im;

reg signed [31:0] q_rnd_re2;
reg signed [31:0] q_rnd_im2;
reg signed [31:0] q_tmp_re2;
reg signed [31:0] q_tmp_im2;

reg signed [15:0] q_sat_re2;
reg signed [15:0] q_sat_im2;


reg signed [47:0] d_in_d11, d_in_d22;

wire signed [31:0] cal_d11_inv, cal_d22_inv; 

reg d11_inv_start, d22_inv_start;
wire d11_inv_done, d22_inv_done;

inverse_opt d11_inverse(.clk(CLK), .RSTN(RSTN), .inv_start(d11_inv_start), .d_in(d_in_d11), .d_out(cal_d11_inv), .inv_done(d11_inv_done));

inverse_opt d22_inverse(.clk(CLK), .RSTN(RSTN), .inv_start(d22_inv_start), .d_in(d_in_d22), .d_out(cal_d22_inv), .inv_done(d22_inv_done));

// FSM state
reg [4:0] calc_state;
localparam S_IDLE                    = 4'd0;
localparam S_CALC_L21_WAIT           = 5'd4;    /// 나눗셈
localparam S_CALC_D22_STEP1          = 4'd5;
localparam S_CALC_D22_STEP2_1          = 4'd6;
localparam S_CALC_D22_STEP2_2          = 4'd7;
localparam S_CALC_D22_STEP3          = 4'd8;
localparam S_CALC_D22_STEP3_2          = 4'd9;
localparam S_CALC_FWD                = 4'd10;
localparam S_CALC_DIAG_WAIT_V        = 5'd12;
localparam S_CALC_BACK_1             = 4'd13;
localparam S_CALC_BACK_2_and_OUT_X2  = 4'd14;
localparam S_OUT_X1                  = 4'd15;

// 연산 wire

wire signed [47:0] b1_re_next;
wire signed [47:0] b1_im_next;
wire signed [47:0] b2_re_next;
wire signed [47:0] b2_im_next;

wire signed [47:0] A11_re_next;

wire signed [47:0] d22_next;



wire signed [63:0] l21z2_re_next;
wire signed [63:0] l21z2_im_next; 


// G calculation removed (pre-calculated)

assign b1_re_next =
    $signed(h11_re)*$signed(y1_re) + $signed(h11_im)*$signed(y1_im) +
    $signed(h21_re)*$signed(y2_re) + $signed(h21_im)*$signed(y2_im);
assign b1_im_next =
    $signed(h11_re)*$signed(y1_im) - $signed(h11_im)*$signed(y1_re) +
    $signed(h21_re)*$signed(y2_im) - $signed(h21_im)*$signed(y2_re);
assign b2_re_next =
    $signed(h12_re)*$signed(y1_re) + $signed(h12_im)*$signed(y1_im) +
    $signed(h22_re)*$signed(y2_re) + $signed(h22_im)*$signed(y2_im);
assign b2_im_next =
    $signed(h12_re)*$signed(y1_im) - $signed(h12_im)*$signed(y1_re) +
    $signed(h22_re)*$signed(y2_im) - $signed(h22_im)*$signed(y2_re);

assign A11_re_next = G11_CONST + ($signed({38'd0, CON[9:0]}) <<< 17);

wire signed [95:0] d11_mul_abs2_full = $signed(A11_re) * $signed(l21_abs2);
wire signed [95:0] d11_mul_abs2_sh   = d11_mul_abs2_full >>> 34;
wire signed [47:0] d11_mul_abs2_q426 = d11_mul_abs2_sh[47:0];


assign d22_next = A22_re - d11_mul_abs2_q426;

wire signed [79:0] l21u1_re_full = $signed(l21_re)*$signed(u1_re) - $signed(l21_im)*$signed(u1_im);
wire signed [79:0] l21u1_re_sh = l21u1_re_full >>> 17;
wire signed [47:0] l21u1_re_q426 = l21u1_re_sh[47:0];

wire signed [79:0] l21u1_im_full = $signed(l21_re)*$signed(u1_im) + $signed(l21_im)*$signed(u1_re);
wire signed [79:0] l21u1_im_sh = l21u1_im_full >>> 17;
wire signed [47:0] l21u1_im_q426 = l21u1_im_sh[47:0];


assign l21z2_re_next = $signed(l21_re) * $signed(v2_re) + $signed(l21_im) * $signed(v2_im);
assign l21z2_im_next = $signed(l21_re) * $signed(v2_im) - $signed(l21_im) * $signed(v2_re);


always @(posedge CLK or negedge RSTN) begin
    if (!RSTN) begin
        calc_state    <= S_IDLE;
        calc_done_reg <= 1'b0;
        ipout_reg     <= 32'd0;

        b1_re  <= 0; b1_im  <= 0;
        b2_re  <= 0; b2_im  <= 0;
        A11_re <= 0; 
        A21_re <= 0; A21_im <= 0; A22_re <= 0;

        l21_re <= 0; l21_im <= 0;
        v1_re  <= 0; v1_im  <= 0;
        v2_re  <= 0; v2_im  <= 0;
        u1_re  <= 0; u1_im  <= 0;
        u2_re  <= 0; u2_im  <= 0;

        l21_abs2       <= 0;
        z1_re          <= 0; z1_im    <= 0;
        noise_q426     <= 0;

        x1_re <= 0; x1_im <= 0;
        x2_re <= 0; x2_im <= 0;

        d11_inv_q216  <= 32'sd0;
        d22_inv_q216  <= 32'sd0;
        d11_inv_start <= 1'b0;
        d22_inv_start <= 1'b0;
        d_in_d11      <= 48'sd0;
        d_in_d22      <= 48'sd0;

    end
    else begin

        case (calc_state)

            S_IDLE: begin
                calc_done_reg <= 1'b0;
                ipout_reg <= 32'd0;
                d11_inv_start <= 1'b0; 

                if (read_pulse) begin
                    noise_q426 <= $signed({38'd0, CON[9:0]}) <<< 17; 
                    
                    b1_re <= b1_re_next;
                    b1_im <= b1_im_next;
                    b2_re <= b2_re_next;
                    b2_im <= b2_im_next;

                    A11_re <= A11_re_next;
                    A22_re <= G22_CONST + ($signed({38'd0, CON[9:0]}) <<< 17);

                    A21_re <= G21_RE_CONST;
                    A21_im <= G21_IM_CONST;  

                    d_in_d11 <= A11_re_next;
                    d11_inv_start <= 1; 

                    calc_state <= S_CALC_L21_WAIT;
                end
            end

            S_CALC_L21_WAIT: begin
                d11_inv_start <= 1'b0;
                if (d11_inv_done) begin
                    d11_inv_q216 <= (cal_d11_inv >>> 12);

                    calc_state <= S_CALC_D22_STEP1;       
                end
                else calc_state <= S_CALC_L21_WAIT;
            end

            S_CALC_D22_STEP1: begin
                l21_re <= (A21_re * d11_inv_q216) >>> 26;
                l21_im <= (A21_im * d11_inv_q216) >>> 26;

                calc_state <= S_CALC_D22_STEP2_1;
            end

            S_CALC_D22_STEP2_1: begin
                l21_abs2 <=
                    $signed(l21_re)*$signed(l21_re) +
                    $signed(l21_im)*$signed(l21_im);

                calc_state <= S_CALC_D22_STEP3;
            end

            S_CALC_D22_STEP3: begin
                d_in_d22 <= d22_next;
                d22_inv_start <= 1'b1;

                u1_re <= b1_re;
                u1_im <= b1_im;
    
                calc_state <= S_CALC_FWD;
            end

            S_CALC_FWD: begin
                u2_re <= b2_re - l21u1_re_q426;
                u2_im <= b2_im - l21u1_im_q426;
                
                d22_inv_start <= 1'b0;

                if (d22_inv_done) begin
                    d22_inv_q216 <= (cal_d22_inv >>> 12);
                    calc_state <= S_CALC_DIAG_WAIT_V;
                end
                else calc_state<= S_CALC_FWD;
            end

            S_CALC_DIAG_WAIT_V: begin
                v1_re <= (u1_re * d11_inv_q216) >>> 26;
                v1_im <= (u1_im * d11_inv_q216) >>> 26;
                v2_re <= (u2_re * d22_inv_q216) >>> 26;
                v2_im <= (u2_im * d22_inv_q216) >>> 26;

                calc_state <= S_CALC_BACK_1;
            
            end

            S_CALC_BACK_1: begin
                q_rnd_re = v2_re + 32'sd4;
                q_rnd_im = v2_im + 32'sd4;

                // 스케일 다운 (>>3 = /8)
                q_tmp_re = q_rnd_re >>> 4;
                q_tmp_im = q_rnd_im >>> 4;

                // 포화 (16bit)
                if (q_tmp_re > 32'sh7FFF)           q_sat_re = 16'sh7FFF;
                else if (q_tmp_re < -32'sh8000)     q_sat_re = -16'sh8000;
                else                                q_sat_re = q_tmp_re[15:0];

                if (q_tmp_im > 32'sh7FFF)           q_sat_im = 16'sh7FFF;
                else if (q_tmp_im < -32'sh8000)     q_sat_im = -16'sh8000;
                else                                q_sat_im = q_tmp_im[15:0];

                x2_re <= q_sat_re;
                x2_im <= q_sat_im;

                // 스케일 정렬해서 v1(Q2.16)과 뺄셈
                z1_re <= v1_re - $signed(l21z2_re_next >>> 17);
                z1_im <= v1_im - $signed(l21z2_im_next >>> 17);

                calc_state <= S_CALC_BACK_2_and_OUT_X2;
            end

            S_CALC_BACK_2_and_OUT_X2: begin

                q_rnd_re2 = z1_re + 32'sd4;
                q_rnd_im2 = z1_im + 32'sd4;

                // 스케일 다운
                q_tmp_re2 = q_rnd_re2 >>> 4;
                q_tmp_im2 = q_rnd_im2 >>> 4;

                // 포화
                if (q_tmp_re2 > 32'sh7FFF)          q_sat_re2 = 16'sh7FFF;
                else if (q_tmp_re2 < -32'sh8000)    q_sat_re2 = -16'sh8000;
                else                                 q_sat_re2 = q_tmp_re2[15:0];

                if (q_tmp_im2 > 32'sh7FFF)          q_sat_im2 = 16'sh7FFF;
                else if (q_tmp_im2 < -32'sh8000)    q_sat_im2 = -16'sh8000;
                else                                 q_sat_im2 = q_tmp_im2[15:0];

                x1_re <= q_sat_re2;
                x1_im <= q_sat_im2;

                ipout_reg     <= {x2_re, x2_im};
                calc_state    <= S_OUT_X1;

            end

            S_OUT_X1: begin
                ipout_reg     <= {x1_re, x1_im};
                calc_done_reg <= 1'b1;
                calc_state    <= S_IDLE;
            end

        endcase
    end
end

assign IPOUT = ipout_reg;

endmodule



module inverse_opt (
    input clk,
    input RSTN,
    input inv_start,
    input signed [47:0] d_in,
    output reg signed [31:0] d_out,
    output reg inv_done
);

    reg signed [31:0] x_reg;
    reg signed [79:0] t1_raw;
    reg signed [31:0] t1;
    reg signed [31:0] t2;


    reg signed [63:0] x_next_raw;
    reg signed [31:0] x_next;

    wire [7:0] d_q23 = d_in >>> 23;

    wire [4:0] idx = (d_q23 <= 8'd4)  ? 5'd0 :
                    (d_q23 >= 8'd36) ? 5'd31 :
                    (d_q23 - 8'd4);

    wire [31:0] x_0;

    recip_lut32 u_lut(.idx(idx), .y0(x_0));

    reg [3:0] state;
    localparam S_IDLE   = 4'd0;
    localparam S_INIT   = 4'd1; 
    localparam S_ITER1  = 4'd2;
    localparam S_ITER1_2  = 4'd3;
    localparam S_ITER2  = 4'd4;
    localparam S_ITER2_2  = 4'd5;
    localparam S_DONE   = 4'd6;

    
    always @(posedge clk or negedge RSTN)  begin
        if (!RSTN) begin
            state <= S_IDLE;
            inv_done <= 0;
            d_out <= 0;
            x_reg    <= 32'sd0;
        end
        else begin
            inv_done <= 0;
            case(state)
                S_IDLE: 
                    if (inv_start) begin
                        x_reg <= x_0;
                        state <= S_ITER1;
                    end
                
                // x_{k+1} = x_k * (2 - d * x_k)
                S_ITER1: begin
                    t1_raw = $signed(d_in) * $signed(x_reg);
                    t1 = $signed(t1_raw >>>26);
                    t2 = (32'sd2 <<< 29) - t1;
                    state <= S_ITER1_2;
                end

                S_ITER1_2: begin
                    x_next_raw = $signed(x_reg) * $signed(t2);
                    x_next = $signed(x_next_raw) >>> 29;
                    x_reg <= x_next;
                    state <= S_ITER2;
                end

                S_ITER2 : begin
                    t1_raw = $signed(d_in) * $signed(x_reg);
                    t1     = $signed(t1_raw >>> 26);
                    t2 = (32'sd2 <<< 29) - t1;

                    state <= S_ITER2_2;
                end

                S_ITER2_2 : begin
                    x_next_raw = $signed(x_reg) * $signed(t2);
                    x_next = x_next_raw >>> 29;
                    x_reg <= x_next;
                    state <= S_DONE;
                end


                S_DONE : begin
                    d_out <= x_reg;
                    inv_done <= 1'b1;
                    state <= S_IDLE;
                end

            endcase
        end
    end
endmodule



module recip_lut32 (
    input  wire [4:0] idx,
    output reg  [31:0] y0   // Q1.29
);
always @(*) begin
    case (idx)
        5'd0 :  y0 = 32'h40000000; // d=0.50, x0=2.000000
        5'd1 :  y0 = 32'h3199999A; // d=0.645, x0=1.55
        5'd2 :  y0 = 32'h287D6344; // d=0.790, x0=1.265306
        5'd3 :  y0 = 32'h2234F72C; // d=0.935, x0=1.068966
        5'd4 :  y0 = 32'h1D9CA81F; // d=1.081, x0=0.925373
        5'd5 :  y0 = 32'h1A1AF287; // d=1.226, x0=0.815789
        5'd6 :  y0 = 32'h17575757; // d=1.371, x0=0.729412
        5'd7 :  y0 = 32'h151B3BEA; // d=1.516, x0=0.659574
        5'd8 :  y0 = 32'h13431B57; // d=1.661, x0=0.601942
        5'd9 :  y0 = 32'h11B6DB6E; // d=1.806, x0=0.553571
        5'd10:  y0 = 32'h10658DC1; // d=1.952, x0=0.512397
        5'd11:  y0 = 32'h0F42F42F; // d=2.097, x0=0.476923
        5'd12:  y0 = 32'h0E45FC51; // d=2.242, x0=0.446043
        5'd13:  y0 = 32'h0D67C8A6; // d=2.387, x0=0.418919
        5'd14:  y0 = 32'h0CA30EAD; // d=2.532, x0=0.394904
        5'd15:  y0 = 32'h0BF3A9A3; // d=2.677, x0=0.373494
        5'd16:  y0 = 32'h0B564EFF; // d=2.823, x0=0.354286
        5'd17:  y0 = 32'h0AC8590B; // d=2.968, x0=0.336957
        5'd18:  y0 = 32'h0A47A07F; // d=3.113, x0=0.321244
        5'd19:  y0 = 32'h09D26051; // d=3.258, x0=0.306931
        5'd20:  y0 = 32'h096720C2; // d=3.403, x0=0.293839
        5'd21:  y0 = 32'h0904A790; // d=3.548, x0=0.281818
        5'd22:  y0 = 32'h08A9EBE1; // d=3.694, x0=0.270742
        5'd23:  y0 = 32'h08560CE8; // d=3.839, x0=0.260504
        5'd24:  y0 = 32'h08084AA0; // d=3.984, x0=0.251012
        5'd25:  y0 = 32'h07C00000; // d=4.129, x0=0.242187
        5'd26:  y0 = 32'h077C9E6E; // d=4.274, x0=0.233962
        5'd27:  y0 = 32'h073DAA0B; // d=4.419, x0=0.226277
        5'd28:  y0 = 32'h0702B6BA; // d=4.565, x0=0.219081
        5'd29:  y0 = 32'h06CB65B3; // d=4.710, x0=0.212329
        5'd30:  y0 = 32'h06976382; // d=4.855, x0=0.205980
        5'd31:  y0 = 32'h06666666; // d=5.000, x0=0.200000
        default: y0 = 32'h00000000;
    endcase
end
endmodule

