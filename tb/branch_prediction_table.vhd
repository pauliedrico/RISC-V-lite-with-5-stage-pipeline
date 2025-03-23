library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity branch_prediction_table is
  port
  (
    resetn         		 				: in std_logic;
	read_address, write_address 		: in std_logic_vector(6 downto 0);
	write_data							: in std_logic_vector(32 downto 0);
	wr									: in std_logic; 
	prediction						    : out std_logic; 
	target				 				: out std_logic_vector(31 downto 0)
  );
end branch_prediction_table;

architecture behavior of branch_prediction_table is

 -- signals declaration
 type table_array is array(0 to 127) of std_logic_vector(32 downto 0);
 signal table : table_array;
 signal out_table : std_logic_vector(32 downto 0);
 
begin

process (resetn, read_address, write_address, write_data, wr)
  begin
	
    if resetn = '0' then --reset
      table <= (others => (others => '0'));
	  
    else
		out_table <= table(to_integer(unsigned(read_address))); --read
		
      if wr = '1' then
        table(to_integer(unsigned(write_address))) <= write_data; -- write
      end if;
    end if;
  end process;
  
  prediction <= out_table(32);
  target <= out_table(31 downto 0);
  
end behavior;


