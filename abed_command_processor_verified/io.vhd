library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity IO is
    port (
        clk           : in  std_logic;
        rst           : in  std_logic;
        data_o        : in  std_logic_vector(7 downto 0);
        send          : in  std_logic;        -- Send trigger
        valid         : in  std_logic;       -- Receive data valid
        txDone        : in  std_logic;       -- Transmission complete
        rxdata        : in  std_logic_vector(7 downto 0);  -- Received data
        sendDone      : out std_logic;       -- Send completion
        data_in       : out std_logic_vector(7 downto 0);  -- Received data output
        receiveDone   : out std_logic;       -- Receive completion
        txNow         : out std_logic;       -- Transmit trigger
        txdata        : out std_logic_vector(7 downto 0);  -- Data to transmit
        current_state_sim_io : out std_logic_vector(1 downto 0);
        done: out std_logic
    );
end IO;

architecture FSM of IO is
    type state_type is (IDLE, START_TRANSMISSION,SENDING, RECEIVING, START_RECEIVING);
    signal current_state, next_state : state_type;
    signal txdata_reg, rxdata_reg: std_logic_vector(7 downto 0):=(others => '0');
begin

-- State register
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

-- Next state and output logic
process(current_state, send, valid, txDone)
begin
    -- Default outputs
    done <= '0'; -- later map done and receivedone to the same sig
    txNow <= '0';
    receiveDone <= '0';
    next_state <= current_state;
    sendDone <= '1';
    case current_state is
        when IDLE =>
            if send = '1' then
                next_state <= START_TRANSMISSION;
            elsif valid = '1' then 
                next_state <= START_RECEIVING;
            end if;

        when START_TRANSMISSION =>
            sendDone <= '0';
            txdata_reg <= data_o;
            txNow <= '1';
            next_state <= SENDING;
            
        when START_RECEIVING =>
            rxdata_reg <= rxdata;
            done <= '1';
            receiveDone <= '1';
            next_state <= IDLE;
--            if valid = '0' then
--                next_state <= RECEIVING;
--            end if;
            
        when SENDING =>
            sendDone <= '0';
            if txDone = '1' then       -- Wait for transmission complete
                next_state <= IDLE;
            end if;
        
        when RECEIVING =>
--            receiveDone <= '1';
            next_state <= IDLE;

    end case;
end process;

-- Simulation state output
current_state_sim_io <= "00" when current_state = IDLE else
                        "01" when current_state = SENDING else
                        "11"; -- RECEIVING

txdata <= txdata_reg; 
data_in <= rxdata_reg;
           
end FSM;
