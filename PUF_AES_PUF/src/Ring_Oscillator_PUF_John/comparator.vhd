library ieee;
use ieee.std_logic_1164.all;
USE ieee.numeric_std.ALL;

entity compare_1out is
    port(inputTop : in std_logic_vector(7 downto 0);	
		 inputBot : in std_logic_vector(7 downto 0);
		 reset	  :in std_logic;
		 output   : out std_logic);
end entity;


architecture behav of compare_1out is
--signal timesRan : integer := 0;	
begin		
process(inputTop,inputBot, reset)
begin		 
	
--	if(timesRan <= 2000) then
--		timesRan <= timesRan + 1;	

--	elsif (timesRan = 2000) then

		if (inputTop > inputBot) then 
			output <= '1';
		elsif (inputTop <= inputBot) then
			output <= '0';
		else
			output <= 'U';
		end if;		
--	end if;	   
	
	if(reset = '1') then
--		timesRan <= 0;
	end if;
		 
end process;
end architecture;
