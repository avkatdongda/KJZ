--
-- VHDL Architecture TEST.LOCK_DETECT.arch_name
--
-- Created:
--          by - zb5700.UNKNOWN (LAPTOP-IBGQUTEL)
--          at - 10:57:22 2023/02/ 6
--
-- using Mentor Graphics HDL Designer(TM) 2012.1 (Build 6)
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;

ENTITY LOCK_DETECT_SINGLE IS
	port(
		g_FPGA_Clk  : in std_logic;
		PLL_Locked : in std_logic;
		PLL_Rst : out std_logic
	);
END ENTITY LOCK_DETECT_SINGLE;

--
ARCHITECTURE arch_name OF LOCK_DETECT_SINGLE IS
	signal Cnt_Det_1us : integer range 0 to 99;
	signal Cnt_Det_1ms : integer range 0 to 999;
	signal PLL_Cnt_Det_Rst : integer range 0 to 127;
	signal Cnt_Det : integer range 0 to 511;
	signal En_Det_n : std_logic;
BEGIN

-- eb2 2                                        
process(g_FPGA_Clk) begin
	if rising_edge(g_FPGA_Clk) then
		if(Cnt_Det_1us >= 99) then
			Cnt_Det_1us <= 0;
		else
			Cnt_Det_1us <= Cnt_Det_1us + 1;
		end if;
		
		if(Cnt_Det_1us = 99) then
			if(Cnt_Det_1ms >= 999) then
				Cnt_Det_1ms <= 0;
			else
				Cnt_Det_1ms <= Cnt_Det_1ms + 1;
			end if;
		end if;
		
		if(Cnt_Det_1us = 99)and(Cnt_Det_1ms = 999) then
			if(Cnt_Det >= 511) then
				Cnt_Det <= 0;
			else
				Cnt_Det <= Cnt_Det + 1;
			end if;
		end if;
		
		case Cnt_Det is
			when 5 => 
				En_Det_n <= '0';
			when others => 
				En_Det_n <= '1';
		end case;
	end if;
end process;

------------------------------------------------------------------------
process(g_FPGA_Clk) begin
	if rising_edge(g_FPGA_Clk) then
		if(En_Det_n = '0') then
			if(PLL_Locked = '0') then
				if(PLL_Cnt_Det_Rst >= 127) then
					PLL_Cnt_Det_Rst <= 127;
				else
					PLL_Cnt_Det_Rst <= PLL_Cnt_Det_Rst + 1;
				end if;
			else
				PLL_Cnt_Det_Rst <= 0;
			end if;
		else
			PLL_Cnt_Det_Rst <= 0;
		end if;
	end if;
end process;

process(g_FPGA_Clk) begin
	if rising_edge(g_FPGA_Clk) then
		case PLL_Cnt_Det_Rst is
			when 7 to 12 =>
				PLL_Rst <= '1';
			when others =>
				PLL_Rst <= '0';
		end case;
	end if;
end process;




END ARCHITECTURE arch_name;

