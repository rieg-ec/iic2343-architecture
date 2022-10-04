library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;

entity RegStatus is
    Port ( clock    : in  std_logic;
           clear    : in  std_logic;
           load     : in  std_logic;
           c     : in  std_logic;
           z     : in  std_logic;
           n     : in  std_logic;
           dataout  : out std_logic_vector (2 downto 0));
end RegStatus;

architecture Behavioral of RegStatus is

signal reg : std_logic_vector(2 downto 0) := (others => '0');

begin

reg_prosses : process (clock, clear)
        begin
          if (clear = '1') then
            reg <= (others => '0');
          elsif (rising_edge(clock)) then
            if (load = '1') then
                reg <= c & z & n;
            end if;
          end if;
        end process;

dataout <= reg;

end Behavioral;
