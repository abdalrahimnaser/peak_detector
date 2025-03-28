----------------------------------------------------------------------------------
-- Institution: University of Bristol 
-- Student: Abdalrahim Naser & Ben Jack
-- 
-- Description: UART input-output handling unit
-- Module Name: IO - Behavioral
-- Project Name: Peak Detector
-- Target Devices: artix-7 35t cpg236-1
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity IO is
    port (
        clk           : in  std_logic;
        rst           : in  std_logic;
        deviceOutput        : in  std_logic_vector(7 downto 0);
        send          : in  std_logic;        -- send trigger
        valid         : in  std_logic;       -- receive data valid
        txDone        : in  std_logic;       -- transmission complete
        rxdata        : in  std_logic_vector(7 downto 0);  -- received data
        deviceOutputSent      : out std_logic;       -- send completion
        deviceInput       : out std_logic_vector(7 downto 0);  -- received data output
        deviceInputReady   : out std_logic;       -- receive completion
        txNow         : out std_logic;       -- transmit trigger
        txdata        : out std_logic_vector(7 downto 0);  -- data to transmit
        done: out std_logic;
        hex_disp: in std_logic;
        space:    in std_logic;
        newline:  in std_logic
    );
end IO;

architecture FSM of IO is
    -- state defintion
    type state_type is (IDLE, START_TRANSMISSION, SENDING, START_RECEIVING, ECHO,
                        SEND_HEX_HIGH, WAIT_HEX_HIGH, SEND_HEX_LOW, WAIT_HEX_LOW,
                        SEND_SPACE, WAIT_SPACE,
                        SEND_CR, WAIT_CR,SEND_LF, WAIT_LF, WAIT_ECHO
                        );
    signal current_state, next_state : state_type;
    
    -- data regs
    signal txdata_reg, rxdata_reg: std_logic_vector(7 downto 0) := (others => '0');
    signal hex_high_reg, hex_low_reg : std_logic_vector(3 downto 0) := (others => '0');
    
    -- control signals
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

-- register transition
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

-- state transition logic
process(current_state, send, newline,valid, txDone, hex_disp, space, deviceOutput, hex_high_reg, hex_low_reg, space_reg)
begin
    -- defaults
    done <= '0';
    txNow <= '0';
    deviceInputReady <= '0';
    next_state <= current_state;
    deviceOutputSent <= '1'; 
    hex_disp_reg_next <= hex_disp_reg;
    space_reg_next <= space_reg;
    
    case current_state is
        when IDLE =>
            if newline = '1' then
                next_state <= SEND_CR;
            elsif send = '1' then
                next_state <= START_TRANSMISSION;
                space_reg_next <= space;
                hex_disp_reg_next <= hex_disp;
            elsif valid = '1' then 
                next_state <= START_RECEIVING;
            end if;
            
        when SEND_CR =>
            deviceOutputSent <= '0';
            txdata_reg <= x"0D";  -- carriage return
            txNow <= '1';
            next_state <= WAIT_CR;

        when WAIT_CR =>
            deviceOutputSent <= '0';
            if txDone = '1' then
                next_state <= SEND_LF;
            end if;

        when SEND_LF =>
            deviceOutputSent <= '0';
            txdata_reg <= x"0A";  -- line feed
            txNow <= '1';
            next_state <= WAIT_LF;

        when WAIT_LF =>
            deviceOutputSent <= '0';
            if txDone = '1' then
                next_state <= IDLE;
            end if;
            
        when START_TRANSMISSION =>
            deviceOutputSent <= '0';
            if hex_disp_reg = '1' then
                hex_high_reg <= deviceOutput(7 downto 4);
                hex_low_reg <= deviceOutput(3 downto 0);
                next_state <= SEND_HEX_HIGH;
            else
                txdata_reg <= deviceOutput;
                txNow <= '1';
                next_state <= SENDING;
            end if;

        when SEND_HEX_HIGH =>
            deviceOutputSent <= '0';
            txdata_reg <= nibble_to_ascii(hex_high_reg);
            txNow <= '1';
            next_state <= WAIT_HEX_HIGH;

        when WAIT_HEX_HIGH =>
            deviceOutputSent <= '0';
            if txDone = '1' then
                next_state <= SEND_HEX_LOW;
            end if;

        when SEND_HEX_LOW =>
            deviceOutputSent <= '0';
            txdata_reg <= nibble_to_ascii(hex_low_reg);
            txNow <= '1';
            next_state <= WAIT_HEX_LOW;

        when WAIT_HEX_LOW =>
            deviceOutputSent <= '0';
            if txDone = '1' then
                if space_reg = '1' then
                    next_state <= SEND_SPACE;
                else
                    next_state <= IDLE;
                end if;

            end if;

        when SEND_SPACE =>
            deviceOutputSent <= '0';
            txdata_reg <= x"20"; -- ascii space
            txNow <= '1';
            next_state <= WAIT_SPACE;

        when WAIT_SPACE =>
            deviceOutputSent <= '0';
            if txDone = '1' then
                next_state <= IDLE;

            end if;

        when SENDING =>
            deviceOutputSent <= '0';
            if txDone = '1' then
                if space_reg = '1' then
                    next_state <= SEND_SPACE;
                else
                    next_state <= IDLE;
                end if;

            end if;

        when START_RECEIVING =>
            rxdata_reg <= rxdata;
            txdata_reg <= rxdata;
            txNow <= '1';
            next_state <= ECHO;
        
        when ECHO =>
            deviceOutputSent <= '0';
            if txDone = '1' then
                next_state <= WAIT_ECHO;
            end if;
        
       when WAIT_ECHO =>
            deviceOutputSent <= '0';
            done <= '1';
            deviceInputReady <= '1';
            next_state <= IDLE; 
               
    end case;
end process;

-- output mapping
txdata <= txdata_reg;
deviceInput <= rxdata_reg;

end FSM;
