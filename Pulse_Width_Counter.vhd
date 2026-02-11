-- 引入 IEEE 标准库
library IEEE;
-- 使用标准逻辑类型定义包
use IEEE.STD_LOGIC_1164.ALL;
-- 使用数值标准包，用于无符号数等数值类型操作
use IEEE.NUMERIC_STD.ALL;

-- 定义实体 Pulse_Width_Counter，用于统计脉冲宽度
entity Pulse_Width_Counter is
    -- 定义泛型参数，可配置计数器位宽
    Generic (
        COUNTER_WIDTH : positive := 32 -- 计数器位宽，可根据最大脉冲宽度调整
    );
    -- 定义端口
    Port (
        clk     : in  STD_LOGIC;  -- 时钟信号，作为时序逻辑的驱动
        rst     : in  STD_LOGIC;  -- 复位信号，高电平有效，用于系统初始化
        pulse_in : in  STD_LOGIC; -- 输入脉冲信号，待测量宽度的脉冲
        -- 修改端口类型为 std_logic_vector
        pulse_width : out STD_LOGIC_VECTOR(COUNTER_WIDTH - 1 downto 0); 
        valid : out STD_LOGIC -- 有效信号，脉冲结束时拉高一个时钟周期
    );
end Pulse_Width_Counter;

-- 定义架构 Behavioral
architecture Behavioral of Pulse_Width_Counter is
    -- 定义内部信号
    signal counter : unsigned(COUNTER_WIDTH - 1 downto 0) := (others => '0'); -- 用于计数脉冲宽度的计数器
    signal pulse_active : std_logic := '0'; -- 标记脉冲是否处于激活状态
begin
    -- 定义进程，由时钟信号和复位信号触发
    process(clk, rst)
    begin
        -- 当复位信号有效时
        if rst = '1' then
            counter <= (others => '0'); -- 计数器清零
            pulse_active <= '0'; -- 标记脉冲未激活
            -- 将无符号数转换为 std_logic_vector 后赋值
            pulse_width <= (others => '0'); 
            valid <= '0'; -- 有效信号清零
        -- 当时钟上升沿到来时
        elsif rising_edge(clk) then
            valid <= '0'; -- 默认有效信号为低

            -- 当输入脉冲为高电平时
            if pulse_in = '1' then
                -- 若脉冲之前未激活，即检测到上升沿
                if pulse_active = '0' then
                    -- 重置计数器
                    counter <= (others => '0');
                    -- 标记脉冲已激活
                    pulse_active <= '1';
                -- 若脉冲已经处于激活状态
                else
                    -- 计数器加 1
                    counter <= counter + 1;
                end if;
            -- 当输入脉冲为低电平且脉冲之前处于激活状态时，即检测到下降沿
            elsif pulse_active = '1' then
                -- 输出脉冲宽度，由于计数器从 0 开始，所以加 1，再转换为 std_logic_vector
                pulse_width <= std_logic_vector(counter + 1); 
                -- 拉高有效信号
                valid <= '1';
                -- 标记脉冲未激活
                pulse_active <= '0';
            end if;
        end if;
    end process;
end Behavioral;
