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
    constant CLK_FREQ_HZ       : integer := 100_000_000;  -- 100 MHz clock
    constant ATTACK_TIME_NS    : integer := 50;           -- 50ns attack time
    constant DECAY_TIME_MS     : integer := 5;            -- 5ms for testing (500ms in final version)
    
    -- Calculate clock cycles for timing
    constant ATTACK_CYCLES     : integer := (CLK_FREQ_HZ * ATTACK_TIME_NS) / 1_000_000_000;  -- cycles for 50ns
    constant DECAY_CYCLES      : integer := (CLK_FREQ_HZ * DECAY_TIME_MS) / 1000;            -- cycles for decay time
    
    -- State machine states
    type state_type is (IDLE, ATTACK, HOLD, DECAY);
    signal state : state_type := IDLE;
    
    signal current_value    : unsigned(WIDTH-1 downto 0) := (others => '0');
    signal peak_sample      : unsigned(WIDTH-1 downto 0) := (others => '0');
    signal target_value     : unsigned(WIDTH-1 downto 0) := (others => '0');
    signal timer            : integer range 0 to DECAY_CYCLES := 0;
    signal decay_step_size  : unsigned(WIDTH-1 downto 0) := (others => '0');
    signal decay_step_count : integer := 0;
    signal decay_interval   : integer := 1;
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                current_value <= (others => '0');
                timer <= 0;
                state <= IDLE;
            else
                peak_sample <= unsigned(peak_in);
                
                case state is
                    when IDLE =>
                        -- Start attack phase if new peak is higher
                        if peak_sample > current_value then
                            target_value <= peak_sample;
                            state <= ATTACK;
                            timer <= 0;
                            
                            -- Calculate decay parameters for linear decay over DECAY_CYCLES
                            if peak_sample > 0 then
                                -- For consistent 5ms decay time, calculate step interval
                                decay_step_count <= to_integer(peak_sample);
                                decay_interval <= DECAY_CYCLES / to_integer(peak_sample);
                                if (DECAY_CYCLES / to_integer(peak_sample)) = 0 then
                                    decay_interval <= 1; -- Minimum 1 cycle per step
                                end if;
                            end if;
                        end if;
                        
                    when ATTACK =>
                        -- Instant attack (within ATTACK_CYCLES)
                        if timer < ATTACK_CYCLES-1 then
                            timer <= timer + 1;
                        else
                            current_value <= target_value;
                            timer <= 0;
                            state <= HOLD;
                        end if;
                        
                    when HOLD =>
                        -- Check if a new higher peak arrived
                        if peak_sample > target_value then
                            target_value <= peak_sample;
                            timer <= 0;
                            -- Recalculate decay parameters
                            if peak_sample > 0 then
                                decay_step_count <= to_integer(peak_sample);
                                decay_interval <= DECAY_CYCLES / to_integer(peak_sample);
                                if (DECAY_CYCLES / to_integer(peak_sample)) = 0 then
                                    decay_interval <= 1;
                                end if;
                            end if;
                        else
                            -- After hold, start decay
                            state <= DECAY;
                            timer <= 0;
                        end if;
                        
                    when DECAY =>
                        -- Check if a new higher peak arrived during decay
                        if peak_sample > current_value then
                            target_value <= peak_sample;
                            current_value <= peak_sample;
                            timer <= 0;
                            state <= HOLD;
                            
                            -- Recalculate decay parameters
                            if peak_sample > 0 then
                                decay_step_count <= to_integer(peak_sample);
                                decay_interval <= DECAY_CYCLES / to_integer(peak_sample);
                                if (DECAY_CYCLES / to_integer(peak_sample)) = 0 then
                                    decay_interval <= 1;
                                end if;
                            end if;
                        else
                            -- Linear decay over DECAY_CYCLES
                            if timer >= decay_interval and current_value > 0 then
                                current_value <= current_value - 1;
                                timer <= 0;
                            elsif current_value = 0 then
                                state <= IDLE;
                            else
                                timer <= timer + 1;
                            end if;
                        end if;
                end case;
            end if;
        end if;
    end process;
    
    decay_out <= std_logic_vector(current_value);
end architecture;
