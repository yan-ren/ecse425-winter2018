LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE STD.textio.ALL;
USE ieee.std_logic_textio.ALL;

ENTITY DataMem IS
	GENERIC (
		ram_size : INTEGER := 32768
	);
	PORT (
		clock : IN std_logic;
		opcode : IN std_logic_vector(5 DOWNTO 0) := (OTHERS => '0');
		dest_addr_in : IN std_logic_vector(4 DOWNTO 0) := (OTHERS => '0');
		ALU_result : IN std_logic_vector(31 DOWNTO 0) := (OTHERS => '0');
		rt_data : IN std_logic_vector(31 DOWNTO 0) := (OTHERS => '0');
		bran_taken : IN std_logic; -- from mem
		bran_addr_in : IN std_logic_vector(31 DOWNTO 0) := (OTHERS => '0'); -- new added
		MEM_control_buffer : IN std_logic_vector(5 DOWNTO 0) := (OTHERS => '0');
		WB_control_buffer : IN std_logic_vector(5 DOWNTO 0) := (OTHERS => '0');

		MEM_control_buffer_out : OUT std_logic_vector(5 DOWNTO 0) := (OTHERS => '0'); --for ex forward
		WB_control_buffer_out : OUT std_logic_vector(5 DOWNTO 0) := (OTHERS => '0'); -- for wb stage

		mem_data : OUT std_logic_vector(31 DOWNTO 0) := (OTHERS => '0');
		ALU_data : OUT std_logic_vector(31 DOWNTO 0) := (OTHERS => '0');
		dest_addr_out : OUT std_logic_vector(4 DOWNTO 0) := (OTHERS => '0');
		bran_addr : OUT std_logic_vector(31 DOWNTO 0) := (OTHERS => '0'); -- for if
		bran_taken_out : OUT std_logic := '0'; -- for if
		write_reg_txt : IN std_logic := '0' -- indicate program ends-- from testbench
	);
	END DataMem;

	ARCHITECTURE behavior OF DataMem IS
		TYPE MEM IS ARRAY(ram_size - 1 DOWNTO 0) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
		SIGNAL ram_block : MEM;
	BEGIN
		MEM_control_buffer_out <= MEM_control_buffer;
		PROCESS (clock)
		BEGIN
			--This is a cheap trick to initialize the SRAM in simulation
			IF (now < 1 ps) THEN
				FOR i IN 0 TO ram_size - 1 LOOP
					ram_block(i) <= std_logic_vector(to_signed(0, 8));
				END LOOP;
			END IF;

			IF (rising_edge(clock)) THEN
				dest_addr_out <= dest_addr_in;
				bran_addr <= bran_addr_in;
				bran_taken_out <= bran_taken;
				-- the opcode is sw
				IF (opcode = "101011") THEN
					-- bran_addr <= std_logic_vector(to_unsigned(0, 32));
					FOR i IN 1 TO 4 LOOP
						ram_block((to_integer(signed(ALU_result))) + i - 1) <= rt_data(8 * i - 1 DOWNTO 8 * i - 8);
						REPORT "rt_data IS " & INTEGER'image(to_integer(signed(rt_data(8 * i - 1 DOWNTO 8 * i - 8))));
						REPORT "store successfully!";
					END LOOP;
					-- the opcode is lw
				ELSIF (opcode = "100011") THEN
					-- bran_addr <= std_logic_vector(to_unsigned(0, 32));
					FOR i IN 0 TO 3 LOOP
						mem_data(8 * i + 7 DOWNTO 8 * i) <= ram_block(to_integer(signed(ALU_result)) + i);
					END LOOP;
					-- the opcode is other
				ELSE
					-- bran_addr <= std_logic_vector(to_unsigned(0, 32));
					ALU_data <= ALU_result;
				END IF;
			ELSIF (falling_edge(clock)) THEN
				WB_control_buffer_out <= WB_control_buffer;
			END IF;
		END PROCESS;

		output : PROCESS (write_reg_txt)
			FILE memoryfile : text;
			VARIABLE line_num : line;
			VARIABLE fstatus : file_open_status;
			VARIABLE reg_value : std_logic_vector(31 DOWNTO 0);
		BEGIN
			IF (write_reg_txt = '1') THEN -- program ends
				REPORT "Start writing the memory.txt FILE";
				file_open(fstatus, memoryfile, "memory.txt", write_mode);
				FOR i IN 1 TO 8192 LOOP
					FOR j IN 1 TO 4 LOOP
						reg_value(8 * j - 1 DOWNTO 8 * j - 8) := ram_block(i * 4 + j - 5);
					END LOOP;
					--reg_value := outdata;
					write(line_num, reg_value);
					writeline(memoryfile, line_num);
				END LOOP;
				file_close(memoryfile);
				REPORT "Finish outputing the memory.txt";
			END IF;
		END PROCESS;
END behavior;
