library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Branch_Prediction_Unit is
  port
  (
	clk									: in std_logic;
    resetn 								: in std_logic; 
	reg_enable							: in std_logic;
	address 							: in std_logic_vector(6 downto 0); --k bits from PC
	ALU_result_sign, ALU_result_zero 	: in std_logic;
	jump, branch						: in std_logic; -- from opcode
	computed_address					: in std_logic_vector(31 downto 0); --address computed in the execution stage, if the prediction is wrong it will replace the target
	pc_plus4 							: in std_logic_vector(31 downto 0);
	funct7_3							: in std_logic; -- to distinguish branch_ltu from branch_ge (0x05 from 0x06) we take the last bit of funct7_3 
	old_prediction						: in std_logic;
	old_address							: in std_logic_vector(6 downto 0);
	prediction							: out std_logic; --U/T
	flush								: out std_logic; -- "1" if the prediction is wrong
	target								: out std_logic_vector(31 downto 0);
	next_address						: out std_logic_vector(31 downto 0)
  );
end;

architecture behavior of Branch_Prediction_Unit is

-- signals declaration 
	signal branch_ltu_cond,branch_ge_cond, branch_cond_result : std_logic_vector(0 downto 0);
	signal wrong_prediction: std_logic; -- '0' if the prediction is correct and no flush is needed
	signal write_data_bpt: std_logic_vector(32 downto 0);
	signal wr, sflush, sPrediction, outcome : std_logic; 

-- components declaration

  component branch_prediction_table is
  port
  (
    resetn         		 				: in std_logic;
	read_address, write_address 		: in std_logic_vector(6 downto 0);
	write_data							: in std_logic_vector(32 downto 0);
	wr									: in std_logic; 
	prediction						    : out std_logic; 
	target				 				: out std_logic_vector(31 downto 0)
  );
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

	BPT: branch_prediction_table
	port map (resetn => resetn, read_address => address, write_address => old_address, write_data =>write_data_bpt, wr => wr, prediction =>sPrediction, target =>target);
	
	
  branch_ltu_cond(0) <= (not ALU_result_zero) and ALU_result_sign;
  branch_ge_cond(0)  <= ALU_result_zero or not(ALU_result_sign);

  Mux_branch : generic_mux2to1 generic
  map (n_bit => 1)
  port
  map(input1 => branch_ltu_cond, input2 => branch_ge_cond, sel => funct7_3, output => branch_cond_result);

  outcome <= (branch_cond_result(0) and branch); -- '1' if branch taken
  wrong_prediction <= outcome xor old_prediction; -- ff_pipe3_pred corresponds to the prediction delayed
  sflush <= wrong_prediction or jump;
  flush <= sflush;
   --
  process(clk)
  begin 
	if(clk'event and clk = '1' and reg_enable = '0') then
		wr <= wrong_prediction and outcome;
		write_data_bpt <= outcome & computed_address;
	end if;
  end process;

  Mux_address : generic_mux2to1 generic map (n_bit => 32)
  port map(input1 => pc_plus4, input2 => computed_address, sel => outcome, output => next_address);
  prediction <= sPrediction;
  
end behavior;
