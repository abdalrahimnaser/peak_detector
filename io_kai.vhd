library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity IO is
    Port (
        clk         : in  STD_LOGIC;
        rst         : in  STD_LOGIC;
        data_o      : in STD_LOGIC_VECTOR(55 downto 0);
        send        : in  STD_LOGIC;
        sendDone    : out STD_LOGIC;
        data_in     : out STD_LOGIC_VECTOR(31 downto 0);
        receiveDone : out STD_LOGIC;
        txnow       : out STD_LOGIC;
        txdone      : in  STD_LOGIC;
        rxnow       : in  STD_LOGIC;
        rxdata      : in  STD_LOGIC_VECTOR(7 downto 0);
        rxdone      : out STD_LOGIC
    );
end IO;

architecture Behavioral of IO is
    signal counter : integer range 0 to 6 := 0; 
    signal data_out_temp : STD_LOGIC_VECTOR(55 downto 0) := (others => '0');
    signal data_in_temp : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal send_state : STD_LOGIC := '0';
    signal receive_state : STD_LOGIC := '0';

begin
    process(clk, rst)
    begin
        if rst = '1' then
            data_out_temp <= (others => '0');
            sendDone <= '0';
            receiveDone <= '0';
            counter <= 0;
            send_state <= '0';
            receive_state <= '0';
            txnow <= '0';
            rxdone <= '0'; 
        elsif rising_edge(clk) then
            
            if send = '1' and send_state = '0' then
                data_out_temp <= data_o; 
                send_state <= '1';
                counter <= 0;
            elsif send_state = '1' then
                if counter < 7 then 
                    txnow <= '1';
                    data_in <= data_out_temp((counter+1)*8-1 downto counter*8); 
                    if txdone = '1' then 
                        counter <= counter + 1;
                    end if;
                else
                    txnow <= '0';
                    send_state <= '0';
                    sendDone <= '1'; 
                    counter <= 0;
                end if;
            else
                sendDone <= '0';
                txnow <= '0';
            end if;

            -- Receive Process
            if rxnow = '1' and receive_state = '0' then 
                receive_state <= '1';
                counter <= 0;
                data_in_temp <= (others => '0'); 
            elsif receive_state = '1' then
                if counter < 4 then 
                    data_in_temp((counter+1)*8-1 downto counter*8) <= rxdata;
                    counter <= counter + 1;
                    rxdone <= '1'; 
                else
                    receive_state <= '0';
                    receiveDone <= '1'; 
                    data_in <= data_in_temp; 
                    counter <= 0;
                end if;
            else
                receiveDone <= '0';
                rxdone <= '0';
            end if;
        end if;
    end process;

end Behavioral;
