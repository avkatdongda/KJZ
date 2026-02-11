-- 引入 IEEE 标准库
library IEEE;
-- 使用标准逻辑类型定义包
use IEEE.STD_LOGIC_1164.ALL;
-- 使用数值标准包，用于无符号数等数值类型操作
use IEEE.NUMERIC_STD.ALL;

-- 定义实体 Pulse_Generator，用于连续输出脉冲
entity Pulse_Generator is
    -- 定义泛型参数，可配置计数器位宽
    Generic (
        COUNTER_WIDTH : positive := 32
    );
    -- 定义端口
    Port (
        clk          : in  STD_LOGIC;  -- 时钟信号，作为时序逻辑的驱动
        rst          : in  STD_LOGIC;  -- 复位信号，高电平有效，用于系统初始化
        ms_pulse     : in  STD_LOGIC;  -- 每 1 毫秒产生一个脉冲信号
        pulse_interval : in  STD_LOGIC_VECTOR(COUNTER_WIDTH - 1 downto 0); -- 脉冲间隔，单位为毫秒
        pulse_out    : out STD_LOGIC   -- 输出脉冲信号
    );
end Pulse_Generator;

-- 定义架构 Behavioral
architecture Behavioral of Pulse_Generator is
    -- 定义内部信号
    signal counter : unsigned(COUNTER_WIDTH - 1 downto 0) := (others => '0'); -- 用于计数脉冲间隔的计数器
    signal active_interval : unsigned(COUNTER_WIDTH - 1 downto 0) := (others => '0'); -- 当前有效脉冲间隔
    signal pulse_active : std_logic := '0'; -- 标记脉冲是否处于激活状态
begin
    -- 定义进程，由时钟信号和复位信号触发
    process(clk, rst)
    begin
        -- 当复位信号有效时
        if rst = '1' then
            counter <= (others => '0'); -- 计数器清零
            pulse_active <= '0'; -- 标记脉冲未激活
            pulse_out <= '0'; -- 输出脉冲信号清零
            active_interval <= (others => '0'); -- 有效脉冲间隔清零
        -- 当时钟上升沿到来时
        elsif rising_edge(clk) then
            -- 直接更新有效脉冲间隔
            active_interval <= unsigned(pulse_interval);

            -- 当检测到 1 毫秒脉冲时
            if ms_pulse = '1' then
                -- 当计数器达到有效脉冲间隔时
                if counter >= active_interval then
                    pulse_out <= '1'; -- 输出脉冲
                    counter <= (others => '0'); -- 计数器清零
                else
                    pulse_out <= '0'; -- 无脉冲输出
                    counter <= counter + 1; -- 计数器加 1
                end if;
            else
                pulse_out <= '0'; -- 无 1 毫秒脉冲时，无脉冲输出
            end if;
        end if;
    end process;
end Behavioral;
