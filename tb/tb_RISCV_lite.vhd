library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.STD_LOGIC_TEXTIO.all;

library std;
use std.textio.all;

entity tb_RISCV_lite is
end entity tb_RISCV_lite;

architecture behavioral of tb_RISCV_lite is

  signal CLK, RSTn : std_logic;
  type tState is (RST_S, IDLE_S, REQ_ON_S, WAIT_RDY_S, REQ_OFF_S);
  signal sState_IM, sState_DM, start, start_reg                           : tState;
  signal Init, done_init_IM, done_init_DM                                 : std_logic;
  signal sWE_IM_init, sPROC_REQ_IM_init, sMEM_RDY_IM_init, sVALID_IM_init : std_logic;
  signal sADDR_IM_init, sWDATA_IM_init, sRDATA_IM_init                    : std_logic_vector(31 downto 0);
  signal sWE_DM_init, sPROC_REQ_DM_init, sMEM_RDY_DM_init, sVALID_DM_init : std_logic;
  signal sADDR_DM_init, sWDATA_DM_init, sRDATA_DM_init                    : std_logic_vector(31 downto 0);

  constant Ts  : time := 10000 ps;
  constant tco : time := 0 ns;
  constant tpd : time := 0 ns;

  component clk_gen
    port
    (
      CLK  : out std_logic;
      RSTn : out std_logic
    );
  end component;

  component RISCV_SSRAM
    port
    (
      CLK               : in std_logic;
      RSTn              : in std_logic;
      init              : in std_logic;
      sWE_IM_init       : in std_logic;
      sPROC_REQ_IM_init : in std_logic;
      sMEM_RDY_IM_init  : out std_logic;
      sVALID_IM_init    : out std_logic;
      sADDR_IM_init     : in std_logic_vector(31 downto 0);
      sWDATA_IM_init    : in std_logic_vector(31 downto 0);
      sRDATA_IM_init    : out std_logic_vector(31 downto 0);
      sWE_DM_init       : in std_logic;
      sPROC_REQ_DM_init : in std_logic;
      sMEM_RDY_DM_init  : out std_logic;
      sVALID_DM_init    : out std_logic;
      sADDR_DM_init     : in std_logic_vector(31 downto 0);
      sWDATA_DM_init    : in std_logic_vector(31 downto 0);
      sRDATA_DM_init    : out std_logic_vector(31 downto 0)
    );
  end component;

  impure function fInit_offset (
    constant CT : integer)
    return std_logic_vector is
    file fp0_in      : text open READ_MODE is "./text_init.hex";
    file fp1_in      : text open READ_MODE is "./data_init.hex";
    variable line_in : line;
    variable value   : std_logic_vector(31 downto 0) := (others => '0');
  begin -- function fInit_offset
    case CT is
      when 0 =>
        if not endfile(fp0_in) then
          readline(fp0_in, line_in);
          hread(line_in, value);
        end if;
      when 1 =>
        if not endfile(fp1_in) then
          readline(fp1_in, line_in);
          hread(line_in, value);

        end if;
      when others => null;
    end case;
    return value;
  end function fInit_offset;

begin
  CG : clk_gen
  port map
  (
    CLK  => CLK,
    RSTn => RSTn
  );

  RISCV_inst : RISCV_SSRAM
  port
  map (
  CLK               => CLK,
  RSTn              => RSTn,
  init              => init,
  sWE_IM_init       => sWE_IM_init,
  sPROC_REQ_IM_init => sPROC_REQ_IM_init,
  sMEM_RDY_IM_init  => sMEM_RDY_IM_init,
  sVALID_IM_init    => sVALID_IM_init,
  sADDR_IM_init     => sADDR_IM_init,
  sWDATA_IM_init    => sWDATA_IM_init,
  sRDATA_IM_init    => sRDATA_IM_init,
  sWE_DM_init       => sWE_DM_init,
  sPROC_REQ_DM_init => sPROC_REQ_DM_init,
  sMEM_RDY_DM_init  => sMEM_RDY_DM_init,
  sVALID_DM_init    => sVALID_DM_init,
  sADDR_DM_init     => sADDR_DM_init,
  sWDATA_DM_init    => sWDATA_DM_init,
  sRDATA_DM_init    => sRDATA_DM_init
  );

  init <= done_init_DM nand done_init_IM;

  -----------------------------------------------------------------------------
  -- ADDR generation IM
  -----------------------------------------------------------------------------
  process (CLK, RSTn) is
  begin -- process
    if RSTn = '0' then -- asynchronous reset (active low)
      sADDR_IM_init <= fInit_offset(0);
    elsif CLK'event and CLK = '1' then -- rising clock edge
      if (sPROC_REQ_IM_init = '1' and sMEM_RDY_IM_init = '1') then
        sADDR_IM_init <= sADDR_IM_init + conv_std_logic_vector(4, 32) after tco;
      end if;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- ADDR generation DM
  -----------------------------------------------------------------------------
  process (CLK, RSTn) is
  begin -- process
    if RSTn = '0' then -- asynchronous reset (active low)
      sADDR_DM_init <= fInit_offset(1);
    elsif CLK'event and CLK = '1' then -- rising clock edge
      if (sPROC_REQ_DM_init = '1' and sMEM_RDY_DM_init = '1') then
        sADDR_DM_init <= sADDR_DM_init + conv_std_logic_vector(4, 32) after tco;
      end if;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- WE and WDATA generation
  ----------------------------------------------------------------------------_
  sWE_IM_init <= '1';
  sWE_DM_init <= '1';
  -- WDATA IM
  process (CLK, RSTn) is
    file bin_file          : text open READ_MODE is "./main.bin";
    variable line_contents : line;
    variable data_value    : std_logic_vector(31 downto 0);
  begin
    if RSTn'event and RSTn = '0' then -- asynchronous reset (active low)
      done_init_IM <= '0';
      readline(bin_file, line_contents);
      hread(line_contents, data_value);
      -- Write data into instruction memory
      sWDATA_IM_init <= data_value;
    elsif CLK'event and CLK = '1' then
      if (sPROC_REQ_IM_init = '1' and sMEM_RDY_IM_init = '1') then
        if not endfile(bin_file) then
          done_init_IM <= '0';
          readline(bin_file, line_contents);
          hread(line_contents, data_value);
          -- Write data into instruction memory
          sWDATA_IM_init <= data_value;
        else
          done_init_IM <= '1';
        end if;
      end if;
    end if;
  end process;

  -- WDATA DM
  process (CLK, RSTn) is
    file bin_file          : text open READ_MODE is "./data.bin";
    variable line_contents : line;
    variable data_value    : std_logic_vector(31 downto 0);
  begin
    if RSTn'event and RSTn = '0' then -- asynchronous reset (active low)
      done_init_DM <= '0';
      readline(bin_file, line_contents);
      hread(line_contents, data_value);
      -- Write data into data memory
      sWDATA_DM_init <= data_value;
    elsif CLK'event and CLK = '1' then
      if (sPROC_REQ_DM_init = '1' and sMEM_RDY_DM_init = '1') then
        if not endfile(bin_file) then
          done_init_DM <= '0';
          readline(bin_file, line_contents);
          hread(line_contents, data_value);
          -- Write data into instruction memory
          sWDATA_DM_init <= data_value;
        else
          done_init_DM <= '1';
        end if;
      end if;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- PROC_REQ generation for IM initialization
  -----------------------------------------------------------------------------  
  -- FSM_IM
  FSM_state_IM : process (CLK, RSTn) is
  begin -- process
    if RSTn = '0' or done_init_IM = '1' then -- asynchronous reset (active low)
      sState_IM <= RST_S;
    elsif CLK'event and CLK = '1' then -- rising clock edge
      case sState_IM is
        when RST_S =>
          sState_IM <= IDLE_S after tco;
        when IDLE_S =>
          sState_IM <= REQ_ON_S after tco;
        when REQ_ON_S =>
          if (sMEM_RDY_IM_init = '1') then
            sState_IM <= REQ_OFF_S after tco;
          else
            sState_IM <= WAIT_RDY_S after tco;
          end if;
        when WAIT_RDY_S =>
          if (sMEM_RDY_IM_init = '1') then
            sState_IM <= REQ_OFF_S after tco;
          end if;
        when others =>
          sState_IM <= IDLE_S after tco;
      end case;
    end if;
  end process;

  -- FSM output
  FSM_output_IM : process (sState_IM) is
  begin -- process
    case sState_IM is
      when RST_S =>
        sPROC_REQ_IM_init <= '0' after tpd;
      when IDLE_S =>
        sPROC_REQ_IM_init <= '0' after tpd;
      when REQ_ON_S =>
        sPROC_REQ_IM_init <= '1' after tpd;
      when WAIT_RDY_S =>
        sPROC_REQ_IM_init <= '1' after tpd;
      when REQ_OFF_S =>
        sPROC_REQ_IM_init <= '0' after tpd;
      when others =>
        sPROC_REQ_IM_init <= '0' after tpd;
    end case;
  end process;
  -----------------------------------------------------------------------------
  -- PROC_REQ generation for DM initialization
  -----------------------------------------------------------------------------  
  -- FSM_DM
  FSM_state_DM : process (CLK, RSTn) is
  begin -- process
    if RSTn = '0' or done_init_DM = '1' then -- asynchronous reset (active low)
      sState_DM <= RST_S;
    elsif CLK'event and CLK = '1' then -- rising clock edge
      case sState_DM is
        when RST_S =>
          sState_DM <= IDLE_S after tco;
        when IDLE_S =>
          sState_DM <= REQ_ON_S after tco;
        when REQ_ON_S =>
          if (sMEM_RDY_DM_init = '1') then
            sState_DM <= REQ_OFF_S after tco;
          else
            sState_DM <= WAIT_RDY_S after tco;
          end if;
        when WAIT_RDY_S =>
          if (sMEM_RDY_DM_init = '1') then
            sState_DM <= REQ_OFF_S after tco;
          end if;
        when others =>
          sState_DM <= IDLE_S after tco;
      end case;
    end if;
  end process;

  -- FSM output
  FSM_output_DM : process (sState_DM) is
  begin -- process
    case sState_DM is
      when RST_S =>
        sPROC_REQ_DM_init <= '0' after tpd;
      when IDLE_S =>
        sPROC_REQ_DM_init <= '0' after tpd;
      when REQ_ON_S =>
        sPROC_REQ_DM_init <= '1' after tpd;
      when WAIT_RDY_S =>
        sPROC_REQ_DM_init <= '1' after tpd;
      when REQ_OFF_S =>
        sPROC_REQ_DM_init <= '0' after tpd;
      when others =>
        sPROC_REQ_DM_init <= '0' after tpd;
    end case;
  end process;

end architecture behavioral;
