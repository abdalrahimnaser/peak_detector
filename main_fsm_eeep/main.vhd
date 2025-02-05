library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
entity Main is
  port(
    clk,rst: in std_logic;
    sendDone: in std_logic;
    data_in: in std_logic_vector(31 downto 0);
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
    data_o: out std_logic_vector(55 downto 0);
    send: out std_logic;
    pr_start: out std_logic;
    cmd: out std_logic_vector(31 downto 0)
  );
end Main; 

architecture MAIN_FSM of Main is
  type state_type is (IDLE, CMD_DETECTED, PATTERN_0, PATTERN_ELSE, DATA_PROCESSING);
  signal current_state, next_state : state_type; 
  
  -- Registered outputs
  signal dp_start_reg, pr_start_reg, send_reg : std_logic;
  signal cmd_reg                               : std_logic_vector(31 downto 0);
  signal data_o_reg                            : std_logic_vector(55 downto 0);
  signal num2, num1, num0                      : std_logic_vector(3 downto 0);
  signal num5, num4, num3                      : std_logic_vector(7 downto 0);
  signal dataResults_reg                       : std_logic_vector(55 downto 0);
  signal maxIndex_reg                          : std_logic_vector(11 downto 0);
  signal tmp5, tmp4, tmp3                      : std_logic_vector(7 downto 0);


begin


-- ascii to bcd conversion

  -- ASCII to BCD conversion (cmd_reg format: "ANNN")
  num2 <= std_logic_vector(resize(unsigned(cmd_reg(23 downto 16)) - 48, 4));
  num1 <= std_logic_vector(resize(unsigned(cmd_reg(15 downto 8))  - 48, 4));
  num0 <= std_logic_vector(resize(unsigned(cmd_reg(7 downto 0))   - 48, 4));

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
        end if;
    end if;
end process;

-- next state logic
process(current_state, receiveDone, dataReady, sendDone, seqDone)
begin
    -- assign defaults here (remember process is sequential)
    dp_start_reg <= '0';
    pr_start_reg <= '0';
    send_reg <= '0';
    case current_state is
        when IDLE =>
            if receiveDone = '1' then
                next_state <= CMD_DETECTED;
            end if;
        when CMD_DETECTED =>
            cmd_reg <= data_in;
            pr_start_reg <= '1';
            if recogniseDone = '1' then
                if pattern = "00" then
                    next_state <= PATTERN_0;
                else
                    next_state <= PATTERN_ELSE;
                end if;
            end if;

        when PATTERN_ELSE =>
            -- should i define a pattern_reg and assign it the pattern val in cmd detected?
            if pattern = "01" then
                data_o_reg <= dataResults_reg(31 downto 24) & x"20" & num5 & num4 & num3 & x"2020";
            elsif pattern = "10" then
                data_o_reg <= dataResults_reg; -- should bytes be spaced out????
            elsif pattern = "11" then
                data_o_reg <= x"696E76616C6964"; -- "invalid"                        
            end if;
            
            send_reg <= '1';
            next_state <= IDLE;

        when PATTERN_0 =>
            -- cmd_reg = "ANNN", 
            numWords <= num2 & num1 & num0; -- bcd(cmd)
            dp_start_reg <= '1';
            next_state <= DATA_PROCESSING;
        when DATA_PROCESSING =>
            if dataReady='1' and sendDone='1' then
                data_o_reg  <= byte & x"202020202020"; -- Byte + 6 spaces
                send_reg <= '1';
                -- TODO: if data processor is faster than Io send
                -- then construct some sort of buffer and idk adjust 
                -- fsm accordingly
                -- even if it worked fine (dp isn't faster), do implement the mentioned above
                -- as a good design practice, and state that in the report.
                if seqDone='1' then
                    dataResults_reg <= dataResults;
                    maxIndex_reg <= maxIndex;
                    next_state <= IDLE;
                end if;

            end if;
    end case;

end process;

-- Output assignments
dp_start <= dp_start_reg;
pr_start <= pr_start_reg;
send     <= send_reg;
cmd      <= cmd_reg;
data_o   <= data_o_reg;

end MAIN_FSM;