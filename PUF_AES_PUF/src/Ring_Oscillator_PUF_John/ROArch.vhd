library ieee;
use ieee.std_logic_1164.all;

entity main is
    port(	input128		 	 	: in std_logic_vector(127 downto 0);
			resetComp				: in std_logic;
			chain_reset_bit 		: in std_logic; 
			boardTemp				: in std_logic_vector (6 downto 0);
			O					 	: out std_logic);
end entity;


architecture behav of main is
   
component ringOscillator is 
    port(	input : in std_logic;	
			reset : in std_logic;
			output : out std_logic);
end component;

component mux128_1 is
    port(input 			: in std_logic_vector(127 downto 0);
		 BoardSelect 	: in std_logic_vector(6 downto 0);
		 output 		: out std_logic);
--		 muxReady	  	: out std_logic);
end component;	  

component counterTest is
    port(	input		: in std_logic;
		  	output 		: out std_logic_vector (7 downto 0));
end component;	 

component compare_1out is
    port(inputTop : in std_logic_vector(7 downto 0);	
		 inputBot : in std_logic_vector(7 downto 0);
		 reset	  :in std_logic;
		 output   : out std_logic);
end component;


signal tempChainOutput		: std_logic_vector (127 downto 0)	:= (others => '0');	  
signal tempChainOutput2		: std_logic_vector (127 downto 0)	:= (others => '0');
signal tempMuxOutput 		: std_logic_vector (1 downto 0) 		:= (others => '0');  
signal tempCounterOutput 	: std_logic_vector (7 downto 0) 		:= (others => '0');
signal tempCounterOutput2	: std_logic_vector (7 downto 0)		:= (others => '0');		

--signal muxReady 				: std_logic_vector (1 downto 0)		:= (others => '0');

--signal input128 				: std_logic_vector (127 downto 0) 	:= x"ABCDEF1023456ABCD897412ABCDEF532";


begin 	
	
	GEN_RO1:
	for I in 0 to 127 generate
		ROX : ringOscillator port map
		(input128(I), chain_reset_bit, tempChainOutput(I));	 
	end generate GEN_RO1;	
	
	GEN_RO2:
	for I in 0 to 127 generate
		ROX2 : ringOscillator port map
		(input128(I), chain_reset_bit, tempChainOutput2(I));	 
	end generate GEN_RO2;
	
	
	M1 : mux128_1 port map(tempChainOutput, boardTemp, tempMuxOutput(0));
	M2 : mux128_1 port map(tempChainOutput2, boardTemp, tempMuxOutput(1));		 

	C1 : counterTest port map(tempMuxOutput(0), tempCounterOutput);
	C2 : counterTest port map(tempMuxOutput(1), tempCounterOutput2);
	
	CM : compare_1out port map(tempCounterOutput, tempCounterOutput2, resetComp, O);

end architecture;