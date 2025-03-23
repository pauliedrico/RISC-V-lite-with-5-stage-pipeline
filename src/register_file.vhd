library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity register_file is
  port
  (
    clk             : in std_logic;
    resetn          : in std_logic;
    read_register_1 : in std_logic_vector(4 downto 0);
    read_register_2 : in std_logic_vector(4 downto 0);
    write_register  : in std_logic_vector(4 downto 0);
    write_data      : in std_logic_vector(31 downto 0);
    reg_write       : in std_logic;
    read_data_1     : out std_logic_vector(31 downto 0);
    read_data_2     : out std_logic_vector(31 downto 0)
  );
end;

architecture beh of register_file is

  type register_array is array(0 to 31) of std_logic_vector(31 downto 0);
  signal registers : register_array;
  
--begin
begin
  
  process (clk, resetn)
  begin
	
    if resetn = '0' then --reset
      registers(0) <= (others => '0');
	  registers(1) <= (others => '0');
      registers(2) <= "01111111111111111110111111111100";
      registers(3) <= "00010000000000001000000000000000";
	  registers(4 to 31) <= (others => (others => '0'));
	  
	  
    elsif (clk'event and clk = '1') then --clock event
		read_data_1 <= registers(to_integer(unsigned(read_register_1))); --read
		read_data_2 <= registers(to_integer(unsigned(read_register_2)));
		
      if (reg_write = '1' and not (write_register="00000")) then
        registers(to_integer(unsigned(write_register))) <= write_data; -- write
      end if;
    end if;
  end process;
end beh;


