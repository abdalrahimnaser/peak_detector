library IEEE;
use IEEE.numeric_std.all;
use IEEE.std_logic_1164.all;

entity main is
    port (
        clk : in std_logic;
        rst : in std_logic;
	data_o  : in std_logic_vector(55 downto 0);
        send  : in  std_logic;
	valid : in std_logic; 
	txDone : in  std_logic;
	rxdata  : in  std_logic_vector(7 downto 0);
	-------------------------
        sendDone : out std_logic;
        data_in : out std_logic_vector(31 downto 0);
        receiveDone : out std_logic;
	done  : out std_logic;
	txNow : out std_logic;
	data : out  std_logic_vector(7 downto 0)

	 );
end main;

architecture FSM of main is
	type state_type is (IDLE, RECIEVE, TRANSMIT);
	signal current_state, next_state : state_type;
	signal data_in_temp : std_logic_vector(31 downto 0) := (others => '0');  --are these 3 lines necessary?
 	signal byte_index : integer := 0;

begin

process(clk) 
begin
	if rising_edge(clk) then
		if rst = '1' then    
			done <= '1';
			data_in_temp <= (others => '0');
			data_in <= (others => '0');
			sendDone <= '1';  --not sure about this? perhaps 0?
			--byte_index <= 0; --program doesnt like this?
			txNow <= '1';
			receiveDone <= '1';
        		current_state <= IDLE;
        	else 
        		current_state <= next_state;
        	end if;
	end if;
end process;

process(current_state)
begin	
	case current_state is
		when IDLE =>
			if valid = '1' then  -- not sure about this? which one to prioritise?
				next_state <= RECIEVE;
			end if;
			if send = '1' then
				next_state <= TRANSMIT;
			end if;

		when RECIEVE => 
			if rxdata /= "00000000" then -- when user is sending data(rxdata is not empty)
				receiveDone <= '0';  -- process currently underway
				done <= '0';
				data_in_temp(31 downto 8) <= data_in_temp(23 downto 0);  -- characters 2,3 and 4 get shifted to positions 1,2 and 3
            			data_in_temp(7 downto 0) <= rxdata;	-- data transmitted by user gets stored in position 4
			else
				done <= '1'; --when user is no longer transmitting data
				receiveDone <= '1';
				data_in <= data_in_temp; --send data_in to main sub-module
				data_in_temp <= (others => '0'); --reset register, ready to recieve next user input
			end if;
			next_state <= IDLE;

		when TRANSMIT =>
			if txDone = '1' then -- when transmitter is ready and there is no current process:
				txNow <= '1';
				byte_index <= 0;
                		sendDone <= '0';
			else
                		data <= data_o(byte_index*8+7 downto byte_index*8); -- each byte 0-7 in incremented through, (chatgpt helped with this line)
                		if byte_index = 6 then  -- when final byte has reached, set operation as completed
                    			sendDone <= '1';
                    			txNow <= '0';
               			else
                    			byte_index <= byte_index + 1;
                		end if;
           		end if;
			next_state <= IDLE;
	end case;
end process;		
end FSM;
