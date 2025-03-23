library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cu_RISCV_lite is
  port
  (
    opcode   : in std_logic_vector(6 downto 0);
    Branch   : out std_logic;
	Jump     : out std_logic; 
    MemRead  : out std_logic;
    MemtoReg : out std_logic;
    ALUOp    : out std_logic_vector(1 downto 0);
    MemWrite : out std_logic;
    ALUSrc1  : out std_logic;
    ALUSrc2  : out std_logic;
    RegWrite : out std_logic;
    sel_MUX_ALU : out std_logic_vector(1 downto 0);
    sel_adder_MUX : out std_logic
  );
end;

architecture beh of cu_RISCV_lite is
begin
  process (opcode)
  begin
    case opcode is
      when "0110011" => Jump <='0'; Branch <='0'; MemRead <='0';MemtoReg <='0';ALUOp <="10";MemWrite <='0';ALUSrc1 <='0';ALUSrc2 <='0';RegWrite <='1';sel_MUX_ALU <="01";sel_adder_MUX <='0';--add,sub = type R 
      when "1100011" => Jump <='0'; Branch <='1'; MemRead <='0';MemtoReg <='0';ALUOp <="01";MemWrite <='0';ALUSrc1 <='0';ALUSrc2 <='0';RegWrite <='0';sel_MUX_ALU <="01";sel_adder_MUX <='0';--bltu,bge = type B 
      when "1100111" => Jump <='1'; Branch <='0'; MemRead <='0';MemtoReg <='0';ALUOp <="00";MemWrite <='0';ALUSrc1 <='0';ALUSrc2 <='1';RegWrite <='0';sel_MUX_ALU <="00";sel_adder_MUX <='1';--jalr = type I   
      when "0010011" => Jump <='0'; Branch <='0'; MemRead <='0';MemtoReg <='0';ALUOp <="00";MemWrite <='0';ALUSrc1 <='0';ALUSrc2 <='1';RegWrite <='1';sel_MUX_ALU <="01";sel_adder_MUX <='0';--addi = type I 
      when "1101111" => Jump <='1'; Branch <='0'; MemRead <='0';MemtoReg <='0';ALUOp <="10";MemWrite <='0';ALUSrc1 <='1';ALUSrc2 <='1';RegWrite <='1';sel_MUX_ALU <="00";sel_adder_MUX <='0';--jal = type J 
      when "0010111" => Jump <='0'; Branch <='0'; MemRead <='0';MemtoReg <='0';ALUOp <="00";MemWrite <='0';ALUSrc1 <='1';ALUSrc2 <='1';RegWrite <='1';sel_MUX_ALU <="01";sel_adder_MUX <='0';--auipc = type U 
      when "0000011" => Jump <='0'; Branch <='0'; MemRead <='1';MemtoReg <='1';ALUOp <="00";MemWrite <='0';ALUSrc1 <='0';ALUSrc2 <='1';RegWrite <='1';sel_MUX_ALU <="01";sel_adder_MUX <='0';--lw = type I  
      when "0100011" => Jump <='0'; Branch <='0'; MemRead <='0';MemtoReg <='0';ALUOp <="00";MemWrite <='1';ALUSrc1 <='0';ALUSrc2 <='1';RegWrite <='0';sel_MUX_ALU <="01";sel_adder_MUX <='0';--sw = type S  
      when "0110111" => Jump <='0'; Branch <='0'; MemRead <='0';MemtoReg <='0';ALUOp <="00";MemWrite <='0';ALUSrc1 <='0';ALUSrc2 <='0';RegWrite <='1';sel_MUX_ALU <="10";sel_adder_MUX <='1';--lui = type U 
      when others    => Jump <='0'; Branch <='0'; MemRead <='0';MemtoReg <='0';ALUOp <="10";MemWrite <='0';ALUSrc1 <='0';ALUSrc2 <='0';RegWrite <='0';sel_MUX_ALU <="10";sel_adder_MUX <='0';
    end case;
  end process;
end;
