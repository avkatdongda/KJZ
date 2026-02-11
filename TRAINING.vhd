----------------------------------------------------------------------------------
-- Company:         CIOMP
-- Engineer:        WangZheng
-- Create Date:     2025/01/06 09:04:13
-- Module Name:     TRAINING - Behavioral
-- Project Name:    CH4_G400
-- Target Devices:  XC7K325T
-- Tool Versions:   Vivado 2018.3
-- Description:     synchronize the LVDS outputs of the sensor using training algorithm
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

entity TRAINING is
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
end TRAINING;

architecture Behavioral of TRAINING is

    -- cnt
    signal  chan_cnt        : STD_LOGIC_VECTOR (2 downto 0);                    -- count channel of the sensor
    signal  align_cnt       : integer range 0 to 15;                            -- count clk of align_state
    signal  step_cnt        : STD_LOGIC_VECTOR (4 downto 0);                    -- count the step of idelay tap
    signal  shift_cnt       : integer range 0 to 15;                            -- count shift addr of TP word
    signal  round_cnt       : integer range 0 to 30;                            -- count word align round
    -- reg
    signal  Start_Align     : STD_LOGIC;                                        -- the sign of training start
    signal  Align_Done      : STD_LOGIC;                                        -- the sign of training end
    signal  Cmd_Train_R     : STD_LOGIC;                                        -- the rising edge of Cmd_Train
    signal  Sign_Tp         : STD_LOGIC;                                        -- the sign of outputting TP word, '1' valid
    signal  Data_Stable     : STD_LOGIC;                                        -- the sign compare current data with previous data, '1' is same
    signal  Data_Cur        : STD_LOGIC_VECTOR (11 downto 0);                   -- current data
    signal  Data_Pre        : STD_LOGIC_VECTOR (11 downto 0);                   -- previous data
    signal  Loc_Eye_Start   : STD_LOGIC_VECTOR (4 downto 0);
    signal  Loc_Eye_Mid     : STD_LOGIC_VECTOR (4 downto 0);
    signal  Loc_Eye_End     : STD_LOGIC_VECTOR (4 downto 0);
    -- ser2par
    signal  Idelayce        : STD_LOGIC_VECTOR (7 downto 0);                    -- the ce signal of idelay component
    signal  Idelayrst       : STD_LOGIC_VECTOR (7 downto 0);                    -- the rst signal of idelay component
    signal  Bitslip         : STD_LOGIC_VECTOR (7 downto 0);                    -- the signal of slippling bit
    signal  Pixel_Shift     : STD_LOGIC_VECTOR (7 downto 0);                    -- the signal of shifting pixel
    type    Data_2D is array (0 to 7) of STD_LOGIC_VECTOR (11 downto 0);        -- the two dimensional array of Data_Par 
    signal  Data_Par_2D     : Data_2D;
    -- fsm
    type    Fsm_Ctrl    is (S_Ctrl_Idle, S_Start_Align, S_Align);
    signal  ctrl_state      : Fsm_Ctrl;
    type    Fsm_Align   is (S_Idle, S_Reset1, S_Eye_Sample, S_Eye_Delay, S_Eye_Check, S_Eye_Calc, S_Reset2, S_Eye_Center, S_Word_Align, S_Chan_Align, S_Finsh);
    signal  align_state     : Fsm_Align;
    type    Fsm_Eye     is (S_Find_Edge1, S_Edge_Confirm, S_Find_Edge2);
    signal  eye_state       : Fsm_Eye;

    attribute mark_debug    : string;
    attribute mark_debug    of Data_Par_Chan1           : signal is "true";
    attribute mark_debug    of Data_Par_Chan2           : signal is "true";
    attribute mark_debug    of Data_Par_Chan3           : signal is "true";
    attribute mark_debug    of Data_Par_Chan4           : signal is "true";
    attribute mark_debug    of Data_Par_Chan5           : signal is "true";
    attribute mark_debug    of Data_Par_Chan6           : signal is "true";
    attribute mark_debug    of Data_Par_Chan7           : signal is "true";
    attribute mark_debug    of Data_Par_Chan8           : signal is "true";
    -- attribute mark_debug    of ctrl_state               : signal is "true";
    attribute mark_debug    of align_state              : signal is "true";
    attribute mark_debug    of eye_state                : signal is "true";
    attribute mark_debug    of step_cnt                 : signal is "true";
    attribute mark_debug    of chan_cnt                 : signal is "true";
    attribute mark_debug    of align_cnt                : signal is "true";
    attribute mark_debug    of Data_Stable              : signal is "true";
    attribute mark_debug    of Loc_Eye_Start            : signal is "true";
    attribute mark_debug    of Loc_Eye_Mid              : signal is "true";
    attribute mark_debug    of Loc_Eye_End              : signal is "true";
    -- attribute mark_debug    of Sign_Tp                  : signal is "true";
    -- attribute mark_debug    of shift_cnt                : signal is "true";
    attribute mark_debug    of Start_Align              : signal is "true";
    -- attribute mark_debug    of Train_TRA                : signal is "true";
    attribute mark_debug    of Data_Cur                 : signal is "true";
    attribute mark_debug    of Data_Pre                 : signal is "true";
    attribute mark_debug    of Idelayce                 : signal is "true";
    attribute mark_debug    of Idelayrst                : signal is "true";
    -- attribute mark_debug    of Bitslip                  : signal is "true";
    -- attribute mark_debug    of Pixel_Shift              : signal is "true";
    -- attribute mark_debug    of round_cnt                : signal is "true";

    component RISE_EDGE
    port(
        Clk                 : in  STD_LOGIC;
        Rst                 : in  STD_LOGIC;
        D_a                 : in  STD_LOGIC;
        Q_s_R               : out STD_LOGIC);
    end component;

    component SER2PAR is
    port (
        DATA_SER_P          : in  STD_LOGIC;
        DATA_SER_N          : in  STD_LOGIC;
        Clk_Ref             : in  STD_LOGIC;
        Rst_Ref             : in  STD_LOGIC;
        Clk_Ddr             : in  STD_LOGIC;
        Rst_Ddr             : in  STD_LOGIC;

        Idelayce            : in  STD_LOGIC;
        Idelayrst           : in  STD_LOGIC;
        Bitslip             : in  STD_LOGIC;
        Pixel_Shift         : in  STD_LOGIC;
        Data_Par            : out STD_LOGIC_VECTOR (11 downto 0));
    end component;

begin

    -- Rising Edge Pulse of Cmd_Train
    U241 : RISE_EDGE
    port map (
        Clk         => Clk_Ref,
        Rst         => Rst_Ref,
        D_a         => Cmd_Train,
        Q_s_R       => Cmd_Train_R);

    -- inst SER2PAR is receiver and convert serial data to parallel data
    GEN_SER2PAR: for i in 0 to 7 generate                                       -- generate a loop for 8 channels
    U242 : SER2PAR
    port map (
        DATA_SER_P  => DATA_SER_P(i),
        DATA_SER_N  => DATA_SER_N(i),
        Clk_Ref     => Clk_Ref,
        Rst_Ref     => Rst_Ref,
        Clk_Ddr     => Clk_Ddr,
        Rst_Ddr     => Rst_Ddr,

        Idelayce    => Idelayce(i),
        Idelayrst   => Idelayrst(i),
        Bitslip     => Bitslip(i),
        Pixel_Shift => Pixel_Shift(i),
        Data_Par    => Data_Par_2D(i));
    end generate;

    Data_Par_Chan1  <= Data_Par_2D(0);
    Data_Par_Chan2  <= Data_Par_2D(1);
    Data_Par_Chan3  <= Data_Par_2D(2);
    Data_Par_Chan4  <= Data_Par_2D(3);
    Data_Par_Chan5  <= Data_Par_2D(4);
    Data_Par_Chan6  <= Data_Par_2D(5);
    Data_Par_Chan7  <= Data_Par_2D(6);
    Data_Par_Chan8  <= Data_Par_2D(7);

    ------------------------------------------------------------------------------
    -- ALIGNMENT CONTROLLER
    -- The alignment algorithm is run for every channel sequentially
    -- The alignment controller selects the correct channel and starts the alignment algorithm
    ------------------------------------------------------------------------------

    process(Clk_Ref, Rst_Ref) begin
        if (Rst_Ref = '0') then
            ctrl_state      <= S_Ctrl_Idle;
            chan_cnt        <= (others => '0');
            Train_Done      <= '0';
            Start_Align     <= '0';
            Data_Cur        <= (others => '0');
        elsif (Clk_Ref'event and Clk_Ref = '1') then
            -- these signals keep default value when clk rising.
            Start_Align     <= '0';
            -- select correct data
            Data_Cur        <= Data_Par_2D (CONV_INTEGER(chan_cnt));

            case ctrl_state is
                when S_Ctrl_Idle =>
                    if (Cmd_Train_R = '1') then
                        ctrl_state  <= S_Start_Align;
                        chan_cnt    <= (others => '0');
                        Train_Done  <= '0';
                    else
                        ctrl_state  <= S_Ctrl_Idle;
                    end if;

                when S_Start_Align =>
                    ctrl_state      <= S_Align;
                    Start_Align     <= '1';

                when S_Align =>
                    if (Align_Done = '1') then
                        if (chan_cnt = "111") then
                            -- last alignment finished
                            ctrl_state  <= S_Ctrl_Idle;
                            Train_Done  <= '1';
                        else
                            -- one channel alignment finished, go to next channel
                            chan_cnt    <= chan_cnt + '1';
                            ctrl_state  <= S_Start_Align;
                        end if;
                    else
                        ctrl_state      <= S_Align;
                    end if;

                when others =>
                    ctrl_state  <= S_Ctrl_Idle;
            end case;
        end if;
    end process;
    
    ------------------------------------------------------------------------------
    -- BIT & WORD ALIGNMENT
    -- Runs the training algorithm on one channel
    -- (first bit alignment, then word alignment)
    --
    -- Bit alignment: 
    --  1. continuously sample data (data_curr) and compare with previous
    --  iteration (data_prev).
    --  2. after comparing, the IDELAY is increment to go to the next step.
    --  3. a complete stable region is found between the points loc_eye_start and
    --  loc_eye_end.
    --  4. the mid point between these two is found (loc_eye_mid) and the IDELAY
    --  of the channel is set to that value.
    --
    -- Word alignment: 
    --  the bitslip module of the ISERDES is asserted until the
    --  data output matches the training word.
    ------------------------------------------------------------------------------

    process(Clk_Ref, Rst_Ref) begin
        if (Rst_Ref = '0') then
            align_state     <= S_Idle;
            eye_state       <= S_Find_Edge1;
            align_cnt       <= 0;
            shift_cnt       <= 0;
            round_cnt       <= 0;
            Train_TRA       <= '0';
            Align_Done      <= '0';
            Data_Stable     <= '0';
            Sign_Tp         <= '0';
            step_cnt        <= (others => '0');
            Idelayce        <= (others => '0');
            Idelayrst       <= (others => '0');
            Bitslip         <= (others => '0');
            Pixel_Shift     <= (others => '0');
            Data_Pre        <= (others => '0');
            Loc_Eye_End     <= (others => '1');                                 -- 31
            Loc_Eye_Mid     <= (others => '1');                                 -- 31
            Loc_Eye_Start   <= (others => '1');                                 -- 31
        elsif (Clk_Ref'event and Clk_Ref = '1') then
            -- these signals keep default value when clk rising, so pull up only 1 clk.
            Align_Done      <= '0';
            Idelayce        <= (others => '0');
            Idelayrst       <= (others => '0');
            Bitslip         <= (others => '0');
            Pixel_Shift     <= (others => '0');
            -- FSM
            case align_state is
                when S_Idle =>
                    if (Start_Align = '1') then
                        align_state     <= S_Reset1;
                        eye_state       <= S_Find_Edge1;
                        align_cnt       <= 0;
                        Train_TRA       <= '0';
                        step_cnt        <= (others => '0');
                        Loc_Eye_End     <= (others => '1');                     -- 31
                        Loc_Eye_Mid     <= (others => '1');                     -- 31
                        Loc_Eye_Start   <= (others => '1');                     -- 31
                    else
                        align_state     <= S_Idle;
                    end if;
                -- reset ser2par module
                when S_Reset1 =>
                    Train_TRA           <= '1';
                    if (align_cnt = 15) then
                        align_state     <= S_Eye_Sample;
                        eye_state       <= S_Find_Edge1;
                        align_cnt       <= 0;
                        Data_Stable     <= '1';
                        Data_Pre        <= Data_Cur;
                    elsif (align_cnt = 0) then
                        align_state     <= S_Reset1;
                        align_cnt       <= align_cnt + 1;
                        Idelayrst (CONV_INTEGER(chan_cnt)) <= '1';
                    else
                        align_state     <= S_Reset1;
                        align_cnt       <= align_cnt + 1;
                    end if;
                -- make samples to check if data is stable and same as previous
                when S_Eye_Sample =>
                    if (align_cnt = 15) then
                        align_state     <= S_Eye_Delay;
                        align_cnt       <= 0;
                        Data_Pre        <= Data_Cur;
                    else
                        align_state     <= S_Eye_Sample;
                        align_cnt       <= align_cnt + 1;
                    end if;
                    
                    if (Data_Cur /= Data_Pre) then
                        Data_Stable     <= '0';
                    else
                        Data_Stable     <= '1';
                    end if;
                -- pull up Idelayce 1 clk, add 1 delay tap to se2par
                when S_Eye_Delay =>
                    if (align_cnt = 15) then
                        align_state     <= S_Eye_Check;
                        align_cnt       <= 0;
                    elsif (align_cnt = 0) then
                        align_state     <= S_Eye_Delay;
                        align_cnt       <= align_cnt + 1;
                        Idelayce (CONV_INTEGER(chan_cnt)) <= '1';
                    else
                        align_state     <= S_Eye_Delay;
                        align_cnt       <= align_cnt + 1;
                    end if;
                -- check if data is stable and take action
                when S_Eye_Check =>
                    align_state <= S_Eye_Sample;
                    step_cnt    <= step_cnt + '1';
                    Data_Stable <= '1';

                    if (step_cnt = 31) then
                        align_state <= S_Eye_Calc;
                    else
                        -- record start edge
                        case eye_state is
                            when S_Find_Edge1 =>
                                if (Data_Stable = '0') then
                                    eye_state   <= S_Edge_Confirm;
                                end if;

                            when S_Edge_Confirm =>
                                if (Data_Stable = '1') then
                                    eye_state   <= S_Find_Edge2;
                                    Loc_Eye_Start   <= step_cnt;
                                end if;

                            when S_Find_Edge2 =>
                                if (Data_Stable = '0') then
                                    align_state <= S_Eye_Calc;
                                    eye_state   <= S_Find_Edge1;
                                    Loc_Eye_End <= step_cnt;
                                end if;

                            when others =>
                                eye_state   <= S_Find_Edge1;
                        end case;
                    end if;

                -- calculate the mid point between start and end
                when S_Eye_Calc =>
                    align_state <= S_Reset2;
                    if Loc_Eye_Start <= 16 then
                        Loc_Eye_Mid <= Loc_Eye_Start + "01111"; --15
                        step_cnt    <= Loc_Eye_Start + "01111";
                    else
                        Loc_Eye_Mid <= Loc_Eye_Start - "10000"; --16
                        step_cnt    <= Loc_Eye_Start - "10000";
                    end if;

                -- reset ser2par module
                when S_Reset2 =>
                    if (align_cnt = 15) then
                        align_state     <= S_Eye_Center;
                        align_cnt       <= 0;
                    elsif (align_cnt = 0) then
                        align_state     <= S_Reset2;
                        align_cnt       <= align_cnt + 1;
                        Idelayrst (CONV_INTEGER(chan_cnt)) <= '1';
                    else
                        align_state     <= S_Reset2;
                        align_cnt       <= align_cnt + 1;
                    end if;

                -- reduce the step_cnt to go to the center of eye
                when S_Eye_Center =>
                    if (align_cnt = 15) then
                        align_cnt   <= 0;
                        if (step_cnt = 0) then
                            align_state <= S_Word_Align;
                            step_cnt    <= step_cnt;
                        else
                            align_state <= S_Eye_Center;
                            step_cnt    <= step_cnt - '1';
                        end if;
                    elsif (align_cnt = 0) then
                        align_state     <= S_Eye_Center;
                        align_cnt       <= align_cnt + 1;
                        Idelayce (CONV_INTEGER(chan_cnt)) <= '1';
                    else
                        align_state     <= S_Eye_Center;
                        align_cnt       <= align_cnt + 1;
                    end if;
                    
                -- match training word "98D"
                when S_Word_Align =>
                    if (align_cnt = 15) then
                        align_cnt   <= 0;
                        if (Data_Cur = X"98D") then
                            align_state <= S_Chan_Align;
                            Train_TRA   <= '0';
                        else
                            if (round_cnt = 30) then
                                align_state <= S_Reset1;                        -- restart bit train
                                round_cnt   <= 0;
                            else
                                align_state <= S_Word_Align;
                                Bitslip (CONV_INTEGER(chan_cnt))  <= '1';
                                round_cnt   <= round_cnt + 1;
                            end if;
                        end if;
                    else
                        align_state     <= S_Word_Align;
                        align_cnt       <= align_cnt + 1;
                    end if;

                -- pull Train_TRA high for 1 clk for channel correction
                when S_Chan_Align =>
                    if (Sign_Tp = '0') then                                     -- wait for Train_TRA pull up
                        if (align_cnt = 15) then
                            align_cnt   <= 0;
                            Train_TRA   <= '1';
                            Sign_Tp     <= '1';
                        else
                            align_cnt   <= align_cnt + 1;
                        end if;
                    else
                        Train_TRA   <= '0';
                        if (Data_Cur = X"98D") then
                            if (shift_cnt = 10) then                            -- count the clk between Train_TRA and TP word
                                align_state <= S_Finsh;
                            else
                                align_state <= S_Chan_Align;
                                Pixel_Shift (CONV_INTEGER(chan_cnt))  <= '1';   -- shift addr +1, turn TP word to 11 position
                            end if;
                            Sign_Tp     <= '0';                                 -- TP word again
                            shift_cnt   <= 0;                                   -- shift_cnt restart
                        else
                            if (shift_cnt = 15) then                            -- can't find "98D"
                                align_state <= S_Chan_Align;
                                Sign_Tp     <= '0';                             -- TP word again
                                shift_cnt   <= 0;                               -- shift_cnt restart
                            else
                                shift_cnt   <= shift_cnt + 1;
                            end if;
                        end if;
                    end if;

                when S_Finsh =>
                    align_state <= S_Idle;
                    Align_Done  <= '1';

                when others =>
                    align_state <= S_Idle;
            end case;
        end if;
    end process;
end Behavioral;