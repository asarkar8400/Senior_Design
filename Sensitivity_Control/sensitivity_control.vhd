library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity sensitivity_control is
	port(
		sensitivity_switch : in STD_LOGIC_VECTOR(1 downto 0);
		peak_power : in STD_LOGIC_VECTOR(11 downto 0);
		divided_peak_power : out STD_LOGIC_VECTOR(11 downto 0)
	);
end sensitivity_control;

architecture sensitivity_control of sensitivity_control is
begin

	process (all) is
 	begin
    	if (sensitivity_switch = "00") then 
			divided_peak_power <= peak_power;		 --don't shift if ss = 0	   		
		elsif (sensitivity_switch = "01") then 
			divided_peak_power <= peak_power srl 1;	 --shift right by 1	if ss = 1
		elsif (sensitivity_switch = "10") then
			divided_peak_power <= peak_power srl 2;	 --shift right by 2	if ss = 2
		else divided_peak_power <= peak_power srl 3; --shift right by 3 if ss = 3
		end if;
	end process;
end sensitivity_control;
