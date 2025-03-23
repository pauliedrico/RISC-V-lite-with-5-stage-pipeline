library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity DP_RISCV_lite is
  port
  (
    CLK               : in std_logic;
    RSTn              : in std_logic;
	Flush             : in std_logic;
	prediction,correction: in std_logic;
    REGwrite          : in std_logic; -- from CU
    ALUSrc1, ALUSrc2  : in std_logic; -- from CU
    MemToReg          : in std_logic; --from CU
    ALUControl        : in std_logic_vector(3 downto 0); -- from CU
    sel_adder_mux     : in std_logic;
    sel_mux_ALU       : in std_logic_vector(1 downto 0);
    inst_code_mem_out : in std_logic_vector(31 downto 0); 
    out_data_mem      : in std_logic_vector(31 downto 0);
    address_data_mem  : out std_logic_vector(31 downto 0);
    write_data_mem    : out std_logic_vector(31 downto 0);
    enable_pipe       : in std_logic;
	next_address						: in std_logic_vector(31 downto 0);
	target								: in std_logic_vector(31 downto 0);
	pc_plus4_to_bpu						: out std_logic_vector(31 downto 0);
	computed_address					: out std_logic_vector(31 downto 0);
	IF_ID_RegRs1 : out std_logic_vector(4 downto 0);
    IF_ID_RegRs2 : out std_logic_vector(4 downto 0);
    ID_EX_RegRd  : out std_logic_vector(4 downto 0);
    HDU_Ctrl     : in std_logic;

    REG_PIPE2_INST1                  : out std_logic_vector(3 downto 0); --to ALU_ctrl
    opcode                           : out std_logic_vector(6 downto 0);
    pc                               : buffer std_logic_vector(31 downto 0);
    ALU_result_sign, ALU_result_zero : out std_logic; -- to BPU
    rs1_ex,rs2_ex,rd_mem,rd_wb       : out std_logic_vector(4 downto 0); -- to Forwarding Unit
    forward_Src1                     : in std_logic;
	selection_Src1                   : in std_logic;
    forward_Src2                     : in std_logic;
	selection_Src2                   : in std_logic
  );
end DP_RISCV_lite;

architecture behavior of DP_RISCV_lite is
  -- signal declaration
  signal pc_plus4, reg_rd_IM_pc, reg_rd_IM_pc_plus4                  : std_logic_vector(31 downto 0);
  signal zero, sign                                                                                            : std_logic;
  signal reg_pipe1_pc, reg_pipe1_inst_mem, reg_pipe1_pc_plus4                                            : std_logic_vector(31 downto 0);
  signal reg_pipe2_pc, reg_pipe2_read_data1, reg_pipe2_read_data2, reg_pipe2_imm_gen, reg_pipe2_pc_plus4 : std_logic_vector(31 downto 0);
  signal funct7_3, reg_pipe2_funct7_3                                                                    : std_logic_vector(3 downto 0);
  signal reg_dest, reg_pipe2_reg_dest, reg_pipe3_reg_dest                                                : std_logic_vector(4 downto 0);
  signal reg_source1,reg_source2                                                                         : std_logic_vector(4 downto 0);
  signal reg_pipe2_source1,reg_pipe2_source2                                                             : std_logic_vector(4 downto 0);
  signal reg_pipe3_adder_alu, reg_pipe3_alu_result, reg_pipe3_read_data2                                 : std_logic_vector(31 downto 0);
  signal reg_pipe4_alu_result, reg_pipe4_data_mem,reg_pipe3_pc_plus4                                     : std_logic_vector(31 downto 0);
  signal reg_pipe4_reg_dest                                                                              : std_logic_vector(4 downto 0);
  signal imm_gen_out, read_data1, read_data2                                                             : std_logic_vector(31 downto 0);
  signal ALU_result, out_adder_alu                                : std_logic_vector(31 downto 0);
  signal out_mux_WB                                                                       : std_logic_vector(31 downto 0);

  --component declaration
  component instruction_fetch is
    port
    (
      CLK         : in std_logic;
      RSTn        : in std_logic;
	  flush       : in std_logic;
      PCSrc_1       : in std_logic; -- predicted address
	  PCSrc_2		: in std_logic;
      target, next_address  : in std_logic_vector(31 downto 0);
      enable_pipe : in std_logic;
      pc          : buffer std_logic_vector(31 downto 0);
      HDU_Ctrl : in std_logic;
      pc_plus4    : buffer std_logic_vector(31 downto 0)
    );
  end component;

  component instruction_decode is
    port
    (
      CLK                                 : in std_logic;
      RSTn                                : in std_logic;
      write_reg                           : in std_logic_vector(4 downto 0);
      write_data                          : in std_logic_vector(31 downto 0);
      instruction                         : in std_logic_vector(31 downto 0);
      REGwrite                            : in std_logic;
      read_data1, read_data2, imm_gen_out : out std_logic_vector(31 downto 0);
	  reg_source1		                  : out std_logic_vector(4 downto 0);	
      reg_source2		                  : out std_logic_vector(4 downto 0);
      reg_dest                            : out std_logic_vector(4 downto 0);
      funct7_3                            : out std_logic_vector(3 downto 0)
    );
  end component;

  component execute is
    port
    (
      ALUSrc1, ALUSrc2                                : in std_logic;
      ALUControl                                      : in std_logic_vector(3 downto 0);
      sel_adder_mux                                   : in std_logic;
      sel_mux_ALU                                     : in std_logic_vector(1 downto 0);
	  funct_3                                         : in std_logic;
      read_data2, read_data1, pc, immediate, pc_plus4 : in std_logic_vector(31 downto 0);
      zero, sign                                      : out std_logic;
      out_to_pc, out_to_mem                           : out std_logic_vector(31 downto 0);
      forward_Src1                                    : in std_logic;
	  selection_Src1                                  : in std_logic;
      forward_Src2                                    : in std_logic;
	  selection_Src2                                  : in std_logic;
	  forward_data_mem                                : in std_logic_vector(31 downto 0);
	  forward_data_wb                                 : in std_logic_vector(31 downto 0)
    );
  end component;

  component write_back is
    port
    (
      Read_data  : in std_logic_vector(31 downto 0);
      ALU_result : in std_logic_vector(31 downto 0);
      MemToReg   : in std_logic;
      out_mux_WB : out std_logic_vector(31 downto 0)
    );
  end component;

begin

  IF_ID_RegRs1 <= reg_source1;
  IF_ID_RegRs2 <= reg_source2;
  ID_EX_RegRd  <= reg_pipe2_reg_dest;
  -- INSTRUCTON FETCH
  -----------------------------------------------------------------------------------
  INST_F : instruction_fetch
  port map
    (CLK => CLK, RSTn => RSTn, flush=>flush, PCSrc_1 => prediction, PCSrc_2 => correction, target => target, next_address => reg_pipe3_adder_alu, enable_pipe=> enable_pipe, pc => pc, pc_plus4 => pc_plus4, HDU_Ctrl => HDU_Ctrl);

  IF_PIPE : process (clk, RSTn)
  begin
    if (RSTn = '0') then
      reg_pipe1_pc       <= (others => '0');
      reg_pipe1_inst_mem <= (others => '0');
      reg_pipe1_pc_plus4 <= (others => '0');
	  reg_rd_IM_pc       <= (others => '0');
      reg_rd_IM_pc_plus4 <= (others => '0');
    elsif (clk'event and clk = '1') then
        if (enable_pipe = '1') then 
	      if (Flush = '0') then--sampling
          if (HDU_Ctrl = '0') then -- update pipeline
            reg_rd_IM_pc       <= pc;
            reg_pipe1_pc       <= reg_rd_IM_pc;
			if(reg_rd_IM_pc = (reg_rd_IM_pc'range => '0')) then 
				reg_pipe1_inst_mem <= (others=>'0');
			else
				reg_pipe1_inst_mem <= inst_code_mem_out;
			end if;
            reg_rd_IM_pc_plus4 <= pc_plus4;
            reg_pipe1_pc_plus4 <= reg_rd_IM_pc_plus4;
          end if;
     	 else -- pipe flush
    	    reg_pipe1_pc       <= (others => '0');
  	      	reg_pipe1_inst_mem <= (others => '0');
    	    reg_pipe1_pc_plus4 <= (others => '0');
            reg_rd_IM_pc       <= (others => '0');
            reg_rd_IM_pc_plus4 <= (others => '0');
      		end if;
		end if;	
    end if;
  end process;

  -- INSTRUCTION DECODE
  ------------------------------------------------------------------------------------------
  opcode <= reg_pipe1_inst_mem(6 downto 0);
  REG_PIPE2_INST1 <= reg_pipe2_funct7_3; 

  ID : instruction_decode
  port
  map(CLK => CLK, RSTn => RSTn, write_reg => reg_pipe4_reg_dest, write_data => out_mux_WB, instruction => reg_pipe1_inst_mem, REGwrite => REGwrite,
  read_data1 => read_data1, read_data2 => read_data2, imm_gen_out => imm_gen_out, reg_dest => reg_dest, reg_source1=>reg_source1, reg_source2=>reg_source2,funct7_3 => funct7_3);

  ID_PIPE : process (clk, RSTn)
  begin
    if (RSTn = '0') then
      reg_pipe2_pc         <= (others => '0');
      reg_pipe2_read_data1 <= (others => '0');
      reg_pipe2_read_data2 <= (others => '0');
      reg_pipe2_imm_gen    <= (others => '0');
	  reg_pipe2_funct7_3   <= (others => '0'); 
      reg_pipe2_reg_dest   <= (others => '0');
      reg_pipe2_pc_plus4   <= (others => '0');
	  reg_pipe2_source1    <= (others => '0');
	  reg_pipe2_source2    <= (others => '0');
    elsif (clk'event and clk = '1') then
		if (enable_pipe = '1') then 
			if (Flush = '0') then --sampling
				reg_pipe2_pc         <= reg_pipe1_pc;
				reg_pipe2_read_data1 <= read_data1;
				reg_pipe2_read_data2 <= read_data2;
				reg_pipe2_imm_gen    <= imm_gen_out;
				reg_pipe2_funct7_3   <= funct7_3;
				reg_pipe2_reg_dest   <= reg_dest;
				reg_pipe2_pc_plus4   <= reg_pipe1_pc_plus4;
				reg_pipe2_source1    <= reg_source1;
	  	        reg_pipe2_source2    <= reg_source2;
			else 									-- flush pipe
				reg_pipe2_pc         <= (others => '0');
				reg_pipe2_read_data1 <= (others => '0');
				reg_pipe2_read_data2 <= (others => '0');
				reg_pipe2_imm_gen    <= (others => '0');
	            reg_pipe2_funct7_3   <= (others => '0'); 
				reg_pipe2_reg_dest   <= (others => '0');
				reg_pipe2_pc_plus4   <= (others => '0');
		  	    reg_pipe2_source1    <= (others => '0');
			    reg_pipe2_source2    <= (others => '0');
			end if;
		end if;
	end if;
  end process;
  -- 	EXECUTE
  ------------------------------------------------------------------------------------------
  rs1_ex<=reg_pipe2_source1;
  rs2_ex<=reg_pipe2_source2; 

  EX : execute
  port
  map(ALUSrc1 => ALUSrc1, ALUSrc2 => ALUSrc2, ALUControl => ALUControl, sel_adder_mux => sel_adder_mux, sel_mux_ALU => sel_mux_ALU,funct_3=>reg_pipe2_funct7_3(0), read_data2 => reg_pipe2_read_data2, read_data1 => reg_pipe2_read_data1, pc => reg_pipe2_pc,
  immediate => reg_pipe2_imm_gen, pc_plus4 => reg_pipe2_pc_plus4, zero => zero, sign => sign, out_to_pc => out_adder_alu, out_to_mem => ALU_result,forward_Src1 =>forward_Src1 ,selection_Src1=>selection_Src1,forward_Src2=>forward_Src2 ,selection_Src2=>selection_Src2, forward_data_mem=>reg_pipe3_alu_result, forward_data_wb=>out_mux_WB);

  EX_PIPE : process (clk, RSTn)
  begin
    if (RSTn = '0') then
      ALU_result_zero      <= '0';
	  ALU_result_sign     <='0';
      reg_pipe3_adder_alu  <= (others => '0');
      reg_pipe3_alu_result <= (others => '0');
      reg_pipe3_read_data2 <= (others => '0');
	  reg_pipe3_pc_plus4   <= (others => '0'); 
      reg_pipe3_reg_dest   <= (others => '0');
    elsif (clk'event and clk = '1') then
		if (enable_pipe = '1') then 
			if (Flush = '0') then --sampling
				ALU_result_zero      <= zero;
                ALU_result_sign      <= sign;
				reg_pipe3_adder_alu  <= out_adder_alu;
				reg_pipe3_alu_result <= ALU_result;
				reg_pipe3_read_data2 <= reg_pipe2_read_data2;
				reg_pipe3_reg_dest   <= reg_pipe2_reg_dest;
				reg_pipe3_pc_plus4	 <= reg_pipe2_pc_plus4;						  
			else 										-- pipe flush
			ALU_result_zero      <= '0';
	        ALU_result_sign     <='0';
			reg_pipe3_adder_alu  <= (others => '0');
			reg_pipe3_alu_result <= (others => '0');
			reg_pipe3_read_data2 <= (others => '0');
			reg_pipe3_pc_plus4   <= (others => '0'); 							   
			reg_pipe3_reg_dest   <= (others => '0');
			end if;
		end if;
	end if;
  end process;
  pc_plus4_to_bpu <= reg_pipe3_pc_plus4;
 computed_address <= reg_pipe3_adder_alu;

  -- MEMORY
  ------------------------------------------------------------------------------------------
  address_data_mem <= reg_pipe3_alu_result;
  write_data_mem   <= reg_pipe3_read_data2;
  rd_mem<=reg_pipe3_reg_dest;

  MEM_PIPE : process (clk, RSTn)
  begin
    if (RSTn = '0') then
      reg_pipe4_data_mem   <= (others => '0');
      reg_pipe4_alu_result <= (others => '0');
      reg_pipe4_reg_dest      <= (others => '0');
    elsif (clk'event and clk = '1') then	
			if (enable_pipe = '1') then 		--sampling
				reg_pipe4_data_mem   <= out_data_mem;
				reg_pipe4_alu_result <= reg_pipe3_alu_result;
				reg_pipe4_reg_dest      <= reg_pipe3_reg_dest;
			end if;
	end if;
  end process;

  -- WRITE BACK
  ------------------------------------------------------------------------------------------
  rd_wb<=reg_pipe4_reg_dest;

  WB : write_back
  port
  map(Read_data => reg_pipe4_data_mem, ALU_result =>reg_pipe4_alu_result , MemToReg => MemToReg, out_mux_WB => out_mux_WB);

end behavior;
