library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity instruction_decode is
  port
  (
    CLK             : in std_logic;
    RSTn            : in std_logic;
	write_reg		: in std_logic_vector(4 downto 0);
	write_data 		: in std_logic_vector(31 downto 0);
    instruction		: in std_logic_vector(31 downto 0);
    REGwrite        : in std_logic;
	read_data1,read_data2, imm_gen_out		: out std_logic_vector(31 downto 0);
	reg_dest		: out std_logic_vector(4 downto 0);
	reg_source1		: out std_logic_vector(4 downto 0);	
    reg_source2		: out std_logic_vector(4 downto 0);
	funct7_3		: out std_logic_vector(3 downto 0)
  );
end instruction_decode;


architecture behavior of instruction_decode is

	-- components declaration
 
   component register_file is
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
  end component;
  
  component imm_gen is
    port
    (
      instruction : in std_logic_vector(31 downto 0);
      immediate   : out std_logic_vector(31 downto 0)
    );
  end component;
  
  begin
  
  RegisterFile : register_file
  port map (clk => CLK, resetn => RSTn, read_register_1 => instruction(19 downto 15), read_register_2 => instruction(24 downto 20),
			write_register => write_reg, write_data => write_data, reg_write => REGwrite, read_data_1 => read_data1, read_data_2 => read_data2);

  ImmGen : imm_gen
  port map(instruction => instruction, immediate => imm_gen_out);
  
  reg_dest <= instruction(11 downto 7);
  reg_source1 <= instruction(19 downto 15);
  reg_source2 <= instruction(24 downto 20);
  funct7_3 <= instruction(30) & instruction(14 downto 12);

end behavior;
