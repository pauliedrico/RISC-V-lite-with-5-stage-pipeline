library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ALU_Control is
  port
  (
	ALUOp      : in std_logic_vector(1 downto 0);
	funct7_3   : in std_logic_vector(3 downto 0);
	ALU_ctrl   : out std_logic_vector(3 downto 0)
  );
end ALU_Control;

architecture behavior of ALU_Control is

begin
	process (ALUop,funct7_3)
	begin
	case ALUOp is
		when "00" => ALU_ctrl <= "0010";
		when "01" => ALU_ctrl <= "0110";
		when "10" => 
			if(funct7_3(3)='0') then
				ALU_ctrl <= "0010";
			else
				ALU_ctrl <= "0110";
			end if;		
		when others => ALU_ctrl <= "0110";
	end case;
	end process;

end behavior;
