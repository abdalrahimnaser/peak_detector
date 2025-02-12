library IEEE;
use IEEE.numeric_std.all;
use IEEE.std_logic_1164.all;

entity IO is
    port (
        clk : in std_logic;
        rst : in std_logic;
	data_o  : in std_logic_vector(55 downto 0);
        send  : in  std_logic;
	valid : in std_logic; 
	txDone : in  std_logic;
	rxdata  : in  std_logic_vector(7 downto 0);
	-------------------------
        sendDone : out std_logic; -- we didnt account for this in FSM
        data_in : out std_logic_vector(7 downto 0);
        receiveDone : out std_logic;  --doesnt get used in the FSM we made today? 11/02
	done  : out std_logic;
	txNow : out std_logic;
	txdata : out  std_logic_vector(7 downto 0);
	current_state_sim: out std_logic_vector(1 downto 0)

	 );
end IO;

architecture FSM of IO is
	type state_type is (IDLE, S1, S2, S3);
	signal current_state, next_state : state_type;
 	signal count : integer := 0;
	signal data_o_reg : std_logic_vector(55 downto 0);

begin

process(clk) 
begin
	if rising_edge(clk) then
		if rst = '1' then    
			-- txNow <= '0'; for some reason this causes undef state for txNow.
			receiveDone <= '0';
        	current_state <= IDLE;
			sendDone <= '0';
			-- done <= '0'; same as txNow;
			
        	else 
        		current_state <= next_state;
        	end if;
	end if;
end process;

process(current_state, send, valid, txDone)
begin	
	case current_state is
		when IDLE =>
			sendDone <= '0';
			receiveDone <= '0';
			count <= 0;
			done <= '1';
			if send = '1' then
--				sendDone <= '0'; --not sure for this either
				data_o_reg <= data_o; --not sure if in right spot? (data_o could not be shifted itself(because its an input))
				next_state <= S1;
			elsif valid = '1' then -- (abed): changed if to elseif  
				next_state <= S3;
			end if;
			

		when S1 => 
			if count = 8 then
				receiveDone <= '1';
				next_state <= IDLE;
			else 
				if txDone = '1' then
					count <= count + 1;
					next_state <= S2;
				end if;
			end if;
			


		when S2 => 
			txdata <= data_o_reg(7 downto 0);
			txNow <= '1';  -- (abed): swapped its loc with the line above as case-when is sequential
			if txDone = '0' then
				data_o_reg <= std_logic_vector(shift_right(unsigned(data_o_reg), 8)); -- (abed): built-in more-readable shifting func
				txNow <= '0';
				next_state <= S1;
			end if;


		when S3 => 
--			receiveDone <= '0'; -- we didnt include this is FSM, not sure about this?
			done <= '0';
			data_in <= rxdata;
			next_state <= IDLE;		
			receiveDone <= '1';

	end case;
end process;		

current_state_sim <= "00" when current_state = IDLE else
             "01" when current_state = S1 else
             "10" when current_state = S2 else
             "11";



end FSM;




