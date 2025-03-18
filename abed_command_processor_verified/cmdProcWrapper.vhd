----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01.02.2019 21:00:29
-- Design Name: 
-- Module Name: cmdProc - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.common_pack.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity cmdProc is
port (
    clk:		in std_logic;
    reset:        in std_logic;
    rxnow:        in std_logic;
    rxData:            in std_logic_vector (7 downto 0);
    txData:            out std_logic_vector (7 downto 0);
    rxdone:        out std_logic;
    ovErr:        in std_logic;
    framErr:    in std_logic;
    txnow:        out std_logic;
    txdone:        in std_logic;
    start: out std_logic;
    numWords_bcd: out BCD_ARRAY_TYPE(2 downto 0);
    dataReady: in std_logic;
    byte: in std_logic_vector(7 downto 0);
    maxIndex: in BCD_ARRAY_TYPE(2 downto 0);
    dataResults: in CHAR_ARRAY_TYPE(0 to RESULT_BYTE_NUM-1);
    seqDone: in std_logic
    );
end cmdProc;

architecture Behavioral of cmdProc is

    component CMD_PROCESSOR_TOP is
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
    numWords: out std_logic_vector(11 downto 0)
  );
    
    end component;


component Controller is
  port(
    clk,rst: in std_logic;
    deviceOutputSent: in std_logic;
    deviceInput: in std_logic_vector(7 downto 0);
    deviceInputReady: in std_logic;
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
    deviceOutput: out std_logic_vector(7 downto 0);
    send: out std_logic;
    pr_start: out std_logic;
    char: out std_logic_vector(7 downto 0);
    hex_disp: out std_logic;
    space:    out std_logic
  );
	end component;  

component IO is
     port (
        clk           : in  std_logic;
        rst           : in  std_logic;
        deviceOutput        : in  std_logic_vector(7 downto 0);
        send          : in  std_logic;        -- Send trigger
        valid         : in  std_logic;       -- Receive data valid
        txDone        : in  std_logic;       -- Transmission complete
        rxdata        : in  std_logic_vector(7 downto 0);  -- Received data
        deviceOutputSent      : out std_logic;       -- Send completion
        deviceInput       : out std_logic_vector(7 downto 0);  -- Received data output
        deviceInputReady   : out std_logic;       -- Receive completion
        txNow         : out std_logic;       -- Transmit trigger
        txdata        : out std_logic_vector(7 downto 0);  -- Data to transmit
        done: out std_logic;
        hex_disp: in std_logic;
        space:    in std_logic
    );
end component;


	component pr is
    port (
        clk : in std_logic;
        rst : in std_logic;
        start : in std_logic; 
        char : in std_logic_vector(7 downto 0); 
        pattern : out std_logic_vector(1 downto 0); 
        recogniseDone : out std_logic 
    );
	end component;	

    -- signal declaration here
    signal deviceOutputSent :std_logic;
    signal deviceInput: std_logic_vector(7 downto 0);
    signal deviceOutput : std_logic_vector(7 downto 0);
    signal deviceInputReady: std_logic;
    signal pr_start: std_logic;
    signal pattern: std_logic_vector(1 downto 0);
    signal recogniseDone: std_logic;
    signal send: std_logic;
    signal char: std_logic_vector(7 downto 0);
    signal hex_disp_sig , space_sig: std_logic;

    -- Signals for conversion
    signal numWords_signal: std_logic_vector(11 downto 0);
    signal maxIndex_signal: std_logic_vector(11 downto 0);
    signal dataResults_signal: std_logic_vector(55 downto 0);

begin
    -- Assigning signals
    numWords_bcd(2) <= numWords_signal(11 downto 8);  -- Hundreds place
    numWords_bcd(1) <= numWords_signal(7 downto 4);   -- Tens place
    numWords_bcd(0) <= numWords_signal(3 downto 0);   -- Units place    maxIndex_signal <= maxIndex(2) & maxIndex(1) & maxIndex(0);
    maxIndex_signal <= maxIndex(2) & maxIndex(1) & maxIndex(0);
    dataResults_signal <= dataResults(0) & dataResults(1) & dataResults(2) & dataResults(3) & dataResults(4) & dataResults(5) & dataResults(6);

main_fsm : Controller
    port map(
        -- DP IF
        clk => clk,
        rst => reset,
        dataReady => dataReady,
        byte => byte,
        maxIndex => maxIndex_signal,
        dataResults => dataResults_signal,
        seqDone => seqDone,
        dp_start => start,
        numWords => numWords_signal,
        
        -- IO IF
        deviceOutputSent=> deviceOutputSent,
        deviceInput => deviceInput,
        deviceInputReady => deviceInputReady,
        deviceOutput => deviceOutput,
        send => send,

        -- pattern recogniser IF
        pr_start => pr_start,
        pattern => pattern,
        recogniseDone => recogniseDone,
        char => char,
              
        hex_disp => hex_disp_sig,
        space => space_sig
    
        
    );

    PattR: pr 
    port map(
        clk => clk,
        rst => reset,
        start => pr_start,
        char => char,
        pattern => pattern,
        recogniseDone => recogniseDone
    );
    

    IOXX: IO
    port map(
        clk => clk,
        rst => reset,        
        deviceOutput => deviceOutput,    
        send => send,       
        deviceOutputSent => deviceOutputSent,
        deviceInput  => deviceInput,   
        deviceInputReady => deviceInputReady,
        txNow  => txnow,     
        txDone => txdone,
        txdata => txData,
        valid  => rxnow,
        rxdata => rxData,     
        done => rxdone,
        hex_disp => hex_disp_sig,
        space => space_sig
        );

end Behavioral;
