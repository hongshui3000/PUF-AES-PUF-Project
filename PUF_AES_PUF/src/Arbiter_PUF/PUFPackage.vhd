library ieee;
use ieee. std_logic_1164.all;

package PUFPackage is
	function DFlipFlop (D,CLK  : std_logic) return std_logic;
end package;

package body PUFPackage is
function DFlipFlop (D,CLK  : std_logic) return std_logic is
	variable Q : std_logic;
	begin
		if(CLK='1' and CLK'event) then Q := D;
		end if;
		return Q;
end function;


end package body;