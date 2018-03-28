--ECSE 425 Lab 3 Cache VHDL
--Tara Tabet	260625552
--Shi Yu Liu	260683360
--Edward Yu	260617063
--Ryan Ren	260580535

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fetch is
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
	waitrequest : out std_logic
);
end fetch;

architecture arch of fetch is

-- states of our FSM
--type state_type is (RESET_FETCH, INSTRUCTION_FETCH, WAIT_STATE);

-- declare signals here
--signals that work with cache and memory
signal clk : std_logic := '0';
constant clk_period : time := 1 ns;

signal m_addr : integer range 0 to 2147483647;
signal m_read : std_logic;
signal m_readdata : std_logic_vector (31 downto 0);
signal m_write : std_logic;
signal m_writedata : std_logic_vector (31 downto 0);
signal m_waitrequest : std_logic;

--signals that work with fetch 
--signal state: state_type;

signal PC : STD_LOGIC_VECTOR (31 downto 0);
signal PC_new : STD_LOGIC_VECTOR (31 downto 0);
signal PC_add : STD_LOGIC_VECTOR (31 downto 0);
signal i : INTEGER;
signal statenum : integer;

begin

-- Connect the components which we instantiated above to their
-- respective signals.

MEM : entity work.memory_instruction
GENERIC MAP(
            ram_size => 1024
)
port map (
    clock => clock,
    writedata => m_writedata,
    address => m_addr,
    memwrite => m_write,
    memread => m_read,
    readdata => m_readdata,
    waitrequest => m_waitrequest
);

cache_FSM_do: process(clock, reset)
	variable index: INTEGER;

begin
    IF(now < 1 ps)THEN
			PC <= "00000000000000000000000000000000";	
		  state_number <= m_addr;
		  m_read <= '0';
		  m_addr <= to_integer(unsigned(PC));
		  PC_new <= std_logic_vector(to_unsigned(to_integer(unsigned(PC))+4, 32));
		  m_read <= '1';
		  test_vector <= PC;
		end if;
	if (rising_edge(clock)) THEN -- If not reset, do...
	  
                 m_addr <= to_integer(unsigned(PC));
				         PC_MUX <= PC_new;
    	            PC <= PC_new;
    	            
	               PC_new <= std_logic_vector(to_unsigned(to_integer(unsigned(PC))+4, 32));
                 state_number <= m_addr;
                 test_vector <= PC;
	      
	             --if branch is taken,
	             if(branch_taken = '1') then
	                test_vector <= PC;
            
      	           state_number <= m_addr;
      	           --IR <= m_readdata;
				          --branch_taken = '0';
				          PC_new <= branch_address;
				          PC_MUX <= PC_new; 
				          PC <= PC_new; 
				          
				          m_addr <= to_integer(unsigned(PC));
				          test_vector <= PC;
      	           state_number <= m_addr;
      	           
				        elsif ( branch_taken = '0') then
				          test_vector <= PC;
      	           state_number <= m_addr;
      	           
                
				          
				          state_number <= m_addr;
				          test_vector <= PC;
				         end if;
				  
    	            IR <= m_readdata;
	               
                 test_vector <= PC;
  	              state_number <= m_addr;
  	              
                
        
	     
	end if;			
end process;	
end arch;






