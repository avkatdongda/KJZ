----------------------------------------------------------------------------------
-- Company: CIOMP
-- Engineer: WangZheng
-- Create Date:    21:40:20 05/23/2019
-- Module Name:    FALL_EDGE - Behavioral
-- Project Name:   SEN_IMA
-- Target Devices: Virtex-4 xqr4vsx55-10cf1140
-- Tool versions:  ISE 14.2
-- Description:    asynchronous signal edge detect synchronizer
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity FALL_EDGE is
    port (
        Clk     : in  STD_LOGIC;                                                -- clock
        Rst     : in  STD_LOGIC;                                                -- reset
        D_a     : in  STD_LOGIC;                                                -- input asynchronous signal
        Q_s_F   : out STD_LOGIC);                                               -- output '1' pulse when falling edge pulse
end FALL_EDGE;

architecture Behavioral of FALL_EDGE is
    signal   Q1 : STD_LOGIC := '0';                                             -- 1st FFD Q out
    signal   Q2 : STD_LOGIC := '0';                                             -- 2nd FFD Q out
    signal   Q3 : STD_LOGIC := '0';                                             -- 3rd FFD Q out
begin
    -- Two FFD in series in the clk domain
    process (Clk, Rst) begin
        if (Rst = '0') then
            Q1    <= '0';
            Q2    <= '0';
            Q3    <= '0';
            Q_s_F <= '0';
        elsif (Clk'event and Clk = '1') then
            Q1    <= D_a;
            Q2    <= Q1;
            Q3    <= Q2;
            -- falling edge
            if (Q2 = '0' and Q3 = '1') then
                Q_s_F <= '1';
            else
                Q_s_F <= '0';
            end if;
        end if;
    end process;
end Behavioral;