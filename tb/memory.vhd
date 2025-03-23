library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity memory is
  port
  (
    CLK             : in std_logic;
    RSTn            : in std_logic;
	MemWrite, MemRead: in std_logic;
	address			: in std_logic_vector(31 downto 0);
	write_data		: in std_logic_vector(31 downto 0);
	read_data		: out std_logic_vector(31 downto 0)
	
  );
end memory;


architecture behavior of memory is
	-- signals declaration
	
	-- components declaration

  begin
  


end behavior;