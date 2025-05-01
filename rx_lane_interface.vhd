library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity rx_lane_interface is
    port (
        clk         : in  std_logic;
        rst_bar     : in  std_logic;  -- active-low reset
        rx_tvalid   : in  std_logic;
        rx_tdata    : in  std_logic_vector(31 downto 0);
        sample_out  : out std_logic_vector(11 downto 0)
    );
end entity;

architecture rtl of rx_lane_interface is
    signal sample_reg : std_logic_vector(11 downto 0) := (others => '0');
begin

    process(clk)
    begin
        if rising_edge(clk) then
            if rst_bar = '0' then
                sample_reg <= (others => '0');
            elsif rx_tvalid = '1' then
                sample_reg <= rx_tdata(11 downto 0);
            end if;
        end if;
    end process;

    sample_out <= sample_reg;

end architecture;
