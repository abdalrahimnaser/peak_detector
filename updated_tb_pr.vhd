library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb_pr is
end tb_pr;

architecture tb of tb_pr is
    -- Component declaration for the DUT
    component main
        port (
            clk : in std_logic;
            rst : in std_logic;
            start : in std_logic;
            cmd : in std_logic_vector(7 downto 0);
            pattern : out std_logic_vector(1 downto 0);
            recogniseDone : out std_logic
        );
    end component;

    -- Signals
    signal clk : std_logic := '0';
    signal rst : std_logic := '1';
    signal start : std_logic := '0';
    signal cmd : std_logic_vector(7 downto 0) := (others => '0');
    signal pattern : std_logic_vector(1 downto 0);
    signal recogniseDone : std_logic;

    constant clk_period : time := 10 ns;

begin
    -- Instantiate the DUT
    dut: main
        port map (
            clk => clk,
            rst => rst,
            start => start,
            cmd => cmd,
            pattern => pattern,
            recogniseDone => recogniseDone
        );

    -- Clock process
    clk_process : process
    begin
        while true loop
            clk <= '0';
            wait for clk_period / 2;
            clk <= '1';
            wait for clk_period / 2;
        end loop;
    end process;

    -- Stimulus process
    stim_process : process
        procedure send_byte(c : integer) is
        begin
            cmd <= std_logic_vector(to_unsigned(c, 8));
            start <= '1';
            wait for clk_period;  -- 1 clock cycle with start = '1'
            start <= '0';
            wait for clk_period;  -- 1 clock cycle to allow processing
        end procedure;

    begin
        -- Reset the design
        rst <= '1';
        wait for 3 * clk_period;
        rst <= '0';
        wait for 2 * clk_period;

        -- Test A123 (should match pattern "00")
        send_byte(65);  -- 'A'
        send_byte(49);  -- '1'
        send_byte(50);  -- '2'
        send_byte(51);  -- '3'

        wait for clk_period;  -- Give time for recogniseDone to update

        assert (pattern = "00")
            report "FAIL: Expected pattern 00 for A123"
            severity error;

        -- Test 'p' (should match pattern "01")
        send_byte(112);  -- 'p'

        wait for clk_period;

        assert (pattern = "01")
            report "FAIL: Expected pattern 01 for p"
            severity error;

        -- Test 'L' (should match pattern "10")
        send_byte(76);  -- 'L'

        wait for clk_period;

        assert (pattern = "10")
            report "FAIL: Expected pattern 10 for L"
            severity error;

        -- Test invalid character (should leave pattern at 11 or unchanged)
        send_byte(35);  -- '#'
        wait for clk_period;

        assert (pattern = "11")  -- Expect unrecognised pattern
            report "FAIL: Expected pattern 11 after invalid character"
            severity error;

        -- Test a456 (should match pattern "00")
        send_byte(97);  -- 'a'
        send_byte(52);  -- '4'
        send_byte(53);  -- '5'
        send_byte(54);  -- '6'

        wait for clk_period;

        assert (pattern = "00")
            report "FAIL: Expected pattern 00 for a456"
            severity error;

        -- Send 0 (end of transmission, expect unrecognised "11")
        send_byte(0);

        wait for clk_period;

        assert (pattern = "11")
            report "FAIL: Expected pattern 11 for end-of-transmission"
            severity error;

        -- Final report
        report "Testbench completed successfully";

        wait;
    end process;
end tb;
