
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Time_Double2Int is
	port(
		Clk					: in std_logic;
		time_in_second 	: in  std_logic_vector(63 downto 0);
		second 				: out std_logic_vector(31 downto 0);
		millisecond 		: out std_logic_vector(9 downto 0)
	);
end Time_Double2Int;


architecture arch of Time_Double2Int is
	constant INT_PART_NUM 	: integer := 32;
	constant FRAC_PART_NUM 	: integer := 16;
	signal fix_time 		: STD_LOGIC_VECTOR ( 47 downto 0 );
	
	signal frac_part    	: UNSIGNED(14 downto 0);
	signal mul_res		  	: UNSIGNED(29 downto 0);
	signal div_res		  	: UNSIGNED(29 downto 0);
	signal tvalid 			: std_logic;
	signal tready        : std_logic;
	
	component double2fix is
	Port ( 
		aclk : in STD_LOGIC;
		s_axis_a_tvalid : in STD_LOGIC;
		s_axis_a_tready : out STD_LOGIC;
		s_axis_a_tdata : in STD_LOGIC_VECTOR ( 63 downto 0 );
		m_axis_result_tvalid : out STD_LOGIC;
		m_axis_result_tready : in STD_LOGIC;
		m_axis_result_tdata : out STD_LOGIC_VECTOR ( 47 downto 0 )
	);
	end component;
begin
	-- 调用Float IP将double转换为定点数
	
	tvalid <= '1';
	tready <= '1';
	U1 : double2fix 
	Port map( 
		aclk 					=> Clk,
		s_axis_a_tvalid 	=> tvalid,
		s_axis_a_tready 	=> open,
		s_axis_a_tdata 	=> time_in_second,
		m_axis_result_tvalid => open,
		m_axis_result_tready => tready,
		m_axis_result_tdata  => fix_time
	);
	
	-- 分离整数部分和小数部分
	frac_part    <= UNSIGNED(fix_time(14 downto 0));
	
	-- 输出整秒数
	second <= fix_time(46 downto 15);
	mul_res <= (frac_part * 1000) ; 
	div_res <= (mul_res srl 10);
	millisecond <= STD_LOGIC_VECTOR(mul_res(9 downto 0));
end arch;