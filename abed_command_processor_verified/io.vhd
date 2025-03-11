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
        done: out std_logic;
        hex_disp: in std_logic;
        space:    in std_logic
    );
end IO;

architecture FSM of IO is
    type state_type is (IDLE, START_TRANSMISSION, SENDING, RECEIVING, START_RECEIVING,
                        SEND_HEX_HIGH, WAIT_HEX_HIGH, SEND_HEX_LOW, WAIT_HEX_LOW,
                        SEND_HEX_SPACE, WAIT_HEX_SPACE);
    signal current_state, next_state : state_type;
    signal txdata_reg, rxdata_reg: std_logic_vector(7 downto 0) := (others => '0');
    signal hex_high_reg, hex_low_reg : std_logic_vector(3 downto 0) := (others => '0');
    signal space_reg, hex_disp_reg, space_reg_next, hex_disp_reg_next : std_logic := '0';
    
    function nibble_to_ascii(nibble : std_logic_vector(3 downto 0)) return std_logic_vector is
    begin
        case nibble is
            when x"0" => return x"30"; -- '0'
            when x"1" => return x"31"; -- '1'
            when x"2" => return x"32"; -- '2'
            when x"3" => return x"33"; -- '3'
            when x"4" => return x"34"; -- '4'
            when x"5" => return x"35"; -- '5'
            when x"6" => return x"36"; -- '6'
            when x"7" => return x"37"; -- '7'
            when x"8" => return x"38"; -- '8'
            when x"9" => return x"39"; -- '9'
            when x"A" => return x"41"; -- 'A'
            when x"B" => return x"42"; -- 'B'
            when x"C" => return x"43"; -- 'C'
            when x"D" => return x"44"; -- 'D'
            when x"E" => return x"45"; -- 'E'
            when x"F" => return x"46"; -- 'F'
            when others => return x"3F"; -- '?'
        end case;
    end function;

begin

-- State register
process(clk)
begin
    if rising_edge(clk) then
        if rst = '1' then
            current_state <= IDLE;
        else
            current_state <= next_state;
            space_reg <= space_reg_next;
            hex_disp_reg <= hex_disp_reg_next;
        end if;
    end if;
end process;

-- Next state and output logic
process(current_state, send, valid, txDone, hex_disp, space, data_o, hex_high_reg, hex_low_reg, space_reg)
begin
    -- Default outputs
    done <= '0';
    txNow <= '0';
    receiveDone <= '0';
    next_state <= current_state;
    sendDone <= '1'; -- Default sendDone is high when not sending
    hex_disp_reg_next <= hex_disp_reg;
    space_reg_next <= space_reg;
    case current_state is
        when IDLE =>
            if send = '1' then
                next_state <= START_TRANSMISSION;
                space_reg_next <= space;
                hex_disp_reg_next <= hex_disp;
            elsif valid = '1' then 
                next_state <= START_RECEIVING;
            end if;

        when START_TRANSMISSION =>
            sendDone <= '0';
            if hex_disp_reg = '1' then
                hex_high_reg <= data_o(7 downto 4);
                hex_low_reg <= data_o(3 downto 0);
                next_state <= SEND_HEX_HIGH;
            else
                txdata_reg <= data_o;
                txNow <= '1';
                next_state <= SENDING;
            end if;

        when SEND_HEX_HIGH =>
            sendDone <= '0';
            txdata_reg <= nibble_to_ascii(hex_high_reg);
            txNow <= '1';
            next_state <= WAIT_HEX_HIGH;

        when WAIT_HEX_HIGH =>
            sendDone <= '0';
            if txDone = '1' then
                next_state <= SEND_HEX_LOW;
            else
                next_state <= WAIT_HEX_HIGH;
            end if;

        when SEND_HEX_LOW =>
            sendDone <= '0';
            txdata_reg <= nibble_to_ascii(hex_low_reg);
            txNow <= '1';
            next_state <= WAIT_HEX_LOW;

        when WAIT_HEX_LOW =>
            sendDone <= '0';
            if txDone = '1' then
                if space_reg = '1' then
                    next_state <= SEND_HEX_SPACE;
                else
                    next_state <= IDLE;
                end if;
            else
                next_state <= WAIT_HEX_LOW;
            end if;

        when SEND_HEX_SPACE =>
            sendDone <= '0';
            txdata_reg <= x"20"; -- ASCII space
            txNow <= '1';
            next_state <= WAIT_HEX_SPACE;

        when WAIT_HEX_SPACE =>
            sendDone <= '0';
            if txDone = '1' then
                next_state <= IDLE;
            else
                next_state <= WAIT_HEX_SPACE;
            end if;

        when SENDING =>
            sendDone <= '0';
            if txDone = '1' then
                if space_reg = '1' then
                    next_state <= SEND_HEX_SPACE;
                else
                    next_state <= IDLE;
                end if;
            else 
                next_state <= SENDING;
            end if;

        when START_RECEIVING =>
            rxdata_reg <= rxdata;
            done <= '1';
            receiveDone <= '1';
            next_state <= IDLE;

        when others =>
            next_state <= IDLE;

    end case;
end process;

-- Output assignments
txdata <= txdata_reg;
data_in <= rxdata_reg;

-- Simulation state output encoding
current_state_sim_io <= "00" when current_state = IDLE else
                        "01" when current_state = SENDING else
                        "10" when (current_state = SEND_HEX_HIGH or current_state = WAIT_HEX_HIGH or
                                    current_state = SEND_HEX_LOW or current_state = WAIT_HEX_LOW or
                                    current_state = SEND_HEX_SPACE or current_state = WAIT_HEX_SPACE) else
                        "11"; -- RECEIVING or others

end FSM;
