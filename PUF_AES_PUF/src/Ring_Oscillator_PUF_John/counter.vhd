library ieee;
use ieee.std_logic_1164.all;  
use ieee.numeric_std.all;

entity counterTest is
    port(	input		: in std_logic;
		  	output 		: out std_logic_vector (7 downto 0));
end entity;

architecture behav of counterTest is
signal temp_num : integer := 0;
signal timesRan : integer := 0;
signal readySignal : std_logic := '0';
begin 
process(input)
begin	 	   
		readySignal <= input;
		if (readySignal = '1') then
			temp_num <= temp_num + 1;
			readySignal <= '0';
			timesran <= timesran + 1; 
		end if;
		if (timesran = 20) then
			output <= std_logic_vector(to_unsigned(temp_num, output'length));
			temp_num <= 0;
			timesran <= 0;
		end if;
		
end process;
end architecture;