LIBRARY ieee;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY ID IS
	PORT (
		clk : IN std_logic;
		opcode : IN std_logic_vector(5 DOWNTO 0);
		funct : IN std_logic_vector(5 DOWNTO 0);
		branch : IN std_logic;
		oldBranch : IN std_logic;
		ALU1src : OUT STD_LOGIC;
		ALU2src : OUT STD_LOGIC;
		MemRead : OUT STD_LOGIC;
		MemWrite : OUT STD_LOGIC;
		RegWrite : OUT STD_LOGIC;
		MemToReg : OUT STD_LOGIC;
		RType : OUT STD_LOGIC;
		JType : OUT STD_LOGIC;
		Shift : OUT STD_LOGIC;
		structuralStall : OUT STD_LOGIC;
		ALUOp : OUT STD_LOGIC_VECTOR(4 DOWNTO 0)
	);
END ID;

ARCHITECTURE ID_arch OF ID IS

BEGIN
	PROCESS (opcode, funct)
	BEGIN
		--Send empty ctrl insturctions
		IF (branch = '1') OR (oldBranch = '1') THEN
			ALU1src <= '0';
			ALU2src <= '0';
			MemRead <= '0';
			MemWrite <= '0';
			RegWrite <= '0';
			MemToReg <= '0';
			ALUOp <= "00000";
			RType <= '1';
			Shift <= '0';
			JType <= '0';
			structuralStall <= '0';
		ELSE

			CASE opcode IS
				-- SLL PADED BY SIGN EXTEND TO DO OUTPUT 17
				WHEN "000000" =>
					IF funct = "000000" THEN
						ALU1src <= '0';
						ALU2src <= '0';
						MemRead <= '0';
						MemWrite <= '0';
						RegWrite <= '1';
						MemToReg <= '0';
						ALUOp <= "10001";
						RType <= '1';
						Shift <= '1';
						JType <= '0';
						structuralStall <= '0';

						--SUB OUTPUT 1
					ELSIF funct = "100010" THEN
						ALU1src <= '0';
						ALU2src <= '1';
						MemRead <= '0';
						MemWrite <= '0';
						RegWrite <= '1';
						MemToReg <= '0';
						ALUOp <= "00001";
						RType <= '1';
						Shift <= '0';
						JType <= '0';
						structuralStall <= '0';

						--XOR OUTPUT 10
					ELSIF funct = "101000" THEN
						ALU1src <= '0';
						ALU2src <= '1';
						MemRead <= '0';
						MemWrite <= '0';
						RegWrite <= '1';
						MemToReg <= '0';
						ALUOp <= "01010";
						RType <= '1';
						Shift <= '0';
						structuralStall <= '0';

						--AND OUTPUT 7
					ELSIF funct = "100100" THEN
						ALU1src <= '0';
						ALU2src <= '1';
						MemRead <= '0';
						MemWrite <= '0';
						RegWrite <= '1';
						MemToReg <= '0';
						ALUOp <= "00111";
						RType <= '1';
						Shift <= '0';
						JType <= '0';
						structuralStall <= '0';

						--ADD OUTPUT 0
					ELSIF funct = "100000" THEN
						ALU1src <= '0';
						ALU2src <= '1';
						MemRead <= '0';
						MemWrite <= '0';
						RegWrite <= '1';
						MemToReg <= '0';
						ALUOp <= "00000";
						RType <= '1';
						Shift <= '0';
						JType <= '0';
						structuralStall <= '0';

						--SLT OUTPUT 5
					ELSIF funct = "101010" THEN
						ALU1src <= '0';
						ALU2src <= '1';
						MemRead <= '0';
						MemWrite <= '0';
						RegWrite <= '1';
						MemToReg <= '0';
						ALUOp <= "00101";
						RType <= '1';
						Shift <= '0';
						JType <= '0';
						structuralStall <= '0';

						--SRL PADED BY SIGN EXTEND OUTPUT 18
					ELSIF funct = "000010" THEN
						ALU1src <= '0';
						ALU2src <= '0';
						MemRead <= '0';
						MemWrite <= '0';
						RegWrite <= '1';
						MemToReg <= '0';
						ALUOp <= "10010";
						RType <= '1';
						Shift <= '1';
						JType <= '0';
						structuralStall <= '0';

						--OR OUTPUT 8
					ELSIF funct = "100101" THEN
						ALU1src <= '0';
						ALU2src <= '1';
						MemRead <= '0';
						MemWrite <= '0';
						RegWrite <= '1';
						MemToReg <= '0';
						ALUOp <= "01000";
						RType <= '1';
						Shift <= '0';
						JType <= '0';
						structuralStall <= '0';

						--NOR OUTPUT 9
					ELSIF funct = "100111" THEN
						ALU1src <= '0';
						ALU2src <= '1';
						MemRead <= '0';
						MemWrite <= '0';
						RegWrite <= '1';
						MemToReg <= '0';
						ALUOp <= "01001";
						RType <= '1';
						Shift <= '0';
						JType <= '0';
						structuralStall <= '0';

						--JUMP REGISTER OUTPUT 25
					ELSIF funct = "001000" THEN
						ALU1src <= '0';
						ALU2src <= '0';
						MemRead <= '0';
						MemWrite <= '0';
						RegWrite <= '0';
						MemToReg <= '0';
						ALUOp <= "11001";
						RType <= '1';
						Shift <= '0';
						JType <= '1';
						structuralStall <= '0';

						-- DIVIDING OUTPUT 4
					ELSIF funct = "011010" THEN
						ALU1src <= '0';
						ALU2src <= '1';
						MemRead <= '0';
						MemWrite <= '0';
						RegWrite <= '1';
						MemToReg <= '0';
						ALUOp <= "00100";
						RType <= '1';
						Shift <= '0';
						JType <= '0';
						structuralStall <= '0';

						-- MULT OUTPUT 3
					ELSIF funct = "011000" THEN
						ALU1src <= '0';
						ALU2src <= '1';
						MemRead <= '0';
						MemWrite <= '0';
						RegWrite <= '1';
						MemToReg <= '0';
						ALUOp <= "00011";
						RType <= '1';
						Shift <= '0';
						JType <= '0';
						structuralStall <= '0';

						--SRA OUTPUT 18
					ELSIF funct = "000011" THEN
						ALU1src <= '0';
						ALU2src <= '0';
						MemRead <= '0';
						MemWrite <= '0';
						RegWrite <= '1';
						MemToReg <= '0';
						ALUOp <= "10010";
						RType <= '1';
						JType <= '0';
						structuralStall <= '0';

						-- TO DO HIGH OUTPUT 14
					ELSIF funct = "001010" THEN
						ALU1src <= '0';
						ALU2src <= '1';
						MemRead <= '0';
						MemWrite <= '0';
						RegWrite <= '1';
						MemToReg <= '0';
						ALUOp <= "01110";
						RType <= '1';
						Shift <= '1';
						JType <= '0';
						structuralStall <= '0';

						--TO DO LOW OUTPUT 15
					ELSIF funct = "001100" THEN
						ALU1src <= '0';
						ALU2src <= '1';
						MemRead <= '0';
						MemWrite <= '0';
						RegWrite <= '1';
						MemToReg <= '0';
						ALUOp <= "01111";
						RType <= '1';
						Shift <= '0';
						JType <= '0';
						structuralStall <= '0';

					END IF;

					--ADDI OUTPUT 2
				WHEN "001000" =>
					ALU1src <= '0';
					ALU2src <= '0';
					MemRead <= '0';
					MemWrite <= '0';
					RegWrite <= '1';
					MemToReg <= '0';
					ALUOp <= "00010";
					RType <= '0';
					Shift <= '0';
					JType <= '0';
					structuralStall <= '0';

					--SLTI OUTPUT 6
				WHEN "001010" =>
					ALU1src <= '0';
					ALU2src <= '0';
					MemRead <= '0';
					MemWrite <= '0';
					RegWrite <= '1';
					MemToReg <= '0';
					ALUOp <= "00110";
					RType <= '0';
					Shift <= '0';
					JType <= '0';
					structuralStall <= '0';

					--ANDI OUTPUT 11
				WHEN "001100" =>
					ALU1src <= '0';
					ALU2src <= '0';
					MemRead <= '0';
					MemWrite <= '0';
					RegWrite <= '1';
					MemToReg <= '0';
					ALUOp <= "01011";
					RType <= '0';
					Shift <= '0';
					JType <= '0';
					structuralStall <= '0';

					--ORI OUTPUT 12

				WHEN "001101" =>
					ALU1src <= '0';
					ALU2src <= '0';
					MemRead <= '0';
					MemWrite <= '0';
					RegWrite <= '1';
					MemToReg <= '0';
					ALUOp <= "01100";
					RType <= '0';
					Shift <= '0';
					JType <= '0';
					structuralStall <= '0';

					--XORI OUTPUT 13

				WHEN "001110" =>
					ALU1src <= '0';
					ALU2src <= '0';
					MemRead <= '0';
					MemWrite <= '0';
					RegWrite <= '1';
					MemToReg <= '0';
					ALUOp <= "01101";
					RType <= '0';
					Shift <= '0';
					JType <= '0';
					structuralStall <= '0';

					--LUI OUTPUT 16

				WHEN "001111" =>
					ALU1src <= '0';
					ALU2src <= '0';
					MemRead <= '0';
					MemWrite <= '0';
					RegWrite <= '1';
					MemToReg <= '0';
					ALUOp <= "10000";
					RType <= '0';
					Shift <= '0';
					JType <= '0';
					structuralStall <= '0';
					-- LW OUTPUT 20
				WHEN "100011" =>
					ALU1src <= '0';
					ALU2src <= '0';
					MemRead <= '1';
					MemWrite <= '0';
					RegWrite <= '1';
					MemToReg <= '1';
					ALUOp <= "10100";
					RType <= '0';
					Shift <= '0';
					JType <= '0';
					structuralStall <= '1';

					-- Store OUTPUT 21

				WHEN "101011" =>
					ALU1src <= '0';
					ALU2src <= '0';
					MemRead <= '0';
					MemWrite <= '1';
					RegWrite <= '0';
					MemToReg <= '1';
					ALUOp <= "10101";
					RType <= '0';
					Shift <= '0';
					JType <= '0';
					structuralStall <= '0';

					-- BEQ OUTPUT 22
				WHEN "000100" =>
					ALU1src <= '1';
					ALU2src <= '0';
					MemRead <= '0';
					MemWrite <= '0';
					RegWrite <= '0';
					MemToReg <= '0';
					ALUOp <= "10110";
					RType <= '0';
					Shift <= '0';
					JType <= '0';
					structuralStall <= '0';

					--BNE OUTPUT 23

				WHEN "000101" =>
					ALU1src <= '1';
					ALU2src <= '0';
					MemRead <= '0';
					MemWrite <= '0';
					RegWrite <= '0';
					MemToReg <= '0';
					ALUOp <= "10111";
					RType <= '0';
					Shift <= '0';
					JType <= '0';
					structuralStall <= '0';

					-- JUMP OUTPUT 24

				WHEN "000010" =>
					ALU1src <= '1';
					ALU2src <= '0';
					MemRead <= '0';
					MemWrite <= '0';
					RegWrite <= '0';
					MemToReg <= '0';
					ALUOp <= "11000";
					RType <= '0';
					Shift <= '0';
					JType <= '1';
					structuralStall <= '0';

					-- JUMP AND LINK OUTPUT 26
				WHEN "000011" =>
					ALU1src <= '1';
					ALU2src <= '0';
					MemRead <= '0';
					MemWrite <= '0';
					RegWrite <= '1';
					MemToReg <= '0';
					ALUOp <= "11010";
					RType <= '0';
					Shift <= '0';
					JType <= '1';
					structuralStall <= '0';

				WHEN OTHERS =>

			END CASE;
		END IF;
	END PROCESS;

END ID_arch;
