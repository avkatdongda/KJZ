-- 引入 IEEE 标准库
library IEEE;
-- 使用标准逻辑类型定义包
use IEEE.STD_LOGIC_1164.ALL;

-- 定义实体 Input_Passthrough
entity Input_Passthrough is
    Port (
        clk     : in  STD_LOGIC;  -- 时钟信号
        rst     : in  STD_LOGIC;  -- 复位信号，高电平有效
        start   : in  STD_LOGIC;  -- 开启控制信号
        stop    : in  STD_LOGIC;  -- 关闭控制信号
        input   : in  STD_LOGIC;  -- 输入信号
        output  : out STD_LOGIC   -- 输出信号
    );
end Input_Passthrough;

-- 定义架构 Behavioral
architecture Behavioral of Input_Passthrough is
    -- 定义状态信号，用于记录当前状态
    type state_type is (IDLE, ENABLED);
    signal current_state : state_type := IDLE;
begin
    -- 定义进程，由时钟信号和复位信号触发
    process(clk, rst)
    begin
        -- 当复位信号有效时
        if rst = '1' then
            current_state <= IDLE;  -- 回到空闲状态
            output <= '0';          -- 输出置为低电平
        -- 当时钟上升沿到来时
        elsif rising_edge(clk) then
            case current_state is
                -- 空闲状态
                when IDLE =>
                    if start = '1' then
                        current_state <= ENABLED;  -- 进入开启状态
                    end if;
                    output <= '0';  -- 空闲状态输出低电平
                -- 开启状态
                when ENABLED =>
                    if stop = '1' then
                        current_state <= IDLE;  -- 回到空闲状态
                        output <= '0';          -- 输出置为低电平
                    else
                        output <= input;        -- 将输入信号传递到输出
                    end if;
            end case;
        end if;
    end process;
end Behavioral;
