library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity main is
    Port (
        clk         : in  STD_LOGIC;
        rst         : in  STD_LOGIC;
        data_o      : in  STD_LOGIC_VECTOR(55 downto 0);
        send        : in  STD_LOGIC;
        sendDone    : out STD_LOGIC;
        data_in     : out STD_LOGIC_VECTOR(7 downto 0);
        receive     : in  STD_LOGIC;
        receiveDone : out STD_LOGIC;
        txnow       : out STD_LOGIC;
        txdone      : in  STD_LOGIC;
        rxnow       : in  STD_LOGIC;
        rxdata      : in  STD_LOGIC_VECTOR(7 downto 0);
        rxdone      : out STD_LOGIC;
        txdata      : out  std_logic_vector(7 downto 0)
    );
end main;

architecture FSM of main is
    
	type state_type is (IDLE, State1, State2, State3);
    
    signal current_state, next_state : state_type;
 	signal count : integer := 0;
    signal data_send    : STD_LOGIC_VECTOR(55 downto 0) := (others => '0');
    signal data_receive : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    
begin
process(clk) 
begin
	if rising_edge(clk) then
		    if rst = '1' then 
            
               data_send    <= (others => '0');
               data_receive <= (others => '0');
               sendDone      <= '0';
               receiveDone   <= '0';
               count       <= 0;
               txnow         <= '0';
               rxdone        <= '0';
               data_in       <= (others => '0');
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
                    sendDone <= '1';
                    receiveDone <= '1';
                    count <= 0;
                    if send = '1' then
                       data_send <= data_o;
                       count <= 0;
                       next_state <= State1;
                    end if;
                    if receive = '1' then  
                       next_state <= State3;
                    end if;          
 		       
 		        when State1 => 
			         if count = 7 then
				        next_state <= IDLE;
			         else if 
			         txdone = '1' then
			         data_in <= data_send((count+1)*8-1 downto count*8);
					 count <= count + 1;
					 end if;
					 next_state <= State2;
				end if;             
              
              
               when State2 => 
			        txnow <= '1'; 
			        txdata <= data_send(7 downto 0);
			        if txdone = '0' then
				    data_send(47 downto 0) <= data_send(55 downto 8);
				    next_state <= State1;
				    end if
				   
				       		
               when State3 => 
                    receiveDone <= '1'; 
                    data_in <= rxdata;
                    rxdone <= '1';
                    next_state <= IDLE;  
					 
       end case;
    end process;
end FSM;
