LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE STD.textio.ALL;
USE ieee.std_logic_textio.ALL;
USE IEEE.std_logic_unsigned.ALL;

ENTITY ID IS
	GENERIC (
		register_size : INTEGER := 32
	);
	PORT (
		clk : IN std_logic;
		bran_taken_in : IN std_logic; -- from mem
		IR_addr : IN std_logic_vector(31 DOWNTO 0);
		IR : IN std_logic_vector(31 DOWNTO 0);
		writeback_register_address : IN std_Logic_vector(4 DOWNTO 0);
		writeback_register_content : IN std_logic_vector(31 DOWNTO 0);
		ex_state_buffer : IN std_logic_vector(10 DOWNTO 0);

		IR_addr_out : OUT std_logic_vector(31 DOWNTO 0);
		jump_addr : OUT std_logic_vector(25 DOWNTO 0);
		rs : OUT std_logic_vector(31 DOWNTO 0);
		rt : OUT std_logic_vector(31 DOWNTO 0);
		des_addr : OUT std_logic_vector(4 DOWNTO 0);
		signExtImm : OUT std_logic_vector(31 DOWNTO 0);
		insert_stall : OUT std_logic;
		EX_control_buffer : OUT std_logic_vector(10 DOWNTO 0); -- for ex stage provide information for forward and harzard detect, first bit for mem_read, 9-5 for rt, 4-0 for rs
		MEM_control_buffer : OUT std_logic_vector(5 DOWNTO 0); -- for mem stage, provide info for forward and hazard detect, first bit for wb_signal, 4-0 for des_adr
		WB_control_buffer : OUT std_logic_vector(5 DOWNTO 0); -- for wb stage, provide info for forward and hazard detect, first bit for wb_signal, 4-0 for des_adr
		funct : OUT std_logic_vector(5 DOWNTO 0);
		opcode : OUT std_logic_vector(5 DOWNTO 0);
		write_enable : IN std_logic := '0' -- indicate program ends
	);
END ID;

ARCHITECTURE behaviour OF ID IS
	TYPE registerarray IS ARRAY(register_size - 1 DOWNTO 0) OF std_logic_vector(31 DOWNTO 0);
	SIGNAL register_block : registerarray := (OTHERS => "00000000000000000000000000000000"); -- initialize all registers to 32 bits of 0.
	SIGNAL s_rs_address : std_logic_vector(4 DOWNTO 0) := "00000";
	SIGNAL s_rt_address : std_logic_vector(4 DOWNTO 0) := "00000";
	SIGNAL s_immediate : std_logic_vector(15 DOWNTO 0) := "0000000000000000";
	SIGNAL s_rd_address : std_logic_vector(4 DOWNTO 0) := "00000";
	SIGNAL s_opcode : std_logic_vector(5 DOWNTO 0) := "000000";
	SIGNAL s_funct : std_logic_vector(5 DOWNTO 0) := "000000";
	SIGNAL s_dest_address : std_logic_vector(4 DOWNTO 0) := "00000";
	SIGNAL s_MEM_control_buffer : std_logic_vector(5 DOWNTO 0);
	SIGNAL s_WB_control_buffer : std_logic_vector(5 DOWNTO 0);
	SIGNAL s_hazard_detect : std_logic := '0';
	SIGNAL s_write_enable: std_logic := '0';

BEGIN
	s_opcode <= IR(31 DOWNTO 26);
	s_funct <= IR(5 DOWNTO 0);
	s_rs_address <= IR(25 DOWNTO 21);
	s_rt_address <= IR (20 DOWNTO 16);
	s_rd_address <= IR(15 DOWNTO 11);
	s_immediate <= IR(15 DOWNTO 0);
	insert_stall <= s_hazard_detect;

	-- hazard detect
	hazard_process : PROCESS (ex_state_buffer, clk)
	BEGIN
		s_hazard_detect <= '0';
		IF (ex_state_buffer(10) = '1' AND bran_taken_in = '0') THEN
		-- EX is using rs or rx register, hazard detected
			IF (ex_state_buffer(9 DOWNTO 5) = s_rs_address OR ex_state_buffer(4 DOWNTO 0) = s_rt_address) THEN
				s_hazard_detect <= '1';
			END IF;
		END IF;
	END PROCESS;

	-- write back process
	wb_process : PROCESS (clk, writeback_register_address, writeback_register_content)
	BEGIN
		-- write back the data to register
		IF (writeback_register_address /= "00000" AND now > 4 ns) THEN
			REPORT "write back called ";
			register_block(to_integer(unsigned(writeback_register_address))) <= writeback_register_content;
			s_write_enable <= '1';
		else
			s_write_enable <= '0';
		END IF;

	END PROCESS;

	reg_process : PROCESS (clk)
	BEGIN
		IF (clk'EVENT AND clk = '1') THEN
			CASE s_opcode IS
				-- R instruction
				WHEN "000000" =>
					-- div, mult, jr
					IF (s_funct = "011010" OR s_funct = "011000" OR s_funct = "001000") THEN
						s_dest_address <= "00000";
					ELSE
						s_dest_address <= s_rd_address;
					END IF;
					-- I & J instruction
					-- lw
				WHEN "100011" =>
					s_dest_address <= s_rt_address;
					-- lui
				WHEN "001111" =>
					s_dest_address <= s_rt_address;
					-- ori
				WHEN "001101" =>
					s_dest_address <= s_rt_address;
					-- xori
				WHEN "001110" =>
					s_dest_address <= s_rd_address;
					-- addi
				WHEN "001000" =>
					s_dest_address <= s_rt_address;
					-- andi
				WHEN "001100" =>
					s_dest_address <= s_rt_address;
					-- slti
				WHEN "001010" =>
					s_dest_address <= s_rt_address;
					-- jal
				WHEN "000011" =>
					s_dest_address <= "11111";
				WHEN OTHERS =>
					s_dest_address <= "00000";
			END CASE;

			-- works on falling edge
		ELSIF (falling_edge(clk)) THEN

			IF (bran_taken_in = '0') THEN
				-- throw data into id and ex buffer
				des_addr <= s_dest_address;
				rs <= register_block(to_integer(unsigned(s_rs_address)));
				rt <= register_block(to_integer(unsigned(s_rt_address)));
				opcode <= IR(31 DOWNTO 26);
				funct <= s_funct;
				IR_addr_out <= IR_addr;
				jump_addr <= IR(25 DOWNTO 0);
				signExtImm(15 DOWNTO 0) <= s_immediate;

				IF (IR(31 DOWNTO 27) = "00110") THEN
					signExtImm(31 DOWNTO 16) <= (31 DOWNTO 16 => '0');
				ELSE
					signExtImm(31 DOWNTO 16) <= (31 DOWNTO 16 => s_immediate(15));
				END IF;
			ELSE
				des_addr <= (OTHERS => '0');
				rs <= (OTHERS => '0');
				rt <= (OTHERS => '0');
				opcode <= (OTHERS => '0');
				funct <= (OTHERS => '0');
				IR_addr_out <= (OTHERS => '0');
				jump_addr <= (OTHERS => '0');
				signExtImm(31 DOWNTO 0) <= (OTHERS => '0');

			END IF;

		END IF;
	END PROCESS;
	-- to save the control signal to the buffer
	control_process : PROCESS (clk)
	BEGIN
		-- prepare for ex_control buffer
		IF (falling_edge(clk)) THEN
			IF (bran_taken_in = '0') THEN
				IF (s_opcode = "100011") THEN
					EX_control_buffer(10) <= '1';
				ELSE
					EX_control_buffer(10) <= '0';
				END IF;
				EX_control_buffer(9 DOWNTO 5) <= s_rt_address;
				EX_control_buffer(4 DOWNTO 0) <= s_rs_address;
				--prepare for mem and wb control buffer
				CASE s_opcode IS
					-- R instruction
					WHEN "000000" =>
						IF (s_funct = "011010" OR s_funct = "011000" OR s_funct = "001000") THEN
							s_MEM_control_buffer(5) <= '0';
							s_WB_control_buffer(5) <= '0';
						ELSE
							s_MEM_control_buffer(5) <= '1';
							s_WB_control_buffer(5) <= '1';
						END IF;
						-- I & J instruction
						-- lw
					WHEN "100011" =>
						s_MEM_control_buffer(5) <= '0';
						s_WB_control_buffer(5) <= '1';
						-- luiha
					WHEN "001111" =>
						s_MEM_control_buffer(5) <= '1';
						s_WB_control_buffer(5) <= '1';
						-- xori
					WHEN "001110" =>
						s_MEM_control_buffer(5) <= '1';
						s_WB_control_buffer(5) <= '1';
						-- ori
					WHEN "001101" =>
						s_MEM_control_buffer(5) <= '1';
						s_WB_control_buffer(5) <= '1';
						-- andi
					WHEN "001100" =>
						s_MEM_control_buffer(5) <= '1';
						s_WB_control_buffer(5) <= '1';
						-- slti
					WHEN "001010" =>
						s_MEM_control_buffer(5) <= '1';
						s_WB_control_buffer(5) <= '1';
						-- addi
					WHEN "001000" =>
						s_MEM_control_buffer(5) <= '1';
						s_WB_control_buffer(5) <= '1';
						-- jal
					WHEN "000011" =>
						s_MEM_control_buffer(5) <= '1';
						s_WB_control_buffer(5) <= '1';
					WHEN OTHERS =>
						s_MEM_control_buffer(5) <= '0';
						s_WB_control_buffer(5) <= '0';
				END CASE;
				s_MEM_control_buffer(4 DOWNTO 0) <= s_dest_address;
				s_WB_control_buffer(4 DOWNTO 0) <= s_dest_address;
			ELSE
				s_WB_control_buffer <= (OTHERS => '0');
				s_MEM_control_buffer <= (OTHERS => '0');
				EX_control_buffer <= (OTHERS => '0');
			END IF;
		END IF;

	END PROCESS;
	WB_control_buffer <= s_WB_control_buffer;
	MEM_control_buffer <= s_MEM_control_buffer;

	write_file_process : PROCESS (write_enable)
	FILE register_file : text OPEN write_mode IS "register_file.txt";
	VARIABLE outLine : line;
	VARIABLE rowLine : INTEGER := 0;
	BEGIN
		-- when the program ends
		IF (write_enable = '1') THEN
			REPORT "Start writing the REGISTER FILE";
			WHILE (rowLine < 32) LOOP
				write(outLine, register_block(rowLine));
				writeline(register_file, outLine);
				rowLine := rowLine + 1;
			END LOOP;
			REPORT "Finish writting the REGISTER FILE";
		END IF;
	END PROCESS;

END behaviour;
