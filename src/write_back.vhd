
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity write_back is
  port
  (
    Read_data 		: in std_logic_vector(31 downto 0);
	ALU_result		: in std_logic_vector(31 downto 0);
	MemToReg		: in std_logic;
	out_mux_WB		: out std_logic_vector(31 downto 0)
  );
end write_back;


architecture behavior of write_back is
	-- signals declaration
	
	-- components declaration
   component generic_mux2to1 is
    generic
      (n_bit : integer);
    port
    (
      input1 : in std_logic_vector(n_bit - 1 downto 0);
      input2 : in std_logic_vector(n_bit - 1 downto 0);
      sel    : in std_logic;
      output : out std_logic_vector(n_bit - 1 downto 0));
  end component;
  
  begin
  
  Mux_WB : generic_mux2to1 generic map (n_bit => 32)
  port map(input1 => ALU_result, input2 => Read_data, sel => MemToReg, output => out_mux_WB);
  
end behavior;
