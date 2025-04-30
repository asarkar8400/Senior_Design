library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity Hold_Decay_tb is
end entity;

architecture sim of Hold_Decay_tb is
    -- Clock and reset signals
    constant CLK_PERIOD : time := 10 ns;  -- 100 MHz clock
    signal clk : std_logic := '0';
    signal rst : std_logic := '1';
    
    -- DUT signals
    signal peak_in   : std_logic_vector(11 downto 0) := (others => '0');
    signal decay_out : std_logic_vector(11 downto 0);
    
    -- Test signals for stimulus generation
    signal sim_done : boolean := false;
    
    -- Helper function to convert std_logic_vector to integer
    function to_int(slv : std_logic_vector) return integer is
    begin
        return to_integer(unsigned(slv));
    end function;
    
begin
    -- Device Under Test instantiation
    DUT: entity work.Hold_Decay
    port map (
        clk       => clk,
        rst       => rst,
        peak_in   => peak_in,
        decay_out => decay_out
    );
    
    -- Clock generation
    clk_process: process
    begin
        while not sim_done loop
            clk <= '0';
            wait for CLK_PERIOD/2;
            clk <= '1';
            wait for CLK_PERIOD/2;
        end loop;
        wait;
    end process;
    
    -- Stimulus process
    stim_process: process
        -- Variables for timing verification
        variable attack_start_time : time;
        variable attack_end_time : time;
        variable decay_start_time : time;
        variable decay_end_time : time;
        variable current_value : integer := 0;
        variable prev_value : integer := 0;
        
        -- For reporting
        variable l : line;
    begin
        -- Initialize and assert reset
        peak_in <= (others => '0');
        rst <= '1';
        wait for 100 ns;
        rst <= '0';
        wait for 100 ns;
        
        write(l, string'("Test 1: Basic attack/decay with value 1000"));
        writeline(output, l);
        
        -- Test 1: Simple attack/hold/decay with medium value
        attack_start_time := now;
        peak_in <= std_logic_vector(to_unsigned(1000, 12));  -- Set peak to 1000
        
        -- Wait for attack to complete and value to stabilize
        wait for 100 ns;
        attack_end_time := now;
        
        -- Verify that output reached the peak value
        assert to_int(decay_out) = 1000 
            report "Failed to reach peak value 1000, got " & integer'image(to_int(decay_out))
            severity error;
        
        -- Report attack time
        write(l, string'("  Attack time: ") & time'image(attack_end_time - attack_start_time));
        writeline(output, l);
        
        -- Now verify decay timing
        write(l, string'("  Starting decay verification..."));
        writeline(output, l);
        
        peak_in <= (others => '0');  -- Remove the peak input
        decay_start_time := now;
        
        -- Monitor decay until value reaches zero or timeout
        wait for 100 ns;  -- Give time for state transition
        prev_value := to_int(decay_out);
        
        while to_int(decay_out) > 0 loop
            current_value := to_int(decay_out);
            
            -- Verify value is decreasing
            if current_value < prev_value then
                write(l, string'("  Decay progress: value = ") & integer'image(current_value) & 
                        string'(" at time ") & time'image(now - decay_start_time));
                writeline(output, l);
            end if;
            
            prev_value := current_value;
            wait for 100 us;  -- Check value every 100 us
            
            -- Safety timeout
            if (now - decay_start_time) > 10 ms then
                write(l, string'("  WARNING: Decay taking too long, aborting decay test"));
                writeline(output, l);
                exit;
            end if;
        end loop;
        
        decay_end_time := now;
        
        write(l, string'("  Total decay time: ") & time'image(decay_end_time - decay_start_time));
        writeline(output, l);
        
        -- Test 2: Check re-triggering during decay
        wait for 1 ms;
        write(l, string'("Test 2: Re-trigger during decay"));
        writeline(output, l);
        
        -- First pulse
        peak_in <= std_logic_vector(to_unsigned(800, 12));
        wait for 200 ns;
        peak_in <= (others => '0');
        
        -- Wait for decay to start
        wait for 500 us;
        
        -- Second higher pulse during decay - should re-trigger
        peak_in <= std_logic_vector(to_unsigned(1200, 12));
        
        wait for 200 ns;
        peak_in <= (others => '0');
        
        -- Verify that the value increased
        assert to_int(decay_out) = 1200
            report "Failed to re-trigger to value 1200, got " & integer'image(to_int(decay_out))
            severity error;
            
        write(l, string'("  Re-triggered value: ") & integer'image(to_int(decay_out)));
        writeline(output, l);
        
        -- Wait for full decay
        wait for 6 ms;
        
        -- Test 3: Multiple peaks in succession
        write(l, string'("Test 3: Multiple peaks in quick succession"));
        writeline(output, l);
        
        peak_in <= std_logic_vector(to_unsigned(300, 12));
        wait for 100 ns;
        
        peak_in <= std_logic_vector(to_unsigned(700, 12));
        wait for 100 ns;
        
        peak_in <= std_logic_vector(to_unsigned(500, 12));
        wait for 100 ns;
        
        peak_in <= std_logic_vector(to_unsigned(1500, 12));
        wait for 100 ns;
        
        -- Final peak should win
        assert to_int(decay_out) = 1500
            report "Failed to capture highest peak 1500, got " & integer'image(to_int(decay_out))
            severity error;
            
        peak_in <= (others => '0');
        
        write(l, string'("  Final peak captured: ") & integer'image(to_int(decay_out)));
        writeline(output, l);
        
        -- Wait for full decay
        wait for 6 ms;
        
        -- Test 4: Maximum value
        write(l, string'("Test 4: Maximum value (4095)"));
        writeline(output, l);
        
        peak_in <= (others => '1');  -- 4095 (max 12-bit value)
        wait for 200 ns;
        peak_in <= (others => '0');
        
        assert to_int(decay_out) = 4095
            report "Failed to reach maximum value 4095, got " & integer'image(to_int(decay_out))
            severity error;
            
        -- Monitor full decay of maximum value
        decay_start_time := now;
        
        while to_int(decay_out) > 0 loop
            -- Report at certain thresholds
            if to_int(decay_out) = 3000 or to_int(decay_out) = 2000 or 
               to_int(decay_out) = 1000 or to_int(decay_out) = 100 then
                write(l, string'("  Decay progress for max value: ") & integer'image(to_int(decay_out)) & 
                        string'(" at time ") & time'image(now - decay_start_time));
                writeline(output, l);
            end if;
            
            wait for 200 us;
            
            -- Safety timeout
            if (now - decay_start_time) > 10 ms then
                write(l, string'("  WARNING: Max value decay taking too long, aborting"));
                writeline(output, l);
                exit;
            end if;
        end loop;
        
        decay_end_time := now;
        write(l, string'("  Total decay time for max value: ") & time'image(decay_end_time - decay_start_time));
        writeline(output, l);
        
        -- End simulation
        write(l, string'("All tests completed!"));
        writeline(output, l);
        sim_done <= true;
        wait;
    end process;
    
    -- Monitor process to track output changes for debugging
    monitor_process: process
        variable l : line;
    begin
        if rising_edge(clk) then
            if rst = '0' then  -- Only monitor when not in reset
            end if;
        end if;
        wait on clk;
    end process;
    
end architecture;
