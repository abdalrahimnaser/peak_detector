library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity main  is
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
end main ;

architecture FSM of main  is
    type send_state_type is (STATE0, STATE1, STATE2);
    signal send_state : send_state_type := STATE0;
    
    type receive_state_type is (STATE0, STATE1, STATE2);
    signal receive_state : receive_state_type := STATE0;
    
    signal counter : integer range 0 to 7 := 0;
    signal rdata_send : STD_LOGIC_VECTOR(55 downto 0) := (others => '0');
    signal rdata_receive : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');

begin
    process(clk, rst)
    begin
        if rst = '1' then
            rdata_send <= (others => '0');
            sendDone <= '0';
            receiveDone <= '0';
            counter <= 0;
            send_state <= STATE0;
            receive_state <= STATE0;
            txnow <= '0';
            rxdone <= '0';
            data_in <= (others => '0');
        elsif rising_edge(clk) then
            
            case send_state is
                when STATE0 =>
                    sendDone <= '0';
                    txnow <= '0';
                    if send = '1' then
                        rdata_send <= data_o;
                        send_state <= STATE1;
                        counter <= 0;
                    end if;
                    
                when STATE1 =>
                    if counter < 7 then
                        txnow <= '1';
                        data_in <= rdata_send((counter+1)*8-1 downto counter*8);
                        if txdone = '1' then
                           rdata_send <= rdata_send(55 downto 8) & x"00"
                           counter <= counter + 1;
                        end if;
                    else
                        send_state <= STATE2;
                    end if;
                    
                when STATE2 =>
                    txnow <= '0';
                    sendDone <= '1';
                    send_state <= STATE0;
                    
                when others =>
                    send_state <= STATE0;
            end case;

          
            case receive_state is
                when STATE0 =>
                    receiveDone <= '0';
                    rxdone <= '0';
                    if rxnow = '1' then
                        receive_state <= STATE1;
                        counter <= 0;
                        rdata_receive <= (others => '0');
                    end if;
                    
                when STATE1 =>
                    if counter < 4 then
                        rdata_receive <= rdata_receive(31 downto 8) & x"00"；
                        rdata_receive(7 downto 0) <= rxdata;
                        rxdone <= '1';
                        counter <= counter + 1;
                    else
                        receive_state <= STATE2;
                    end if;
                    
                when STATE2 =>
                    receiveDone <= '1';
                    data_in <= rdata_receive;
                    receive_state <= STATE0;
                    
                when others =>
                    receive_state <= STATE0;
            end case;
        end if;
    end process;

end FSM;
