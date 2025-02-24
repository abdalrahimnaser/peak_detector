----------------------------------------------------------------------------
--	test_top.vhd -- Top level component for testing
----------------------------------------------------------------------------
-- Author:  Dinesh Pamunuwa
----------------------------------------------------------------------------
--
----------------------------------------------------------------------------
--	This component instantiates the Rx, Tx and control_unit_test
----------------------------------------------------------------------------
--
----------------------------------------------------------------------------
-- Version:			1.0
-- Revision History:
--  31/01/2019 (Dinesh): Created using Xilinx Vivado for 64 bit Win
----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity CMD_PROCESSOR_TOP is 
port(
    -- general:
    clk,rst: in std_logic;

    -- tx interface:
    tx_done: in std_logic;
    data_to_tx: out std_logic_vector(7 downto 0);
    tx_now: out std_logic;

    -- rx interface:
    data_from_rx: in std_logic_vector(7 downto 0);
    rx_valid: in std_logic;
    rx_done: out std_logic;

    -- data processor 
    dataReady: in std_logic;
    byte: in std_logic_vector(7 downto 0);
    maxIndex: in std_logic_vector(11 downto 0);
    dataResults: in std_logic_vector(55 downto 0);
    seqDone: in std_logic;
    dp_start: out std_logic;
    numWords: out std_logic_vector(11 downto 0);
    
    -- debug probes
    state_debug_main: out std_logic_vector(2 downto 0);
    current_state_sim_io: out std_logic_vector(1 downto 0)
  );
end;

architecture STRUCT of CMD_PROCESSOR_TOP is

    component clk_wiz_0
    port (
        clk_out          : out    std_logic; -- Clock out ports
        clk_in           : in     std_logic  -- Clock in ports
    );
    end component;


	component main is
  port(
    clk,rst: in std_logic;
    sendDone: in std_logic;
    data_in: in std_logic_vector(7 downto 0);
    receiveDone: in std_logic;
    pattern: in std_logic_vector(1 downto 0);
    recogniseDone: in std_logic;
    dataReady: in std_logic;
    byte: in std_logic_vector(7 downto 0);
    maxIndex: in std_logic_vector(11 downto 0);
    dataResults: in std_logic_vector(55 downto 0);
    seqDone: in std_logic;
    ------------------------
    dp_start: out std_logic;
    numWords: out std_logic_vector(11 downto 0);
    data_o: out std_logic_vector(7 downto 0);
    send: out std_logic;
    pr_start: out std_logic;
    cmd: out std_logic_vector(31 downto 0);
    state_debug_main: out std_logic_vector(2 downto 0)
--    fifo_wr_en : out std_logic
  );
	end component;  

component IO is
     port (
        clk           : in  std_logic;
        rst           : in  std_logic;
        data_o        : in  std_logic_vector(7 downto 0);
        send          : in  std_logic;        -- Send trigger
        valid         : in  std_logic;       -- Receive data valid
        txDone        : in  std_logic;       -- Transmission complete
        rxdata        : in  std_logic_vector(7 downto 0);  -- Received data
        sendDone      : out std_logic;       -- Send completion
        data_in       : out std_logic_vector(7 downto 0);  -- Received data output
        receiveDone   : out std_logic;       -- Receive completion
        txNow         : out std_logic;       -- Transmit trigger
        txdata        : out std_logic_vector(7 downto 0);  -- Data to transmit
        current_state_sim_io : out std_logic_vector(1 downto 0);
        done: out std_logic
    );
end component;


	component main_pr is
    port (
        clk : in std_logic;
        rst : in std_logic;
        start : in std_logic; -- from 'main', signals that it's ready to transmit
        cmd : in std_logic_vector(31 downto 0); -- 4-character string from main
        pattern : out std_logic_vector(1 downto 0); -- 2-bit command that informs main of further instructions
        recogniseDone : out std_logic -- signals to main that the pattern recogniser is ready to receive data
    );
	end component;	

    -- signal declaration here
    signal sendDone :std_logic;
    signal data_in: std_logic_vector(7 downto 0);
    signal data_o : std_logic_vector(7 downto 0);
    signal receiveDone: std_logic;
    signal pr_start: std_logic;
    signal pattern: std_logic_vector(1 downto 0);
    signal recogniseDone: std_logic;
    signal send: std_logic;
    signal cmd: std_logic_vector(31 downto 0);
    
        
begin 
    main_fsm : main
    port map(
        -- DP IF
        clk => clk,
        rst => rst,
        dataReady => dataReady,
        byte => byte,
        maxIndex => maxIndex,
        dataResults => dataResults,
        seqDone => seqDone,
        dp_start => dp_start,
        numWords => numWords,
        
        -- IO IF
        sendDone=> sendDone,
        data_in => data_in,
        receiveDone => receiveDone,
        data_o => data_o,
        send => send,

        -- pattern recogniser IF
        pr_start => pr_start,
        pattern => pattern,
        recogniseDone => recogniseDone,
        cmd => cmd,
        
        state_debug_main => state_debug_main
        
    );

    PR: main_pr 
    port map(
        clk => clk,
        rst => rst,
        start => pr_start,
        cmd => cmd,
        pattern => pattern,
        recogniseDone => recogniseDone
    );
    

    IOXX: IO
    port map(
        clk => clk,
        rst => rst,        
        data_o => data_o,    
        send => send,       
        sendDone => sendDone,
        data_in  => data_in,   
        receiveDone => receiveDone,
        txNow  => tx_now,     
        txDone => tx_done,
        txdata => data_to_tx,
        valid  => rx_valid,
        rxdata => data_from_rx,     
        done => rx_done,
        current_state_sim_io => current_state_sim_io
        
        );

end;

