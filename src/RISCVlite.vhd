library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RISCVlite is
  port
  (
    CLK          : in std_logic;
    RSTn         : in std_logic;
    mem_rdy_IM : in std_logic;
    mem_rdy_DM : in std_logic;
    valid_IM     : in std_logic;
    valid_DM     : in std_logic;
    proc_req_IM  : out std_logic;
    proc_req_DM  : out std_logic;
    addr_IM      : out std_logic_vector(31 downto 0);
    addr_DM      : out std_logic_vector(31 downto 0);
    we_IM        : out std_logic;
    we_DM        : out std_logic;
    wdata_IM     : out std_logic_vector(31 downto 0);
    wdata_DM     : out std_logic_vector(31 downto 0);
    rdata_IM     : in std_logic_vector(31 downto 0);
    rdata_DM     : in std_logic_vector(31 downto 0)
  );
end RISCVlite;

architecture behavior of RISCVlite is

  -- signals declaration
 signal sPrediction, sCorrection 																					 : std_logic;
signal sNext_address, sTarget: std_logic_vector(31 downto 0); 															   
  signal REGwrite, ALUSrc1, ALUSrc2, MemToReg                                                                            : std_logic;
  signal ALUControl                                                                                                      : std_logic_vector(3 downto 0);
  signal MemWrite, MemRead                                                                                               : std_logic;
  signal sel_mux_ALU, ALUOp                                                                                              : std_logic_vector(1 downto 0);
  signal opcode                                                                                                          : std_logic_vector(6 downto 0);
  signal ALU_result_sign, ALU_result_zero                                                                                : std_logic;
  signal branch_inst,jump_inst,flush                                                                                           : std_logic;
  signal reg_pipe2_ALUOp                                                                                                 : std_logic_vector(1 downto 0);
  signal ff_pipe2_branch_inst,ff_pipe2_jump_inst, ff_pipe2_MemRead, ff_pipe2_MemtoReg                                                       : std_logic;
  signal ff_pipe2_MemWrite, ff_pipe2_ALUSrc1, ff_pipe2_ALUSrc2, ff_pipe2_RegWrite, sel_adder_MUX, ff_pipe2_sel_adder_MUX : std_logic;
  signal reg_pipe2_sel_MUX_ALU                                                                                           : std_logic_vector(1 downto 0);
  signal reg_pipe2_funct7_3, reg_pipe3_funct7_3                                                                          : std_logic_vector(3 downto 0);
  signal ff_pipe3_branch_inst, ff_pipe3_jump_inst, ff_pipe3_MemRead, ff_pipe3_MemtoReg, ff_pipe3_MemWrite                                    : std_logic;
  signal ff_pipe3_RegWrite, ff_pipe4_MemtoReg, ff_pipe4_RegWrite                                                         : std_logic;
  signal done_fetcher, done_LSU, busy_LSU                                                                                : std_logic;
  signal reg_enable_fetcher, reg_enable_LSU, reg_enable                                                                  : std_logic;
  --for Forwarding Unit
  signal rd_mem, rd_wb, rs1_ex, rs2_ex                                                                               : std_logic_vector(4 downto 0);
  signal forward_Src1, selection_Src1, forward_Src2,selection_Src2                                                       : std_logic;
    signal pc_plus4_to_bpu, computed_address																				 : std_logic_vector(31 downto 0);
  --temporaneo, segnali per le memorie                                   
  signal data_in_code_mem, inst_code_mem_out, pc, write_data_mem, out_data_mem, address_data_mem : std_logic_vector(31 downto 0);
  signal ID_EX_RegRd, IF_ID_RegRs1, IF_ID_RegRs2  : std_logic_vector(4 downto 0);
  signal HDU_Ctrl : std_logic;
  -- BPU
  signal ff_pipe_pred, ff_pipe2_pred, ff_pipe3_pred, old_pred: std_logic;
  signal reg_pipe_add, reg_pipe2_add, reg_pipe3_add, old_add : std_logic_vector(6 downto 0);
  
  

  -- components declaration
  component DP_RISCV_lite is
    port
    (
      CLK                              : in std_logic;
      RSTn                             : in std_logic;
	  flush                            : in std_logic;
	  prediction, correction				: in std_logic; -- from Branch Prediction Unit	  	
      REGwrite                         : in std_logic; -- from CU
      ALUSrc1, ALUSrc2                 : in std_logic; -- from CU
      MemToReg                         : in std_logic; --from CU
      ALUControl                       : in std_logic_vector(3 downto 0); -- from CU
      sel_adder_mux                    : in std_logic;
      sel_mux_ALU                      : in std_logic_vector(1 downto 0);
      inst_code_mem_out                : in std_logic_vector(31 downto 0); -- quello che ho letto dalla memoria
      out_data_mem                     : in std_logic_vector(31 downto 0);
      address_data_mem                 : out std_logic_vector(31 downto 0); -- indirizzo nella memoria dato di 32 bit??
      write_data_mem                   : out std_logic_vector(31 downto 0);
      enable_pipe                      : in std_logic;
      REG_PIPE2_INST1                  : out std_logic_vector(3 downto 0); --to ALU_ctrl
      opcode                           : out std_logic_vector(6 downto 0); -- sarebbe funct7_3
      pc                               : buffer std_logic_vector(31 downto 0); --per andare a leggere nella memoria
      ALU_result_sign, ALU_result_zero : out std_logic; -- to CU
      rs1_ex,rs2_ex,rd_mem,rd_wb       : out std_logic_vector(4 downto 0); --Forwarding
      forward_Src1                     : in std_logic;
	  selection_Src1                   : in std_logic;
      forward_Src2                     : in std_logic;
 	  IF_ID_RegRs1 : out std_logic_vector(4 downto 0);
      IF_ID_RegRs2 : out std_logic_vector(4 downto 0);
      ID_EX_RegRd  : out std_logic_vector(4 downto 0);
      HDU_Ctrl     : in std_logic;
	  selection_Src2                   : in std_logic;
	  next_address						: in std_logic_vector(31 downto 0);
	target								: in std_logic_vector(31 downto 0);
	pc_plus4_to_bpu						: out std_logic_vector(31 downto 0);
	computed_address					: out std_logic_vector(31 downto 0)
    );
  end component;

component hazard_detection_unit is
    port
    (
      ID_EX_MemRead : in std_logic;
      ID_EX_RegRd   : in std_logic_vector(4 downto 0);
      IF_ID_RegRs1  : in std_logic_vector(4 downto 0);
      IF_ID_RegRs2  : in std_logic_vector(4 downto 0);
      HDU_Ctrl      : out std_logic
    );
  end component;

  component CU_RISCV_lite is
    port
    (
      opcode           : in std_logic_vector(6 downto 0);
      Branch           : out std_logic;
	  Jump             : out std_logic;
      MemRead          : out std_logic;
      MemtoReg         : out std_logic;
      ALUOp            : out std_logic_vector(1 downto 0);
      MemWrite         : out std_logic;
      ALUSrc1, ALUSrc2 : out std_logic;
      RegWrite         : out std_logic;
      sel_MUX_ALU      : out std_logic_vector(1 downto 0);
      sel_adder_MUX    : out std_logic
    );
  end component;
    
  component Branch_Prediction_Unit is
  port
  (
	clk									: in std_logic;
    resetn 								: in std_logic; 
	reg_enable							: in std_logic;
	address 							: in std_logic_vector(6 downto 0); --k bits from PC
	ALU_result_sign, ALU_result_zero 	: in std_logic;
	jump, branch						: in std_logic; -- from opcode
	computed_address		: in std_logic_vector(31 downto 0); --address computed in the execution stage, if the prediction is wrong it will replace the target
	pc_plus4 							: in std_logic_vector(31 downto 0);
	funct7_3							: in std_logic; -- to distinguish branch_ltu from branch_ge (0x05 from 0x06) we take the last bit of funct7_3 
	old_prediction						: in std_logic;
	old_address							: in std_logic_vector(6 downto 0);
	prediction							: out std_logic; --U/T
	flush								: out std_logic; -- "1" if the prediction is wrong
	target								: out std_logic_vector(31 downto 0);
	next_address						: out std_logic_vector(31 downto 0)
  );
  end component;

  component ALU_Control is
    port
    (
      ALUOp    : in std_logic_vector(1 downto 0);
      funct7_3 : in std_logic_vector(3 downto 0);
      ALU_ctrl : out std_logic_vector(3 downto 0)
    );
  end component;

  component generic_mux2to1 is
    generic
      (n_bit : integer);
    port
    (
      input1 : in std_logic_vector(n_bit - 1 downto 0);
      input2 : in std_logic_vector(n_bit - 1 downto 0);
      sel    : in std_logic;
      output : out std_logic_vector(n_bit - 1 downto 0));
  end component;

  component load_store_unit is
    port
    (
      clk          : in std_logic;
      RSTn         : in std_logic;
      MemRead      : in std_logic;
      MemWrite     : in std_logic;
      proc_req     : out std_logic;
      mem_rdy    : in std_logic;
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
  end component;

  component fetcher is
    port
    (
      clk        : in std_logic;
      RSTn       : in std_logic;
      proc_req   : out std_logic;
      mem_rdy  : in std_logic;
      valid      : in std_logic;
      addr_in    : in std_logic_vector(31 downto 0);
      wdata_in   : in std_logic_vector(31 downto 0);
      rdata_in   : in std_logic_vector(31 downto 0);
      addr_out   : out std_logic_vector(31 downto 0);
      we_out     : out std_logic;
      wdata_out  : out std_logic_vector(31 downto 0);
      rdata_out  : out std_logic_vector(31 downto 0);
      done_LSU   : in std_logic;
	  busy_LSU   : in std_logic;
      done       : out std_logic;
      reg_enable : out std_logic
    );
  end component;

  component forwarding_unit is
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
  end component;

begin

HDU : hazard_detection_unit --  (aggiungere s_HDU_Ctrl + altri segnali se ho problemi)
  port map
  (
    ID_EX_MemRead => ff_pipe2_MemRead,
    ID_EX_RegRd   => ID_EX_RegRd,
    IF_ID_RegRs1  => IF_ID_RegRs1,
    IF_ID_RegRs2  => IF_ID_RegRs2,
    HDU_Ctrl      => HDU_Ctrl
  );

  DP : DP_RISCV_lite
  port map
  (
    CLK => CLK, RSTn => RSTn,flush=>flush , prediction => sPrediction, correction => sCorrection, REGwrite => ff_pipe4_RegWrite, ALUSrc1 => ff_pipe2_ALUSrc1, ALUSrc2 => ff_pipe2_ALUSrc2, MemToReg => ff_pipe4_MemtoReg, ALUControl => ALUControl,
    sel_adder_mux => ff_pipe2_sel_adder_MUX, sel_mux_ALU => reg_pipe2_sel_MUX_ALU, inst_code_mem_out => inst_code_mem_out, out_data_mem => out_data_mem, address_data_mem => address_data_mem, write_data_mem => write_data_mem,
    enable_pipe => reg_enable, next_address => sNext_address, target => sTarget, pc_plus4_to_bpu =>pc_plus4_to_bpu, computed_address => computed_address,REG_PIPE2_INST1 => reg_pipe2_funct7_3, opcode => opcode, ALU_result_sign => ALU_result_sign, pc => pc, ALU_result_zero => ALU_result_zero, rs1_ex=> rs1_ex,rs2_ex=> rs2_ex,rd_mem=> rd_mem,rd_wb=> rd_wb, forward_Src1=>forward_Src1, selection_Src1=> selection_Src1, forward_Src2=>forward_Src2, selection_Src2=>selection_Src2, IF_ID_RegRs1 => IF_ID_RegRs1, IF_ID_RegRs2 => IF_ID_RegRs2, ID_EX_RegRd  => ID_EX_RegRd, HDU_Ctrl => HDU_Ctrl );

	BPU : Branch_Prediction_Unit
	port map
	(
		clk => CLK, resetn => RSTn, reg_enable => reg_enable, address => pc(8 downto 2), ALU_result_sign => ALU_result_sign, ALU_result_zero => ALU_result_zero, 
		jump => ff_pipe3_jump_inst, branch => ff_pipe3_branch_inst, computed_address => computed_address, pc_plus4 => pc_plus4_to_bpu, funct7_3 => reg_pipe3_funct7_3(0),	
		old_prediction => ff_pipe3_pred, old_address => reg_pipe3_add, prediction => sPrediction, flush => flush, target => sTarget, next_address => sNext_address
	);



	sCorrection <= flush;

  CU : CU_RISCV_lite
  port
  map(opcode => opcode, Branch => branch_inst, Jump => jump_inst, MemRead => MemRead, MemtoReg => MemToReg, ALUOp => ALUOp, MemWrite => MemWrite, ALUSrc1 => ALUSrc1, ALUSrc2 => ALUSrc2,
  RegWrite => REGwrite, sel_MUX_ALU => sel_mux_ALU, sel_adder_MUX => sel_adder_mux);

  Fetch_unit : fetcher
  port
  map(CLK => CLK, RSTn => RSTn, proc_req => proc_req_IM, mem_rdy => mem_rdy_IM, valid => valid_IM,
  addr_in => pc, wdata_in => data_in_code_mem, rdata_in => rdata_IM, addr_out => addr_IM, we_out => we_IM, wdata_out => wdata_IM, rdata_out => inst_code_mem_out, busy_LSU=>busy_LSU, done_LSU => done_LSU, done => done_fetcher, reg_enable => reg_enable_fetcher); -- interfaccia con memoria

  LSU : load_store_unit -- interfaccia con memoria
  port
  map(CLK => CLK, RSTn => RSTn, proc_req => proc_req_DM, MemRead => ff_pipe3_MemRead, MemWrite => ff_pipe3_MemWrite, mem_rdy => mem_rdy_DM, valid => valid_DM,
  addr_in => address_data_mem, wdata_in => write_data_mem, rdata_in => rdata_DM, addr_out => addr_DM, we_out => we_DM, wdata_out => wdata_DM, rdata_out => out_data_mem, done_fetcher => done_fetcher,done => done_LSU, busy_LSU=>busy_LSU, reg_enable => reg_enable_LSU);

  ForwUnit : forwarding_unit
  port
  map(RSTn => RSTn, RegWrite_mem=>ff_pipe3_RegWrite, RegWrite_wb=>ff_pipe4_RegWrite,rs1_ex=>rs1_ex, rs2_ex=> rs2_ex, rd_mem=>rd_mem ,rd_wb=>rd_wb, forward_Src1=>forward_Src1,selection_Src1=> selection_Src1,forward_Src2=>forward_Src2, selection_Src2=>selection_Src2);

  reg_enable <= reg_enable_fetcher and reg_enable_LSU;

   -----------------------------------------------------------------------------------------------	IF/ID 

   IF_PIPE : process (clk, RSTn)
  begin
    if (RSTn = '0') then
	  ff_pipe_pred <= '0';
	  reg_pipe_add <= (others => '0');
	  old_add <= (others => '0');
	  old_pred <= '0';
    elsif (clk'event and clk = '1') then
		if (reg_enable = '1') then
		if (flush = '0') then
			reg_pipe_add <= old_add;
			old_add <= pc(8 downto 2);
			ff_pipe_pred <= old_pred;
			old_pred <= sPrediction;
			
			--reg_pipe_add <= pc(8 downto 2);
			--ff_pipe_pred <= sPrediction;
			
		--else
			--ff_pipe_pred <= '0';
			--reg_pipe_add <= (others => '0');
		end if;
	end if;
	end if;
  end process;

  -----------------------------------------------------------------------------------------------	ID/EX
  ID_PIPE : process (clk, RSTn)
  begin
    if (RSTn = '0') then
      ff_pipe2_branch_inst   <= '0';
      ff_pipe2_jump_inst     <= '0';
      ff_pipe2_MemRead       <= '0';
      ff_pipe2_MemtoReg      <= '0';
      reg_pipe2_ALUOp        <= (others => '0');
      ff_pipe2_MemWrite      <= '0';
      ff_pipe2_ALUSrc1       <= '0';
      ff_pipe2_ALUSrc2       <= '0';
      ff_pipe2_RegWrite      <= '0';
      reg_pipe2_sel_MUX_ALU  <= (others => '0');
      ff_pipe2_sel_adder_MUX <= '0';
	  ff_pipe2_pred 		 <= '0';
	  reg_pipe2_add			 <= (others => '0');
	  ff_pipe2_pred 		 <= '0';
	  reg_pipe2_add 		 <= (others => '0');
	  
    elsif (clk'event and clk = '1') then
      if (reg_enable = '1') then
        if (flush = '0') then
		
          if (HDU_Ctrl = '0') then -- update pipeline
            ff_pipe2_MemtoReg      <= MemtoReg;
            reg_pipe2_sel_MUX_ALU  <= sel_MUX_ALU;
            reg_pipe2_ALUOp        <= ALUOp;
            ff_pipe2_jump_inst     <= jump_inst;
            ff_pipe2_branch_inst   <= branch_inst;
            ff_pipe2_MemRead       <= MemRead;
            ff_pipe2_MemWrite      <= MemWrite;
            ff_pipe2_ALUSrc1       <= ALUSrc1;
            ff_pipe2_ALUSrc2       <= ALUSrc2;
            ff_pipe2_RegWrite      <= REGWrite;
            ff_pipe2_sel_adder_MUX <= sel_adder_MUX;
			ff_pipe2_pred 		   <= ff_pipe_pred;
			reg_pipe2_add		   <= reg_pipe_add;
          else -- insert NOP
            ff_pipe2_branch_inst   <= '0';
            ff_pipe2_jump_inst     <= '0';
            ff_pipe2_MemRead       <= '0';
            ff_pipe2_MemtoReg      <= '0';
            reg_pipe2_ALUOp        <= (others => '0');
            ff_pipe2_MemWrite      <= '0';
            ff_pipe2_ALUSrc1       <= '0';
            ff_pipe2_ALUSrc2       <= '0';
            ff_pipe2_RegWrite      <= '0';
            reg_pipe2_sel_MUX_ALU  <= (others => '0');
            ff_pipe2_sel_adder_MUX <= '0';
			ff_pipe2_pred 		 <= '0';
			reg_pipe2_add 		 <= (others => '0');
			end if;
		
 		else -- do flush
          ff_pipe2_branch_inst   <= '0';
          ff_pipe2_jump_inst     <= '0';
          ff_pipe2_MemRead       <= '0';
          ff_pipe2_MemtoReg      <= '0';
          reg_pipe2_ALUOp        <= (others => '0');
          ff_pipe2_MemWrite      <= '0';
          ff_pipe2_ALUSrc1       <= '0';
          ff_pipe2_ALUSrc2       <= '0';
          ff_pipe2_RegWrite      <= '0';
          reg_pipe2_sel_MUX_ALU  <= (others => '0');
          ff_pipe2_sel_adder_MUX <= '0';
		  --ff_pipe2_pred 		 <= '0';
		  --reg_pipe2_add 		 <= (others => '0');
          end if;
       end if;
        end if;
    end process;

  -----------------------------------------------------------------------------------------------	EX/MEM

  EX_PIPE : process (clk, RSTn)
  begin
    if (RSTn = '0') then
	  ff_pipe3_jump_inst <= '0';
      ff_pipe3_branch_inst <= '0';
      ff_pipe3_MemRead     <= '0';
      ff_pipe3_MemtoReg    <= '0';
      ff_pipe3_MemWrite    <= '0';
      ff_pipe3_RegWrite    <= '0';
      reg_pipe3_funct7_3   <= (others => '0');
	  ff_pipe3_pred 		 <= '0';
	  reg_pipe3_add 		 <= (others => '0');
    elsif (clk'event and clk = '1') then
	if (reg_enable = '1') then
      if (flush = '0') then
		
		ff_pipe3_jump_inst   <= ff_pipe2_jump_inst;
        ff_pipe3_branch_inst <= ff_pipe2_branch_inst;
        ff_pipe3_MemRead     <= ff_pipe2_MemRead;
        ff_pipe3_MemtoReg    <= ff_pipe2_MemtoReg;
        ff_pipe3_MemWrite    <= ff_pipe2_MemWrite;
        ff_pipe3_RegWrite    <= ff_pipe2_RegWrite;
        reg_pipe3_funct7_3   <= reg_pipe2_funct7_3;
		ff_pipe3_pred 		   <= ff_pipe2_pred;
		reg_pipe3_add		   <= reg_pipe2_add;
	
else
	  ff_pipe3_jump_inst <= '0';
      ff_pipe3_branch_inst <= '0';
      ff_pipe3_MemRead     <= '0';
      ff_pipe3_MemtoReg    <= '0';
      ff_pipe3_MemWrite    <= '0';
      ff_pipe3_RegWrite    <= '0';
      reg_pipe3_funct7_3   <= (others => '0');
	  --ff_pipe3_pred 		 <= '0';
	  --reg_pipe3_add 		 <= (others => '0');
    end if;
	end if;
	end if;
  end process;

  ------------------------------------------------------------------------------------------------ MEM/WB	

  MEM_PIPE : process (clk, RSTn)
  begin
    if (RSTn = '0') then
      ff_pipe4_MemtoReg <= '0';
      ff_pipe4_RegWrite <= '0';
    elsif (clk'event and clk = '1') then
	--if (flush = '0') then
      if (reg_enable = '1') then
        ff_pipe4_MemtoReg <= ff_pipe3_MemtoReg;
        ff_pipe4_RegWrite <= ff_pipe3_RegWrite;
      end if;
	--else
	--  ff_pipe4_MemtoReg <= '0';
    --  ff_pipe4_RegWrite <= '0';
	--end if;
    end if;
  end process;

  ------------------------------------------------------------------------------------------------

  ALU_Control_inst : ALU_Control
  port
  map(ALUOp => reg_pipe2_ALUOp, funct7_3 => reg_pipe2_funct7_3, ALU_ctrl => ALUControl);

end behavior;
