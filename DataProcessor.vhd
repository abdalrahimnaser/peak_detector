library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common_pack.all;

entity dataConsume is
      port (
          clk:            in std_logic;
            reset:        in std_logic; 
            start:        in std_logic;
            numWords_bcd: in BCD_ARRAY_TYPE(2 downto 0);
            ctrlIn:       in std_logic; 
            ctrlOut:      out std_logic; 
            data:         in std_logic_vector(7 downto 0);
            dataReady:    out std_logic;
            byte:         out std_logic_vector(7 downto 0);
            seqDone:      out std_logic;
            maxIndex:     out BCD_ARRAY_TYPE(2 downto 0);
            dataResults:  out CHAR_ARRAY_TYPE(0 to RESULT_BYTE_NUM-1)
      );
end dataConsume;



architecture behavioural of dataConsume is
    --All signals declared
    type state_cmd is (WAIT_S, INIT, OUTPUT_STATE, INIT_START, PENDING, START_P, WAIT_START,PEAK_STAGE_1, PEAK_STAGE_2, PEAK_STAGE_3, FINISHED);

    signal curState : state_cmd := INIT;
    signal nextState : state_cmd := INIT;
    
    signal reg_numWords : integer := 0;
        
    signal reg_dataResult : CHAR_ARRAY_TYPE(0 to 5); 
    signal dataResults_current, dataResults_next : CHAR_ARRAY_TYPE(0 to RESULT_BYTE_NUM-1); 
    
    signal reg_Count : integer := 0;
    signal reg_Start : std_logic;
    
    signal ctrlIn_delayed, ctrlIn_detected : std_logic;
    signal reg_OUTPUT_STATE : std_logic;
    
    signal reg_peak : integer := 0;
    
    signal maxIndex_current, maxIndex_next : BCD_ARRAY_TYPE(2 downto 0); --this is new to try to reduce latches
    -------------------------------
    -- Converts Decimal to Binary using a BCD conversion
    -------------------------------
    function DecToBCD(input_dec : integer) return BCD_ARRAY_TYPE is
    variable bcd : BCD_ARRAY_TYPE(2 downto 0);
    begin
        bcd := (others => (others => '0')); -- Initialize bcd to 0
        -- Convert thousands digit
        bcd(2) := std_logic_vector(to_unsigned(input_dec / 100, 4));
        -- Convert hundreds digit
        bcd(1) := std_logic_vector(to_unsigned((input_dec mod 100) / 10, 4));
        -- Convert tens digit
        bcd(0) := std_logic_vector(to_unsigned((input_dec mod 100) mod 10, 4));
        return bcd;
    end DecToBCD;
    
    begin--This is the begin statement for the whole process
    
    -------------------------------
    -- Stores the previous value of ctrlIn that is used in moving states
    -- Part of the two-phase handshaking protocol
    -------------------------------
    delay_CtrlIn: process(clk)     
    begin
         if rising_edge(clk) then
            ctrlIn_delayed <= ctrlIn;
          end if;
    end process;
                
    -- ctrlIn_detected stays 0 if the same value is detected.
    --It only changes to '1' when ctrlIn changes its value.
    ctrlIn_detected <= ctrlIn xor ctrlIn_delayed;

    -------------------------------
    -- Where the next state is decided depending on the current state
    -------------------------------
    combi_nextState : process(curState, reg_Start, ctrlIn_detected, reg_Count, reg_numWords) -- registers referenced
    begin 
        case curState is        

            when INIT =>   
            -- set defaults here 
                if reg_Start = '1' then                 
                    nextState <= OUTPUT_STATE;
                else
                    nextState <= INIT;
                end if;
                    
            when OUTPUT_STATE =>
                nextState <= INIT_START;
                    
            when INIT_START =>
                if ctrlIn_detected = '1' then
                    nextState <= PENDING;
                else
                    nextState <= INIT_START;
                end if;
                
            when PENDING =>
                nextState <= START_P;
                
            when START_P =>  
                if reg_Count < reg_numWords then
                    nextState <= WAIT_START;
                else
                    nextState <= PEAK_STAGE_1;
                end if;
            
            when PEAK_STAGE_1 =>
                nextState <= PEAK_STAGE_2;
            
            when PEAK_STAGE_2 =>
                nextState <= PEAK_STAGE_3;
                
            when PEAK_STAGE_3 =>
                nextState <= FINISHED; 
                
            when WAIT_START =>
                if reg_Start = '1' then                 
                    nextState <= OUTPUT_STATE;
                else
                    nextState <= WAIT_START;
                end if;
              
            when FINISHED =>
                nextState <= WAIT_S;
                
            when WAIT_S =>
                nextState <= INIT;
            
            when others =>
                nextState <= INIT;
        
        end case;
    end process;
    
    -------------------------------
    -- Use to control the value of signal register of OUTPUT_STATE, depending on the current state
    -- Part of the two-phased handshake protocol.
    -------------------------------
    combi_assignCtr : process(clk)
    begin
        if clk'event and clk ='1' then   
            if curState = INIT then
                reg_OUTPUT_STATE <= '0';
            elsif curState = OUTPUT_STATE then
                reg_OUTPUT_STATE <= not reg_OUTPUT_STATE;
            end if; 
        end if;
    end process; 
    
    -------------------------------
    -- Assigns values for signals declared depending on what the current state is
    -- The signals are used for moving from one state to another depending on the value
    --Good to Go: 17/02/2025 used MUX protocol
    -------------------------------
    combi_storeReg : process(clk) 
    variable reg_peak : integer := 0;
    begin
        if rising_edge(clk) then
            case curState is
                when INIT =>
                    dataResults_next <= (others => (others => '0'));
                    reg_peak := -128;                
                    maxIndex <= (others => (others => '0'));
    
                when OUTPUT_STATE =>
                    dataResults_next <= dataResults_current;
    
                when PENDING =>
                    dataResults_next(0) <= data;
                    dataResults_next(1 to 6) <= dataResults_current(0 to 5);
                    
    
                when START_P =>
                   if signed(dataResults_current(3)) > reg_peak then
                        dataResults_next <= dataResults_current;
                        maxIndex_next <= DecToBCD(reg_Count - 4); --bcd convert count
                        reg_peak := to_integer(signed(dataResults_current(3)));
                    end if;
    
                when PEAK_STAGE_1 =>
                   if signed(dataResults_current(2)) > reg_peak and reg_Count = reg_numWords then
                        reg_peak := to_integer(signed(dataResults_current(2)));
                        dataResults_next <= (others => (others => '0'));
                        dataResults_next(1 to 6) <= dataResults_current(0 to 5);
                        maxIndex_next <= DecToBCD(reg_Count - 3);
                    end if;
    
                when PEAK_STAGE_2 =>
                    if signed(dataResults_current(1)) > reg_peak and reg_Count = reg_numWords then
                        reg_peak := to_integer(signed(dataResults_current(1)));
                        dataResults_next <= (others => (others => '0'));
                        dataResults_next(2 to 6) <= dataResults_current(0 to 4);
                        maxIndex_next <= DecToBCD(reg_Count - 2);
                    end if;
    
                when PEAK_STAGE_3 =>
                   if signed(dataResults_current(0)) > reg_peak and reg_Count = reg_numWords then
                        reg_peak := to_integer(signed(dataResults_current(0)));
                        dataResults_next <= (others => (others => '0'));
                        dataResults_next(3 to 6) <= dataResults_current(0 to 3);
                        maxIndex_next <= DecToBCD(reg_Count - 2);
                    end if;
    
                when others => 
                    null;
            end case;
        end if;
    end process;
                             

    -------------------------------
    -- Assigned values to the output signals seqDone, dataReady and byte depending on the current state
    -------------------------------
    assign_byte : process(clk)
    begin
        if rising_edge(clk) then    
            case curState is
                when FINISHED =>
                    seqDone   <= '1';
                    dataReady <= '0';
    
                when START_P =>
                    dataReady <= '1';
    
                when others =>
                    seqDone   <= '0';
                    dataReady <= '0';
            end case;
        end if;
    end process;
    
    -------------------------------
    -- Increases the value of the signal reg_Count or sets it to 0 depending on what the current state is
    -------------------------------
    combi_Counter : process(clk)
    begin
        if rising_edge(clk) then
            if curState = INIT_START and nextState = PENDING then
                reg_Count <= reg_Count + 1;
            elsif curState = FINISHED then
                reg_Count <= 0; -- Reset properly
            end if;
        end if;
    end process;
    
    -------------------------------
    -- Converts the binary in the array numWords to decimal using a BCD conversion 
    -- Stores the output in the signal reg_numwords when in the INIT state.
    -------------------------------
    combi_numWords_bcd : process(clk)
    begin 
            if rising_edge(clk) then
            if curState = INIT then
                reg_numWords <= to_integer(unsigned(numWords_bcd(2))) * 100 + 
                                to_integer(unsigned(numWords_bcd(1))) * 10 + 
                                to_integer(unsigned(numWords_bcd(0)));
            elsif curState = FINISHED then
                reg_numWords <= 0; -- Properly reset the value
            end if;
        end if;
    end process;

    -------------------------------
    -- Clock process is used to move from the current state to the next state. Causes a synchronous process
    -- Updates the start register with start and ctrlOut with the ctrlOut register 
    -- Part of the two-phased handshake protocol
    -------------------------------
    rising_edge_detection: process (clk, reset)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                curState <= INIT;
                dataResults_current <= (others => (others => '0'));
                maxIndex_current <= (others => (others => '0'));
            else
                curState  <= nextState;
                reg_Start <= start;
                ctrlOut   <= reg_OUTPUT_STATE;
                dataResults_current <= dataResults_next;
                maxIndex_current <= maxIndex_next;
            end if;
        end if;         
    end process rising_edge_detection;
 
byte <= data;
dataResults <= dataResults_current;
maxIndex <= maxIndex_current;


end behavioural;

--Last updated 17/02/2025
