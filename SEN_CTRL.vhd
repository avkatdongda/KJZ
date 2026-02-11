----------------------------------------------------------------------------------
-- Company:         CIOMP
-- Engineer:        WangZheng
-- Create Date:     2025/02/22 09:00:58
-- Module Name:     SEN_CTRL - Behavioral
-- Project Name:    CH4_G400
-- Target Devices:  xc7k325tffg900-2
-- Tool Versions:   Vivado 2018.3
-- Description:     generate the sensor control signals
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

entity SEN_CTRL is
    generic (
        Cms_Delay                   : STD_LOGIC_VECTOR (11 downto 0):= X"001"); -- 1ms
    port (
        ---------pin---------
        SEN_RST_N                   : out STD_LOGIC;                            -- the rst of sensor, low level valid
        ---------CLOCKING---------
        Clk_Ref                     : in  STD_LOGIC;                            -- sensor main clk 25MHz, same as CLK_PIX in datasheet
        Rst_Ref                     : in  STD_LOGIC;                            -- Clk_Ref correspond rst signal
        ---------TOP---------
        Power_On                    : in  STD_LOGIC;                            -- sensor power supply, 1 power on, 0 power off
        Sen_Supply1                 : out STD_LOGIC;                            -- sensor supply1 signal
        Sen_Supply2                 : out STD_LOGIC;                            -- sensor supply2 signal
        Sen_Supply3                 : out STD_LOGIC;                            -- sensor supply3 signal 3.3V
        Set_Pulse                   : in  STD_LOGIC;                            -- the set signal pulse
        Shoot_Pulse                 : in  STD_LOGIC;                            -- the shoot signal pulse
        Image_Mode                  : in  STD_LOGIC_VECTOR (7 downto 0);        -- set image mode 11H shoot, 22H selfcheck1, 33H selfcheck2
        Exposure_Time               : in  STD_LOGIC_VECTOR (15 downto 0);       -- Exposure_Line 0000H~FFFFH default 0100H
        Gain_Value                  : in  STD_LOGIC_VECTOR (7 downto 0);        -- gain value, default odd 0100, even 0111
        Sen_Status                  : out STD_LOGIC_VECTOR (7 downto 0);        -- the status of sensor, 00H none, 01H training, 10H shooting
        -------SEN_SPI---------
        Gain_Odd                    : out STD_LOGIC_VECTOR (2 downto 0);        -- low gain default 100 1.29x
        Gain_Even                   : out STD_LOGIC_VECTOR (2 downto 0);        -- high gain default 111 7.25x
        Cmd_Wr_Spi                  : out STD_LOGIC;                            -- the command of writing spi
        Cmd_Rd_Spi                  : out STD_LOGIC;                            -- the command of reading spi
        Spi_Wr_Done                 : in  STD_LOGIC;                            -- the finish signal of writing spi, '1' is valid
        Spi_Rd_Done                 : in  STD_LOGIC;                            -- the finish signal of reading spi, '1' is valid
        -------SEN_DRIVE---------
        Frame_Circle                : in  STD_LOGIC_VECTOR (7 downto 0);        -- count the circle of 2048 rows
        Cmd_Drive                   : out STD_LOGIC;                            -- the command of driving ctrl signal
        Cmd_Check1                  : out STD_LOGIC;                            -- the command of check1 signal
        Exposure_Line               : out STD_LOGIC_VECTOR (15 downto 0);       -- Exposure_Line 0000H~FFFFH default 0100H
        -------IMA_GEN---------
        Cmd_Check2                  : out STD_LOGIC;                            -- the command of check2 signal
        Frame_Circle_S              : in  STD_LOGIC_VECTOR (7 downto 0);        -- count the circle of 2048 rows
        -------TRAINING---------
        Train_Done                  : in  STD_LOGIC;                            -- the sign of training completion
        Cmd_Train                   : out STD_LOGIC);                           -- the command of starting training
end SEN_CTRL;

architecture Behavioral of SEN_CTRL is

    -- cnt
    signal  delay_cnt               : integer range 0 to 100000;                -- 4ms
    signal  spi_delay_cnt           : integer range 0 to 100000;                -- 4ms
    signal  rst_delay_cnt           : integer range 0 to 100;                   -- 4us
    signal  round_cnt               : STD_LOGIC_VECTOR (11 downto 0);           -- n*1ms
    -- reg
    signal  Power_On_R              : STD_LOGIC;
    signal  Power_On_F              : STD_LOGIC;
    signal  Set_Pulse_R             : STD_LOGIC;
    signal  Shoot_Pulse_R           : STD_LOGIC;
    signal  Image_Mode_r            : STD_LOGIC_VECTOR (7 downto 0);
    signal  Set_Req                 : STD_LOGIC;
    -- fsm
    type    Fsm_Ctrl is (S_Idle, S_Power_Off, S_Power_Delay, S_Supply_Delay, S_Sen_Rst, S_Spi_Wr, S_Spi_Delay, S_Training, S_Spi_Read, S_Set, S_Spi_Wr2, S_Spi_Delay2, S_Spi_Read2, S_Shoot, S_Sen_Drive, S_Check1, S_Check2, S_Train_Delay);
    signal  state : Fsm_Ctrl;

    -- attribute mark_debug    : string;
    -- attribute mark_debug    of Sen_Status               : signal is "true";
    -- attribute mark_debug    of Train_Done               : signal is "true";
    -- attribute mark_debug    of Cmd_Train                : signal is "true";
    -- attribute mark_debug    of Spi_Wr_Done              : signal is "true";
    -- attribute mark_debug    of Spi_Rd_Done              : signal is "true";
    -- attribute mark_debug    of Frame_Circle             : signal is "true";
    -- attribute mark_debug    of Cmd_Drive                : signal is "true";
    -- attribute mark_debug    of state                    : signal is "true";
    -- attribute mark_debug    of SEN_RST_N                : signal is "true";

    component RISE_EDGE
    port(
        Clk                 : in  STD_LOGIC;
        Rst                 : in  STD_LOGIC;
        D_a                 : in  STD_LOGIC;
        Q_s_R               : out STD_LOGIC);
    end component;

    component FALL_EDGE
    port(
        Clk                 : in  STD_LOGIC;
        Rst                 : in  STD_LOGIC;
        D_a                 : in  STD_LOGIC;
        Q_s_F               : out STD_LOGIC);
    end component;

begin

    -- Rising Edge Pulse of Power_On Set_Pulse Shoot_Pulse
    U210 : RISE_EDGE
    port map (
        Clk         => Clk_Ref,
        Rst         => Rst_Ref,
        D_a         => Power_On,
        Q_s_R       => Power_On_R);

    U211 : RISE_EDGE
    port map (
        Clk         => Clk_Ref,
        Rst         => Rst_Ref,
        D_a         => Set_Pulse,
        Q_s_R       => Set_Pulse_R);

    U212 : RISE_EDGE
    port map (
        Clk         => Clk_Ref,
        Rst         => Rst_Ref,
        D_a         => Shoot_Pulse,
        Q_s_R       => Shoot_Pulse_R);

    U213 : FALL_EDGE
    port map (
        Clk         => Clk_Ref,
        Rst         => Rst_Ref,
        D_a         => Power_On,
        Q_s_F       => Power_On_F);

    --*****************************************************
    -- recognize Image_Mode, generate control signal
    ------------------------
    process (Clk_Ref, Rst_Ref) begin
        if (Rst_Ref = '0') then
            state               <= S_Idle;
            delay_cnt           <= 0;
            spi_delay_cnt       <= 0;
            rst_delay_cnt       <= 0;
            Sen_Supply1         <= '0';
            Sen_Supply2         <= '0';
            Sen_Supply3         <= '0';
            SEN_RST_N           <= '0';
            Cmd_Wr_Spi          <= '0';
            Cmd_Rd_Spi          <= '0';
            Cmd_Drive           <= '0';
            Cmd_Check1          <= '0';
            Cmd_Check2          <= '0';
            Cmd_Train           <= '0';
            Sen_Status          <= X"00";
            Gain_Odd            <= "100";
            Gain_Even           <= "111";
            Exposure_Line       <= X"0064";
            Image_Mode_r        <= X"11";
            round_cnt           <= (others => '0');
            Set_Req             <= '0';
        elsif (Clk_Ref'event and Clk_Ref = '1') then
            case state is
                when S_Idle =>
                    if (Set_Req = '1') then
                        state       <= S_Set;
                        Set_Req     <= '0';
                    elsif (Power_On_R = '1') then
                        state       <= S_Power_Delay;
                        Sen_Supply3 <= '1';
                    elsif (Set_Pulse_R = '1') then
                        state       <= S_Set;
                    elsif (Shoot_Pulse_R = '1') then
                        state       <= S_Shoot;
                    elsif (Power_On_F = '1') then
                        state       <= S_Power_Off;
                    else
                        state   <= S_Idle;
                    end if;
                --*****************************************************
                -- power off
                ------------------------
                when S_Power_Off =>
                    state       <= S_Idle;
                    Sen_Supply1 <= '0';
                    Sen_Supply2 <= '0';
                    Sen_Supply3 <= '0';
                    SEN_RST_N   <= '0';
                --*****************************************************
                -- power up sequence
                ------------------------
                -- two cmos power delay (n+1)*1ms
                when S_Power_Delay =>
                    if (delay_cnt = 25000) then                                 -- delay 1ms
                        if (round_cnt = Cms_Delay) then
                            state       <= S_Supply_Delay;
                            round_cnt   <= (others => '0');
                        else
                            state       <= S_Power_Delay;
                            round_cnt   <= round_cnt + '1';
                        end if;
                        delay_cnt       <= 0;
                    else
                        state           <= S_Power_Delay;
                        delay_cnt       <= delay_cnt + 1;
                        Sen_Status      <= X"01";                               -- supply state
                    end if;
                -- supply1 delay
                when S_Supply_Delay =>
                    if (delay_cnt = 100000) then                                -- after supply1 stable, delay 4ms, next state S_Sen_Rst
                        state           <= S_Sen_Rst;
                        delay_cnt       <= 0;
                        Sen_Status      <= X"02";                               -- rst state
                    else
                        state           <= S_Supply_Delay;
                        delay_cnt       <= delay_cnt + 1;
                        Sen_Supply1     <= '1';
                    end if;
                -- sensor reset
                when S_Sen_Rst =>
                    if (rst_delay_cnt = 100) then                               -- after rst pull high, delay >2us
                        state           <= S_Spi_Wr;
                        Cmd_Wr_Spi      <= '1';
                        rst_delay_cnt   <= 0;
                    elsif (rst_delay_cnt >= 0 and rst_delay_cnt <= 35) then     -- low reset, delay >1us
                        state           <= S_Sen_Rst;
                        rst_delay_cnt   <= rst_delay_cnt + 1;
                        SEN_RST_N       <= '0';
                    else
                        state           <= S_Sen_Rst;
                        rst_delay_cnt   <= rst_delay_cnt + 1;
                        SEN_RST_N       <= '1';
                    end if;
                -- write spi register
                when S_Spi_Wr =>
                    if (Spi_Wr_Done = '1') then
                        state           <= S_Spi_Delay;
                    else
                        state           <= S_Spi_Wr;
                        Cmd_Wr_Spi      <= '0';
                        Sen_Status      <= X"03";                               -- spi state
                    end if;
                -- supply2 power on
                when S_Spi_Delay =>
                    if (spi_delay_cnt = 100000) then                            -- after write spi done, delay 4ms
                        state           <= S_Spi_Read;
                        Cmd_Rd_Spi      <= '1';
                        spi_delay_cnt   <= 0;
                    elsif (spi_delay_cnt = 2500) then                           -- after write spi done, delay 100us
                        state           <= S_Spi_Delay;
                        spi_delay_cnt   <= spi_delay_cnt + 1;
                        Sen_Supply2     <= '1';                                 -- supply2 power on
                    else
                        state           <= S_Spi_Delay;
                        spi_delay_cnt   <= spi_delay_cnt + 1;
                    end if;
                -- read spi register
                when S_Spi_Read =>
                    if (Spi_Rd_Done = '1') then
                        state           <= S_Train_Delay;
                        Cmd_Train       <= '1';
                    else
                        state           <= S_Spi_Read;
                        Cmd_Rd_Spi      <= '0';
                        Sen_Status      <= X"03";                               -- spi state
                    end if;
                -- train delay
                when S_Train_Delay =>
                    if (delay_cnt = 10) then                                    -- wait Train_Done downto 0
                        state           <= S_Training;
                        delay_cnt       <= 0;
                    else
                        state           <= S_Train_Delay;
                        delay_cnt       <= delay_cnt + 1;
                    end if;
                -- training
                when S_Training =>
                    if (Train_Done = '1') then
                        state           <= S_Idle;
                        Sen_Status      <= X"00";
                    else
                        state           <= S_Training;
                        Cmd_Train       <= '0';
                        Sen_Status      <= X"04";                               -- training state
                    end if;

                --*****************************************************
                -- set parameter
                ------------------------
                when S_Set =>
                    state           <= S_Spi_Wr2;
                    Image_Mode_r    <= Image_Mode;
                    Exposure_Line   <= Exposure_Time;
                    Gain_Odd        <= Gain_Value(6 downto 4);
                    Gain_Even       <= Gain_Value(2 downto 0);
                    Cmd_Wr_Spi      <= '1';

                -- write spi register
                when S_Spi_Wr2 =>
                    if (Spi_Wr_Done = '1') then
                        state           <= S_Spi_Delay2;
                        Sen_Status      <= X"00";
                    else
                        state           <= S_Spi_Wr2;
                        Cmd_Wr_Spi      <= '0';
                        Sen_Status      <= X"03";                               -- spi state
                    end if;

                -- spi delay
                when S_Spi_Delay2 =>
                    if (spi_delay_cnt = 100) then
                        state           <= S_Spi_Read2;
                        Cmd_Rd_Spi      <= '1';
                        spi_delay_cnt   <= 0;
                    else
                        state           <= S_Spi_Delay2;
                        spi_delay_cnt   <= spi_delay_cnt + 1;
                    end if;

                -- read spi register
                when S_Spi_Read2 =>
                    if (Spi_Rd_Done = '1') then
                        state           <= S_Idle;
                        Sen_Status      <= X"00";
                    else
                        state           <= S_Spi_Read2;
                        Cmd_Rd_Spi      <= '0';
                        Sen_Status      <= X"03";                               -- spi state
                    end if;

                --*****************************************************
                -- shoot
                ------------------------
                when S_Shoot =>
                    case Image_Mode_r is
                        when X"11" =>
                            state       <= S_Sen_Drive;                         -- shooting
                            Cmd_Check1  <= '0';
                            Cmd_Check2  <= '0';
                            Sen_Status  <= X"11";                               -- shoot state
                        when X"22" =>
                            state       <= S_Check1;                            -- output selfcheck1, sensor output 98E
                            Cmd_Drive   <= '0';
                            Cmd_Check2  <= '0';
                            Sen_Status  <= X"22";                               -- Check1 state
                        when X"33" =>
                            state       <= S_Check2;                            -- output selfcheck2, FPGA output accumulate data
                            Cmd_Drive   <= '0';
                            Cmd_Check1  <= '0';
                            Sen_Status  <= X"33";                               -- Check2 state
                        when others =>
                            Sen_Status  <= X"00";                               -- none state
                            state       <= S_Idle;
                    end case;
                -- drive the sensor, start shoot
                when S_Sen_Drive =>
                    if (Set_Pulse_R = '1') then
                        Set_Req <= '1';
                    end if;
                    
                    if (Frame_Circle = X"01") then                              -- shut down drive
                        state           <= S_Idle;
                        Cmd_Drive       <= '0';
                        Sen_Status      <= X"00";                               -- none state
                    else
                        state           <= S_Sen_Drive;
                        Cmd_Drive       <= '1';
                        Sen_Status      <= X"11";                               -- shoot state
                    end if;
                -- down the selfcheck1, sensor output 98E
                when S_Check1 =>
                    if (Frame_Circle = X"01") then                              -- shut down check1
                        state           <= S_Idle;
                        Cmd_Check1      <= '0';
                        Sen_Status      <= X"00";                               -- none state
                    else
                        state           <= S_Check1;
                        Cmd_Check1      <= '1';
                        Sen_Status      <= X"22";                               -- Check1 state
                    end if;
                -- down the selfcheck2, FPGA output accumulate data
                when S_Check2 =>
                    if (Frame_Circle_S =  X"01") then                           -- shut down check2
                        state           <= S_Idle;
                        Cmd_Check2      <= '0';
                        Sen_Status      <= X"00";                               -- none state
                    else
                        state           <= S_Check2;
                        Cmd_Check2      <= '1';
                        Sen_Status      <= X"33";                               -- Check2 state
                    end if;

                when others =>
                    state   <= S_Idle;
            end case;
        end if;
    end process;
end Behavioral;