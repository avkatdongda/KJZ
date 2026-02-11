library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity Time_Int2Double is
	port(
		Clk					: in std_logic;
		Reset					: in std_logic;
		second 				: in std_logic_vector(31 downto 0);
		millisecond 		: in std_logic_vector(9 downto 0);
		time_in_second 	: out  std_logic_vector(63 downto 0)
	);
end Time_Int2Double;

architecture arch of Time_Int2Double is
	constant INT_PART 	: integer := 32;
	constant FRAC_PART 	: integer := 10;
	


component Divide_By1000 is
    Port (
        clk : in STD_LOGIC;
        rst : in STD_LOGIC;
        input : in signed(20 downto 0);
        output : out signed(20 downto 0)
    );
end component;

component fix2double is
  Port ( 
    aclk : in STD_LOGIC;
    s_axis_a_tvalid : in STD_LOGIC;
    s_axis_a_tready : out STD_LOGIC;
    s_axis_a_tdata : in STD_LOGIC_VECTOR ( 47 downto 0 );
    m_axis_result_tvalid : out STD_LOGIC;
    m_axis_result_tready : in STD_LOGIC;
    m_axis_result_tdata : out STD_LOGIC_VECTOR ( 63 downto 0 )
  );

end component;
	signal tvallid 			: std_logic;
	signal second_fixed 		: signed(42 downto 0);
	signal millisecond_fixed : signed(10 downto 0);  
	signal mul_res 			: signed(20 downto 0);
	signal div_res 			: signed(20 downto 0);
	signal total_fixed 		: signed(47 downto 0);
	signal total_fixed_std  : std_logic_vector(47 downto 0);
	signal tready				: std_logic;
begin
	second_fixed      <= ( resize(signed(second), 43) sll 10);      -- 33
	millisecond_fixed <= signed('0' & millisecond);  -- 10u to 11s
	mul_res <= ( resize(millisecond_fixed,21) sll 10);            -- 11s to 21s
	
	U1 : Divide_By1000
    Port map(
        clk 		=> Clk,
        rst 		=> Reset,
        input 		=> mul_res,
        output 	=> div_res
    );

	
	total_fixed <= resize(div_res, 48) + resize(second_fixed, 48);   
	total_fixed_std <= STD_LOGIC_VECTOR(total_fixed);
	tvallid <= '1';
	tready  <= '1';
	U2 : fix2double
  Port map( 
    aclk 						=> Clk,
    s_axis_a_tvalid 			=> tvallid,
    s_axis_a_tready 			=> open,
    s_axis_a_tdata 			=> total_fixed_std,
    m_axis_result_tvalid 	=> open,
    m_axis_result_tready 	=> tready,
    m_axis_result_tdata  	=> time_in_second
  );


end arch;