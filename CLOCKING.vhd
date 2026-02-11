----------------------------------------------------------------------------------
-- Company:         CIOMP
-- Engineer:        WangZheng
-- Create Date:     2025/02/21 09:00:58
-- Module Name:     CLOCKING - Behavioral
-- Project Name:    CH4_G400
-- Target Devices:  xc7k325tffg900-2
-- Tool versions:   Vivado 2018.3
-- Description:     Generate clock and reset signal for each module.
--                  Clk_Ref      25MHz       Rst_Ref_n
--                  Clk_Sys      80MHz       Rst_Sys_n
--                  Clk_Ddr      150MHz      Rst_Ddr_n
--                  Clk_Delay    200MHz
--                  Clk_Cmos     300MHz
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

entity CLOCKING is
    port (
        -- CLOCKING_pin
        FPGA_CLK80M                 : in  STD_LOGIC;                            -- FPGA input clk 80MHz
        ---------OTHERS---------
        Clk_Ref                     : out STD_LOGIC;                            -- cmos main clk 25MHz, same as CLK_PIX in datasheet
        Rst_Ref_n                   : out STD_LOGIC;
        Clk_Sys                     : out STD_LOGIC;                            -- system clk 80MHz
        Rst_Sys_n                   : out STD_LOGIC;
        Clk_100M                    : out STD_LOGIC;
        Rst_100M_n                  : out STD_LOGIC;
        Clk_Ddr                     : out STD_LOGIC;                            -- cmos sample ddr clk, 150MHz
        Rst_Ddr_n                   : out STD_LOGIC;
        Clk_300M                    : out STD_LOGIC);
end CLOCKING;

architecture Behavioral of CLOCKING is

    -- for generating clk
    signal  Clk_80M_Bufg            : STD_LOGIC;
    signal  Clk_25M_Int             : STD_LOGIC;
    signal  Clk_80M_Int             : STD_LOGIC;
    signal  Clk_100M_Int            : STD_LOGIC;
    signal  Clk_150M_Int            : STD_LOGIC;
    signal  Clk_200M_Int            : STD_LOGIC;
    signal  Clk_300M_Int            : STD_LOGIC;
    -- for generating rst
    signal  Rst_Mmcm                : STD_LOGIC := '0';
    signal  Rst_Int                 : STD_LOGIC;
    signal  Rst_Int_r               : STD_LOGIC;
    signal  Rst_25M_Int             : STD_LOGIC;
    signal  Rst_80M_Int             : STD_LOGIC;
    signal  Rst_100M_Int            : STD_LOGIC;
    signal  Rst_150M_Int            : STD_LOGIC;
    signal  Rst_200M_Int            : STD_LOGIC;
    signal  Rst_Idelayctrl          : STD_LOGIC;
    signal  Mmcm_Locked             : STD_LOGIC;
    signal  Mmcm_Locked_r1          : STD_LOGIC := '0';
    signal  Mmcm_Locked_r2          : STD_LOGIC := '0';
    signal  Dec_En                  : STD_LOGIC := '0';
    -- cnt
    signal  rst_cnt1                : integer range 0 to 99;
    signal  rst_cnt2                : integer range 0 to 99;
    signal  rst_cnt3                : integer range 0 to 99;
    signal  rst_cnt4                : integer range 0 to 99;
    signal  rst_cnt5                : integer range 0 to 99;
    signal  det_cnt_1us             : integer range 0 to 99 := 0;
    signal  det_cnt_1ms             : integer range 0 to 999 := 0;
    signal  det_cnt_rst             : integer range 0 to 99 := 0;

    component clk_wiz_0
    port (
        clk_in1                     : in  STD_LOGIC;
        clk_out1                    : out STD_LOGIC;
        clk_out2                    : out STD_LOGIC;
        clk_out3                    : out STD_LOGIC;
        clk_out4                    : out STD_LOGIC;
        clk_out5                    : out STD_LOGIC;
        clk_out6                    : out STD_LOGIC;
        reset                       : in  STD_LOGIC;
        locked                      : out STD_LOGIC);
    end component;

begin

    Clk_80M_Bufg    <= FPGA_CLK80M;

    U11 : clk_wiz_0
    port map (
        clk_in1         => Clk_80M_Bufg,
        clk_out1        => Clk_25M_Int,
        clk_out2        => Clk_80M_Int,
        clk_out3        => Clk_100M_Int,
        clk_out4        => Clk_150M_Int,
        clk_out5        => Clk_200M_Int,
        clk_out6        => Clk_300M_Int,
        reset           => Rst_Mmcm,
        locked          => Mmcm_Locked);                                        -- Rst_Int is low valid, Mmcm_locked is high when the Mmcm is ready

    --********************************************
    -- generate global system clk
    ----------------------------------------------
    Clk_Ref     <= Clk_25M_Int;
    Clk_Sys     <= Clk_80M_Int;
    Clk_100M    <= Clk_100M_Int;
    Clk_Ddr     <= Clk_150M_Int;
    Clk_300M    <= Clk_300M_Int;

    --********************************************
    -- generate rst
    ----------------------------------------------
    process (Clk_80M_Bufg, Mmcm_Locked) begin
        if (Mmcm_Locked = '0') then
            Rst_Int     <= '0';
            Rst_Int_r   <= '0';
        elsif (Clk_80M_Bufg'event and Clk_80M_Bufg = '1') then
            Rst_Int     <= '1';
            Rst_Int_r   <= Rst_Int;
        end if;
    end process;

    --25MHz
    process (Clk_25M_Int, Rst_Int_r) begin
        if (Rst_Int_r = '0') then
            rst_cnt1    <= 0;
            Rst_25M_Int <= '0';
        elsif (Clk_25M_Int'event and Clk_25M_Int = '1') then
            if (rst_cnt1 = 79) then
                rst_cnt1    <= 79;
                Rst_25M_Int <= '1';
            else
                rst_cnt1    <= rst_cnt1 + 1;
                Rst_25M_Int <= '0';
            end if;
        end if;
    end process;

    --80MHz
    process (Clk_80M_Int, Rst_Int_r) begin
        if (Rst_Int_r = '0') then
            rst_cnt5    <= 0;
            Rst_80M_Int <= '0';
        elsif (Clk_80M_Int'event and Clk_80M_Int = '1') then
            if (rst_cnt5 = 79) then
                rst_cnt5    <= 79;
                Rst_80M_Int <= '1';
            else
                rst_cnt5    <= rst_cnt5 + 1;
                Rst_80M_Int <= '0';
            end if;
        end if;
    end process;

    --100MHz
    process (Clk_100M_Int, Rst_Int_r) begin
        if (Rst_Int_r = '0') then
            rst_cnt2        <= 0;
            Rst_100M_Int    <= '0';
        elsif (Clk_100M_Int'event and Clk_100M_Int = '1') then
            if (rst_cnt2 = 79) then
                rst_cnt2        <= 79;
                Rst_100M_Int    <= '1';
            else
                rst_cnt2        <= rst_cnt2 + 1;
                Rst_100M_Int    <= '0';
            end if;
        end if;
    end process;

    --150MHz
    process (Clk_150M_Int, Rst_Int_r) begin
        if (Rst_Int_r = '0') then
            rst_cnt3        <= 0;
            Rst_150M_Int    <= '0';
        elsif (Clk_150M_Int'event and Clk_150M_Int = '1') then
            if (rst_cnt3 = 79) then
                rst_cnt3        <= 79;
                Rst_150M_Int    <= '1';
            else
                rst_cnt3        <= rst_cnt3 + 1;
                Rst_150M_Int    <= '0';
            end if;
        end if;
    end process;

    --200MHz
    process (Clk_200M_Int, Rst_Int_r) begin
        if (Rst_Int_r = '0') then
            rst_cnt4        <= 0;
            Rst_200M_Int    <= '0';
        elsif (Clk_200M_Int'event and Clk_200M_Int = '1') then
            if (rst_cnt4 = 79) then
                rst_cnt4        <= 79;
                Rst_200M_Int    <= '1';
            else
                rst_cnt4        <= rst_cnt4 + 1;
                Rst_200M_Int    <= '0';
            end if;
        end if;
    end process;

    S1 : BUFG
    port map(
        I   => Rst_25M_Int,
        O   => Rst_Ref_n);

    S2 : BUFG
    port map(
        I   => Rst_80M_Int,
        O   => Rst_Sys_n);

    S3 : BUFG
    port map(
        I   => Rst_100M_Int,
        O   => Rst_100M_n);

    S4 : BUFG
    port map(
        I   => Rst_150M_Int,
        O   => Rst_Ddr_n);

    S5 : BUFG
    port map(
        I   => Rst_200M_Int,
        O   => Rst_Idelayctrl);

    S6 : IDELAYCTRL                                                             -- 200 MHz -> ~78ps/tap
    port map (
        RDY         => open,                                                    -- 1-bit output indicates validity of the REFCLK
        REFCLK      => Clk_200M_Int,                                            -- 1-bit reference clock input 200MHz
        RST         => not Rst_Idelayctrl);                                     -- 1-bit reset input, '1' valid

    --********************************************
    -- Detect pll
    ----------------------------------------------
    --1ms
    process (Clk_80M_Bufg) begin
        if (Clk_80M_Bufg'event and Clk_80M_Bufg = '1') then
            if (det_cnt_1us = 79) then              --1us
                det_cnt_1us <= 0;
                if (det_cnt_1ms = 999) then
                    det_cnt_1ms <= 0;
                    Dec_En      <= '1';             --1ms
                else
                    det_cnt_1ms <= det_cnt_1ms + 1;
                    Dec_En      <= '0';
                end if;
            else
                det_cnt_1us <= det_cnt_1us + 1;
            end if;
        end if;
    end process;

    process (Clk_80M_Bufg) begin
        if (Clk_80M_Bufg'event and Clk_80M_Bufg = '1') then
            Mmcm_Locked_r1  <= Mmcm_Locked;
            Mmcm_Locked_r2  <= Mmcm_Locked_r1;
        end if;
    end process;

    process (Clk_80M_Bufg) begin
        if (Clk_80M_Bufg'event and Clk_80M_Bufg = '1') then
            if (Dec_En = '1') then
                if (Mmcm_Locked_r2 = '0') then      --pll lost control
                    if (det_cnt_rst = 69) then
                        det_cnt_rst <= 69;
                    elsif (det_cnt_rst >= 60 and det_cnt_rst <= 65) then  --reset pll Rst for 6 cycle
                        Rst_Mmcm    <= '1';
                        det_cnt_rst <= det_cnt_rst + 1;
                    else
                        Rst_Mmcm    <= '0';
                        det_cnt_rst <= det_cnt_rst + 1;
                    end if;
                else
                    det_cnt_rst <= 0;
                end if;
            else
                det_cnt_rst <= 0;
            end if;
        end if;
    end process;
end Behavioral;