library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity execute is
  port
  (
	ALUSrc1,ALUSrc2			: in std_logic;
	ALUControl		: in std_logic_vector(3 downto 0);
	sel_adder_mux	: in std_logic;
	sel_mux_ALU		: in std_logic_vector(1 downto 0);
	funct_3         : in std_logic;
	read_data2, read_data1, pc, immediate, pc_plus4		: in std_logic_vector(31 downto 0);
	zero, sign 			: out std_logic;
	out_to_pc,out_to_mem					: out std_logic_vector(31 downto 0);
    forward_Src1                                    : in std_logic;
	selection_Src1                                  : in std_logic;
    forward_Src2                                    : in std_logic;
	selection_Src2                                  : in std_logic;
	forward_data_mem                                : in std_logic_vector(31 downto 0);
	forward_data_wb                                 : in std_logic_vector(31 downto 0)
  );
end execute;


architecture behavior of execute is
	-- signals declaration
	signal out_mux_alu1, out_mux_alu2, out_adder_alu, out_mux1, ALU_result : std_logic_vector(31 downto 0);
    signal out_mux_forward1, out_mux_forward2                              : std_logic_vector(31 downto 0);
    signal ALU_input1, ALU_input2                                          : std_logic_vector(31 downto 0);
	signal imm2                                                            : std_logic_vector(31 downto 0);
	signal sel_forward2: std_logic;
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
  
   component n_bit_unsigned_adder is
    generic
      (n_bit : integer);
    port
    (
      in_a, in_b : in std_logic_vector (n_bit - 1 downto 0);
      sum_out    : out std_logic_vector (n_bit - 1 downto 0));
  end component;
  
  component alu_riscv_lite is
    port
    (
      in_a, in_b : in std_logic_vector (31 downto 0);
      op         : in std_logic_vector (3 downto 0);
	  funct_3    : in std_logic;
      zero,sign       : out std_logic;
      result     : out std_logic_vector (31 downto 0));
  end component;
   
  
  begin
  
  Mux_alu_1 : generic_mux2to1 generic map (n_bit => 32)
  port map(input1 => read_data1, input2 => pc, sel => ALUSrc1, output => out_mux_alu1);

  Mux_alu_2 : generic_mux2to1 generic map (n_bit => 32)
  port map(input1 => read_data2, input2 => immediate, sel => ALUSrc2, output => out_mux_alu2);


  --Forwarding input--
  Mux_forward_1 : generic_mux2to1 generic map (n_bit => 32)
  port map(input1 => out_mux_alu1, input2 => out_mux_forward1 , sel => forward_Src1 , output => ALU_input1);

  Mux_selection_1 : generic_mux2to1 generic map (n_bit => 32)
  port map(input1 => forward_data_mem , input2 => forward_data_wb, sel => selection_Src1 , output => out_mux_forward1 );

  sel_forward2<=forward_Src2 and (not ALUSrc2);

  Mux_forward_2 : generic_mux2to1 generic map (n_bit => 32)
  port map(input1 => out_mux_alu2 , input2 =>out_mux_forward2 , sel => sel_forward2 , output => ALU_input2);

  Mux_selection_2 : generic_mux2to1 generic map (n_bit => 32)
  port map(input1 => forward_data_mem , input2 => forward_data_wb , sel => selection_Src2 , output => out_mux_forward2);

  --------------------
  imm2 <= std_logic_vector(shift_left(unsigned(immediate), 1));  

  Adder_alu : n_bit_unsigned_adder generic map (n_bit => 32)
  port map(in_a => pc, in_b => imm2 , sum_out => out_adder_alu);

  ALU : alu_riscv_lite 
  port map(in_a => ALU_input1, in_b => ALU_input2, op => ALUControl,funct_3 => funct_3, zero => zero, sign=>sign ,result => ALU_result);
  
  Mux_after_adder : generic_mux2to1 generic map (n_bit => 32)
  port map(input1 => out_adder_alu, input2 => ALU_result, sel => sel_adder_mux , output => out_to_pc);
  
  Mux1_after_ALU : generic_mux2to1 generic map (n_bit => 32)
  port map(input1 => pc_plus4, input2 => ALU_result, sel => sel_mux_ALU(0), output => out_mux1);
  
  Mux2_after_ALU : generic_mux2to1 generic map (n_bit => 32)
  port map(input1 => out_mux1, input2 => immediate, sel => sel_mux_ALU(1), output => out_to_mem);
  

end behavior;
