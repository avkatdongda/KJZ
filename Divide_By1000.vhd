library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Divide_By1000 is
    Port (
        clk : in STD_LOGIC;
        rst : in STD_LOGIC;
        input : in signed(20 downto 0);
        output : out signed(20 downto 0)
    );
end Divide_By1000;

architecture Behavioral of Divide_By1000 is
    -- 定义各阶段的中间结果信号
    signal stage1 : signed(20 downto 0);
    signal stage2 : signed(20 downto 0);
    signal stage3 : signed(20 downto 0);
    signal stage4 : signed(20 downto 0);
    signal stage5 : signed(20 downto 0);
    signal stage6 : signed(20 downto 0);
    signal stage7 : signed(20 downto 0);
    signal stage8 : signed(20 downto 0);
    signal stage9 : signed(20 downto 0);
begin
    process(clk, rst)
    begin
        if rst = '1' then
            -- 复位时将所有中间结果置为 0
            stage1 <= (others => '0');
            stage2 <= (others => '0');
            stage3 <= (others => '0');
            stage4 <= (others => '0');
            stage5 <= (others => '0');
            stage6 <= (others => '0');
            stage7 <= (others => '0');
            stage8 <= (others => '0');
            stage9 <= (others => '0');
        elsif rising_edge(clk) then
            -- 第一阶段：2^(-10)
            stage1 <= input srl 10;
            -- 第二阶段：2^(-13)
            stage2 <= input srl 13;
            -- 第三阶段：累加前两个阶段结果
            stage3 <= stage1 + stage2;
            -- 第四阶段：2^(-14)
            stage4 <= input srl 14;
            -- 第五阶段：累加前三个阶段结果
            stage5 <= stage3 + stage4;
            -- 第六阶段：2^(-15)
            stage6 <= input srl 15;
            -- 第七阶段：累加前四个阶段结果
            stage7 <= stage5 + stage6;
            -- 第八阶段：2^(-16)
            stage8 <= input srl 16;
            -- 第九阶段：累加前五个阶段结果
            stage9 <= stage7 + stage8;
            -- 这里可以继续添加后续的移位和累加操作
            -- 最终输出结果
            output <= stage9;
        end if;
    end process;
end Behavioral;
