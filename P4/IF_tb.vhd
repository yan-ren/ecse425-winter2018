--ECSE 425 Lab 3 Cache Testbench
--Tara Tabet	260625552
--Shi Yu Liu	260683360
--Edward Yu	260617063
--Ryan Ren	260580535

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity IF_tb is
end IF_tb;

architecture behavior of IF_tb is

component InsF is
generic(
    ram_size : INTEGER := 4096
);
port(
    clock : in std_logic;

    -- Avalon interface --
	branch_address : in std_logic_vector (31 downto 0);
	branch_taken : in std_logic;
	
	next_address : out std_logic_vector (31 downto 0);
	IR : out std_logic_vector (31 downto 0)
);
end component;

	
-- test signals 
signal reset : std_logic := '0';
signal clk : std_logic := '0';
constant clk_period : time := 1 ns;

signal	branch_address : std_logic_vector (31 downto 0);
signal	branch_taken : std_logic;
	
signal	next_address : std_logic_vector (31 downto 0);
signal	IR : std_logic_vector (31 downto 0);
signal i : integer := 0;

begin

-- Connect the components which we instantiated above to their
-- respective signals.
dut: InsF
port map(
    clock => clk,

	  branch_address => branch_address,
  	 branch_taken => branch_taken,
	
	  next_address => next_address,
	  IR => IR
);


				

clk_process : process
begin
  clk <= '0';
  wait for clk_period/2;
  clk <= '1';
  wait for clk_period/2;
end process;

test_process : process
begin
    
-- put your tests here
	i <= 0;
  branch_taken <= '0';
  if (i =0) then
    reset <= '1';
    WAIT FOR 3*clk_period;
  end if;  
	
	
	reset <= '0';
	
	
	if(i <50) then
	  i <= i+1;
	  if(i = 20) then
	  branch_address <= "00000000000000000000000000010110";	
	  branch_taken <= '1';
	  end if;
	  WAIT FOR clk_period;
	end if;
	
	
end process;
	
end;
