library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity instruction_fetch is
  port
  (
    CLK         			: in std_logic;
    RSTn        			: in std_logic;
	flush       			: in std_logic;
    PCSrc_1     			: in std_logic; -- predicted address
	PCSrc_2     			: in std_logic; -- correction address
    target, next_address  	: in std_logic_vector(31 downto 0);
    enable_pipe 			: in std_logic;
    pc          			: buffer std_logic_vector(31 downto 0);
    HDU_Ctrl     			: in std_logic;
    pc_plus4    			: buffer std_logic_vector(31 downto 0)
  );
end instruction_fetch;


architecture behavior of instruction_fetch is
  -- signals declaration
  signal out_mux_pc_1, out_mux_pc_2, s_pc_plus4 : std_logic_vector(31 downto 0);
  -- components declaration

  component n_bit_unsigned_adder is
    generic
      (n_bit : integer);
    port
    (
      in_a, in_b : in std_logic_vector (n_bit - 1 downto 0);
      sum_out    : out std_logic_vector (n_bit - 1 downto 0));
  end component;

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

-- mux with the predicted target
  Mux_pc_1 : generic_mux2to1 generic
  map (n_bit => 32)
  port map
    (input1 => pc_plus4, input2 => target, sel => PCSrc_1, output => out_mux_pc_1);
	
-- mux with the corrected address
  Mux_pc_2 : generic_mux2to1 generic
  map (n_bit => 32)
  port map
    (input1 => out_mux_pc_1, input2 => next_address, sel => PCSrc_2, output => out_mux_pc_2);
  ID_PIPE : process (clk, RSTn)
  begin
    if (RSTn = '0') then
      pc <= "00000000010000000000000000000000";
    elsif (clk'event and clk = '1') then
      if (enable_pipe = '1') then --sampling
          if (HDU_Ctrl = '0') then -- update pipeline
            pc <= out_mux_pc_2;
          end if;       
      end if;
    end if;
  end process;

  Adder_pc : n_bit_unsigned_adder generic
  map (n_bit => 32)
  port
  map (in_a => pc, in_b => std_logic_vector(to_unsigned(4, 32)), sum_out => s_pc_plus4);
  pc_plus4 <= s_pc_plus4;

end behavior;
