library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity n_bit_unsigned_adder is
	generic (n_bit : integer);
	port (	in_a, in_b : in std_logic_vector (n_bit-1 downto 0);
			sum_out : out std_logic_vector (n_bit-1 downto 0));
end n_bit_unsigned_adder;

architecture behavior of n_bit_unsigned_adder is
	begin
	process(in_a,in_b)
	begin
		sum_out <= std_logic_vector(unsigned(in_a) + unsigned(in_b));
	end process;

end behavior;
