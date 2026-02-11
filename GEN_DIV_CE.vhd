----------------------------------------------------------------------------------
-- Company: CIOMP
-- Engineer: WangZheng
-- Create Date:    20:24:43 10/10/2017 
-- Module Name:    GEN_DIV_CE - Behavioral 
-- Project Name:   SEN_IMA
-- Target Devices: Virtex-4 xc4vsx55-12ff1148
-- Tool versions:  ISE 14.7
-- Description:    产生1M UART时钟
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;



entity GEN_DIV_CE is
    generic (
        DIV     : positive := 80);
    port (
        Clk    : in  STD_LOGIC;
        Reset_n    : in  STD_LOGIC;
        CE      : in  STD_LOGIC;
        DIV_CE  : out STD_LOGIC);
end GEN_DIV_CE;

architecture Behavioral of GEN_DIV_CE is
    signal cnt : integer range 0 to DIV - 1 := 0;
begin
    process (Clk, Reset_n)
    begin
        if (Reset_n = '0') then
            cnt     <= 0;
            DIV_CE  <= '0';
        elsif (Clk'event and Clk = '1') then
            if (CE = '1') then
                if (cnt = (DIV - 1)) then
                    cnt     <= 0;
                    DIV_CE  <= '1';
                else
                    cnt     <= cnt + 1;
                    DIV_CE  <= '0';
                end if;
            else
                DIV_CE  <= '0';
            end if;
        end if;
    end process;
end Behavioral;