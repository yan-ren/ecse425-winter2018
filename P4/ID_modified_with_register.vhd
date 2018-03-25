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

		instruction_addr : IN std_logic_vector(31 DOWNTO 0);
		IR_in : IN std_logic_vector(31 DOWNTO 0);
		writeback_register_address : IN std_Logic_vector(4 DOWNTO 0);
		writeback_register_content : IN std_logic_vector(31 DOWNTO 0);
		ex_state_buffer : IN std_logic_vector(10 DOWNTO 0);
		instruction_addr_out : OUT std_logic_vector(31 DOWNTO 0);
		jump_addr : OUT std_logic_vector(25 DOWNTO 0);
		rs : OUT std_logic_vector(31 DOWNTO 0);
		rt : OUT std_logic_vector(31 DOWNTO 0);

		des_addr : OUT std_logic_vector(4 DOWNTO 0);
		signExtImm : OUT std_logic_vector(31 DOWNTO 0);
		insert_stall : OUT std_logic;
		EX_control_buffer : OUT std_logic_vector(10 DOWNTO 0); -- for ex stage provide information for forward and harzard detect, first bit for mem_read, 9-5 for rt, 4-0 for rs
		MEM_control_buffer : OUT std_logic_vector(5 DOWNTO 0); -- for mem stage, provide info for forward and hazard detect, first bit for wb_signal, 4-0 for des_adr
		WB_control_buffer : OUT std_logic_vector(5 DOWNTO 0); -- for mem stage, provide info for forward and hazard detect, first bit for wb_signal, 4-0 for des_adr
		funct_out : OUT std_logic_vector(5 DOWNTO 0);
		opcode_out : OUT std_logic_vector(5 DOWNTO 0);
		write_reg_txt : IN std_logic := '0' -- indicate program ends
	);
END ID;

ARCHITECTURE behaviour OF ID IS
	COMPONENT register_file IS
		GENERIC (
			register_size : INTEGER := 32 --MIPS register size is 32 bit
		);

		PORT (
		  clock : IN STD_LOGIC;
			rs : IN STD_LOGIC_VECTOR (4 DOWNTO 0); -- first source register
			rt : IN STD_LOGIC_VECTOR (4 DOWNTO 0); -- second source register
			write_enable : IN STD_LOGIC; -- signals that rd_data may be written into rd
			rd : IN STD_LOGIC_VECTOR (4 DOWNTO 0); -- destination register
			rd_data : IN STD_LOGIC_VECTOR (31 DOWNTO 0); -- destination register data
			writeToText : IN STD_LOGIC := '0';

			rs_data : OUT STD_LOGIC_VECTOR (31 DOWNTO 0); -- data of register rs
			rt_data : OUT STD_LOGIC_VECTOR (31 DOWNTO 0) -- data of register rt
		);
	END COMPONENT;

	TYPE registerarray IS ARRAY(register_size - 1 DOWNTO 0) OF std_logic_vector(31 DOWNTO 0);
	SIGNAL register_block : registerarray;
	SIGNAL rs_pos : std_logic_vector(4 DOWNTO 0) := "00000";
	SIGNAL rt_pos : std_logic_vector(4 DOWNTO 0) := "00000";
	SIGNAL immediate : std_logic_vector(15 DOWNTO 0) := "0000000000000000";
	SIGNAL rd_pos : std_logic_vector(4 DOWNTO 0) := "00000";
	SIGNAL IR : std_logic_vector(31 DOWNTO 0) := (OTHERS => '0');
	SIGNAL opcode : std_logic_vector(5 DOWNTO 0) := "000000";
	SIGNAL funct : std_logic_vector(5 DOWNTO 0) := "000000";
	SIGNAL dest_address : std_logic_vector(4 DOWNTO 0) := "00000";
	SIGNAL temp_MEM_control_buffer : std_logic_vector(5 DOWNTO 0);
	SIGNAL temp_WB_control_buffer : std_logic_vector(5 DOWNTO 0);
	SIGNAL hazard_detect : std_logic := '0';
  SIGNAL write_enable : std_logic := '0';

BEGIN

opcode <= IR(31 DOWNTO 26);
funct <= IR(5 DOWNTO 0);
rs_pos <= IR(25 DOWNTO 21);
rt_pos <= IR (20 DOWNTO 16);
rd_pos <= IR(15 DOWNTO 11);
immediate <= IR(15 DOWNTO 0);
insert_stall <= hazard_detect;

rg : register_file
		GENERIC MAP(
		   register_size => 32 --MIPS register size is 32 bit
		)
		PORT MAP(
			clock => clk,
			rs => rs_pos, -- first source register
			rt => rt_pos, -- second source register
			write_enable => write_enable, -- signals that rd_data may be written into rd
			rd => writeback_register_address, -- destination register
			rd_data => writeback_register_content, -- destination register data
			writeToText => write_reg_txt,

			rs_data => rs, -- data of register rs
			rt_data => rt -- data of register rt
		);


-- hazard detect
hazard_process : PROCESS (ex_state_buffer, clk)
BEGIN
	hazard_detect <= '0';
	IF (ex_state_buffer(10) = '1' AND bran_taken_in = '0') THEN
		IF (ex_state_buffer(9 DOWNTO 5) = rs_pos OR ex_state_buffer(4 DOWNTO 0) = rt_pos) THEN
			IR <= IR_in;
			hazard_detect <= '1';
		ELSE
			IR <= x"00000020";
			hazard_detect <= '0';
		END IF;
	ELSE
		IR <= IR_in;
	END IF;

END PROCESS;

-- write back process

wb_process : PROCESS (clk, writeback_register_address, writeback_register_content)
BEGIN
  --	initialize the register
	IF (now < 1 ps) THEN
		REPORT "initial the REGISTER";
		FOR i IN 0 TO register_size - 1 LOOP
			register_block(i) <= std_logic_vector(to_unsigned(0, 32));

		END LOOP;
	END IF;

	-- write back the data to register

	IF (writeback_register_address /= "00000" AND now > 4 ns) THEN
		REPORT "write back called ";
      write_enable <= '1';
		  register_block(to_integer(unsigned(writeback_register_address))) <= writeback_register_content;
  else
      write_enable <= '0';
  END IF;

END PROCESS;

reg_process : PROCESS (clk)
BEGIN
	IF (clk'EVENT AND clk = '1') THEN

		CASE opcode IS
			-- R instruction
			WHEN "000000" =>
				IF (funct = "011010" OR funct = "011000" OR funct = "001000") THEN
					dest_address <= "00000";
				ELSE
					dest_address <= rd_pos;
				END IF;
				-- I & J instruction
				-- lw
			WHEN "100011" =>
				dest_address <= rt_pos;
				-- lui
			WHEN "001111" =>
				dest_address <= rt_pos;
				-- xori
			WHEN "001110" =>
				dest_address <= rd_pos;
				-- ori
			WHEN "001101" =>
				dest_address <= rt_pos;
				-- andi
			WHEN "001100" =>
				dest_address <= rt_pos;
				-- slti
			WHEN "001010" =>
				dest_address <= rt_pos;
				-- addi
			WHEN "001000" =>
				dest_address <= rt_pos;
				-- jal
			WHEN "000011" =>
				dest_address <= "11111";
			WHEN OTHERS =>
				dest_address <= "00000";
		END CASE;

		-- works on falling edge
	ELSIF (falling_edge(clk)) THEN

		IF (bran_taken_in = '0') THEN
			-- throw data into id and ex buffer
			des_addr <= dest_address;
			rs <= register_block(to_integer(unsigned(rs_pos)));
			rt <= register_block(to_integer(unsigned(rt_pos)));
			opcode_out <= IR(31 DOWNTO 26);
			funct_out <= funct;
			instruction_addr_out <= instruction_addr;
			jump_addr <= IR(25 DOWNTO 0);
			signExtImm(15 DOWNTO 0) <= immediate;

			IF (IR(31 DOWNTO 27) = "00110") THEN
				signExtImm(31 DOWNTO 16) <= (31 DOWNTO 16 => '0');
			ELSE
				signExtImm(31 DOWNTO 16) <= (31 DOWNTO 16 => immediate(15));
			END IF;
		ELSE
			des_addr <= (OTHERS => '0');
			rs <= (OTHERS => '0');
			rt <= (OTHERS => '0');
			opcode_out <= (OTHERS => '0');
			funct_out <= (OTHERS => '0');
			instruction_addr_out <= (OTHERS => '0');
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
			IF (opcode = "100011") THEN
				EX_control_buffer(10) <= '1';
			ELSE
				EX_control_buffer(10) <= '0';
			END IF;
			EX_control_buffer(9 DOWNTO 5) <= rt_pos;
			EX_control_buffer(4 DOWNTO 0) <= rs_pos;
			--prepare for mem and wb control buffer
			CASE opcode IS
				-- R instruction
				WHEN "000000" =>
					IF (funct = "011010" OR funct = "011000" OR funct = "001000") THEN
						temp_MEM_control_buffer(5) <= '0';
						temp_WB_control_buffer(5) <= '0';
					ELSE
						temp_MEM_control_buffer(5) <= '1';
						temp_WB_control_buffer(5) <= '1';
					END IF;
					-- I & J instruction
					-- lw
				WHEN "100011" =>
					temp_MEM_control_buffer(5) <= '0';
					temp_WB_control_buffer(5) <= '1';
					-- luiha
				WHEN "001111" =>
					temp_MEM_control_buffer(5) <= '1';
					temp_WB_control_buffer(5) <= '1';
					-- xori
				WHEN "001110" =>
					temp_MEM_control_buffer(5) <= '1';
					temp_WB_control_buffer(5) <= '1';
					-- ori
				WHEN "001101" =>
					temp_MEM_control_buffer(5) <= '1';
					temp_WB_control_buffer(5) <= '1';
					-- andi
				WHEN "001100" =>
					temp_MEM_control_buffer(5) <= '1';
					temp_WB_control_buffer(5) <= '1';
					-- slti
				WHEN "001010" =>
					temp_MEM_control_buffer(5) <= '1';
					temp_WB_control_buffer(5) <= '1';
					-- addi
				WHEN "001000" =>
					temp_MEM_control_buffer(5) <= '1';
					temp_WB_control_buffer(5) <= '1';
					-- jal
				WHEN "000011" =>
					temp_MEM_control_buffer(5) <= '1';
					temp_WB_control_buffer(5) <= '1';
				WHEN OTHERS =>
					temp_MEM_control_buffer(5) <= '0';
					temp_WB_control_buffer(5) <= '0';
			END CASE;
			-- MEM_control_buffer(5) <= temp_MEM_control_buffer(5);
			temp_MEM_control_buffer(4 DOWNTO 0) <= dest_address;
			temp_WB_control_buffer(4 DOWNTO 0) <= dest_address;
		ELSE
			temp_WB_control_buffer <= (OTHERS => '0');
			temp_MEM_control_buffer <= (OTHERS => '0');
			EX_control_buffer <= (OTHERS => '0');
		END IF;
	END IF;

END PROCESS;
WB_control_buffer <= temp_WB_control_buffer;
MEM_control_buffer <= temp_MEM_control_buffer;

file_handler_process : PROCESS (write_reg_txt)
	FILE registerfile : text;
	VARIABLE line_num : line;
	VARIABLE fstatus : file_open_status;
	VARIABLE reg_value : std_logic_vector(31 DOWNTO 0);
BEGIN
	-- when the program ends
	IF (write_reg_txt = '1') THEN
		REPORT "Start writing the REGISTER FILE";
		file_open(fstatus, registerfile, "register_file.txt", WRITE_MODE);
		-- register_file.txt has 32 lines
		-- convert each bit value of reg_value to character for writing
		FOR i IN 0 TO 31 LOOP
			reg_value := register_block(i);
			--write the line
			write(line_num, reg_value);
			--write the contents into txt file
			writeline(registerfile, line_num);
		END LOOP;
		file_close(registerfile);
		REPORT "Finish outputing the REGISTER FILE";
	END IF;
END PROCESS;

END behaviour;
