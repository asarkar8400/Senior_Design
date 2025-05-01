library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity led_mapping_tb is
end led_mapping_tb;

architecture tb_architecture of led_mapping_tb is
    signal peak_pow   : std_logic_vector(11 downto 0);
    signal buzzer     : std_logic;
    signal led_output : std_logic_vector(9 downto 0);
    constant period   : time := 20 ns;

    function expected_led_output(peak_pow_val : integer) return std_logic_vector is
    begin
        if peak_pow_val < 410 then
            return "0000000000";
        elsif peak_pow_val < 820 then
            return "0000000001";
        elsif peak_pow_val < 1230 then
            return "0000000011";
        elsif peak_pow_val < 1640 then
            return "0000000111";
        elsif peak_pow_val < 2050 then
            return "0000001111";
        elsif peak_pow_val < 2460 then
            return "0000011111";
        elsif peak_pow_val < 2870 then
            return "0000111111";
        elsif peak_pow_val < 3280 then
            return "0001111111";
        elsif peak_pow_val < 3690 then
            return "0011111111";
        elsif peak_pow_val < 4000 then
            return "0111111111";
        else
            return "1111111111";
        end if;
    end function expected_led_output;

    function expected_buzzer(led_out : std_logic_vector) return std_logic is
    begin
        if led_out(0) = '1' or led_out(1) = '1' then
            return '1';
        else
            return '0';
        end if;
    end function expected_buzzer;

begin
    UUT: entity work.led_mapping
        port map (
            peak_pow   => peak_pow,
            buzzer     => buzzer,
            led_output => led_output
        );
		
    stimulus: process
        variable peak_pow_int : integer;
        variable expected_led : std_logic_vector(9 downto 0);
        variable expected_buz : std_logic;
    begin
        for i in 0 to 4095 loop
            peak_pow_int := i;
            peak_pow <= std_logic_vector(to_unsigned(peak_pow_int, 12));
            wait for period;

            expected_led := expected_led_output(peak_pow_int);
            expected_buz := expected_buzzer(expected_led);

            if led_output /= expected_led then
                report "Error when peak_pow = " & integer'image(peak_pow_int) &
                      ", expected led_output = " & to_string(expected_led) &
                      ", but got led_output = " & to_string(led_output)
                severity error;
            end if;

            if buzzer /= expected_buz then
                report "Error for peak_pow = " & integer'image(peak_pow_int) &
                      ", expected buzzer = " & std_logic'image(expected_buz) &
                      ", but got buzzer = " & std_logic'image(buzzer)
                severity error;
            end if;
        end loop;
        std.env.finish;
    end process;
end tb_architecture;
