library ieee;
use ieee.std_logic_1164.all;

entity DFlipFlop is
port(
	D,CLK  : in std_logic;
	Q      : out std_logic);
end DFlipFlop;

architecture Behavioral of DFlipFlop is
begin
	process(CLK)
	begin
		if(CLK='1' and CLK'event) then Q <= D;
		end if;
	end process;
end Behavioral;