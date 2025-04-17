library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity envelope_follower is
  generic (
    WIDTH         : positive := 12;         -- input/output data width
    CLK_FREQ_HZ   : positive := 100_000_000;-- your FPGA clock, e.g. 100 MHz
    DECAY_TIME_MS : positive := 500         -- decay time in milliseconds
  );
  port (
    clk        : in  std_logic;
    reset_n    : in  std_logic;  
    peak_input : in  unsigned(WIDTH-1 downto 0);
    envelope   : out unsigned(WIDTH-1 downto 0)
  );
end entity;


architecture rtl of envelope_follower is
  -- total number of discrete steps from full‑scale to zero
  constant MAX_STEP : natural := 2**WIDTH;

  -- how many clock ticks between each “–1” step
  constant TICKS_PER_DECAY : natural :=
    integer( (real(CLK_FREQ_HZ) * real(DECAY_TIME_MS) / 1_000.0) / real(MAX_STEP) );

  -- make sure we never divide by zero
  constant DECAY_TICKS : natural := 
  (if TICKS_PER_DECAY > 0 
   then TICKS_PER_DECAY 
   else 1);

  -- counter width: enough bits to count up to DECAY_TICKS
  constant CNT_WIDTH : integer := integer(ceil(log2(real(DECAY_TICKS+1))));

  signal decay_cnt : unsigned(CNT_WIDTH-1 downto 0) := (others => '0');
  signal peak_reg  : unsigned(WIDTH-1    downto 0) := (others => '0');
begin

  process(clk, reset_n)
  begin
    if reset_n = '0' then
      peak_reg  <= (others => '0');
      decay_cnt <= (others => '0');

    elsif rising_edge(clk) then

      -- **attack**: any time input rises above stored value, grab it immediately
      if peak_input > peak_reg then
        peak_reg  <= peak_input;
        decay_cnt <= (others => '0');

      else
        -- **decay**: wait DECAY_TICKS clock cycles, then subtract 1, repeat
        if decay_cnt = to_unsigned(DECAY_TICKS-1, CNT_WIDTH) then
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
