library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Hold_Decay is
    port (
        clk        : in  std_logic;
        rst        : in  std_logic;
        peak_in    : in  std_logic_vector(11 downto 0);
        decay_out  : out std_logic_vector(11 downto 0)
    );
end entity;

architecture Behavioral of Hold_Decay is
    constant WIDTH             : integer := 12;
    constant CLK_FREQ_HZ       : integer := 100_000_000;
    constant ATTACK_TIME_NS    : integer := 50;
    constant DECAY_TIME_MS     : integer := 5;

    -- Precomputed for synthesis safety
    constant ATTACK_CYCLES     : natural := 5;         -- 100 MHz × 50 ns
    constant DECAY_CYCLES      : natural := 500000;    -- 100 MHz × 5 ms

    type state_type is (IDLE, ATTACK, HOLD, DECAY);
    signal state : state_type := IDLE;

    signal current_value        : unsigned(WIDTH-1 downto 0) := (others => '0');
    signal peak_sample          : unsigned(WIDTH-1 downto 0) := (others => '0');
    signal target_value         : unsigned(WIDTH-1 downto 0) := (others => '0');

    signal timer                : integer range 0 to ATTACK_CYCLES := 0;
    signal decay_step_count     : integer := 0;
    signal decay_tick_counter   : integer := 0;
    signal decay_interval       : integer := 1;

    -- Safe divisor to prevent division by zero
    function safe_divisor(val : integer) return integer is
    begin
        if val <= 0 then
            return 1;
        else
            return val;
        end if;
    end function;
begin

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                current_value        <= (others => '0');
                timer                <= 0;
                decay_step_count     <= 0;
                decay_tick_counter   <= 0;
                decay_interval       <= 1;
                state                <= IDLE;
            else
                peak_sample <= unsigned(peak_in);

                case state is
                    when IDLE =>
                        if peak_sample > current_value then
                            target_value <= peak_sample;
                            timer        <= 0;
                            state        <= ATTACK;
                        end if;

                    when ATTACK =>
                        if timer < ATTACK_CYCLES - 1 then
                            timer <= timer + 1;
                        else
                            current_value       <= target_value;
                            decay_step_count    <= to_integer(target_value);
                            decay_tick_counter  <= 0;
                            decay_interval      <= DECAY_CYCLES / safe_divisor(to_integer(target_value));
                            state               <= HOLD;
                        end if;

                    when HOLD =>
                        if peak_sample > target_value then
                            target_value        <= peak_sample;
                            decay_step_count    <= to_integer(peak_sample);
                            decay_tick_counter  <= 0;
                            decay_interval      <= DECAY_CYCLES / safe_divisor(to_integer(peak_sample));
                        else
                            timer <= 0;
                            state <= DECAY;
                        end if;

                    when DECAY =>
                        if peak_sample > current_value then
                            target_value        <= peak_sample;
                            current_value       <= peak_sample;
                            decay_step_count    <= to_integer(peak_sample);
                            decay_tick_counter  <= 0;
                            decay_interval      <= DECAY_CYCLES / safe_divisor(to_integer(peak_sample));
                            state               <= HOLD;
                        else
                            if decay_step_count > 0 then
                                if decay_tick_counter >= decay_interval then
                                    current_value      <= current_value - 1;
                                    decay_step_count   <= decay_step_count - 1;
                                    decay_tick_counter <= 0;
                                else
                                    decay_tick_counter <= decay_tick_counter + 1;
                                end if;
                            else
                                state <= IDLE;
                            end if;
                        end if;
                end case;
            end if;
        end if;
    end process;

    decay_out <= std_logic_vector(current_value);
end architecture;
