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
	ram_size : INTEGER := 1024
);
port(
	clock : in std_logic;
	
	branch_address : in std_logic_vector (31 downto 0);
	branch_taken : in std_logic;
	
	next_address : out std_logic_vector (31 downto 0);
	IR : out std_logic_vector (31 downto 0);
	next_IR : out std_logic_vector (31 downto 0);
	branch_next : out std_logic
);
end fetch;

architecture arch of fetch is

-- declare signals here
signal clk : std_logic := '0';
constant clk_period : time := 1 ns;

--signals that work with fetch 
file file_instruction : text;
signal PC : STD_LOGIC_VECTOR (31 downto 0);
signal i : INTEGER;
signal j : INTEGER;
signal b : std_logic;
signal next_instruction : std_logic_vector (31 downto 0);
TYPE MEM IS ARRAY(ram_size-1 downto 0) OF STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL instruct_block: MEM;
TYPE BUF IS ARRAY(5 downto 0) OF STD_LOGIC_VECTOR(33 DOWNTO 0);
	SIGNAL IR_buffer: BUF;	

begin
IF_process: process(clock)

    variable line : line;
    variable instruct : std_logic_vector(31 downto 0);
    
begin
  
    IF(now < 1 ps)THEN
    
			file_open(file_instruction, "program_1.txt",  read_mode);
       For j in 0 to ram_size-1 LOOP
          if (endfile(file_instruction)) then
            exit;
          end if;
          readline(file_instruction, line);
          read(line, instruct);
				  instruct_block(j) <= instruct;
			 END LOOP;
		  file_close(file_instruction);
		  
		  For j in 0 to 5 LOOP
		    IR_buffer(j) <= "0000000000000000000000000000000000";
		  END LOOP;
		  
		  PC <= "00000000000000000000000000000000";
		  
		  
		  if ((to_integer(unsigned(instruct_block(0)(31 downto 26))) = 4) OR (to_integer(unsigned(instruct_block(0)(31 downto 26))) = 5)) then
                 b <= '1';
                 branch_next <= '1';
                 IR_buffer(0) <= "1100000000000000000000000000000000";
                 
                   if ((to_integer(unsigned(instruct_block(1)(31 downto 26))) = 4) OR (to_integer(unsigned(instruct_block(1)(31 downto 26))) = 5)) then
                      IR_buffer(1) <= "11" & "00000000000000000000000000000001";
                   else 
                      IR_buffer(1) <= "10" & "00000000000000000000000000000001"; 
                   end if;
                 
      end if;
      
		  next_instruction <= "00000000000000000000000000000001";
		  next_IR <= next_instruction;
		end if;
	
	if (rising_edge(clock)) THEN 
	             next_IR <= next_instruction;
	  
               --IR is the instruction later sent to the decode stage
               IR <= instruct_block(to_integer(unsigned(PC)));
               next_instruction <= instruct_block(to_integer(unsigned(PC))+2);
               
               
	             --if branch is taken, puts branch address into PC_MUX and PC
	             if(branch_taken = '1') then
				        
				          For j in 1 to 5 LOOP
				            if (IR_buffer(j)(33) = '1') then
				              
				                if (IR_buffer(j)(31 downto 0) = branch_address) then
				                    For t in 1 to 5 LOOP
				                       if(IR_buffer(t)(32) = '1') then
		                              IR_buffer(0) <= IR_buffer(t);
		                              IR_buffer(0) <= "00" & "00000000000000000000000000000000";
		                                  For y in (t+1) to 5 loop
		                                    IR_buffer(y-t) <= IR_buffer(y);
		                                    IR_buffer(y)(33) <= '0';
		                                  end loop;
		                               exit;
		                            else 
		                              IR_buffer(j)(33) <= '0';
		                            end if;
		                         END LOOP;
		                         next_address <= std_logic_vector(to_unsigned(to_integer(unsigned(PC))+1, 32));
  	                          PC <= std_logic_vector(to_unsigned(to_integer(unsigned(PC))+1, 32));
		                     elsif (j=5) then
		                        next_address <= branch_address; 
				                    PC <= branch_address; 
				                    For x in 0 to 5 LOOP
				                        IR_buffer(x)(33) <= '0';
				                    end loop;
				                end if;
				             else
				               next_address <= branch_address; 
				               PC <= branch_address; 
				               For x in 0 to 5 LOOP
				                 IR_buffer(x)(33) <= '0';
				               end loop;
				               exit;
				            end if;
				          end loop;
				        
    				       --if branch is not taken, puts PC+1 into PC_MUX and PC 
				       elsif ( branch_taken = '0') then
				         
      	           next_address <= std_logic_vector(to_unsigned(to_integer(unsigned(PC))+1, 32));
    	             PC <= std_logic_vector(to_unsigned(to_integer(unsigned(PC))+1, 32));
    	             
    	             if (IR_buffer(0)(33) = '1') then
				                
				                --if buffer is full push everything until the next branch up in the buffer
				                if (IR_buffer(5)(33) = '1') then
				                    For j in 1 to 5 LOOP
				                       if(IR_buffer(j)(32) = '1') then
		                              IR_buffer(0) <= IR_buffer(j);
		                              IR_buffer(0) <= "00" & "00000000000000000000000000000000";
		                                  For y in (j+1) to 5 loop
		                                    IR_buffer(y-j) <= IR_buffer(y);
		                                    IR_buffer(y)(33) <= '0';
		                                  end loop;
		                               exit;
		                            else 
		                              IR_buffer(j)(33) <= '0';
		                            end if;
		                        END LOOP;
		                     
		                     --if buffer is not full, place instruction address at next available spot and specifies whether it's a branch instruction or not
		                     else
		                         For j in 1 to 5 LOOP
				                       if(IR_buffer(j)(33) = '0') then
				                       
				                          if ((to_integer(unsigned(instruct_block(to_integer(unsigned(next_instruction)))(31 downto 26))) = 4) OR (to_integer(unsigned(instruct_block(to_integer(unsigned(next_instruction)))(31 downto 26))) = 5)) then
                                      IR_buffer(j) <= "11" & next_instruction;
                                  else 
                                      IR_buffer(j) <= "10" & next_instruction; 
                                  end if;
                                  exit;
		                            end if; 
		                         END LOOP;
		                     end if;
				                
				         
				          end if;
    	             
    	             
				       end if;
	     
	end if;	
end process;	
end arch;
