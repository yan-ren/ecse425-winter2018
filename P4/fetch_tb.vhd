--ECSE 425 Lab 3 Cache Testbench
--Tara Tabet	260625552
--Shi Yu Liu	260683360
--Edward Yu	260617063
--Ryan Ren	260580535

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fetch_tb is
end fetch_tb;

architecture behavior of fetch_tb is

component fetch is
generic(
    ram_size : INTEGER := 32768
);
port(
    clock : in std_logic;
    reset : in std_logic;

    -- Avalon interface --
	branch_address : in std_logic_vector (31 downto 0);
	branch_taken : in std_logic;
	
	PC_mux : out std_logic_vector (31 downto 0);
	IR : out std_logic_vector (31 downto 0);
	test_vector : out std_logic_vector (31 downto 0);
  state_number: out integer;
  waitrequest: out std_logic
);
end component;

	
-- test signals 
signal reset : std_logic := '0';
signal clk : std_logic := '0';
constant clk_period : time := 1 ns;

signal	branch_address : std_logic_vector (31 downto 0);
signal	branch_taken : std_logic;
	
signal	PC_mux : std_logic_vector (31 downto 0);
signal	IR : std_logic_vector (31 downto 0);
signal	test_vector : std_logic_vector (31 downto 0);
signal state_number: integer;
signal waitrequest: std_logic;
signal i : integer := 0;

begin

-- Connect the components which we instantiated above to their
-- respective signals.
dut: fetch
port map(
    clock => clk,
    reset => reset,

	  branch_address => branch_address,
  	 branch_taken => branch_taken,
	
	  PC_mux => PC_mux,
	  IR => IR,
	  test_vector => test_vector,
	  state_number => state_number,
	  waitrequest => waitrequest
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
	
	
	if(i <100) then
	  i <= i+1;
	  WAIT FOR clk_period;
	end if;
	
	
end process;
	
end;
