library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_main is
end tb_main;

architecture behavior of tb_main is 

    component IO
    port(
        clk : in std_logic;
        rst : in std_logic;
        data_o : in std_logic_vector(55 downto 0);
        send : in std_logic;
        valid : in std_logic;
        txDone : in std_logic;
        rxdata : in std_logic_vector(7 downto 0);
        sendDone : out std_logic;
        data_in : out std_logic_vector(7 downto 0);
        receiveDone : out std_logic;
        done : out std_logic;
        txNow : out std_logic;
        txdata : out std_logic_vector(7 downto 0);
        current_state_sim : out std_logic_vector(1 downto 0)
    );
    end component;

    -- Inputs
    signal clk : std_logic := '0';
    signal rst : std_logic := '1';  -- Start with reset active
    signal data_o : std_logic_vector(55 downto 0) := (others => '0');
    signal send : std_logic := '0';
    signal valid : std_logic := '0';
    signal txDone : std_logic := '0';
    signal rxdata : std_logic_vector(7 downto 0) := (others => '0');

    signal sendDone : std_logic;
    signal data_in : std_logic_vector(7 downto 0);
    signal receiveDone : std_logic;
    signal done : std_logic;
    signal txNow : std_logic;
    signal txdata : std_logic_vector(7 downto 0);
    signal current_state : std_logic_vector(1 downto 0);

    constant clk_period : time := 10 ns;

begin

    uut: IO port map (
        clk => clk,
        rst => rst,
        data_o => data_o,
        send => send,
        valid => valid,
        txDone => txDone,
        rxdata => rxdata,
        sendDone => sendDone,
        data_in => data_in,
        receiveDone => receiveDone,
        done => done,
        txNow => txNow,
        txdata => txdata,
        current_state_sim => current_state
    );



    clk_process: process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;


    stim_proc: process
    begin
        -- Hold reset for two clock cycles
        wait for clk_period*2;
        rst <= '0';
        wait for clk_period;

        -- Test transmission functionality
        data_o <= x"AABBCCDDEEFF55"; -- 7-byte test pattern
        txDone <= '1';
        send <= '1';
        wait for clk_period;
        send <= '0';

        -- Generate txDone pulses for each byte transmission
        for i in 0 to 6 loop
            wait until txNow = '1';
            txDone <= '0';
            wait for clk_period*5;  -- Simulate transmission delay
            txDone <= '1';
        end loop;

        -- wait until done = '1';
        wait for clk_period;

        -- Test receive functionality
        rxdata <= x"7F";
        valid <= '1';
        wait for clk_period;
        valid <= '0';

        wait until receiveDone = '1';
        assert data_in = x"7F" 
            report "Received data mismatch" severity error;

        -- End simulation
        wait for clk_period*2;
        report "Simulation completed successfully" severity note;
        wait;
    end process;

end architecture;
