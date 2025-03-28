library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity peak_power_detector is
	port(
		adc_data1 : in STD_LOGIC_VECTOR(11 downto 0);
		adc_data2 : in STD_LOGIC_VECTOR(11 downto 0);
		adc_data3 : in STD_LOGIC_VECTOR(11 downto 0);
		adc_data4 : in STD_LOGIC_VECTOR(11 downto 0);
		peak_power : out STD_LOGIC_VECTOR(11 downto 0)
	);
end peak_power_detector;


architecture peak_power_detector of peak_power_detector is
begin
	process (all) is
 	begin
    	if (adc_data1 >= adc_data2 and adc_data1 >= adc_data3 and adc_data1 >= adc_data4) then 
			peak_power <= adc_data1;			   		
		elsif (adc_data2 >= adc_data3 and adc_data2 >= adc_data4) then 
			peak_power <= adc_data2;
		elsif (adc_data3 >= adc_data4) then
			peak_power <= adc_data3;
		else peak_power <= adc_data4;
		end if;
	end process;
end peak_power_detector;
