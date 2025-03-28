library ieee;
use ieee.std_logic_1164.all;
library xil_defaultlib; -- default library to which all user-defined components are compiled 
use xil_defaultlib.common_pack.all;

entity top is 
	port (
		clk:	in std_logic;
		reset:	in std_logic;
		rxData:	in std_logic;
		txData:	out std_logic
	);
end;

architecture struct of top is 

component clk_wiz_0
port
 (
  clk_out          : out    std_logic; -- Clock out ports
  clk_in           : in     std_logic  -- Clock in ports
 );
end component;

  component UART_TX_CTRL is
      Port ( 
        SEND : in  STD_LOGIC;
        DATA : in  STD_LOGIC_VECTOR (7 downto 0);
        CLK : in  STD_LOGIC;
        READY : out  STD_LOGIC;
        UART_TX : out  STD_LOGIC
      );
  end component;  
  
  component UART_RX_CTRL is
    port(
      RxD: in std_logic; 			-- serial data in
    	sysclk: in std_logic; 		-- system clock
    	reset: in std_logic;		--	synchronous reset
  	   rxDone: in std_logic;			-- data succesfully read (active high)
      rcvDataReg: out std_logic_vector(7 downto 0); -- received data
      dataReady: out std_logic;	-- data ready to be read
    	setOE: out std_logic;		-- overrun error (active high)
    	setFE: out std_logic		-- frame error (active high)
    );
  end component; 

  component dataGen is
  	port (
  	 clk:		in std_logic;
  		reset:		in std_logic; -- synchronous reset
  		ctrlIn: in std_logic;
  		ctrlOut: out std_logic;
  		data: out std_logic_vector(7 downto 0)
  	);
  end component;
  
  component dataConsume is
  	port (
	  clk:		in std_logic;
		reset:		in std_logic; -- synchronous reset
		start: in std_logic;		
		numWords_bcd: in BCD_ARRAY_TYPE(2 downto 0);
		ctrlIn: in std_logic;
		ctrlOut: out std_logic;
		data: in std_logic_vector(7 downto 0);
		dataReady: out std_logic;
		byte: out std_logic_vector(7 downto 0);
		seqDone: out std_logic;
		maxIndex: out BCD_ARRAY_TYPE(2 downto 0);		
		dataResults: out CHAR_ARRAY_TYPE(0 to RESULT_BYTE_NUM-1) 
  	);
  end component;
  
  component cmdProc is
	port (
		clk:		in std_logic;
		reset:		in std_logic;
		rxnow:		in std_logic;
		rxData:			in std_logic_vector (7 downto 0);
		txData:			out std_logic_vector (7 downto 0);
		rxdone:		out std_logic;
		ovErr:		in std_logic;
		framErr:	in std_logic;
		txnow:		out std_logic;
		txdone:		in std_logic;
		start: out std_logic;
		numWords_bcd: out BCD_ARRAY_TYPE(2 downto 0);
		dataReady: in std_logic;
		byte: in std_logic_vector(7 downto 0);
		maxIndex: in BCD_ARRAY_TYPE(2 downto 0);
		dataResults: in CHAR_ARRAY_TYPE(0 to RESULT_BYTE_NUM-1);
		seqDone: in std_logic
	);
end component;
  
  signal clk_100: std_logic;
  signal sig_start, ctrl_genDriv, ctrl_consDriv: std_logic;
  signal sig_rxDone, sig_rxNow, sig_ovErr, sig_framErr, sig_txNow, sig_txDone, sig_seqDone, sig_dataReady: std_logic;
  signal sig_rxData, sig_txData, dataRead, sig_byte: std_logic_vector(7 downto 0);
  signal numWords: std_logic_vector(9 downto 0) := "0000100000";
  signal sig_dataResults: CHAR_ARRAY_TYPE(0 to RESULT_BYTE_NUM-1);
  signal sig_numWords_bcd, sig_maxIndex: BCD_ARRAY_TYPE(2 downto 0);
  
begin


clk_wiz : clk_wiz_0
   port map (  
   clk_out => clk_100, -- Clock out ports  
   clk_in => clk       -- Clock in ports
 );

	 
  dataGen1: dataGen
    port map (
      clk => clk_100,
      reset => reset,
      ctrlIn => ctrl_consDriv,
      ctrlOut => ctrl_genDriv,
      data => dataRead
    );
    
  dataConsume1: dataConsume
    port map (
      clk => clk_100,
      reset => reset,
      start => sig_start,
		numWords_bcd => sig_numWords_bcd,
      ctrlIn => ctrl_genDriv,
      ctrlOut => ctrl_consDriv,
      data => dataRead,
		dataReady => sig_dataReady,
		byte => sig_byte,
      seqDone => sig_seqDone,
    	maxIndex => sig_maxIndex,
      dataResults => sig_dataResults
    );
    
  cmdProc1: cmdProc
    	port map (
    		clk => clk_100,
    		reset => reset,
    		rxNow => sig_rxNow,
    		rxData => sig_rxData,
    		txData => sig_txData,
    		rxDone => sig_rxDone,
    		ovErr => sig_ovErr,
    		framErr => sig_framErr,
    		txNow => sig_txNow,
    		txDone => sig_txDone,
    		start => sig_start,
 			numWords_bcd => sig_numWords_bcd,
			dataReady => sig_dataReady,
			byte => sig_byte,
    		maxIndex => sig_maxIndex,
    		seqDone => sig_seqDone,
    		dataResults => sig_dataResults
   	);
    	
  tx: UART_TX_CTRL
  	port map (
  	SEND => sig_txNow,
  	DATA => sig_txData,
  	CLK => clk_100,
  	READY => sig_txDone,
  	UART_TX => txData -- output serial line
  	);    	
  	
  rx : UART_RX_CTRL
   port map(
	   RxD => rxData, -- input serial line
	   sysclk => clk_100,
	   reset => reset, 
	   rxDone => sig_rxdone,
	   rcvDataReg => sig_rxData,
		dataReady => sig_rxNow,
		setOE => sig_ovErr,
		setFE =>  sig_framerr
   );   	
  	
 end struct;
