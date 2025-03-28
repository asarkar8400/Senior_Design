library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sensitivity_control_tb is
end sensitivity_control_tb;

architecture tb_architecture of sensitivity_control_tb is
    -- Stimulus signals
    signal sensitivity_switch : std_logic_vector(1 downto 0);
    signal peak_power         : std_logic_vector(11 downto 0);
    -- Observed signal
    signal divided_peak_power : std_logic_vector(11 downto 0);

    constant period: time := 20 ns;

begin
    -- Instantiate Unit Under Test (UUT)
    UUT : entity work.sensitivity_control
    port map (
        sensitivity_switch => sensitivity_switch,
        peak_power => peak_power,
        divided_peak_power => divided_peak_power
    );

    stimulus: process
    begin
        for i in 0 to 3 loop
            sensitivity_switch <= std_logic_vector(to_unsigned(i, 2));
            for j in 0 to 4095 loop
                peak_power <= std_logic_vector(to_unsigned(j, 12));
                wait for period;

				assert (((sensitivity_switch = "00") and (unsigned(divided_peak_power) = unsigned(peak_power))) or 
    			((sensitivity_switch = "01") and (unsigned(divided_peak_power) = shift_right(unsigned(peak_power), 1))) or
    			((sensitivity_switch = "10") and (unsigned(divided_peak_power) = shift_right(unsigned(peak_power), 2))) or
    			((sensitivity_switch = "11") and (unsigned(divided_peak_power) = shift_right(unsigned(peak_power), 3))))
					report "Error: sensitivity_switch=" & to_string(sensitivity_switch) &
       						", peak_power=" & to_string(peak_power) &
       						", Got: " & to_string(divided_peak_power)
					severity error;
            end loop;
        end loop;
        std.env.finish;  
    end process;
end tb_architecture;
