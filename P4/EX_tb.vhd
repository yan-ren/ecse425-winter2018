library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

ENTITY EX_tb IS
END EX_tb;

ARCHITECTURE behav of EX_tb IS
	COMPONENT EX IS
		PORT(
			IR_addr_out : in std_logic_vector(31 DOWNTO 0);
			funct : in std_logic_vector(5 DOWNTO 0);
			opcode : in std_logic_vector(5 DOWNTO 0);
			rs: in std_logic_vector(31 downto 0);
			rt: in std_logic_vector(31 downto 0);
			signExtImm : in std_logic_vector(31 DOWNTO 0);
			result: out std_logic_vector(31 downto 0);
			des_addr_in : in std_logic_vector(4 DOWNTO 0);
			des_addr_out : OUT std_logic_vector(4 DOWNTO 0);
			bran_taken: out std_logic:= '0';
			jump_addr : in std_logic_vector(25 DOWNTO 0);
			branch_addr: out std_logic_vector(31 downto 0)
		);
	END COMPONENT;

	SIGNAL clock: STD_LOGIC := '0';
	CONSTANT clock_period : time := 1 ns;
	SIGNAL IR_addr_out :  std_logic_vector(31 DOWNTO 0);
	SIGNAL funct :  std_logic_vector(5 DOWNTO 0);
	SIGNAL opcode :  std_logic_vector(5 DOWNTO 0);
	SIGNAL rs:  std_logic_vector(31 downto 0);
	SIGNAL rt:  std_logic_vector(31 downto 0);
	SIGNAL signExtImm :  std_logic_vector(31 DOWNTO 0);
	SIGNAL result:  std_logic_vector(31 downto 0);
	SIGNAL des_addr_in :  std_logic_vector(4 DOWNTO 0);
	SIGNAL des_addr_out :  std_logic_vector(4 DOWNTO 0);
	SIGNAL bran_taken:std_logic:= '0';
	SIGNAL jump_addr :  std_logic_vector(25 DOWNTO 0);
	SIGNAL branch_addr:  std_logic_vector(31 downto 0);

BEGIN
	alutest : EX
	PORT MAP(
		IR_addr_out => IR_addr_out,
		funct => funct,
		opcode => opcode,
		rs=>rs,
		rt=>rt,
		signExtImm =>signExtImm,
		result=> result,
		des_addr_in => des_addr_in,
		des_addr_out => des_addr_out,
		bran_taken=> bran_taken,
		jump_addr => jump_addr,
		branch_addr=>branch_addr
	);

	clock_process : PROCESS
	BEGIN
		clock <= '1';
		wait for clock_period/2;
		clock <= '0';
		wait for clock_period/2;
	END PROCESS;

	test_process : PROCESS
	BEGIN
		wait for clock_period;

		-- ADD
		IR_addr_out <= "00000000000000000000000000000000";
		signExtImm <= "00000000000000000000000000000000";
		des_addr_in <= "00000";
		bran_taken <='0';
		rs <= "00000000000000000000000000000000";
		rt <= "00000000000000000000000000000001";
		opcode <= "000000";
		funct <= "100000";
		wait for clock_period;

		--SUBTRACT
		IR_addr_out <= "00000000000000000000000000000000";
		signExtImm <= "00000000000000000000000000000000";
		des_addr_in <= "00000";
		bran_taken <='0';
		rs <= "00000000000000000000000000000001";
		rt <= "00000000000000000000000000000001";
		opcode <= "000000";
		funct <= "100010";
		wait for clock_period;
			
	        --SLT
		IR_addr_out <= "00000000000000000000000000000000";
		signExtImm <= "00000000000000000000000000000000";
		des_addr_in <= "00000";
		bran_taken <='0';
		rs <= "00000000000000000000000000000001";
		rt <= "00000000000000000000000000000000";
		opcode <= "000000";
		funct <= "101010";
		wait for clock_period;
	

		
		WAIT;
	END PROCESS;
END behav;