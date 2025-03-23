library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity n_bit_reg is
	generic (n_bit : integer); 
	port (reg_in : in std_logic_vector(n_bit-1 downto 0);
		  clock, resetn : in std_logic; 
		  reg_out : out std_logic_vector(n_bit-1 downto 0));
end n_bit_reg;

architecture behavior of n_bit_reg is
	begin
	
	process (clock, resetn)
	begin
		if (resetn = '0') then				--ASYNCHRONOUS reset
			reg_out <= (others => '0');                 
		elsif (clock'event and clock = '1') then	--data load
			reg_out <= reg_in;
		end if;
	end process;
end behavior;
