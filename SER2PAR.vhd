----------------------------------------------------------------------------------
-- Company:         CIOMP
-- Engineer:        WangZheng
-- Create Date:     2025/01/06 09:04:13
-- Module Name:     SER2PAR - Behavioral
-- Project Name:    CH4_G400
-- Target Devices:  XC7K325T
-- Tool Versions:   Vivado 2018.3
-- Description:     1 LVDS differential input to 12 parallel output.
--                  The IDELAY primitive in the ser2par block need the IDELAYCTRL.
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

entity SER2PAR is
    port (
        DATA_SER_P          : in  STD_LOGIC;
        DATA_SER_N          : in  STD_LOGIC;
        Clk_Ref             : in  STD_LOGIC;
        Rst_Ref             : in  STD_LOGIC;
        Clk_Ddr             : in  STD_LOGIC;
        Rst_Ddr             : in  STD_LOGIC;
        Idelayce            : in  STD_LOGIC;
        Idelayrst           : in  STD_LOGIC;
        Bitslip             : in  STD_LOGIC;
        Pixel_Shift         : in  STD_LOGIC;
        Data_Par            : out STD_LOGIC_VECTOR (11 downto 0));
end SER2PAR;

architecture Behavioral of SER2PAR is

    -- serial
    signal  Data_Ser        : STD_LOGIC;
    signal  Data_Ser_Delay  : STD_LOGIC;
    -- idelay
    signal  Cnt_Value_Out   : STD_LOGIC_VECTOR (4 downto 0);

    -- word align
    signal  Shift_Timer     : STD_LOGIC_VECTOR (4 downto 0);
    signal  Shift_Data      : STD_LOGIC_VECTOR (11 downto 0);
    -- chan align
    signal  Shift_Addr      : STD_LOGIC_VECTOR (2 downto 0);
    signal  Shift_Pixel_In  : STD_LOGIC_VECTOR (11 downto 0);
    -- ddr
    signal  Iddr_Q1         : STD_LOGIC;
    signal  Iddr_Q2         : STD_LOGIC;
    signal  Data_Q1         : STD_LOGIC;
    signal  Data_Q2         : STD_LOGIC;
    signal  Data_Q3         : STD_LOGIC;
    signal  Bitslip_Q1      : STD_LOGIC;
    signal  Bitslip_Q2      : STD_LOGIC;
    signal  Bitslip_Even    : STD_LOGIC;                                        -- detect the rising edge of bitslip, flip the level
    signal  Bitslip_Req     : STD_LOGIC;
    signal  Load_par        : STD_LOGIC;
    
    component c_shift_ram_0
    port (
        A                   : in  STD_LOGIC_VECTOR (2 downto 0);                -- shift numble of pixel
        D                   : in  STD_LOGIC_VECTOR (11 downto 0);               -- register data input
        CLK                 : in  STD_LOGIC;                                    -- Clk_Ref
        Q                   : out STD_LOGIC_VECTOR (11 downto 0));              -- register data output
    end component;

begin

    --********************************************
    -- LVDS receiver, change differential to serial
    ----------------------------------------------
    IBUFDS_inst : IBUFDS
    generic map (
        DIFF_TERM       => TRUE,                                                -- Enables the on-chip termination resistor (100¦¸).
        IBUF_LOW_PWR    => FALSE,                                               -- High-performance mode
        IOSTANDARD      => "LVDS_25")                                           -- 2.5V LVDS
    port map (
        O               => Data_Ser,                                            -- Buffer output
        I               => DATA_SER_P,                                          -- Diff_p buffer input (connect directly to top-level port)
        IB              => DATA_SER_N);                                         -- Diff_n buffer input (connect directly to top-level port)

    --**********************************
    -- 1 tap delay serial data 78ps
    ------------------------------------
    IDELAYE2_inst : IDELAYE2
    generic map (
        CINVCTRL_SEL            => "FALSE",                                     -- Disable dynamic clock inversion
        DELAY_SRC               => "DATAIN",                                    -- Delay input (IO pin input IDATAIN, internal FPGA logic DATAIN)
        HIGH_PERFORMANCE_MODE   => "TRUE",                                      -- Reduced jitter ("TRUE"), Reduced power ("FALSE")
        IDELAY_TYPE             => "VARIABLE",                                  -- FIXED, VARIABLE, VAR_LOAD, VAR_LOAD_PIPE
        IDELAY_VALUE            => 0,                                           -- Input delay tap setting (0-31)
        PIPE_SEL                => "FALSE",                                     -- Select pipelined mode, FALSE, TRUE
        REFCLK_FREQUENCY        => 200.0,                                       -- IDELAYCTRL clock input frequency in 200MHz
        SIGNAL_PATTERN          => "DATA")                                      -- DATA, CLOCK input signal
    port map (
        CNTVALUEOUT             => Cnt_Value_Out,                               -- 5-bit output: Counter value output
        DATAOUT                 => Data_Ser_Delay,                              -- 1-bit output: Delayed data output
        C                       => Clk_Ref,                                     -- 1-bit input: Clock input
        CE                      => Idelayce,                                    -- 1-bit input: Active high enable increment/decrement input
        CINVCTRL                => '0',                                         -- 1-bit input: Dynamic clock inversion input
        CNTVALUEIN              => "00000",                                     -- 5-bit input: Counter value input
        DATAIN                  => Data_Ser,                                    -- 1-bit input: Internal delay data input
        IDATAIN                 => '0',                                         -- 1-bit input: Data input from the I/O
        INC                     => '1',                                         -- 1-bit input: Increment / Decrement tap delay input
        LD                      => Idelayrst,                                   -- 1-bit input: Load IDELAY_VALUE input
        LDPIPEEN                => '0',                                         -- 1-bit input: Enable PIPELINE register to load data input
        REGRST                  => '0');                                        -- 1-bit input: Active-high reset tap-delay input

    --**************************************
    -- ddr clk sample double data rate input
    ----------------------------------------
    IDDR_inst : IDDR
    generic map (
        DDR_CLK_EDGE    => "SAME_EDGE_PIPELINED",                               -- "OPPOSITE_EDGE", "SAME_EDGE"
        INIT_Q1         => '0',                                                 -- Initial value of Q1: '0' or '1'
        INIT_Q2         => '0',                                                 -- Initial value of Q2: '0' or '1'
        SRTYPE          => "SYNC")                                              -- Set/Reset type: "SYNC" or "ASYNC"
    port map (
        Q1              => Iddr_Q1,                                             -- 1-bit output for positive edge of clock
        Q2              => Iddr_Q2,                                             -- 1-bit output for negative edge of clock
        C               => Clk_Ddr,                                             -- ddr clock input
        CE              => '1',                                                 -- 1-bit clock enable input
        D               => Data_Ser_Delay,                                      -- 1-bit DDR data input
        R               => '0',                                                 -- 1-bit reset
        S               => '0');                                                -- 1-bit set

   C1 : c_shift_ram_0
    port map (
        A               => Shift_Addr,
        D               => Shift_Pixel_In,
        CLK             => Clk_Ref,
        Q               => Data_Par);

    --********************************
    -- shift chan data with Shift_Addr
    ----------------------------------
    process(Clk_Ref, Rst_Ref) begin
        if (Rst_Ref = '0') then
            Shift_Addr      <= "000";
        elsif (Clk_Ref'event and Clk_Ref = '1') then
            if (Pixel_Shift = '1') then
                if (Shift_Addr = "111") then
                    Shift_Addr  <= "000";
                else
                    Shift_Addr  <= Shift_Addr + '1';
                end if;
            end if; 
        end if;
    end process;

    process(Clk_Ddr, Rst_Ddr) begin
        if (Rst_Ddr = '0') then
            Data_Q1         <= '0';
            Data_Q2         <= '0';
            Data_Q3         <= '0';
            Bitslip_Q1      <= '0';
            Bitslip_Q2      <= '0';
            Bitslip_Even    <= '0';
            Bitslip_Req     <= '0';
            Load_par        <= '0';
            Shift_Timer     <= (others => '1');
            Shift_Data      <= (others => '1');
            Shift_Pixel_In  <= (others => '0');
        elsif (Clk_Ddr'event and Clk_Ddr = '1') then
            Load_par        <= '0';
            -- rising edge detector on bitslip
            Data_Q1         <= Iddr_Q1;
            Data_Q2         <= Iddr_Q2;
            Data_Q3         <= Data_Q2;
            Bitslip_Q1      <= Bitslip;
            Bitslip_Q2      <= Bitslip_Q1;
            Shift_Timer     <= '0' & Shift_Timer (4 downto 1);

            ------------------------------------------------------------------------
            -- The receiver sampled 2 bits per clock period. At the rising edge of
            -- Clk_Ddr, these two bits are shifted into the shift_data.
            -- The actual bitslip shifts 2 bits at once.
            -- Therefore, every other bitslip request, the bitslip will not be executed.
            if (Bitslip_Q2 = '0' and Bitslip_Q1 = '1') then
                if (Bitslip_Even = '0') then
                    Bitslip_Even    <= '1';
                    Bitslip_Req     <= '1';
                else
                    Bitslip_Even    <= '0';
                end if;
            end if;
            ------------------------------------------------------------------------
            -- The timer will count the required number of clocks to receive one data word.
            -- (needs 6 times) At the end of a timer period, the data is copied from the
            -- shift register to the parallel data output.
            if (Shift_Timer = "00000") then
                Shift_Timer <= (others => '1');
                Load_par    <= '1';
            elsif (Shift_Timer = "00001") then
                if (Bitslip_Req = '1') then
                    Shift_Timer     <= (others => '1');
                    Bitslip_Req     <= '0';
                end if;
            end if;

            -- shift data when bitslip_even at high level
            if (Bitslip_Even = '1') then
                Shift_Data  <= Shift_Data (9 downto 0) & Data_Q3 & Data_Q1;
            else
                Shift_Data  <= Shift_Data (9 downto 0) & Data_Q1 & Data_Q2;
            end if;

            -- copy shift register to parallel data output
            if (Load_par = '1') then
                Shift_Pixel_In  <= Shift_Data;
            end if;

        end if;
    end process;
end Behavioral;