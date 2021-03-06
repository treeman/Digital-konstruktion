
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Microcontroller is
    Port(
        -- Our clock
        clk : in std_logic;

        -- Asynced reset
        reset_a : in std_logic;

        -- Buss input
        buss_in : in std_logic_vector(7 downto 0);

        uCount_limit : in std_logic_vector(7 downto 0);

        -- Control codes
        PC_code : out std_logic_vector(1 downto 0);

        buss_code : out std_logic_vector(2 downto 0);

        ALU_code : out std_logic_vector(2 downto 0);
        ALU1_code : out std_logic_vector(1 downto 0);
        ALU2_code : out std_logic;

        memory_addr_code : out std_logic_vector(2 downto 0);

        memory1_write : out std_logic;
        memory2_write : out std_logic;
        memory3_write : out std_logic;

        memory1_read : out std_logic;
        memory2_read : out std_logic;
        memory3_read : out std_logic;

        OP_code : out std_logic;
        M1_code : out std_logic_vector(1 downto 0);
        M2_code : out std_logic_vector(1 downto 0);

        ADR1_code : out std_logic_vector(1 downto 0);
        ADR2_code : out std_logic_vector(1 downto 0);

        FIFO_code : out std_logic_vector(1 downto 0);

        game_code : out std_logic_vector(1 downto 0);

        -- Status signals
        Z : in std_logic;
        N : in std_logic;
        both_Z : in std_logic;

        new_IN : in std_logic;
        game_started : in std_logic;
        shall_load : in std_logic;
        game_over : in std_logic;

        current_instr : out std_logic_vector(3 downto 0)
    );
end Microcontroller;

architecture Behavioral of Microcontroller is

    -- Microcode lives here
    subtype DataLine is std_logic_vector(46 downto 0);
    type Data is array (0 to 255) of DataLine;

    -- game FIFO IR ADR1 ADR2 OP M1 M2 mem1 mem2 mem3 mem_addr ALU1 ALU2 ALU buss PC  uPC  uPC_addr
    --  00   00  0   00  00   0  00 00  00   00   00    000     00   0   000 000  00 00000 00000000
    signal mem : Data := (
        -- Startup, check if we're in game
        "00000000000000000000000000000000000011000110011", -- jmpS GAME(33)
        "00000000000000000000000000000000000101000000001", -- jmpO +0(01)

        -- Clear memory contents
        "00000000000000000000000000110000000000000000000", -- ALU = 0
        "00000000010101000000000000000100010000000000000", -- ALU1 -> buss, buss -> OP, buss -> M1, buss -> M2, buss -> PC
        "00000000000000000000110000000000000000000000000", -- PC -> mem_addr
        "00000000000000101010000000000000000000000000000", -- OP -> mem, M1 -> mem, M2 -> mem
        "00000000000000000000000000100000000000000000000", -- ALU++
        "00000000000000000000000000000100010001100001001", -- ALU1 -> buss, buss -> PC, jmpZ LOADP(09)
        "00000000000000000000000000000000000001000000100", -- jmp CLRMEM(04)
        --"00000000000000000000000000000000000000000000000", -- nothing, skip clearing memory

        "11000000000000000000000000000000000001000001011", -- shall_load, jmp POLL(0b)
        "00000000000000000000000000000000000001000001001", -- jmp -1(09)

        -- Load in program to memory
        "00000000000000000000000000000110000000000000000", -- IN -> buss

        -- Load program 1
        "00110000000000000000000000110000000000000000000", -- ALU = 0, fifo_next
        "00010000000000000000000000000100010000000000000", -- ALU1 -> buss, buss -> FIFO, buss -> PC

        "00000000000000000000000000000000000010000010000", -- jmpIN F1NUM(10)
        "00000000000000000000000000000000000001000001110", -- jmp -1(0e)
        "00000000000000000000000010001110000000000000000", -- IN -> buss, buss -> ALU1
        "00000000000000000000000000000000000010000010011", -- jmpIN F1OP(13)
        "00000000000000000000000000000000000001000010001", -- jmp -1(11)
        "00000000010000000000000000000110000000000000000", -- IN -> buss, buss -> OP
        "00000000000000000000000000000000000010000010110", -- jmpIN F1M1(16)
        "00000000000000000000000000000000000001000010100", -- jmp -1(14)
        "00000000000100000000000000000110000000000000000", -- IN -> buss, buss -> M1
        "00000000000000000000000000000000000010000011001", -- jmpIN F1M2(19)
        "00000000000000000000000000000000000001000010111", -- jmp -1(17)
        "00000000000001000000110000000110000000000000000", -- IN -> buss, buss -> M2, PC -> mem_addr
        "00000000000000101010000000000000000000000000000", -- OP -> mem, M1 -> mem, M2 -> mem
        "00000000000000000000000000101000100000000000000", -- ALU--, PC++
        "00000000000000000000000000000000000001100011110", -- jmpZ LOAD2(1e)
        "00000000000000000000000000000000000001000010001", -- jmp F1ROW(11)

        -- Load program 2
        "00100000000000000000000000000000000000000000000", -- change_player
        "00000000000000000000000000000000000010000100001", -- jmpIN F2PC(21)
        "00000000000000000000000000000000000001000011111", -- jmp -1(1f)
        "00010000000000000000000000000110010000000000000", -- IN -> buss, buss -> FIFO, buss -> PC
        "00000000000000000000000000000000000010000100100", -- jmpIN F2NUM(24)
        "00000000000000000000000000000000000001000100010", -- jmp -1(22)
        "00000000000000000000000010001110000000000000000", -- IN -> buss, buss -> ALU1
        "00000000000000000000000000000000000010000100111", -- jmpIN F2OP(27)
        "00000000000000000000000000000000000001000100101", -- jmp -1(25)
        "00000000010000000000000000000110000000000000000", -- IN -> buss, buss -> OP
        "00000000000000000000000000000000000010000101010", -- jmpIN F2M1(2a)
        "00000000000000000000000000000000000001000101000", -- jmp -1(28)
        "00000000000100000000000000000110000000000000000", -- IN -> buss, buss -> M1
        "00000000000000000000000000000000000010000101101", -- jmpIN F2M2(2d)
        "00000000000000000000000000000000000001000101011", -- jmp -1(2b)
        "00000000000001000000110000000110000000000000000", -- IN -> buss, buss -> M2, PC -> mem_addr
        "00000000000000101010000000000000000000000000000", -- OP -> mem, M1 -> mem, M2 -> mem
        "00000000000000000000000000101000100000000000000", -- ALU--, PC++
        "00000000000000000000000000000000000001100110010", -- jmpZ LEND(32)
        "00000000000000000000000000000000000001000100101", -- jmp F2ROW(25)
        "01000000000000000000000000000000000001100000000", -- game_started, jmpZ 0(00)


        -- Game sequence
        "00100000000000000000000000000000000000000000000", -- change_player
        "00110000000000000000000000000000000000000000000", -- fifo_next
        "00000000000000000000000000000101010000000000000", -- FIFO -> buss, buss -> PC
        "00000000000000000000110000000000000000000000000", -- PC -> mem_addr
        "00000000000000010101000000000000000000000000000", -- mem -> OP, mem -> M1, mem -> M2
        "00001000000000000000000000000001000001000111001", -- OP -> buss, buss -> IR, jmp AMOD(39)

        -- Calculate adress mode for A operand
        "00000000000000000000000000000000001000001001010", -- jmpAimm BMOD(4a)
        "00000000000000000000000000001000000000000000000", -- M1 -> ALU1
        "00000000000000000000000010010000000000000000000", -- ALU1 += PC
        "00000000001000000000000000000000000000000000000", -- ALU1 -> M1
        "00000000000000000000000000000000001000101001010", -- jmpAdir BMOD(4a)
        "00000000000000000000001000000010000000000000000", -- M1 -> buss, buss -> mem_addr
        "00000000000000000001000000000000000000000000000", -- mem -> M2
        "00000000000100000000000000000011001001001000101", -- M2 -> buss, buss -> M1, jmpApre APRE(45)
        "00000000000000000000000000001000000000000000000", -- M1 -> ALU1
        "00000000000000000000000110010000000000000000000", -- ALU1 += mem_addr
        "00000000001000000000000000000000000000000000000", -- ALU1 -> M1
        "00000000000000000000000000000000000001001001010", -- jmp BMOD(4a)

        "00000000000000000000000000001000000000000000000", -- M1 -> ALU1
        "00000000000000000000000000101000000000000000000", -- ALU--
        "00000000001010000000000000000000000000000000000", -- ALU1 -> M1, ALU1 -> M2
        "00000000000000000010000000000000000000000000000", -- M2 -> mem
        "00000000000000000000000000000000000001001000001", -- jmp AOFF(41)

        -- Calculate adress mode for B operand
        "00000000000000000000110000000000000000000000000", -- PC -> mem_addr
        "00000000000000000001000000000000000000000000000", -- mem -> M2
        "00000000000000000000000000000000001001101011101", -- jmpBimm INSTR(5d)
        "00000000000000000000000100001000000000000000000", -- M2 -> ALU1
        "00000000000000000000000010010000000000000000000", -- ALU1 += PC
        "00000000000010000000000000000000000000000000000", -- ALU1 -> M2
        "00000000000000000000000000000000001010001011101", -- jmpBdir INSTR(5d)
        "00000000000000000000001000000011000000000000000", -- M2 -> buss, buss -> mem_addr
        "00000000000000000001000000000000000000000000000", -- mem -> M2
        "00000000000000000000000000000000001010101011000", -- jmpBpre BPRE(58)
        "00000000000000000000000100001000000000000000000", -- M2 -> ALU1
        "00000000000000000000000110010000000000000000000", -- ALU1 += mem_addr
        "00000000000010000000000000000000000000000000000", -- ALU1 -> M2
        "00000000000000000000000000000000000001001011101", -- jmp INSTR(5d)

        "00000000000000000000000100001000000000000000000", -- M2 -> ALU1
        "00000000000000000000000000101000000000000000000", -- ALU--
        "00000000000010000000000000000000000000000000000", -- ALU1 -> M2
        "00000000000000000010000000000000000000000000000", -- M2 -> mem
        "00000000000000000000000000000000000001001010100", -- jmp BOFF(54)


        -- Load up instruction and proceed to instruction decoding
        -- A operand is now in ADR1 and B in ADR2
        -- If immediate ignore these, they're also in M1 and M2

        "00000101000000000000000000000000000000100000000", -- M1 -> ADR1, M2 -> ADR2, op_addr -> uPC


        -- Execute instruction
        --
        -- ADR1 is now the absolute address for the A operand
        -- ADR2 is for the B operand
        -- M1 and M2 holds copies of ADR1 and ADR2 always
        --
        -- If immediate, the data is instead in M1 or M2

        -- DAT  Executing data will eat up the PC
	"00000000000000000000000000000000000001011000001", -- jmp END(c1)

	-- MOV  Move A to B
	"00000000000000000000000000000000001000001100101", -- jmpAimm IMOV(65)
	"00000000000000000000100000000000000000000000000", -- ADR1 -> mem_addr
	"00000000000000010101000000000000000000000000000", -- mem -> OP, mem -> M1, mem -> M2
	"00000000000000000000101000000000000000000000000", -- ADR2 -> mem_addr
	"00000000000000101010000000000000000000000000000", -- OP -> mem, M1 -> mem, M2 -> mem
	"00000000000000000000000000000000000001010111111", -- jmp ADDPC(bf)

	-- If A immediate, move A to B op specified by B mem address
	"00000000000001000000101000000010000000000000000", -- ADR2 -> mem_addr, M1 -> buss, buss -> M2
	"00000000000000000010000000000000000000000000000", -- M2 -> mem
	"00000000000000000000000000000000000001010111111", -- jmp ADDPC(bf)

	-- ADD  Add A to B
	"00000000000000000000000000000000001000001110001", -- jmpAimm IADD(71)
	"00000000000000000000100000000000000000000000000", -- ADR1 -> mem_addr
	"00000000000000000101000000000000000000000000000", -- mem -> M1, mem -> M2
	"00000000000000000000101001001000000000000000000", -- ADR2 -> mem_addr, M1 -> ALU1, M2 -> ALU2
	"00000000000000000101000000000000000000000000000", -- mem -> M1, mem -> M2
	"00000000000000000000000001010000000000000000000", -- ALU1 += M1, ALU2 += M2
	"00000000001011000000000000000000000000000000000", -- ALU1 -> M1, ALU2 -> M2
	"00000000000000001010000000000000000000000000000", -- M1 -> mem, M2 -> mem
	"00000000000000000000000000000000000001010111111", -- jmp ADDPC(bf)

	"00000000000000000000101000000000000000000000000", -- ADR2 -> mem_addr
	"00000000000000000001000000001000000000000000000", -- M1 -> ALU1, mem -> M2
	"00000000000000000000000100010000000000000000000", -- ALU1 += M2
	"00000000000010000000000000000000000000000000000", -- ALU1 -> M2
	"00000000000000000010000000000000000000000000000", -- M2 -> mem
	"00000000000000000000000000000000000001010111111", -- jmp ADDPC(bf)

	-- SUB  Sub A from B
	"00000000000000000000000000000000001000010000000", -- jmpAimm ISUB(80)
	"00000000000000000000101000000000000000000000000", -- ADR2 -> mem_addr
	"00000000000000000101000000000000000000000000000", -- mem -> M1, mem -> M2
	"00000000000000000000100001001000000000000000000", -- ADR1 -> mem_addr, M1 -> ALU1, M2 -> ALU2
	"00000000000000000101000000000000000000000000000", -- mem -> M1, mem -> M2
	"00000000000000000000000001011000000000000000000", -- ALU1 -= M1, ALU2 -= M2
	"00000000001011000000101000000000000000000000000", -- ALU1 -> M1, ALU2 -> M2, ADR2 -> mem_addr
	"00000000000000001010000000000000000000000000000", -- M1 -> mem, M2 -> mem
	"00000000000000000000000000000000000001010111111", -- jmp ADDPC(bf)

	"00000000000000000000101000000000000000000000000", -- ADR2 -> mem_addr
	"00000000000000000001000000000000000000000000000", -- mem -> M2
	"00000000000000000000000100001000000000000000000", -- M2 -> ALU1
	"00000000000000000000000000011000000000000000000", -- ALU1 -= M1
	"00000000000010000000000000000000000000000000000", -- ALU1 -> M2
	"00000000000000000010000000000000000000000000000", -- M2 -> mem
	"00000000000000000000000000000000000001010111111", -- jmp ADDPC(bf)

	-- JMP  Jump to A
	"00010000000000000000000000000010000001011000001", -- M1 -> buss, buss -> FIFO, jmp END(c1)

	-- JMPZ Jump to A if B zero
	"00000000000000000000000000000000001001110001011", -- jmpBimm IJMPZ(8b)
	"00000000000000000000101000000000000000000000000", -- ADR2 -> mem_addr
	"00000000000000000001000000000000000000000000000", -- mem -> M2
	"00000000000000000000000100001000000000000000000", -- M2 -> ALU1
	"00000000000000000000000000000000000001110001110", -- jmpZ DOJMPZ(8e)
	"00000000000000000000000000000000000001010111111", -- jmp ADDPC(bf)
	"00000000000000000000000000000000000001010000111", -- jmp JMP(87)

	-- JMPN Jump to A if B non-zero
	"00000000000000000000000000000000001001110010010", -- jmpBimm IJMPN(92)
	"00000000000000000000101000000000000000000000000", -- ADR2 -> mem_addr
	"00000000000000000001000000000000000000000000000", -- mem -> M2
	"00000000000000000000000100001000000000000000000", -- M2 -> ALU1
	"00000000000000000000000000000000000001110111111", -- jmpZ ADDPC(bf)
	"00000000000000000000000000000000000001010000111", -- jmp JMP(87)

	-- CMP If A eq B skip next instr
	"00000000000000000000000000000000001000010100010", -- jmpAimm ICMP(a2)
	"00000000000000000000101000000000000000000000000", -- ADR2 -> mem_addr
	"00000000000000010101000000000000000000000000000", -- mem -> OP, mem -> M1, mem -> M2
	"00000000000000000000100001001000000000000000000", -- ADR1 -> mem_addr, M1 -> ALU1, M2 -> ALU2
	"00000000000000000101000000000000000000000000000", -- mem -> M1, mem -> M2
	"00000000000000000000000001011000000000000000000", -- ALU1 -= M1, ALU2 -= M2
	"00000000000000000000000000000000000100010011101", -- jmpE CMPOP(9d)
	"00000000000000000000000000000000000001010111111", -- jmp ADDPC(bf)

	"00000000000000000000000010001001000000000000000", -- OP -> buss, buss -> ALU1
	"00000000000000010000000000000000000000000000000", -- mem -> OP
	"00000000000000000000000010011001000000000000000", -- ALU1 -= OP
	"00000000000000000000000000000000000001110111110", -- jmpZ SKIP(be)
	"00000000000000000000000000000000000001010111111", -- jmp ADDPC(bf)

	"00000000000000000000101000000000000000000000000", -- ADR2 -> mem_addr
	"00000000000000000001000000001000000000000000000", -- mem -> M2, M1 -> ALU1
	"00000000000000000000000100011000000000000000000", -- ALU1 -= M2
	"00000000000000000000000000000000000001110111110", -- jmpZ SKIP(be)
	"00000000000000000000000000000000000001010111111", -- jmp ADDPC(bf)

	-- SLT if A is less than B skip next instr
	"00000000000000000000000000000000001000010110000", -- jmpAimm ISLT(b0)
	"00000000000000000000100000000000000000000000000", -- ADR1 -> mem_addr
	"00000000000000000001000000000000000000000000000", -- mem -> M2
	"00000000000000000000000100001000000000000000000", -- M2 -> ALU1
	"00000000000000000000101000000000000000000000000", -- ADR2 -> mem_addr
	"00000000000000000001000000000000000000000000000", -- mem -> M2
	"00000000000000000000000100011000000000000000000", -- ALU1 -= M2
	"00000000000000000000000000000000000011110111110", -- jmpN SKIP(be)
	"00000000000000000000000000000000000001010111111", -- jmp ADDPC(bf)

	"00000000000000000000000000001000000001010101011", -- M1 -> ALU1, jmp SLTCMP(ab)

	-- DJN Decr B, if not zero jmp to A
	"00000000000000000000000000000000001001110111010", -- jmpBimm IDJN(ba)
	"00000000000000000000101000000000000000000000000", -- ADR2 -> mem_addr
	"00000000000000000001000000000000000000000000000", -- mem -> M2
	"00000000000000000000000100001000000000000000000", -- M2 -> ALU1
	"00000000000000000000000000101000000000000000000", -- ALU--
	"00000000000010000000000000000000000000000000000", -- ALU1 -> M2
	"00000000000000000010000000000000000000000000000", -- M2 -> mem
	"00000000000000000000000000000000000001110111111", -- jmpZ ADDPC(bf)
	"00010000000000000000000000000010000001011000001", -- M1 -> buss, buss -> FIFO, jmp END(c1)

	"00000000000000000000110100001000000001010110100", -- M2 -> ALU1, PC -> mem_addr, jmp DODJN(b4)


	-- SPL Place A in process queue
	"00000000000000000000000000000000100000000000000", -- PC++
	"00010000000000000000000000000000000000000000000", -- PC -> buss, buss -> FIFO
	"00010000000000000000000000000010000001011000001", -- M1 -> buss, buss -> FIFO, jmp END(c1)


	"00000000000000000000000000000000100001010111111", -- PC++, jmp ADDPC(bf)

	-- Keep the PC for next round
	"00000000000000000000000000000000100000000000000", -- PC++
	"00010000000000000000000000000000000000000000000", -- PC -> buss, buss -> FIFO

	"10000000000000000000000000000000000000000000000", -- check_gameover
	"00000000000000000000000000000000000010100000000", -- jmpC 0(00)
	--"00000000000000000000000000000000001111100000000", -- uPC = 0
	"00000000000000000000000000000000000001011000010", -- jmp DELAY(c2)

        others => (others => '0')
    );

    -- Synced reset
    signal reset : std_logic;

    signal uCount_limit_sync : std_logic_vector(7 downto 0);

    -- Current microcode line to process
    signal signals : DataLine;

    -- Controll the behavior of next uPC value
    signal uPC_addr : std_logic_vector(7 downto 0);
    signal uPC_code : std_logic_vector(4 downto 0);

    signal IR_code : std_logic;

    signal uCounter : std_logic_vector(26 downto 0);

    -- Registers
    signal IR : std_logic_vector(7 downto 0);
    signal uPC : std_logic_vector(7 downto 0);

    -- Split up IR
    alias OP_field is IR(7 downto 4);
    alias A_field is IR(3 downto 2);
    alias B_field is IR(1 downto 0);

    -- Instruction code decodings
    signal op_addr : std_logic_vector(7 downto 0);
    signal A_imm : std_logic;
    signal A_dir : std_logic;
    signal A_pre : std_logic;
    signal B_imm : std_logic;
    signal B_dir : std_logic;
    signal B_pre : std_logic;
begin

    current_instr <= OP_field;

    -------------------------------------------------------------------------
    -- RETRIEVE SIGNALS
    -------------------------------------------------------------------------

    signals <= mem(conv_integer(uPC));

    uPC_addr <= signals(7 downto 0);
    uPC_code <= signals(12 downto 8);

    PC_code <= signals(14 downto 13);
    buss_code <= signals(17 downto 15);

    ALU_code <= signals(20 downto 18);
    ALU2_code <= signals(21);
    ALU1_code <= signals(23 downto 22);

    memory_addr_code <= signals(26 downto 24);

    memory3_read <= signals(27);
    memory3_write <= signals(28);

    memory2_read <= signals(29);
    memory2_write <= signals(30);

    memory1_read <= signals(31);
    memory1_write <= signals(32);

    M2_code <= signals(34 downto 33);
    M1_code <= signals(36 downto 35);
    OP_code <= signals(37);

    ADR2_code <= signals(39 downto 38);
    ADR1_code <= signals(41 downto 40);

    IR_code <= signals(42);
    FIFO_code <= signals(44 downto 43);

    game_code <= signals(46 downto 45);

    -------------------------------------------------------------------------
    -- ENCODINGS
    -------------------------------------------------------------------------

    -- OP code address decoding
    with OP_field select
        op_addr <=      "01011110" when "0000", -- DAT 5e
			"01011111" when "0001", -- MOV 5f
			"01101000" when "0010", -- ADD 68
			"01110111" when "0011", -- SUB 77
			"10000111" when "0100", -- JMP 87
			"10001000" when "0101", -- JMPZ 88
			"10001111" when "0110", -- JMPN 8f
			"10010101" when "0111", -- CMP 95
			"10100111" when "1000", -- SLT a7
			"10110001" when "1001", -- DJN b1
			"10111011" when "1010", -- SPL bb
			"11111111" when others;


    A_dir <= '1' when A_field = "00" else '0';
    A_imm <= '1' when A_field = "01" else '0';
    A_pre <= '1' when A_field = "11" else '0';

    B_dir <= '1' when B_field = "00" else '0';
    B_imm <= '1' when B_field = "01" else '0';
    B_pre <= '1' when B_field = "11" else '0';

    -------------------------------------------------------------------------
    -- ON CLOCK EVENT
    -------------------------------------------------------------------------

    process (clk)
    begin
        if rising_edge(clk) then

            if reset_a = '1' then
                reset <= '1';
            elsif reset = '1' then
                reset <= '0';
            end if;

        uCount_limit_sync <= uCount_limit;

            -------------------------------------------------------------------------
            -- SIGNAL MULTIPLEXERS
            -------------------------------------------------------------------------

            -- Update uPC
            if reset_a = '1' then
                uPC <= "00000000";
            elsif uPC_code = "00001" then
                uPC <= op_addr;
            elsif uPC_code = "00010" then
                uPC <= uPC_addr;
            elsif uPC_code = "00011" and Z = '1' then
                uPC <= uPC_addr;
            elsif uPC_code = "00100" and new_IN = '1' then
                uPC <= uPC_addr;
            --elsif uPC_code = "00101" and '0' & uCounter >= '0' & uCount_limit_sync & "0000011000000000000" then
            elsif uPC_code = "00101" and '0' & uCounter >= '0' 
		& uCount_limit_sync(7 downto 6) & "00" 
		& uCount_limit_sync(5 downto 4) & "00" 
		& uCount_limit_sync(3 downto 2) & "00" 
		& uCount_limit_sync(1 downto 0) & "00" 
		& "00000000000" then

                uPC <= uPC_addr;
            elsif uPC_code = "00110" and game_started = '1' then
                uPC <= uPC_addr;
            elsif uPC_code = "00111" and N = '1' then
                uPC <= uPC_addr;
            elsif uPC_code = "01000" and both_Z = '1' then
                uPC <= uPC_addr;
            -- elsif uPC_code = "01001" and  = '1' then
            elsif uPC_code = "01001" then -- Deprecated
                uPC <= uPC_addr;
            elsif uPC_code = "01010" and game_over = '1' then
                uPC <= uPC_addr;

            elsif uPC_code = "10000" and A_imm = '1' then
                uPC <= uPC_addr;
            elsif uPC_code = "10001" and A_dir = '1' then
                uPC <= uPC_addr;
            elsif uPC_code = "10010" and A_pre = '1' then
                uPC <= uPC_addr;
            elsif uPC_code = "10011" and B_imm = '1' then
                uPC <= uPC_addr;
            elsif uPC_code = "10100" and B_dir = '1' then
                uPC <= uPC_addr;
            elsif uPC_code = "10101" and B_pre = '1' then
                uPC <= uPC_addr;

            elsif uPC_code = "11111" then
                uPC <= "00000000";
            else
                uPC <= uPC + 1;
            end if;

            -- Update uCounter
            if reset_a = '1' then
                uCounter <= (others => '0');
            elsif uPC = "00000000" then
                uCounter <= (others => '0');
            else
                uCounter <= uCounter + 1;
            end if;

            if reset = '1' then
                IR <= "00000000";
            elsif IR_code = '1' then
                IR <= buss_in;
            end if;

        end if;
    end process;

end Behavioral;

