--ECSE 425 Lab 3 Cache Testbench
--Tara Tabet	260625552
--Shi Yu Liu	260683360
--Edward Yu	260------
--Ryan Ren	260------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cache_tb is
end cache_tb;

architecture behavior of cache_tb is

component cache is
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

    m_addr : out integer range 0 to ram_size-1;
    m_read : out std_logic;
    m_readdata : in std_logic_vector (7 downto 0);
    m_write : out std_logic;
    m_writedata : out std_logic_vector (7 downto 0);
    m_waitrequest : in std_logic
);
end component;

component memory is 
GENERIC(
    ram_size : INTEGER := 32768;
    mem_delay : time := 10 ns;
    clock_period : time := 1 ns
);
PORT (
    clock: IN STD_LOGIC;
    writedata: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
    address: IN INTEGER RANGE 0 TO ram_size-1;
    memwrite: IN STD_LOGIC;
    memread: IN STD_LOGIC;
    readdata: OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
    waitrequest: OUT STD_LOGIC
);
end component;
	
-- test signals 
signal reset : std_logic := '0';
signal clk : std_logic := '0';
constant clk_period : time := 1 ns;

signal s_addr : std_logic_vector (31 downto 0);
signal s_read : std_logic;
signal s_readdata : std_logic_vector (31 downto 0);
signal s_write : std_logic;
signal s_writedata : std_logic_vector (31 downto 0);
signal s_waitrequest : std_logic;

signal m_addr : integer range 0 to 2147483647;
signal m_read : std_logic;
signal m_readdata : std_logic_vector (7 downto 0);
signal m_write : std_logic;
signal m_writedata : std_logic_vector (7 downto 0);
signal m_waitrequest : std_logic; 

begin

-- Connect the components which we instantiated above to their
-- respective signals.
dut: cache 
port map(
    clock => clk,
    reset => reset,

    s_addr => s_addr,
    s_read => s_read,
    s_readdata => s_readdata,
    s_write => s_write,
    s_writedata => s_writedata,
    s_waitrequest => s_waitrequest,

    m_addr => m_addr,
    m_read => m_read,
    m_readdata => m_readdata,
    m_write => m_write,
    m_writedata => m_writedata,
    m_waitrequest => m_waitrequest
);

MEM : memory
port map (
    clock => clk,
    writedata => m_writedata,
    address => m_addr,
    memwrite => m_write,
    memread => m_read,
    readdata => m_readdata,
    waitrequest => m_waitrequest
);
				

clk_process : process
begin
  clk <= '0';
  wait for clk_period/2;
  clk <= '1';
  wait for clk_period/2;
end process;

test_process : process
begin
    
-- put your tests here
	
	--We will test for different combinations of {valid/invalid block, 
  --dirty/not dirty block, access is read/write, tag is equal/tag is not equal}
  --  
  --There are 16 test cases:
    -- #1:  {Valid, Dirty, Read, Tag Equal}
    -- #2:  {Valid, Dirty, Read, Tag Not Equal}
    -- #3:  {Valid, Dirty, Write, Tag Equal}
    -- #4:  {Valid, Dirty, Write, Tag Not Equal}
    -- #5:  {Valid, Not Dirty, Read, Tag Equal}
    -- #6:  {Valid, Not Dirty, Read, Tag Not Equal}
    -- #7:  {Valid, Not Dirty, Write, Tag Equal}
    -- #8:  {Valid, Not Dirty, Write, Tag Not Equal}
    -- #9:  {Invalid, Dirty, Read, Tag Equal}
    -- #10: {Invalid, Dirty, Read, Tag Not Equal}
    -- #11: {Invalid, Dirty, Write, Tag Equal}
    -- #12: {Invalid, Dirty, Write, Tag Not Equal}
    -- #13: {Invalid, Not Dirty, Read, Tag Equal}
    -- #14: {Invalid, Not Dirty, Read, Tag Not Equal}
    -- #15: {Invalid, Not Dirty, Write, Tag Equal}
    -- #16: {Invalid, Not Dirty, Write, Tag Not Equal}
    
    --Test cases 9, 10, 11 and 12 cannot be tested for since an invalid block cannot be dirty.
	s_write <= '0';
	s_read <= '0';
 	



	--Test Case #13 &14: reads an empty slot
		--If the cache invalid, the tag will automatically not match
		--since there is no data at the current index.
	s_addr <= "00000000000000000111000010111100";
	s_read <= '1';
	WAIT until s_waitrequest = '0';
	s_write <= '0';
	s_read <= '0';
	WAIT FOR 1*clk_period;
	
	
	--Test Case #15&16: writes to an empty slot with tag equal
		--If the cache invalid, the tag will automatically not match
		--since there is no data at the current index.
	s_addr <= "00000000000000000111000010111100";
	s_writedata <= "00110101001010001101010101010111";
	s_write <= '1';
	WAIT until s_waitrequest = '0';
	s_write <= '0';
	s_read <= '0';
	WAIT FOR 1*clk_period;
	
	--Test Case #1
	--reads info that has been written but not saved in memory
	s_addr <= "00000000000000000111000010111100";
	s_read <= '1';
	WAIT until s_waitrequest = '0';
	s_write <= '0';
	s_read <= '0';
	WAIT FOR 1*clk_period;
	
	--Test Case #2
	--reads info that has been written but not saved in memory with not equal tag
	s_addr <= "00000000000000000111010010111100";
	s_read <= '1';
	WAIT until s_waitrequest = '0';
	s_write <= '0';
	s_read <= '0';
	WAIT FOR 1*clk_period;
	
	--Test Case #4
	--write to a spot that already has info with not equal tag
	s_addr <= "00000000000000000111110010111100";
	s_writedata <= "00110101001010010001010101010111";
	s_write <= '1';
	WAIT until s_waitrequest = '0';
	s_write <= '0';
	s_read <= '0';
	WAIT FOR 1*clk_period;
	
	--Test Case #3
	--write to a spot that already has info 
	s_addr <= "00000000000000000111000010111100";
	s_writedata <= "00110101001010010001010101010111";
	s_write <= '1';
	WAIT until s_waitrequest = '0';
	s_write <= '0';
	s_read <= '0';
	WAIT FOR 1*clk_period;
	
	--Test Case #5
	--reads info that has been written but not saved in memory
	s_addr <= "00000000000000000111000010111100";
	s_read <= '1';
	WAIT until s_waitrequest = '0';
	s_write <= '0';
	s_read <= '0';
	WAIT FOR 1*clk_period;
	
	--Test Case #6
	--reads info that has been written but not saved in memory with not equal tag
	s_addr <= "00000000000000000111110010111100";
	s_read <= '1';
	WAIT until s_waitrequest = '0';
	s_write <= '0';
	s_read <= '0';
	WAIT FOR 1*clk_period;
	
	--Test Case #8
	--write to a spot that already has info with not equal tag
	s_addr <= "00000000000000000111110010111100";
	s_writedata <= "00110101001010010001010101010111";
	s_write <= '1';
	WAIT until s_waitrequest = '0';
	s_write <= '0';
	s_read <= '0';
	WAIT FOR 1*clk_period;
	
	--Test Case #7
	--write to a spot that already has info
	s_addr <= "00000000000000000111000010111100";
	s_writedata <= "00110101001010010001010101010111";
	s_write <= '1';
	WAIT until s_waitrequest = '0';
	s_write <= '0';
	s_read <= '0';
	WAIT FOR 1*clk_period;
	
	reset <= '1';
	WAIT FOR 3*clk_period;
	
end process;
	
end;