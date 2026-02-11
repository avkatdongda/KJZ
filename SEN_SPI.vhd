----------------------------------------------------------------------------------
-- Company:         CIOMP
-- Engineer:        WangZheng
-- Create Date:     2025/02/21 09:00:58
-- Module Name:     SEN_SPI - Behavioral
-- Project Name:    CH4_G400
-- Target Devices:  xc7k325tffg900-2
-- Tool versions:   Vivado 2018.3
-- Description:     program the sensor's register via spi interface
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity SEN_SPI is
    port (
        ---------CLOCKING---------
        Clk_Ref                     : in  STD_LOGIC;                            -- 25MHz
        Rst_Ref                     : in  STD_LOGIC;                            -- Clk_Ref correspond rst signal
        ---------pin---------
        SPI_OUT                     : in  STD_LOGIC;                            -- sensor spi output signal
        SPI_CLK                     : out STD_LOGIC;                            -- sensor spi clk in 25MHz/50ns
        SPI_IN                      : out STD_LOGIC;                            -- sensor spi input signal
        SPI_WRITE                   : out STD_LOGIC;                            -- the enable of of writing spi
        SPI_READ                    : out STD_LOGIC;                            -- the enable of of reading spi
        ---------TOP---------
        Spi_GainOdd                 : out STD_LOGIC_VECTOR (2 downto 0);        -- read spi low gain register
        Spi_GainEven                : out STD_LOGIC_VECTOR (2 downto 0);        -- read spi high gain register
        ---------SEN_CTRL---------
        Gain_Odd                    : in  STD_LOGIC_VECTOR (2 downto 0);        -- low gain default 100 1.29x
        Gain_Even                   : in  STD_LOGIC_VECTOR (2 downto 0);        -- high gain default 111 7.25x
        Cmd_Wr_Spi                  : in  STD_LOGIC;                            -- the command of writing spi
        Cmd_Rd_Spi                  : in  STD_LOGIC;                            -- the command of reading spi
        Spi_Wr_Done                 : out STD_LOGIC;                            -- the finish signal of writing spi, '1' is valid
        Spi_Rd_Done                 : out STD_LOGIC);                           -- the finish signal of reading spi, '1' is valid
end SEN_SPI;

architecture Behavioral of SEN_SPI is

    -- SPI register definiton
    signal  PLLDIV                  : STD_LOGIC_VECTOR (3 downto 0);            -- 192-189 internal PLL multiplication factor Mx
    signal  PLLCTRL                 : STD_LOGIC_VECTOR (1 downto 0);            -- 188-187 internal PLL dividing factor Dy
    signal  LVDSRECEN               : STD_LOGIC;                                -- 186 '0' internal PLL, '1' external PLL
    signal  TRAIN_DATA              : STD_LOGIC_VECTOR (11 downto 0);           -- 181-170 Training data X"98E"
    signal  CNT_ADC                 : STD_LOGIC_VECTOR (13 downto 0);           -- 165-152 start counting level of the internal counter
    -- reg
    signal  Spi_Wr_Data             : STD_LOGIC_VECTOR (255 downto 0);          -- write spi register
    signal  Spi_Rd_Data             : STD_LOGIC_VECTOR (271 downto 0);          -- read spi register and 16bit temperature
    signal  Sen_Temp                : STD_LOGIC_VECTOR (15 downto 0);           -- the temperature of sensor
    signal  SPI_OUT_r1              : STD_LOGIC;
    signal  SPI_OUT_r2              : STD_LOGIC;
    -- cnt
    signal  spi_wr_cnt              : integer range 0 to 257;                   -- count spi write bit
    signal  spi_rd_cnt              : integer range 0 to 272;                   -- count spi read bit
    -- fsm
    type    Fsm_Spi is (S_Idle, S_Write, S_Delay, S_Read);
    signal  state   : Fsm_Spi;

    -- attribute mark_debug    : string;
    -- attribute mark_debug    of Cmd_Wr_Spi           : signal is "true";
    -- attribute mark_debug    of Cmd_Rd_Spi           : signal is "true";
    -- attribute mark_debug    of state                : signal is "true";
    -- attribute mark_debug    of spi_wr_cnt           : signal is "true";
    -- attribute mark_debug    of spi_rd_cnt           : signal is "true";
    -- attribute mark_debug    of Spi_Wr_Data          : signal is "true";
    -- attribute mark_debug    of Spi_Rd_Data          : signal is "true";
    -- attribute mark_debug    of SPI_OUT              : signal is "true";
    -- attribute mark_debug    of SPI_CLK              : signal is "true";
    -- attribute mark_debug    of SPI_IN               : signal is "true";
    -- attribute mark_debug    of SPI_WRITE            : signal is "true";
    -- attribute mark_debug    of SPI_READ             : signal is "true";
    -- attribute mark_debug    of Spi_GainOdd             : signal is "true";
    -- attribute mark_debug    of Spi_GainEven            : signal is "true";

begin
    -- SPI register initialization value
    PLLDIV              <= "1011";              -- Mx default 1011=12
    PLLCTRL             <= "00";                -- Dy default 00=1
    LVDSRECEN           <= '1';                 -- PLL '0' internal, '1' external
    TRAIN_DATA          <= "100110001101";      -- X"98D"
    CNT_ADC             <= "11110111101010";

    -- 12bit spi register map for HDR
    Spi_Wr_Data <= "0000" & "0101" & "0000" & "0101" & "0111" & "0111" & "110010" & "110010" & "000000" & '0' &         -- 255-213
                    Gain_Odd & Gain_Even & '0' & '0' & '0' & '1' & '0' & '1' & '0' & '0' & '1' & '1' & '0' & '0' &      -- 212-195
                    '1' & '0' & PLLDIV & PLLCTRL & LVDSRECEN & "1010" & TRAIN_DATA & "0000" & CNT_ADC & "0000000" &     -- 194-145
                    "0000000" & "0000" & "000000" & "0111" & "0101" & "0111" & "011" & "010" & "0000000000" &           -- 144-100
                    "0000000000" & "0000000000" & "0000000000" & "0000000000" & "0000000000" & "0000000000" &           -- 99-40
                    "0000000000" & "0000000000" & "0000000000" & "0000000000";                                          -- 39-0

    SPI_CLK         <= not Clk_Ref;
    Sen_Temp        <= Spi_Rd_Data (15 downto 0);
    Spi_GainOdd     <= Spi_Rd_Data (228 downto 226);
    Spi_GainEven    <= Spi_Rd_Data (225 downto 223);

    process(Clk_Ref, Rst_Ref) begin
        if (Rst_Ref = '0') then
            SPI_OUT_r1  <= '0';
            SPI_OUT_r2  <= '0';
        elsif (Clk_Ref'event and Clk_Ref = '1') then
            SPI_OUT_r1  <= SPI_OUT;
            SPI_OUT_r2  <= SPI_OUT_r1;
        end if;
    end process;

    process(Clk_Ref, Rst_Ref) begin
        if (Rst_Ref = '0') then
            state       <= S_Idle;
            SPI_IN      <= '0';
            Spi_Wr_Done <= '0';
            Spi_Rd_Done <= '0';
            SPI_WRITE   <= '0';
            SPI_READ    <= '0';
            spi_wr_cnt  <= 0;
            spi_rd_cnt  <= 0;
            Spi_Rd_Data <= (others => '0');
        elsif (Clk_Ref'event and Clk_Ref = '1') then
            case state is
                when S_Idle =>
                    if (Cmd_Wr_Spi = '1') then
                        state       <= S_Write;
                    elsif (Cmd_Rd_Spi = '1') then
                        state       <= S_Delay;
                        SPI_READ    <= '1';
                    else
                        state       <= S_Idle;
                    end if;
                    Spi_Wr_Done <= '0';
                    Spi_Rd_Done <= '0';

                when S_Write =>
                    if (spi_wr_cnt = 257) then
                        state       <= S_Idle;
                        Spi_Wr_Done <= '1';
                        SPI_WRITE   <= '0';
                        spi_wr_cnt  <= 0;
                    elsif (spi_wr_cnt = 256) then
                        state       <= S_Write;
                        SPI_WRITE   <= '1';
                        spi_wr_cnt  <= spi_wr_cnt + 1;
                    else
                        state       <= S_Write;
                        SPI_IN      <= Spi_Wr_Data (255 - spi_wr_cnt);
                        SPI_WRITE   <= '0';
                        spi_wr_cnt  <= spi_wr_cnt + 1;
                    end if;

                when S_Delay =>
                    state   <= S_Read;

                when S_Read =>
                    if (spi_rd_cnt = 272) then
                        state       <= S_Idle;
                        Spi_Rd_Done <= '1';
                        spi_rd_cnt  <= 0;
                    elsif (spi_rd_cnt = 269) then
                        SPI_READ    <= '0';
                        Spi_Rd_Data (271 - spi_rd_cnt)  <= SPI_OUT_r2;
                        spi_rd_cnt  <= spi_rd_cnt + 1;
                    else
                        state       <= S_Read;
                        Spi_Rd_Data (271 - spi_rd_cnt)  <= SPI_OUT_r2;
                        spi_rd_cnt  <= spi_rd_cnt + 1;
                    end if;

                when others =>
                    state <= S_Idle;
            end case;
        end if;
    end process;
end Behavioral;