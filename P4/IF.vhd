LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE STD.textio.all;
USE ieee.std_logic_textio.all;

ENTITY IF_STAGE IS
	GENERIC(
		ram_size : INTEGER := 4096
	);
	PORT(
		clock: IN STD_LOGIC;
		reset: in std_logic := '0';
		insert_stall: in std_logic := '0';
		BranchAddr: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		Branch_taken: IN STD_LOGIC := '0';
		next_addr: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
		inst: out std_logic_vector(31 downto 0);
    readfinish : in std_logic := '0'
	);
END IF_STAGE;

ARCHITECTURE behavioral of IF_STAGE IS
	TYPE MEM IS ARRAY(ram_size-1 downto 0) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL ram_block: MEM;
	signal pc: STD_LOGIC_VECTOR (31 DOWNTO 0):= (others => '0');
	signal pc_plus4: STD_LOGIC_VECTOR (31 DOWNTO 0):= (others => '0');
	signal inst_i: std_logic_vector(31 downto 0);
  signal max_inst: integer :=0;

begin
	--Read the 'program.txt' file into instruction memory
	readprogram: process (readfinish)
		file program: text;
		variable mem_line: line;
    variable fstatus: file_open_status;
		variable read_data: std_logic_vector(31 downto 0);
		variable char : character:='0';
    variable counter: integer := 0;
		begin
    	report "start read the program.txt file";
			file_open(fstatus,program,"program.txt", read_mode);
			while not endfile(program) loop
				readline(program,mem_line);
				read(mem_line,read_data); --32bits data
				for i in 1 to 4 loop
					ram_block(counter) <= read_data( 8*i-1 downto  8*i-8);
					counter := counter+1;
				end loop;
			end loop;
			file_close(program);
			report "finish reading the porgram.txt file and put them into memory";
    	max_inst <= counter - 4;
	end process;

  process (pc_plus4, Branch_taken)
    begin
    	if(Branch_taken = '1') and (insert_stall = '0')then
				pc <= BranchAddr;
			elsif  (insert_stall = '0') then
				pc <= pc_plus4;
      end if;
  end process;

	process (clock)
	begin
		if(falling_edge(clock)) then
			-- read data if not stall
			if (insert_stall = '0') then
				pc_plus4 <= std_logic_vector(to_unsigned( to_integer(unsigned(pc)) + 4,32));
				inst_i(31 downto 24) <= ram_block(to_integer(unsigned(pc))+3);
				inst_i(23 downto 16) <= ram_block(to_integer(unsigned(pc))+2);
				inst_i(15 downto 8) <= ram_block(to_integer(unsigned(pc))+1);
				inst_i(7 downto 0) <= ram_block(to_integer(unsigned(pc)));
        next_addr<= pc;
			end if;

		end if;
	end process;

	pass_inst:process(inst_i)
	begin
		if( to_integer(unsigned(pc)) > max_inst) then
    	inst <= x"00000020";
    else
			inst <= inst_i;
		end if;
	end process;
end behavioral;
