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
    type state_type is (IDLE, SENDING, RECEIVING);
    signal current_state, next_state : state_type;
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
process(current_state, send, valid, txDone, rxdata, data_o)
begin
    -- Default outputs
    sendDone <= '1';
    receiveDone <= '0';
    done <= '0'; -- later map done and receivedone to the same sig
    txNow <= '0';
    txdata <= (others => '0');
    data_in <= (others => '0');
    next_state <= current_state;

    case current_state is
        when IDLE =>
            if send = '1' then
                next_state <= SENDING;
                txdata <= data_o;      -- Latch output data
                txNow <= '1';          -- Start transmission
            elsif valid = '1' then
--                next_state <= RECEIVING;
                done <= '1';
                receiveDone <= '1';
                data_in <= rxdata;     -- Capture received data
            end if;

        when SENDING =>
            sendDone <= '0';
            if txDone = '1' then       -- Wait for transmission complete
--                sendDone <= '1';
                next_state <= IDLE;
            end if;

        when RECEIVING =>
--            receiveDone <= '1';
--            done <= '0';
--            next_state <= IDLE;

    end case;
end process;

-- Simulation state output
current_state_sim_io <= "00" when current_state = IDLE else
                        "01" when current_state = SENDING else
                        "11"; -- RECEIVING
end FSM;
