library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use STD.textio.all;
use ieee.std_logic_textio.all;

entity processor is
  port(
    clock : in std_logic;
	  next_address_t : out std_logic_vector (31 downto 0);
	  IR_t : out std_logic_vector (31 downto 0);
	  rs_t : OUT std_logic_vector(31 DOWNTO 0);
		rt_t : OUT std_logic_vector(31 DOWNTO 0)
);
end processor;

architecture behavior of processor is

-- IF stage
component fetch is
  generic(
    ram_size : INTEGER := 1024
  );
  port(
    clock : in std_logic;

	  branch_address : in std_logic_vector (31 downto 0);
	  branch_taken : in std_logic;
	
	  next_address : out std_logic_vector (31 downto 0);
	  IR : out std_logic_vector (31 downto 0)
);
end component;

-- ID stage
component ID IS
	GENERIC (
		register_size : INTEGER := 32
	);
	PORT (
		clk : IN std_logic;
		bran_taken_in : IN std_logic; -- from mem
		IR_addr : IN std_logic_vector(31 DOWNTO 0);
		IR : IN std_logic_vector(31 DOWNTO 0);
		writeback_register_address : IN std_Logic_vector(4 DOWNTO 0);
		writeback_register_content : IN std_logic_vector(31 DOWNTO 0);
		ex_state_buffer : IN std_logic_vector(10 DOWNTO 0);

		IR_addr_out : OUT std_logic_vector(31 DOWNTO 0);
		jump_addr : OUT std_logic_vector(25 DOWNTO 0);
		rs : OUT std_logic_vector(31 DOWNTO 0);
		rt : OUT std_logic_vector(31 DOWNTO 0);
		des_addr : OUT std_logic_vector(4 DOWNTO 0);
		signExtImm : OUT std_logic_vector(31 DOWNTO 0);
		insert_stall : OUT std_logic;
		EX_control_buffer : OUT std_logic_vector(10 DOWNTO 0); -- for ex stage provide information for forward and harzard detect, first bit for mem_read, 9-5 for rt, 4-0 for rs
		MEM_control_buffer : OUT std_logic_vector(5 DOWNTO 0); -- for mem stage, provide info for forward and hazard detect, first bit for wb_signal, 4-0 for des_adr
		WB_control_buffer : OUT std_logic_vector(5 DOWNTO 0); -- for wb stage, provide info for forward and hazard detect, first bit for wb_signal, 4-0 for des_adr
		funct : OUT std_logic_vector(5 DOWNTO 0);
		opcode : OUT std_logic_vector(5 DOWNTO 0);
		write_enable : IN std_logic := '0' -- indicate program ends
	);
END component;

-- EX stage
	-- TODO

-- MEM stage
component MEM is
generic(
	clock_period : time := 1ns;
	ram_size : integer := 8192;
	reg_size : integer := 32
);
port(
	-- inputs
	clock : in std_logic;
	stall_in : in std_logic;
	instr_in : in std_logic_vector(31 downto 0);
	ALU_in1 : in std_logic_vector(31 downto 0);
	ALU_in2 : in std_logic_vector(31 downto 0);
	immediate: in std_logic_vector(31 downto 0);
	write_to_txt: in integer;
	
	-- outputs
	stall_out : out std_logic;
	MEM_out1 : out std_logic_vector(31 downto 0);
	MEM_out2 : out std_logic_vector(31 downto 0);
	instr_out : out std_logic_vector(31 downto 0);
	
	-- for test purposes
	i : out integer
);
end component;

-- WB stage
component WB is
generic(
	clock_period : time := 1ns;
	ram_size : integer := 8192;
	reg_size : integer := 32
);
port(
	-- inputs
	clock : in std_logic;
	stall_in : in std_logic;
	instr_in : in std_logic_vector(31 downto 0);
	MEM_in1 : in std_logic_vector(31 downto 0);
	MEM_in2 : in std_logic_vector(31 downto 0);
	immediate: in std_logic_vector(31 downto 0);
	
	-- outputs
	stall_out : out std_logic;
	reg_to_load : out std_logic_vector(4 downto 0);
	load_to_reg : out std_logic_vector(31 downto 0);
	instr_out : out std_logic_vector(31 downto 0)
	
	-- for test purposes
	
);
end component;

-- Signals
constant clock_period : time := 1 ns;

	-- IF Stage
signal next_address : std_logic_vector (31 downto 0);
signal branch_address : std_logic_vector (31 downto 0);
signal branch_taken : std_logic;

	-- ID Stage
signal clk : std_logic;
signal bran_taken_in : std_logic := '0'; -- from mem
signal IR_addr : std_logic_vector(31 DOWNTO 0);
signal IR : std_logic_vector(31 DOWNTO 0);
signal writeback_register_address : std_Logic_vector(4 DOWNTO 0);
signal writeback_register_content : std_logic_vector(31 DOWNTO 0);
signal ex_state_buffer : std_logic_vector(10 DOWNTO 0);
signal IR_addr_out : std_logic_vector(31 DOWNTO 0);
signal jump_addr : std_logic_vector(25 DOWNTO 0);
signal rs : std_logic_vector(31 DOWNTO 0);
signal rt : std_logic_vector(31 DOWNTO 0);
signal des_addr : std_logic_vector(4 DOWNTO 0);
signal signExtImm : std_logic_vector(31 DOWNTO 0);
signal insert_stall : std_logic;
signal EX_control_buffer : std_logic_vector(10 DOWNTO 0);
signal MEM_control_buffer : std_logic_vector(5 DOWNTO 0);
signal WB_control_buffer : std_logic_vector(5 DOWNTO 0);
signal funct : std_logic_vector(5 DOWNTO 0);
signal opcode : std_logic_vector(5 DOWNTO 0);
signal write_enable : std_logic := '0';

	-- MEM Stage
signal clock_mem : std_logic;
signal stall_in_mem : std_logic;
signal instr_in_mem : std_logic_vector(31 downto 0);
signal ALU_in1 : std_logic_vector(31 downto 0);
signal ALU_in2 : std_logic_vector(31 downto 0);
signal immediate_mem: std_logic_vector(31 downto 0);
signal write_to_txt: integer;
signal stall_out_mem : std_logic;
signal MEM_out1 : std_logic_vector(31 downto 0);
signal MEM_out2 : std_logic_vector(31 downto 0);
signal instr_out_mem : std_logic_vector(31 downto 0);

	-- WB Stage
signal clock_wb : std_logic;
signal stall_in_wb : std_logic;
signal MEM_in1 : std_logic_vector(31 downto 0);
signal MEM_in2 : std_logic_vector(31 downto 0);
signal immediate_wb: std_logic_vector(31 downto 0);
signal stall_out_wb : std_logic;
signal reg_to_load : std_logic_vector(4 downto 0);
signal load_to_reg : std_logic_vector(31 downto 0);
signal instr_out_wb : std_logic_vector(31 downto 0);

begin

	-- IF/ID
IF_ID: fetch
port map(
  clock => clock,
	branch_address => branch_address,
	branch_taken => bran_taken_in,
	next_address => next_address,
	IR => IR
);


	-- ID/EX
ID_EX: ID
port map(
	clk => clock,
	bran_taken_in => bran_taken_in,
	IR_addr => next_address,
	IR => IR,
	writeback_register_address => writeback_register_address,
	writeback_register_content => writeback_register_content,
	ex_state_buffer => ex_state_buffer,

	IR_addr_out => IR_addr_out,
	jump_addr => jump_addr,
	rs => rs,
	rt => rt,
	des_addr => des_addr,
	signExtImm => signExtImm,
	insert_stall => insert_stall,
	EX_control_buffer => EX_control_buffer,
	MEM_control_buffer => MEM_control_buffer,
	WB_control_buffer => WB_control_buffer,
	funct => funct,
	opcode => opcode,
	write_enable => write_enable
);
	-- EX/MEM
	
	-- MEM/WB
mem_wb: WB
port map(
	clock => clock,
	stall_in => stall_out_mem,
	instr_in => instr_out_mem,
	MEM_in1 => MEM_out1,
	MEM_in2 => MEM_out2,
	immediate => immediate_mem,
	stall_out => stall_out_wb,
	reg_to_load => reg_to_load,
	load_to_reg => load_to_reg,
	instr_out => instr_out_wb
);
	-- WB/ID
	
	
	next_address_t <= next_address;
	IR_t <= IR;
	rs_t <= rs;
	rt_t <= rt;
 
end;