----------------------------------------------------------------------------------
-- Institution: University of Bristol 
-- Student: Abdalrahim Naser
-- 
-- Description: Main control unit of the command processor 
-- Module Name: Controller - Behavioral
-- Project Name: Peak Detector
-- Target Devices: artix-7 35t cpg236-1
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.common_pack.all;

entity Controller is
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
end Controller; 

architecture FSM of Controller is
  -- state machine defintion
  type state_type is (IDLE, PATTERN_RECOGNISED, PATTERN_0, PATTERN_1, PATTERN_2, SEPERATOR_0, SEPERATOR_1, COUNTER_RESET);
  signal current_state, next_state : state_type; 
  
  -- control signals
  signal dp_start_reg, pr_start_reg, send_reg, newline_reg, hex_disp_reg, space_reg: std_logic;
  signal counter                               : integer := 0;
  signal en_cnt,rst_cnt : std_logic:='0';

  -- data regs
  signal char_reg                               : std_logic_vector(31 downto 0) := (others => '0');
  signal deviceOutput_current, deviceOutput_next                            : std_logic_vector(7 downto 0):=(others => '0'); --do this for the rest
  signal dataResults_reg,dataResults_reg_next  : CHAR_ARRAY_TYPE(0 to RESULT_BYTE_NUM-1);
  signal maxIndex_reg, maxIndex_reg_next       : BCD_ARRAY_TYPE(2 downto 0);
  
  -- conversion signals  
  signal num2, num1, num0                      : std_logic_vector(3 downto 0);
  signal num5, num4, num3                      : std_logic_vector(7 downto 0);
  signal tmp2, tmp1, tmp0                      : std_logic_vector(7 downto 0);

begin


-- ASCII to BCD conversion (char_reg format: "ANNN")
num2 <= std_logic_vector(resize(unsigned(char_reg(23 downto 16)) - 48, 4));
num1 <= std_logic_vector(resize(unsigned(char_reg(15 downto 8))  - 48, 4));
num0 <= std_logic_vector(resize(unsigned(char_reg(7 downto 0))   - 48, 4));

-- BCD to ASCII conversion (maxIndex_reg: 12-bit binary to 3 ASCII bytes)
tmp2 <= "0000" & maxIndex_reg(2);
tmp1 <= "0000" & maxIndex_reg(1);
tmp0 <= "0000" & maxIndex_reg(0);

num5 <= std_logic_vector(unsigned(tmp2) + 48);
num4 <= std_logic_vector(unsigned(tmp1) + 48);
num3 <= std_logic_vector(unsigned(tmp0) + 48);


-- register transition
process(clk) 
begin
    if rising_edge(clk) then
        if rst = '1' then
            current_state <= IDLE;
        else 
            current_state <= next_state;
            deviceOutput_current <= deviceOutput_next;
            maxIndex_reg <= maxIndex_reg_next;
            dataResults_reg <= dataResults_reg_next;
        end if;
    end if;
end process;


-- counter process
process(clk)
begin
if rising_edge(clk) then
    if rst_cnt = '1' then
        counter <= 0;
    elsif en_cnt = '1' then
        counter <= counter + 1;
    end if;
    end if;
end process;

-- command buffering
process(clk)
begin
if rising_edge(clk) then
if deviceInputReady = '1' then
    char_reg <= char_reg(23 downto 0) & deviceInput;
end if;
end if;
end process;


-- state transition logic
process(current_state,deviceInputReady, deviceOutputSent, recogniseDone, dataReady, seqDone)
begin
    -- defaults assignement
    dp_start_reg <= '0';
    pr_start_reg <= '0';
    send_reg <= '0';
    hex_disp_reg <= '0';
    space_reg <= '0';
    newline_reg <= '0';
    en_cnt <= '0';
    rst_cnt<= '1';
    next_state <= current_state;
    maxIndex_reg_next <= maxIndex_reg;
    dataResults_reg_next <= dataResults_reg;
    deviceOutput_next <= deviceOutput_current;
    
     case current_state is
        when IDLE =>
            if deviceInputReady = '1' then
                pr_start_reg <= '1';
            end if;

            if recogniseDone = '1' then 
                next_state <= SEPERATOR_0;
            end if;

        when PATTERN_RECOGNISED =>
                if    pattern = "00" then 
                        next_state <= PATTERN_0;
                elsif pattern = "01" then  
                        next_state <= PATTERN_1;
                elsif pattern = "10" then  
                        next_state <= PATTERN_2;
                else   
                        next_state <= IDLE;
                end if;
                
                
        when PATTERN_0 =>
                dp_start_reg <= '1';
                space_reg <= '1';
                hex_disp_reg <= '1';   
                
                if deviceOutputSent = '0' then
                    dp_start_reg <= '0';
                end if;
                
                if dataReady = '1' then
                    deviceOutput_next <= byte;
                    send_reg <= '1';
                    dp_start_reg <= '0';
                end if;
  
               if seqDone = '1' then
                    maxIndex_reg_next <= maxIndex;
                    dataResults_reg_next <= dataResults;
                    next_state <= SEPERATOR_1;
               end if;

        when PATTERN_1 =>
            rst_cnt <= '0';
            if deviceOutputSent = '1' then
                send_reg <= '1';
                en_cnt <= '1';
                case counter is
                    when 0 =>
                        deviceOutput_next <= dataResults_reg(3);
                        space_reg <= '1';
                        hex_disp_reg <= '1';
                    when 1 =>
                        deviceOutput_next <= num5;
                    when 2 =>
                        deviceOutput_next <= num4;
                    when 3 =>
                        deviceOutput_next <= num3;
                    when others =>
                        next_state <= COUNTER_RESET;
                        rst_cnt <= '1';
                        send_reg <= '0';
                end case;
            end if;
    
       when PATTERN_2 =>
            rst_cnt <= '0';
            space_reg <= '1';
            hex_disp_reg <= '1';
            if deviceOutputSent = '1' then  
                send_reg <= '1';
                en_cnt <= '1';
                case counter is
                    when 0 =>
                        deviceOutput_next <= dataResults_reg(0);
                    when 1 =>
                        deviceOutput_next <= dataResults_reg(1);
                    when 2 =>
                        deviceOutput_next <= dataResults_reg(2);
                    when 3 =>
                        deviceOutput_next <= dataResults_reg(3);
                    when 4 =>
                        deviceOutput_next <= dataResults_reg(4);
                    when 5 =>
                        deviceOutput_next <= dataResults_reg(5);
                    when 6 =>
                        deviceOutput_next <= dataResults_reg(6);
                    when others =>
                        next_state <= COUNTER_RESET;
                        rst_cnt <= '1';
                        send_reg <= '0';
                end case;
            end if;  
            
        when COUNTER_RESET => -- one cycle delay for counter to reset
            next_state <= SEPERATOR_1;
            
        when SEPERATOR_0 =>
            rst_cnt <= '0';
            if deviceOutputSent = '1' then
                en_cnt <= '1';
                if counter = 0 then
                    newline_reg <= '1';                   
                elsif counter < 5 then
                    send_reg <= '1';
                    deviceOutput_next  <= x"3D"; -- '=' symbol 
                else 
                    send_reg <= '0';
                    newline_reg <= '1'; 
                    next_state <= PATTERN_RECOGNISED;
                end if;                 
            end if; 
             
        when SEPERATOR_1 => 
            rst_cnt <= '0';
            if deviceOutputSent = '1' then
                en_cnt <= '1';
                if counter = 0 then
                    newline_reg <= '1';                   
                elsif counter < 5 then
                    send_reg <= '1';
                    deviceOutput_next  <= x"3D"; -- '=' symbol 
                else 
                    send_reg <= '0';
                    newline_reg <= '1'; 
                    next_state <= IDLE;
                end if;                 
            end if;      
            
    end case;

end process;

-- output mapping
dp_start <= dp_start_reg;
pr_start <= pr_start_reg;
send     <= send_reg;
deviceOutput <= deviceOutput_current;
char <= deviceInput;
hex_disp <= hex_disp_reg;
space <= space_reg;             
newline <= newline_reg;

numWords_bcd(2) <= num2;
numWords_bcd(1) <= num1;
numWords_bcd(0) <= num0;

end FSM;
