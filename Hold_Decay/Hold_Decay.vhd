library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity envelope_follower is
  generic (
    WIDTH         : positive := 12;          -- input data bit width
    CLK_FREQ_HZ   : positive := 100_000_000; -- FPGA CLK speed (100 MHz)
    DECAY_TIME_MS : positive := 500          -- decay time in milliseconds
  );
  port (
    clk        : in  std_logic;
    rst_bar    : in  std_logic;  
    peak_input : in  unsigned(WIDTH-1 downto 0);
    envelope   : out unsigned(WIDTH-1 downto 0)
  );
end entity;

architecture rtl of envelope_follower is

  -- Helper function to safely return DECAY_TICKS
  function safe_decay(clk_cycles : natural) return natural is
  begin
    if clk_cycles > 0 then
      return clk_cycles;
    else
      return 1;
    end if;
  end function;

  -- Custom implementation of clog2
 function clog2(x : natural) return natural is
    variable res : natural := 0;
    variable val : natural := x - 1;
  begin
    while val > 0 loop
      res := res + 1;
      val := val / 2;
    end loop;
    return res;
  end function;

  -- Decay Logic
  constant MAX_STEP      : natural := 2 ** WIDTH;
  constant CLK_CYCLES    : natural := integer((real(CLK_FREQ_HZ) * real(DECAY_TIME_MS) / 1_000.0) / real(MAX_STEP));
  constant DECAY_TICKS   : natural := safe_decay(CLK_CYCLES);
  constant CNT_WIDTH     : integer := clog2(DECAY_TICKS + 1);

  signal decay_cnt       : unsigned(CNT_WIDTH-1 downto 0) := (others => '0');
  signal peak_reg        : unsigned(WIDTH-1 downto 0)     := (others => '0');

  -- Attack Logic
  constant ATTACK_CYCLES     : natural := 5;  -- 50ns @ 100MHz
  constant ATTACK_CNT_WIDTH  : integer := clog2(ATTACK_CYCLES + 1);
  signal attack_cnt          : unsigned(ATTACK_CNT_WIDTH-1 downto 0) := (others => '0');
  signal attack_active       : std_logic := '0';
  signal attack_input        : unsigned(WIDTH-1 downto 0) := (others => '0');

begin

  process(clk, rst_bar)
  begin
    if rst_bar = '0' then
      peak_reg      <= (others => '0');
      decay_cnt     <= (others => '0');
      attack_cnt    <= (others => '0');
      attack_active <= '0';
      attack_input  <= (others => '0');

    elsif rising_edge(clk) then

      -- Start attack if new input > current peak
      if peak_input > peak_reg and attack_active = '0' then
        attack_input  <= peak_input;
        attack_cnt    <= (others => '0');
        attack_active <= '1';

      elsif attack_active = '1' then
        if attack_cnt = to_unsigned(ATTACK_CYCLES - 1, ATTACK_CNT_WIDTH) then
          peak_reg      <= attack_input;
          decay_cnt     <= (others => '0');
          attack_active <= '0';
        else
          attack_cnt <= attack_cnt + 1;
        end if;

      elsif peak_input <= peak_reg then
        -- Decay logic
        if decay_cnt = to_unsigned(DECAY_TICKS - 1, CNT_WIDTH) then
          decay_cnt <= (others => '0');
          if peak_reg > 0 then
            peak_reg <= peak_reg - 1;
          end if;
        else
          decay_cnt <= decay_cnt + 1;
        end if;
      end if;

    end if;
  end process;

  envelope <= peak_reg;

end architecture;
