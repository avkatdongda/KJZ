-- hds interface_start
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
USE ieee.std_logic_arith.all;

LIBRARY JWXJ;

-- ----------------------------------------------------------------
--  115200  8.68055ms     542.535us    
--  UART_Clk    11.0592 90.42245ns    6000分频
--  UART_ClkEn  6000分频脉冲使能 
--  增加奇偶校验功能  奇校验  
--  20200817  增加FIFO缓存大小为2048
-- 
ENTITY UART_TX_DRIVER_PT_C250303 IS
   Generic(
		VARPARITY     : std_logic := '1'
   );
   PORT( 
      SYS_Clk       : IN     std_logic;
      SYS_Reset_n   : IN     std_logic;
      UART_Clk      : IN     std_logic;
      UART_Reset_n  : IN     std_logic;
      UART_ClkEn    : IN     std_logic;                      --CLK的16分频使能脉冲
      TX_PAD_O      : OUT    std_logic;
      DATA          : IN     std_logic_vector (8 DOWNTO 0);  --并行数据
      VALID         : IN     std_logic;
      UART_TF_Empty : OUT    std_logic;
	  TX_DIS		: OUT    std_logic
   );

-- Declarations

END UART_TX_DRIVER_PT_C250303 ;
-- hds interface_end

architecture RTL of UART_TX_DRIVER_PT_C250303 is 

--******************************************************
-- 常数声明
--******************************************************
    -- constant ST_IDLE        : std_logic_vector(2 downto 0) 	   := "000";
    -- constant ST_POPBYTE     : std_logic_vector(2 downto 0) 	   := "001";
    -- constant ST_SENDSTART   : std_logic_vector(2 downto 0) 	   := "010";
    -- constant ST_SENDBYTE    : std_logic_vector(2 downto 0) 	   := "011";
    -- constant ST_SENDPARITY  : std_logic_vector(2 downto 0) 	   := "100";
    -- constant ST_SENDSTOP    : std_logic_vector(2 downto 0) 	   := "101";
	
	TYPE STATE_TYPE is(
		ST_IDLE,
		ST_POPBYTE,
		ST_SENDSTART,
		ST_SENDBYTE,
		ST_SENDPARITY,
		ST_SENDSTOP,
		ST_TXDIS_WAIT,
		ST_TXDIS
	);
    
    signal Parity : std_logic;
    signal STOP_s : std_logic;
------------------------------------------------------------
-- FIFO
------------------------------------------------------------
   
-- COMPONENT TX_FIFO
  -- PORT (
    -- UART_Clk : IN STD_LOGIC;
    -- srst : IN STD_LOGIC;
    -- din : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    -- wr_en : IN STD_LOGIC;
    -- rd_en : IN STD_LOGIC;
    -- dout : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    -- full : OUT STD_LOGIC;
    -- empty : OUT STD_LOGIC
  -- );
-- END COMPONENT;

COMPONENT UART_TXFIFO_WITHTAIL
  PORT (
    rst : IN STD_LOGIC;
    wr_clk : IN STD_LOGIC;
    rd_clk : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(8 DOWNTO 0);
    full : OUT STD_LOGIC;
    empty : OUT STD_LOGIC;
    wr_rst_busy : OUT STD_LOGIC;
    rd_rst_busy : OUT STD_LOGIC
  );
END COMPONENT;

  signal UART_TXFIFO_Rst : std_logic;
  signal TF_Din  : std_logic_vector(8 downto 0);
  signal TF_WrEn : std_logic;
  signal TF_Pop  : std_logic;
  signal TF_Full : std_logic;
  signal TF_Empty: std_logic;
  signal TF_Dout : std_logic_vector(8 downto 0);
  
------------------------------------------------------------
-- 状态机
------------------------------------------------------------
   signal State_c : STATE_TYPE;
   signal State_n : STATE_TYPE;
   signal SEND2STOP_Start : std_logic;
------------------------------------------------------------
-- 位计数器
------------------------------------------------------------
   signal BitCnt : std_logic_vector(2 downto 0);
   signal Add_BitCnt : std_logic;
   signal End_BitCnt : std_logic;   
------------------------------------------------------------
-- 定时器
------------------------------------------------------------
   signal Cnt : std_logic_vector(4 downto 0);
   signal Add_Cnt : std_logic;
   signal End_Cnt : std_logic;
   signal XX  : std_logic_vector(4 downto 0);
   
------------------------------------------------------------
-- FIFO读出逻辑
------------------------------------------------------------
   signal TF_Pop_t : std_logic;
   signal TF_Pop_r : std_logic;

------------------------------------------------------------
-- 移位寄存器
------------------------------------------------------------
   signal Shift : std_logic_vector(7 downto 0);  

   attribute   ASYNC_REG                   : string;
   signal UART_TF_Empty_r1  : std_logic;
   attribute   ASYNC_REG of  UART_TF_Empty_r1   : signal is "TRUE";
   signal UART_TF_Empty_r2  : std_logic;
   attribute   ASYNC_REG of  UART_TF_Empty_r2   : signal is "TRUE";
   
   signal RdResetBusy  : std_logic;
   signal WrResetBusy  : std_logic;
   
   
      -- pragma synthesis_off
   --FOR ALL : UART_TXFIFO_WITHTAIL USE ENTITY JWXJ.UART_TXFIFO_WITHTAIL;
   -- pragma synthesis_on
--====================================================================
begin


------------------------------------------------------------
-- FIFO
------------------------------------------------------------
	-- mTX_FIFO : TX_FIFO
   -- PORT MAP (
		-- clk         => SYS_Clk,
		-- srst        => reset,
		-- din         => DATA,
		-- wr_en       => VALID,
		-- rd_en       => TF_Pop,
		-- dout        => TF_Dout,
		-- full        => TF_Full,
		-- empty       => TF_Empty
  -- );

  
  UART_TXFIFO_Rst <=  not(SYS_Reset_n) or not(UART_Reset_n);
  
  process(SYS_Clk, SYS_Reset_n) begin
      if(SYS_Reset_n = '0') then
         TF_WrEn <= '0';
      elsif rising_edge(SYS_Clk) then
         if(VALID = '1') and (TF_Full = '0')and(WrResetBusy = '0') then
            TF_WrEn <= '1';
         else
            TF_WrEn <= '0';
         end if;
      end if;
  end process;
  
  process(SYS_Clk, SYS_Reset_n) begin
      if(SYS_Reset_n = '0') then
         TF_Din <= (others => '0');
      elsif rising_edge(SYS_Clk) then
         TF_Din <= DATA;
      end if;
  end process;
  
   process(SYS_Clk, SYS_Reset_n) begin
      if(SYS_Reset_n = '0') then
         UART_TF_Empty_r1 <= '0';
         UART_TF_Empty_r2 <= '0';
         UART_TF_Empty <= '0';
      elsif rising_edge(SYS_Clk) then
         UART_TF_Empty_r1 <= TF_Empty;
         UART_TF_Empty_r2 <= UART_TF_Empty_r1;
         UART_TF_Empty    <= UART_TF_Empty_r2;
      end if;
   end process;
  
  mTX_FIFO : UART_TXFIFO_WITHTAIL
  PORT MAP (
    rst        => UART_TXFIFO_Rst,
    wr_clk     => SYS_Clk,
    rd_clk     => UART_Clk,
    din        => TF_Din,
    wr_en      => TF_WrEn,
    rd_en      => TF_Pop,
    dout       => TF_Dout,
    full       => TF_Full,
    empty      => TF_Empty,
    wr_rst_busy => WrResetBusy,
    rd_rst_busy => RdResetBusy
  );
------------------------------------------------------------
-- 状态机
------------------------------------------------------------

   process (UART_Clk, UART_Reset_n) begin
        if(UART_Reset_n = '0') then
            State_c <= ST_IDLE;
        elsif rising_edge(UART_Clk) then
            if (UART_ClkEn = '1') then
               State_c <= State_n;
            end if;
        end if;
   end process;

   process(State_c, TF_Empty, SEND2STOP_Start, End_Cnt, RdResetBusy) begin  --0624 补充RdResetBusy
      case(State_c) is
         when ST_IDLE      =>
            if(TF_Empty = '0') and (RdResetBusy = '0') then
               State_n <= ST_POPBYTE;
            else
               State_n <= State_c;
            end if;
         when ST_POPBYTE   =>          --001
            State_n <= ST_SENDSTART;
         when ST_SENDSTART =>
            if(End_Cnt = '1') then           
               State_n <= ST_SENDBYTE;
            else
               State_n <= State_c;
            end if;
         when ST_SENDBYTE  =>
            if(SEND2STOP_Start = '1') then
               State_n <= ST_SENDPARITY;
            else
               State_n <= State_c;
            end if;
         when ST_SENDPARITY =>  --发送奇校验位
            if(End_Cnt = '1') then
               State_n <= ST_SENDSTOP;
            else
               State_n <= State_c;
            end if;
         when ST_SENDSTOP  => 
            if(End_Cnt = '1') then
				if(STOP_s = '1') then
					State_n <= ST_TXDIS_WAIT;
				else
					State_n <= ST_IDLE;
				end if;
            else
               State_n <= State_c;
            end if;
		 when ST_TXDIS_WAIT  =>
			if(End_Cnt = '1') then
				State_n <= ST_TXDIS;
			else
				State_n <= State_c;
			end if;
		 when ST_TXDIS  =>
			State_n <= ST_IDLE;
         when others => 
            State_n <= ST_IDLE;
      end case;
   end process;
   
   SEND2STOP_Start <= '1' when (State_c = ST_SENDBYTE) and (End_Cnt = '1') and (End_BitCnt = '1') else '0';
------------------------------------------------------------
-- 位计数器
------------------------------------------------------------
   
   process(UART_Clk, UART_Reset_n) begin
      if(UART_Reset_n = '0') then
         BitCnt <= (others => '0');
      elsif rising_edge(UART_Clk) then
         if (UART_ClkEn = '1') then
            if(Add_BitCnt = '1') then
               if(End_BitCnt = '1') then
                  BitCnt <= (others => '0');
               else
                  BitCnt <= BitCnt + "001";
               end if;
            end if;
         end if;
      end if;
   end process;
   
   Add_BitCnt <= '1' when (State_c = ST_SENDBYTE) and (End_Cnt = '1') else '0';
   End_BitCnt <= '1' when (Add_BitCnt = '1') and (BitCnt = conv_std_logic_vector(8-1,3)) else '0';
------------------------------------------------------------
-- 定时器
------------------------------------------------------------
   process(State_c) begin
      case(State_c) is
         when ST_SENDSTART =>
            XX <= conv_std_logic_vector(16-1,5);
         when ST_SENDBYTE  =>
            XX <= conv_std_logic_vector(16-1,5);
         when ST_SENDPARITY =>
            XX <= conv_std_logic_vector(16-1,5);
         when ST_SENDSTOP  => 
            XX <= conv_std_logic_vector(14-1,5);
		 when ST_TXDIS_WAIT =>
			XX <= conv_std_logic_vector(16-1,5);
         when others =>
            XX <= conv_std_logic_vector(1-1,5);
      end case;
   end process;
   
   process(UART_Clk, UART_Reset_n) begin
      if(UART_Reset_n = '0') then
         Cnt <= (others => '0');
      elsif rising_edge(UART_Clk) then
         if(UART_ClkEn = '1') then
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
------------------------------------------------------------
-- FIFO读出逻辑
------------------------------------------------------------

   
   process(UART_Clk, UART_Reset_n) begin
      if(UART_Reset_n = '0') then
         TF_Pop_t <= '0';
      elsif rising_edge(UART_Clk) then
         if(UART_ClkEn = '1') then
            if(State_c = ST_POPBYTE) then
               TF_Pop_t <= '1';
            else
               TF_Pop_t <= '0';
            end if;
         end if;
      end if;
   end process;
   
   -- 转换到SYS_CLK时钟域
   PROCESS (UART_Clk, UART_Reset_n)
   BEGIN
      IF (UART_Reset_n = '0') THEN
         TF_Pop_r <= '0';
      ELSIF rising_edge(UART_Clk) THEN
         TF_Pop_r <= TF_Pop_t;
      END IF;
   END PROCESS;
   
   
   TF_Pop <= TF_Pop_t AND NOT(TF_Pop_r);
------------------------------------------------------------
-- 移位寄存器
------------------------------------------------------------
   process(UART_Clk, UART_Reset_n) begin
        if(UART_Reset_n = '0') then
            Shift <= (others => '0');
        elsif rising_edge(UART_Clk) then
            if(UART_ClkEn = '1') then
               if(State_c = ST_POPBYTE) then
                   Shift      <= TF_Dout(7 downto 0);
               elsif(State_c = ST_SENDBYTE) and (End_Cnt = '1') then
                   Shift(6 downto 0) <= Shift(7 downto 1);
               end if;
            end if;
        end if;
    end process;
    
    process(UART_Clk, UART_Reset_n) begin
        if(UART_Reset_n = '0') then
            TX_PAD_O <= '1';
        elsif rising_edge(UART_Clk) then
            if(UART_ClkEn = '1') then
               case(State_c) is 
                  when ST_IDLE => 
                     TX_PAD_O <= '1';
                  when ST_POPBYTE => 
                     TX_PAD_O <= '1';
                  when ST_SENDSTART => 
                     TX_PAD_O <= '0';
                  when ST_SENDBYTE  => 
                     TX_PAD_O <= Shift(0);
                  when ST_SENDPARITY =>
                     TX_PAD_O <= Parity;
                  when ST_SENDSTOP  =>
                     TX_PAD_O <= '1';
                  when others =>
                     TX_PAD_O <= '1';
               end case;
            end if;
        end if;
    end process;
    
    
    -- 统计奇偶校验  1的个数为奇数 校验位0
    process(UART_Clk, UART_Reset_n) begin
      if(UART_Reset_n = '0') then
         Parity <= VARPARITY;
      elsif rising_edge(UART_Clk) then
         if(UART_ClkEn = '1') then
            if(State_c = ST_POPBYTE) then
               Parity <= VARPARITY;
            elsif(State_c = ST_SENDBYTE) and (Cnt = conv_std_logic_vector(8,5)) then
               Parity <= Parity xor Shift(0);
            end if;
         end if;
      end if;
    end process;
	
	process(UART_Clk, UART_Reset_n) begin
        if(UART_Reset_n = '0') then
            STOP_s <= '0';
        elsif rising_edge(UART_Clk) then
            if(UART_ClkEn = '1') then
               if(State_c = ST_POPBYTE) then
                   STOP_s      <= TF_Dout(8);
               end if;
            end if;
        end if;
    end process;
	
	process(UART_Reset_n, UART_Clk) begin
		if(UART_Reset_n = '0') then
			TX_DIS <= '0';
		elsif rising_edge(UART_Clk) then
			if(State_c = ST_TXDIS) then
				TX_DIS <= '1';
			else
				TX_DIS <= '0';
			end if;
		end if;
	end process;
	
end RTL;
