library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cache is
generic(
	ram_size : INTEGER := 32768;
);
port(
	clock : in std_logic;
	reset : in std_logic;
	
	-- Avalon interface --
	s_addr : in std_logic_vector (31 downto 0);
	s_read : in std_logic;
	s_readdata : out std_logic_vector (31 downto 0);
	s_write : in std_logic;
	s_writedata : in std_logic_vector (31 downto 0);
	s_waitrequest : out std_logic; 
    
	m_addr : out integer range 0 to ram_size-1;
	m_read : out std_logic;
	m_readdata : in std_logic_vector (7 downto 0);
	m_write : out std_logic;
	m_writedata : out std_logic_vector (7 downto 0);
	m_waitrequest : in std_logic
);
end cache;

architecture arch of cache is
--Address struct
--25 bits of tag
--5 bis of index
--2 bits of offset

-- Cache struct [32]
--1 bit valid
--1 bit dirty
--25 bit tag
--128 bit data(4 words)

-- sets up data in a cache block as an array of 4*32 bit vectors.
type data_array is array(3 downto 0) of STD_LOGIC_VECTOR (31 downto 0);

-- type tag_array is array (31 downto 0) of STD_LOGIC_VECTOR (24 downto 0);

-- sets cache block as a record with 1 dirty bit, 1 valid bit, and 4*32 data bits
type cache_block is record
	dirtyBit: std_logic;
	validBit: std_logic;
	tag: STD_LOGIC_VECTOR (24 downto 0);
	data: data_array;
end record;

-- sets entire cache as an array of 32 cache blocks
type cache_mem is array(31 downto 0) of cache_block;

type state_type is (INIT, IDLE, CHECK_TAG, CHECK_DIRTY_BIT, READ_MAIN_MEM, WRITE_MAIN_MEM, WRITE_CACHE, READ_CACHE);
signal state : state_type;
signal next_state : state_type;
signal cache_memory : cache_mem;


-- declare signals here



begin

-- make circuits here
cache_state_change: process (clock,s_read,s_write)
			     variable index : INTEGER;
begin
	index := to_integer(unsigned(s_addr(6 downto 2)));

	if (initialize = '1') then 
		state<=INIT;
	elsif(rising_edge(clock) and initialize ='0') then
		case state is
			when INIT=>
				state<=IDLE;
			when IDLE=>
				if((s_read xor s_write)='1') then
					state<=CHECK_TAG;
				end if;
			when CHECK_TAG=>
				-- hit and s_read
				if(cache_memory(index).validBit = '1' and cache_memory(index).tag = s_addr(31 downto 7) and s_read='1') then
					state<=READ_CACHE;
				-- hit and s_write
				elsif (cache_memory(index).validBit = '1' and cache_memory(index).tag = s_addr(31 downto 7) and s_write='1') then
					state<=WRITE_CACHE;
				-- miss
				else
					state<=CHECK_DIRTY_BIT;															
				end if;
			when CHECK_DIRTY_BIT=>
				if(cache_memory(index).dirtyBit='0' and s_read) then
					state<=READ_MAIN_MEM;
				elsif(cache_memory(index).dirtyBit='0' and s_write) then
					state<=WRITE_CACHE;
				-- write back
				elsif (cache_memory(index).dirtyBit='1' and s_read) then
					state<=WRITE_MAIN_MEM;
				elsif (cache_memory(index).dirtyBit='1' and s_write) then
					state<=WRITE_MAIN_MEM;
				end if;
			when WRITE_MAIN_MEM=>
				state<=READ_MAIN_MEM;
			when READ_MAIN_MEM=>
				if(((not DIRTY_BIT) and s_read and (not m_waitrequest))='1') then
					state<=IDLE;
				elsif (((not DIRTY_BIT) and s_write and (not m_waitrequest))='1') then
					state<=WRITE_CACHE;
				end if;
			when WRITE_CACHE=>
				state<=IDLE;
			when READ_CACHE=>
				state<=IDLE;
		end case;
	end if;
end process;

state_action: process (state,s_addr,m_readdata,s_writedata)
			variable index : INTEGER;
begin
	index := to_integer(unsigned(s_addr(6 downto 2)));
	case state is
		when INIT=>
			-- set all valid bits and dirty bits to 0 in INIT state
			for i in 0 to 31 loop
				cache_memory(i).validBit <= '0';
				cache_memory(i).dirtyBit <= '0';
			end loop;
			-- set initalize to zero so that we never enter this state again
			initialize<= '0';
		when IDLE=>
			-- set both cache wait request and memory wait request to 0
			s_waitrequest<='0';
			waitrequest<='0';
		when CHECK_TAG=>
			s_waitrequest<='1';
		when CHECK_DIRTY_BIT=>
			s_waitrequest<='1';
		when WRITE_MAIN_MEM=>
--			write_to_main_mem(cache_addr_to_mem_map(s_addr),s_writedata, writedata, address);
--			m_addr<= address;
--			m_write<='1';
--			if m_writedata exists
			s_waitrequest<='1';
		when READ_MAIN_MEM=>
--			address<=cache_addr_to_mem_map(s_addr);
--			m_read<='1';
--			for i in 0 to 3 loop
--				readdata<=m_readdata;
--				mem_burst_data(i)<=m_readdata;
--				address<=cache_addr_to_mem_map(s_addr)+32;
--			end loop;
--			write_to_cache_from_mm(mem_burst_data(0),mem_burst_data(1),mem_burst_data(2), mem_burst_data(3), c_writedata);
--			s_readdata<=c_writedata;
--			s_waitrequest<='1';
--			if m_readdata exists;
			DIRTY_BIT<='0';
		when WRITE_CACHE=>
			cache_memory(index).data(to_integer(unsigned(s_addr(1 downto 0))))<=s_writedata;
			DIRTY_BIT<='1';
			s_waitrequest<='1';
		when READ_CACHE=>
			s_readdata<=cache_memory(index).data(to_integer(unsigned(s_addr(1 downto 0))));
			s_waitrequest<='1';
	end case;
end process;
end arch;