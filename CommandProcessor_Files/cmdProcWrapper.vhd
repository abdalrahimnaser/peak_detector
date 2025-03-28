----------------------------------------------------------------------------------
-- Institution: University of Bristol 
-- Student: Abdalrahim Naser
-- 
-- Description: Command Processor top-level Wrapper 
-- Module Name: cmdProc - Behavioral
-- Project Name: Peak Detector
-- Target Devices: artix-7 35t cpg236-1
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.common_pack.all;

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

component Controller is
  port(
    clk,rst: in std_logic;
    
    -- io interface
    deviceOutput: out std_logic_vector(7 downto 0);     -- 8-bit UART output data
    deviceOutputSent: in std_logic;                     -- indicates output is sent and ready for next send operation
    deviceInput: in std_logic_vector(7 downto 0);       -- 8-bit UART input data
    deviceInputReady: in std_logic;                     -- input received
    send: out std_logic;                                -- initiate data sending
    hex_disp: out std_logic;                            -- enables hexadecimal display mode
    space:    out std_logic;                            -- outputs a space character after a send operation
    newline:  out std_logic;                            -- prints new line
    
    -- PR interface
    pattern: in std_logic_vector(1 downto 0);           -- pattern identifier
    recogniseDone: in std_logic;                        -- pattern recognition op complete
    char: out std_logic_vector(7 downto 0);             -- character output to PR
    pr_start: out std_logic;                            -- start pattern recognition

    -- DP interface
    dataReady: in std_logic;
    byte: in std_logic_vector(7 downto 0);              -- byte is valid to read
    maxIndex: in BCD_ARRAY_TYPE(2 downto 0);            -- byte data
    dataResults:  in CHAR_ARRAY_TYPE(0 to RESULT_BYTE_NUM-1); -- results array (XXXpeakXXX)  
    seqDone: in std_logic;                              -- sequence processing complete
    dp_start: out std_logic;                            -- initiate/resume DP
    numWords_bcd: out BCD_ARRAY_TYPE(2 downto 0)        -- number of bytes to retrieve
  );
  
	end component;  

component IO is
    port (
        clk           : in  std_logic;
        rst           : in  std_logic;
        deviceOutput        : in  std_logic_vector(7 downto 0);
        send          : in  std_logic;        -- send trigger
        valid         : in  std_logic;       -- receive data valid
        txDone        : in  std_logic;       -- transmission complete
        rxdata        : in  std_logic_vector(7 downto 0);  -- received data
        deviceOutputSent      : out std_logic;       -- send completion
        deviceInput       : out std_logic_vector(7 downto 0);  -- received data output
        deviceInputReady   : out std_logic;       -- receive completion
        txNow         : out std_logic;       -- transmit trigger
        txdata        : out std_logic_vector(7 downto 0);  -- data to transmit
        done: out std_logic;
        hex_disp: in std_logic;
        space:    in std_logic;
        newline:  in std_logic
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

    -- connecting wires/signals
    signal deviceOutputSent :std_logic;
    signal deviceInput: std_logic_vector(7 downto 0);
    signal deviceOutput : std_logic_vector(7 downto 0);
    signal deviceInputReady: std_logic;
    signal pr_start: std_logic;
    signal pattern: std_logic_vector(1 downto 0);
    signal recogniseDone: std_logic;
    signal send: std_logic;

    signal char: std_logic_vector(7 downto 0);
    signal hex_disp_sig , space_sig, newline_sig: std_logic;

begin

main_fsm : Controller
    port map(
        -- DP IF
        clk => clk,
        rst => reset,
        dataReady => dataReady,
        byte => byte,
        maxIndex => maxIndex,
        dataResults => dataResults,
        seqDone => seqDone,
        dp_start => start,
        numWords_bcd => numWords_bcd,
        
        -- IO IF
        deviceOutputSent=> deviceOutputSent,
        deviceInput => deviceInput,
        deviceInputReady => deviceInputReady,
        deviceOutput => deviceOutput,
        send => send,
        newline => newline_sig,
        
        -- PR IF
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
        space => space_sig,
        newline => newline_sig
        );

end Behavioral;
