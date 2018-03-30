--ECSE 425 Lab 3 Cache Testbench
--Tara Tabet	260625552
--Shi Yu Liu	260683360
--Edward Yu	260617063
--Ryan Ren	260580535

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity processor_tb is
end processor_tb;

architecture behavior of processor_tb is

component processor is
 port(   clock : in std_logic;
	  next_address_t : out std_logic_vector (31 downto 0);
	  IR_t : out std_logic_vector (31 downto 0);
	  rs_t : OUT std_logic_vector(31 DOWNTO 0);
		rt_t : OUT std_logic_vector(31 DOWNTO 0)
		);
end component;

	
-- test signals 
signal reset : std_logic := '0';
signal clk : std_logic := '0';
constant clk_period : time := 1 ns;

signal	rs : std_logic_vector (31 downto 0);
signal	rt : std_logic_vector (31 downto 0);
	
signal	next_address : std_logic_vector (31 downto 0);
signal	IR : std_logic_vector (31 downto 0);
signal i : integer := 0;

begin

-- Connect the components which we instantiated above to their
-- respective signals.

dut: processor
port map(
    clock => clk,

	  next_address_t => next_address,
	  IR_t => IR,
	  rs_t => rs,
		rt_t => rt
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
	if(i <100) then
	  i <= i+1;
	  
	  WAIT FOR clk_period;
	end if;
	
	
end process;
	
end;

