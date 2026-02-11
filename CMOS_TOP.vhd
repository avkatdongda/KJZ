----------------------------------------------------------------------------------
-- Company:         CIOMP
-- Engineer:        WangZheng
-- Create Date:     2025/01/06 09:04:13
-- Module Name:     TOP - Behavioral
-- Project Name:    CH4_G400
-- Target Devices:  XC7K325T
-- Tool Versions:   Vivado 2018.3
-- Description:     the top module of the project
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

entity CMOS_TOP is
    port (
        ---------TOP---------
        --CMOSA
        CMA_Set_Pulse                   : in  STD_LOGIC;                            -- the set signal pulse
        CMA_Shoot_Pulse                 : in  STD_LOGIC;                            -- the shoot signal pulse
        CMA_Image_Mode                  : in  STD_LOGIC_VECTOR (7 downto 0);        -- set image mode 11H shoot, 22H selfcheck1, 33H selfcheck2
        CMA_Exposure_Time               : in  STD_LOGIC_VECTOR (15 downto 0);       -- Exposure_Line 0000H~FFFFH default 0100H
        CMA_Gain_Value                  : in  STD_LOGIC_VECTOR (7 downto 0);        -- gain value, default odd 0100, even 0111
        CMA_Sen_Status                  : out STD_LOGIC_VECTOR (7 downto 0);        -- the status of sensor, 00H none, 01H training, 10H shooting
        CMA_Spi_Gain                    : out STD_LOGIC_VECTOR (7 downto 0);        -- read spi gain register, odd & even
        CMA_Sync_Rx                     : out STD_LOGIC;                            -- the one clk sync signal of every line
        CMA_Image_Out                   : out STD_LOGIC;                            -- pull high when the image's output is valid
        CMA_Data_Par_Chan1              : out STD_LOGIC_VECTOR (11 downto 0);       -- training output channel1 data
        CMA_Data_Par_Chan2              : out STD_LOGIC_VECTOR (11 downto 0);       -- training output channel2 data
        CMA_Data_Par_Chan3              : out STD_LOGIC_VECTOR (11 downto 0);       -- training output channel3 data
        CMA_Data_Par_Chan4              : out STD_LOGIC_VECTOR (11 downto 0);       -- training output channel4 data
        CMA_Data_Par_Chan5              : out STD_LOGIC_VECTOR (11 downto 0);       -- training output channel5 data
        CMA_Data_Par_Chan6              : out STD_LOGIC_VECTOR (11 downto 0);       -- training output channel6 data
        CMA_Data_Par_Chan7              : out STD_LOGIC_VECTOR (11 downto 0);       -- training output channel7 data
        CMA_Data_Par_Chan8              : out STD_LOGIC_VECTOR (11 downto 0);       -- training output channel8 data
        CMA_Self_Sync_Rx                : out STD_LOGIC;                            -- the one clk sync signal of every line
        CMA_Self_Image_Out              : out STD_LOGIC;                            -- pull high when the image is ready to output
        CMA_Self_Par_Chan1              : out STD_LOGIC_VECTOR (11 downto 0);       -- selfcheck output channel1 data
        CMA_Self_Par_Chan2              : out STD_LOGIC_VECTOR (11 downto 0);       -- selfcheck output channel2 data
        CMA_Self_Par_Chan3              : out STD_LOGIC_VECTOR (11 downto 0);       -- selfcheck output channel3 data
        CMA_Self_Par_Chan4              : out STD_LOGIC_VECTOR (11 downto 0);       -- selfcheck output channel4 data
        CMA_Self_Par_Chan5              : out STD_LOGIC_VECTOR (11 downto 0);       -- selfcheck output channel5 data
        CMA_Self_Par_Chan6              : out STD_LOGIC_VECTOR (11 downto 0);       -- selfcheck output channel6 data
        CMA_Self_Par_Chan7              : out STD_LOGIC_VECTOR (11 downto 0);       -- selfcheck output channel7 data
        CMA_Self_Par_Chan8              : out STD_LOGIC_VECTOR (11 downto 0);       -- selfcheck output channel8 data
        --CMOSB
        CMB_Set_Pulse                   : in  STD_LOGIC;                            -- the set signal pulse
        CMB_Shoot_Pulse                 : in  STD_LOGIC;                            -- the shoot signal pulse
        CMB_Image_Mode                  : in  STD_LOGIC_VECTOR (7 downto 0);        -- set image mode 11H shoot, 22H selfcheck1, 33H selfcheck2
        CMB_Exposure_Time               : in  STD_LOGIC_VECTOR (15 downto 0);       -- Exposure_Line 0000H~FFFFH default 0100H
        CMB_Gain_Value                  : in  STD_LOGIC_VECTOR (7 downto 0);        -- gain value, default odd 0100, even 0111
        CMB_Sen_Status                  : out STD_LOGIC_VECTOR (7 downto 0);        -- the status of sensor, 00H none, 01H training, 10H shooting
        CMB_Spi_Gain                    : out STD_LOGIC_VECTOR (7 downto 0);        -- read spi gain register, odd & even
        CMB_Sync_Rx                     : out STD_LOGIC;                            -- the one clk sync signal of every line
        CMB_Image_Out                   : out STD_LOGIC;                            -- pull high when the image's output is valid
        CMB_Data_Par_Chan1              : out STD_LOGIC_VECTOR (11 downto 0);       -- training output channel1 data
        CMB_Data_Par_Chan2              : out STD_LOGIC_VECTOR (11 downto 0);       -- training output channel2 data
        CMB_Data_Par_Chan3              : out STD_LOGIC_VECTOR (11 downto 0);       -- training output channel3 data
        CMB_Data_Par_Chan4              : out STD_LOGIC_VECTOR (11 downto 0);       -- training output channel4 data
        CMB_Data_Par_Chan5              : out STD_LOGIC_VECTOR (11 downto 0);       -- training output channel5 data
        CMB_Data_Par_Chan6              : out STD_LOGIC_VECTOR (11 downto 0);       -- training output channel6 data
        CMB_Data_Par_Chan7              : out STD_LOGIC_VECTOR (11 downto 0);       -- training output channel7 data
        CMB_Data_Par_Chan8              : out STD_LOGIC_VECTOR (11 downto 0);       -- training output channel8 data
        CMB_Self_Sync_Rx                : out STD_LOGIC;                            -- the one clk sync signal of every line
        CMB_Self_Image_Out              : out STD_LOGIC;                            -- pull high when the image is ready to output
        CMB_Self_Par_Chan1              : out STD_LOGIC_VECTOR (11 downto 0);       -- selfcheck output channel1 data
        CMB_Self_Par_Chan2              : out STD_LOGIC_VECTOR (11 downto 0);       -- selfcheck output channel2 data
        CMB_Self_Par_Chan3              : out STD_LOGIC_VECTOR (11 downto 0);       -- selfcheck output channel3 data
        CMB_Self_Par_Chan4              : out STD_LOGIC_VECTOR (11 downto 0);       -- selfcheck output channel4 data
        CMB_Self_Par_Chan5              : out STD_LOGIC_VECTOR (11 downto 0);       -- selfcheck output channel5 data
        CMB_Self_Par_Chan6              : out STD_LOGIC_VECTOR (11 downto 0);       -- selfcheck output channel6 data
        CMB_Self_Par_Chan7              : out STD_LOGIC_VECTOR (11 downto 0);       -- selfcheck output channel7 data
        CMB_Self_Par_Chan8              : out STD_LOGIC_VECTOR (11 downto 0);       -- selfcheck output channel8 data
        ---------pin---------
        -- CLOCKING
        FPGA_CLK80M                 : in  STD_LOGIC;                            -- FPGA clk input 80MHz
        -- CMOSA
        SUP_EN1                     : out STD_LOGIC;                            -- CMOSA supply1
        SUP_EN2                     : out STD_LOGIC;                            -- CMOSA supply1
        SUP_EN3                     : out STD_LOGIC;                            -- CMOSA supply1
        SUP_EN4                     : out STD_LOGIC;                            -- CMOSA supply2
        SUP_EN5                     : out STD_LOGIC;                            -- CMOSA supply2
        SUP_EN6                     : out STD_LOGIC;                            -- CMOSA supply2
        SUP_EN7                     : out STD_LOGIC;                            -- CMOSA supply2
        SUP_EN8                     : out STD_LOGIC;                            -- CMOSA supply2
        CMA_CLK_REF                 : out STD_LOGIC;                            -- CMOSA reference clock
        CMA_CLK_PIX                 : in  STD_LOGIC;                            -- CMOSA pixel clock
        CMA_SEN_RST_N               : out STD_LOGIC;                            -- the rst of CMOSA, low level valid
        CMA_SPI_OUT                 : in  STD_LOGIC;                            -- CMOSA spi output signal
        CMA_SPI_CLK                 : out STD_LOGIC;                            -- CMOSA spi clk in 20MHz/50ns
        CMA_SPI_IN                  : out STD_LOGIC;                            -- CMOSA spi input signal
        CMA_SPI_WRITE               : out STD_LOGIC;                            -- the enable of writing CMOSA spi
        CMA_SPI_READ                : out STD_LOGIC;                            -- the enable of reading CMOSA spi
        CMA_ROW                     : out STD_LOGIC_VECTOR (11 downto 0);       -- CMOSA read and reset addr
        CMA_TX                      : out STD_LOGIC;
        CMA_RS                      : out STD_LOGIC;
        CMA_RST                     : out STD_LOGIC;
        CMA_HDR                     : out STD_LOGIC;
        CMA_TAZ                     : out STD_LOGIC;
        CMA_TAB                     : out STD_LOGIC;
        CMA_TPC                     : out STD_LOGIC;
        CMA_TINITO                  : out STD_LOGIC;
        CMA_TINITE                  : out STD_LOGIC;
        CMA_TSO                     : out STD_LOGIC;
        CMA_TSE                     : out STD_LOGIC;
        CMA_TAC                     : out STD_LOGIC;
        CMA_TRD                     : out STD_LOGIC;
        CMA_TADR                    : out STD_LOGIC;
        CMA_TADS                    : out STD_LOGIC;
        CMA_TWS                     : out STD_LOGIC;
        CMA_SYNC                    : out STD_LOGIC;
        CMA_TBS                     : out STD_LOGIC;
        CMA_TS                      : out STD_LOGIC;
        CMA_TRAIN                   : out STD_LOGIC;
        CMA_DATA_SER_P              : in  STD_LOGIC_VECTOR (7 downto 0);        -- the positive LVDS outputs of CMOSA, 8 channels
        CMA_DATA_SER_N              : in  STD_LOGIC_VECTOR (7 downto 0);        -- the negative LVDS outputs of CMOSA, 8 channels
        -- CMOSB
        SUP_EN9                     : out STD_LOGIC;                            -- CMOSB supply1
        SUP_EN10                    : out STD_LOGIC;                            -- CMOSB supply1
        SUP_EN11                    : out STD_LOGIC;                            -- CMOSB supply1
        SUP_EN12                    : out STD_LOGIC;                            -- CMOSB supply2
        SUP_EN13                    : out STD_LOGIC;                            -- CMOSB supply2
        SUP_EN14                    : out STD_LOGIC;                            -- CMOSB supply2
        SUP_EN15                    : out STD_LOGIC;                            -- CMOSB supply2
        SUP_EN16                    : out STD_LOGIC;                            -- CMOSB supply2
        CMB_CLK_REF                 : out STD_LOGIC;                            -- CMOSB reference clock
        CMB_CLK_PIX                 : in  STD_LOGIC;                            -- CMOSB pixel clock
        CMB_SEN_RST_N               : out STD_LOGIC;                            -- the rst of CMOSB, low level valid
        CMB_SPI_OUT                 : in  STD_LOGIC;                            -- CMOSB spi output signal
        CMB_SPI_CLK                 : out STD_LOGIC;                            -- CMOSB spi clk in 20MHz/50ns
        CMB_SPI_IN                  : out STD_LOGIC;                            -- CMOSB spi input signal
        CMB_SPI_WRITE               : out STD_LOGIC;                            -- the enable of writing CMOSB spi
        CMB_SPI_READ                : out STD_LOGIC;                            -- the enable of reading CMOSB spi
        CMB_ROW                     : out STD_LOGIC_VECTOR (11 downto 0);       -- CMOSB read and reset addr
        CMB_TX                      : out STD_LOGIC;
        CMB_RS                      : out STD_LOGIC;
        CMB_RST                     : out STD_LOGIC;
        CMB_HDR                     : out STD_LOGIC;
        CMB_TAZ                     : out STD_LOGIC;
        CMB_TAB                     : out STD_LOGIC;
        CMB_TPC                     : out STD_LOGIC;
        CMB_TINITO                  : out STD_LOGIC;
        CMB_TINITE                  : out STD_LOGIC;
        CMB_TSO                     : out STD_LOGIC;
        CMB_TSE                     : out STD_LOGIC;
        CMB_TAC                     : out STD_LOGIC;
        CMB_TRD                     : out STD_LOGIC;
        CMB_TADR                    : out STD_LOGIC;
        CMB_TADS                    : out STD_LOGIC;
        CMB_TWS                     : out STD_LOGIC;
        CMB_SYNC                    : out STD_LOGIC;
        CMB_TBS                     : out STD_LOGIC;
        CMB_TS                      : out STD_LOGIC;
        CMB_TRAIN                   : out STD_LOGIC;
        CMB_DATA_SER_P              : in  STD_LOGIC_VECTOR (7 downto 0);        -- the positive LVDS outputs of CMOSA, 8 channels
        CMB_DATA_SER_N              : in  STD_LOGIC_VECTOR (7 downto 0));       -- the negative LVDS outputs of CMOSA, 8 channels
end CMOS_TOP;

architecture Behavioral of CMOS_TOP is

    ---------CLOCKING---------
    signal  Clk_Sys                 : STD_LOGIC;                                -- system clk 80MHz
    signal  Rst_Sys                 : STD_LOGIC;                                -- Clk_Sys correspond rst signal
    signal  Clk_Ref                 : STD_LOGIC;                                -- cmos main clk 25MHz, same as CLK_PIX in datasheet
    signal  Rst_Ref                 : STD_LOGIC;                                -- Clk_Ref correspond rst signal
    signal  Clk_Ddr                 : STD_LOGIC;                                -- cmos sample ddr clk, 120MHz
    signal  Rst_Ddr                 : STD_LOGIC;                                -- Clk_Ddr correspond rst signal
    ---------SENSOR---------
    signal  CMA_Sen_Supply1         : STD_LOGIC;
    signal  CMA_Sen_Supply2         : STD_LOGIC;
    signal  CMB_Sen_Supply1         : STD_LOGIC;
    signal  CMB_Sen_Supply2         : STD_LOGIC;

    component CLOCKING is
    port (
        -- CLOCKING_pin
        FPGA_CLK80M                 : in  STD_LOGIC;                            -- FPGA input clk 80MHz
        ---------OTHERS---------
        Clk_Ref                     : out STD_LOGIC;                            -- cmos main clk 25MHz, same as CLK_PIX in datasheet
        Rst_Ref                     : out STD_LOGIC;                            -- Clk_Ref correspond rst signal
        Clk_Sys                     : out STD_LOGIC;                            -- system clk 80MHz
        Rst_Sys                     : out STD_LOGIC;                            -- Clk_Sys correspond rst signal
        Clk_Ddr                     : out STD_LOGIC;                            -- cmos sample ddr clk, 150MHz
        Rst_Ddr                     : out STD_LOGIC);                           -- Clk_Ddr correspond rst signal
    end component;

    component SENSOR is
    generic (
        Cms_Delay                   : STD_LOGIC_VECTOR (11 downto 0):= X"001"); -- 1ms
    port (
        ---------TOP---------
        Sen_Supply1                 : out STD_LOGIC;                            -- sensor supply1 signal
        Sen_Supply2                 : out STD_LOGIC;                            -- sensor supply2 signal
        Set_Pulse                   : in  STD_LOGIC;                            -- the set signal pulse
        Shoot_Pulse                 : in  STD_LOGIC;                            -- the shoot signal pulse
        Image_Mode                  : in  STD_LOGIC_VECTOR (7 downto 0);        -- set image mode 11H shoot, 22H selfcheck1, 33H selfcheck2
        Exposure_Time               : in  STD_LOGIC_VECTOR (15 downto 0);       -- Exposure_Line 0000H~FFFFH default 0100H
        Gain_Value                  : in  STD_LOGIC_VECTOR (7 downto 0);        -- gain value, default odd 0100, even 0111
        Sen_Status                  : out STD_LOGIC_VECTOR (7 downto 0);        -- the status of sensor, 00H none, 01H training, 10H shooting
        Spi_Gain                    : out STD_LOGIC_VECTOR (7 downto 0);        -- read spi gain register, odd & even
        Sync_Rx                     : out STD_LOGIC;                            -- the one clk sync signal of every line
        Image_Out                   : out STD_LOGIC;                            -- pull high when the image's output is valid
        Data_Par_Chan1              : out STD_LOGIC_VECTOR (11 downto 0);       -- training output channel1 data
        Data_Par_Chan2              : out STD_LOGIC_VECTOR (11 downto 0);       -- training output channel2 data
        Data_Par_Chan3              : out STD_LOGIC_VECTOR (11 downto 0);       -- training output channel3 data
        Data_Par_Chan4              : out STD_LOGIC_VECTOR (11 downto 0);       -- training output channel4 data
        Data_Par_Chan5              : out STD_LOGIC_VECTOR (11 downto 0);       -- training output channel5 data
        Data_Par_Chan6              : out STD_LOGIC_VECTOR (11 downto 0);       -- training output channel6 data
        Data_Par_Chan7              : out STD_LOGIC_VECTOR (11 downto 0);       -- training output channel7 data
        Data_Par_Chan8              : out STD_LOGIC_VECTOR (11 downto 0);       -- training output channel8 data
        Self_Sync_Rx                : out STD_LOGIC;                            -- the one clk sync signal of every line
        Self_Image_Out              : out STD_LOGIC;                            -- pull high when the image is ready to output
        Self_Par_Chan1              : out STD_LOGIC_VECTOR (11 downto 0);       -- selfcheck output channel1 data
        Self_Par_Chan2              : out STD_LOGIC_VECTOR (11 downto 0);       -- selfcheck output channel2 data
        Self_Par_Chan3              : out STD_LOGIC_VECTOR (11 downto 0);       -- selfcheck output channel3 data
        Self_Par_Chan4              : out STD_LOGIC_VECTOR (11 downto 0);       -- selfcheck output channel4 data
        Self_Par_Chan5              : out STD_LOGIC_VECTOR (11 downto 0);       -- selfcheck output channel5 data
        Self_Par_Chan6              : out STD_LOGIC_VECTOR (11 downto 0);       -- selfcheck output channel6 data
        Self_Par_Chan7              : out STD_LOGIC_VECTOR (11 downto 0);       -- selfcheck output channel7 data
        Self_Par_Chan8              : out STD_LOGIC_VECTOR (11 downto 0);       -- selfcheck output channel8 data
        ---------CLOCKING---------
        Clk_Ref                     : in  STD_LOGIC;                            -- cmos main clk 25MHz, same as CLK_PIX in datasheet
        Rst_Ref                     : in  STD_LOGIC;                            -- Clk_Ref correspond rst signal
        Clk_Sys                     : in  STD_LOGIC;                            -- system clk 80MHz
        Rst_Sys                     : in  STD_LOGIC;                            -- Clk_Sys correspond rst signal
        Clk_Ddr                     : in  STD_LOGIC;                            -- cmos sample ddr clk, 150MHz
        Rst_Ddr                     : in  STD_LOGIC;                            -- Clk_Ddr correspond rst signal
        ---------pin---------
        --SEN_CTRL
        SEN_RST_N                   : out STD_LOGIC;                            -- the rst of sensor, low level valid
        --SEN_SPI
        SPI_OUT                     : in  STD_LOGIC;                            -- sensor spi output signal
        SPI_CLK                     : out STD_LOGIC;                            -- sensor spi clk in 25MHz/50ns
        SPI_IN                      : out STD_LOGIC;                            -- sensor spi input signal
        SPI_WRITE                   : out STD_LOGIC;                            -- the enable of of writing spi
        SPI_READ                    : out STD_LOGIC;                            -- the enable of of reading spi
        --SEN_DRIVE
        ROW                         : out STD_LOGIC_VECTOR (11 downto 0);       -- sensor read and reset addr
        TX                          : out STD_LOGIC;                            -- digital control signal
        RS                          : out STD_LOGIC;                            -- digital control signal
        RST                         : out STD_LOGIC;                            -- digital control signal
        HDR                         : out STD_LOGIC;                            -- digital control signal
        TAZ                         : out STD_LOGIC;                            -- digital control signal
        TAB                         : out STD_LOGIC;                            -- digital control signal
        TPC                         : out STD_LOGIC;                            -- digital control signal
        TINITO                      : out STD_LOGIC;                            -- digital control signal
        TINITE                      : out STD_LOGIC;                            -- digital control signal
        TSO                         : out STD_LOGIC;                            -- digital control signal
        TSE                         : out STD_LOGIC;                            -- digital control signal
        TAC                         : out STD_LOGIC;                            -- digital control signal
        TRD                         : out STD_LOGIC;                            -- digital control signal
        TADR                        : out STD_LOGIC;                            -- digital control signal
        TADS                        : out STD_LOGIC;                            -- digital control signal
        TWS                         : out STD_LOGIC;                            -- digital control signal
        SYNC                        : out STD_LOGIC;                            -- digital control signal
        TBS                         : out STD_LOGIC;                            -- digital control signal
        TS                          : out STD_LOGIC;                            -- digital control signal
        TRAIN                       : out STD_LOGIC;                            -- digital control signal
        --TRAINING
        DATA_SER_P                  : in  STD_LOGIC_VECTOR (7 downto 0);        -- the positive LVDS outputs of the sensor, 8 channels
        DATA_SER_N                  : in  STD_LOGIC_VECTOR (7 downto 0));       -- the negative LVDS outputs of the sensor, 8 channels
    end component;

begin
    --CMOSA
    SUP_EN1     <= CMA_Sen_Supply1;
    SUP_EN2     <= '1';
    SUP_EN3     <= CMA_Sen_Supply1;
    SUP_EN4     <= CMA_Sen_Supply2;
    SUP_EN5     <= CMA_Sen_Supply2;
    SUP_EN6     <= CMA_Sen_Supply2;
    SUP_EN7     <= CMA_Sen_Supply2;
    SUP_EN8     <= CMA_Sen_Supply2;
    CMA_CLK_REF <= Clk_Ref;
    --CMOSB
    SUP_EN9     <= CMB_Sen_Supply1;
    SUP_EN10    <= '1';
    SUP_EN11    <= CMB_Sen_Supply1;
    SUP_EN12    <= CMB_Sen_Supply2;
    SUP_EN13    <= CMB_Sen_Supply2;
    SUP_EN14    <= CMB_Sen_Supply2;
    SUP_EN15    <= CMB_Sen_Supply2;
    SUP_EN16    <= CMB_Sen_Supply2;
    CMB_CLK_REF <= Clk_Ref;

    U1 : CLOCKING
    port map (
        FPGA_CLK80M                 => FPGA_CLK80M,
        Clk_Ref                     => Clk_Ref,
        Rst_Ref                     => Rst_Ref,
        Clk_Sys                     => Clk_Sys,
        Rst_Sys                     => Rst_Sys,
        Clk_Ddr                     => Clk_Ddr,
        Rst_Ddr                     => Rst_Ddr);

    U2 : SENSOR
    generic map (
        Cms_Delay                   => X"001")      --1ms
    port map (
        Sen_Supply1                 => CMA_Sen_Supply1,
        Sen_Supply2                 => CMA_Sen_Supply2,
        Set_Pulse                   => CMA_Set_Pulse,
        Shoot_Pulse                 => CMA_Shoot_Pulse,
        Image_Mode                  => CMA_Image_Mode,
        Exposure_Time               => CMA_Exposure_Time,
        Gain_Value                  => CMA_Gain_Value,
        Sen_Status                  => CMA_Sen_Status,
        Spi_Gain                    => CMA_Spi_Gain,
        Sync_Rx                     => CMA_Sync_Rx,
        Image_Out                   => CMA_Image_Out,
        Data_Par_Chan1              => CMA_Data_Par_Chan1,
        Data_Par_Chan2              => CMA_Data_Par_Chan2,
        Data_Par_Chan3              => CMA_Data_Par_Chan3,
        Data_Par_Chan4              => CMA_Data_Par_Chan4,
        Data_Par_Chan5              => CMA_Data_Par_Chan5,
        Data_Par_Chan6              => CMA_Data_Par_Chan6,
        Data_Par_Chan7              => CMA_Data_Par_Chan7,
        Data_Par_Chan8              => CMA_Data_Par_Chan8,
        Self_Sync_Rx                => CMA_Self_Sync_Rx,
        Self_Image_Out              => CMA_Self_Image_Out,
        Self_Par_Chan1              => CMA_Self_Par_Chan1,
        Self_Par_Chan2              => CMA_Self_Par_Chan2,
        Self_Par_Chan3              => CMA_Self_Par_Chan3,
        Self_Par_Chan4              => CMA_Self_Par_Chan4,
        Self_Par_Chan5              => CMA_Self_Par_Chan5,
        Self_Par_Chan6              => CMA_Self_Par_Chan6,
        Self_Par_Chan7              => CMA_Self_Par_Chan7,
        Self_Par_Chan8              => CMA_Self_Par_Chan8,
        Clk_Ref                     => Clk_Ref,
        Rst_Ref                     => Rst_Ref,
        Clk_Sys                     => Clk_Sys,
        Rst_Sys                     => Rst_Sys,
        Clk_Ddr                     => Clk_Ddr,
        Rst_Ddr                     => Rst_Ddr,
        SEN_RST_N                   => CMA_SEN_RST_N,
        SPI_OUT                     => CMA_SPI_OUT,
        SPI_CLK                     => CMA_SPI_CLK,
        SPI_IN                      => CMA_SPI_IN,
        SPI_WRITE                   => CMA_SPI_WRITE,
        SPI_READ                    => CMA_SPI_READ,
        ROW                         => CMA_ROW,
        TX                          => CMA_TX,
        RS                          => CMA_RS,
        RST                         => CMA_RST,
        HDR                         => CMA_HDR,
        TAZ                         => CMA_TAZ,
        TAB                         => CMA_TAB,
        TPC                         => CMA_TPC,
        TINITO                      => CMA_TINITO,
        TINITE                      => CMA_TINITE,
        TSO                         => CMA_TSO,
        TSE                         => CMA_TSE,
        TAC                         => CMA_TAC,
        TRD                         => CMA_TRD,
        TADR                        => CMA_TADR,
        TADS                        => CMA_TADS,
        TWS                         => CMA_TWS,
        SYNC                        => CMA_SYNC,
        TBS                         => CMA_TBS,
        TS                          => CMA_TS,
        TRAIN                       => CMA_TRAIN,
        DATA_SER_P                  => CMA_DATA_SER_P,
        DATA_SER_N                  => CMA_DATA_SER_N);

    U3 : SENSOR
    generic map (
        Cms_Delay                   => X"0C8")      --200ms
    port map (
        Sen_Supply1                 => CMB_Sen_Supply1,
        Sen_Supply2                 => CMB_Sen_Supply2,
        Set_Pulse                   => CMB_Set_Pulse,
        Shoot_Pulse                 => CMB_Shoot_Pulse,
        Image_Mode                  => CMB_Image_Mode,
        Exposure_Time               => CMB_Exposure_Time,
        Gain_Value                  => CMB_Gain_Value,
        Sen_Status                  => CMB_Sen_Status,
        Spi_Gain                    => CMB_Spi_Gain,
        Sync_Rx                     => CMB_Sync_Rx,
        Image_Out                   => CMB_Image_Out,
        Data_Par_Chan1              => CMB_Data_Par_Chan1,
        Data_Par_Chan2              => CMB_Data_Par_Chan2,
        Data_Par_Chan3              => CMB_Data_Par_Chan3,
        Data_Par_Chan4              => CMB_Data_Par_Chan4,
        Data_Par_Chan5              => CMB_Data_Par_Chan5,
        Data_Par_Chan6              => CMB_Data_Par_Chan6,
        Data_Par_Chan7              => CMB_Data_Par_Chan7,
        Data_Par_Chan8              => CMB_Data_Par_Chan8,
        Self_Sync_Rx                => CMB_Self_Sync_Rx,
        Self_Image_Out              => CMB_Self_Image_Out,
        Self_Par_Chan1              => CMB_Self_Par_Chan1,
        Self_Par_Chan2              => CMB_Self_Par_Chan2,
        Self_Par_Chan3              => CMB_Self_Par_Chan3,
        Self_Par_Chan4              => CMB_Self_Par_Chan4,
        Self_Par_Chan5              => CMB_Self_Par_Chan5,
        Self_Par_Chan6              => CMB_Self_Par_Chan6,
        Self_Par_Chan7              => CMB_Self_Par_Chan7,
        Self_Par_Chan8              => CMB_Self_Par_Chan8,
        Clk_Ref                     => Clk_Ref,
        Rst_Ref                     => Rst_Ref,
        Clk_Sys                     => Clk_Sys,
        Rst_Sys                     => Rst_Sys,
        Clk_Ddr                     => Clk_Ddr,
        Rst_Ddr                     => Rst_Ddr,
        SEN_RST_N                   => CMB_SEN_RST_N,
        SPI_OUT                     => CMB_SPI_OUT,
        SPI_CLK                     => CMB_SPI_CLK,
        SPI_IN                      => CMB_SPI_IN,
        SPI_WRITE                   => CMB_SPI_WRITE,
        SPI_READ                    => CMB_SPI_READ,
        ROW                         => CMB_ROW,
        TX                          => CMB_TX,
        RS                          => CMB_RS,
        RST                         => CMB_RST,
        HDR                         => CMB_HDR,
        TAZ                         => CMB_TAZ,
        TAB                         => CMB_TAB,
        TPC                         => CMB_TPC,
        TINITO                      => CMB_TINITO,
        TINITE                      => CMB_TINITE,
        TSO                         => CMB_TSO,
        TSE                         => CMB_TSE,
        TAC                         => CMB_TAC,
        TRD                         => CMB_TRD,
        TADR                        => CMB_TADR,
        TADS                        => CMB_TADS,
        TWS                         => CMB_TWS,
        SYNC                        => CMB_SYNC,
        TBS                         => CMB_TBS,
        TS                          => CMB_TS,
        TRAIN                       => CMB_TRAIN,
        DATA_SER_P                  => CMB_DATA_SER_P,
        DATA_SER_N                  => CMB_DATA_SER_N);

end Behavioral;