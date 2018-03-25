LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY testbench IS
END testbench;

ARCHITECTURE behaviour OF testbench IS

	COMPONENT IF_STAGE IS
		GENERIC (
			ram_size : INTEGER := 4096
			--clock_period : time : 1 ns
		);
		PORT (
			clock : IN std_logic;
			reset : IN std_logic := '0';
			insert_stall : IN std_logic := '0';
			branch_addr : IN std_logic_vector (31 DOWNTO 0);
			branch_taken : IN std_logic := '0';
			next_addr : OUT std_logic_vector (31 DOWNTO 0);
			inst : OUT std_logic_vector (31 DOWNTO 0);
			readfinish : IN std_logic := '0'
		);
	END COMPONENT;

	COMPONENT ID IS
		GENERIC (
			register_size : INTEGER := 32
		);
		PORT (
			clk : IN std_logic;
			--hazard_detect: in std_logic; -- stall the instruction when hazard_detect is 1
			bran_taken_in : IN std_logic;-- from mem
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
			EX_control_buffer : OUT std_logic_vector(10 DOWNTO 0);
			MEM_control_buffer : OUT std_logic_vector(5 DOWNTO 0);
			WB_control_buffer : OUT std_logic_vector(5 DOWNTO 0);
			funct : OUT std_logic_vector(5 DOWNTO 0);
			opcode : OUT std_logic_vector(5 DOWNTO 0);
			write_enable : IN std_logic := '0'
		);
	END COMPONENT;

	COMPONENT EX IS
		PORT (
			clk : IN std_logic;

			-- from id stage
			instruction_addr : IN std_logic_vector(31 DOWNTO 0);
			jump_addr : IN std_logic_vector(25 DOWNTO 0); -- changed from 31 dwonto 0 to 25 down to 0
			rs : IN std_logic_vector(31 DOWNTO 0);
			rt : IN std_logic_vector(31 DOWNTO 0);
			des_addr : IN std_logic_vector(4 DOWNTO 0);
			signExtImm : IN std_logic_vector(31 DOWNTO 0);
			EX_control_buffer : IN std_logic_vector(10 DOWNTO 0); -- for ex stage provide information for forward and harzard detect, first bit for mem_read, 9-5 for rt, 4-0 for rs
			MEM_control_buffer : IN std_logic_vector(5 DOWNTO 0); -- for mem stage, provide info for forward and hazard detect, first bit for wb_signal, 4-0 for des_adr
			WB_control_buffer : IN std_logic_vector(5 DOWNTO 0); -- for mem stage, provide info for forward and hazard detect, first bit for wb_signal, 4-0 for des_adr
			opcode_in : IN std_logic_vector(5 DOWNTO 0);
			funct_in : IN std_logic_vector(5 DOWNTO 0);

			-- from mem stage
			MEM_control_buffer_before : IN std_logic_vector(5 DOWNTO 0); --control buffer from last instruction which is in mem stage now
			bran_taken_in : IN std_logic;-- from mem
			-- MEM_result: in std_logic_vector(31 downto 0); -- if last inst is load word, its data from mem
			-- last_opcode : in std_logic_vector(5 downto 0); -- opcode of last instruction

			-- from wb stage
			WB_control_buffer_before : IN std_logic_vector(5 DOWNTO 0); --control buffer from the one before last instruction which is in wb stage now
			writeback_data : IN std_logic_vector(31 DOWNTO 0); -- data for forwarding of last last instruction

			-- for mem stage
			branch_addr : OUT std_logic_vector(31 DOWNTO 0);
			bran_taken : OUT std_logic;
			opcode_out : OUT std_logic_vector(5 DOWNTO 0);
			des_addr_out : OUT std_logic_vector(4 DOWNTO 0);
			ALU_result : OUT std_logic_vector(31 DOWNTO 0);
			rt_data : OUT std_logic_vector(31 DOWNTO 0);
			MEM_control_buffer_out : OUT std_logic_vector(5 DOWNTO 0); -- for mem stage, provide info for forward and hazard detect, first bit for wb_signal, 4-0 for des_adr
			WB_control_buffer_out : OUT std_logic_vector(5 DOWNTO 0); -- for mem stage, provide info for forward and hazard detect, first bit for wb_signal, 4-0 for des_adr
			-- for id stage
			EX_control_buffer_out : OUT std_logic_vector(10 DOWNTO 0) -- for ex stage provide information for forward and harzard detect, first bit for mem_read, 9-5 for rt, 4-0 for rs
		);
	END COMPONENT;

	COMPONENT DataMem IS
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
		END COMPONENT;

		COMPONENT WB IS
			PORT (
				clk : IN std_logic;
				memory_data : IN std_logic_vector(31 DOWNTO 0);
				alu_result : IN std_logic_vector(31 DOWNTO 0);
				opcode : IN std_logic_vector(5 DOWNTO 0);
				writeback_addr : IN std_logic_vector(4 DOWNTO 0);
				WB_control_buffer : IN std_logic_vector(5 DOWNTO 0);
				-- for ex stage forward
				WB_control_buffer_out : OUT std_logic_vector(5 DOWNTO 0);
				-- for id stage
				writeback_data_out : OUT std_logic_vector(31 DOWNTO 0);
				writeback_addr_out : OUT std_logic_vector(4 DOWNTO 0)
			);
		END COMPONENT;
		---------------------------------------------------------------------------------
		SIGNAL clock : std_logic;
		SIGNAL programend : std_logic := '0';
		CONSTANT clock_period : TIME := 1 ns;
		SIGNAL readfinish : std_logic := '0';
		-- signal into if
		SIGNAL reset : std_logic;
		SIGNAL insert_stall : std_logic := '0';
		SIGNAL s_branch_addr : std_logic_vector (31 DOWNTO 0) := (OTHERS => '0');
		SIGNAL s_branch_taken : std_logic := '0';
		-- signal into id
		SIGNAL inst_addr : std_logic_vector (31 DOWNTO 0) := (OTHERS => '0');
		SIGNAL inst : std_logic_vector (31 DOWNTO 0) := (OTHERS => '0');
		SIGNAL writeback_register_address : std_Logic_vector(4 DOWNTO 0) := (OTHERS => '0');
		SIGNAL writeback_data : std_logic_vector(31 DOWNTO 0) := (OTHERS => '0'); -- also into ex, out of wb
		SIGNAL EX_control_buffer_from_ex : std_logic_vector(10 DOWNTO 0) := (OTHERS => '0');
		-- signal into ex
		-- from id
		SIGNAL jump_addr : std_logic_vector (25 DOWNTO 0) := (OTHERS => '0');
		SIGNAL inst_addr_from_id : std_logic_vector (31 DOWNTO 0) := (OTHERS => '0');
		SIGNAL rs : std_logic_vector(31 DOWNTO 0) := (OTHERS => '0');
		SIGNAL rt : std_logic_vector(31 DOWNTO 0) := (OTHERS => '0');
		SIGNAL des_addr_from_id : std_logic_vector(4 DOWNTO 0) := (OTHERS => '0');
		SIGNAL funct_from_id : std_logic_vector(5 DOWNTO 0) := (OTHERS => '0');
		SIGNAL signExtImm : std_logic_vector(31 DOWNTO 0) := (OTHERS => '0');
		SIGNAL opcode_bt_IdnEx : std_logic_vector(5 DOWNTO 0) := (OTHERS => '0'); -- out of id
		SIGNAL EX_control_buffer_from_id : std_logic_vector(10 DOWNTO 0) := (OTHERS => '0');
		SIGNAL MEM_control_buffer_from_id : std_logic_vector(5 DOWNTO 0) := (OTHERS => '0');
		SIGNAL WB_control_buffer_from_id : std_logic_vector(5 DOWNTO 0) := (OTHERS => '0');
		-- from mem and wb
		SIGNAL MEM_control_buffer_from_mem : std_logic_vector(5 DOWNTO 0) := (OTHERS => '0'); -- out of mem
		SIGNAL WB_control_buffer_from_wb : std_logic_vector(5 DOWNTO 0) := (OTHERS => '0'); -- out of wb
		-- singnal into ex end
		-- signal into mem
		SIGNAL opcode_bt_ExnMem : std_logic_vector(5 DOWNTO 0) := (OTHERS => '0'); -- out of ex
		SIGNAL ALU_result_from_ex : std_logic_vector(31 DOWNTO 0) := (OTHERS => '0');
		SIGNAL des_addr_from_ex : std_logic_vector(4 DOWNTO 0) := (OTHERS => '0');
		SIGNAL rt_data_from_ex : std_logic_vector(31 DOWNTO 0) := (OTHERS => '0');
		SIGNAL bran_taken_from_ex : std_logic := '0';
		SIGNAL bran_addr_from_ex : std_logic_vector(31 DOWNTO 0) := (OTHERS => '0');
		SIGNAL MEM_control_buffer_from_ex : std_logic_vector(5 DOWNTO 0) := (OTHERS => '0');
		SIGNAL WB_control_buffer_from_ex : std_logic_vector(5 DOWNTO 0) := (OTHERS => '0');
		-- signal into writeback
		SIGNAL opcode_bt_MemnWb : std_logic_vector(5 DOWNTO 0) := (OTHERS => '0'); -- out of mem
		SIGNAL memory_data : std_logic_vector(31 DOWNTO 0) := (OTHERS => '0');
		SIGNAL alu_result_from_mem : std_logic_vector(31 DOWNTO 0) := (OTHERS => '0');
		SIGNAL des_addr_from_mem : std_logic_vector(4 DOWNTO 0) := (OTHERS => '0'); -- writeback_addr in wb stage
		SIGNAL WB_control_buffer_from_mem : std_logic_vector(5 DOWNTO 0) := (OTHERS => '0'); -- from

		--signal EX_control_buffer: std_logic_vector(10 downto 0); -- not in use
		--signal MEM_control_buffer: std_logic_vector(5 downto 0); -- not in use
		--signal WB_control_buffer: std_logic_vector(5 downto 0); --not in use

		--------------------------------------------------------------------

	BEGIN
		fetch : IF_STAGE
			GENERIC MAP(
			ram_size => 4096
			)
			PORT MAP(
				clock => clock,
				reset => reset,
				insert_stall => insert_stall,
				branch_addr => s_branch_addr,
				branch_taken => s_branch_taken,
				next_addr => inst_addr,
				inst => inst,
				readfinish => readfinish
			);

				decode : ID
					GENERIC MAP(
					register_size => 32
					)
					PORT MAP(
						clk => clock,
						bran_taken_in => s_branch_taken,
						IR_addr => inst_addr,
						IR => inst,
						writeback_register_address => writeback_register_address,
						writeback_register_content => writeback_data, -- in
						ex_state_buffer => EX_control_buffer_from_ex,

						IR_addr_out => inst_addr_from_id,
						jump_addr => jump_addr,
						rs => rs,
						rt => rt,
						des_addr => des_addr_from_id,
						signExtImm => signExtImm,
						insert_stall => insert_stall,
						EX_control_buffer => EX_control_buffer_from_id,
						MEM_control_buffer => MEM_control_buffer_from_id,
						WB_control_buffer => WB_control_buffer_from_id,
						funct => funct_from_id,
						opcode => opcode_bt_IdnEx,
						write_enable => programend
					);

						execute : EX
						PORT MAP(
							clk => clock,
							bran_taken_in => s_branch_taken,
							instruction_addr => inst_addr_from_id,
							jump_addr => jump_addr,
							rs => rs,
							rt => rt,
							des_addr => des_addr_from_id,
							signExtImm => signExtImm,
							EX_control_buffer => EX_control_buffer_from_id,
							MEM_control_buffer => MEM_control_buffer_from_id,
							WB_control_buffer => WB_control_buffer_from_id,
							opcode_in => opcode_bt_IdnEx,
							funct_in => funct_from_id,
							MEM_control_buffer_before => MEM_control_buffer_from_mem, --in
							WB_control_buffer_before => WB_control_buffer_from_wb, --in
							writeback_data => writeback_data, --in
							branch_addr => bran_addr_from_ex, -- ?? -- added in mem (runze)
							bran_taken => bran_taken_from_ex,
							opcode_out => opcode_bt_ExnMem,
							des_addr_out => des_addr_from_ex,
							ALU_result => ALU_result_from_ex,
							rt_data => rt_data_from_ex,
							MEM_control_buffer_out => MEM_control_buffer_from_ex,
							WB_control_buffer_out => WB_control_buffer_from_ex,
							EX_control_buffer_out => EX_control_buffer_from_ex
		);

		memory : DataMem
		PORT MAP(
			clock => clock,
			opcode => opcode_bt_ExnMem,
			dest_addr_in => des_addr_from_ex,
			ALU_result => ALU_result_from_ex,
			rt_data => rt_data_from_ex,
			bran_taken => bran_taken_from_ex,
			bran_addr_in => bran_addr_from_ex,
			MEM_control_buffer => MEM_control_buffer_from_ex,
			WB_control_buffer => WB_control_buffer_from_ex,
			write_reg_txt => programend,
			MEM_control_buffer_out => MEM_control_buffer_from_mem,
			WB_control_buffer_out => WB_control_buffer_from_mem,
			mem_data => memory_data,
			ALU_data => ALU_result_from_mem,
			dest_addr_out => des_addr_from_mem,
			bran_addr => s_branch_addr,
			bran_taken_out => s_branch_taken
		);

		writeback : WB
		PORT MAP(
			clk => clock,
			memory_data => memory_data,
			alu_result => alu_result_from_mem,
			opcode => opcode_bt_MEmnWb,
			writeback_addr => des_addr_from_mem,
			WB_control_buffer => WB_control_buffer_from_mem,
			WB_control_buffer_out => WB_control_buffer_from_wb,
			writeback_addr_out => writeback_register_address,
			writeback_data_out => writeback_data
		);

		clk_process : PROCESS
		BEGIN
			clock <= '0';
			WAIT FOR clock_period/2;
			clock <= '1';
			WAIT FOR clock_period/2;
		END PROCESS;
		test_process : PROCESS
		BEGIN
			WAIT FOR 10000 * clock_period;
			programend <= '1';
			WAIT;
		END PROCESS;
END behaviour;
