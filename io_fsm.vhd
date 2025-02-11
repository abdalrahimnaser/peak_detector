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
        data_in : out std_logic_vector(7 downto 0);
        receiveDone : out std_logic;  --doesnt get used in the FSM we made today? 11/02
	done  : out std_logic;
	txNow : out std_logic;
	txdata : out  std_logic_vector(7 downto 0)

	 );
end main;

architecture FSM of main is
	type state_type is (IDLE, S1, S2, S3);
	signal current_state, next_state : state_type;
 	signal count : integer := 0;
	signal data_o_reg : std_logic_vector(55 downto 0);

begin

process(clk) 
begin
	if rising_edge(clk) then
		if rst = '1' then    
			sendDone <= '1';  --not sure about this? perhaps 0?
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
			receiveDone <= '1';
			count <= 0;
			done <= '1';
			if send = '1' then
				receiveDone <= '0'; -- we didnt include this is FSM, not sure about this?
				data_o_reg <= data_o; --not sure if in right spot? (data_o could not be shifted itself(because its an input))
				next_state <= S1;
			end if;
			if valid = '1' then  
				next_state <= S3;
			end if;
			

		when S1 => 
			if count = 7 then
				next_state <= IDLE;
			else 
				if txdone = '1' then
					count <= count + 1;
					next_state <= S2;
				end if;
			end if;
			


		when S2 => 
			txnow <= '1'; 
			txdata <= data_o_reg(7 downto 0);
			if txdone = '0' then
				data_o_reg(47 downto 0) <= data_o_reg(55 downto 8);
				next_state <= S1;
			end if;


		when S3 => 
			data_in <= rxdata;
			done <= '1';
			next_state <= S3;
			
			
	end case;
end process;		
end FSM;


