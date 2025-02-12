library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity IO_TB is
end IO_TB;

architecture Behavioral of IO_TB is
    component IO is
        Port (
            clk         : in  STD_LOGIC;
            rst         : in  STD_LOGIC;
            data_o      : in STD_LOGIC_VECTOR(55 downto 0);
            send        : in  STD_LOGIC;
            sendDone    : out STD_LOGIC;
            data_in     : out STD_LOGIC_VECTOR(31 downto 0);
            receiveDone : out STD_LOGIC;
            txnow       : out STD_LOGIC;
            txdone      : in  STD_LOGIC;
            rxnow       : in  STD_LOGIC;
            rxdata      : in  STD_LOGIC_VECTOR(7 downto 0);
            rxdone      : out STD_LOGIC
        );
    end component;

  -- Send Process
    signal clk          : STD_LOGIC := '0';
    signal rst          : STD_LOGIC := '1';
    signal data_o       : STD_LOGIC_VECTOR(55 downto 0) := (others => '0');
    signal send         : STD_LOGIC := '0';
    signal txdone       : STD_LOGIC := '0';
    signal rxnow        : STD_LOGIC := '0';
    signal rxdata       : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');

  -- Recive Process
    signal sendDone     : STD_LOGIC;
    signal data_in      : STD_LOGIC_VECTOR(31 downto 0);
    signal receiveDone  : STD_LOGIC;
    signal txnow        : STD_LOGIC;
    signal rxdone       : STD_LOGIC;

constant clk_period : time := 10ns ;

begin

    uut: main port map (
        clk         => clk,
        rst         => rst,
        data_o      => data_o,
        send        => send,
        sendDone    => sendDone,
        data_in     => data_in,
        receiveDone => receiveDone,
        txnow       => txnow,
        txdone      => txdone,
        rxnow       => rxnow,
        rxdata      => rxdata,
        rxdone      => rxdone
    );
    -- Clock process definitions
    clk_process : process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;
    
    stim_proc: process
    begin
        rst <= '1';
        wait for clk_period*2;
        rst <= '0';
        wait for clk_period;  -- Initialize the reset

        rxnow <= '1';
        rxdata <= x"01";
        wait for clk_period;       
        wait until rxdone = '1';
        rxnow <= '0';
        wait for clk_period;
        rxnow <= '1';
        rxdata <= x"02";
        wait for clk_period;
        wait until rxdone = '1';
        rxnow <= '0';
        wait for clk_period;       
        rxnow <= '1';
        rxdata <= x"03";
        wait for clk_period;
        wait until rxdone = '1';
        rxnow <= '0';
        wait for clk_period;
        rxnow <= '1';
        rxdata <= x"04";
        wait for clk_period;
        wait until rxdone = '1';
        rxnow <= '0';
        wait for clk_period;
        
        wait for clk_period * 10;
        
       -- verify the received data
        wait until receiveDone = '1';
        assert data_in = X"04030201" 
           report "Receive error. Expected 04030201, got" & data_in(31 downto 28) & data_in(27 downto 24) & data_in(23 downto 20) & data_in(19 downto 16) & data_in(15 downto 12) & data_in(11 downto 8) & data_in(7 downto 4) & data_in(3 downto 0)
           severity error;
        report "Receive test passed";
       
       -- Send operation test
       data_o <= X"0123456789ABCD"; -- 56-bit data
       send <= '1';
       wait for clk_period;
       send <= '0';
       
       for i in 0 to 6 loop
                   case i is
                when 0 => assert data_in = x"01" report "Byte 0 error" severity error;
                when 1 => assert data_in = x"23" report "Byte 1 error" severity error;
                when 2 => assert data_in = x"45" report "Byte 2 error" severity error;
                when 3 => assert data_in = x"67" report "Byte 3 error" severity error;
                when 4 => assert data_in = x"89" report "Byte 4 error" severity error;
                when 5 => assert data_in = x"AB" report "Byte 5 error" severity error;
                when 6 => assert data_in = x"CD" report "Byte 6 error" severity error;
                when others => null;
            end case;
       wait until txnow = '1';
       txdone <= '1';
       wait for clk_period;
       txdone <= '0';
       wait for clk_period;
       end loop;

       wait until sendDone = '1';
       wait for clk_period;
       report "Send test passed";
    
       wait;
    end process;

end Behavioral;
