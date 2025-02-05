library IEEE;
use IEEE.numeric_std.all;
use IEEE.std_logic_1164.all;

entity tb_main is END;

architecture tb of tb_main is
    component main
        port (
            clk : in std_logic;
            rst : in std_logic;
            start : in std_logic;
            cmd : in std_logic_vector(31 downto 0);
   ------------------------------------------
            pattern : out std_logic_vector(1 downto 0);
            recogniseDone : out std_logic
        );
     end component;

    -- initial values of each signal
    signal clk_tb : std_logic := '1';
    signal rst_tb : std_logic := '0';
    signal start_tb : std_logic := '0';
    signal cmd_tb : std_logic_vector(31 downto 0) := (others => '0');
    signal pattern_tb : std_logic_vector(1 downto 0);
    signal recogniseDone_tb : std_logic;


begin
    uut: main
        port map (
            clk => clk_tb,
            rst => rst_tb,
            start => start_tb,
            cmd => cmd_tb,
            pattern => pattern_tb,
            recogniseDone => recogniseDone_tb
        );

    clk_tb <= not clk_tb after 10ns; -- creates a clock with a predetermined period(20ns here)


    program : process
    begin
        --rst_tb <= '1'; --resetting the system
        --wait for 10ns;
        --rst_tb <= '0';
--wait for 10ns;
start_tb <= '1'; --'start' recieved from main
        -- test 1: pattern ending 'p' or 'P' (input: A19p)
wait for 19ns;
        cmd_tb <= std_logic_vector(to_unsigned(65, 8)) & std_logic_vector(to_unsigned(49, 8)) & std_logic_vector(to_unsigned(57, 8)) & std_logic_vector(to_unsigned(112, 8));
        assert pattern_tb = "01" and recogniseDone_tb = '1'
        report "test 1 failed - expected 01" severity error;
        wait for 20ns;

        -- test 2: pattern ending 'l' or 'L' (input: A19l)
        cmd_tb <= std_logic_vector(to_unsigned(65, 8)) & std_logic_vector(to_unsigned(49, 8)) & std_logic_vector(to_unsigned(57, 8)) & std_logic_vector(to_unsigned(108, 8));
        assert pattern_tb = "10" and recogniseDone_tb = '1'
        report "test 2 failed - expected 02" severity error;
wait for 20ns;

        -- test 3: 'A' followed by 3 numbers (input: A190)
        cmd_tb <= std_logic_vector(to_unsigned(65, 8)) & std_logic_vector(to_unsigned(49, 8)) & std_logic_vector(to_unsigned(57, 8)) & std_logic_vector(to_unsigned(48, 8));
        assert pattern_tb = "00" and recogniseDone_tb = '1'
        report "test 3 failed - expected 03" severity error;
wait for 20ns;

        -- test 4: unrecognized pattern (input: 'WXYY')
        cmd_tb <= std_logic_vector(to_unsigned(87, 8)) & std_logic_vector(to_unsigned(88, 8)) & std_logic_vector(to_unsigned(89, 8)) & std_logic_vector(to_unsigned(89, 8));
        assert pattern_tb = "11" and recogniseDone_tb = '1'
        report "test 4 failed - expected 04" severity error;

        wait;
    end process;
end tb;
