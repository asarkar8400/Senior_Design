library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity peak_power_detector_tb is
end peak_power_detector_tb;

architecture tb_architecture of peak_power_detector_tb is
    signal adc_data1, adc_data2, adc_data3, adc_data4 : std_logic_vector(11 downto 0);
    signal peak_power : std_logic_vector(11 downto 0);
    constant period : time := 20 ns;
begin
    UUT : entity work.peak_power_detector
        port map (
            adc_data1 => adc_data1,
            adc_data2 => adc_data2,
            adc_data3 => adc_data3,
            adc_data4 => adc_data4,
            peak_power => peak_power
        );

    stimulus: process
        variable expected_peak_value_int : integer;
        variable expected_peak_value : std_logic_vector(11 downto 0);
    begin
        for i in 0 to 15 loop
            for j in 0 to 15 loop
                for k in 0 to 15 loop
                    for l in 0 to 15 loop
                        adc_data1 <= std_logic_vector(to_unsigned(i, 12));
                        adc_data2 <= std_logic_vector(to_unsigned(j, 12));
                        adc_data3 <= std_logic_vector(to_unsigned(k, 12));
                        adc_data4 <= std_logic_vector(to_unsigned(l, 12));
                        wait for period;

                        expected_peak_value_int := i;
                        if j > expected_peak_value_int then
                            expected_peak_value_int := j;
                        end if;
                        if k > expected_peak_value_int then
                            expected_peak_value_int := k;
                        end if;
                        if l > expected_peak_value_int then
                            expected_peak_value_int := l;
                        end if;
                        expected_peak_value := std_logic_vector(to_unsigned(expected_peak_value_int, 12));

                        assert peak_power = expected_peak_value
                            report "Error: adc_data1=" & to_string(adc_data1) &
                                   ", adc_data2=" & to_string(adc_data2) &
                                   ", adc_data3=" & to_string(adc_data3) &
                                   ", adc_data4=" & to_string(adc_data4) &
                                   " | Expected: " & to_string(expected_peak_value) &
                                   ", Got: " & to_string(peak_power)
                            severity error;
                    end loop;
                end loop;
            end loop;
        end loop;
        std.env.finish;
    end process;
end tb_architecture;
