LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE STD.textio.all;
USE ieee.std_logic_textio.all;

entity DataMem is
    GENERIC(
		ram_size : INTEGER := 32768
	);
    port(
         clock: in std_logic;
         opcode: in std_logic_vector(5 downto 0):=(others => '0');
         dest_addr_in: in std_logic_vector(4 downto 0):=(others => '0');
         ALU_result: in std_logic_vector(31 downto 0):=(others => '0');
         rt_data: in std_logic_vector(31 downto 0):=(others => '0');
	     bran_taken: in std_logic;  -- from mem
	     bran_addr_in: in std_logic_vector(31 downto 0):=(others => '0');  -- new added 
	     MEM_control_buffer: in std_logic_vector(5 downto 0):=(others => '0');
	     WB_control_buffer : in std_logic_vector(5 downto 0):=(others => '0');
	    
	     MEM_control_buffer_out: out std_logic_vector(5 downto 0):=(others => '0'); --for ex forward 
	     WB_control_buffer_out : out std_logic_vector(5 downto 0):=(others => '0'); -- for wb stage 
         
	     mem_data: out std_logic_vector(31 downto 0):=(others => '0');
         ALU_data: out std_logic_vector(31 downto 0):=(others => '0');
         dest_addr_out: out std_logic_vector(4 downto 0):=(others => '0');
         bran_addr: out std_logic_vector(31 downto 0):=(others => '0'); -- for if 
	     bran_taken_out: out std_logic:= '0';                -- for if 
	     write_reg_txt: in std_logic := '0' -- indicate program ends-- from testbench
	    
         );
end DataMem;

architecture behavior of DataMem is
    -- memory
    	TYPE MEM IS ARRAY(ram_size-1 downto 0) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL ram_block: MEM;
	-- output file
	--signal outdata: std_logic_vector(31 downto 0);
    
begin
 MEM_control_buffer_out<= MEM_control_buffer;


     process(clock)
     begin
	--This is a cheap trick to initialize the SRAM in simulation
	if(now < 1 ps)THEN
		For i in 0 to ram_size-1 LOOP
			ram_block(i) <= std_logic_vector(to_signed(0,8));
		END LOOP;
		report "Start initializing the data memory to zero";
	end if;

       if(rising_edge(clock))then
         	dest_addr_out <= dest_addr_in;
          	bran_addr <= bran_addr_in;
          	bran_taken_out<= bran_taken;
        
        	-- the opcode is for branch
        	--if(opcode = "000101" or opcode = "000100")then
        
			
        	-- the opcode is sw 
        	if(opcode = "101011")then
         	-- bran_addr <= std_logic_vector(to_unsigned(0, 32));
         		for i in 1 to 4 loop
             			ram_block((to_integer(signed(ALU_result))) + i - 1) <= rt_data(8*i - 1 downto 8*i - 8);
				report "rt_data is " & integer'image(to_integer(signed(rt_data(8*i - 1 downto 8*i - 8))));
				report "store successfully!";
         	 	end loop;
        	-- the opcode is lw 
        	elsif(opcode = "100011")then
       		--  bran_addr <= std_logic_vector(to_unsigned(0, 32));
          		for i in 0 to 3 loop
             			mem_data(8*i+7 downto 8*i) <= ram_block(to_integer(signed(ALU_result))+i);
         		end loop;
        	-- the opcode is other
        	else
       		-- bran_addr <= std_logic_vector(to_unsigned(0, 32));
        		ALU_data <= ALU_result;
        	end if;
	elsif(falling_edge(clock))then
		WB_control_buffer_out<= WB_control_buffer;
       	end if;
    end process;
	       
    output: process (write_reg_txt)
		file memoryfile : text;
		variable line_num : line;
		variable fstatus: file_open_status;
        	variable reg_value  : std_logic_vector(31 downto 0);
	begin
	if(write_reg_txt = '1') then -- program ends
		report "Start writing the memory.txt file";
		file_open(fstatus, memoryfile, "memory.txt", write_mode);
		for i in 1 to 8192 loop
			for j in 1 to 4 loop
				reg_value(8*j - 1 downto 8*j-8) := ram_block(i*4+j-5);
			end loop;
			--reg_value := outdata;
			write(line_num, reg_value);
			writeline(memoryfile, line_num);
		end loop;
		file_close(memoryfile);
		report "Finish outputing the memory.txt";
	end if;
	end process;	
end behavior;
