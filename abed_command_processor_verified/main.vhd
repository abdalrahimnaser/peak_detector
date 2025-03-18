library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity Main is
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
--    fifo_wr_en : out std_logic
  );
end Main; 

architecture MAIN_FSM of Main is
  type state_type is (IDLE, char_COMBINE, TMP,PATTERN_RECOGNITION, PATTERN_0, PATTERN_1, PATTERN_2, WAIT_0);
  signal current_state, next_state : state_type; 
  
  -- Registered outputs
  signal dp_start_reg, pr_start_reg, send_reg : std_logic;
  signal char_reg                               : std_logic_vector(31 downto 0) := (others => '0');
  signal deviceOutput_current, deviceOutput_next                            : std_logic_vector(7 downto 0):=(others => '0'); --do this for the rest
  signal num2, num1, num0                      : std_logic_vector(3 downto 0);
  signal num5, num4, num3                      : std_logic_vector(7 downto 0);
  signal dataResults_reg,dataResults_reg_next                       : std_logic_vector(55 downto 0) := (others => '0');
  signal maxIndex_reg, maxIndex_reg_next                          : std_logic_vector(11 downto 0) := (others => '0');
  signal tmp5, tmp4, tmp3                      : std_logic_vector(7 downto 0);
  signal counter                               : integer := 0;
  signal pattern_0_current, pattern_0_next: std_logic_vector(15 downto 0);
  signal en_cnt,rst_cnt : std_logic:='0';
  signal test_reg : std_logic_vector(7 downto 0);
  signal pattern_reg: std_logic_vector(1 downto 0);
  signal hex_disp_reg, space_reg : std_logic := '0';
begin

process(clk)
begin
if rising_edge(clk) then
if deviceInputReady = '1' then
    char_reg <= char_reg(23 downto 0) & deviceInput;
end if;
end if;
end process;


-- ascii to bcd conversion

  -- ASCII to BCD conversion (char_reg format: "ANNN")
  num2 <= std_logic_vector(resize(unsigned(char_reg(23 downto 16)) - 48, 4));
  num1 <= std_logic_vector(resize(unsigned(char_reg(15 downto 8))  - 48, 4));
  num0 <= std_logic_vector(resize(unsigned(char_reg(7 downto 0))   - 48, 4));

  -- BCD to ASCII conversion (maxIndex_reg: 12-bit binary to 3 ASCII bytes)
  tmp5 <= "0000" & maxIndex_reg(11 downto 8);
  tmp4 <= "0000" & maxIndex_reg(7 downto 4);
  tmp3 <= "0000" & maxIndex_reg(3 downto 0);
  
  num5 <= std_logic_vector(unsigned(tmp5) + 48);
  num4 <= std_logic_vector(unsigned(tmp4) + 48);
  num3 <= std_logic_vector(unsigned(tmp3) + 48);

--state transition -- synchronous reset (figure out what rst implementation we need to do sync/non-sync)
process(clk) 
begin
    if rising_edge(clk) then
        if rst = '1' then
            current_state <= IDLE;
        else 
            current_state <= next_state;
            deviceOutput_current <= deviceOutput_next;
            pattern_0_current <= pattern_0_next;
            maxIndex_reg <= maxIndex_reg_next;
            dataResults_reg <= dataResults_reg_next;
        end if;
    end if;
end process;


--process(clk) 
--begin
--    if rising_edge(clk) then
--        if en_cnt_4 = '1' then
--            if deviceInputReady='1' then
--                counter <= counter + 1;
--                char_reg <= char_reg(23 downto 0) & deviceInput;
--             end if;
--        else 
--            counter <= 0;
--        end if;
 
--        end if;
--end process;


--process(en_cnt_4, deviceInputReady)
--begin
--    if en_cnt_4 = '1' then
--        if deviceInputReady = '1' then
--             char_reg <= char_reg(23 downto 0) & deviceInput;
--             counter <= counter + 1;
--        end if;
--    else
--        counter <= 0;
--    end if;
--end process;

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


-- In clocked process
--en_cnt_4 <= '1' when (current_state = char_COMBINE) else '0';

-- Then use en_cnt_4_reg in other processes

-- next state logic



process(current_state,deviceInputReady, deviceOutputSent, recogniseDone, dataReady, seqDone)
begin
    -- assign defaults here (remember process is sequential)
    dp_start_reg <= '0';
    pr_start_reg <= '0';
    send_reg <= '0';
    hex_disp_reg <= '0';
    space_reg <= '0';
    en_cnt <= '0';
    rst_cnt<= '1';
    next_state <= current_state;
    maxIndex_reg_next <= maxIndex_reg;
    dataResults_reg_next <= dataResults_reg;
    pattern_0_next <= pattern_0_current;
    deviceOutput_next <= deviceOutput_current;
    
     case current_state is
        when IDLE =>
            if deviceInputReady = '1' then
                send_reg <= '1';
                pr_start_reg <= '1';
                deviceOutput_next <= deviceInput;
            end if;

            if recogniseDone = '1' then 
                next_state <= PATTERN_RECOGNITION;
            end if;

        when char_COMBINE =>
--            rst_cnt_4 <= '0';
--            if counter = 3 then
--                next_state <= char_DETECTED;
--            else
--                if deviceInputReady = '1' then
--                    en_cnt_4 <= '1';
--                else
--                    en_cnt_4 <= '0';
--                end if;
--            end if;
                 
             

        
        
--            if counter = 4 then
--                next_state <=char_DETECTED;
--                end if;

        when TMP =>
            next_state <= WAIT_0;
--            if counter = 4 then
--                next_state <= char_DETECTED;
--            else
--                counter <= counter + 1;
--                if deviceInputReady = '1' then
--                    next_state <= char_COMBINE;
--                    char_reg <= char_reg(23 downto 0) & deviceInput;

--                end if;
--            end if;
        
        
        when PATTERN_RECOGNITION =>
                -- use case pattern
                if    pattern = "00" then 
                        next_state <= PATTERN_0;
                elsif pattern = "01" then  
                        next_state <= PATTERN_1;
                elsif pattern = "10" then  
                        next_state <= PATTERN_2;
                else   
                        next_state <= IDLE;
                end if;
--        when PATTERN_ELSE =>
--            -- should i define a pattern_reg and assign it the pattern val in char detected?
--            if pattern = "01" then
--                deviceOutput_reg <= dataResults_reg(31 downto 24) & x"20" & num5 & num4 & num3 & x"2020";
--            elsif pattern = "10" then
--                deviceOutput_reg <= dataResults_reg; -- should bytes be spaced out????
--            elsif pattern = "11" then
--                deviceOutput_reg <= x"696E76616C6964"; -- "invalid"                        
--            end if;
            
--            send_reg <= '1';
--            next_state <= IDLE;
    when PATTERN_1 =>
            rst_cnt <= '0';
            send_reg <= '1';
            space_reg <= '0';
            hex_disp_reg <= '0';
            en_cnt <= '1';     
                  
            if deviceOutputSent = '0' then
                en_cnt <= '0';
                send_reg <= '0';
            end if;              
             
            if counter = 0 then
                deviceOutput_next <= dataResults_reg(31 downto 24);
                space_reg <= '1';
                hex_disp_reg <= '1';
            elsif counter = 1 then
                deviceOutput_next <= num4;
            elsif counter = 2 then
                deviceOutput_next <= num5;
            elsif counter = 3 then
                deviceOutput_next <= num5;
                space_reg <= '1';
            else 
                next_state <= IDLE;
            end if;

       when PATTERN_2 =>
            rst_cnt <= '0';
            send_reg <= '1';
            en_cnt <= '1'; 
            space_reg <= '1';
            hex_disp_reg <= '1';
                      
            if deviceOutputSent = '0' then
                en_cnt <= '0';
                send_reg <= '0';
            end if;  
            
            if counter = 0 then
                    deviceOutput_next <= dataResults_reg(55 downto 48);
                elsif counter = 1 then
                    deviceOutput_next <= dataResults_reg(47 downto 40);
                elsif counter = 2 then
                    deviceOutput_next <= dataResults_reg(39 downto 32);
                elsif counter = 3 then
                    deviceOutput_next <= dataResults_reg(31 downto 24);
               elsif counter = 4 then
                    deviceOutput_next <= dataResults_reg(23 downto 16);
               elsif counter = 5 then
                    deviceOutput_next <= dataResults_reg(15 downto 8);
                elsif counter = 6 then 
                    deviceOutput_next <= dataResults_reg(7 downto 0);
                else
                    next_state <= IDLE;

                end if;



        when PATTERN_0 =>
            dp_start_reg <= '1';
            send_reg <= '1';
            space_reg <= '1';
            hex_disp_reg <= '1';   
            
            if deviceOutputSent = '0' then
                dp_start_reg <= '0';
                send_reg <= '0';
            end if;
            
            if dataReady = '1' then
                deviceOutput_next <= byte;
            end if;
            
           if seqDone = '1' then
                maxIndex_reg_next <= maxIndex;
                dataResults_reg_next <= dataResults;
                deviceOutput_next <= x"0D"; -- carriage return and line feed CRLF (TODO: add this as a feature in IO)
                hex_disp_reg <= '0';   
                next_state <= IDLE;
                send_reg <= '1'; --since it will go zero at idle
           end if;

             
        when WAIT_0 =>
--           if seqDone = '1' then
--                next_state <= IDLE;
                
--           elsif deviceOutputSent = '1' then
--                next_state <= PATTERN_0;
--            end if;
    
    end case;

end process;

-- Output assignments
dp_start <= dp_start_reg;
pr_start <= pr_start_reg;
send     <= send_reg;
--char      <= char_reg;
deviceOutput   <= deviceOutput_current;
char <= deviceInput;
numWords <= num2&num1&num0; -- bcd(char)

 hex_disp <= hex_disp_reg;
 space <= space_reg;             


end MAIN_FSM;
