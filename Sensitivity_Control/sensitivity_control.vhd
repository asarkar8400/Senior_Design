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
			divided_peak_power <= peak_power;			   		
		elsif (sensitivity_switch = "01") then 
			divided_peak_power <= peak_power srl 2;
		elsif (sensitivity_switch = "10") then
			divided_peak_power <= peak_power srl 4;
		else divided_peak_power <= peak_power srl 8;
		end if;
	end process;
end sensitivity_control;
