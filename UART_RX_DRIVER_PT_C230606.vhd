---------------------------------------------------------
-- UART接收底层
-- 本代码结合OPENCORE的Uart_receiver模块和火星代码CC_SDR模块

-- (1) 保留来自OPENCORE的状态机编码风格
-- (2) 修正统一的计数器编程风格
-- (2) 采纳火星代码3判2的方法
---------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
USE ieee.std_logic_arith.all;


entity UART_RX_DRIVER_PT_C230606 is
    port(
        UART_Clk         : in std_logic;
        UART_ClkEn  : in std_logic;                   
        UART_Reset_n     : in std_logic;
        RX_PAD_I    : in std_logic;                     
        VALID       : out std_logic;                    
        DATA        : out std_logic_vector(7 downto 0);  
		  Debug_State : out std_logic_vector(3 downto 0)
    );
end UART_RX_DRIVER_PT_C230606;

architecture RTL of UART_RX_DRIVER_PT_C230606 is
    attribute   ASYNC_REG                   : string;
    attribute fsm_safe_state : string;
    
--******************************************************
-- 常数声明
--******************************************************
    constant ST_IDLE        : std_logic_vector(3 downto 0) 	   := "0000";
    constant ST_START       : std_logic_vector(3 downto 0) 	   := "0001";
    constant ST_PREPARE     : std_logic_vector(3 downto 0) 	   := "0010";
    constant ST_RECVBIT     : std_logic_vector(3 downto 0) 	   := "0011";
    constant ST_BITCNT      : std_logic_vector(3 downto 0) 	   := "0100";
    constant ST_PARITY      : std_logic_vector(3 downto 0) 	   := "0101";
    constant ST_STOP        : std_logic_vector(3 downto 0) 	   := "0110";
    constant ST_PUSH        : std_logic_vector(3 downto 0) 	   := "0111";
    constant ST_WAIT        : std_logic_vector(3 downto 0) 	   := "1000";
	
	-- TYPE STATE_TYPE IS (
		-- ST_IDLE,
		-- ST_START,
		-- ST_PREPARE,
		-- ST_RECVBIT,
		-- ST_BITCNT,
		-- ST_PARITY,
		-- ST_STOP,
		-- ST_PUSH,
		-- ST_WAIT
	-- );

------------------------------------------------------------------
-- 异步数据处理
------------------------------------------------------------------
    signal RX_r2 : std_logic;   

------------------------------------------------------------------
-- 状态机
------------------------------------------------------------------
    signal State_c : std_logic_vector(3 downto 0);
    signal State_n : std_logic_vector(3 downto 0);
    signal START2PREPARE_Start  : std_logic;
    signal END2STOP_Start       : std_logic;
    signal RECVBIT2BITCNT_Start    : std_logic;

------------------------------------------------------------------
-- 帧错误
------------------------------------------------------------------
signal Frame_Error : std_logic;

------------------------------------------------------------------
-- 计数器逻辑
------------------------------------------------------------------
    signal Cnt      : std_logic_vector(4 downto 0);
    signal Add_Cnt  : std_logic;
    signal End_Cnt  : std_logic;   
    signal XX       : std_logic_vector(4 downto 0);
------------------------------------------------------------------
-- 包计数器逻辑
------------------------------------------------------------------
    signal BitCnt : std_logic_vector(2 downto 0);
    signal Add_BitCnt : std_logic;
    signal End_BitCnt : std_logic;
    
------------------------------------------------------------------
-- 移位寄存器
------------------------------------------------------------------
    signal Sample1 : std_logic;
    signal Sample2 : std_logic;
    signal Sample3 : std_logic;
    signal RX_Res : std_logic;
    
    signal Shift : std_logic_vector(7 downto 0);
    signal BitCapture : std_logic;

------------------------------------------------------------------
-- 单脉冲化
------------------------------------------------------------------
signal Valid_b  : std_logic;
signal Valid_r  : std_logic;    
signal Data_b   : std_logic_vector(7 downto 0);
begin
	Debug_State <= State_c;
------------------------------------------------------------------
-- 异步数据处理 去掉移动到最外层，不做三模
------------------------------------------------------------------    
	RX_r2 <= RX_PAD_I;
------------------------------------------------------------------
-- 状态机
------------------------------------------------------------------
    
    process (UART_Clk, UART_Reset_n) begin
        if(UART_Reset_n = '0') then
            State_c <= ST_IDLE;
        elsif rising_edge(UART_Clk)   then
            if(UART_ClkEn = '1') then
               State_c <= State_n;
            end if;
        end if;
    end process;
    

    END2STOP_Start      <= '1' when (State_c = ST_BITCNT) and (BitCnt = conv_std_logic_vector(8-1, 4))  else '0';
    START2PREPARE_Start <= '1' when (State_c = ST_START) and (End_Cnt = '1') else '0';    --(End_Cnt = '1') 
    RECVBIT2BITCNT_Start   <= '1' when (State_c = ST_RECVBIT) and ( End_Cnt = '1') else '0';


    
    process(State_c, RX_r2, START2PREPARE_Start, RECVBIT2BITCNT_Start,  End_Cnt,  END2STOP_Start,  Frame_Error) begin
        case(State_c) is
            when ST_IDLE        => --1
                if( RX_r2 = '0') then
                    State_n <= ST_START; 
                else
                    State_n <= State_c;
                end if;
            when ST_START   =>  --7
                if( START2PREPARE_Start = '1') then
                    State_n <= ST_PREPARE;
                elsif(RX_r2 = '1') then
                    State_n <= ST_IDLE;   
                else
                    State_n <= State_c;
                end if;
            when ST_PREPARE     =>
                if(End_Cnt = '1') then
                    State_n <= ST_RECVBIT;
                else
                    State_n <= State_c;
                end if;
            when ST_RECVBIT     =>
                if (RECVBIT2BITCNT_Start = '1')then              --(End_Cnt = '1')
                    State_n <= ST_BITCNT;
                else
                    State_n <= State_c;
                end if;
            when ST_BITCNT        =>   --位计数
                if(END2STOP_Start = '1') then
                    State_n <= ST_PARITY;
                else
                    State_n <= ST_RECVBIT;
                end if;
            when ST_PARITY     =>
                if(End_Cnt = '1') then
                     State_n <= ST_STOP;
                else
                     State_n <= State_c;
                end if;
            when ST_STOP       =>
                if(End_Cnt = '1') then 
                    if(Frame_Error = '0') then
                        State_n <= ST_PUSH;
                    else
                        State_n <= ST_WAIT;
                    end if;
                else
                    State_n <= State_c;
                end if;
            when ST_PUSH       =>
                State_n <= ST_IDLE;
            when ST_WAIT       =>
                State_n <= ST_IDLE;
            when others        =>
                State_n <= ST_IDLE;
        end case;
    end process;

------------------------------------------------------------------
-- 帧错误
------------------------------------------------------------------

process(UART_Clk, UART_Reset_n) begin
    if(UART_Reset_n = '0') then
        Frame_Error <= '0';
    elsif rising_edge(UART_Clk) then
      if (UART_ClkEn = '1') then
         if(State_c = ST_PREPARE) then
            Frame_Error <= '0';
         elsif((State_c = ST_STOP) and (Cnt = conv_std_logic_vector(7, 5)) and (RX_r2 = '0')) then
            Frame_Error <= '1';
         end if;
      end if;
    end if;
end process;

------------------------------------------------------------------
-- 接收数据
------------------------------------------------------------------

process(UART_Clk, UART_Reset_n) begin
    if(UART_Reset_n = '0') then
        Valid_b <= '0';
    elsif rising_edge(UART_Clk) then
      if(UART_ClkEn = '1') then
        if(State_c = ST_PUSH) then
            Valid_b <= '1';
        else
            Valid_b <= '0';
        end if;
      end if;
    end if;
end process;

process(UART_Clk, UART_Reset_n) begin
    if(UART_Reset_n = '0') then
        Data_b <= (others => '0');
    elsif rising_edge(UART_Clk) then
      if (UART_ClkEn = '1') then
        if(State_c = ST_PUSH) then
            Data_b  <= Shift;
        end if;
      end if;
    end if;
end process;
------------------------------------------------------------------
-- 计数器逻辑
------------------------------------------------------------------
    process(State_c) begin
      case(State_c) is
         when ST_START     =>
            XX <= conv_std_logic_vector(7-1,5);
         when ST_PREPARE   =>
            XX <= conv_std_logic_vector(8-1,5);
         when ST_RECVBIT   => 
            XX <= conv_std_logic_vector(15-1,5);
         when ST_PARITY    =>
            XX <= conv_std_logic_vector(16-1,5);
         when ST_STOP      => 
            XX <= conv_std_logic_vector(9-1,5);
         when others =>
            XX <= conv_std_logic_vector(1-1,5);
      end case;
    end process;
    
    process(UART_Clk, UART_Reset_n) begin
        if(UART_Reset_n = '0') then
            Cnt <= (others => '0');
        elsif rising_edge(UART_Clk) then
            if (UART_ClkEn = '1') then 
               if(Add_Cnt = '1') then
                   if(End_Cnt = '1') then
                       Cnt <= (others => '0');
                   else
                       Cnt <= Cnt + "00001";
                   end if;
               end if;
            end if;
        end if;
    end process;
    
    Add_Cnt <= '1' when (State_c /= ST_IDLE) else '0';
    End_Cnt <= '1' when (Add_Cnt = '1') and (Cnt = XX) else '0';
    
------------------------------------------------------------------
-- 包计数器逻辑
------------------------------------------------------------------    
    process(UART_Clk, UART_Reset_n) begin
        if(UART_Reset_n = '0') then
            BitCnt <= "000";
        elsif rising_edge(UART_Clk) then
            if (UART_ClkEn = '1') then 
               if(Add_BitCnt = '1') then
                   if(End_BitCnt = '1') then
                       BitCnt <= "000";
                   else
                       BitCnt <= BitCnt + "001";
                   end if;
               end if;
            end if;
        end if;
    end process;
    
    Add_BitCnt <= '1' when (State_c = ST_BITCNT) else '0';
    End_BitCnt <= '1' when (Add_BitCnt = '1') and (BitCnt = conv_std_logic_vector(8-1,4)) else '0';
------------------------------------------------------------------
-- 表决和移位寄存器
------------------------------------------------------------------
    process(UART_Clk, UART_Reset_n) begin
        if(UART_Reset_n = '0') then
            Sample1 <= '1';
            Sample2 <= '1';
            Sample3 <= '1';
            RX_Res  <= '1';
        elsif rising_edge(UART_Clk) then
            if (UART_ClkEn = '1') then 
               if(State_c = ST_RECVBIT) then
                   case Cnt is
                       when "00110" =>   --6
                           Sample1 <= RX_PAD_I;
                       when "00111" =>   --7
                           Sample2 <= RX_PAD_I;
                       when "01000" =>   --8
                           Sample3 <= RX_PAD_I;
                       when "01001" =>   --9
                           RX_Res <= (Sample1 and Sample2) or (Sample2 and Sample3) or (Sample1 and Sample3);
                       when others =>
                           RX_Res <= RX_Res;
                   end case;
               end if;
            end if;
        end if;
    end process;
    
    BitCapture <= '1' when (State_c = ST_RECVBIT) and (Cnt = conv_std_logic_vector(10, 5)) else '0';
    process(UART_Clk, UART_Reset_n) begin
        if(UART_Reset_n = '0') then
            Shift <= (others => '0');
        elsif rising_edge(UART_Clk) then
            if (UART_ClkEn = '1') then 
               if(START2PREPARE_Start = '1') then
                   Shift <= (others => '0');
               elsif(BitCapture = '1') then
                   Shift(7 downto 0) <= RX_Res & Shift(7 downto 1);
               end if;
            end if;
        end if;
    end process;
------------------------------------------------------------------
-- 单脉冲化
------------------------------------------------------------------

process(UART_Clk, UART_Reset_n) begin
    if(UART_Reset_n = '0') then
        Valid_r <= '0';
    elsif rising_edge(UART_Clk) then
        Valid_r <= Valid_b;
    end if;
end process; 

process(UART_Clk, UART_Reset_n) begin
    if(UART_Reset_n = '0') then
        VALID <= '0';
        DATA  <= (others => '0');
    elsif rising_edge(UART_Clk) then
        VALID <= Valid_b and not(Valid_r);
        DATA  <= Data_b;
    end if;
end process;   
end RTL;