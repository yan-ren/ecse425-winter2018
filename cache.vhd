library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cache is
generic(
	ram_size : INTEGER := 32768
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

	state_thing : out integer;
  	send_data_packet_thing : out integer;
    	read_data_packet_thing : out integer;
	thing : out integer;
    
	m_addr : out integer range 0 to ram_size-1;
	m_read : out std_logic;
	m_readdata : in std_logic_vector (7 downto 0);
	m_write : out std_logic;
	m_writedata : out std_logic_vector (7 downto 0);
	m_waitrequest : in std_logic
);
end cache;

architecture arch of cache is
-- 32 bit address: only using lower 15 bits
-- 128 bit per block, main memory reads/writes in bytes: 4 bit offset
-- 32 bit word, 4 words per block, cache reads/writes in words: only using upper 2 bit offset
-- 32 blocks: 5 bit index
-- 15 - 4 - 5 = 6 bit tag
-- 1 dirty bit
-- 1 valid bit

-- implement the cache blocks into 4 words of 32 bits
type cache_words is array(3 downto 0) of std_logic_vector(31 downto 0);

-- cache slots as labeled above
type cache_block is record
	valid_bit: std_logic;
	dirty_bit: std_logic;
	tag: std_logic_vector(5 downto 0);
	cache_data: cache_words;
end record;

--cache structure as labeled above
type cache_struct_is is array(31 downto 0) of cache_block;

-- states of our FSM
type state_type is (RESET_CACHE, WAITING, CHECK_TAG_VALID, HIT, MISS, CACHE_READ, CACHE_WRITE,
							NOT_DIRTY, DIRTY, READ_MM, WRITE_MM);

-- declare signals here
signal state: state_type;
signal read_waitrequest: std_logic := '1';
signal write_waitrequest: std_logic := '1';
signal i : INTEGER := 0;
signal cache_struct: cache_struct_is;
signal send_data_packet : integer := 0;
signal read_data_packet : integer := 0;
signal send_data_counter : integer := 0;
signal read_data_counter : integer := 0;
signal send_temp_address : integer := 0;
signal read_temp_address : integer := 0;

signal mem_addr_from_cache : STD_LOGIC_VECTOR (14 downto 0);

begin

-- make circuits here
cache_FSM_do: process(clock, s_write, s_read, reset)
	variable index: INTEGER;

begin
	index := to_integer(unsigned(s_addr(8 downto 4)));
	s_waitrequest<= read_waitrequest and write_waitrequest;

	if (reset = '1') then -- Check for reset
		state <= RESET_CACHE;
	elsif (rising_edge(clock)) THEN -- If not reset, do...
		case state is
			when RESET_CACHE => -- Reset validity & dirty bits for each cache block
				state_thing<=0;
				for i in 0 to 31 loop
					cache_struct(i).valid_bit <= '0';
					cache_struct(i).dirty_bit <= '0';
				end loop;
				state <= WAITING;
			when WAITING => -- wait for when cache is called upon
				state_thing<=1;
				read_waitrequest <= '1';
				write_waitrequest <= '1';
				
				if (s_read = '1' or s_write = '1' ) then
					state <= CHECK_TAG_VALID;
				end if;
			when CHECK_TAG_VALID => -- checks for the address' validity in the intended index
				state_thing<=2;
				-- if valid and tag is a match: hit
				if (cache_struct(index).valid_bit = '1' and cache_struct(index).tag = s_addr(14 downto 9)) then
					state <= HIT;
				else -- else: miss
					state <= MISS;
				end if;
			when HIT => -- data in cache, reading or writing?
				state_thing<=3;
				if (s_read = '1' and s_write = '0') then
					state <= CACHE_READ;
				elsif (s_read = '0' and s_write = '1') then
					state <= CACHE_WRITE;
				end if;
			when MISS => -- check if the data in cache is dirty
				state_thing<=4;
				send_data_packet <= 0;
		  		read_data_packet <= 0;
				send_data_counter <= 0;
		  		read_data_counter <= 0;
				read_data_packet_thing<=read_data_counter;
				mem_addr_from_cache <= s_addr (14 downto 4)&"0000";	
				send_data_packet_thing <= to_integer(unsigned(mem_addr_from_cache));
				read_temp_address <= to_integer(unsigned(mem_addr_from_cache));
				if (cache_struct(index).dirty_bit = '0') then
					state <= NOT_DIRTY;
				elsif (cache_struct(index).dirty_bit = '1') then
					state <= DIRTY;
				end if;
			when CACHE_READ =>
				state_thing<=5;
				-- get the data from the block array[s_addr(3 downto 2)]
				s_readdata <= cache_struct(index).cache_data(to_integer(unsigned(s_addr(3 downto 2))));
				read_waitrequest <= '0';
				state <= WAITING;
			when CACHE_WRITE =>
				state_thing<=6;
				-- write the data to the block array[s_addr(3 downto 2)]
				cache_struct(index).cache_data(to_integer(unsigned(s_addr(3 downto 2)))) <= s_writedata;
				cache_struct(index).tag <= s_addr(14 downto 9);
				cache_struct(index).dirty_bit <= '1';
				write_waitrequest <= '0';
				state <= WAITING;
			when NOT_DIRTY =>
				state_thing<=7;
				state <= READ_MM;
			when DIRTY =>
				state_thing<=8;
				state <= WRITE_MM;
			when READ_MM =>
				state_thing<=9;
				m_read <= '0';
				m_write <= '0';

				
				if(read_data_packet = 4) then
					cache_struct(index).valid_bit <= '1';
					state<=HIT;
				end if;

				mem_addr_from_cache <= s_addr (14 downto 4)&"0000";	
				send_data_packet_thing <= to_integer(unsigned(mem_addr_from_cache));
				if((read_data_counter=0) and (read_data_packet = 0)) then
					
					--mem_addr_from_cache <= s_addr (14 downto 4)&"0000";
					send_data_packet_thing <= to_integer(unsigned(mem_addr_from_cache));
					read_temp_address <= to_integer(unsigned(mem_addr_from_cache));
				
					read_data_counter <= read_data_counter + 1;
					m_addr <= read_temp_address;
					m_read <= '1'after 1ns, '0' after 2ns;
					cache_struct(index).cache_data(0)(7 downto 0) <= m_readdata;
					read_data_packet_thing<=read_data_counter;
					
				end if;

				if(m_waitrequest='0') then				
				
					--mem_addr_from_cache <= s_addr (14 downto 4)&"0000";	
					send_data_packet_thing <= to_integer(unsigned(mem_addr_from_cache));

					

					if(read_data_packet < 4) then
					
						read_temp_address <= to_integer(unsigned(mem_addr_from_cache)) + (read_data_packet*4) +read_data_counter;

		

						m_addr <= read_temp_address;
						read_data_packet_thing<=read_data_counter;
						cache_struct(index).cache_data(read_data_packet)((7+(read_data_counter*8)) downto (read_data_counter*8)) <= m_readdata;
						read_data_counter <= read_data_counter + 1;
						m_read <= '1' after 1ns, '0' after 2ns;
						
						read_data_packet_thing<=read_data_counter;
					end if;
					
				end if;		
				
				
				
				if(read_data_counter = 4) then
					read_data_packet <= read_data_packet + 1;
					read_data_counter <= 0;
				end if;

			when WRITE_MM =>
				state_thing<=10;
				m_read <= '0';
				m_write <= '0';
				

				if(send_data_packet = 4) then
					cache_struct(index).dirty_bit <= '0';
					state<=READ_MM;
				end if;

				mem_addr_from_cache <= s_addr (14 downto 4)&"0000";

				if((send_data_counter=0) and (send_data_packet = 0)) then
					
					send_temp_address <= to_integer(unsigned(mem_addr_from_cache));
					send_data_counter <= send_data_counter + 1;
					m_addr <= send_temp_address;
					m_write <= '1' after 1ns, '0' after 2ns;
					m_writedata <= cache_struct(index).cache_data(0)(7 downto 0);
					
				end if;

				if(m_waitrequest='0') then					
				
					--mem_addr_from_cache <= s_addr (14 downto 4)&"0000";	

					if(send_data_packet < 4) then
					
						send_temp_address <= to_integer(unsigned(mem_addr_from_cache)) + send_data_packet*4 +send_data_counter;
					
						
						m_addr <= send_temp_address;
						m_writedata <= cache_struct(index).cache_data(send_data_packet)(7+send_data_counter*8 downto send_data_counter*8);
						send_data_counter <= send_data_counter + 1;
						m_write <= '1' after 1ns, '0' after 2ns;
						
					end if;
				end if;
				if(send_data_counter =4) then
					
					send_data_packet <= send_data_packet + 1;
					send_data_counter <= 0;
				end if;

		end case;
	end if;
			
end process;	

end arch;
