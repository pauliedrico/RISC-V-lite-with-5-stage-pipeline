--vhdl unsigned memory with <data_bits> data parallelism and <addr_bits> address parallelism

--data_in, data_out : unsigned data input and output with <data_bits> data parallelism
--address : unsigned address input with <addr_bits> address parallelism
--cs : chip select std_logic input
--wrn : active low write enable std_logic input
--rd : read enable std_logic input
--clk : clock std_logic input

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity generic_memory is
	generic (addr_bits, data_bits : integer);
	port (data_in : in std_logic_vector(data_bits-1 downto 0);
			data_out : out std_logic_vector(data_bits-1 downto 0);
			address : in std_logic_vector(0 to addr_bits-1);
			cs, wrn, rd, clk : in std_logic);
end generic_memory;


architecture behavior of generic_memory is
	type memory is array(0 to (2**addr_bits)-1) of std_logic_vector(data_bits-1 downto 0);
	signal mem : memory;
	begin
	process(clk)
		begin
		if clk'event and clk = '1' then
			if cs = '1' then										--for any operation cs must be active ('1')
				if wrn = '0' and rd = '0' then				--wrn and rd must be '0' for reading operations
					mem(to_integer(unsigned(address))) <= data_in;
				elsif wrn = '1' and rd = '1' then			--wrn and rd must be '1' for writing operations
					data_out <= mem(to_integer(unsigned(address)));
				end if;
			end if;
		end if;
	end process;
	
end behavior;