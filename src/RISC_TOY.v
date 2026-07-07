/*****************************************
   Team 08 :
       2021104213    Kim Minsung
       2023105225    Kim Jihyun
*****************************************/


// You are able to add additional modules and instantiate in RISC_TOY.


////////////////////////////////////
//  TOP MODULE
////////////////////////////////////




module RISC_TOY (
    input  wire         CLK,
    input  wire         RSTN,
    output wire         IREQ,
    output wire [29:0]  IADDR,
    input  wire [31:0]  INSTR,
    output wire         DREQ,
    output wire [1:0]   DRW,
    output wire [29:0]  DADDR,
    output wire [31:0]  DWDATA,
    output wire [31:0]  CONSIG,
    input  wire [31:0]  DRDATA
);


    wire [2:0]  w_ImmType;
    wire [3:0]  w_ALUOp;
    wire        w_ALUSrc;
    wire        w_RegWrite_ID;
    wire        w_MemRead_ID;
    wire        w_MemWrite_ID;
    wire [1:0]  w_MemtoReg_ID;
    wire        w_Branch_ID;
    wire        w_Jump_ID;
    wire        w_IP_MemRead_ID;
    wire        w_IP_MemWrite_ID;


    wire        w_Stall;
    wire        w_IF_Flush;
    wire [1:0]  w_ForwardA;
    wire [1:0]  w_ForwardB;
    wire [1:0]  w_ForwardStore;


    wire [4:0]  w_Opcode;
    wire        w_EX_MemRead;
    wire        w_EX_MemWrite;
    wire        w_EX_RegWrite;
    wire        w_MEM_RegWrite;
    wire        w_WB_RegWrite;
    wire        w_EX_Branch;
    wire        w_EX_Jump;
    wire        w_EX_Branch_Taken_Result;
    wire [4:0]  w_ID_rs1_addr;
    wire [4:0]  w_ID_rs2_addr;
    wire [4:0]  w_ID_EX_rd_addr;
    wire [4:0]  w_EX_MEM_rd_addr;
    wire [4:0]  w_MEM_WB_rd_addr;


    wire [4:0]  w_EX_rs1_addr;
    wire [4:0]  w_EX_rs2_addr;


    wire        w_GPR_WriteEn;
    wire [4:0]  w_GPR_WriteAddr;
    wire [31:0] w_GPR_WriteData;
    wire [4:0]  w_GPR_ReadAddr1;
    wire [4:0]  w_GPR_ReadAddr2;
    wire [31:0] w_GPR_ReadData1; 
    wire [31:0] w_GPR_ReadData2; 


    wire [31:0] w_EX_ALU_Result_Out;

    Datapath u_Datapath (
        .CLK               (CLK),
        .RSTN              (RSTN),
        .IREQ              (IREQ),
        .IADDR             (IADDR),
        .INSTR             (INSTR),
        .DREQ              (DREQ),
        .DRW               (DRW),
        .DADDR             (DADDR),
        .DWDATA            (DWDATA),
        .DRDATA            (DRDATA),


        .ImmType           (w_ImmType),
        .ALUOp             (w_ALUOp),
        .ALUSrc            (w_ALUSrc),
        .RegWrite_ID       (w_RegWrite_ID),
        .MemRead_ID        (w_MemRead_ID),
        .MemWrite_ID       (w_MemWrite_ID),
        .MemtoReg_ID       (w_MemtoReg_ID),
        .Branch_ID         (w_Branch_ID),
        .Jump_ID           (w_Jump_ID),
        .IP_MemRead_ID     (w_IP_MemRead_ID),
        .IP_MemWrite_ID    (w_IP_MemWrite_ID),
        .Opcode            (w_Opcode),


        .IF_Flush          (w_IF_Flush),
        .Stall             (w_Stall),
        .ForwardA          (w_ForwardA),
        .ForwardB          (w_ForwardB),
        .ForwardStore      (w_ForwardStore),


        .EX_MemRead        (w_EX_MemRead),
        .EX_MemWrite       (w_EX_MemWrite),
        .EX_RegWrite       (w_EX_RegWrite),
        .MEM_RegWrite      (w_MEM_RegWrite),
        .WB_RegWrite       (w_WB_RegWrite),
        .EX_Branch         (w_EX_Branch),
        .EX_Jump           (w_EX_Jump),
        .EX_Branch_Taken_Result (w_EX_Branch_Taken_Result),
        .EX_ALU_Result_Out (w_EX_ALU_Result_Out),


        .ID_rs1_addr       (w_ID_rs1_addr),
        .ID_rs2_addr       (w_ID_rs2_addr),
        .ID_EX_rd_addr     (w_ID_EX_rd_addr),
        .EX_MEM_rd_addr    (w_EX_MEM_rd_addr),
        .MEM_WB_rd_addr    (w_MEM_WB_rd_addr),
        .EX_rs1_out        (w_EX_rs1_addr),
        .EX_rs2_out        (w_EX_rs2_addr),


        .GPR_ReadAddr1     (w_GPR_ReadAddr1),
        .GPR_ReadAddr2     (w_GPR_ReadAddr2),
        .GPR_WriteEn       (w_GPR_WriteEn),
        .GPR_WriteAddr     (w_GPR_WriteAddr),
        .GPR_WriteData     (w_GPR_WriteData),
        .GPR_ReadData1     (w_GPR_ReadData1),
        .GPR_ReadData2     (w_GPR_ReadData2)
    );


    Controller u_Controller (
        .Opcode    (w_Opcode),
        .ALUSrc    (w_ALUSrc),
        .ALUOp     (w_ALUOp),
        .Branch    (w_Branch_ID),
        .Jump      (w_Jump_ID),
        .MemRead   (w_MemRead_ID),
        .MemWrite  (w_MemWrite_ID),
        .MemtoReg  (w_MemtoReg_ID),
        .RegWrite  (w_RegWrite_ID),
        .ImmType   (w_ImmType),
        .IP_Load   (w_IP_MemRead_ID),
        .IP_Store  (w_IP_MemWrite_ID)
    );


    HazardUnit u_Hazard (
        .ID_EX_MemRead     (w_EX_MemRead),
        .ID_EX_MemWrite    (w_EX_MemWrite),
        .ID_EX_RegWrite    (w_EX_RegWrite),
        .EX_MEM_RegWrite   (w_MEM_RegWrite),
        .MEM_WB_RegWrite   (w_WB_RegWrite),


        .ID_Branch         (w_Branch_ID),
        .ID_Jump           (w_Jump_ID),


        .EX_Branch         (w_EX_Branch),
        .EX_Jump           (w_EX_Jump),
        .EX_Branch_Taken   (w_EX_Branch_Taken_Result),


        .ID_rs1_addr       (w_ID_rs1_addr),
        .ID_rs2_addr       (w_ID_rs2_addr),
        .EX_rs1_addr       (w_EX_rs1_addr),
        .EX_rs2_addr       (w_EX_rs2_addr),
        .ID_EX_rd_addr     (w_ID_EX_rd_addr),
        .EX_MEM_rd_addr    (w_EX_MEM_rd_addr),
        .MEM_WB_rd_addr    (w_MEM_WB_rd_addr),


        .IF_Flush          (w_IF_Flush),
        .Stall             (w_Stall),
        .ForwardA          (w_ForwardA),
        .ForwardB          (w_ForwardB),
        .ForwardStore      (w_ForwardStore)
    );


    REGFILE #(
        .AW    (5),
        .ENTRY (32)
    ) RegFile (
        .CLK    (CLK),
        .RSTN   (RSTN),
        .WEN    (~w_GPR_WriteEn),
        .WA     (w_GPR_WriteAddr),
        .DI     (w_GPR_WriteData),
        .RA0    (w_GPR_ReadAddr1),
        .RA1    (w_GPR_ReadAddr2),
        .DOUT0  (w_GPR_ReadData1),
        .DOUT1  (w_GPR_ReadData2),
        .CONSIG (CONSIG)
    );


endmodule

module adder (
    input  [31:0] a,
    input  [31:0] b,
    output [31:0] y
);
    assign y = a + b;
endmodule


module mux2 (
    input  [31:0] d0,
    input  [31:0] d1,
    input         s,
    output [31:0] y
);
    assign y = s ? d1 : d0;
endmodule


module mux3 (
    input  [31:0] d00,
    input  [31:0] d01,
    input  [31:0] d10,
    input  [1:0]  s,
    output [31:0] y
);
    assign y = (s == 2'b10) ? d10 :
               (s == 2'b01) ? d01 :
                              d00;
endmodule

module flopr #(
    parameter WIDTH = 32
) (
    input                 clk,
    input                 RSTN,
    input  [WIDTH-1:0]    d,
    input                 stall,
    output reg [WIDTH-1:0] q
);
    always @(posedge clk or negedge RSTN) begin
        if (!RSTN)
            q <= {WIDTH{1'b0}};
        else if (!stall)
            q <= d;
    end
endmodule

module ImmGen (
    input  [31:0] INSTR,
    input  [2:0]  ImmType,
    output reg [31:0] Immediate
);


    wire [16:0] imm17 = INSTR[16:0];
    wire [21:0] imm22 = INSTR[21:0];
    wire [4:0]  rb    = INSTR[21:17];


    parameter [2:0] IMM_R  = 3'b000,
                    IMM_I  = 3'b001,
                    IMM_LD = 3'b010,
                    IMM_ST = 3'b011,
                    IMM_J  = 3'b100,
                    IMM_IP = 3'b101;


    always @(*) begin
        case (ImmType)
            IMM_I: begin
                Immediate = { {15{imm17[16]}}, imm17 };
            end

            IMM_LD: begin
                if (rb == 5'b11111)
                    Immediate = { 15'b0, imm17 };
                else
                    Immediate = { {15{imm17[16]}}, imm17 };
            end

            IMM_ST: begin
                if (rb == 5'b11111)
                    Immediate = { 15'b0, imm17 };
                else
                    Immediate = { {15{imm17[16]}}, imm17 };
            end


            IMM_J: begin
                Immediate = { {10{imm22[21]}}, imm22 };
            end


             IMM_IP: begin
                Immediate = { 10'b0, imm22 };
            end


            default: begin
                Immediate = 32'h00000000;
            end
        endcase
    end
endmodule



module Controller (
    input [4:0] Opcode,


    // EX
    output reg       ALUSrc,
    output reg [3:0] ALUOp,
    output reg       Branch,
    output reg       Jump,


    // MEM
    output reg       MemRead,
    output reg       MemWrite,


    // WB
    output reg [1:0] MemtoReg,
    output reg       RegWrite,


    // IP
    output reg       IP_Load,
    output reg       IP_Store,


    // Imm type
    output reg [2:0] ImmType
);


    // OPCODE
    parameter [4:0] ADD  = 5'd0,
                    ADDI = 5'd1,
                    SUB  = 5'd2,
                    NEG  = 5'd3,
                    NOT_ = 5'd4,
                    AND_ = 5'd5,
                    ANDI = 5'd6,
                    OR_  = 5'd7,
                    ORI  = 5'd8,
                    XOR_ = 5'd9,
                    LSR  = 5'd10,
                    ASR  = 5'd11,
                    SHL  = 5'd12,
                    ROR  = 5'd13,
                    MOVI = 5'd14,
                    J    = 5'd15,
                    JL   = 5'd16,
                    BR   = 5'd17,
                    BRL  = 5'd18,
                    ST   = 5'd19,
                    STR  = 5'd20,
                    LD   = 5'd21,
                    LDR  = 5'd22,
                    LDIP = 5'd23,
                    STIP = 5'd24;


    // ALUOp
    parameter [3:0] ALU_ADD    = 4'b0000,
                    ALU_SUB    = 4'b0001,
                    ALU_AND    = 4'b0010,
                    ALU_OR     = 4'b0011,
                    ALU_XOR    = 4'b0100,
                    ALU_LSR    = 4'b0101,
                    ALU_ASR    = 4'b0110,
                    ALU_SHL    = 4'b0111,
                    ALU_ROR    = 4'b1000,
                    ALU_NEG    = 4'b1001,
                    ALU_NOT    = 4'b1010,
                    ALU_PASS_B = 4'b1011,
                    ALU_COND   = 4'b1100;


    parameter [2:0] IMM_R  = 3'b000,
                    IMM_I  = 3'b001,
                    IMM_LD = 3'b010,
                    IMM_ST = 3'b011,
                    IMM_J  = 3'b100,
                    IMM_IP = 3'b101;


    // MemtoReg
    parameter [1:0] MTR_ALU = 2'b00,
                    MTR_MEM = 2'b01,
                    MTR_PC  = 2'b10;


    always @(*) begin
        ALUSrc   = 1'b0;
        ALUOp    = 4'b0000;
        Branch   = 1'b0;
        Jump     = 1'b0;
        MemRead  = 1'b0;
        MemWrite = 1'b0;
        MemtoReg = MTR_ALU;
        RegWrite = 1'b0;
        IP_Load  = 1'b0;
        IP_Store = 1'b0;
        ImmType  = IMM_R;


        case (Opcode)
            // R-type
            ADD:  begin RegWrite=1; ALUSrc=0; ALUOp=ALU_ADD; MemtoReg=MTR_ALU; ImmType=IMM_R; end
            SUB:  begin RegWrite=1; ALUSrc=0; ALUOp=ALU_SUB; MemtoReg=MTR_ALU; ImmType=IMM_R; end
            NEG:  begin RegWrite=1; ALUSrc=0; ALUOp=ALU_NEG; MemtoReg=MTR_ALU; ImmType=IMM_R; end
            NOT_: begin RegWrite=1; ALUSrc=0; ALUOp=ALU_NOT; MemtoReg=MTR_ALU; ImmType=IMM_R; end
            AND_: begin RegWrite=1; ALUSrc=0; ALUOp=ALU_AND; MemtoReg=MTR_ALU; ImmType=IMM_R; end
            OR_:  begin RegWrite=1; ALUSrc=0; ALUOp=ALU_OR;  MemtoReg=MTR_ALU; ImmType=IMM_R; end
            XOR_: begin RegWrite=1; ALUSrc=0; ALUOp=ALU_XOR; MemtoReg=MTR_ALU; ImmType=IMM_R; end


            // Shifters
            LSR:  begin RegWrite=1; ALUSrc=0; ALUOp=ALU_LSR; MemtoReg=MTR_ALU; ImmType=IMM_R; end
            ASR:  begin RegWrite=1; ALUSrc=0; ALUOp=ALU_ASR; MemtoReg=MTR_ALU; ImmType=IMM_R; end
            SHL:  begin RegWrite=1; ALUSrc=0; ALUOp=ALU_SHL; MemtoReg=MTR_ALU; ImmType=IMM_R; end
            ROR:  begin RegWrite=1; ALUSrc=0; ALUOp=ALU_ROR; MemtoReg=MTR_ALU; ImmType=IMM_R; end


            // I-type
            ADDI: begin RegWrite=1; ALUSrc=1; ALUOp=ALU_ADD; MemtoReg=MTR_ALU; ImmType=IMM_I; end
            ANDI: begin RegWrite=1; ALUSrc=1; ALUOp=ALU_AND; MemtoReg=MTR_ALU; ImmType=IMM_I; end
            ORI:  begin RegWrite=1; ALUSrc=1; ALUOp=ALU_OR;  MemtoReg=MTR_ALU; ImmType=IMM_I; end
            MOVI: begin RegWrite=1; ALUSrc=1; ALUOp=ALU_PASS_B; MemtoReg=MTR_ALU; ImmType=IMM_I; end


            // Load
            LD:  begin RegWrite=1; ALUSrc=1; ALUOp=ALU_ADD; MemRead=1; MemtoReg=MTR_MEM; ImmType=IMM_LD; end
            LDR: begin RegWrite=1; ALUSrc=1; ALUOp=ALU_ADD; MemRead=1; MemtoReg=MTR_MEM; ImmType=IMM_J;  end


            // Store
            ST:  begin RegWrite=0; ALUSrc=1; ALUOp=ALU_ADD; MemWrite=1; ImmType=IMM_ST; end
            STR: begin RegWrite=0; ALUSrc=1; ALUOp=ALU_ADD; MemWrite=1; ImmType=IMM_J;  end


            // Branch
            BR:  begin RegWrite=0; ALUSrc=0; ALUOp=ALU_COND; Branch=1; ImmType=IMM_R; end
            BRL: begin RegWrite=1; ALUSrc=0; ALUOp=ALU_COND; Branch=1; MemtoReg=MTR_PC; ImmType=IMM_R; end


            // Jump
            J:   begin RegWrite=0; ALUSrc=1; ALUOp=ALU_ADD; Jump=1; ImmType=IMM_J; end
            JL:  begin RegWrite=1; ALUSrc=1; ALUOp=ALU_ADD; Jump=1; MemtoReg=MTR_PC; ImmType=IMM_J; end


            // IP instructions
            LDIP: begin RegWrite=0; ALUSrc=1; ALUOp=ALU_ADD; MemRead=1;  IP_Load=1;  ImmType=IMM_IP; end
            STIP: begin RegWrite=0; ALUSrc=1; ALUOp=ALU_ADD; MemWrite=1; IP_Store=1; ImmType=IMM_IP; end


            default: begin
            end
        endcase
    end


endmodule


module ALU (
    input  [31:0] A,
    input  [31:0] B,
    input  [3:0]  ALUOp,
    input  [4:0]  Shamt_i,
    input  [4:0]  Shamt_r,
    input         i_bit,
    input  [2:0]  Cond,


    output reg [31:0] Result,
    output reg        BranchTaken
);
    parameter [3:0] ALU_ADD    = 4'b0000,
                    ALU_SUB    = 4'b0001,
                    ALU_AND    = 4'b0010,
                    ALU_OR     = 4'b0011,
                    ALU_XOR    = 4'b0100,
                    ALU_LSR    = 4'b0101,
                    ALU_ASR    = 4'b0110,
                    ALU_SHL    = 4'b0111,
                    ALU_ROR    = 4'b1000,
                    ALU_NEG    = 4'b1001,
                    ALU_NOT    = 4'b1010,
                    ALU_PASS_B = 4'b1011,
                    ALU_COND   = 4'b1100;


    wire [4:0] shift_amount = i_bit ? Shamt_r : Shamt_i;


    always @(*) begin
        Result      = 32'h00000000;
        BranchTaken = 1'b0;


        case (ALUOp)
            ALU_ADD:    Result = A + B;
            ALU_SUB:    Result = A - B;
            ALU_NEG:    Result = ~B + 1;
            ALU_NOT:    Result = ~B;
            ALU_AND:    Result = A & B;
            ALU_OR:     Result = A | B;
            ALU_XOR:    Result = A ^ B;
            ALU_LSR:    Result = A >> shift_amount;
            ALU_ASR:    Result = $signed(A) >>> shift_amount;
            ALU_SHL:    Result = A << shift_amount;
            ALU_ROR: begin
                if (shift_amount == 0)
                    Result = A;
                else
                    Result = (A >> shift_amount) | (A << (32 - shift_amount));
            end
            ALU_PASS_B: Result = B;


            ALU_COND: begin
                Result = A;
                case (Cond)
                    3'b000: BranchTaken = 1'b0;
                    3'b001: BranchTaken = 1'b1;
                    3'b010: BranchTaken = (B == 32'b0);
                    3'b011: BranchTaken = (B != 32'b0);
                    3'b100: BranchTaken = ($signed(B) >= 0);
                    3'b101: BranchTaken = ($signed(B) < 0);
                    default: BranchTaken = 1'b0;
                endcase
            end


            default: begin
                Result = 32'h00000000;
            end
        endcase
    end


endmodule

module HazardUnit (
    input        ID_EX_MemRead,
    input        ID_EX_MemWrite,
    input        ID_EX_RegWrite,
    input        EX_MEM_RegWrite,
    input        MEM_WB_RegWrite,


    input        ID_Branch,
    input        ID_Jump,


    input        EX_Branch,
    input        EX_Jump,
    input        EX_Branch_Taken,


    input  [4:0] ID_rs1_addr,
    input  [4:0] ID_rs2_addr,
    input  [4:0] EX_rs1_addr,
    input  [4:0] EX_rs2_addr,
    input  [4:0] ID_EX_rd_addr,
    input  [4:0] EX_MEM_rd_addr,
    input  [4:0] MEM_WB_rd_addr,
   


    output reg   IF_Flush,
    output reg   Stall,
    output reg [1:0] ForwardA,
    output reg [1:0] ForwardB,
    output reg [1:0] ForwardStore
);


    wire ld_use_hazard;
    wire branch_load_hazard;


    assign ld_use_hazard =
        ID_EX_MemRead &&
        (ID_EX_rd_addr != 5'b0) &&
        ((ID_EX_rd_addr == ID_rs1_addr) ||
         (ID_EX_rd_addr == ID_rs2_addr));


    assign branch_load_hazard =
        ID_Branch && ID_EX_MemRead &&
        (ID_EX_rd_addr != 5'b0) &&
        ((ID_EX_rd_addr == ID_rs1_addr) ||
         (ID_EX_rd_addr == ID_rs2_addr));


    always @(*) begin
        Stall = ld_use_hazard || branch_load_hazard;

        IF_Flush = EX_Jump || (EX_Branch && EX_Branch_Taken);

        if (EX_MEM_RegWrite && (EX_MEM_rd_addr != 5'b0) && (EX_MEM_rd_addr == EX_rs1_addr))
            ForwardA = 2'b10;
        else if (MEM_WB_RegWrite && (MEM_WB_rd_addr != 5'b0) && (MEM_WB_rd_addr == EX_rs1_addr))
            ForwardA = 2'b01;
        else
            ForwardA = 2'b00;

        if (ID_EX_MemWrite) begin
            ForwardB = 2'b00;
        end else if (EX_MEM_RegWrite && (EX_MEM_rd_addr != 5'b0) && (EX_MEM_rd_addr == EX_rs2_addr))
            ForwardB = 2'b10;
        else if (MEM_WB_RegWrite && (MEM_WB_rd_addr != 5'b0) && (MEM_WB_rd_addr == EX_rs2_addr))
            ForwardB = 2'b01;
        else
            ForwardB = 2'b00;

        if (ID_EX_MemWrite) begin
            if (EX_MEM_RegWrite && (EX_MEM_rd_addr != 5'b0) && (EX_MEM_rd_addr == EX_rs2_addr))
                ForwardStore = 2'b10;
            else if (MEM_WB_RegWrite && (MEM_WB_rd_addr != 5'b0) && (MEM_WB_rd_addr == EX_rs2_addr))
                ForwardStore = 2'b01;
            else
                ForwardStore = 2'b00;
        end else begin
            ForwardStore = 2'b00;
        end
    end


endmodule

module Datapath (
    input         CLK,
    input         RSTN,
    output        IREQ,
    output [29:0] IADDR,
    input  [31:0] INSTR,
    output        DREQ,
    output [1:0]  DRW,
    output [29:0] DADDR,
    output [31:0] DWDATA,
    input  [31:0] DRDATA,

    input  [2:0]  ImmType,
    input  [3:0]  ALUOp,
    input         ALUSrc,
    input         RegWrite_ID,
    input         MemRead_ID,
    input         MemWrite_ID,
    input  [1:0]  MemtoReg_ID,
    input         Branch_ID,
    input         Jump_ID,
    input         IP_MemRead_ID,
    input         IP_MemWrite_ID,
    output [4:0]  Opcode,

    input         IF_Flush,
    input         Stall,
    input  [1:0]  ForwardA,
    input  [1:0]  ForwardB,
    input  [1:0]  ForwardStore,
    output        EX_MemRead,
    output        EX_MemWrite,
    output        EX_RegWrite,
    output        MEM_RegWrite,
    output        WB_RegWrite,
    output        EX_Branch,
    output        EX_Jump,
    output        EX_Branch_Taken_Result,
    output [31:0] EX_ALU_Result_Out,
    output [4:0]  ID_rs1_addr,
    output [4:0]  ID_rs2_addr,
    output [4:0]  ID_EX_rd_addr,
    output [4:0]  EX_MEM_rd_addr,
    output [4:0]  MEM_WB_rd_addr,
    output [4:0]  EX_rs1_out,
    output [4:0]  EX_rs2_out,

    output [4:0]  GPR_ReadAddr1,
    output [4:0]  GPR_ReadAddr2,
    output        GPR_WriteEn,
    output [4:0]  GPR_WriteAddr,
    output [31:0] GPR_WriteData,
    input  [31:0] GPR_ReadData1,
    input  [31:0] GPR_ReadData2
);



    parameter [2:0] IMM_R  = 3'b000,
                    IMM_I  = 3'b001,
                    IMM_LD = 3'b010,
                    IMM_ST = 3'b011,
                    IMM_J  = 3'b100,
                    IMM_IP = 3'b101;

    reg first_cycle_done;
    wire [31:0] w_NextPC;

    // IF stage
    reg  [31:0] PC;
    wire [31:0] PC_plus_4;

    wire Branch_Taken_Signal = EX_Branch & EX_Branch_Taken_Result;
    wire Redirect_In = EX_Jump || Branch_Taken_Signal;

    always @(posedge CLK or negedge RSTN) begin
        if (!RSTN) begin
            PC         <= 32'h0000_0000;
    
        end else begin
            
            PC <= w_NextPC; 
        end
    end


    adder pc_plus_4_adder (
        .a (PC),
        .b (32'd4),
        .y (PC_plus_4)
    );


    // IF/ID pipeline
    wire [31:0] IF_ID_INSTR;
    wire [31:0] IF_ID_PC_plus_4;

    always @(posedge CLK or negedge RSTN) begin
        if (!RSTN) first_cycle_done <= 0;
        else first_cycle_done <= 1;
    end

    wire IFID_stall = Stall | (!first_cycle_done);




    flopr #(32) if_id_instr_reg (
        .clk   (CLK),
        .RSTN  (RSTN),
        .stall (IFID_stall),
        .d     (IF_Flush ? 32'b0 : INSTR),
        .q     (IF_ID_INSTR)
    );


    flopr #(32) if_id_pc_plus_4_reg (
        .clk   (CLK),
        .RSTN  (RSTN),
        .stall (Stall),
        .d     (PC_plus_4),
        .q     (IF_ID_PC_plus_4)
    );


    // ID stage
    assign Opcode = IF_ID_INSTR[31:27];


    wire [4:0] ID_ra      = IF_ID_INSTR[26:22];
    wire [4:0] ID_rb      = IF_ID_INSTR[21:17];
    wire [4:0] ID_rc      = IF_ID_INSTR[16:12];
    wire [4:0] ID_Shamt_i = IF_ID_INSTR[4:0];
    wire       ID_i_bit   = IF_ID_INSTR[5];
    wire [2:0] ID_Cond    = IF_ID_INSTR[2:0];


    wire [31:0] ID_Imm_Out;
    ImmGen u_ImmGen (
        .INSTR    (IF_ID_INSTR),
        .ImmType  (ImmType),
        .Immediate(ID_Imm_Out)
    );


    wire [4:0] ID_GPR_ReadAddr2 = (MemWrite_ID) ? ID_ra : ID_rc;


    assign GPR_ReadAddr1 = ID_rb;
    assign GPR_ReadAddr2 = ID_GPR_ReadAddr2;
    assign ID_rs1_addr   = ID_rb;
    assign ID_rs2_addr   = ID_GPR_ReadAddr2;


    // ID/EX pipeline regs
    wire [31:0] ID_EX_PC_plus_4;
    wire [31:0] ID_EX_ReadData1;
    wire [31:0] ID_EX_ReadData2;
    wire [31:0] ID_EX_Immediate;
    wire [4:0]  ID_EX_rb;
    wire [4:0]  ID_EX_rs2_addr_pipelined;
    wire [4:0]  ID_EX_rc;
    wire [4:0]  ID_EX_Shamt_i;
    wire        ID_EX_i_bit;
    wire [2:0]  ID_EX_Cond;
    wire        ID_EX_ALUSrc;
    wire [3:0]  ID_EX_ALUOp;
    wire [2:0]  ID_EX_ImmType;
    wire [1:0]  ID_EX_MemtoReg;
    wire        EX_IP_MemRead;
    wire        EX_IP_MemWrite;

    wire [31:0] WB_Data_to_GPR;
    wire [31:0] ID_rs1_val;
    wire [31:0] ID_rs2_val;


    flopr #(32) id_ex_pc_plus_4_reg ( .clk(CLK), .RSTN(RSTN), .stall(Stall), .d(IF_ID_PC_plus_4), .q(ID_EX_PC_plus_4) );
    flopr #(32) id_ex_readdata1_reg ( .clk(CLK), .RSTN(RSTN), .stall(Stall), .d(ID_rs1_val), .q(ID_EX_ReadData1) );
    flopr #(32) id_ex_readdata2_reg ( .clk(CLK), .RSTN(RSTN), .stall(Stall), .d(ID_rs2_val), .q(ID_EX_ReadData2) );

    flopr #(32) id_ex_immediate_reg ( .clk(CLK), .RSTN(RSTN), .stall(Stall), .d(ID_Imm_Out),   .q(ID_EX_Immediate) );


    flopr #(5)  id_ex_ra_reg         ( .clk(CLK), .RSTN(RSTN), .stall(Stall), .d(ID_ra),           .q(ID_EX_rd_addr) );
    flopr #(5)  id_ex_rb_reg         ( .clk(CLK), .RSTN(RSTN), .stall(Stall), .d(ID_rb),           .q(ID_EX_rb) );
    flopr #(5)  id_ex_rs2_addr_reg   ( .clk(CLK), .RSTN(RSTN), .stall(Stall), .d(ID_GPR_ReadAddr2),.q(ID_EX_rs2_addr_pipelined) );
    flopr #(5)  id_ex_rc_reg         ( .clk(CLK), .RSTN(RSTN), .stall(Stall), .d(ID_rc),           .q(ID_EX_rc) );
    flopr #(5)  id_ex_shamt_reg      ( .clk(CLK), .RSTN(RSTN), .stall(Stall), .d(ID_Shamt_i),      .q(ID_EX_Shamt_i) );
    flopr #(1)  id_ex_i_bit_reg      ( .clk(CLK), .RSTN(RSTN), .stall(Stall), .d(ID_i_bit),        .q(ID_EX_i_bit) );
    flopr #(3)  id_ex_cond_reg       ( .clk(CLK), .RSTN(RSTN), .stall(Stall), .d(ID_Cond),         .q(ID_EX_Cond) );


    // Bubble inject on stall only (Delay Slot should NOT be flushed)
    wire Bubble_Inject = Stall;


    flopr #(1) id_ex_alusrc_reg (
        .clk   (CLK), .RSTN(RSTN), .stall(1'b0),
        .d     (Bubble_Inject ? 1'b0 : ALUSrc),
        .q     (ID_EX_ALUSrc)
    );


    flopr #(1) id_ex_branch_reg (
        .clk   (CLK), .RSTN(RSTN), .stall(1'b0),
        .d     (Bubble_Inject ? 1'b0 : Branch_ID),
        .q     (EX_Branch)
    );


    flopr #(1) id_ex_jump_reg (
        .clk   (CLK), .RSTN(RSTN), .stall(1'b0),
        .d     (Bubble_Inject ? 1'b0 : Jump_ID),
        .q     (EX_Jump)
    );


    flopr #(1) id_ex_memread_reg (
        .clk   (CLK), .RSTN(RSTN), .stall(1'b0),
        .d     (Bubble_Inject ? 1'b0 : MemRead_ID),
        .q     (EX_MemRead)
    );


    flopr #(1) id_ex_memwrite_reg (
        .clk   (CLK), .RSTN(RSTN), .stall(1'b0),
        .d     (Bubble_Inject ? 1'b0 : MemWrite_ID),
        .q     (EX_MemWrite)
    );


    flopr #(1) id_ex_regwrite_reg (
        .clk   (CLK), .RSTN(RSTN), .stall(1'b0),
        .d     (Bubble_Inject ? 1'b0 : RegWrite_ID),
        .q     (EX_RegWrite)
    );


    flopr #(4) id_ex_aluop_reg (
        .clk   (CLK), .RSTN(RSTN), .stall(1'b0),
        .d     (Bubble_Inject ? 4'b0000 : ALUOp),
        .q     (ID_EX_ALUOp)
    );


    flopr #(2) id_ex_memtoreg_reg (
        .clk   (CLK), .RSTN(RSTN), .stall(1'b0),
        .d     (Bubble_Inject ? 2'b00 : MemtoReg_ID),
        .q     (ID_EX_MemtoReg)
    );


    flopr #(3) id_ex_immtype_reg (
        .clk   (CLK), .RSTN(RSTN), .stall(1'b0),
        .d     (Bubble_Inject ? 3'b000 : ImmType),
        .q     (ID_EX_ImmType)
    );


    flopr #(1) id_ex_ip_memread_reg (
        .clk   (CLK), .RSTN(RSTN), .stall(1'b0),
        .d     (Bubble_Inject ? 1'b0 : IP_MemRead_ID),
        .q     (EX_IP_MemRead)
    );


    flopr #(1) id_ex_ip_memwrite_reg (
        .clk   (CLK), .RSTN(RSTN), .stall(1'b0),
        .d     (Bubble_Inject ? 1'b0 : IP_MemWrite_ID),
        .q     (EX_IP_MemWrite)
    );


    // EX stage
    wire [31:0] EX_ALU_Input_A_Pre_Fwd;
    wire [31:0] EX_ALU_Input_B_Pre_Fwd;
    wire [31:0] EX_StoreData_Pre_Fwd = ID_EX_ReadData2;
    wire [31:0] EX_StoreData;


    wire is_J_Type     = EX_Jump | (ID_EX_ImmType == IMM_J);
    wire is_LD_ST_Type = (ID_EX_ImmType == IMM_LD) | (ID_EX_ImmType == IMM_ST);
    wire is_Abs_Addr   = is_LD_ST_Type & (ID_EX_rb == 5'b11111);
    wire is_IP_Type    = (ID_EX_ImmType == IMM_IP);


    wire [1:0] ALU_A_Sel =
        (is_J_Type)               ? 2'b10 :
        (is_Abs_Addr | is_IP_Type)? 2'b01 :
                                     2'b00;


    mux3 alu_a_mux (
        .d00 (ID_EX_ReadData1),
        .d01 (32'b0),
        .d10 (ID_EX_PC_plus_4),
        .s   (ALU_A_Sel),
        .y   (EX_ALU_Input_A_Pre_Fwd)
    );


    mux2 alu_src_mux (
        .d0 (ID_EX_ReadData2),
        .d1 (ID_EX_Immediate),
        .s  (ID_EX_ALUSrc),
        .y  (EX_ALU_Input_B_Pre_Fwd)
    );


    wire [31:0] EX_ALU_Input_A;
    wire [31:0] EX_ALU_Input_B;
    wire [31:0] EX_MEM_ALU_Result;
    wire [31:0] GPR_WriteData_Out;


    mux3 fwd_a_mux (
        .d00 (EX_ALU_Input_A_Pre_Fwd),
        .d01 (WB_Data_to_GPR),
        .d10 (EX_MEM_ALU_Result),
        .s   (ForwardA),
        .y   (EX_ALU_Input_A)
    );


    mux3 fwd_b_mux (
        .d00 (EX_ALU_Input_B_Pre_Fwd),
        .d01 (WB_Data_to_GPR),
        .d10 (EX_MEM_ALU_Result),
        .s   (ForwardB),
        .y   (EX_ALU_Input_B)
    );


    mux3 fwd_store_mux (
        .d00 (EX_StoreData_Pre_Fwd),
        .d01 (WB_Data_to_GPR),
        .d10 (EX_MEM_ALU_Result),
        .s   (ForwardStore),
        .y   (EX_StoreData)
    );


    wire [31:0] ALU_Result_Internal;
    wire        BranchTaken_Internal;


    ALU u_ALU (
        .A         (EX_ALU_Input_A),
        .B         (EX_ALU_Input_B),
        .ALUOp     (ID_EX_ALUOp),
        .Shamt_i   (ID_EX_Shamt_i),
        .Shamt_r   (ID_EX_ReadData2[4:0]),
        .i_bit     (ID_EX_i_bit),
        .Cond      (ID_EX_Cond),
        .Result    (ALU_Result_Internal),
        .BranchTaken(BranchTaken_Internal)
    );


    assign EX_ALU_Result_Out      = ALU_Result_Internal;
    assign EX_Branch_Taken_Result = BranchTaken_Internal;


    // EX/MEM pipeline
    wire [31:0] EX_MEM_WriteData;
    wire [31:0] EX_MEM_PC_plus_4;
    wire        MEM_Read_Internal;
    wire        MEM_Write_Internal;
    wire [1:0]  MEM_MemtoReg_Internal;
    wire        IP_Read_Internal;
    wire        IP_Write_Internal;


    flopr #(32) ex_mem_alu_result_reg ( .clk(CLK), .RSTN(RSTN), .stall(1'b0), .d(EX_ALU_Result_Out), .q(EX_MEM_ALU_Result) );
    flopr #(32) ex_mem_writedata_reg  ( .clk(CLK), .RSTN(RSTN), .stall(1'b0), .d(EX_StoreData),      .q(EX_MEM_WriteData) );
    flopr #(5)  ex_mem_ra_reg         ( .clk(CLK), .RSTN(RSTN), .stall(1'b0), .d(ID_EX_rd_addr),     .q(EX_MEM_rd_addr) );
    flopr #(32) ex_mem_pc_plus_4_reg  ( .clk(CLK), .RSTN(RSTN), .stall(1'b0), .d(ID_EX_PC_plus_4),   .q(EX_MEM_PC_plus_4) );
    flopr #(1)  ex_mem_memread_reg    ( .clk(CLK), .RSTN(RSTN), .stall(1'b0), .d(EX_MemRead),        .q(MEM_Read_Internal) );
    flopr #(1)  ex_mem_memwrite_reg   ( .clk(CLK), .RSTN(RSTN), .stall(1'b0), .d(EX_MemWrite),       .q(MEM_Write_Internal) );
    flopr #(1)  ex_mem_regwrite_reg   ( .clk(CLK), .RSTN(RSTN), .stall(1'b0), .d(EX_RegWrite),       .q(MEM_RegWrite) );
    flopr #(2)  ex_mem_memtoreg_reg   ( .clk(CLK), .RSTN(RSTN), .stall(1'b0), .d(ID_EX_MemtoReg),    .q(MEM_MemtoReg_Internal) );
    flopr #(1)  ex_mem_ip_memread_reg ( .clk(CLK), .RSTN(RSTN), .stall(1'b0), .d(EX_IP_MemRead),     .q(IP_Read_Internal) );
    flopr #(1)  ex_mem_ip_memwrite_reg ( .clk(CLK), .RSTN(RSTN), .stall(1'b0), .d(EX_IP_MemWrite),    .q(IP_Write_Internal) );

    // MEM

    
    assign DADDR  = EX_ALU_Result_Out[29:0];
    assign DWDATA = EX_StoreData;
    

   


     // EX 스테이지 신호 사용 
    wire ex_ip_read    = EX_IP_MemRead;   // LDIP
    wire ex_ip_write   = EX_IP_MemWrite;  // STIP
    wire ex_risc_read  = EX_MemRead;      // LD, LDR
    wire ex_risc_write = EX_MemWrite;     // ST, STR
    assign DREQ = ex_ip_read | ex_ip_write | ex_risc_read | ex_risc_write;
    assign DRW = ex_ip_write   ? 2'b01 :  // STIP
                 ex_ip_read    ? 2'b11 :  // LDIP
                 ex_risc_write ? 2'b00 :  // ST, STR
                 ex_risc_read  ? 2'b10 :  // LD, LDR
                                2'b10;   // default


    // MEM/WB pipeline
    wire [31:0] MEM_WB_ReadData;
    wire [31:0] MEM_WB_ALU_Result;
    wire [31:0] MEM_WB_PC_plus_4;
    wire [1:0]  WB_MemtoReg_Internal;
    wire        WB_RegWrite_Signal;

    wire [4:0]  WB_rd_addr;

    assign ID_rs1_val =
        (WB_RegWrite_Signal && (WB_rd_addr != 5'd0) && (WB_rd_addr == ID_rs1_addr)) ?
            WB_Data_to_GPR :
            GPR_ReadData1;

    assign ID_rs2_val =
        (WB_RegWrite_Signal && (WB_rd_addr != 5'd0) && (WB_rd_addr == ID_rs2_addr)) ?
            WB_Data_to_GPR :
            GPR_ReadData2;


    assign MEM_WB_rd_addr = WB_rd_addr;


    flopr #(32) mem_wb_readdata_reg   ( .clk(CLK), .RSTN(RSTN), .stall(1'b0), .d(DRDATA),          .q(MEM_WB_ReadData) );
    flopr #(32) mem_wb_alu_result_reg ( .clk(CLK),  .RSTN(RSTN), .stall(1'b0), .d(EX_MEM_ALU_Result),.q(MEM_WB_ALU_Result) );
    flopr #(5)  mem_wb_ra_reg         ( .clk(CLK),  .RSTN(RSTN), .stall(1'b0), .d(EX_MEM_rd_addr),  .q(WB_rd_addr) );
    flopr #(32) mem_wb_pc_plus_4_reg  ( .clk(CLK),  .RSTN(RSTN), .stall(1'b0), .d(EX_MEM_PC_plus_4),.q(MEM_WB_PC_plus_4) );
    flopr #(1)  mem_wb_regwrite_reg   ( .clk(CLK),  .RSTN(RSTN), .stall(1'b0), .d(MEM_RegWrite),    .q(WB_RegWrite_Signal) );
    flopr #(2)  mem_wb_memtoreg_reg   ( .clk(CLK),  .RSTN(RSTN), .stall(1'b0), .d(MEM_MemtoReg_Internal), .q(WB_MemtoReg_Internal) );


    assign WB_RegWrite = WB_RegWrite_Signal;


    // WB
    mux3 wb_mux (
        .d00 (MEM_WB_ALU_Result),
        .d01 (MEM_WB_ReadData),
        .d10 (MEM_WB_PC_plus_4),
        .s   (WB_MemtoReg_Internal),
        .y   (WB_Data_to_GPR)
    );

    assign GPR_WriteEn   = WB_RegWrite_Signal;
    assign GPR_WriteAddr = WB_rd_addr;
    assign GPR_WriteData = WB_Data_to_GPR;
 

    assign IREQ  = !Stall;





    assign w_NextPC = (!RSTN) ? 32'd0 :
                    (Stall || !first_cycle_done) ? PC :
                    (Redirect_In) ? EX_ALU_Result_Out : 
                    PC_plus_4;
    
    assign IADDR = w_NextPC[29:0];




    assign EX_rs1_out = ID_EX_rb;
    assign EX_rs2_out = ID_EX_rs2_addr_pipelined;


endmodule



