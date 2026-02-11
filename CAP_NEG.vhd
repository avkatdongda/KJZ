
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;

entity CAP_NEG is
   port(
      Clk : in std_logic;
      Din : in std_logic;
      Dout : out std_logic
   );
end entity;

ARCHITECTURE struct OF CAP_NEG IS
   signal Din_r : std_logic;
begin
   process(Clk) begin
      if rising_edge(Clk) then
        Din_r <= Din;
      end if;
   end process;
   
   process(Clk) begin
      if rising_edge(Clk) then
         if(Din = '0') and (Din_r = '1') then
            Dout <= '1';
         else 
            Dout <= '0';
         end if;
      end if;
   end process;
end struct;