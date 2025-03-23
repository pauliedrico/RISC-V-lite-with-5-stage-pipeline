library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity RISCV_SSRAM is
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
end entity RISCV_SSRAM;

architecture behavioral of RISCV_SSRAM is
  signal done_init_IM, done_init_DM, active, start, start_reg             : std_logic;
  signal sWE_IM, sPROC_REQ_IM, sMEM_RDY_IM, sVALID_IM                     : std_logic;
  signal sADDR_IM, sWDATA_IM, sRDATA_IM                                   : std_logic_vector(31 downto 0);
  signal sWE_IM_op, sPROC_REQ_IM_op, sMEM_RDY_IM_op, sVALID_IM_op         : std_logic;
  signal sADDR_IM_op, sWDATA_IM_op, sRDATA_IM_op                          : std_logic_vector(31 downto 0);
  signal sWE_DM, sPROC_REQ_DM, sMEM_RDY_DM, sVALID_DM                     : std_logic;
  signal sADDR_DM, sWDATA_DM, sRDATA_DM                                   : std_logic_vector(31 downto 0);
  signal sWE_DM_op, sPROC_REQ_DM_op, sMEM_RDY_DM_op, sVALID_DM_op         : std_logic;
  signal sADDR_DM_op, sWDATA_DM_op, sRDATA_DM_op                          : std_logic_vector(31 downto 0);

  component RISCVlite
    port
    (
      CLK         : in std_logic;
      RSTn        : in std_logic;
      MEM_RDY_IM  : in std_logic;
      MEM_RDY_DM  : in std_logic;
      VALID_IM    : in std_logic;
      VALID_DM    : in std_logic;
      PROC_REQ_IM : out std_logic;
      PROC_REQ_DM : out std_logic;
      ADDR_IM     : out std_logic_vector(31 downto 0);
      ADDR_DM     : out std_logic_vector(31 downto 0);
      WE_IM       : out std_logic;
      WE_DM       : out std_logic;
      WDATA_IM    : out std_logic_vector(31 downto 0);
      WDATA_DM    : out std_logic_vector(31 downto 0);
      RDATA_IM    : in std_logic_vector(31 downto 0);
      RDATA_DM    : in std_logic_vector(31 downto 0)
    );
  end component;

  component mem_test
    port
    (
      CLK      : in std_logic;
      RSTn     : in std_logic;
      PROC_REQ : in std_logic;
      MEM_RDY  : out std_logic;
      ADDR     : in std_logic_vector(31 downto 0);
      WE       : in std_logic;
      WDATA    : in std_logic_vector(31 downto 0);
      RDATA    : out std_logic_vector(31 downto 0);
      VALID    : out std_logic
    );
  end component;
begin

  RISCV_inst : RISCVlite
  port map
  (
    CLK         => CLK,
    RSTn        => active,
    MEM_RDY_IM  => sMEM_RDY_IM_op,
    MEM_RDY_DM  => sMEM_RDY_DM_op,
    VALID_IM    => sVALID_IM_op,
    VALID_DM    => sVALID_DM_op,
    PROC_REQ_IM => sPROC_REQ_IM_op,
    PROC_REQ_DM => sPROC_REQ_DM_op,
    ADDR_IM     => sADDR_IM_op,
    ADDR_DM     => sADDR_DM_op,
    WE_IM       => sWE_IM_op,
    WE_DM       => sWE_DM_op,
    WDATA_IM    => sWDATA_IM_op,
    WDATA_DM    => sWDATA_DM_op,
    RDATA_IM    => sRDATA_IM_op,
    RDATA_DM    => sRDATA_DM_op
  );

  mem_inst : mem_test
  port
  map (
  CLK      => CLK,
  RSTn     => RSTn,
  PROC_REQ => sPROC_REQ_IM,
  MEM_RDY  => sMEM_RDY_IM,
  ADDR     => sADDR_IM,
  WE       => sWE_IM,
  WDATA    => sWDATA_IM,
  RDATA    => sRDATA_IM,
  VALID    => sVALID_IM
  );

  mem_data : mem_test
  port
  map (
  CLK      => CLK,
  RSTn     => RSTn,
  PROC_REQ => sPROC_REQ_DM,
  MEM_RDY  => sMEM_RDY_DM,
  ADDR     => sADDR_DM,
  WE       => sWE_DM,
  WDATA    => sWDATA_DM,
  RDATA    => sRDATA_DM,
  VALID    => sVALID_DM
  );

  active <= RSTn and start;

  start_RISCV : process (CLK)
  begin
    if CLK'event and CLK = '1' then -- rising clock edge
      start_reg <= not init;
      start     <= start_reg;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- MUXs initialization IM
  -----------------------------------------------------------------------------
  mux_IM : process (init, sPROC_REQ_IM_op, sWE_IM_op, sADDR_IM_op,
    sWDATA_IM_op, sRDATA_IM, sPROC_REQ_IM_init, sMEM_RDY_IM, sWE_IM_init,
    sVALID_IM, sADDR_IM_init, sWDATA_IM_init)
  begin
    if init = '0' then
      sPROC_REQ_IM   <= sPROC_REQ_IM_op;
      sMEM_RDY_IM_op <= sMEM_RDY_IM;
      sADDR_IM       <= sADDR_IM_op;
      sWE_IM         <= sWE_IM_op;
      sWDATA_IM      <= sWDATA_IM_op;
      sRDATA_IM_op   <= sRDATA_IM;
      sVALID_IM_op   <= sVALID_IM;
    else
      sPROC_REQ_IM     <= sPROC_REQ_IM_init;
      sMEM_RDY_IM_init <= sMEM_RDY_IM;
      sADDR_IM         <= sADDR_IM_init;
      sWE_IM           <= sWE_IM_init;
      sWDATA_IM        <= sWDATA_IM_init;
      sRDATA_IM_init   <= sRDATA_IM;
      sVALID_IM_init   <= sVALID_IM;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- MUXs initialization DM
  -----------------------------------------------------------------------------
  mux_DM : process (init, sPROC_REQ_DM_op, sWE_DM_op, sADDR_DM_op,
    sWDATA_DM_op, sRDATA_DM, sPROC_REQ_DM_init, sMEM_RDY_DM, sWE_DM_init,
    sVALID_DM, sADDR_DM_init, sWDATA_DM_init)
  begin
    if init = '0' then
      sPROC_REQ_DM   <= sPROC_REQ_DM_op;
      sMEM_RDY_DM_op <= sMEM_RDY_DM;
      sADDR_DM       <= sADDR_DM_op;
      sWE_DM         <= sWE_DM_op;
      sWDATA_DM      <= sWDATA_DM_op;
      sRDATA_DM_op   <= sRDATA_DM;
      sVALID_DM_op   <= sVALID_DM;
    else
      sPROC_REQ_DM     <= sPROC_REQ_DM_init;
      sMEM_RDY_DM_init <= sMEM_RDY_DM;
      sADDR_DM         <= sADDR_DM_init;
      sWE_DM           <= sWE_DM_init;
      sWDATA_DM        <= sWDATA_DM_init;
      sRDATA_DM_init   <= sRDATA_DM;
      sVALID_DM_init   <= sVALID_DM;
    end if;
  end process;

end architecture behavioral;
