-- uart_rx.vhd: UART controller - receiving (RX) side
-- Author(s): Vladyslav Yeroma (xyerom00)

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;


-- Entity declaration (DO NOT ALTER THIS PART!)
entity UART_RX is
    port(
        CLK      : in std_logic;
        RST      : in std_logic;
        DIN      : in std_logic;
        DOUT     : out std_logic_vector(7 downto 0);
        DOUT_VLD : out std_logic
    );
end entity;



-- Architecture implementation (INSERT YOUR IMPLEMENTATION HERE)
architecture behavioral of UART_RX is
  signal cnt: std_logic_vector(4 downto 0);
  signal cnt_bits: std_logic_vector(3 downto 0);
  signal vld: std_logic;
  signal rx_en: std_logic;
  signal cnt_en: std_logic;


begin

    FSM: entity work.UART_RX_FSM(behavioral)
   port map(
      CLK           =>  CLK,
      RST           =>  RST,
      DIN           =>  DIN,
      CNT           =>  cnt,
      CNT_BITS      =>  cnt_bits,
      DOUT_VLD      =>  vld,
      RX_EN         =>  rx_en,
      CNT_EN        =>  cnt_en
   );
   -- Will set output to 0 and validation status to current status from FSM
   DOUT_VLD <= vld;

process(CLK)
begin
  -- If reset, set everything to 0
   if (RST = '1') then
      cnt <= (others => '0');
      cnt_bits <= (others => '0');
      DOUT <= (others => '0');
  -- Check only on the rising edge of Clock
   elsif rising_edge(CLK) then
      -- If counter is disabled, set it to  0. Else (counter is enabled, which means we start counting Clock ticks)
      -- check other embeded ifs ()
      if (cnt_en = '0') then
         cnt <= (others => '0');
      else
          -- We check if counter is = or > 16, so we can set it to 0 (we actually setting it to 1, because we have increment in the same
          -- if-else structure, so if we setting it to actual 0, we would miss counting 1 Clock tick each time we set it to 0)
         if (rx_en = '1' and cnt >= "10000") then
            cnt <= "00001";
          -- else if it under 24, we just increment it 
         elsif (cnt < "11000") then
            cnt <= cnt + 1;
         end if;
         -- if Reciever is disabled, then we set Counter of Bits to 0
         if (rx_en = '0') then
            cnt_bits <= (others => '0');
          -- Else if we counter if = or > 16 we pass data to output threw case
         elsif (cnt >= "10000") then
            case cnt_bits is
               when "0000" => DOUT(0) <= DIN;
               when "0001" => DOUT(1) <= DIN;
               when "0010" => DOUT(2) <= DIN;
               when "0011" => DOUT(3) <= DIN;
               when "0100" => DOUT(4) <= DIN;
               when "0101" => DOUT(5) <= DIN;
               when "0110" => DOUT(6) <= DIN;
               when "0111" => DOUT(7) <= DIN;
               when others => null;
            end case;
              -- Increment to next bit
              cnt_bits <= cnt_bits + 1;
         end if;
      end if;
   end if;
end process;


end architecture behavioral; 
