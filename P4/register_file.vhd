LIBRARY IEEE;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE std.textio.ALL;
USE ieee.std_logic_textio.ALL;

ENTITY register_file IS
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
END register_file;

ARCHITECTURE Behav OF register_file IS

	TYPE registers IS ARRAY (0 TO 31) OF STD_LOGIC_VECTOR(31 DOWNTO 0); -- MIPS has 32 registers. Size of data is 32 bits. => 32x32bits
	SIGNAL register_store : registers := (OTHERS => "00000000000000000000000000000000"); -- initialize all registers to 32 bits of 0.

BEGIN
	PROCESS
	BEGIN
		IF (clock'event) THEN
			IF (unsigned(rs)) = "00000" THEN --register $0 is wired to 0x0000
				rs_data <= x"00000000";
			ELSE
				rs_data <= register_store(to_integer(unsigned(rs))); -- data of ra is now the data associated with rs's register index in the register_store
			END IF;

			IF (unsigned(rd)) = "00000" THEN --register $0 is wired to 0x0000
				rt_data <= x"00000000";
			ELSE
				rt_data <= register_store(to_integer(unsigned(rt)));
			END IF;

			IF (write_enable = '1') THEN -- if write_enable is high, we have permission to update the data of rd
				IF (to_integer(unsigned(rd)) = 0) THEN -- if we are trying to write to R0, then deny the write
					NULL;
				ELSE
					register_store(to_integer(unsigned(rd))) <= rd_data; -- access the appropriate register in the register_store, and assign it rd_data
				END IF;
			END IF;
		END IF;
	END PROCESS;

	PROCESS (writeToText)
	FILE register_file : text OPEN write_mode IS "register_file.txt";
	VARIABLE outLine : line;
	VARIABLE rowLine : INTEGER := 0;
	VARIABLE test : std_logic_vector(31 DOWNTO 0) := "00100000000000010000000000000001";

		BEGIN
			IF writeToText = '1' THEN

				WHILE (rowLine < 32) LOOP

				write(outLine, register_store(rowLine));
				writeline(register_file, outLine);
				rowLine := rowLine + 1;

			END LOOP;
		END IF;

		END PROCESS;
END Behav;
