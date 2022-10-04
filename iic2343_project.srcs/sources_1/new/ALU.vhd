library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ALU is
    Port ( a        : in  std_logic_vector (15 downto 0);
           b        : in  std_logic_vector (15 downto 0);
           sop      : in  std_logic_vector (2 downto 0);
           c        : out std_logic;
           z        : out std_logic;
           n        : out std_logic;
           result   : out std_logic_vector (15 downto 0));
end ALU;

architecture Behavioral of ALU is

component Adder
    Port(
        a : in std_logic_vector(15 downto 0);
        b : in std_logic_vector(15 downto 0);
        ci : in std_logic;
        s : out std_logic_vector(15 downto 0);
        co : out std_logic);
end component;

signal ci: std_logic;
signal co: std_logic;
signal alu_result   : std_logic_vector(15 downto 0);
signal b_adder   : std_logic_vector(15 downto 0);
signal result_adder   : std_logic_vector(15 downto 0);

begin

-- substraction works by adding two's complement of the substraend,
-- which is calculated by negating the substraend and then set carry bit to 1

with sop select ci <=
    '1' when "001", -- set cin to 1 to add 1 to the negated substraend
    '0' when others;

with sop select b_adder <=
    not b when "001", -- negate substraend
    b when others;

inst_Adder: Adder port map(
        a => a,
        b => b_adder,
        ci => ci,
        s => result_adder,
        co => co
);

with sop select alu_result <=
    result_adder     when "000",
    result_adder     when "001",
    a and b     when "010",
    a or b     when "011",
    a xor b     when "100",
    not a     when "101",
    '0' & a(15 downto 1) when "110", -- shift right
    a(14 downto 0) & '0' when "111"; -- shift left

result  <= alu_result;

-- carry flag
with sop select c <=
    co when "000",
    co when "001",
    '0' when "010",
    '0' when "011",
    '0' when "100",
    '0' when "101",
    a(0) when "110",
    a(15) when "111";

-- negative flag
with sop select n <=
    not co when "001",
    '0' when others;

-- zero flag
with alu_result select z <=
    '1' when "0000000000000000",
    '0' when others;

end Behavioral;
