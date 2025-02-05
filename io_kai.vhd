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
        -- 新增的端口，用于与外部的信号交互
        txnow       : out STD_LOGIC;
        txdone      : in  STD_LOGIC;
        rxnow       : in  STD_LOGIC;
        rxdata      : in  STD_LOGIC_VECTOR(7 downto 0);
        rxdone      : out STD_LOGIC
    );
end IO;

architecture Behavioral of IO is
    signal counter : integer range 0 to 6 := 0; -- 调整到6，因为我们处理7个字节
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
            rxdone <= '0'; -- 初始化信号
        elsif rising_edge(clk) then
            -- Send Process
            if send = '1' and send_state = '0' then
                data_out_temp <= data_o; -- 准备发送数据
                send_state <= '1';
                counter <= 0;
            elsif send_state = '1' then
                if counter < 7 then -- 发送7个字节
                    txnow <= '1';
                    data_in <= data_out_temp((counter+1)*8-1 downto counter*8); -- 发送一个字节
                    if txdone = '1' then -- 检查发送完成信号
                        counter <= counter + 1;
                    end if;
                else
                    txnow <= '0';
                    send_state <= '0';
                    sendDone <= '1'; -- 发送完成
                    counter <= 0;
                end if;
            else
                sendDone <= '0';
                txnow <= '0';
            end if;

            -- Receive Process
            if rxnow = '1' and receive_state = '0' then -- 数据准备好接收
                receive_state <= '1';
                counter <= 0;
                data_in_temp <= (others => '0'); -- 重置临时存储
            elsif receive_state = '1' then
                if counter < 4 then -- 接收4个字节
                    data_in_temp((counter+1)*8-1 downto counter*8) <= rxdata;
                    counter <= counter + 1;
                    rxdone <= '1'; -- 信号告知已接收一个字节
                else
                    receive_state <= '0';
                    receiveDone <= '1'; -- 接收完成
                    data_in <= data_in_temp; -- 输出接收到的数据
                    counter <= 0;
                end if;
            else
                receiveDone <= '0';
                rxdone <= '0';
            end if;
        end if;
    end process;

end Behavioral;
