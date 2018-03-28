library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity WB_tb is
end WB_tb;

architecture behavior of WB_tb is

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

-- TEST SIGNALS
signal clock : std_logic;
signal stall_in : std_logic;
signal instr_in : std_logic_vector(31 downto 0);
signal MEM_in1 : std_logic_vector(31 downto 0);
signal MEM_in2 : std_logic_vector(31 downto 0);
signal immediate: std_logic_vector(31 downto 0);

-- outputs
signal stall_out : std_logic;
signal reg_to_load : std_logic_vector(4 downto 0);
signal load_to_reg : std_logic_vector(31 downto 0);
signal instr_out : std_logic_vector(31 downto 0);

-- for test purposes

constant clock_period : time := 1 ns;

begin

wb_comp: WB
port map (
	clock => clock,
	stall_in => stall_in,
	instr_in => instr_in,
	MEM_in1 => MEM_in1,
	MEM_in2 => MEM_in2,
	immediate => immediate,
	stall_out => stall_out,
	reg_to_load => reg_to_load,
	load_to_reg => load_to_reg,
	instr_out => instr_out
);

clk_process : process
begin
  clock <= '0';
  wait for clock_period/2;
  clock <= '1';
  wait for clock_period/2;
end process;

test_process: process
begin
	
	-- stall
	stall_in <= '1';
	wait for 1*clock_period;
	stall_in <= '0';
	wait for 1*clock_period;
	
	--LW
	instr_in <= "10001100000000000000000000000000"; -- LW R0, 0(R0)
	MEM_in1 <= "11111100000000000000000000000000";
	wait for 1*clock_period;
	
	
	
end process;

end;