library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity mem_test is
  port
  (
    CLK       : in std_logic;
    RSTn      : in std_logic;
    PROC_REQ  : in std_logic;
    MEM_RDY : out std_logic;
    ADDR      : in std_logic_vector(31 downto 0);
    WE        : in std_logic;
    WDATA     : in std_logic_vector(31 downto 0);
    RDATA     : out std_logic_vector(31 downto 0);
    VALID     : out std_logic
  );
end mem_test;

architecture beh of mem_test is

  --constant tco : time := 1 ns;
  --constant tpd : time := 1 ns;

  -- constant cLAST_ADX : std_logic_vector(10 downto 0) := (others => '1');

  component sram_32_1024_freepdk45 is
    port
    (
      clk0  : in std_logic;
      csb0  : in std_logic;
      web0  : in std_logic;
      addr0 : in std_logic_vector(9 downto 0);
      din0  : in std_logic_vector(31 downto 0);
      dout0 : out std_logic_vector(31 downto 0));
  end component;

  type tState is (IDLE_S, REQ_S, RESULT_S);
  signal sState : tState;
  signal CSn,we_reg,VALID_reg   : std_logic;
  signal addr_reg, wdata_reg,rdata_reg: std_logic_vector(31 downto 0);


begin -- architecture beh

  process (CLK, RSTn) is
  begin -- process
    if RSTn = '0' then -- asynchronous reset (active low)
      addr_reg  <= (others => '0');
      wdata_reg <= (others => '0');
      we_reg    <= '0';
    elsif CLK'event and CLK = '1' then -- rising clock edge
      addr_reg  <= ADDR;
      wdata_reg <= WDATA;
      we_reg    <= not(WE);
      RDATA     <= rdata_reg;
	  VALID     <= valid_reg;
    end if;
  end process;
  

  MEM : sram_32_1024_freepdk45
  port map
    (clk0 => CLK, csb0 => CSn, web0 => we_reg, addr0=> addr_reg(9 downto 0),din0=> wdata_reg, dout0=> rdata_reg);
  -- FSM
  process (CLK, RSTn) is
  begin -- process
    if RSTn = '0' then -- asynchronous reset (active low)
      sState <= IDLE_S;
    elsif CLK'event and CLK = '1' then -- rising clock edge
      case sState is
        when IDLE_S =>
          if (proc_req = '1') then
            sState <= REQ_S;
          end if;
        when REQ_S =>
          sState <= RESULT_S;
        when RESULT_S =>
          sState <= IDLE_S;
        when others =>
          sState <= IDLE_S;
      end case;
    end if;
  end process;


  -- FSM output
  process (sState) is
  begin -- process
    case sState is
      when IDLE_S =>
        MEM_RDY <= '1';
        VALID_reg     <= '0';
        CSn       <= '1';
      when REQ_S =>
        MEM_RDY <= '0';
        VALID_reg     <= '0';
        CSn       <= '0';
      when RESULT_S =>
        MEM_RDY <= '1';
        VALID_reg     <= '1';
        CSn       <= '1';
      when others =>
        MEM_RDY <= '1';
        VALID_reg     <= '0';
        CSn       <= '1';
    end case;
  end process;

end beh;
