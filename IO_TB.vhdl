-----------------------------------------------
-- Institution : University Of Bristol
-- Student : Ben Jack
--
-- Description : Command Process - IO Testbench
-- Project Name : Peak Detector
-- Target Devices : artix-7 35t cpg236-1
-----------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_IO is
end tb_IO;
	
architecture tb of tb_IO is 
component IO
    port(
            clk           	: in  std_logic;
            rst           	: in  std_logic;
            deviceOutput  	: in  std_logic_vector(7 downto 0);
            send          	: in  std_logic;
            valid         	: in  std_logic;
            txDone        	: in  std_logic;
            rxdata        	: in  std_logic_vector(7 downto 0);
	    hex_disp      	: in std_logic;
            space         	: in std_logic;

            deviceOutputSent 	: out std_logic;
            deviceInput   	: out std_logic_vector(7 downto 0);
            deviceInputReady 	: out std_logic;
            txNow         	: out std_logic;
            txdata        	: out std_logic_vector(7 downto 0);
            done          	: out std_logic
            
        );
end component;

signal clk : std_logic := '0';
signal rst : std_logic := '1';
signal deviceOutput : std_logic_vector(7 downto 0) := (others => '0');
signal send : std_logic := '0';
signal valid : std_logic := '0';
signal txDone : std_logic := '0';
signal rxdata : std_logic_vector(7 downto 0) := (others => '0');
signal hex_disp : std_logic := '0';
signal space : std_logic := '0';

signal deviceOutputSent : std_logic;
signal deviceInput : std_logic_vector(7 downto 0);
signal deviceInputReady : std_logic;
signal txNow : std_logic;
signal txdata : std_logic_vector(7 downto 0);
signal done : std_logic;

constant clk_period : time := 10 ns;

begin
        uut: IO
        port map (
            clk => clk,
            rst => rst,
            deviceOutput => deviceOutput,
            send => send,
            valid => valid,
            txDone => txDone,
            rxdata => rxdata,
            deviceOutputSent => deviceOutputSent,
            deviceInput => deviceInput,
            deviceInputReady => deviceInputReady,
            txNow => txNow,
            txdata => txdata,
            done => done,
            hex_disp => hex_disp,
            space => space
        );

clk_process : process
    begin
        while true loop
            clk <= '0';
            wait for clk_period / 2;
            clk <= '1';
            wait for clk_period / 2;
        end loop;
    end process;

stim_proc: process
    begin
        rst <= '1';
        wait for 2 * clk_period;
        rst <= '0';
        wait for clk_period;

	-- test 1: recieving data
        valid <= '1';
        rxdata <= x"C3";
        wait for clk_period;
        valid <= '0';	
        wait for clk_period;
        txDone <= '1';
        wait for clk_period;
        txDone <= '0';
        wait for clk_period;
	wait for clk_period;
	assert (deviceInput = x"C3")
            report "ERROR: deviceInput = x'C3' was expected"
            severity error;

        -- test 2: transmitting without hex display
        deviceOutput <= x"A5";
        send <= '1';
        wait for clk_period;
        send <= '0';

        wait for clk_period;
        txDone <= '1';
        wait for clk_period;
        txDone <= '0';
        wait for clk_period;
	assert (txdata = x"A5")
            report "ERROR: txdata = x'A5' was expected"
            severity error;

        -- test 3: transmitting with hex display
        hex_disp <= '1';
        deviceOutput <= x"4F";
        send <= '1';
        wait for clk_period;
        send <= '0';
        wait for clk_period;
        txDone <= '1';
        wait for clk_period;
        txDone <= '0';
        wait for clk_period;

	--test 3.1: first nibble test
	assert (txdata = x"34")
    	report "ERROR: txdata should be '4' (x'34') in hex display mode"
    	severity error;
	wait for clk_period;
        txDone <= '1';
        wait for clk_period;
        txDone <= '0';
        wait for clk_period;

	--test 3.2: second nibble test
	assert (txdata = x"46")
    	report "ERROR: txdata should be 'F' (x'46') in hex display mode"
    	severity error;
	wait for clk_period;
        txDone <= '1';
        wait for clk_period;
        txDone <= '0';
        wait for clk_period;

	--test 3.3: space test
1	space <= '1';
	if space = '1' then
		assert (txdata = x"20")
        report "ERROR: txdata should be a space ' '(x'20') in hex display mode with space"
        severity error;
	end if;


        
	report "TB completed";
        wait;
    end process;

end tb;
