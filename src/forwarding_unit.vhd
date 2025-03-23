library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity forwarding_unit is
  port
  (
    RSTn           : in std_logic;
    RegWrite_mem   : in std_logic;
    RegWrite_wb    : in std_logic;
    rs1_ex         : in std_logic_vector(4 downto 0);
    rs2_ex         : in std_logic_vector(4 downto 0);
    rd_mem         : in std_logic_vector(4 downto 0);
    rd_wb          : in std_logic_vector(4 downto 0);
    forward_Src1   : out std_logic;
    selection_Src1 : out std_logic;
    forward_Src2   : out std_logic;
    selection_Src2 : out std_logic
  );
end;

architecture beh of forwarding_unit is
  
begin
  process (RSTn, RegWrite_mem, RegWrite_wb, rs1_ex, rs2_ex, rd_mem, rd_wb) is
	variable v_forward_Src1, v_forward_Src2, v_selection_Src1, v_selection_Src2 : std_logic;
  begin
    v_forward_Src1   := '0';
    v_forward_Src2   := '0';
    v_selection_Src1 := '0';
    v_selection_Src2 := '0';
    if (RSTn = '0') then
      forward_Src1   <= '0';
      forward_Src2   <= '0';
      selection_Src1 <= '0';
      selection_Src2 <= '0';
    else
      if (rd_mem = rs1_ex or rd_wb = rs1_ex) then
        
          if (RegWrite_wb = '1' and not (rd_wb = (rd_wb'range => '0'))) then
            if rd_wb = rs1_ex then
              v_forward_Src1   := '1';
              v_selection_Src1 := '1';
            end if;
          end if;
        if (RegWrite_mem = '1' and not (rd_mem = (rd_mem'range => '0'))) then
          if (rd_mem = rs1_ex) then
            v_forward_Src1   := '1';
            v_selection_Src1 := '0';
          end if;
        end if;
      end if;
      if (rd_mem = rs2_ex or rd_wb = rs2_ex) then
        
          if (RegWrite_wb = '1' and not (rd_wb = (rd_wb'range => '0'))) then
            if (rd_wb = rs2_ex) then
              v_forward_Src2   := '1';
              v_selection_Src2 := '1';
            end if;
          end if;
		if (RegWrite_mem = '1' and not (rd_mem = (rd_mem'range => '0'))) then
          if (rd_mem = rs2_ex) then
            v_forward_Src2   := '1';
            v_selection_Src2 := '0';
          end if;
        end if;

        end if;
        forward_Src1   <= v_forward_Src1;
        forward_Src2   <= v_forward_Src2;
        selection_Src1 <= v_selection_Src1;
        selection_Src2 <= v_selection_Src2;
      
    end if;

  end process;

end beh;
