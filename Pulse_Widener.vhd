library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Pulse_Widener is
    Generic (
        PULSE_WIDTH : positive := 5 -- 输出负脉冲宽度，可根据需要修改
    );
    Port (
        clk     : in  STD_LOGIC;
        rst     : in  STD_LOGIC;
        pulse_in : in  STD_LOGIC;
        pulse_out : out STD_LOGIC
    );
end Pulse_Widener;

architecture Behavioral of Pulse_Widener is
    signal counter : unsigned(31 downto 0) := (others => '0');
    signal pulse_active : std_logic := '0';
begin
    process(clk, rst)
    begin
        if rst = '1' then
            counter <= (others => '0');
            pulse_active <= '0';
            pulse_out <= '1';
        elsif rising_edge(clk) then
            if pulse_in = '1' then
                -- 检测到输入正脉冲，激活脉冲展宽
                pulse_active <= '1';
                counter <= to_unsigned(PULSE_WIDTH - 1, counter'length);
            elsif pulse_active = '1' then
                if counter > 0 then
                    -- 计数器未到 0，继续保持负脉冲
                    counter <= counter - 1;
                    pulse_out <= '0';
                else
                    -- 计数器到 0，结束负脉冲
                    pulse_active <= '0';
                    pulse_out <= '1';
                end if;
            end if;
        end if;
    end process;
end Behavioral;
