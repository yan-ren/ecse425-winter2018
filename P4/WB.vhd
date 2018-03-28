-- MEM pipeline process
-- Author: Shi Yu Liu
-- references: http://www.mrc.uidaho.edu/mrc/people/jff/digital/MIPSir.html
-- 				https://www.nandland.com/vhdl/examples/example-file-io.html

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity WB is
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
	
	-- for test pruposes
	
);
end WB;

architecture arch of WB is
	
	-- HI&LO special registers used in MULT and DIV
	type hilo_reg is array(1 downto 0) of std_logic_vector(reg_size-1 downto 0);
	signal hilo: hilo_reg;
	
begin	
	-- Processes the instruction
	WB_process : process(clock, stall_in)
	-- variables needed during the MEM_process
	variable opcode : std_logic_vector(5 downto 0);
	variable funct : std_logic_vector(5 downto 0);
	variable dest_reg_imm : std_logic_vector(4 downto 0);
	variable dest_reg_r : std_logic_vector(4 downto 0);
	
	begin
		opcode := instr_in(31 downto 26);
		funct := instr_in(5 downto 0);
		dest_reg_imm := instr_in(20 downto 16);
		dest_reg_r := instr_in(10 downto 6);
		
		-- Taken from memory.vhd provided in P3
		if(now < 1*clock_period) then
			for i in 0 to 1 loop
				-- Modified to initialize to zero (0)
				hilo(i) <= std_logic_vector(to_unsigned(0,32));
			end loop;
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
						reg_to_load <= dest_reg_imm;
						load_to_reg <= MEM_in1;
					
					-- R instructions
					elsif(opcode = "000000") then
						-- add
						if(funct = "100000") then
							reg_to_load <= dest_reg_r;
							load_to_reg <= MEM_in1;
						-- and
						elsif(funct = "100100") then
							reg_to_load <= dest_reg_r;
							load_to_reg <= MEM_in1;
						-- or
						elsif(funct = "100101") then
							reg_to_load <= dest_reg_r;
							load_to_reg <= MEM_in1;
						-- sll
						elsif(funct = "000000") then
							reg_to_load <= dest_reg_r;
							load_to_reg <= MEM_in1;
						-- sub
						elsif(funct = "100010") then
							reg_to_load <= dest_reg_r;
							load_to_reg <= MEM_in1;
						-- xor
						elsif(funct = "100110") then
							reg_to_load <= dest_reg_r;
							load_to_reg <= MEM_in1;
						-- mfhi
						elsif(funct = "010000") then
							reg_to_load <= dest_reg_r;
							load_to_reg <= hilo(0);
						-- mflo
						elsif(funct = "010010") then
							reg_to_load <= dest_reg_r;
							load_to_reg <= hilo(1);
						-- mult
						elsif(funct = "011000") then
							hilo(0) <= MEM_in2;
							hilo(1) <= MEM_in1;
						-- sub
						elsif(funct = "100010") then
							reg_to_load <= dest_reg_r;
							load_to_reg <= MEM_in1;
						-- div
						elsif(funct = "100010") then
							hilo(0) <= MEM_in2;
							hilo(1) <= MEM_in1;
						-- slt
						elsif(funct = "101010") then
							reg_to_load <= dest_reg_r;
							load_to_reg <= MEM_in1;
						-- nor
						elsif(funct = "100111") then
							reg_to_load <= dest_reg_r;
							load_to_reg <= MEM_in1;
						-- sra
						elsif(funct = "000011") then
							reg_to_load <= dest_reg_r;
							load_to_reg <= MEM_in1;
						-- srl
						elsif(funct = "000010") then
							reg_to_load <= dest_reg_r;
							load_to_reg <= MEM_in1;
						end if;
					
					-- addi
					elsif(opcode = "001000") then
						reg_to_load <= dest_reg_r;
						load_to_reg <= MEM_in1;
					-- slti
					elsif(opcode = "001010") then
						reg_to_load <= dest_reg_r;
						load_to_reg <= MEM_in1;
					-- andi
					elsif(opcode = "001100") then
						reg_to_load <= dest_reg_r;
						load_to_reg <= MEM_in1;
					-- ori
					elsif(opcode = "001101") then
						reg_to_load <= dest_reg_r;
						load_to_reg <= MEM_in1;
					-- xori
					elsif(opcode = "001110") then
						reg_to_load <= dest_reg_r;
						load_to_reg <= MEM_in1;
					-- lui
					elsif(opcode = "001111") then
						reg_to_load <= dest_reg_r;
						load_to_reg <= MEM_in1;
					-- jal
					elsif(opcode = "000011") then
						reg_to_load <= dest_reg_r;
						load_to_reg <= MEM_in1;
					end if;
					
					instr_out <= instr_in;
					
			end if;
		end if;
		
	end process;

end arch;