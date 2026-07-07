/*****************************************
    testbench.v

    Project

    Team 08 :
        2021104213    Kim Minsung
        2023105225    Kim Jihyun

    [테스트 내용] CUSTOM_IP (2×2 MMSE MIMO 가속기) 단독 검증
    ──────────────────────────────────────────────────────────
    CPU·메모리 없이 CUSTOM_IP만 직접 구동하는 단위 테스트.

    입력 프로토콜:
      ① CON[15]=1, IPIN[15:0]=y1_re  → start_pulse 발생, busy=1
      ② IPIN[15:0]=y1_im             (rd_cnt=1)
      ③ IPIN[15:0]=y2_re             (rd_cnt=2)
      ④ IPIN[15:0]=y2_im             (rd_cnt=3)
      ⑤ rd_cnt=4 → read_done → FSM 연산 시작

    출력 타이밍:
      - S_CALC_BACK_2_and_OUT_X2 사이클:
            IPOUT[31:16]=x2_re, IPOUT[15:0]=x2_im  (Q2.13)
      - S_OUT_X1 사이클 (calc_done=1):
            IPOUT[31:16]=x1_re, IPOUT[15:0]=x1_im  (Q2.13)
      - 이후 S_IDLE 복귀, IPOUT=0

    H 행렬 (CUSTOM_IP 내부 하드코딩):
      h11 ≈  0.720 + j·0.110   h12 ≈ -0.320 + j·0.400
      h21 ≈  0.150 - j·0.500   h22 ≈  0.880 + j·0.070
    (Q2.13 기준: 1.0 = 8192 = 16'h2000)

    테스트 케이스:
      TC1: y = [1+0j,  1+0j],    noise = 0
      TC2: y = [1+1j,  0-1j],    noise = 0
      TC3: y = [0.5+0j, 0+0.5j], noise = 4  (Q1.9 = 10'h004)

    [주의] LDL^H FSM + Newton-Raphson 역수 연산(×2) 완료까지
           약 50~100 클럭 소요. 각 TC 사이 200클럭 대기.
*****************************************/

`timescale 1ns/1ps

module testbench;

    // ── Clock & Reset ────────────────────────────────────────
    reg         CLK, RSTN;
    parameter   PERIOD  = 10.0;
    parameter   HPERIOD = PERIOD / 2.0;

    initial CLK = 1'b0;
    always #(HPERIOD) CLK = ~CLK;

    // ── DUT ──────────────────────────────────────────────────
    reg  [31:0] IPIN;
    reg  [31:0] CON;
    wire [31:0] IPOUT;

    CUSTOM_IP DUT (
        .CLK  (CLK),
        .RSTN (RSTN),
        .IPIN (IPIN),
        .CON  (CON),
        .IPOUT(IPOUT)
    );

    // ── 출력 캡처 ────────────────────────────────────────────
    // IPOUT은 x2 출력 1사이클, x1 출력 1사이클만 유지되므로
    // posedge 마다 비영(nonzero) 값을 순서대로 캡처한다.
    integer     out_phase;
    reg [31:0]  x2_out, x1_out;

    always @(posedge CLK) begin
        if (RSTN && IPOUT != 32'd0) begin
            if (out_phase == 0) begin
                x2_out    <= IPOUT;
                out_phase <= 1;
            end else if (out_phase == 1) begin
                x1_out    <= IPOUT;
                out_phase <= 2;
            end
        end
    end

    // ── 입력 구동 ────────────────────────────────────────────
    // negedge에 입력을 바꿔 posedge 셋업 타임을 확보한다.
    task drive_y;
        input [15:0] y1r, y1i, y2r, y2i;
        input [9:0]  noise;
        begin
            out_phase = 0;
            x2_out    = 32'd0;
            x1_out    = 32'd0;

            // ① start_pulse: CON[15]=1, IPIN[15:0]=y1_re
            @(negedge CLK);
            IPIN = {16'h0000, y1r};
            CON  = {16'h0000, 1'b1, 5'b00000, noise}; // CON[15]=1, CON[9:0]=noise

            @(negedge CLK); IPIN = {16'h0000, y1i}; // rd_cnt=1 → y1_im
            @(negedge CLK); IPIN = {16'h0000, y2r}; // rd_cnt=2 → y2_re
            @(negedge CLK); IPIN = {16'h0000, y2i}; // rd_cnt=3 → y2_im
            // rd_cnt=4 다음 사이클: read_done=1 → FSM 시작
            @(negedge CLK);
            IPIN = 32'h0;
            CON  = 32'h0;

            // LDL^H + Newton-Raphson 완료까지 대기 (200클럭)
            repeat(200) @(posedge CLK);
        end
    endtask

    // ── 결과 출력 ────────────────────────────────────────────
    task show_result;
        begin
            $display("  x2: raw=0x%08h  re=%6d  im=%6d",
                x2_out,
                $signed(x2_out[31:16]),
                $signed(x2_out[15:0]));
            $display("  x1: raw=0x%08h  re=%6d  im=%6d",
                x1_out,
                $signed(x1_out[31:16]),
                $signed(x1_out[15:0]));
            $display("  (Q2.13: divide by 8192 to get float)");
        end
    endtask

    // ── 메인 시퀀스 ──────────────────────────────────────────
    initial begin
        $dumpfile("sim_CUSTOM_IP.vcd");
        $dumpvars(0, testbench);

        RSTN = 0; IPIN = 32'h0; CON = 32'h0;
        out_phase = 0; x2_out = 0; x1_out = 0;

        repeat(10) @(posedge CLK);
        RSTN = 1;
        repeat(5)  @(posedge CLK);

        // ── TC1: y = [1+0j, 1+0j],  noise = 0 ───────────────
        $display("========================================");
        $display("[%0t ns] TC1: y=[1+0j, 1+0j]  noise=0", $time);
        drive_y(16'h2000, 16'h0000, 16'h2000, 16'h0000, 10'd0);
        show_result();
        repeat(20) @(posedge CLK);

        // ── TC2: y = [1+1j, 0-1j],  noise = 0 ───────────────
        // 1.0 = 0x2000,  -1.0 = 0xE000  (Q2.13 signed)
        $display("========================================");
        $display("[%0t ns] TC2: y=[1+1j, 0-1j]  noise=0", $time);
        drive_y(16'h2000, 16'h2000, 16'h0000, 16'hE000, 10'd0);
        show_result();
        repeat(20) @(posedge CLK);

        // ── TC3: y = [0.5+0j, 0+0.5j],  noise = 4 ───────────
        // 0.5 = 4096 = 0x1000,  noise Q1.9 = 4
        $display("========================================");
        $display("[%0t ns] TC3: y=[0.5+0j, 0+0.5j]  noise=4", $time);
        drive_y(16'h1000, 16'h0000, 16'h0000, 16'h1000, 10'h004);
        show_result();

        $display("========================================");
        $display("[%0t ns] Simulation complete.", $time);
        $finish;
    end

endmodule
