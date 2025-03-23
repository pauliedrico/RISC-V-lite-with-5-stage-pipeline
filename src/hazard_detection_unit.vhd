library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity hazard_detection_unit is
  port
  (
    ID_EX_MemRead : in std_logic;
    ID_EX_RegRd   : in std_logic_vector(4 downto 0);
    IF_ID_RegRs1  : in std_logic_vector(4 downto 0);
    IF_ID_RegRs2  : in std_logic_vector(4 downto 0);
    HDU_Ctrl      : out std_logic -- NOP_mux_sel / IF_ID_Write / PC_Write we can use only one ctrl signal
  );
end hazard_detection_unit;

architecture behavior of hazard_detection_unit is

begin

  process (ID_EX_MemRead,ID_EX_RegRd,IF_ID_RegRs1,IF_ID_RegRs2)
  begin
    if (ID_EX_MemRead = '1') then
      if (ID_EX_RegRd = IF_ID_RegRs1) then
        HDU_Ctrl <= '1';
      elsif (ID_EX_RegRd = IF_ID_RegRs2) then
        HDU_Ctrl <= '1';
      else
        HDU_Ctrl <= '0';
      end if;
    else
      HDU_Ctrl <= '0';
    end if;
  end process;

end behavior;
