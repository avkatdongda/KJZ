------------------------------------------------------------------------------
-- GTX 光发射模块
------------------------------------------------------------------------------


-- hds interface_start
-- hds interface_start
-- hds interface_start
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE ieee.std_logic_unsigned.all;
USE ieee.std_logic_misc.all;
LIBRARY UNISIM;
USE UNISIM.VCOMPONENTS.ALL;

--  ***********************************Entity Declaration************************
-- 
-- 
ENTITY GTX_DRIVER_C220526 IS
   GENERIC( 
      EXAMPLE_CONFIG_INDEPENDENT_LANES : integer := 1;
      EXAMPLE_LANE_WITH_START_CHAR     : integer := 0;           -- specifies lane with unique start frame ch
      EXAMPLE_WORDS_IN_BRAM            : integer := 512;         -- specifies amount of data in BRAM
      EXAMPLE_SIM_GTRESET_SPEEDUP      : string  := "TRUE";      -- simulation setting for GT SecureIP model
      STABLE_CLOCK_PERIOD              : integer := 12;
      EXAMPLE_USE_CHIPSCOPE            : integer := 0            -- Set to 1 to use Chipscope to drive resets
   );
   PORT( 
      Q0_CLK0_GTREFCLK_PAD_N_IN : IN     std_logic;
      Q0_CLK0_GTREFCLK_PAD_P_IN : IN     std_logic;
      DRP_CLK_IN                : IN     std_logic;
      TRACK_DATA_OUT            : OUT    std_logic;
      -- 数据源
      C0_TX_DATA_CLK            : OUT    std_logic;                       --时钟
      C0_TX_DATA_RESET          : OUT    std_logic;                       --复位
      C0_TXK                    : IN     std_logic_vector (1 DOWNTO 0);   --低位K码
      C0_TXD                    : IN     std_logic_vector (15 DOWNTO 0);
      -- 数据源
      C1_TX_DATA_CLK            : OUT    std_logic;                       --时钟
      C1_TX_DATA_RESET          : OUT    std_logic;                       --复位
      C1_TXK                    : IN     std_logic_vector (1 DOWNTO 0);   --低位K码
      C1_TXD                    : IN     std_logic_vector (15 DOWNTO 0);
      TXN_OUT                   : OUT    std_logic_vector (1 DOWNTO 0);
      TXP_OUT                   : OUT    std_logic_vector (1 DOWNTO 0);
      RXN_IN                    : IN     std_logic_vector (1 DOWNTO 0);
      RXP_IN                    : IN     std_logic_vector (1 DOWNTO 0);
      --H8528_ALERT                             : out  std_logic;
      H8528_SCL                 : OUT    std_logic;
      H8528_SDA                 : OUT    std_logic;
      H8528_TXEN                : OUT    std_logic
   );

-- Declarations

END GTX_DRIVER_C220526 ;
-- hds interface_end
    
architecture RTL of GTX_DRIVER_C220526 is
    attribute DowngradeIPIdentifiedWarnings: string;
    attribute DowngradeIPIdentifiedWarnings of RTL : architecture is "yes";

    attribute CORE_GENERATION_INFO : string;
    attribute CORE_GENERATION_INFO of RTL : architecture is "GTX,gtwizard_v3_6_6,{protocol_file=Start_from_scratch}";

--**************************Component Declarations*****************************


component GTX is
  Port ( 
    SOFT_RESET_TX_IN : in STD_LOGIC;
    SOFT_RESET_RX_IN : in STD_LOGIC;
    DONT_RESET_ON_DATA_ERROR_IN : in STD_LOGIC;
    Q0_CLK0_GTREFCLK_PAD_N_IN : in STD_LOGIC;
    Q0_CLK0_GTREFCLK_PAD_P_IN : in STD_LOGIC;
    GT0_TX_FSM_RESET_DONE_OUT : out STD_LOGIC;
    GT0_RX_FSM_RESET_DONE_OUT : out STD_LOGIC;
    GT0_DATA_VALID_IN : in STD_LOGIC;
    GT1_TX_FSM_RESET_DONE_OUT : out STD_LOGIC;
    GT1_RX_FSM_RESET_DONE_OUT : out STD_LOGIC;
    GT1_DATA_VALID_IN : in STD_LOGIC;
    GT0_TXUSRCLK_OUT : out STD_LOGIC;
    GT0_TXUSRCLK2_OUT : out STD_LOGIC;
    GT0_RXUSRCLK_OUT : out STD_LOGIC;
    GT0_RXUSRCLK2_OUT : out STD_LOGIC;
    GT1_TXUSRCLK_OUT : out STD_LOGIC;
    GT1_TXUSRCLK2_OUT : out STD_LOGIC;
    GT1_RXUSRCLK_OUT : out STD_LOGIC;
    GT1_RXUSRCLK2_OUT : out STD_LOGIC;
    gt0_cpllfbclklost_out : out STD_LOGIC;
    gt0_cplllock_out : out STD_LOGIC;
    gt0_cpllreset_in : in STD_LOGIC;
    gt0_drpaddr_in : in STD_LOGIC_VECTOR ( 8 downto 0 );
    gt0_drpdi_in : in STD_LOGIC_VECTOR ( 15 downto 0 );
    gt0_drpdo_out : out STD_LOGIC_VECTOR ( 15 downto 0 );
    gt0_drpen_in : in STD_LOGIC;
    gt0_drprdy_out : out STD_LOGIC;
    gt0_drpwe_in : in STD_LOGIC;
    gt0_dmonitorout_out : out STD_LOGIC_VECTOR ( 7 downto 0 );
    gt0_eyescanreset_in : in STD_LOGIC;
    gt0_rxuserrdy_in : in STD_LOGIC;
    gt0_eyescandataerror_out : out STD_LOGIC;
    gt0_eyescantrigger_in : in STD_LOGIC;
    gt0_rxdata_out : out STD_LOGIC_VECTOR ( 15 downto 0 );
    gt0_rxdisperr_out : out STD_LOGIC_VECTOR ( 1 downto 0 );
    gt0_rxnotintable_out : out STD_LOGIC_VECTOR ( 1 downto 0 );
    gt0_gtxrxp_in : in STD_LOGIC;
    gt0_gtxrxn_in : in STD_LOGIC;
    gt0_rxbyteisaligned_out : out STD_LOGIC;
    gt0_rxbyterealign_out : out STD_LOGIC;
    gt0_rxcommadet_out : out STD_LOGIC;
    gt0_rxmcommaalignen_in : in STD_LOGIC;
    gt0_rxpcommaalignen_in : in STD_LOGIC;
    gt0_rxdfelpmreset_in : in STD_LOGIC;
    gt0_rxmonitorout_out : out STD_LOGIC_VECTOR ( 6 downto 0 );
    gt0_rxmonitorsel_in : in STD_LOGIC_VECTOR ( 1 downto 0 );
    gt0_rxoutclkfabric_out : out STD_LOGIC;
    gt0_gtrxreset_in : in STD_LOGIC;
    gt0_rxpmareset_in : in STD_LOGIC;
    gt0_rxcharisk_out : out STD_LOGIC_VECTOR ( 1 downto 0 );
    gt0_rxresetdone_out : out STD_LOGIC;
    gt0_gttxreset_in : in STD_LOGIC;
    gt0_txuserrdy_in : in STD_LOGIC;
    gt0_txdata_in : in STD_LOGIC_VECTOR ( 15 downto 0 );
    gt0_gtxtxn_out : out STD_LOGIC;
    gt0_gtxtxp_out : out STD_LOGIC;
    gt0_txoutclkfabric_out : out STD_LOGIC;
    gt0_txoutclkpcs_out : out STD_LOGIC;
    gt0_txcharisk_in : in STD_LOGIC_VECTOR ( 1 downto 0 );
    gt0_txresetdone_out : out STD_LOGIC;
    gt1_cpllfbclklost_out : out STD_LOGIC;
    gt1_cplllock_out : out STD_LOGIC;
    gt1_cpllreset_in : in STD_LOGIC;
    gt1_drpaddr_in : in STD_LOGIC_VECTOR ( 8 downto 0 );
    gt1_drpdi_in : in STD_LOGIC_VECTOR ( 15 downto 0 );
    gt1_drpdo_out : out STD_LOGIC_VECTOR ( 15 downto 0 );
    gt1_drpen_in : in STD_LOGIC;
    gt1_drprdy_out : out STD_LOGIC;
    gt1_drpwe_in : in STD_LOGIC;
    gt1_dmonitorout_out : out STD_LOGIC_VECTOR ( 7 downto 0 );
    gt1_eyescanreset_in : in STD_LOGIC;
    gt1_rxuserrdy_in : in STD_LOGIC;
    gt1_eyescandataerror_out : out STD_LOGIC;
    gt1_eyescantrigger_in : in STD_LOGIC;
    gt1_rxdata_out : out STD_LOGIC_VECTOR ( 15 downto 0 );
    gt1_rxdisperr_out : out STD_LOGIC_VECTOR ( 1 downto 0 );
    gt1_rxnotintable_out : out STD_LOGIC_VECTOR ( 1 downto 0 );
    gt1_gtxrxp_in : in STD_LOGIC;
    gt1_gtxrxn_in : in STD_LOGIC;
    gt1_rxbyteisaligned_out : out STD_LOGIC;
    gt1_rxbyterealign_out : out STD_LOGIC;
    gt1_rxcommadet_out : out STD_LOGIC;
    gt1_rxmcommaalignen_in : in STD_LOGIC;
    gt1_rxpcommaalignen_in : in STD_LOGIC;
    gt1_rxdfelpmreset_in : in STD_LOGIC;
    gt1_rxmonitorout_out : out STD_LOGIC_VECTOR ( 6 downto 0 );
    gt1_rxmonitorsel_in : in STD_LOGIC_VECTOR ( 1 downto 0 );
    gt1_rxoutclkfabric_out : out STD_LOGIC;
    gt1_gtrxreset_in : in STD_LOGIC;
    gt1_rxpmareset_in : in STD_LOGIC;
    gt1_rxcharisk_out : out STD_LOGIC_VECTOR ( 1 downto 0 );
    gt1_rxresetdone_out : out STD_LOGIC;
    gt1_gttxreset_in : in STD_LOGIC;
    gt1_txuserrdy_in : in STD_LOGIC;
    gt1_txdata_in : in STD_LOGIC_VECTOR ( 15 downto 0 );
    gt1_gtxtxn_out : out STD_LOGIC;
    gt1_gtxtxp_out : out STD_LOGIC;
    gt1_txoutclkfabric_out : out STD_LOGIC;
    gt1_txoutclkpcs_out : out STD_LOGIC;
    gt1_txcharisk_in : in STD_LOGIC_VECTOR ( 1 downto 0 );
    gt1_txresetdone_out : out STD_LOGIC;
    GT0_QPLLOUTCLK_OUT : out STD_LOGIC;
    GT0_QPLLOUTREFCLK_OUT : out STD_LOGIC;
    sysclk_in : in STD_LOGIC
  );

end component;

-----------------------------------------------------------------------------------
-- 属性参数
-----------------------------------------------------------------------------------
    attribute   ASYNC_REG                   : string;
    attribute   keep                        : string;
    constant    DLY                         : time := 1 ns;
---------------------------------------------------------------------------------
-- 自定义数据源
---------------------------------------------------------------------------------
    -- component OPT_DRIVER_TEST is
        -- generic(
            -- IMG_COL_BITS : integer := 11;
            -- IMG_ROW_BITS : integer := 11;
            -- INFO_ROW_BITS : integer := 2
            
        -- );
        -- port(
          -- Clk : in std_logic;
          -- Reset_n : in std_logic;
          -- Opt_Req  : in std_logic;
          -- Opt_Ack  : out std_logic;
          

          -- REG_INDEX : in std_logic_vector(4 downto 0);

          -- --光纤接口信号
          -- C0_TKLSB  : out std_logic;
          -- C0_TKMSB  : out std_logic;
          -- C0_TXD    : out std_logic_vector(15 downto 0);
          -- TLK2711_LOOPEN: out std_logic;
          -- TLK2711_ENABLE: out std_logic;
          -- TLK2711_LCKREFN: out std_logic;
          -- TLK2711_PRBSEN: out std_logic;
          -- TLK2711_PRE: out std_logic
        -- );
    -- end component;

    -- signal REG_INDEX    : std_logic_vector(4 downto 0);
    -- signal OPT_DRIVER_Reset_n : std_logic;




    

--************************** Register Declarations ****************************

    
    
----------------------------------------------------------------------------------
-- GTX
----------------------------------------------------------------------------------
    signal  gt0_rxdata_i                    : std_logic_vector(15 downto 0);    --D码
    signal  gt0_rxcharisk_i                 : std_logic_vector(1 downto 0);     --K码
    signal  gt0_txdata_i                    : std_logic_vector(15 downto 0);    --D码
    signal  gt0_txcharisk_i                 : std_logic_vector(1 downto 0);     --K码
    
    signal  gt1_rxdata_i                    : std_logic_vector(15 downto 0);    --D码
    signal  gt1_rxcharisk_i                 : std_logic_vector(1 downto 0);     --K码
    signal  gt1_txdata_i                    : std_logic_vector(15 downto 0);    --D码
    signal  gt1_txcharisk_i                 : std_logic_vector(1 downto 0);     --K码
    
    signal  drpclk_in_i                     : std_logic;
    
-------------- Receive Ports - RX Byte and Word Alignment Ports ------------
    signal  gt0_rxbyteisaligned_i           : std_logic;
    signal  gt0_rxbyterealign_i             : std_logic;
    signal  gt0_rxcommadet_i                : std_logic;
    signal  gt0_rxmcommaalignen_i           : std_logic;
    signal  gt0_rxpcommaalignen_i           : std_logic;
    signal  gt0_track_data_i                : std_logic;
    
    
    signal  gt1_rxbyteisaligned_i           : std_logic;
    signal  gt1_rxbyterealign_i             : std_logic;
    signal  gt1_rxcommadet_i                : std_logic;
    signal  gt1_rxmcommaalignen_i           : std_logic;
    signal  gt1_rxpcommaalignen_i           : std_logic;
    signal  gt1_track_data_i                : std_logic;
----------------------------------------------------------------------------------
-- 时钟
----------------------------------------------------------------------------------
    signal    TX0_Userclk2                    : std_logic; 
    signal    RX0_Userclk2                    : std_logic; 
    
    signal    TX1_Userclk2                    : std_logic; 
    signal    RX1_Userclk2                    : std_logic;
-----------------------------------------------------------------------------------
-- 复位逻辑
-----------------------------------------------------------------------------------
    signal  TX0_Reset           : std_logic;
    signal  RX0_Reset           : std_logic;
    
    signal  TX1_Reset           : std_logic;
    signal  RX1_Reset           : std_logic;
    
    signal      gt0_rxresetdone_i                   : std_logic;
    signal      gt0_rxresetdone_r                   : std_logic;
    signal      gt0_rxresetdone_r2                  : std_logic;
    signal      gt0_rxresetdone_r3                  : std_logic;
    attribute   ASYNC_REG of gt0_rxresetdone_r     : signal is "TRUE";
    attribute   ASYNC_REG of gt0_rxresetdone_r2     : signal is "TRUE";
    attribute   ASYNC_REG of gt0_rxresetdone_r3     : signal is "TRUE";
    
    signal      gt0_txresetdone_i               : std_logic;
    signal      gt0_txfsmresetdone_i            : std_logic;   --发送FSM复位完成
    signal      gt0_txfsmresetdone_r            : std_logic;
    attribute   ASYNC_REG of gt0_txfsmresetdone_r     : signal is "TRUE";
    
    signal      gt0_rxfsmresetdone_i            : std_logic;   --接收FSM复位完成
    signal      gt0_txfsmresetdone_r2           : std_logic;
    attribute   ASYNC_REG of gt0_txfsmresetdone_r2     : signal is "TRUE";
    
    
    signal      gt1_rxresetdone_i                   : std_logic;
    signal      gt1_rxresetdone_r                   : std_logic;
    signal      gt1_rxresetdone_r2                  : std_logic;
    signal      gt1_rxresetdone_r3                  : std_logic;
    attribute   ASYNC_REG of gt1_rxresetdone_r     : signal is "TRUE";
    attribute   ASYNC_REG of gt1_rxresetdone_r2     : signal is "TRUE";
    attribute   ASYNC_REG of gt1_rxresetdone_r3     : signal is "TRUE";
    
    signal      gt1_txresetdone_i               : std_logic;
    signal      gt1_txfsmresetdone_i            : std_logic;   --发送FSM复位完成
    signal      gt1_txfsmresetdone_r            : std_logic;
    attribute   ASYNC_REG of gt1_txfsmresetdone_r     : signal is "TRUE";
    
    signal      gt1_rxfsmresetdone_i            : std_logic;   --接收FSM复位完成
    signal      gt1_txfsmresetdone_r2           : std_logic;
    attribute   ASYNC_REG of gt1_txfsmresetdone_r2     : signal is "TRUE";


   function and_reduce(arg: std_logic_vector) return std_logic is
	variable result: std_logic;
    begin
	result := '1';
	for i in arg'range loop
	    result := result and arg(i);
	end loop;
        return result;
    end;


--**************************** Main Body of Code *******************************
begin

    -------------------------------------------------------------------------------
    -- 光发射模块使能信号
    -------------------------------------------------------------------------------
    H8528_SCL       <= '1';
    H8528_SDA       <= '1';
    H8528_TXEN      <= '1';
    
    C0_TX_DATA_CLK     <= TX0_Userclk2;
    C0_TX_DATA_RESET   <= TX0_Reset;
    
    C1_TX_DATA_CLK     <= TX1_Userclk2;
    C1_TX_DATA_RESET   <= TX1_Reset;


    -------------------------------------------------------------------------------
    -- GTX
    -------------------------------------------------------------------------------


    GTX_support_i : GTX
    port map
    (
        SOFT_RESET_TX_IN                =>      '0',                    -- 高复位TX初始化状态机
        SOFT_RESET_RX_IN                =>      '0',                    -- 高复位RX初始化状态机
        DONT_RESET_ON_DATA_ERROR_IN     =>      '0',
        Q0_CLK0_GTREFCLK_PAD_N_IN       =>      Q0_CLK0_GTREFCLK_PAD_N_IN,
        Q0_CLK0_GTREFCLK_PAD_P_IN       =>      Q0_CLK0_GTREFCLK_PAD_P_IN,
        
        GT0_TX_FSM_RESET_DONE_OUT       =>      gt0_txfsmresetdone_i,   --发送复位状态机完成
        GT0_RX_FSM_RESET_DONE_OUT       =>      gt0_rxfsmresetdone_i,   --接收复位状态机完成
        GT0_DATA_VALID_IN               =>      gt0_track_data_i,       --RX端数据是否有效
        
        GT1_TX_FSM_RESET_DONE_OUT       =>      gt1_txfsmresetdone_i,
        GT1_RX_FSM_RESET_DONE_OUT       =>      gt1_rxfsmresetdone_i,
        GT1_DATA_VALID_IN               =>      gt1_track_data_i,
    
    
        GT0_TXUSRCLK_OUT                => open,
        GT0_TXUSRCLK2_OUT               => TX0_Userclk2,
        GT0_RXUSRCLK_OUT                => open,
        GT0_RXUSRCLK2_OUT               => RX0_Userclk2,
        
        
        GT1_TXUSRCLK_OUT                => open,
        GT1_TXUSRCLK2_OUT               => TX1_Userclk2,
        GT1_RXUSRCLK_OUT                => open,
        GT1_RXUSRCLK2_OUT               => RX1_Userclk2,

 

        --------------------------------- CPLL Ports -------------------------------
        gt0_cpllfbclklost_out           =>      open,
        gt0_cplllock_out                =>      open,
        gt0_cpllreset_in                =>      '0',
        
        gt1_cpllfbclklost_out           =>      open,
        gt1_cplllock_out                =>      open,
        gt1_cpllreset_in                =>      '0',
        
        ---------------------------- Channel - DRP Ports  --------------------------
        gt0_drpaddr_in                  =>      (others => '0'),
        gt0_drpdi_in                    =>      (others => '0'),
        gt0_drpdo_out                   =>      open,
        gt0_drpen_in                    =>      '0',
        gt0_drprdy_out                  =>      open,
        gt0_drpwe_in                    =>      '0',
        
        gt1_drpaddr_in                  =>      (others => '0'),
        gt1_drpdi_in                    =>      (others => '0'),
        gt1_drpdo_out                   =>      open,
        gt1_drpen_in                    =>      '0',
        gt1_drprdy_out                  =>      open,
        gt1_drpwe_in                    =>      '0',
        --------------------------- Digital Monitor Ports --------------------------
        gt0_dmonitorout_out             =>      open,
        
        gt1_dmonitorout_out             =>      open,
        --------------------- RX Initialization and Reset Ports --------------------
        gt0_eyescanreset_in             =>      '0',
        gt0_rxuserrdy_in                =>      '0',
        
        gt1_eyescanreset_in             =>      '0',
        gt1_rxuserrdy_in                =>      '0',
        -------------------------- RX Margin Analysis Ports ------------------------
        gt0_eyescandataerror_out        =>      open,
        gt0_eyescantrigger_in           =>      '0',
        
        gt1_eyescandataerror_out        =>      open,
        gt1_eyescantrigger_in           =>      '0',
        ------------------ Receive Ports - FPGA RX interface Ports -----------------
        gt0_rxdata_out                  =>      gt0_rxdata_i,
        
        gt1_rxdata_out                  =>      gt1_rxdata_i,
        ------------------ Receive Ports - RX 8B/10B Decoder Ports -----------------
        gt0_rxdisperr_out               =>      open,
        gt0_rxnotintable_out            =>      open,
        
        gt1_rxdisperr_out               =>      open,
        gt1_rxnotintable_out            =>      open,
        --------------------------- Receive Ports - RX AFE -------------------------
        gt0_gtxrxp_in                   =>      RXP_IN(0),
        
        gt1_gtxrxp_in                   =>      RXP_IN(1),
        ------------------------ Receive Ports - RX AFE Ports ----------------------
        gt0_gtxrxn_in                   =>      RXN_IN(0),
        
        gt1_gtxrxn_in                   =>      RXN_IN(1),
        -------------- Receive Ports - RX Byte and Word Alignment Ports ------------
        gt0_rxbyteisaligned_out         =>      gt0_rxbyteisaligned_i,
        gt0_rxbyterealign_out           =>      gt0_rxbyterealign_i,
        gt0_rxcommadet_out              =>      gt0_rxcommadet_i,
        gt0_rxmcommaalignen_in          =>      gt0_rxmcommaalignen_i,
        gt0_rxpcommaalignen_in          =>      gt0_rxpcommaalignen_i,
        
        gt1_rxbyteisaligned_out         =>      gt1_rxbyteisaligned_i,
        gt1_rxbyterealign_out           =>      gt1_rxbyterealign_i,
        gt1_rxcommadet_out              =>      gt1_rxcommadet_i,
        gt1_rxmcommaalignen_in          =>      gt1_rxmcommaalignen_i,
        gt1_rxpcommaalignen_in          =>      gt1_rxpcommaalignen_i,
        --------------------- Receive Ports - RX Equalizer Ports -------------------
        gt0_rxdfelpmreset_in            =>      '0',
        gt0_rxmonitorout_out            =>      open,
        gt0_rxmonitorsel_in             =>      "00",
        
        gt1_rxdfelpmreset_in            =>      '0',
        gt1_rxmonitorout_out            =>      open,
        gt1_rxmonitorsel_in             =>      "00",
        --------------- Receive Ports - RX Fabric Output Control Ports -------------
        gt0_rxoutclkfabric_out          =>      open,
        
        gt1_rxoutclkfabric_out          =>      open,
        ------------- Receive Ports - RX Initialization and Reset Ports ------------
        gt0_gtrxreset_in                =>      '0',
        gt0_rxpmareset_in               =>      '0',
        
        gt1_gtrxreset_in                =>      '0',
        gt1_rxpmareset_in               =>      '0',
        ------------------- Receive Ports - RX8B/10B Decoder Ports -----------------
        gt0_rxcharisk_out               =>      gt0_rxcharisk_i,
        
        gt1_rxcharisk_out               =>      gt1_rxcharisk_i,
        -------------- Receive Ports -RX Initialization and Reset Ports ------------
        gt0_rxresetdone_out             =>      gt0_rxresetdone_i,
        
        gt1_rxresetdone_out             =>      gt1_rxresetdone_i,
        --------------------- TX Initialization and Reset Ports --------------------
        gt0_gttxreset_in                =>      '0',
        gt0_txuserrdy_in                =>      '1',
        
        gt1_gttxreset_in                =>      '0',
        gt1_txuserrdy_in                =>      '1',
        ------------------ Transmit Ports - TX Data Path interface -----------------
        gt0_txdata_in                   =>      gt0_txdata_i,
        
        gt1_txdata_in                   =>      gt1_txdata_i,
        ---------------- Transmit Ports - TX Driver and OOB signaling --------------
        gt0_gtxtxn_out                  =>      TXN_OUT(0),
        gt0_gtxtxp_out                  =>      TXP_OUT(0),
        
        gt1_gtxtxn_out                  =>      TXN_OUT(1),
        gt1_gtxtxp_out                  =>      TXP_OUT(1),
        ----------- Transmit Ports - TX Fabric Clock Output Control Ports ----------
        gt0_txoutclkfabric_out          =>      open,
        gt0_txoutclkpcs_out             =>      open,
        
        gt1_txoutclkfabric_out          =>      open,
        gt1_txoutclkpcs_out             =>      open,
        --------------------- Transmit Ports - TX Gearbox Ports --------------------
        gt0_txcharisk_in                =>      gt0_txcharisk_i,
        
        gt1_txcharisk_in                =>      gt1_txcharisk_i,
        ------------- Transmit Ports - TX Initialization and Reset Ports -----------
        gt0_txresetdone_out             =>      gt0_txresetdone_i,
        
        gt1_txresetdone_out             =>      gt1_txresetdone_i,



    --____________________________COMMON PORTS________________________________
        GT0_QPLLOUTCLK_OUT  => open,
        GT0_QPLLOUTREFCLK_OUT => open,
         sysclk_in => drpclk_in_i
    );
 
    -----------------------------------------------------------------------------------
    -- 复位逻辑
    -----------------------------------------------------------------------------------
    -- All the User Modules i.e. FRAME_GEN, FRAME_CHECK and the sync modules
    -- are held in reset till the RESETDONE goes high. 
    -- The RESETDONE is registered a couple of times on USRCLK2 and connected 
    -- to the reset of the modules
    
    -----------------------------------------------------------------------------------
    -- 主份通道
    -----------------------------------------------------------------------------------
    
    process(RX0_Userclk2,gt0_rxresetdone_i)
        begin
            if(gt0_rxresetdone_i = '0') then
                gt0_rxresetdone_r  <= '0'   after DLY;
                gt0_rxresetdone_r2 <= '0'   after DLY;
                gt0_rxresetdone_r3 <= '0'   after DLY;
    elsif (RX0_Userclk2'event and RX0_Userclk2 = '1') then
                gt0_rxresetdone_r  <= gt0_rxresetdone_i   after DLY;
                gt0_rxresetdone_r2 <= gt0_rxresetdone_r   after DLY;
                gt0_rxresetdone_r3  <= gt0_rxresetdone_r2   after DLY;
            end if;
        end process;

    process(TX0_Userclk2,gt0_txfsmresetdone_i)
        begin
            if(gt0_txfsmresetdone_i = '0') then
                gt0_txfsmresetdone_r  <= '0'   after DLY;
                gt0_txfsmresetdone_r2 <= '0'   after DLY;
        elsif (TX0_Userclk2'event and TX0_Userclk2 = '1') then
                gt0_txfsmresetdone_r  <= gt0_txfsmresetdone_i   after DLY;
                gt0_txfsmresetdone_r2 <= gt0_txfsmresetdone_r   after DLY;
            end if;
    end process; 
    

    TX0_Reset                        <= not gt0_txfsmresetdone_r2;
    RX0_Reset                        <= not gt0_rxresetdone_r3;

    process( RX0_Userclk2 )
    begin
    if(RX0_Userclk2'event and RX0_Userclk2 = '1') then
        if(RX0_Reset = '1') then 
            gt0_rxmcommaalignen_i   <= '0';
        else              
            gt0_rxmcommaalignen_i   <= '1';
        end if;
    end if;    
    end process;

    -- Drive the enmcommaalign port of the gt for alignment
    process( RX0_Userclk2 )
    begin
    if(RX0_Userclk2'event and RX0_Userclk2 = '1') then
        if(RX0_Reset = '1') then 
            gt0_rxpcommaalignen_i   <= '0' after DLY;
        else              
            gt0_rxpcommaalignen_i   <= '1' after DLY;
        end if;
    end if;    
    end process;
    
    -----------------------------------------------------------------------------------
    -- 备份通道
    -----------------------------------------------------------------------------------
    
    process(RX1_Userclk2,gt1_rxresetdone_i)
        begin
            if(gt1_rxresetdone_i = '0') then
                gt1_rxresetdone_r  <= '0'   after DLY;
                gt1_rxresetdone_r2 <= '0'   after DLY;
                gt1_rxresetdone_r3 <= '0'   after DLY;
    elsif (RX1_Userclk2'event and RX1_Userclk2 = '1') then
                gt1_rxresetdone_r  <= gt1_rxresetdone_i   after DLY;
                gt1_rxresetdone_r2 <= gt1_rxresetdone_r   after DLY;
                gt1_rxresetdone_r3  <= gt1_rxresetdone_r2   after DLY;
            end if;
        end process;

    process(TX1_Userclk2,gt1_txfsmresetdone_i)
        begin
            if(gt1_txfsmresetdone_i = '0') then
                gt1_txfsmresetdone_r  <= '0'   after DLY;
                gt1_txfsmresetdone_r2 <= '0'   after DLY;
        elsif (TX1_Userclk2'event and TX1_Userclk2 = '1') then
                gt1_txfsmresetdone_r  <= gt1_txfsmresetdone_i   after DLY;
                gt1_txfsmresetdone_r2 <= gt1_txfsmresetdone_r   after DLY;
            end if;
    end process; 
    

    TX1_Reset                        <= not gt1_txfsmresetdone_r2;
    RX1_Reset                        <= not gt1_rxresetdone_r3;

    process( RX1_Userclk2 )
    begin
    if(RX1_Userclk2'event and RX1_Userclk2 = '1') then
        if(RX1_Reset = '1') then 
            gt1_rxmcommaalignen_i   <= '0';
        else              
            gt1_rxmcommaalignen_i   <= '1';
        end if;
    end if;    
    end process;

    -- Drive the enmcommaalign port of the gt for alignment
    process( RX1_Userclk2 )
    begin
    if(RX1_Userclk2'event and RX1_Userclk2 = '1') then
        if(RX1_Reset = '1') then 
            gt1_rxpcommaalignen_i   <= '0' after DLY;
        else              
            gt1_rxpcommaalignen_i   <= '1' after DLY;
        end if;
    end if;    
    end process;

 
   DRP_CLK_BUFG : BUFG 
   port map 
    (
        I    => DRP_CLK_IN,
        O    => drpclk_in_i 
    );

    
    
    -------------------------------------------------------------------------------
    -- 数据接口
    -------------------------------------------------------------------------------
    gt0_txdata_i    <= C0_TXD;
    gt0_txcharisk_i <= C0_TXK;
    
    gt1_txdata_i    <= C1_TXD;
    gt1_txcharisk_i <= C1_TXK;

    TRACK_DATA_OUT   <= gt0_track_data_i and gt1_track_data_i ;

end RTL;


