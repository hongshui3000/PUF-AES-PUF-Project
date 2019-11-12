library ieee;
use ieee.std_logic_1164.all;
USE ieee.numeric_std.ALL;

entity PUF_AES_PUF is 
generic (BitWidth : integer := 128;
			MaxChalllenges : integer := 104); --108=MAX for DE10 Standard's 50Hz clock cycle
	port(
		CLK        			: in  std_logic;
		RST        			: in  std_logic;
		MODE     			: in  std_logic_vector(1 downto 0); --SW0.Sw1
		Keys     			: in  std_logic_vector(2 downto 0); --Key0.Key1,Key2
		SWro     			: in  std_logic; --SW2
		SW     			   : in  std_logic_vector(2 downto 0); --SW2,SW9.Sw8,Sw7
		H0,H1,H2,H3,H4,H5 : out std_logic_vector(0 to 6); --7Segment Displays
		Response  			: out std_logic_vector(BitWidth-1 downto 0);
		Done 	     			: out std_logic := '1');
end entity;

architecture Structural of PUF_AES_PUF is
-------------------------------------------------------------------------------
-- Component Instantiations
-------------------------------------------------------------------------------
	--Arbiter PUF
	component ArbiterPUF
		generic (BitWidth : integer;
					MaxChalllenges : integer);
		port(
			CLK        : in  std_logic;
			RST        : in  std_logic;
			Input	     : in  std_logic;  --initial input bit for MUX
			Challenge  : in  std_logic_vector(BitWidth-1 downto 0);  --N-bit Challenge 
			Response   : out std_logic);
	end component;

	-- Linear Feedback Shift Register (LFSR)
	component lfsr_n
		generic(constant N  : integer);
		port (
			clk			:in  std_logic;                    
			reset		:in  std_logic;                    
			lfsr_out	:out std_logic_vector (N-1 downto 0));
	end component;

	--Ring Oscillator
--	component ROArch128 is
--	port(input128		 	 	: in std_logic_vector(127 downto 0);
--			resetComp				: in std_logic;
--			chain_reset_bit 		: in std_logic; 
--			boardTemp				: in std_logic_vector (6 downto 0);
--			O					 	: out std_logic_vector(127 downto 0));
--	end component;

	--Rijndael AES
	component AES
		Port( 
			clk    		: in  STD_LOGIC;
			plaintext 	: in  STD_LOGIC_VECTOR (127 downto 0);
			key         : in  STD_LOGIC_VECTOR (127 downto 0);
			cyphertext  : out STD_LOGIC_VECTOR (127 downto 0));
	end component;
	
-------------------------------------------------------------------------------
-- Signals, Constants, Attributes
-------------------------------------------------------------------------------
	signal C     		      : std_logic_vector(BitWidth-1 downto 0);-- := x"4f53742927575e5538515e437b9156a8";  --Random Challenge key generated from  http://www.andrewscompanies.com/tools/wep.asp
	signal aKey   		   	: std_logic_vector(BitWidth-1 downto 0) := x"5d2212345ccdaa9898000b277ef988ab";  --5d2212345ccdaa9898000b277ef97069
	signal PUFR1 		   	: std_logic_vector(BitWidth-1 downto 0);
	signal PUFR2 		   	: std_logic_vector(BitWidth-1 downto 0);
	signal AESCT 		   	: std_logic_vector(BitWidth-1 downto 0);
	signal State  		   	: integer := 0;
	signal d5,d4            : std_logic_vector(0 to 6);
	signal d3,d2,d1,d0   	: std_logic_vector(3 downto 0);
	signal ClockIn       	: std_logic := '1';
	signal input128 			: std_logic_vector (127 downto 0) 	:= x"ABCDEF1023456ABCD897412ABCDEF532";	
--	attribute keep: boolean;
--	attribute noprune: boolean;
--	attribute preserve: boolean;
--	attribute keep of PUF_AES_PUF: entity is true;
--	attribute noprune of PUF_AES_PUF: entity is true;
--	attribute preserve of PUF_AES_PUF: entity is true;

-------------------------------------------------------------------------------
-- Architecture [PUF-AES-PUF Component Paring]
-------------------------------------------------------------------------------
begin	
-- ArbiterPUF_AES_ArbiterPUF Component Paring
	GEN:
	for i in 0 to (Bitwidth-1) generate
			--Call LFSR to generate a unique 128-bit challenge(C) for the current MUX-pair sequence
			--C1  : lfsr_n generic map(N=>BitWidth) port map(clk=>CLK, reset=>RST, lfsr_out=>C);
						 
			--Call ArbiterPUF to generate a response bit
			P1  : ArbiterPUF generic map (BitWidth=>BitWidth, MaxChalllenges=>MaxChalllenges)        
			      port map(CLK=>ClockIn, RST=>RST, Input=>ClockIn, Challenge=>C,Response=>PUFR1(i));
			Response(i)<=PUFR1(i);
	end generate GEN;
	
	A1: AES port map(clk=>CLK, plaintext=>PUFR1, key=>aKey, cyphertext=>AESCT);
	
	GEN2:
	for i in 0 to (BitWidth-1) generate
			--Call LFSR to generate a unique 128-bit challenge(C) for the current MUX-pair sequence
			--C2  : lfsr_n generic map(N=>BitWidth) port map(clk=>CLK, reset=>RST, lfsr_out=>C);
						 
			--Call ArbiterPUF to generate a response bit
			P2  : ArbiterPUF generic map (BitWidth=>BitWidth, MaxChalllenges=>MaxChalllenges) 
					port map(CLK=>ClockIn, RST=>RST, Input=>AESCT(i), Challenge=>C,Response=>PUFR2(i));
			Response(i)<=PUFR1(i);
	end generate GEN2;
-- End of Paring

-- ROPUF_AES_ROPUF Component Paring
--	P1 : ROArch128 port map(input128, Keys(0), SWro, "0101011", PUFR1);
--	A1: AES port map(clk=>CLK, plaintext=>PUFR1, key=>aKey, cyphertext=>AESCT);
--	P2 : ROArch128 port map(AESCT, Keys(0), SWro,"0001111", PUFR2);
-- End of Paring

	process(CLK)
	begin
		if (rising_edge(CLK)) then
			ClockIn <= not ClockIn;
		end if;
	end process;
	
-------------------------------------------------------------------------------
--DE10 Standard Output to 7-Segment displays 
-------------------------------------------------------------------------------
--The 128-bit PUF1 response key, AES ciphertext, and PUF2 response key is 
--divided into 8 sections and displayed 16-bits at a time across 4 7-Segment
--displays. The outputs are in Hexadecimal

--The 4-bit nibbles of the 3 outputs are displayed from LSB to MSB from 
--HEX0 to HEX3 on the DE10 FPGA.

--Switches 0 and 1 determine which output to display on the 7-Segment displays.
--The 2-bit combinations are represented as MODEs

--MODE "00" displays PUF1's response key
--MODE "01" displays AES ciphertext
--MODE "10" displays PUF2's response key

--Switches 7,8,and 9 determine which 16-bit section of an output to display.

--HEX5 represents the current section of an output
--HEX4 is not used and outputs a "-"

	--DE10 Standard Output Test
	process(MODE, SW)
	begin
		case MODE is
			when "00" =>			--Output PUFR1
				State <= to_integer(unsigned(SW));
				H5 <= d5;
				H4 <= d4;
			when "01" =>			--Output AES Cyphertext
				State <= to_integer(unsigned(SW));
				H5 <= d5;
				H4 <= d4;
			when "10" =>			--Output PUFR2
				State <= to_integer(unsigned(SW));
				H5 <= d5;
				H4 <= d4;
			when others =>
				H5 <= (others => '0');
				H4 <= (others => '0');
		end case;
	end process;
	
	process(State,d4,d3,d2,d1,d0)
	begin
	
		if (MODE = "00") then
			case State is
			 --             "ABCDEFG"
				when 0 => 
					d5 <= not "1111110";	-- 0
					d4 <= not "0000001";	-- -(Dash)
					d3 <= PUFR1(127 downto 124);
					d2 <= PUFR1(123 downto 120);
					d1 <= PUFR1(119 downto 116);
					d0 <= PUFR1(115 downto 112);
				when 1 => 
					d5 <= not "0110000";	-- 1
					d4 <= not "0000001";	-- -(Dash)
					d3 <= PUFR1(111 downto 108);
					d2 <= PUFR1(107 downto 104);
					d1 <= PUFR1(103 downto 100);
					d0 <= PUFR1(99 downto 96);
				when 2 => 
					d5 <= not "1101101";	-- 2
					d4 <= not "0000001";	-- -(Dash)
					d3 <= PUFR1(95 downto 92);
					d2 <= PUFR1(91 downto 88);
					d1 <= PUFR1(87 downto 84);
					d0 <= PUFR1(83 downto 80);
				when 3 => 
					d5 <= not "1111001";	-- 3
					d4 <= not "0000001";	-- -(Dash)
					d3 <= PUFR1(79 downto 76);
					d2 <= PUFR1(75 downto 72);
					d1 <= PUFR1(71 downto 68);
					d0 <= PUFR1(67 downto 64);
				when 4 => 
					d5 <= not "0110011";	-- 4
					d4 <= not "0000001";	-- -(Dash)
					d3 <= PUFR1(63 downto 60);
					d2 <= PUFR1(59 downto 56);
					d1 <= PUFR1(55 downto 52);
					d0 <= PUFR1(51 downto 48);
				when 5 => 
					d5 <= not "1011011";	-- 5
					d4 <= not "0000001";	-- -(Dash)
					d3 <= PUFR1(47 downto 44);
					d2 <= PUFR1(43 downto 40);
					d1 <= PUFR1(39 downto 36);
					d0 <= PUFR1(35 downto 32);
				when 6 => 
					d5 <= not "1011111";	-- 6
					d4 <= not "0000001";	-- -(Dash)
					d3 <= PUFR1(31 downto 28);
					d2 <= PUFR1(27 downto 24);
					d1 <= PUFR1(23 downto 20);
					d0 <= PUFR1(19 downto 16);
				when 7 => 
					d5 <= not "1110000";	-- 7
					d4 <= not "0000001";	-- -(Dash)
					d3 <= PUFR1(15 downto 12);
					d2 <= PUFR1(11 downto 8);
					d1 <= PUFR1(7 downto 4);
					d0 <= PUFR1(3 downto 0);
				when others =>
					d5 <= (others => '0');
			end case;
		end if;
		
		if (MODE = "01") then
			case State is
			 --             "ABCDEFG"
				when 0 => 
					d5 <= not "1111110";	-- 0
					d4 <= not "0000001";	-- -(Dash)
					d3 <= AESCT(127 downto 124);
					d2 <= AESCT(123 downto 120);
					d1 <= AESCT(119 downto 116);
					d0 <= AESCT(115 downto 112);
				when 1 => 
					d5 <= not "0110000";	-- 1
					d4 <= not "0000001";	-- -(Dash)
					d3 <= AESCT(111 downto 108);
					d2 <= AESCT(107 downto 104);
					d1 <= AESCT(103 downto 100);
					d0 <= AESCT(99 downto 96);
				when 2 => 
					d5 <= not "1101101";	-- 2
					d4 <= not "0000001";	-- -(Dash)
					d3 <= AESCT(95 downto 92);
					d2 <= AESCT(91 downto 88);
					d1 <= AESCT(87 downto 84);
					d0 <= AESCT(83 downto 80);
				when 3 => 
					d5 <= not "1111001";	-- 3
					d4 <= not "0000001";	-- -(Dash)
					d3 <= AESCT(79 downto 76);
					d2 <= AESCT(75 downto 72);
					d1 <= AESCT(71 downto 68);
					d0 <= AESCT(67 downto 64);
				when 4 => 
					d5 <= not "0110011";	-- 4
					d4 <= not "0000001";	-- -(Dash)
					d3 <= AESCT(63 downto 60);
					d2 <= AESCT(59 downto 56);
					d1 <= AESCT(55 downto 52);
					d0 <= AESCT(51 downto 48);
				when 5 => 
					d5 <= not "1011011";	-- 5
					d4 <= not "0000001";	-- -(Dash)
					d3 <= AESCT(47 downto 44);
					d2 <= AESCT(43 downto 40);
					d1 <= AESCT(39 downto 36);
					d0 <= AESCT(35 downto 32);
				when 6 => 
					d5 <= not "1011111";	-- 6
					d4 <= not "0000001";	-- -(Dash)
					d3 <= AESCT(31 downto 28);
					d2 <= AESCT(27 downto 24);
					d1 <= AESCT(23 downto 20);
					d0 <= AESCT(19 downto 16);
				when 7 => 
					d5 <= not "1110000";	-- 7
					d4 <= not "0000001";	-- -(Dash)
					d3 <= AESCT(15 downto 12);
					d2 <= AESCT(11 downto 8);
					d1 <= AESCT(7 downto 4);
					d0 <= AESCT(3 downto 0);
				when others =>
					d5 <= (others => '0');
			end case;
		end if;
		
		if (MODE = "10") then
			case State is
			 --             "ABCDEFG"
				when 0 => 
					d5 <= not "1111110";	-- 0
					d4 <= not "0000001";	-- -(Dash)
					d3 <= PUFR2(127 downto 124);
					d2 <= PUFR2(123 downto 120);
					d1 <= PUFR2(119 downto 116);
					d0 <= PUFR2(115 downto 112);
				when 1 => 
					d5 <= not "0110000";	-- 1
					d4 <= not "0000001";	-- -(Dash)
					d3 <= PUFR2(111 downto 108);
					d2 <= PUFR2(107 downto 104);
					d1 <= PUFR2(103 downto 100);
					d0 <= PUFR2(99 downto 96);
				when 2 => 
					d5 <= not "1101101";	-- 2
					d4 <= not "0000001";	-- -(Dash)
					d3 <= PUFR2(95 downto 92);
					d2 <= PUFR2(91 downto 88);
					d1 <= PUFR2(87 downto 84);
					d0 <= PUFR2(83 downto 80);
				when 3 => 
					d5 <= not "1111001";	-- 3
					d4 <= not "0000001";	-- -(Dash)
					d3 <= PUFR2(79 downto 76);
					d2 <= PUFR2(75 downto 72);
					d1 <= PUFR2(71 downto 68);
					d0 <= PUFR2(67 downto 64);
				when 4 => 
					d5 <= not "0110011";	-- 4
					d4 <= not "0000001";	-- -(Dash)
					d3 <= PUFR2(63 downto 60);
					d2 <= PUFR2(59 downto 56);
					d1 <= PUFR2(55 downto 52);
					d0 <= PUFR2(51 downto 48);
				when 5 => 
					d5 <= not "1011011";	-- 5
					d4 <= not "0000001";	-- -(Dash)
					d3 <= PUFR2(47 downto 44);
					d2 <= PUFR2(43 downto 40);
					d1 <= PUFR2(39 downto 36);
					d0 <= PUFR2(35 downto 32);
				when 6 => 
					d5 <= not "1011111";	-- 6
					d4 <= not "0000001";	-- -(Dash)
					d3 <= PUFR2(31 downto 28);
					d2 <= PUFR2(27 downto 24);
					d1 <= PUFR2(23 downto 20);
					d0 <= PUFR2(19 downto 16);
				when 7 => 
					d5 <= not "1110000";	-- 7
					d4 <= not "0000001";	-- -(Dash)
					d3 <= PUFR2(15 downto 12);
					d2 <= PUFR2(11 downto 8);
					d1 <= PUFR2(7 downto 4);
					d0 <= PUFR2(3 downto 0);
				when others =>
					d5 <= (others => '0');
			end case;
		end if;
	end process;
	
	process(d3,d2,d1,d0)
	begin
		case d3 is
		 --                       "ABCDEFG"
			when x"0" => H3 <= not "1111110";	-- 0
			when x"1" => H3 <= not "0110000";	-- 1
			when x"2" => H3 <= not "1101101";	-- 2
			when x"3" => H3 <= not "1111001";	-- 3
			when x"4" => H3 <= not "0110011";	-- 4
			when x"5" => H3 <= not "1011011";	-- 5
			when x"6" => H3 <= not "1011111";	-- 6
			when x"7" => H3 <= not "1110000";	-- 7
			when x"8" => H3 <= not "1111111";	-- 8
			when x"9" => H3 <= not "1110011";	-- 9
			when x"A" => H3 <= not "1110111";	-- A
			when x"B" => H3 <= not "0011111";	-- B
			when x"C" => H3 <= not "0001101";	-- C
			when x"D" => H3 <= not "0111101";	-- D
			when x"E" => H3 <= not "1001111";	-- E
			when x"F" => H3 <= not "1001111";	-- F
			when others =>
				H3 <= (others => '0');
		end case;
		
		case d2 is
		 --                       "ABCDEFG"
			when x"0" => H2 <= not "1111110";	-- 0
			when x"1" => H2 <= not "0110000";	-- 1
			when x"2" => H2 <= not "1101101";	-- 2
			when x"3" => H2 <= not "1111001";	-- 3
			when x"4" => H2 <= not "0110011";	-- 4
			when x"5" => H2 <= not "1011011";	-- 5
			when x"6" => H2 <= not "1011111";	-- 6
			when x"7" => H2 <= not "1110000";	-- 7
			when x"8" => H2 <= not "1111111";	-- 8
			when x"9" => H2 <= not "1110011";	-- 9
			when x"A" => H2 <= not "1110111";	-- A
			when x"B" => H2 <= not "0011111";	-- B
			when x"C" => H2 <= not "0001101";	-- C
			when x"D" => H2 <= not "0111101";	-- D
			when x"E" => H2 <= not "1001111";	-- E
			when x"F" => H2 <= not "1001111";	-- F
			when others =>
				H2 <= (others => '0');
		end case;

		case d1 is
		 --                       "ABCDEFG"
			when x"0" => H1 <= not "1111110";	-- 0
			when x"1" => H1 <= not "0110000";	-- 1
			when x"2" => H1 <= not "1101101";	-- 2
			when x"3" => H1 <= not "1111001";	-- 3
			when x"4" => H1 <= not "0110011";	-- 4
			when x"5" => H1 <= not "1011011";	-- 5
			when x"6" => H1 <= not "1011111";	-- 6
			when x"7" => H1 <= not "1110000";	-- 7
			when x"8" => H1 <= not "1111111";	-- 8
			when x"9" => H1 <= not "1110011";	-- 9
			when x"A" => H1 <= not "1110111";	-- A
			when x"B" => H1 <= not "0011111";	-- B
			when x"C" => H1 <= not "0001101";	-- C
			when x"D" => H1 <= not "0111101";	-- D
			when x"E" => H1 <= not "1001111";	-- E
			when x"F" => H1 <= not "1001111";	-- F
			when others =>
				H1 <= (others => '0');
		end case;
		
		case d0 is
		 --                       "ABCDEFG"
			when x"0" => H0 <= not "1111110";	-- 0
			when x"1" => H0 <= not "0110000";	-- 1
			when x"2" => H0 <= not "1101101";	-- 2
			when x"3" => H0 <= not "1111001";	-- 3
			when x"4" => H0 <= not "0110011";	-- 4
			when x"5" => H0 <= not "1011011";	-- 5
			when x"6" => H0 <= not "1011111";	-- 6
			when x"7" => H0 <= not "1110000";	-- 7
			when x"8" => H0 <= not "1111111";	-- 8
			when x"9" => H0 <= not "1110011";	-- 9
			when x"A" => H0 <= not "1110111";	-- A
			when x"B" => H0 <= not "0011111";	-- B
			when x"C" => H0 <= not "0001101";	-- C
			when x"D" => H0 <= not "0111101";	-- D
			when x"E" => H0 <= not "1001111";	-- E
			when x"F" => H0 <= not "1001111";	-- F
			when others =>
				H0 <= (others => '0');
		end case;
	end process;
	--End of Test
end architecture; 