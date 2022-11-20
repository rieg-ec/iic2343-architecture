library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;

entity Reg is
    generic(
      datain_width : integer := 16;
      dataout_width : integer := 16;
      clear_bit : std_logic := '0'
    );
    Port (
      clock    : in  std_logic;
      clear    : in  std_logic;
      load     : in  std_logic;
      up       : in  std_logic;
      down     : in  std_logic;
      datain   : in  std_logic_vector (datain_width-1 downto 0);
      dataout  : out std_logic_vector (dataout_width-1 downto 0)
    );
end Reg;

architecture Behavioral of Reg is

signal reg : std_logic_vector(datain_width-1 downto 0) := (others => clear_bit);

begin

reg_prosses : process (clock, clear)
        begin
          if (clear = '1') then
            reg <= (others => clear_bit);
          elsif (rising_edge(clock)) then
            if (load = '1') then
                reg <= datain;
            elsif (up = '1') then
                reg <= reg + 1;
            elsif (down = '1') then
                reg <= reg - 1;
            end if;
          end if;
        end process;

dataout <= reg;

end Behavioral;
