library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity flip_flop is
	port (ff_in : in std_logic;
		  clock, resetn : in std_logic; 
		  ff_out : out std_logic);
end flip_flop;

architecture behavior of flip_flop is
	begin
	
	process (clock, resetn)
	begin
		if (resetn = '0') then				--ASYNCHRONOUS reset
			ff_out <= '0';                 
		elsif (clock'event and clock = '1') then	
			ff_out <= ff_in;
		end if;
	end process;
end behavior;
