library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu_riscv_lite is
  port
  (
    in_a, in_b : in std_logic_vector (31 downto 0);
    op         : in std_logic_vector (3 downto 0);
	funct_3	   : in std_logic;
    zero,sign       : out std_logic;
    result     : out std_logic_vector (31 downto 0));
end alu_riscv_lite;

architecture behavior of alu_riscv_lite is
signal s_result : signed (31 downto 0); --32 bit
	begin
		process (op, in_a, in_b)
		begin
		case op is
		when "0010" => s_result <=(signed(in_a) + signed(in_b)); 
		when others => s_result <=(signed(in_a) - signed(in_b)); -- op = 0110
		end case;
	end process;
	result<= std_logic_vector(s_result(31 downto 0));
	process(s_result,funct_3)
	begin
		if(std_logic_vector(s_result) = "00000000000000000000000000000000") then
			zero<='1';
		else
			zero<='0';
		end if;
		
		if(funct_3 = '0') then
			if(unsigned(in_a) < unsigned(in_b)) then
			sign<='1';
			else
			sign<='0';
			end if;
		else
			sign<=s_result(31);
		end if;
	end process;
end behavior;
