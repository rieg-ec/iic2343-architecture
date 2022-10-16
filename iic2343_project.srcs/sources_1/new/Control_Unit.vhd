library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ControlUnit is
    Port (opcode : in std_logic_vector (19 downto 0);
          status : in std_logic_vector (2 downto 0);
          selA : out std_logic_vector (1 downto 0);
          selB : out std_logic_vector (1 downto 0);
          enableA : out std_logic;
          enableB : out std_logic;
          selALU : out std_logic_vector (2 downto 0);
          w : out std_logic;
          loadPC : out std_logic;
          selAdd : out std_logic_vector (1 downto 0);
          incSP : out std_logic;
          decSP : out std_logic;
          selPC : out std_logic;
          selDin : out std_logic);
end ControlUnit;

architecture Behavioral of ControlUnit is

signal jmp : std_logic_vector(2 downto 0);
signal loadPC_helper : std_logic;

signal c : std_logic;
signal z : std_logic;
signal n : std_logic;

signal jeq : std_logic;
signal jne : std_logic;
signal jgt : std_logic;
signal jge : std_logic;
signal jlt : std_logic;
signal jle : std_logic;
signal jcr : std_logic;

begin

selA <= opcode(19 downto 18);
selB <= opcode(17 downto 16);
enableA <= opcode(15);
enableB <= opcode(14);
selALU <= opcode(13 downto 11);
w <= opcode(10);
loadPC_helper <= opcode(9);
jmp <= opcode(8 downto 6);
selAdd <= opcode(5 downto 4);
incSP <= opcode(3);
decSP <= opcode(2);
selPC <= opcode(1);
selDin <= opcode(0);

c <= status(2);
z <= status(1);
n <= status(0);

jeq <= z;
jne <= not z;
jgt <= (not z) and (not n);
jge <= not n;
jlt <= n;
jle <= z or n;
jcr <= c;

with jmp select loadPC <=
    jeq when "001",
    jne when "010",
    jgt when "011",
    jge when "100",
    jlt when "101",
    jle when "110",
    jcr when "111",
    loadPC_helper when others;

end Behavioral;
