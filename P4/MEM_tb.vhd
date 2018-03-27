library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use STD.textio.all;
use ieee.std_logic_textio.all;

entity MEM_tb is
end MEM_tb;

architecture behavior of MEM_tb is

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
	instr : in std_logic_vector(31 downto 0);
	ALU_in1 : in std_logic_vector(31 downto 0);
	ALU_in2 : in std_logic_vector(31 downto 0);
	immediate: in std_logic_vector(31 downto 0);
	
	-- outputs
	stall_out : out std_logic;
	lw_data : out std_logic_vector(31 downto 0);
	
	-- for test pruposes
	i : out integer
);
end component;

--TEST SIGNALS
-- inputs
signal clock : std_logic;
signal stall_in : std_logic;
signal instr : std_logic_vector(31 downto 0);
signal ALU_in1 : std_logic_vector(31 downto 0);
signal ALU_in2 : std_logic_vector(31 downto 0);
signal immediate: std_logic_vector(31 downto 0);

-- outputs
signal stall_out : std_logic;
signal lw_data : std_logic_vector(31 downto 0);
signal i : integer;

constant clock_period : time := 1 ns;

begin

mem_comp: MEM
port map (
	clock => clock,
	stall_in => stall_in,
	instr => instr,
	ALU_in1 => ALU_in1,
	ALU_in2 => ALU_in2,
	immediate => immediate,
	stall_out => stall_out,
	lw_data => lw_data,
	i => i
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
	
	wait for 10*clock_period;
	
	-- stall
	stall_in <= '1';
	wait for 1*clock_period;
	stall_in <= '0';
	wait for 1*clock_period;
	
	--SW
	instr <= "10101100000000000000000000000000"; -- SW R0, 0(R0)
	ALU_in2 <= "00000000000000000000000000000001";
	ALU_in1 <= "11111100000000000000000000000000";
	wait for 1*clock_period;
	
	--LW
	instr <= "10001100000000000000000000000000"; -- LW R0, 0(R0)
	ALU_in1 <= "00000000000000000000000000000000";
	wait for 1*clock_period;
	
	--LW
	instr <= "10001100000000000000000000000000"; -- LW R0, 0(R0)
	ALU_in1 <= "00000000000000000000000000000001";
	wait for 1*clock_period;
	
	--LW
	instr <= "10001100000000000000000000000000"; -- LW R0, 0(R0)
	ALU_in1 <= "00000000000000000000000000000010";
	wait for 1*clock_period;
	
	--LW
	instr <= "10001100000000000000000000000000"; -- LW R0, 0(R0)
	ALU_in1 <= "00000000000000000000000000000011";
	wait for 1*clock_period;
	
end process;

end;