library IEEE;
use IEEE.numeric_std.all;
use IEEE.std_logic_1164.all;

entity main_pr is
    port (
        clk : in std_logic;
        rst : in std_logic;
        start : in std_logic; -- from 'main', signals that it's ready to transmit
        cmd : in std_logic_vector(31 downto 0); -- 4-character string from main
        pattern : out std_logic_vector(1 downto 0); -- 2-bit command that informs main of further instructions
        recogniseDone : out std_logic -- signals to main that the pattern recogniser is ready to receive data
    );
end main_pr;

architecture recogniser of main_pr is
    signal char_1 : std_logic_vector(7 downto 0);
    signal char_2 : std_logic_vector(7 downto 0);
    signal char_3 : std_logic_vector(7 downto 0);
    signal char_4 : std_logic_vector(7 downto 0);
begin
    char_1 <= cmd(31 downto 24); --splitting cmd into 4 seperate characters
    char_2 <= cmd(23 downto 16);
    char_3 <= cmd(15 downto 8);
    char_4 <= cmd(7 downto 0);


    process(clk, rst)
    begin
        if rst = '1' then
            pattern <= "UU"; -- reset to default "unrecognized" state
            recogniseDone <= '0'; -- default state during reset// changed it to zero (abed)
        elsif rising_edge(clk) then
            if start = '1' then
                recogniseDone <= '0';
                if (char_4 = std_logic_vector(to_unsigned(80, 8)) or char_4 = std_logic_vector(to_unsigned(112, 8))) then
                    pattern <= "01"; -- 'p' or 'P' as the last character
                elsif (char_4 = std_logic_vector(to_unsigned(76, 8)) or char_4 = std_logic_vector(to_unsigned(108, 8))) then
                    pattern <= "10"; -- 'l' or 'L' as the last character
                elsif (char_1 = std_logic_vector(to_unsigned(65, 8)) or char_1 = std_logic_vector(to_unsigned(97, 8))) and
                      (char_2 >= std_logic_vector(to_unsigned(48, 8)) and char_2 < std_logic_vector(to_unsigned(58, 8))) and
                      (char_3 >= std_logic_vector(to_unsigned(48, 8)) and char_3 < std_logic_vector(to_unsigned(58, 8))) and
                      (char_4 >= std_logic_vector(to_unsigned(48, 8)) and char_4 < std_logic_vector(to_unsigned(58, 8))) then
                    pattern <= "00"; -- first character is 'A' or 'a', followed by three digits
                else
                    pattern <= "11"; -- other criteria not met, pattern unrecognised
                end if;

                recogniseDone <= '1'; -- processing complete, ready to take next input from main
            end if;
        end if;
    end process;
end recogniser;
