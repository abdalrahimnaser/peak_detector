library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.common_pack.all;

entity Controller is
  port(
    clk,rst: in std_logic;
    
    -- io interface
    deviceOutputSent: in std_logic;
    deviceInput: in std_logic_vector(7 downto 0);
    deviceInputReady: in std_logic;
    deviceOutput: out std_logic_vector(7 downto 0);
    send: out std_logic;
    hex_disp: out std_logic;
    space:    out std_logic;
    newline:  out std_logic;
    -- PR interface
    pattern: in std_logic_vector(1 downto 0);
    recogniseDone: in std_logic;
    char: out std_logic_vector(7 downto 0);
    pr_start: out std_logic;

    -- DP interface
    dataReady: in std_logic;
    byte: in std_logic_vector(7 downto 0);
    maxIndex: in std_logic_vector(11 downto 0);
    dataResults:  in CHAR_ARRAY_TYPE(0 to RESULT_BYTE_NUM-1);
    seqDone: in std_logic;
    dp_start: out std_logic;
    numWords: out std_logic_vector(11 downto 0)

  );
end Controller; 

architecture FSM of Controller is
  type state_type is (IDLE, PATTERN_RECOGNISED,PATTERN_0, PATTERN_1, PATTERN_2, TEMP);
  signal current_state, next_state : state_type; 
  signal dp_start_reg, pr_start_reg, send_reg, newline_reg : std_logic;
  signal char_reg                               : std_logic_vector(31 downto 0) := (others => '0');
  signal deviceOutput_current, deviceOutput_next                            : std_logic_vector(7 downto 0):=(others => '0'); --do this for the rest
  signal num2, num1, num0                      : std_logic_vector(3 downto 0);
  signal num5, num4, num3                      : std_logic_vector(7 downto 0);
  signal dataResults_reg,dataResults_reg_next  : CHAR_ARRAY_TYPE(0 to RESULT_BYTE_NUM-1);
  signal maxIndex_reg, maxIndex_reg_next                          : std_logic_vector(11 downto 0) := (others => '0');
  signal tmp5, tmp4, tmp3                      : std_logic_vector(7 downto 0);
  signal counter                               : integer := 0;
  signal pattern_0_current, pattern_0_next: std_logic_vector(15 downto 0);
  signal en_cnt,rst_cnt : std_logic:='0';
  signal test_reg : std_logic_vector(7 downto 0);
  signal pattern_reg: std_logic_vector(1 downto 0);
  signal hex_disp_reg, space_reg : std_logic := '0';
  signal deviceOutputSent_delayed: std_logic;
begin


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


-- register transition
process(clk) 
begin
    if rising_edge(clk) then
        if rst = '1' then
            current_state <= IDLE;
            deviceOutputSent_delayed <= '1';
        else 
            current_state <= next_state;
            deviceOutput_current <= deviceOutput_next;
            pattern_0_current <= pattern_0_next;
            maxIndex_reg <= maxIndex_reg_next;
            dataResults_reg <= dataResults_reg_next;
            deviceOutputSent_delayed <=deviceOutputSent;
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
    pattern_0_next <= pattern_0_current;
    deviceOutput_next <= deviceOutput_current;
    
     case current_state is
        when IDLE =>
            if deviceInputReady = '1' then
                pr_start_reg <= '1';
            end if;

            if recogniseDone = '1' then 
                next_state <= PATTERN_RECOGNISED;
                newline_reg <= '1';
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
                
--    when wait_pattern_0 =>
--         dp_start_reg <= '1';
--         next_state <= PATTERN_0;
                
    when PATTERN_0 =>
            dp_start_reg <= '1';
            send_reg <= '0';
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
                next_state <= TEMP;
           end if;


    when TEMP =>
        if deviceOutputSent = '1' then
            newline_reg <= '1';
            next_state <= IDLE;
        end if;


    when PATTERN_1 =>
        rst_cnt <= '0';
        send_reg <= '0';
        en_cnt <= '0';  -- Default to 0, only set on rising edge
        space_reg <= '0';
        hex_disp_reg <= '0';        
        
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
                next_state <= IDLE;
                send_reg <= '0';
                newline_reg <= '1';
        end case;
        end if;
    


       when PATTERN_2 =>
            rst_cnt <= '0';
            send_reg <= '0';
            en_cnt <= '0';  -- Default to 0, only set on rising edge
            space_reg <= '1';
            hex_disp_reg <= '1';
            
--            -- Detect rising edge of deviceOutputSent to increment counter
--            if (deviceOutputSent = '1' and deviceOutputSent_delayed = '0') then
--                en_cnt <= '1';
--            end if;
            
--            if deviceOutputSent = '0' then
--                send_reg <= '0';
--            end if;
        if   deviceOutputSent = '1' then  
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
                next_state <= IDLE;
                send_reg <= '0';
                newline_reg <= '1';
        end case;
        end if;
    end case;

end process;



-- output mapping
dp_start <= dp_start_reg;
pr_start <= pr_start_reg;
send     <= send_reg;
deviceOutput   <= deviceOutput_current;
char <= deviceInput;
numWords <= num2&num1&num0;
hex_disp <= hex_disp_reg;
space <= space_reg;             
newline <= newline_reg;

end FSM;
