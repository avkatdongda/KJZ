----------------------------------------------------------------------------------
-- Company:         CIOMP
-- Engineer:        WangZheng
-- Create Date:     2025/02/22 09:00:58
-- Module Name:     SENSOR - Behavioral
-- Project Name:    CH4_G400
-- Target Devices:  xc7k325tffg900-2
-- Tool Versions:   Vivado 2018.3
-- Description:     SENSOR top module, include drive, spi, training, check image
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

entity SENSOR is
    generic (
        Cms_Delay                   : STD_LOGIC_VECTOR (11 downto 0):= X"001"); -- 1ms
    port (
        ---------TOP---------
        Power_On                    : in  STD_LOGIC;                            -- sensor power supply, 1 power on, 0 power off
        Sen_Supply1                 : out STD_LOGIC;                            -- sensor supply1 signal
        Sen_Supply2                 : out STD_LOGIC;                            -- sensor supply2 signal
        Sen_Supply3                 : out STD_LOGIC;                            -- sensor supply2 signal
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
end SENSOR;

architecture Behavioral of SENSOR is
    ---------SEN_CTRL---------
    signal  Gain_Odd                : STD_LOGIC_VECTOR (2 downto 0);            -- low gain default 100 1.29x
    signal  Gain_Even               : STD_LOGIC_VECTOR (2 downto 0);            -- high gain default 111 7.25x
    signal  Cmd_Wr_Spi              : STD_LOGIC;                                -- the command of writing spi
    signal  Cmd_Rd_Spi              : STD_LOGIC;                                -- the command of reading spi
    signal  Cmd_Drive               : STD_LOGIC;                                -- the command of shooting
    signal  Cmd_Check1              : STD_LOGIC;                                -- the command of check1 signal
    signal  Exposure_Line           : STD_LOGIC_VECTOR (15 downto 0);           -- Exposure_Line 0000H~FFFFH default 0100H
    signal  Cmd_Check2              : STD_LOGIC;                                -- the command of check2 signal
    signal  Cmd_Train               : STD_LOGIC;                                -- the command of starting training
    ---------SEN_SPI---------
    signal  Spi_GainOdd             : STD_LOGIC_VECTOR (2 downto 0);            -- read spi low gain register
    signal  Spi_GainEven            : STD_LOGIC_VECTOR (2 downto 0);            -- read spi high gain register
    signal  Spi_Wr_Done             : STD_LOGIC;                                -- the finish signal of writing spi, '1' is valid
    signal  Spi_Rd_Done             : STD_LOGIC;                                -- the finish signal of reading spi, '1' is valid
    ---------SEN_DRIVE---------
    signal  Train_DRI               : STD_LOGIC;                                -- digital control signal in SEN_DRIVE
    signal  Frame_Circle            : STD_LOGIC_VECTOR (7 downto 0);            -- count the circle of 2048 rows
    ---------TRAINING---------
    signal  Train_TRA               : STD_LOGIC;                                -- digital control signal in TRAINING
    signal  Train_Done              : STD_LOGIC;                                -- the sign of training completion
    ---------IMA_GEN---------
    signal  Frame_Circle_S          : STD_LOGIC_VECTOR (7 downto 0);            -- count the circle of 2048 rows in selfcheck2

    component SEN_CTRL is
    generic (
        Cms_Delay                   : STD_LOGIC_VECTOR (11 downto 0):= X"001"); -- 1ms
    port (
        ---------pin---------
        SEN_RST_N                   : out STD_LOGIC;                            -- the rst of sensor, low level valid
        ---------CLOCKING---------
        Clk_Ref                     : in  STD_LOGIC;                            -- sensor main clk 25MHz, same as CLK_PIX in datasheet
        Rst_Ref                     : in  STD_LOGIC;                            -- Clk_Ref correspond rst signal
        ---------TOP---------
        Power_On                    : in  STD_LOGIC;                            -- sensor power supply, 1 power on, 0 power off
        Sen_Supply1                 : out STD_LOGIC;                            -- sensor supply1 signal
        Sen_Supply2                 : out STD_LOGIC;                            -- sensor supply2 signal
        Sen_Supply3                 : out STD_LOGIC;                            -- sensor supply3 signal
        Set_Pulse                   : in  STD_LOGIC;                            -- the set signal pulse
        Shoot_Pulse                 : in  STD_LOGIC;                            -- the shoot signal pulse
        Image_Mode                  : in  STD_LOGIC_VECTOR (7 downto 0);        -- set image mode 11H shoot, 22H selfcheck1, 33H selfcheck2
        Exposure_Time               : in  STD_LOGIC_VECTOR (15 downto 0);       -- Exposure_Line 0000H~FFFFH default 0100H
        Gain_Value                  : in  STD_LOGIC_VECTOR (7 downto 0);        -- gain value, default odd 0100, even 0111
        Sen_Status                  : out STD_LOGIC_VECTOR (7 downto 0);        -- the status of sensor, 00H none, 01H training, 10H shooting
        -------SEN_SPI---------
        Gain_Odd                    : out STD_LOGIC_VECTOR (2 downto 0);        -- low gain default 100 1.29x
        Gain_Even                   : out STD_LOGIC_VECTOR (2 downto 0);        -- high gain default 111 7.25x
        Cmd_Wr_Spi                  : out STD_LOGIC;                            -- the command of writing spi
        Cmd_Rd_Spi                  : out STD_LOGIC;                            -- the command of reading spi
        Spi_Wr_Done                 : in  STD_LOGIC;                            -- the finish signal of writing spi, '1' is valid
        Spi_Rd_Done                 : in  STD_LOGIC;                            -- the finish signal of reading spi, '1' is valid
        -------SEN_DRIVE---------
        Frame_Circle                : in  STD_LOGIC_VECTOR (7 downto 0);        -- count the circle of 2048 rows
        Cmd_Drive                   : out STD_LOGIC;                            -- the command of driving ctrl signal
        Cmd_Check1                  : out STD_LOGIC;                            -- the command of check1 signal
        Exposure_Line               : out STD_LOGIC_VECTOR (15 downto 0);       -- Exposure_Line 0000H~FFFFH default 0100H
        -------IMA_GEN---------
        Cmd_Check2                  : out STD_LOGIC;                            -- the command of check2 signal
        Frame_Circle_S              : in  STD_LOGIC_VECTOR (7 downto 0);        -- count the circle of 2048 rows
        -------TRAINING---------
        Train_Done                  : in  STD_LOGIC;                            -- the sign of training completion
        Cmd_Train                   : out STD_LOGIC);                           -- the command of starting training
    end component;

    component SEN_SPI is
    port (
        ---------CLOCKING---------
        Clk_Ref                     : in  STD_LOGIC;                            -- sensor main clk 25MHz, same as CLK_PIX in datasheet
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
    end component;

    component SEN_DRIVE is
    port (
        ---------SENSOR------------------
        Train_DRI                   : out STD_LOGIC;                            -- digital control signal in SEN_DRIVE
        ---------CLOCKING---------
        Clk_Ref                     : in  STD_LOGIC;                            -- sensor main clk 25MHz, same as CLK_PIX in datasheet
        Rst_Ref                     : in  STD_LOGIC;                            -- Clk_Ref correspond rst signal
        ---------pin---------
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
        ---------SEN_CTRL---------
        Exposure_Line               : in  STD_LOGIC_VECTOR (15 downto 0);       -- Exposure_Line 0000H~FFFFH default 0100H
        Cmd_Drive                   : in  STD_LOGIC;                            -- the command of shooting
        Cmd_Check1                  : in  STD_LOGIC;                            -- the command of check1 signal
        Frame_Circle                : out STD_LOGIC_VECTOR (7 downto 0);        -- count the circle of 2048 rows
        ---------TOP---------
        Sync_Rx                     : out STD_LOGIC;                            -- the one clk sync signal of every line
        Image_Out                   : out STD_LOGIC);                           -- pull high when the image's output is valid
    end component;

    component TRAINING is
    port (
        ---------SENSOR------------------
        Train_TRA                   : out STD_LOGIC;                            -- digital control signal in TRAINING
         ---------CLOCKING---------
        Clk_Ref                     : in  STD_LOGIC;                            -- cmos main clk 25MHz, same as CLK_PIX in datasheet
        Rst_Ref                     : in  STD_LOGIC;                            -- Clk_Ref correspond rst signal
        Clk_Ddr                     : in  STD_LOGIC;                            -- cmos sample ddr clk, 150MHz
        Rst_Ddr                     : in  STD_LOGIC;                            -- Clk_Ddr correspond rst signal
        ---------pin---------
        DATA_SER_P                  : in  STD_LOGIC_VECTOR (7 downto 0);        -- the positive LVDS outputs of the sensor, 8 channels
        DATA_SER_N                  : in  STD_LOGIC_VECTOR (7 downto 0);        -- the negative LVDS outputs of the sensor, 8 channels
        ---------SEN_CTRL---------
        Cmd_Train                   : in  STD_LOGIC;                            -- the command of starting training
        Train_Done                  : out STD_LOGIC;                            -- the sign of training completion
        ---------TOP---------
        Data_Par_Chan1              : out STD_LOGIC_VECTOR (11 downto 0);       -- training output channel1 data
        Data_Par_Chan2              : out STD_LOGIC_VECTOR (11 downto 0);       -- training output channel2 data
        Data_Par_Chan3              : out STD_LOGIC_VECTOR (11 downto 0);       -- training output channel3 data
        Data_Par_Chan4              : out STD_LOGIC_VECTOR (11 downto 0);       -- training output channel4 data
        Data_Par_Chan5              : out STD_LOGIC_VECTOR (11 downto 0);       -- training output channel5 data
        Data_Par_Chan6              : out STD_LOGIC_VECTOR (11 downto 0);       -- training output channel6 data
        Data_Par_Chan7              : out STD_LOGIC_VECTOR (11 downto 0);       -- training output channel7 data
        Data_Par_Chan8              : out STD_LOGIC_VECTOR (11 downto 0));      -- training output channel8 data
    end component;

    component IMA_GEN is
    port (
        ---------CLOCKING---------
        Clk_Ref                     : in  STD_LOGIC;                            -- sensor main clk 25MHz, same as CLK_PIX in datasheet
        Rst_Ref                     : in  STD_LOGIC;                            -- Clk_Ref correspond rst signal
        ---------TOP---------
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
        ---------SEN_CTRL---------
        Cmd_Check2                  : in  STD_LOGIC;                            -- the command of downing selfcheck image
        Frame_Circle_S              : out STD_LOGIC_VECTOR (7 downto 0));       -- count the circle of 2048 rows in selfcheck2
    end component;

begin

    TRAIN       <= Train_DRI or Train_TRA;
    Spi_Gain    <= '0' & Spi_GainOdd & '0' & Spi_GainEven;

    U21 : SEN_CTRL
    generic map (
        Cms_Delay                   => Cms_Delay)
    port map (
        SEN_RST_N                   => SEN_RST_N,
        Clk_Ref                     => Clk_Ref,
        Rst_Ref                     => Rst_Ref,
        Power_On                    => Power_On,
        Sen_Supply1                 => Sen_Supply1,
        Sen_Supply2                 => Sen_Supply2,
        Sen_Supply3                 => Sen_Supply3,
        Set_Pulse                   => Set_Pulse,
        Shoot_Pulse                 => Shoot_Pulse,
        Image_Mode                  => Image_Mode,
        Exposure_Time               => Exposure_Time,
        Gain_Value                  => Gain_Value,
        Sen_Status                  => Sen_Status,
        Gain_Odd                    => Gain_Odd,
        Gain_Even                   => Gain_Even,
        Cmd_Wr_Spi                  => Cmd_Wr_Spi,
        Cmd_Rd_Spi                  => Cmd_Rd_Spi,
        Spi_Wr_Done                 => Spi_Wr_Done,
        Spi_Rd_Done                 => Spi_Rd_Done,
        Frame_Circle                => Frame_Circle,
        Cmd_Drive                   => Cmd_Drive,
        Cmd_Check1                  => Cmd_Check1,
        Exposure_Line               => Exposure_Line,
        Cmd_Check2                  => Cmd_Check2,
        Frame_Circle_S              => Frame_Circle_S,
        Train_Done                  => Train_Done,
        Cmd_Train                   => Cmd_Train);

    U22 : SEN_SPI
    port map (
        Clk_Ref                     => Clk_Ref,
        Rst_Ref                     => Rst_Ref,
        SPI_OUT                     => SPI_OUT,
        SPI_CLK                     => SPI_CLK,
        SPI_IN                      => SPI_IN,
        SPI_WRITE                   => SPI_WRITE,
        SPI_READ                    => SPI_READ,
        Spi_GainOdd                 => Spi_GainOdd,
        Spi_GainEven                => Spi_GainEven,
        Gain_Odd                    => Gain_Odd,
        Gain_Even                   => Gain_Even,
        Cmd_Wr_Spi                  => Cmd_Wr_Spi,
        Cmd_Rd_Spi                  => Cmd_Rd_Spi,
        Spi_Wr_Done                 => Spi_Wr_Done,
        Spi_Rd_Done                 => Spi_Rd_Done);

    U23 : SEN_DRIVE
    port map (
        Train_DRI                   => Train_DRI,
        Clk_Ref                     => Clk_Ref,
        Rst_Ref                     => Rst_Ref,
        ROW                         => ROW,
        TX                          => TX,
        RS                          => RS,
        RST                         => RST,
        HDR                         => HDR,
        TAZ                         => TAZ,
        TAB                         => TAB,
        TPC                         => TPC,
        TINITO                      => TINITO,
        TINITE                      => TINITE,
        TSO                         => TSO,
        TSE                         => TSE,
        TAC                         => TAC,
        TRD                         => TRD,
        TADR                        => TADR,
        TADS                        => TADS,
        TWS                         => TWS,
        SYNC                        => SYNC,
        TBS                         => TBS,
        TS                          => TS,
        Exposure_Line               => Exposure_Line,
        Cmd_Drive                   => Cmd_Drive,
        Cmd_Check1                  => Cmd_Check1,
        Frame_Circle                => Frame_Circle,
        Sync_Rx                     => Sync_Rx,
        Image_Out                   => Image_Out);

    U24 : TRAINING
    port map (
        Train_TRA                   => Train_TRA,
        Clk_Ref                     => Clk_Ref,
        Rst_Ref                     => Rst_Ref,
        Clk_Ddr                     => Clk_Ddr,
        Rst_Ddr                     => Rst_Ddr,
        DATA_SER_P                  => DATA_SER_P,
        DATA_SER_N                  => DATA_SER_N,
        Cmd_Train                   => Cmd_Train,
        Train_Done                  => Train_Done,
        Data_Par_Chan1              => Data_Par_Chan1,
        Data_Par_Chan2              => Data_Par_Chan2,
        Data_Par_Chan3              => Data_Par_Chan3,
        Data_Par_Chan4              => Data_Par_Chan4,
        Data_Par_Chan5              => Data_Par_Chan5,
        Data_Par_Chan6              => Data_Par_Chan6,
        Data_Par_Chan7              => Data_Par_Chan7,
        Data_Par_Chan8              => Data_Par_Chan8);

    U25 : IMA_GEN
    port map (
        Clk_Ref                     => Clk_Ref,
        Rst_Ref                     => Rst_Ref,
        Self_Sync_Rx                => Self_Sync_Rx,
        Self_Image_Out              => Self_Image_Out,
        Self_Par_Chan1              => Self_Par_Chan1,
        Self_Par_Chan2              => Self_Par_Chan2,
        Self_Par_Chan3              => Self_Par_Chan3,
        Self_Par_Chan4              => Self_Par_Chan4,
        Self_Par_Chan5              => Self_Par_Chan5,
        Self_Par_Chan6              => Self_Par_Chan6,
        Self_Par_Chan7              => Self_Par_Chan7,
        Self_Par_Chan8              => Self_Par_Chan8,
        Cmd_Check2                  => Cmd_Check2,
        Frame_Circle_S              => Frame_Circle_S);

end Behavioral;