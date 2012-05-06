
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

        -- Status signals
        Z : in std_logic;
        N : in std_logic;
        both_Z : in std_logic;

        new_IN : in std_logic;
        game_started : in std_logic
    );
end Microcontroller;

architecture Behavioral of Microcontroller is

    -- Microcode lives here
    subtype DataLine is std_logic_vector(43 downto 0);
    type Data is array (0 to 255) of DataLine;

    -- FIFO IR ADR1 ADR2 OP M1 M2 mem1 mem2 mem3 mem_addr ALU1 ALU2 ALU buss PC uPC  uPC_addr
    --  00  0   00  00   0  00 00  00   00   00    000     00   0   000 000  00 0000 00000000

    signal mem : Data := (
        -- Startup, check if we're in game
        "00000000000000000000000000000000011000101000", -- jmpS GAME(28)

        -- Load in program to memory
        "00000000000000000000000000011000000000000000", -- IN -> buss

        -- Load program 1
        "11000000000000000000000011000000000000000000", -- ALU = 0, fifo_next
        "01000000000000000000000000010001000000000000", -- ALU1 -> buss, buss -> FIFO, buss -> PC
        "10000000000000000000000000000000000000000000", -- change_player

        "00000000000000000000000000000000010000000111", -- jmpIN F1NUM(07)
        "00000000000000000000000000000000001000000101", -- jmp -1(05)
        "00000000000000000000001000111000000000000000", -- IN -> buss, buss -> ALU1
        "00000000000000000000000000000000010000001010", -- jmpIN F1OP(0a)
        "00000000000000000000000000000000001000001000", -- jmp -1(08)
        "00000001000000000000000000011000000000000000", -- IN -> buss, buss -> OP
        "00000000000000000000000000000000010000001101", -- jmpIN F1M1(0d)
        "00000000000000000000000000000000001000001011", -- jmp -1(0b)
        "00000000010000000000000000011000000000000000", -- IN -> buss, buss -> M1
        "00000000000000000000000000000000010000010000", -- jmpIN F1M2(10)
        "00000000000000000000000000000000001000001110", -- jmp -1(0e)
        "00000000000100000011000000011000000000000000", -- IN -> buss, buss -> M2, PC -> mem_addr
        "00000000000010101000000000000000000000000000", -- OP -> mem, M1 -> mem, M2 -> mem
        "00000000000000000000000010100010000000000000", -- ALU--, PC++
        "00000000000000000000000000000000001100010101", -- jmpZ LOAD2(15)
        "00000000000000000000000000000000001000001000", -- jmp F1ROW(08)

        -- Load program 2
        "00000000000000000000000000000000010000010111", -- jmpIN F2PC(17)
        "00000000000000000000000000000000001000010101", -- jmp -1(15)
        "01000000000000000000000000011001000000000000", -- IN -> buss, buss -> FIFO, buss -> PC
        "00000000000000000000000000000000010000011010", -- jmpIN F2NUM(1a)
        "00000000000000000000000000000000001000011000", -- jmp -1(18)
        "00000000000000000000001000111000000000000000", -- IN -> buss, buss -> ALU1
        "00000000000000000000000000000000010000011101", -- jmpIN F2OP(1d)
        "00000000000000000000000000000000001000011011", -- jmp -1(1b)
        "00000001000000000000000000011000000000000000", -- IN -> buss, buss -> OP
        "00000000000000000000000000000000010000100000", -- jmpIN F2M1(20)
        "00000000000000000000000000000000001000011110", -- jmp -1(1e)
        "00000000010000000000000000011000000000000000", -- IN -> buss, buss -> M1
        "00000000000000000000000000000000010000100011", -- jmpIN F2M2(23)
        "00000000000000000000000000000000001000100001", -- jmp -1(21)
        "00000000000100000011000000011000000000000000", -- IN -> buss, buss -> M2, PC -> mem_addr
        "00000000000010101000000000000000000000000000", -- OP -> mem, M1 -> mem, M2 -> mem
        "00000000000000000000000010100010000000000000", -- ALU--, PC++
        "00000000000000000000000000000000001100000000", -- jmpZ 0(00)
        "00000000000000000000000000000000001000011011", -- jmp F2ROW(1b)


        -- Game sequence
        "10000000000000000000000000000000000000000000", -- change_player
        "11000000000000000000000000000000000000000000", -- fifo_next
        "00000000000000000000000000010101000000000000", -- FIFO -> buss, buss -> PC
        "00000000000000000011000000000000000000000000", -- PC -> mem_addr
        "00000000000001010100000000000000000000000000", -- mem -> OP, mem -> M1, mem -> M2
        "00100000000000000000000000000100001000101110", -- OP -> buss, buss -> IR, jmp AMOD(2e)

        -- Calculate adress mode for A operand
        "00000000000000000000000000000000100100111111", -- jmpAimm BMOD(3f)
        "00000000000000000000000000100000000000000000", -- M1 -> ALU1
        "00000000000000000000001001000000000000000000", -- ALU1 += PC
        "00000000100000000000000000000000000000000000", -- ALU1 -> M1
        "00000000000000000000000000000000101000111111", -- jmpAdir BMOD(3f)
        "00000000000000000100100000001000000000000000", -- M1 -> buss, buss -> mem_addr, mem -> M2
        "00000000010000000000000000001100000000000000", -- M2 -> buss, buss -> M1
        "00000000000000000000000000000000101100111010", -- jmpApre APRE(3a)
        "00000000000000000000000000100000000000000000", -- M1 -> ALU1
        "00000000000000000000011001000000000000000000", -- ALU1 += mem_addr
        "00000000100000000000000000000000000000000000", -- ALU1 -> M1
        "00000000000000000000000000000000001000111111", -- jmp BMOD(3f)

        "00000000000000000000000000100000000000000000", -- M1 -> ALU1
        "00000000000000000000000010100000000000000000", -- ALU--
        "00000000101000000000000000000000000000000000", -- ALU1 -> M1, ALU1 -> M2
        "00000000000000001000000000000000000000000000", -- M2 -> mem
        "00000000000000000000000000000000001000110110", -- jmp AOFF(36)

        -- Calculate adress mode for B operand
        "00000000000000000011000000000000000000000000", -- PC -> mem_addr
        "00000000000000000100000000000000000000000000", -- mem -> M2
        "00000000000000000000000000000000110001010010", -- jmpBimm INSTR(52)
        "00000000000000000000010000100000000000000000", -- M2 -> ALU1
        "00000000000000000000001001000000000000000000", -- ALU1 += PC
        "00000000001000000000000000000000000000000000", -- ALU1 -> M2
        "00000000000000000000000000000000110101010010", -- jmpBdir INSTR(52)
        "00000000000000000000100000001100000000000000", -- M2 -> buss, buss -> mem_addr
        "00000000000000000100000000000000000000000000", -- mem -> M2
        "00000000000000000000000000000000111001001101", -- jmpBpre BPRE(4d)
        "00000000000000000000010000100000000000000000", -- M2 -> ALU1
        "00000000000000000000011001000000000000000000", -- ALU1 += mem_addr
        "00000000001000000000000000000000000000000000", -- ALU1 -> M2
        "00000000000000000000000000000000001001010010", -- jmp INSTR(52)

        "00000000000000000000010000100000000000000000", -- M2 -> ALU1
        "00000000000000000000000010100000000000000000", -- ALU--
        "00000000001000000000000000000000000000000000", -- ALU1 -> M2
        "00000000000000001000000000000000000000000000", -- M2 -> mem
        "00000000000000000000000000000000001001001001", -- jmp BOFF(49)


        -- Load up instruction and proceed to instruction decoding
        -- A operand is now in ADR1 and B in ADR2
        -- If immediate ignore these, they're also in M1 and M2

        "00010100000000000000000000000000000100000000", -- M1 -> ADR1, M2 -> ADR2, op_addr -> uPC


        -- Execute instruction
        --
        -- ADR1 is now the absolute address for the A operand
        -- ADR2 is for the B operand
        -- M1 and M2 holds copies of ADR1 and ADR2 always
        --
        -- If immediate, the data is instead in M1 or M2

        -- DAT  Executing data will eat up the PC
        "00000000000000000000000000000000001010111001", -- jmp END(b9)

        -- MOV  Move A to B
        "00000000000000000000000000000000100101011010", -- jmpAimm IMOV(5a)
        "00000000000000000010000000000000000000000000", -- ADR1 -> mem_addr
        "00000000000001010100000000000000000000000000", -- mem -> OP, mem -> M1, mem -> M2
        "00000000000000000010100000000000000000000000", -- ADR2 -> mem_addr
        "00000000000010101000000000000000000000000000", -- OP -> mem, M1 -> mem, M2 -> mem
        "00000000000000000000000000000000001010110111", -- jmp ADDPC(b7)

        -- If A immediate, move A to B op specified by B mem address
        "00000000000100000010100000001000000000000000", -- ADR2 -> mem_addr, M1 -> buss, buss -> M2
        "00000000000000001000000000000000000000000000", -- M2 -> mem
        "00000000000000000000000000000000001010110111", -- jmp ADDPC(b7)

        -- ADD  Add A to B
        "00000000000000000000000000000000100101100110", -- jmpAimm IADD(66)
        "00000000000000000010000000000000000000000000", -- ADR1 -> mem_addr
        "00000000000000010100000000000000000000000000", -- mem -> M1, mem -> M2
        "00000000000000000010100100100000000000000000", -- ADR2 -> mem_addr, M1 -> ALU1, M2 -> ALU2
        "00000000000000010100000000000000000000000000", -- mem -> M1, mem -> M2
        "00000000000000000000000101000000000000000000", -- ALU1 += M1, ALU2 += M2
        "00000000101100000000000000000000000000000000", -- ALU1 -> M1, ALU2 -> M2
        "00000000000000101000000000000000000000000000", -- M1 -> mem, M2 -> mem
        "00000000000000000000000000000000001010110111", -- jmp ADDPC(b7)

        "00000000000000000010100000000000000000000000", -- ADR2 -> mem_addr
        "00000000000000000100000000100000000000000000", -- M1 -> ALU1, mem -> M2
        "00000000000000000000010001000000000000000000", -- ALU1 += M2
        "00000000001000000000000000000000000000000000", -- ALU1 -> M2
        "00000000000000001000000000000000000000000000", -- M2 -> mem
        "00000000000000000000000000000000001010110111", -- jmp ADDPC(b7)

        -- SUB  Sub A from B
        "00000000000000000000000000000000100101110101", -- jmpAimm ISUB(75)
        "00000000000000000010100000000000000000000000", -- ADR2 -> mem_addr
        "00000000000000010100000000000000000000000000", -- mem -> M1, mem -> M2
        "00000000000000000010000100100000000000000000", -- ADR1 -> mem_addr, M1 -> ALU1, M2 -> ALU2
        "00000000000000010100000000000000000000000000", -- mem -> M1, mem -> M2
        "00000000000000000000000101100000000000000000", -- ALU1 -= M1, ALU2 -= M2
        "00000000101100000010100000000000000000000000", -- ALU1 -> M1, ALU2 -> M2, ADR2 -> mem_addr
        "00000000000000101000000000000000000000000000", -- M1 -> mem, M2 -> mem
        "00000000000000000000000000000000001010110111", -- jmp ADDPC(b7)


        "00000000000000000010100000000000000000000000", -- ADR2 -> mem_addr
        "00000000000000000100000000000000000000000000", -- mem -> M2
        "00000000000000000000010000100000000000000000", -- M2 -> ALU1
        "00000000000000000000000001100000000000000000", -- ALU1 -= M1
        "00000000001000000000000000000000000000000000", -- ALU1 -> M2
        "00000000000000001000000000000000000000000000", -- M2 -> mem
        "00000000000000000000000000000000001010110111", -- jmp ADDPC(b7)

        -- JMP  Jump to A
        "00000000000000000010000000000000000000000000", -- ADR1 -> mem_addr
        "00000000000000010000011000100000000000000000", -- mem -> M1, mem_addr -> ALU1
        "00000000000000000000000001000000000000000000", -- ALU1 += M1
        "01000000000000000000000000010000001010111001", -- ALU1 -> buss, buss -> FIFO, jmp END(b9)

        -- JMPZ Jump to A if B zero
        "00000000000000000000000000000000110010000011", -- jmpBimm IJMPZ(83)
        "00000000000000000010100000000000000000000000", -- ADR2 -> mem_addr
        "00000000000000000100000000000000000000000000", -- mem -> M2
        "00000000000000000000010000100000000000000000", -- M2 -> ALU1
        "00000000000000000000000000000000001110000110", -- jmpZ DOJMPZ(86)
        "00000000000000000000000000000000001010110111", -- jmp ADDPC(b7)
        "00000000000000000000000000000000001001111100", -- jmp JMP(7c)

        -- JMPN Jump to A if B non-zero
        "00000000000000000000000000000000110010001010", -- jmpBimm IJMPN(8a)
        "00000000000000000010100000000000000000000000", -- ADR2 -> mem_addr
        "00000000000000000100000000000000000000000000", -- mem -> M2
        "00000000000000000000010000100000000000000000", -- M2 -> ALU1
        "00000000000000000000000000000000001110110111", -- jmpZ ADDPC(b7)
        "00000000000000000000000000000000001001111100", -- jmp JMP(7c)

        -- CMP If A eq B skip next instr
        "00000000000000000000000000000000100110011010", -- jmpAimm ICMP(9a)
        "00000000000000000010100000000000000000000000", -- ADR2 -> mem_addr
        "00000000000001010100000000000000000000000000", -- mem -> OP, mem -> M1, mem -> M2
        "00000000000000000010000100100000000000000000", -- ADR1 -> mem_addr, M1 -> ALU1, M2 -> ALU2
        "00000000000000010100000000000000000000000000", -- mem -> M1, mem -> M2
        "00000000000000000000000101100000000000000000", -- ALU1 -= M1, ALU2 -= M2
        "00000000000000000000000000000000100010010101", -- jmpE CMPOP(95)
        "00000000000000000000000000000000001010110111", -- jmp ADDPC(b7)

        "00000000000000000000001000100100000000000000", -- OP -> buss, buss -> ALU1
        "00000000000001000000000000000000000000000000", -- mem -> OP
        "00000000000000000000001001100100000000000000", -- ALU1 -= OP
        "00000000000000000000000000000000001110110110", -- jmpZ SKIP(b6)
        "00000000000000000000000000000000001010110111", -- jmp ADDPC(b7)

        "00000000000000000010100000000000000000000000", -- ADR2 -> mem_addr
        "00000000000000000100000000100000000000000000", -- mem -> M2, M1 -> ALU1
        "00000000000000000000010001100000000000000000", -- ALU1 -= M2
        "00000000000000000000000000000000001110110110", -- jmpZ SKIP(b6)
        "00000000000000000000000000000000001010110111", -- jmp ADDPC(b7)

        -- SLT if A is less than B skip next instr
        "00000000000000000000000000000000100110101000", -- jmpAimm ISLT(a8)
        "00000000000000000010000000000000000000000000", -- ADR1 -> mem_addr
        "00000000000000000100000000000000000000000000", -- mem -> M2
        "00000000000000000000010000100000000000000000", -- M2 -> ALU1
        "00000000000000000010100000000000000000000000", -- ADR2 -> mem_addr
        "00000000000000000100000000000000000000000000", -- mem -> M2
        "00000000000000000000010001100000000000000000", -- ALU1 -= M2
        "00000000000000000000000000000000011110110110", -- jmpN SKIP(b6)
        "00000000000000000000000000000000001010110111", -- jmp ADDPC(b7)

        "00000000000000000000000000100000001010100011", -- M1 -> ALU1, jmp SLTCMP(a3)

        -- DJN Decr B, if not zero jmp to A
        "00000000000000000000000000000000110010110010", -- jmpBimm IDJN(b2)
        "00000000000000000010100000000000000000000000", -- ADR2 -> mem_addr
        "00000000000000000100000000000000000000000000", -- mem -> M2
        "00000000000000000000010000100000000000000000", -- M2 -> ALU1
        "00000000000000000000000010100000000000000000", -- ALU--
        "00000000001000000000000000000000000000000000", -- ALU1 -> M2
        "00000000000000001000000000000000000000000000", -- M2 -> mem
        "00000000000000000000000000000000001110110111", -- jmpZ ADDPC(b7)
        "01000000000000000000000000001000001010111001", -- M1 -> buss, buss -> FIFO, jmp END(b9)

        "00000000000000000000010000100000001010110000", -- M2 -> ALU1, jmp CMPDJN(b0)

        -- SPL Place A in process queue
        "00000000000000000000000000000010000000000000", -- PC++
        "01000000000000000000000000000000000000000000", -- PC -> buss, buss -> FIFO
        "01000000000000000000000000001000001010111001", -- M1 -> buss, buss -> FIFO, jmp END(b9)

        "00000000000000000000000000000010001010110111", -- PC++, jmp ADDPC(b7)

        -- Keep the PC for next round
        "00000000000000000000000000000010000000000000", -- PC++
        "01000000000000000000000000000000000000000000", -- PC -> buss, buss -> FIFO

        "00000000000000000000000000000000001010111010", -- jmp DELAY(ba)
        "00000000000000000000000000000000010100000000", -- jmpC 0(00)
        "00000000000000000000000000000000001010111010", -- jmp DELAY(ba)

        others => (others => '0')
    );

    -- Synced reset
    signal reset : std_logic;

    -- Current microcode line to process
    signal signals : DataLine;

    -- Controll the behavior of next uPC value
    signal uPC_addr : std_logic_vector(7 downto 0);
    signal uPC_code : std_logic_vector(3 downto 0);

    signal IR_code : std_logic;

    signal uCounter : std_logic_vector(7 downto 0);

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

    -------------------------------------------------------------------------
    -- RETRIEVE SIGNALS
    -------------------------------------------------------------------------

    signals <= mem(conv_integer(uPC));

    uPC_addr <= signals(7 downto 0);
    uPC_code <= signals(11 downto 8);

    PC_code <= signals(13 downto 12);
    buss_code <= signals(16 downto 14);

    ALU_code <= signals(19 downto 17);
    ALU2_code <= signals(20);
    ALU1_code <= signals(22 downto 21);

    memory_addr_code <= signals(25 downto 23);

    memory3_read <= signals(26);
    memory3_write <= signals(27);

    memory2_read <= signals(28);
    memory2_write <= signals(29);

    memory1_read <= signals(30);
    memory1_write <= signals(31);

    M2_code <= signals(33 downto 32);
    M1_code <= signals(35 downto 34);
    OP_code <= signals(36);

    ADR2_code <= signals(38 downto 37);
    ADR1_code <= signals(40 downto 39);

    IR_code <= signals(41);
    FIFO_code <= signals(43 downto 42);

    -------------------------------------------------------------------------
    -- ENCODINGS
    -------------------------------------------------------------------------

    -- OP code address decoding
    with OP_field select
        op_addr <=  "01010011" when "0000", -- DAT 53
                    "01010100" when "0001", -- MOV 54
                    "01011101" when "0010", -- ADD 5d
                    "01101100" when "0011", -- SUB 6c
                    "01111100" when "0100", -- JMP 7c
                    "10000000" when "0101", -- JMPZ 80
                    "10000111" when "0110", -- JMPN 87
                    "10001101" when "0111", -- CMP 8d
                    "10011111" when "1000", -- SLT 9f
                    "10101001" when "1001", -- DJN a9
                    "10110011" when "1010", -- SPL b3
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

            -------------------------------------------------------------------------
            -- SIGNAL MULTIPLEXERS
            -------------------------------------------------------------------------

            -- Update uPC
            if reset_a = '1' then
                uPC <= "00000000";

            elsif uPC_code = "0001" then
                uPC <= op_addr;
            elsif uPC_code = "0010" then
                uPC <= uPC_addr;
            elsif uPC_code = "0011" and Z = '1' then
                uPC <= uPC_addr;
            elsif uPC_code = "0100" and new_IN = '1' then
                uPC <= uPC_addr;
            elsif uPC_code = "0101" and uCounter >= uCount_limit then
                uPC <= uPC_addr;
            elsif uPC_code = "0110" and game_started = '1' then
                uPC <= uPC_addr;
            elsif uPC_code = "0111" and N = '1' then
                uPC <= uPC_addr;
            elsif uPC_code = "1000" and both_Z = '1' then
                uPC <= uPC_addr;

            elsif uPC_code = "1001" and A_imm = '1' then
                uPC <= uPC_addr;
            elsif uPC_code = "1010" and A_dir = '1' then
                uPC <= uPC_addr;
            elsif uPC_code = "1011" and A_pre = '1' then
                uPC <= uPC_addr;
            elsif uPC_code = "1100" and B_imm = '1' then
                uPC <= uPC_addr;
            elsif uPC_code = "1101" and B_dir = '1' then
                uPC <= uPC_addr;
            elsif uPC_code = "1110" and B_pre = '1' then
                uPC <= uPC_addr;

            elsif uPC_code = "1111" then
                uPC <= "00000000";
            else
                uPC <= uPC + 1;
            end if;

            -- Update uCounter
            if reset_a = '1' then
                uCounter <= "00000000";
            elsif uPC = "00000000" then
                uCounter <= "00000000";
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

