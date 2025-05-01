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
    -- Precomputed to avoid synthesis overflow
    constant ATTACK_CYCLES     : natural := 5;         -- 50 ns × 100 MHz
    constant DECAY_CYCLES      : natural := 50000000;  -- 500 ms × 100 MHz

    type state_type is (IDLE, ATTACK, HOLD, DECAY);
    signal state : state_type := IDLE;

    signal current_value        : unsigned(WIDTH-1 downto 0) := (others => '0');
    signal target_value         : unsigned(WIDTH-1 downto 0) := (others => '0');

    signal attack_timer         : integer range 0 to ATTACK_CYCLES := 0;
    signal decay_step_count     : integer := 0;
    signal decay_tick_counter   : integer := 0;
    signal decay_interval       : integer := 1;
begin

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                current_value        <= (others => '0');
                target_value         <= (others => '0');
                attack_timer         <= 0;
                decay_step_count     <= 0;
                decay_tick_counter   <= 0;
                decay_interval       <= 1;
                state                <= IDLE;
            else
                case state is
                    when IDLE =>
                        if unsigned(peak_in) > current_value then
                            target_value <= unsigned(peak_in);
                            attack_timer <= 0;
                            state        <= ATTACK;
                        end if;

                    when ATTACK =>
                        if attack_timer < ATTACK_CYCLES - 1 then
                            attack_timer <= attack_timer + 1;
                        else
                            current_value       <= target_value;
                            decay_step_count    <= to_integer(target_value);
                            decay_tick_counter  <= 0;
                            decay_interval      <= DECAY_CYCLES / (to_integer(target_value) + 1);
                            state               <= HOLD;
                        end if;

                    when HOLD =>
                        if unsigned(peak_in) > target_value then
                            target_value        <= unsigned(peak_in);
                            decay_step_count    <= to_integer(unsigned(peak_in));
                            decay_tick_counter  <= 0;
                            decay_interval      <= DECAY_CYCLES / (to_integer(unsigned(peak_in)) + 1);
                        else
                            state <= DECAY;
                        end if;

                    when DECAY =>
                        if unsigned(peak_in) > current_value then
                            target_value        <= unsigned(peak_in);
                            current_value       <= unsigned(peak_in);
                            decay_step_count    <= to_integer(unsigned(peak_in));
                            decay_tick_counter  <= 0;
                            decay_interval      <= DECAY_CYCLES / (to_integer(unsigned(peak_in)) + 1);
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
