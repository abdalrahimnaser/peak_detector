library IEEE;
use IEEE.numeric_std.all;
use IEEE.std_logic_1164.all;

entity pr_v2 is
    port (
        clk : in std_logic;
        rst : in std_logic;
        start : in std_logic;
        cmd : in std_logic_vector(7 downto 0);
        pattern : out std_logic_vector(1 downto 0);
        recogniseDone : out std_logic
    );
end pr_v2;

architecture recogniserFSM of pr_v2 is
    type state_type is (IDLE, S1, S2, S3, S4, S5, S6);
    signal current_state, next_state : state_type;
    signal temp_pattern, current_pattern, next_pattern : std_logic_vector(1 downto 0);
    signal temp_recogniseDone : std_logic:='0';
   
begin

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                current_state <= IDLE;
                recogniseDone <= '0';
                current_pattern <= "11";
            else
                current_state <= next_state;
                recogniseDone <= temp_recogniseDone;
                current_pattern <= next_pattern;
            end if;
        end if;
    end process;

    process(current_state, start, cmd) --including only 'clk' in the sensitivity list was the only way i could get it work? possibly bad practice?
    begin
        temp_recogniseDone <= '0';
        next_state <= current_state;
        next_pattern <= current_pattern;
        case current_state is
            when IDLE =>
                if start = '1' then
                    if (cmd = std_logic_vector(to_unsigned(80, 8)) or cmd = std_logic_vector(to_unsigned(112, 8))) then
                        next_state <= S5;
                    elsif (cmd = std_logic_vector(to_unsigned(76, 8)) or cmd = std_logic_vector(to_unsigned(108, 8))) then
                        next_state <= S6;
                    elsif (cmd = std_logic_vector(to_unsigned(65, 8)) or cmd = std_logic_vector(to_unsigned(97, 8))) then
                        next_state <= S1;
                    end if;
                end if;

            when S1 =>
                if start = '1' then
                    if (cmd = std_logic_vector(to_unsigned(80, 8)) or cmd = std_logic_vector(to_unsigned(112, 8))) then
                        next_state <= S5;
                    elsif (cmd = std_logic_vector(to_unsigned(76, 8)) or cmd = std_logic_vector(to_unsigned(108, 8))) then
                        next_state <= S6;
                    elsif (cmd >= std_logic_vector(to_unsigned(48, 8)) and cmd <= std_logic_vector(to_unsigned(57, 8))) then
                        next_state <= S2;
                    else
                        next_state <= IDLE;
                    end if;
                end if;

            when S2 =>
                if start = '1' then
                    if (cmd = std_logic_vector(to_unsigned(80, 8)) or cmd = std_logic_vector(to_unsigned(112, 8))) then
                        next_state <= S5;
                    elsif (cmd = std_logic_vector(to_unsigned(76, 8)) or cmd = std_logic_vector(to_unsigned(108, 8))) then
                        next_state <= S6;
                    elsif (cmd >= std_logic_vector(to_unsigned(48, 8)) and cmd <= std_logic_vector(to_unsigned(57, 8))) then
                        next_state <= S3;
                    else
                        next_state <= IDLE;
                    end if;
                end if;

            when S3 =>
                if start = '1' then
                    if (cmd = std_logic_vector(to_unsigned(80, 8)) or cmd = std_logic_vector(to_unsigned(112, 8))) then
                        next_state <= S5;
                    elsif (cmd = std_logic_vector(to_unsigned(76, 8)) or cmd = std_logic_vector(to_unsigned(108, 8))) then
                        next_state <= S6;
                    elsif (cmd >= std_logic_vector(to_unsigned(48, 8)) and cmd <= std_logic_vector(to_unsigned(57, 8))) then
                        next_state <= S4;
                    else
                        next_state <= IDLE;
                    end if;
                end if;

            when S4 =>
                temp_recogniseDone <= '1';
                next_pattern <= "00";
                next_state <= IDLE;
            when S5 =>
                temp_recogniseDone <= '1';
                next_pattern <= "01";
                next_state <= IDLE;
                
                when S6 =>
                    temp_recogniseDone <= '1';
                    next_pattern <= "10";
                    next_state <= IDLE;
          end case;
    end process;

pattern <= current_pattern;

end recogniserFSM;
