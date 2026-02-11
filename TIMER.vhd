----------------------------------------------------------------------------------
-- Company:        CIOMP
-- Engineer: 		 BIN ZHANG
-- 
-- Create Date:    15:21:09 06/05/2020
-- Design Name: 	 HIGH RESOLUTION IMAGING SCIENCE EXPERIMENT
-- Module Name:    TIMER - Behavioral 
-- Project Name: 	 CAMERA
-- Target Devices: SPARTAN 3
-- Tool versions:  VIVADO
-- Description: 
--						 TIME MANAGEMENT MODULE
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
-- 
----------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.numeric_std.all;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY TIMER IS
   PORT( 
      Clk        : IN     std_logic;
      Reset      : IN     std_logic;
      TICK_START : IN     std_logic;                       --对时脉冲
      TICK_SEC   : IN     std_logic_vector (31 DOWNTO 0);  --对时秒值
      TICK_MS    : IN     std_logic_vector (11 DOWNTO 0);  --对时毫秒值
      TICK_NS    : IN     std_logic_vector (19 DOWNTO 0);  --对时纳秒值
      CALIB_SEC  : OUT    std_logic_vector (31 DOWNTO 0);  --校时秒值
      CALIB_MS   : OUT    std_logic_vector (11 DOWNTO 0);
      CALIB_NS   : OUT    std_logic_vector (19 DOWNTO 0)
   );

-- Declarations

END TIMER ;

architecture arch of TIMER is



--------------------------------------------------------
--- 毫秒计数器
--------------------------------------------------------
signal End_CALIB_MS : std_logic;
signal End_CALIB_NS : std_logic;
signal CALIB_MS_b   : std_logic_vector(11 downto 0);
signal CALIB_SEC_b  : std_logic_vector(31 downto 0);
signal CALIB_NS_b   : std_logic_vector(19 downto 0);



begin

--------------------------------------------------------
--- 纳秒计数器
--------------------------------------------------------

End_CALIB_NS <= '1' when (CALIB_NS_b >= conv_std_logic_vector(999990, 20)) else '0';

process(Reset, Clk) begin
   if(Reset = '1') then
      CALIB_NS_b <= (others => '0');
   elsif rising_edge(Clk) then
      if(TICK_START = '1') then
         CALIB_NS_b <= TICK_NS;
      else
         if (End_CALIB_NS = '1') then
            CALIB_NS_b <= (others => '0');
         else
            CALIB_NS_b <= CALIB_NS_b + conv_std_logic_vector(10, 20);
         end if;
      end if;
   end if;
end process;

process(Reset, Clk) begin
   if(Reset = '1') then
      CALIB_NS <= (others => '0');
   elsif rising_edge(Clk) then
      CALIB_NS <= CALIB_NS_b;
   end if;
end process;

--------------------------------------------------------
--- 毫秒计数器
--------------------------------------------------------

End_CALIB_MS <= '1' when (CALIB_MS_b = conv_std_logic_vector(999, 12)) else '0';

process(Reset, Clk) begin
   if(Reset = '1') then
      CALIB_MS_b <= (others => '0');
   elsif rising_edge(Clk) then
      if(TICK_START = '1') then
         CALIB_MS_b <= TICK_MS;
      elsif (End_CALIB_NS = '1') then
         if (End_CALIB_MS = '1') then
            CALIB_MS_b <= (others => '0');
         else
            CALIB_MS_b <= CALIB_MS_b + conv_std_logic_vector(1, 12);
         end if;
      end if;
   end if;
end process;

process(Reset, Clk) begin
   if(Reset = '1') then
      CALIB_MS <= (others => '0');
   elsif rising_edge(Clk) then
      CALIB_MS <= CALIB_MS_b;
   end if;
end process;
--------------------------------------------------------
--- 秒计数器
--------------------------------------------------------
process(Reset, Clk) begin
   if(Reset = '1') then
      CALIB_SEC_b <= (others => '0');
   elsif rising_edge(Clk) then
      if(TICK_START = '1') then
         CALIB_SEC_b <= TICK_SEC;
      elsif ((End_CALIB_NS = '1') and (End_CALIB_MS = '1'))  then
         CALIB_SEC_b <= CALIB_SEC_b + X"00000001";
      end if;
   end if;
end process;


process(Reset, Clk) begin
   if(Reset = '1') then
      CALIB_SEC <= (others => '0');
   elsif rising_edge(Clk) then
      CALIB_SEC <= CALIB_SEC_b;
   end if;
end process;



end arch;






