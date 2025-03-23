library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity load_store_unit is
  port
  (
    clk          : in std_logic;
    RSTn         : in std_logic;
    MemRead      : in std_logic;
    MemWrite     : in std_logic;
    proc_req     : out std_logic;
    mem_rdy      : in std_logic;
    valid        : in std_logic;
    addr_in      : in std_logic_vector(31 downto 0);
    wdata_in     : in std_logic_vector(31 downto 0);
    rdata_in     : in std_logic_vector(31 downto 0);
    addr_out     : out std_logic_vector(31 downto 0);
    we_out       : out std_logic;
    wdata_out    : out std_logic_vector(31 downto 0);
    rdata_out    : out std_logic_vector(31 downto 0);
    done_fetcher : in std_logic;
    done         : out std_logic;
    busy_LSU     : out std_logic;
    reg_enable   : buffer std_logic
  );
end;

architecture beh of load_store_unit is
  type tState is (IDLE_S, REQ_ON_S, WAIT_RDY_S, REQ_OFF_S, WAIT_FETCH, UPDATE_IN);
  signal sState    : tState;
  signal sProc_req : std_logic;

begin
  --Sampling registers
  process (CLK, RSTn) is
  begin -- process
    if RSTn = '0' then -- asynchronous reset (active low)
      addr_out  <= (others => '0');
      wdata_out <= (others => '0');
      rdata_out <= (others => '0');
      we_out    <= '0';
    elsif CLK'event and CLK = '1' then -- rising clock edge
      if (reg_enable = '1') then
        addr_out  <= addr_in;
        wdata_out <= wdata_in;
        we_out    <= MemWrite and (not MemRead);
      end if;
      if (valid = '1') then
        rdata_out <= rdata_in;
      end if;
    end if;
  end process;

  -- FSM
  process (CLK, RSTn) is
  begin -- process
    if RSTn = '0' then -- asynchronous reset (active low)
      sState <= IDLE_S;
    elsif CLK'event and CLK = '1' then -- rising clock edge
      case sState is
        when IDLE_S =>
          if (MemRead = '1' or MemWrite = '1') then
            sState <= REQ_ON_S;
          end if;
        when REQ_ON_S =>
          if (mem_rdy = '1') then
            sState <= REQ_OFF_S;
          else
            sState <= WAIT_RDY_S;
          end if;
        when WAIT_RDY_S =>
          if (mem_rdy = '1') then
            sState <= REQ_OFF_S;
          end if;
        when REQ_OFF_S =>
          if (valid = '1') then
            sState <= WAIT_FETCH;
          end if;
        when WAIT_FETCH =>
          if (done_fetcher = '1') then
            sState <= UPDATE_IN;
          end if;
        when UPDATE_IN =>
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
        sProc_req  <= '0';
        reg_enable <= '1';
        done       <= '1';
        busy_LSU   <= '0';
      when REQ_ON_S =>
        sProc_req  <= '1';
        reg_enable <= '0';
        done       <= '0';
        busy_LSU   <= '1';
      when WAIT_RDY_S =>
        sProc_req  <= '1';
        reg_enable <= '0';
        done       <= '0';
        busy_LSU   <= '1';
      when REQ_OFF_S =>
        sProc_req  <= '0';
        reg_enable <= '0';
        done       <= '0';
        busy_LSU   <= '1';
      when WAIT_FETCH =>
        sProc_req  <= '0';
        reg_enable <= '0';
        done       <= '1';
        busy_LSU   <= '1';
      when UPDATE_IN =>
        sProc_req  <= '0';
        reg_enable <= '1';
        done       <= '1';
        busy_LSU   <= '1';
      when others =>
        sProc_req  <= '0';
        reg_enable <= '1';
        done       <= '1';
        busy_LSU   <= '0';
    end case;
  end process;

  proc_req <= sProc_req;
end;