----------------------------------------------------------------------------------
-- Company:         CIOMP
-- Engineer:        WangZheng
-- Create Date:     2025/02/22 09:00:58
-- Module Name:     SEN_DRIVE - Behavioral
-- Project Name:    CH4_G400
-- Target Devices:  xc7k325tffg900-2
-- Tool Versions:   Vivado 2018.3
-- Description:     generate the sensor's decoder signals (row logic address)
--                  and digital control signals (ctrl sensor readout)
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity SEN_DRIVE is
    port (
        ---------SENSOR------------------
        Train_DRI                   : out STD_LOGIC;                            -- digital control signal in SEN_DRIVE
        ---------CLOCKING---------
        Clk_Ref                     : in  STD_LOGIC;                            -- sensor main clk 25MHz, same as CLK_PIX in datasheet
        Rst_Ref                     : in  STD_LOGIC;                            -- Clk_Ref correspond rst signal
        ---------pin---------
        ROW                         : out STD_LOGIC_VECTOR (11 downto 0);       -- sensor read and reset addr
        TX                          : out STD_LOGIC;                            -- digital control signal
        RS                          : out STD_LOGIC;                            -- digital control signal
        RST                         : out STD_LOGIC;                            -- digital control signal
        HDR                         : out STD_LOGIC;                            -- digital control signal
        TAZ                         : out STD_LOGIC;                            -- digital control signal
        TAB                         : out STD_LOGIC;                            -- digital control signal
        TPC                         : out STD_LOGIC;                            -- digital control signal
        TINITO                      : out STD_LOGIC;                            -- digital control signal
        TINITE                      : out STD_LOGIC;                            -- digital control signal
        TSO                         : out STD_LOGIC;                            -- digital control signal
        TSE                         : out STD_LOGIC;                            -- digital control signal
        TAC                         : out STD_LOGIC;                            -- digital control signal
        TRD                         : out STD_LOGIC;                            -- digital control signal
        TADR                        : out STD_LOGIC;                            -- digital control signal
        TADS                        : out STD_LOGIC;                            -- digital control signal
        TWS                         : out STD_LOGIC;                            -- digital control signal
        SYNC                        : out STD_LOGIC;                            -- digital control signal
        TBS                         : out STD_LOGIC;                            -- digital control signal
        TS                          : out STD_LOGIC;                            -- digital control signal
        ---------SEN_CTRL---------
        Exposure_Line               : in  STD_LOGIC_VECTOR (15 downto 0);       -- Exposure_Line 0000H~FFFFH default 0100H
        Cmd_Drive                   : in  STD_LOGIC;                            -- the command of shooting
        Cmd_Check1                  : in  STD_LOGIC;                            -- the command of check1 signal
        Frame_Circle                : out STD_LOGIC_VECTOR (7 downto 0);        -- count the circle of 2048 rows
        ---------TOP---------
        Sync_Rx                     : out STD_LOGIC;                            -- the one clk sync signal of every line
        Image_Out                   : out STD_LOGIC);                           -- pull high when the image's output is valid
end SEN_DRIVE;

architecture Behavioral of SEN_DRIVE is

    -- cnt
    signal  clk_cnt                 : integer range 0 to 600;                   -- count Clk_Ref to control signal
    signal  read_cnt                : integer range 0 to 1050000;               -- count read row address
    signal  rst_cnt                 : integer range 0 to 1050000;               -- count rst row address
    -- reg
    signal  Read_Ctrl               : STD_LOGIC;                                -- first time read_addr wait Exposure_Line
    signal  frame_cnt               : STD_LOGIC_VECTOR (7 downto 0);            -- count the circle of 2048 rows
    signal  Read_Addr               : STD_LOGIC_VECTOR (11 downto 0);           -- decoder read address M
    signal  Rst_Addr                : STD_LOGIC_VECTOR (11 downto 0);           -- decoder rst address N
    signal  Dummy_Addr              : STD_LOGIC_VECTOR (11 downto 0);           -- dummy address is X"FA0"
    signal  Exposure_Line_r         : STD_LOGIC_VECTOR (15 downto 0);           -- reg of Exposure_Line
    -- fsm
    type    Fsm_Drive is (S_Idle, S0, S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11, S12, S13, S14, S15, S16, S17, S18, S19, S20, S21, S22,
                          S23, S24, S25, S26, S27, S28, S29, S30, S31, S32, S33, S34, S35, S36, S37, S38, S39, S40, S41, S_Delay, C0, C1);
    signal  state : Fsm_Drive;

    -- attribute mark_debug    : string;
    -- attribute mark_debug    of Sync_Rx          : signal is "true";
    -- attribute mark_debug    of Image_Out        : signal is "true";
    -- attribute mark_debug    of ROW              : signal is "true";
    -- attribute mark_debug    of read_cnt         : signal is "true";
    -- attribute mark_debug    of state            : signal is "true";
    -- attribute mark_debug    of Train_DRI        : signal is "true";
    -- attribute mark_debug    of clk_cnt          : signal is "true";
    -- attribute mark_debug    of TX               : signal is "true";
    -- attribute mark_debug    of RS               : signal is "true";
    -- attribute mark_debug    of RST              : signal is "true";
    -- attribute mark_debug    of HDR              : signal is "true";
    -- attribute mark_debug    of TAZ              : signal is "true";
    -- attribute mark_debug    of TAB              : signal is "true";
    -- attribute mark_debug    of TPC              : signal is "true";
    -- attribute mark_debug    of TINITO           : signal is "true";
    -- attribute mark_debug    of TINITE           : signal is "true";
    -- attribute mark_debug    of TSO              : signal is "true";
    -- attribute mark_debug    of TSE              : signal is "true";
    -- attribute mark_debug    of TAC              : signal is "true";
    -- attribute mark_debug    of TRD              : signal is "true";
    -- attribute mark_debug    of TADR             : signal is "true";
    -- attribute mark_debug    of TADS             : signal is "true";
    -- attribute mark_debug    of TWS              : signal is "true";
    -- attribute mark_debug    of SYNC             : signal is "true";
    -- attribute mark_debug    of TBS              : signal is "true";
    -- attribute mark_debug    of TS               : signal is "true";

begin

    Frame_Circle    <= frame_cnt;

    --*****************************************************
    -- synchronous Exposure_Line signal
    ------------------------
    process(Clk_Ref, Rst_Ref) begin
        if (Rst_Ref = '0') then
            Exposure_Line_r <= (others => '0');
        elsif (Clk_Ref'event and Clk_Ref = '1') then
            Exposure_Line_r <= Exposure_Line;
        end if;
    end process;

    --*********************************************************
    -- decoder address and control signals
    -----------------------------------------------------------
    process(Clk_Ref, Rst_Ref) begin
        if (Rst_Ref = '0') then
            state           <= S_Idle;
            clk_cnt         <= 0;
            read_cnt        <= 0;
            rst_cnt         <= 0;
            TX              <= '0';
            RS              <= '0';
            RST             <= '1';
            HDR             <= '1';
            TAZ             <= '1';
            TAB             <= '1';
            TPC             <= '0';
            TINITO          <= '0';
            TINITE          <= '0';
            TSO             <= '0';
            TSE             <= '0';
            TAC             <= '0';
            TRD             <= '0';
            TADR            <= '0';
            TADS            <= '0';
            TWS             <= '0';
            SYNC            <= '0';
            TBS             <= '0';
            TS              <= '0';
            Train_DRI       <= '0';
            Sync_Rx         <= '0';
            Image_Out       <= '0';
            Read_Ctrl       <= '1';
            frame_cnt       <= (others => '0');
            ROW             <= (others => '0');
            Dummy_Addr      <= X"FA0";
            Read_Addr       <= (others => '0');
            Rst_Addr        <= (others => '0');
        elsif (Clk_Ref'event and Clk_Ref = '1') then
            case state is
                when S_Idle =>
                    if (Cmd_Drive = '1') then                                   -- rst_addr start counting, control read_addr depend on Exposure_Line
                        state       <= S0;
                    elsif (Cmd_Check1 = '1') then
                        state       <= C0;
                    else
                        state       <= S_Idle;
                        clk_cnt     <= 0;
                        read_cnt    <= 0;
                        rst_cnt     <= 0;
                        Read_Ctrl   <= '1';
                        Image_Out   <= '0';
                        frame_cnt   <= (others => '0');
                        Read_Addr   <= Dummy_Addr;
                        Rst_Addr    <= (others => '0');
                        ROW         <= (others => '0');
                    end if;
                    TX          <= '0';
                    RS          <= '0';
                    RST         <= '1';
                    HDR         <= '1';
                    TAZ         <= '1';
                    TAB         <= '1';
                    TPC         <= '0';
                    TINITO      <= '0';
                    TINITE      <= '0';
                    TSO         <= '0';
                    TSE         <= '0';
                    TAC         <= '0';
                    TRD         <= '0';
                    TADR        <= '0';
                    TADS        <= '0';
                    TWS         <= '0';
                    SYNC        <= '0';
                    TBS         <= '0';
                    TS          <= '0';
                    Sync_Rx     <= '0';
                --*********************************************************
                -- dirve cmos
                -----------------------------------------------------------
                when S0 =>                                                      -- 0
                    state       <= S1;
                    ROW         <= Read_Addr;                                   -- assign Read_Addr value to ROW
                    --*********************************************************
                    -- read_addr valid after rst_addr = Exposure_Line line
                    -----------------------------------------------------------
                    if (Read_Ctrl = '1') then                                   -- first time read_addr wait Exposure_Line
                        if (read_cnt = CONV_INTEGER(Exposure_Line_r)) then
                            read_cnt    <= 0;
                            Read_Addr   <= X"000";                              -- read_addr start address
                            Read_Ctrl   <= '0';                                 -- cancel first sign
                        else
                            read_cnt    <= read_cnt + 1;
                            Read_Addr   <= Dummy_Addr;
                        end if;
                    else                                                        -- second time don't need to wait, read_addr and rst_addr alternate
                        --*********************************************************
                        -- Exposure_Line is longer than 2049, add dummy
                        -----------------------------------------------------------
                        if (Exposure_Line_r > X"0801") then                     -- 2049 because read_cnt
                            if (read_cnt = CONV_INTEGER(Exposure_Line_r)) then
                                read_cnt    <= 0;
                                Read_Addr   <= X"000";                          -- read_addr start address
                            elsif (read_cnt > 2047 and read_cnt < CONV_INTEGER(Exposure_Line_r)) then   -- add dummy from 2047
                                read_cnt    <= read_cnt + 1;
                                Read_Addr   <= Dummy_Addr;
                            else                                                -- add dummy rows
                                read_cnt    <= read_cnt + 1;
                                Read_Addr   <= Read_Addr + 1;
                            end if;
                        else                                                    -- Exposure_Line is less than 2048
                            if (read_cnt = 2050) then
                                read_cnt    <= 0;
                                Read_Addr   <= X"000";
                            elsif (read_cnt >= 2047 and read_cnt <= 2049) then  -- delay 3 line
                                read_cnt    <= read_cnt + 1;
                                Read_Addr   <= Dummy_Addr;
                            else
                                read_cnt    <= read_cnt + 1;
                                Read_Addr   <= Read_Addr + 1;
                            end if;
                        end if;
                    end if;

                when S1 =>                                                      -- 1
                    TAZ         <= '0';
                    state       <= S2;

                when S2 =>                                                      -- 2
                    RS          <= '1';
                    if (clk_cnt = 7) then                                       -- +8
                        state   <= S3;
                        clk_cnt <= 0;
                    else
                        state   <= S2;
                        clk_cnt <= clk_cnt + 1;
                    end if;

                when S3 =>                                                      -- 10
                    RST         <= '0';
                    if (clk_cnt = 9) then                                       -- +10
                        state   <= S4;
                        clk_cnt <= 0;
                    else
                        state   <= S3;
                        clk_cnt <= clk_cnt + 1;
                    end if;

                when S4 =>                                                      -- 20
                    TAZ         <= '0';
                    state       <= S5;

                when S5 =>                                                      -- 21
                    TAB         <= '0';
                    if (clk_cnt = 1) then                                       -- +2
                        state   <= S6;
                        clk_cnt <= 0;
                    else
                        state   <= S5;
                        clk_cnt <= clk_cnt + 1;
                    end if;

                when S6 =>                                                      -- 23
                    TAC         <= '1';
                    if (clk_cnt = 1) then                                       -- +2
                        state   <= S7;
                        clk_cnt <= 0;
                    else
                        state   <= S6;
                        clk_cnt <= clk_cnt + 1;
                    end if;

                when S7 =>                                                      -- 25
                    TAC         <= '0';
                    if (clk_cnt = 4) then                                       -- +5
                        state   <= S8;
                        clk_cnt <= 0;
                    else
                        state   <= S7;
                        clk_cnt <= clk_cnt + 1;
                    end if;

                when S8 =>                                                      -- 30
                    TRD         <= '1';
                    TADR        <= '1';
                    if (clk_cnt = 2) then                                       -- +3
                        state   <= S9;
                        clk_cnt <= 0;
                    else
                        state   <= S8;
                        clk_cnt <= clk_cnt + 1;
                    end if;

                when S9 =>                                                      -- 33
                    TINITO      <= '1';
                    TINITE      <= '1';
                    TSO         <= '1';
                    if (clk_cnt = 41) then                                      -- +42
                        state   <= S10;
                        clk_cnt <= 0;
                    else
                        state   <= S9;
                        clk_cnt <= clk_cnt + 1;
                    end if;

                when S10 =>                                                     -- 75
                    TINITO      <= '0';
                    if (clk_cnt = 17) then                                      -- +18
                        state   <= S11;
                        clk_cnt <= 0;
                    else
                        state   <= S10;
                        clk_cnt <= clk_cnt + 1;
                    end if;

                when S11 =>                                                     -- 93
                    TRD         <= '0';
                    TADR        <= '0';
                    if (clk_cnt = 4) then                                       -- +5
                        state   <= S12;
                        clk_cnt <= 0;
                    else
                        state   <= S11;
                        clk_cnt <= clk_cnt + 1;
                    end if;

                when S12 =>                                                     -- 98
                    TAC         <= '1';
                    if (clk_cnt = 1) then                                       -- +2
                        state   <= S13;
                        clk_cnt <= 0;
                    else
                        state   <= S12;
                        clk_cnt <= clk_cnt + 1;
                    end if;

                when S13 =>                                                     -- 100
                    TAC         <= '0';
                    if (clk_cnt = 4) then                                       -- +5
                        state   <= S14;
                        clk_cnt <= 0;
                    else
                        state   <= S13;
                        clk_cnt <= clk_cnt + 1;
                    end if;

                when S14 =>                                                     -- 105
                    TRD         <= '1';
                    if (clk_cnt = 2) then                                       -- +3
                        state   <= S15;
                        clk_cnt <= 0;
                    else
                        state   <= S14;
                        clk_cnt <= clk_cnt + 1;
                    end if;

                when S15 =>                                                     -- 108
                    TADS        <= '1';
                    if (clk_cnt = 11) then                                      -- +12
                        state   <= S16;
                        clk_cnt <= 0;
                    else
                        state   <= S15;
                        clk_cnt <= clk_cnt + 1;
                    end if;

                when S16 =>                                                     -- 120
                    TSO         <= '0';
                    if (clk_cnt = 3) then                                       -- +4
                        state   <= S17;
                        clk_cnt <= 0;
                    else
                        state   <= S16;
                        clk_cnt <= clk_cnt + 1;
                    end if;

                when S17 =>                                                     -- 124
                    HDR         <= '0';
                    state       <= S18;

                when S18 =>                                                     -- 125
                    TSE         <= '1';
                    if (clk_cnt = 64) then                                      -- +65
                        state   <= S19;
                        clk_cnt <= 0;
                    else
                        state   <= S18;
                        clk_cnt <= clk_cnt + 1;
                    end if;

                when S19 =>                                                     -- 190
                    TINITE      <= '0';
                    if (clk_cnt = 25) then                                      -- +26
                        state   <= S20;
                        clk_cnt <= 0;
                    else
                        state   <= S19;
                        clk_cnt <= clk_cnt + 1;
                    end if;

                when S20 =>                                                     -- 216
                    TSE         <= '0';
                    if (clk_cnt = 1) then                                       -- +2
                        state   <= S21;
                        clk_cnt <= 0;
                    else
                        state   <= S20;
                        clk_cnt <= clk_cnt + 1;
                    end if;

                when S21 =>                                                     -- 218
                    TSE         <= '1';
                    if (clk_cnt = 1) then                                       -- +2
                        state   <= S22;
                        clk_cnt <= 0;
                    else
                        state   <= S21;
                        clk_cnt <= clk_cnt + 1;
                    end if;

                when S22 =>                                                     -- 220
                    TX          <= '1';
                    if (clk_cnt = 14) then                                      -- +15
                        state   <= S23;
                        clk_cnt <= 0;
                    else
                        state   <= S22;
                        clk_cnt <= clk_cnt + 1;
                    end if;

                when S23 =>                                                     -- 235
                    TX          <= '0';
                    if (clk_cnt = 97) then                                      -- +98
                        state   <= S24;
                        clk_cnt <= 0;
                    else
                        state   <= S23;
                        clk_cnt <= clk_cnt + 1;
                    end if;

                when S24 =>                                                     -- 333
                    TSE         <= '0';
                    if (clk_cnt = 3) then                                       -- +4
                        state   <= S25;
                        clk_cnt <= 0;
                    else
                        state   <= S24;
                        clk_cnt <= clk_cnt + 1;
                    end if;

                when S25 =>                                                     -- 337
                    RS          <= '0';
                    if (clk_cnt = 3) then                                       -- +4
                        state   <= S26;
                        clk_cnt <= 0;
                    else
                        state   <= S25;
                        clk_cnt <= clk_cnt + 1;
                    end if;

                when S26 =>                                                     -- 341
                    HDR         <= '1';
                    if (clk_cnt = 1) then                                       -- +2
                        state   <= S27;
                        clk_cnt <= 0;
                    else
                        state   <= S26;
                        clk_cnt <= clk_cnt + 1;
                    end if;

                when S27 =>                                                     -- 343
                    TX          <= '1';
                    if (clk_cnt = 5) then                                       -- +6
                        state   <= S28;
                        clk_cnt <= 0;
                    else
                        state   <= S27;
                        clk_cnt <= clk_cnt + 1;
                    end if;

                when S28 =>                                                     -- 349
                    TSO         <= '1';
                    if (clk_cnt = 8) then                                       -- +9
                        state   <= S29;
                        clk_cnt <= 0;
                    else
                        state   <= S28;
                        clk_cnt <= clk_cnt + 1;
                    end if;

                when S29 =>                                                     -- 358
                    TX          <= '0';
                    if (clk_cnt = 40) then                                      -- +41
                        state   <= S30;
                        clk_cnt <= 0;
                    else
                        state   <= S29;
                        clk_cnt <= clk_cnt + 1;
                    end if;

                when S30 =>                                                     -- 399
                    RS          <= '1';
                    if (clk_cnt = 63) then                                      -- +64
                        state   <= S31;
                        clk_cnt <= 0;
                    else
                        state   <= S30;
                        clk_cnt <= clk_cnt + 1;
                    end if;

                when S31 =>                                                     -- 463
                    TSO         <= '0';
                    if (clk_cnt = 1) then                                       -- +2
                        state   <= S32;
                        clk_cnt <= 0;
                    else
                        state   <= S31;
                        clk_cnt <= clk_cnt + 1;
                    end if;

                when S32 =>                                                     -- 465
                    RS          <= '0';
                    if (clk_cnt = 1) then                                       -- +2
                        state   <= S33;
                        clk_cnt <= 0;
                    else
                        state   <= S32;
                        clk_cnt <= clk_cnt + 1;
                    end if;

                when S33 =>                                                     -- 467
                    state       <= S34;
                    ROW         <= Rst_Addr;                                    -- rst_addr is valid from beginning
                    --*********************************************************
                    -- Exposure_Line is longer than 2049, rst addr add dummy
                    -----------------------------------------------------------
                    if (Exposure_Line_r >= X"0801") then                        -- 2049
                        if (rst_cnt = CONV_INTEGER(Exposure_Line_r)) then
                            rst_cnt     <= 0;
                            Rst_Addr    <= X"000";                              -- rst_addr start address
                        elsif (rst_cnt >= 2047) then                            -- add dummy addr
                            rst_cnt     <= rst_cnt + 1;
                            Rst_Addr    <= Dummy_Addr;
                        else
                            rst_cnt     <= rst_cnt + 1;
                            Rst_Addr    <= Rst_Addr + '1';
                        end if;
                    else
                        if (rst_cnt = 2050) then
                            rst_cnt     <= 0;
                            Rst_Addr    <= X"000";
                        elsif (rst_cnt >= 2047 and rst_cnt <= 2049) then        -- delay 3 lines
                            rst_cnt     <= rst_cnt + 1;
                            Rst_Addr    <= Dummy_Addr;
                        else
                            rst_cnt     <= rst_cnt + 1;
                            Rst_Addr    <= Rst_Addr + '1';
                        end if;
                    end if;

                when S34 =>                                                     -- 468
                    state       <= S35;

                when S35 =>                                                     -- 469
                    RST         <= '1';
                    if (clk_cnt = 1) then                                       -- +2
                        state   <= S36;
                        clk_cnt <= 0;
                    else
                        state   <= S35;
                        clk_cnt <= clk_cnt + 1;
                    end if;

                when S36 =>                                                     -- 471
                    TX          <= '1';
                    if (clk_cnt = 8) then                                       -- +9
                        state   <= S37;
                        clk_cnt <= 0;
                    else
                        state   <= S36;
                        clk_cnt <= clk_cnt + 1;
                    end if;

                when S37 =>                                                     -- 480
                    TX          <= '0';
                    if (clk_cnt = 13) then                                      -- +14
                        state   <= S38;
                        clk_cnt <= 0;
                    else
                        state   <= S37;
                        clk_cnt <= clk_cnt + 1;
                    end if;

                when S38 =>                                                     -- 494
                    TX          <= '1';
                    if (clk_cnt = 16) then                                      -- +17
                        state   <= S39;
                        clk_cnt <= 0;
                    else
                        state   <= S38;
                        clk_cnt <= clk_cnt + 1;
                    end if;

                when S39 =>                                                     -- 511
                    TX          <= '0';
                    TRD         <= '0';
                    TADS        <= '0';
                    state       <= S_Delay;

                when S_Delay =>
                    if (clk_cnt = 19) then                                      -- +20
                        state   <= S40;
                        clk_cnt <= 0;
                    else
                        state   <= S_Delay;
                        clk_cnt <= clk_cnt + 1;
                    end if;

                when S40 =>                                                     -- 532
                    TWS         <= '1';
                    SYNC        <= '1';
                    state       <= S41;
                    if (Read_Ctrl = '0') then
                        if (read_cnt = 2) then                                      -- 2 line delay, open out
                            Image_Out   <= '1';
                            Sync_Rx     <= '1';
                        elsif (read_cnt = 2050) then                                -- 2 line delay, close out
                            Image_Out   <= '0';
                            frame_cnt   <= frame_cnt + '1';
                        elsif (read_cnt > 2 and read_cnt < 2050) then               -- Sync_Rx
                            Sync_Rx     <= '1';
                        end if;
                    end if;

                when S41 =>                                                     -- 533
                    TWS         <= '0';
                    SYNC        <= '0';
                    Sync_Rx     <= '0';
                    state       <= S_Idle;

                --*********************************************************
                -- check1 cmos training
                -----------------------------------------------------------
                when C0 =>                                                      -- pull up image_out and Sync_Rx
                    if (clk_cnt = 10) then
                        state   <= C1;
                        clk_cnt <= 0;
                    elsif (clk_cnt = 0) then
                        state   <= C0;
                        clk_cnt <= clk_cnt + 1;
                        Sync_Rx <= '1';
                        Image_Out   <= '1';
                        Train_DRI   <= '1';                                     -- open TRAIN
                    else
                        state   <= C0;
                        clk_cnt <= clk_cnt + 1;
                        Sync_Rx <= '0';
                    end if;

                when C1 =>
                    if (clk_cnt = 524) then
                        state   <= S_Idle;
                        clk_cnt <= 0;
                    elsif (clk_cnt = 502) then
                        if (read_cnt = 2047) then
                            read_cnt    <= 0;
                            Image_Out   <= '0';                                 -- one frame, read_cnt = 2048, close Image_Out
                            frame_cnt   <= frame_cnt + '1';
                        else
                            read_cnt    <= read_cnt + 1;
                        end if;
                        state   <= C1;
                        clk_cnt <= clk_cnt + 1;
                        Train_DRI   <= '0';                                     -- close TRAIN
                    else
                        state   <= C1;
                        clk_cnt <= clk_cnt + 1;
                    end if;

                when others =>
                    state       <= S_Idle;
            end case;
        end if;
    end process;
end Behavioral;