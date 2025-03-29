library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity led_mapping is
    port(
        peak_pow   : in  STD_LOGIC_VECTOR(11 downto 0); 
        buzzer     : out STD_LOGIC;                     
        led_output : out STD_LOGIC_VECTOR(9 downto 0)  
    );
end led_mapping;

architecture dataflow of led_mapping is
begin
    led_output <= "0000000000" when to_integer(unsigned(peak_pow)) <  410 else
                  "0000000001" when to_integer(unsigned(peak_pow)) <  820 else
                  "0000000011" when to_integer(unsigned(peak_pow)) < 1230 else
                  "0000000111" when to_integer(unsigned(peak_pow)) < 1640 else
                  "0000001111" when to_integer(unsigned(peak_pow)) < 2050 else
                  "0000011111" when to_integer(unsigned(peak_pow)) < 2460 else
                  "0000111111" when to_integer(unsigned(peak_pow)) < 2870 else
                  "0001111111" when to_integer(unsigned(peak_pow)) < 3280 else
                  "0011111111" when to_integer(unsigned(peak_pow)) < 3690 else
                  "0111111111" when to_integer(unsigned(peak_pow)) < 4000 else
                  "1111111111"; 

    buzzer <= '1' when (led_output(0) = '1' or led_output(1) = '1') else '0';
end dataflow;
