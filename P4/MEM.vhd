-- MEM pipeline process
-- Author: Shi Yu Liu
-- references: http://www.mrc.uidaho.edu/mrc/people/jff/digital/MIPSir.html
-- 				https://www.nandland.com/vhdl/examples/example-file-io.html

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use STD.textio.all;
use ieee.std_logic_textio.all;

entity MEM is
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
end MEM;

architecture arch of MEM is
	
	
	-- Data memory: taken from memory.vhd provided in P3
	-- Modified to have 8192 lines of 32 bits each
	type MEM is array(ram_size-1 downto 0) OF std_logic_vector(reg_size-1 downto 0);
	signal ram_block: MEM;
	
	-- HI&LO special registers used in MULT and DIV
	type hilo_reg is array(1 downto 0) of std_logic_vector(reg_size-1 downto 0);
	signal hilo: hilo_reg;
	
	signal instr : std_logic_vector(31 downto 0);
	
begin	
	-- Processes the instruction
	MEM_process : process(clock, stall_in, write_to_txt)
	-- variables needed during the MEM_process
	variable opcode : std_logic_vector(5 downto 0);
	variable funct : std_logic_vector(5 downto 0);
	variable dest_reg : std_logic_vector(4 downto 0);
	
	-- variables for writing to memory.txt
	file file_MEM : text;
	variable cur_line : line;
	
	begin
		instr <= instr_in;
		opcode := instr(31 downto 26);
		funct := instr(5 downto 0);
		dest_reg := instr(20 downto 16);
		
		-- Taken from memory.vhd provided in P3
		if(now < 1*clock_period) then
			for i in 0 to ram_size-1 loop
				-- Modified to initialize to zero (0)
				ram_block(i) <= std_logic_vector(to_unsigned(0,32));
			end loop;
		end if;
		
		-- Write to txt
		if(write_to_txt = 1 or now > 10000*clock_period) then
		file_open(file_MEM, "memory.txt", write_mode);
			for i in 0 to ram_size-1 loop
				write(cur_line, ram_block(i), right, reg_size);
				writeline(file_MEM, cur_line);
			end loop;
		file_close(file_MEM);
		end if;
		
		if (rising_edge(clock)) then
			-- if there is previous stall, stall next instruction
			if (stall_in = '1') then
				stall_out <= '1' after clock_period, '0' after clock_period + clock_period;
			
			-- otherwise process the new instruction
			elsif (stall_in = '0') then
					
					-- LW Ry, offset(Rx)
					if(opcode = "100011") then
						-- Ry required data <= memory[ALU_in1 = Rx data + offset]
						MEM_out1 <= ram_block(to_integer(unsigned(ALU_in1)));
						MEM_out2 <= ALU_in2;
						i <= to_integer(unsigned(ALU_in1));
					
					-- SW Ry, offset(Rx)
					elsif(opcode = "101011") then
						-- memory[ALU_in1 = Rx data + offset] <= Ry data
						ram_block(to_integer(unsigned(ALU_in2))) <= ALU_in1;
						MEM_out1 <= ALU_in1;
						MEM_out2 <= ALU_in2;
						i <= to_integer(unsigned(ALU_in2));
						
					-- MEM not required
					else
						MEM_out1 <= ALU_in1;
						MEM_out2 <= ALU_in2;
					end if;
					
					instr_out <= instr;
					
			end if;
		end if;
		
	end process;

end arch;