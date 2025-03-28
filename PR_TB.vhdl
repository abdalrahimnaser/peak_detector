-----------------------------------------------
-- Institution : University Of Bristol
-- Student : Ben Jack
--
-- Description : Command Process - PR Testbench
-- Project Name : Peak Detector
-- Target Devices : artix-7 35t cpg236-1
-----------------------------------------------


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb_pr is
end tb_pr;

architecture tb of tb_pr is
    component pr
        port (
            clk 	  : in std_logic;
            rst 	  : in std_logic;
            start 	  : in std_logic;
            char 	  : in std_logic_vector(7 downto 0);
            pattern 	  : out std_logic_vector(1 downto 0);
            recogniseDone : out std_logic
        );
    end component;

    signal clk		 : std_logic := '0';
    signal rst 		 : std_logic := '1';
    signal start 	 : std_logic := '0';
    signal char 	 : std_logic_vector(7 downto 0) := (others => '0');
    signal pattern 	 : std_logic_vector(1 downto 0);
    signal recogniseDone : std_logic;

    constant clk_period : time := 10 ns;

begin
    uut: pr
        port map (
            clk		  => clk,
            rst		  => rst,
            start	  => start,
            char 	  => char,
            pattern	  => pattern,
            recogniseDone => recogniseDone
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

    stim_proc : process
        procedure send_char(c : integer) is
        begin
            char <= std_logic_vector(to_unsigned(c, 8));
            start <= '1';
            wait for clk_period;  -- 1 clock cycle with start = '1'
            start <= '0';
            wait for clk_period;  -- 1 clock cycle to allow processing
        end procedure;

    begin
 
        rst <= '1';
        wait for clk_period;
        rst <= '0';
        wait for clk_period;
	wait for clk_period;


	-- test for initial pattern output of 11
	assert (pattern = "11")
            report "ERROR: pattern = '11' was expected"
            severity error;

	-- test for 'L', expected pattern = "10"
	send_char(76);
	wait for clk_period;
	assert (pattern = "10")
            report "ERROR: pattern = '10' was expected"
            severity error;

	-- test for 'P'
	send_char(80);
	wait for clk_period;
	assert (pattern = "01")
            report "ERROR: pattern = '01' was expected"
            severity error;

	-- test for 'A564'(ANNN)
	send_char(65);  -- 'A'
        send_char(53);  -- '5'
        send_char(54);  -- '6'
        send_char(51);  -- '3'
	wait for clk_period;
	assert (pattern = "00")
            report "ERROR: pattern = '00' was expected"
            severity error;
	wait;
    end process;
end tb;
