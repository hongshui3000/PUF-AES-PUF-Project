library ieee;
use ieee.std_logic_1164.all;

entity MUX21 is 
	port(
		A   : in  std_logic;
		B   : in  std_logic;
		SEL : in  std_logic; --Current challenge bit
		Y   : out std_logic);
end MUX21;

architecture Behavior of MUX21 is
begin
	M1: process (A,B,SEL)
	begin
		if SEL = '0' then Y <= A;
		else Y <= B;
		end if;
	end process M1;
end Behavior; 