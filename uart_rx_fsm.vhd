-- uart_rx_fsm.vhd: UART controller - finite state machine controlling RX side
-- Author(s): Vladyslav Yeroma (xyerom00)

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;



entity UART_RX_FSM is
    port(
       CLK        : in std_logic; -- CLock
       RST        : in std_logic; -- Reset
       DIN        : in std_logic; -- Input
       CNT        : in std_logic_vector(4 downto 0); -- Counter of Clock Ticks
       CNT_BITS   : in std_logic_vector(3 downto 0); -- Counter Of Recieved Bits
       RX_EN      : out std_logic; -- Receiver Enabler
       CNT_EN     : out std_logic;  -- Counter Enabler
       DOUT_VLD   : out std_logic -- Output Validation
    );
end UART_RX_FSM;



architecture behavioral of UART_RX_FSM is
   type type_state is (INACTIVE, PASS_START_BIT, RECIEVE_DATA, PASS_STOP_BIT, VALIDATE_DATA);
   signal state : type_state := INACTIVE;
begin
   process(CLK, RST)
    begin
        -- If reset is log. 1, then state stays INACTIVE
        if RST = '1' then
            state <= INACTIVE;
            DOUT_VLD <= '0';
            RX_EN <= '0';
            CNT_EN <= '0';
        -- Will only continue when we are on the start of the clock tick
        elsif rising_edge(CLK) then
            case state is
               -- If state is INACTIVE and input switches to 0, then we want to switch to PASS_START_BIT state and enable counter of Clock Ticks.
               -- Else counter stays disabled
                when INACTIVE =>
                    if DIN = '0' then
                        state <= PASS_START_BIT;
                        CNT_EN <= '1';
                    else
                        CNT_EN <= '0';
                    end if;

               -- If state is PASS_START_BIT we want to wait until Clock Ticks counter passes 16 ticks (Start Bit) + 8 ticks (middle of the 0. bit) = 24 (11000)
               -- Then we want to switch state to RECIEVE_DATA and enable our Reciever. Clock Ticks counter stays enabled
               -- Else Reciever stays disabled and we keep Clock Ticks counter enabled until it reaches 24 (11000)
                when PASS_START_BIT =>
                    if CNT = "11000" then
                        state <= RECIEVE_DATA;
                        RX_EN <= '1';
                        CNT_EN <= '1';
                    else
                        RX_EN <= '0';
                        CNT_EN <= '1';
                    end if;

               -- If state is RECIEVE_DATA we want to wait until Recieved Bits counter reaches value of 8 (1000)
               -- Then we want to switch state to PASS_STOP_BIT and disable our Reciever. Clock Ticks counter stays enabled
               -- Else Reciever stays enabled and we keep Clock Ticks counter enabled until Recieved Bits counter reaches 8 (1000)
                when RECIEVE_DATA =>
                    if CNT_BITS = "1000" then
                        state <= PASS_STOP_BIT;
                        RX_EN <= '0';
                        CNT_EN <= '1';
                    else
                        RX_EN <= '1';
                        CNT_EN <= '1';
                    end if;

               -- If state is PASS_STOP_BIT we want to wait until Clock Ticks counter reaches value of 16 (10000), which means it reached middle of the Stop Bit, and check if Stop Bit = 1
               -- Then we want to switch state to VALIDATE_DATA and disable our Clock Ticks counter. At the same time we change output validation to log. 1
               -- Else Clock Ticks counter stays enabled and output validation stays disabled until Clock Ticks counter reaches 16 (10000) (middle of the Stop Bit)
                when PASS_STOP_BIT =>
                    if CNT = "10000" and DIN = '1' then
                        state <= VALIDATE_DATA;
                        DOUT_VLD <= '1';
                        CNT_EN <= '0';
                    else
                        DOUT_VLD <= '0';
                        CNT_EN <= '1';
                    end if;

               -- If state is VALIDATE_DATA we want to switch state to INACTIVE and set all our output ports to log. 0, for then to wait until next transmission
                 when VALIDATE_DATA =>
                    state <= INACTIVE;
                    DOUT_VLD <= '0';
                    RX_EN <= '0';
                    CNT_EN <= '0';
               -- If state is undefined, we just do nothing
                when others => null;
            end case;
        end if;
    end process;
end architecture;
