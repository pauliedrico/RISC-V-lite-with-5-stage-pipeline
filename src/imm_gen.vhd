library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity imm_gen is
  port
  (
    instruction : in std_logic_vector(31 downto 0);
    immediate   : out std_logic_vector(31 downto 0)
  );
end;

architecture beh of imm_gen is
  signal opcode : std_logic_vector(6 downto 0);
begin
  opcode <= instruction(6 downto 0);
  process (instruction,opcode)
  begin
    case opcode is
      when "0110011" => immediate <= (others => '0');--add,sub = type R
      when "1100011" =>
        case instruction(14 downto 12) is
          when "110" => immediate  <= (31 downto 12 => '0') & instruction(31) & instruction(7) & instruction(30 downto 25) & instruction(11 downto 8); --bltu = type B
          when others => immediate <= (31 downto 12 => instruction (31)) & instruction(31) & instruction(7) & instruction(30 downto 25) & instruction(11 downto 8); --bge = type B
        end case;
      when "1100111" => immediate <= (31 downto 12 => instruction (31)) & instruction(31 downto 20);--jalr = type I
      when "0010011" => immediate <= (31 downto 12 => instruction (31)) & instruction(31 downto 20);--addi = type I
      when "1101111" => immediate <= (31 downto 20 => instruction (31)) & instruction(31) & instruction(19 downto 12) & instruction(20) & instruction(30 downto 21);--jal = type J
      when "0010111" => immediate <= instruction(31 downto 12) & (11 downto 0 => '0');--auipc = type U
      when "0000011" => immediate <= (31 downto 12 => instruction (31)) & instruction(31 downto 20);--lw = type I
      when "0100011" => immediate <= (31 downto 12 => instruction (31)) & instruction(31 downto 25) & instruction(11 downto 7);--sw = type S
      when "0110111" => immediate <= instruction(31 downto 12) & (11 downto 0 => '0');--lui = type U
      when others => immediate    <= (others => '0');
    end case;
  end process;
end;