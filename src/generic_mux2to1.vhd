library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity generic_mux2to1 is
	generic (n_bit : integer); 
	port(input1	  : in std_logic_vector(n_bit - 1 downto 0);
		 input2   : in std_logic_vector(n_bit - 1 downto 0);
		 sel      : in std_logic;								
		 output   : out std_logic_vector(n_bit - 1 downto 0));								
end generic_mux2to1;

architecture behavior of generic_mux2to1 is
begin

output <= input1 when sel ='0' else
		  input2;

end behavior;