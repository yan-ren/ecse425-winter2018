--ECSE 425 Lab 3 Cache VHDL
--Tara Tabet	260625552
--Shi Yu Liu	260683360
--Edward Yu	260617063
--Ryan Ren	260580535

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use STD.textio.all;
use ieee.std_logic_textio.all;

entity fetch is
generic(
	ram_size : INTEGER := 4096
);
port(
	clock : in std_logic;
	
	-- Avalon interface --
	branch_address : in std_logic_vector (31 downto 0);
	branch_taken : in std_logic;
	
	PC_mux : out std_logic_vector (31 downto 0);
	IR : out std_logic_vector (31 downto 0)
);
end fetch;

architecture arch of fetch is

-- declare signals here
--signals that work with cache and memory
signal clk : std_logic := '0';
constant clk_period : time := 1 ns;


--signals that work with fetch 
file file_instruction : text;
signal PC : STD_LOGIC_VECTOR (31 downto 0);
signal i : INTEGER;
signal j : INTEGER;
TYPE MEM IS ARRAY(ram_size-1 downto 0) OF STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL instruct_block: MEM;

begin
IF_process: process(clock)

     variable line : line;

    variable instruct : std_logic_vector(31 downto 0);
begin
  
    IF(now < 1 ps)THEN
    
			file_open(file_instruction, "program.txt",  read_mode);
      
       For j in 0 to ram_size-1 LOOP
          if (endfile(file_instruction)) then
            exit;
          end if;
         
          readline(file_instruction, line);
          read(line, instruct);
				  instruct_block(j) <= instruct;
			 END LOOP;
			 
		  file_close(file_instruction);
		  
		  PC <= "00000000000000000000000000000000";	
		end if;
	
	if (rising_edge(clock)) THEN -- If not reset, do...
	  
               --IR is the instruction later sent to the decode stage
               IR <= instruct_block(to_integer(unsigned(PC)));
                 
	             --if branch is taken, puts branch address into PC_MUX and PC
	             if(branch_taken = '1') then
				          --branch_taken = '0';
				          PC_MUX <= branch_address; 
				          PC <= branch_address; 
				         
				       --if branch is not taken, puts PC+4 into PC_MUX and PC 
				       elsif ( branch_taken = '0') then
      	           PC_MUX <= std_logic_vector(to_unsigned(to_integer(unsigned(PC))+1, 32));
    	             PC <= std_logic_vector(to_unsigned(to_integer(unsigned(PC))+1, 32));
    	             
				       end if;
	     
	end if;	
end process;	
end arch;
