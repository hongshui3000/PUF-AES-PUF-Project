 library ieee;
use ieee.std_logic_1164.all;

entity ringOscillator is 
    port(	input : in std_logic;	
			reset : in std_logic;
			output : out std_logic);
end entity;


architecture behav of ringOscillator is
		signal and_out 		: std_logic;
		signal not_out1		: std_logic;
		signal not_out2		: std_logic;
		signal not_final	: std_logic;
begin	  
	with reset select
    and_out	 	<=  (input AND reset) when '0',
					(NOT not_final) when '1',
					'0' when others;
					
	with and_out select
	not_out1	 	<=  '1' when '0',
						'0' when '1',
						'0' when others;
	
	with not_out1 select
	not_out2	 	<=  '1' when '0',
						'0' when '1',
						'0' when others;
		
	with not_out2 select
	not_final	 	<=  '1' when '0',
						'0' when '1',
						'0' when others;
		
	with not_final select
	output		 	<=  '0' when '0',
						'1' when '1',
						'0' when others;
		
	
	
--	process	
--	begin
--		if (reset = '0') then
--			and_out <= input AND reset;
--		end if;
--		
--			not_out1 <= NOT and_out;
--
--			not_out2 <= NOT not_out1;
--
--			not_final <= NOT not_out2;	 
--			
--			and_out <= not_final;
--			
--			output <= not_final; 
--	end process;
end architecture;
