----------------------------------------------------------------------------------
-- Company:         CIOMP
-- Engineer:        WangZheng
-- Create Date:     2025/03/06 15:03:24
-- Module Name:     IMA_GEN - Behavioral
-- Project Name:    CH4_G400
-- Target Devices:  xc7k325tffg900-2
-- Tool Versions:   Vivado 2018.3
-- Description:     generate self-check image
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

entity IMA_GEN is
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
end IMA_GEN;

architecture Behavioral of IMA_GEN is

    signal  clk_cnt                 : integer range 0 to 10;
    signal  delay_cnt               : integer range 0 to 100;
    signal  pixel_cnt               : STD_LOGIC_VECTOR (8 downto 0);
    signal  line_cnt                : integer range 0 to 2048;
    signal  frame_cnt               : STD_LOGIC_VECTOR (7 downto 0);            -- count the circle of 2048 rows
    signal  Start_Word1             : STD_LOGIC_VECTOR (11 downto 0);
    signal  Start_Word2             : STD_LOGIC_VECTOR (11 downto 0);
    signal  Start_Word3             : STD_LOGIC_VECTOR (11 downto 0);
    signal  Start_Word4             : STD_LOGIC_VECTOR (11 downto 0);
    signal  Start_Word5             : STD_LOGIC_VECTOR (11 downto 0);
    signal  Start_Word6             : STD_LOGIC_VECTOR (11 downto 0);
    signal  Start_Word7             : STD_LOGIC_VECTOR (11 downto 0);
    signal  Start_Word8             : STD_LOGIC_VECTOR (11 downto 0);
    signal  Data_Word1              : STD_LOGIC_VECTOR (11 downto 0);
    signal  Data_Word2              : STD_LOGIC_VECTOR (11 downto 0);
    signal  Data_Word3              : STD_LOGIC_VECTOR (11 downto 0);
    signal  Data_Word4              : STD_LOGIC_VECTOR (11 downto 0);
    signal  Data_Word5              : STD_LOGIC_VECTOR (11 downto 0);
    signal  Data_Word6              : STD_LOGIC_VECTOR (11 downto 0);
    signal  Data_Word7              : STD_LOGIC_VECTOR (11 downto 0);
    signal  Data_Word8              : STD_LOGIC_VECTOR (11 downto 0);
    type    Fsm_Ima  is (S_Idle, S_Out, S_Sync, S_Ima, S_Delay);
    signal  state       : Fsm_Ima;

    -- attribute mark_debug    : string;
    -- attribute mark_debug    of Self_Sync_Rx     : signal is "true";
    -- attribute mark_debug    of Self_Image_Out   : signal is "true";
    -- attribute mark_debug    of Self_Par_Chan1   : signal is "true";
    -- attribute mark_debug    of Self_Par_Chan2   : signal is "true";
    -- attribute mark_debug    of Self_Par_Chan3   : signal is "true";
    -- attribute mark_debug    of Self_Par_Chan4   : signal is "true";
    -- attribute mark_debug    of Self_Par_Chan5   : signal is "true";
    -- attribute mark_debug    of Self_Par_Chan6   : signal is "true";
    -- attribute mark_debug    of Self_Par_Chan7   : signal is "true";
    -- attribute mark_debug    of Self_Par_Chan8   : signal is "true";
    -- attribute mark_debug    of clk_cnt          : signal is "true";


begin

    Frame_Circle_S  <= frame_cnt;

    process (Clk_Ref, Rst_Ref) begin
        if (Rst_Ref = '0') then
            state           <= S_Idle;
            clk_cnt         <= 0;
            delay_cnt       <= 0;
            pixel_cnt       <= (others => '0');
            line_cnt        <= 0;
            Self_Sync_Rx    <= '0';
            Self_Image_Out  <= '0';
            frame_cnt       <= (others => '0');
            Self_Par_Chan1  <= (others => '0');
            Self_Par_Chan2  <= (others => '0');
            Self_Par_Chan3  <= (others => '0');
            Self_Par_Chan4  <= (others => '0');
            Self_Par_Chan5  <= (others => '0');
            Self_Par_Chan6  <= (others => '0');
            Self_Par_Chan7  <= (others => '0');
            Self_Par_Chan8  <= (others => '0');
            Start_Word1     <= X"000";
            Start_Word2     <= X"100";
            Start_Word3     <= X"200";
            Start_Word4     <= X"300";
            Start_Word5     <= X"400";
            Start_Word6     <= X"500";
            Start_Word7     <= X"600";
            Start_Word8     <= X"700";
            Data_Word1      <= (others => '0');
            Data_Word2      <= (others => '0');
            Data_Word3      <= (others => '0');
            Data_Word4      <= (others => '0');
            Data_Word5      <= (others => '0');
            Data_Word6      <= (others => '0');
            Data_Word7      <= (others => '0');
            Data_Word8      <= (others => '0');
            elsif (Clk_Ref'event and Clk_Ref = '1') then
            case state is
                when S_Idle =>
                    if (Cmd_Check2 = '1') then
                        state       <= S_Out;
                    else
                        state       <= S_Idle;
                        line_cnt    <= 0;
                        frame_cnt   <= (others => '0');
                    end if;
                    clk_cnt         <= 0;
                    delay_cnt       <= 0;
                    pixel_cnt       <= (others => '0');
                    Self_Sync_Rx    <= '0';
                    Self_Par_Chan1  <= (others => '0');
                    Self_Par_Chan2  <= (others => '0');
                    Self_Par_Chan3  <= (others => '0');
                    Self_Par_Chan4  <= (others => '0');
                    Self_Par_Chan5  <= (others => '0');
                    Self_Par_Chan6  <= (others => '0');
                    Self_Par_Chan7  <= (others => '0');
                    Self_Par_Chan8  <= (others => '0');
                    Data_Word1      <= (others => '0');
                    Data_Word2      <= (others => '0');
                    Data_Word3      <= (others => '0');
                    Data_Word4      <= (others => '0');
                    Data_Word5      <= (others => '0');
                    Data_Word6      <= (others => '0');
                    Data_Word7      <= (others => '0');
                    Data_Word8      <= (others => '0');
                when S_Out =>
                    if (clk_cnt = 9) then
                        state       <= S_Sync;
                        clk_cnt     <= 0;
                        Self_Sync_Rx    <= '1';
                        Self_Image_Out  <= '1';
                    else
                        state       <= S_Out;
                        clk_cnt     <= clk_cnt + 1;
                    end if;

                when S_Sync =>
                    if (clk_cnt = 8) then
                        state           <= S_Ima;
                        clk_cnt         <= 0;
                        Self_Par_Chan1  <= X"98E";
                        Self_Par_Chan2  <= X"98E";
                        Self_Par_Chan3  <= X"98E";
                        Self_Par_Chan4  <= X"98E";
                        Self_Par_Chan5  <= X"98E";
                        Self_Par_Chan6  <= X"98E";
                        Self_Par_Chan7  <= X"98E";
                        Self_Par_Chan8  <= X"98E";
                        Data_Word1      <= Start_Word1;
                        Data_Word2      <= Start_Word2;
                        Data_Word3      <= Start_Word3;
                        Data_Word4      <= Start_Word4;
                        Data_Word5      <= Start_Word5;
                        Data_Word6      <= Start_Word6;
                        Data_Word7      <= Start_Word7;
                        Data_Word8      <= Start_Word8;
                    else
                        state       <= S_Sync;
                        clk_cnt     <= clk_cnt + 1;
                    end if;
                    Self_Sync_Rx    <= '0';

                when S_Ima =>
                    if (pixel_cnt = X"1FF") then
                        state       <= S_Delay;
                        pixel_cnt   <= (others => '0');
                    elsif (pixel_cnt(0) = '1') then
                        state       <= S_Ima;
                        pixel_cnt   <= pixel_cnt + '1';
                        Data_Word1  <= Data_Word1 + '1';
                        Data_Word2  <= Data_Word2 + '1';
                        Data_Word3  <= Data_Word3 + '1';
                        Data_Word4  <= Data_Word4 + '1';
                        Data_Word5  <= Data_Word5 + '1';
                        Data_Word6  <= Data_Word6 + '1';
                        Data_Word7  <= Data_Word7 + '1';
                        Data_Word8  <= Data_Word8 + '1';
                    else
                        state       <= S_Ima;
                        pixel_cnt   <= pixel_cnt + '1';
                    end if;
                    Self_Par_Chan1  <= Data_Word1;
                    Self_Par_Chan2  <= Data_Word2;
                    Self_Par_Chan3  <= Data_Word3;
                    Self_Par_Chan4  <= Data_Word4;
                    Self_Par_Chan5  <= Data_Word5;
                    Self_Par_Chan6  <= Data_Word6;
                    Self_Par_Chan7  <= Data_Word7;
                    Self_Par_Chan8  <= Data_Word8;

                when S_Delay =>
                    if (delay_cnt = 60) then
                        state       <= S_Idle;
                        delay_cnt   <= 0;
                    elsif (delay_cnt = 40) then
                        if (line_cnt = 2047) then                               -- add frame_cnt
                            line_cnt    <= 0;
                            frame_cnt   <= frame_cnt + '1';
                            Self_Image_Out  <= '0';
                            Start_Word1     <= X"000";
                            Start_Word2     <= X"100";
                            Start_Word3     <= X"200";
                            Start_Word4     <= X"300";
                            Start_Word5     <= X"400";
                            Start_Word6     <= X"500";
                            Start_Word7     <= X"600";
                            Start_Word8     <= X"700";
                        else
                            line_cnt    <= line_cnt + 1;
                            Start_Word1 <= Start_Word1 + '1';
                            Start_Word2 <= Start_Word2 + '1';
                            Start_Word3 <= Start_Word3 + '1';
                            Start_Word4 <= Start_Word4 + '1';
                            Start_Word5 <= Start_Word5 + '1';
                            Start_Word6 <= Start_Word6 + '1';
                            Start_Word7 <= Start_Word7 + '1';
                            Start_Word8 <= Start_Word8 + '1';
                        end if;
                        state       <= S_Delay;
                        delay_cnt   <= delay_cnt + 1;
                    else
                        state       <= S_Delay;
                        delay_cnt   <= delay_cnt + 1;
                    end if;

                when others =>
                    state   <= S_Idle;
            end case;
        end if;
    end process;
end Behavioral;