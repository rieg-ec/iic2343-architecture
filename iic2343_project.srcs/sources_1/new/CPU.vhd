library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;


entity CPU is
    Port (
           clock : in STD_LOGIC;
           clear : in STD_LOGIC;
           ram_address : out STD_LOGIC_VECTOR (11 downto 0);
           ram_datain : out STD_LOGIC_VECTOR (15 downto 0);
           ram_dataout : in STD_LOGIC_VECTOR (15 downto 0);
           ram_write : out STD_LOGIC;
           rom_address : out STD_LOGIC_VECTOR (11 downto 0);
           rom_dataout : in STD_LOGIC_VECTOR (35 downto 0);
           dis : out STD_LOGIC_VECTOR (15 downto 0);
           led : out STD_LOGIC_VECTOR (15 downto 0));
end CPU;

architecture Behavioral of CPU is

component ALU
  Port ( a        : in  std_logic_vector (15 downto 0);
         b        : in  std_logic_vector (15 downto 0);
         sop      : in  std_logic_vector (2 downto 0);
         c        : out std_logic;
         z        : out std_logic;
         n        : out std_logic;
         result   : out std_logic_vector (15 downto 0));
end component;

component Reg
    Port ( clock    : in  std_logic;
           clear    : in  std_logic;
           load     : in  std_logic;
           up       : in  std_logic;
           down     : in  std_logic;
           datain   : in  std_logic_vector (15 downto 0);
           dataout  : out std_logic_vector (15 downto 0));
end component;

component RegStatus
    Port ( clock    : in  std_logic;
           clear    : in  std_logic;
           load     : in  std_logic;
           c     : in  std_logic;
           z     : in  std_logic;
           n     : in  std_logic;
           dataout  : out std_logic_vector (2 downto 0));
end component;


signal ALU_result : std_logic_vector(15 downto 0);
signal mux_a_out : std_logic_vector(15 downto 0);
signal mux_b_out : std_logic_vector(15 downto 0);
signal reg_a_out : std_logic_vector(15 downto 0);
signal reg_b_out : std_logic_vector(15 downto 0);

signal selA : std_logic_vector(1 downto 0);
signal selB : std_logic_vector(1 downto 0);
signal selALU : std_logic_vector(2 downto 0);
signal enableA : std_logic;
signal enableB : std_logic;
signal loadPC : std_logic;
signal w : std_logic;
signal jmp : std_logic_vector(3 downto 0);
signal c : std_logic;
signal z : std_logic;
signal n : std_logic;
signal reg_status_out : std_logic_vector(2 downto 0);

signal lit : std_logic_vector(15 downto 0);

signal not_loadPC : std_logic;

signal reg_pc_out : std_logic_vector(15 downto 0);

begin

dis <= reg_a_out(7 downto 0) & reg_b_out(7 downto 0);
led <= reg_pc_out;

selA <= rom_dataout(19 downto 18);
selB <= rom_dataout(17 downto 16);
enableA <= rom_dataout(15);
enableB <= rom_dataout(14);
selALU <= rom_dataout(13 downto 11);
w <= rom_dataout(10);
jmp <= rom_dataout(9 downto 6);

not_loadPC <= not loadPC;

rom_address <= reg_pc_out(11 downto 0);

lit <= rom_dataout(35 downto 20);

ram_address <= lit(11 downto 0);
ram_datain <= ALU_result;
ram_write <= w;

-- load_reg_status <= jmp(9); @TODO no se si es necesario

with jmp select loadPC <=
    '1' when "1000", -- jmp
    reg_status_out(1) when "1001", -- jeq
    -- @TODO la logica del resto de los jmp esta mal
    not reg_status_out(1) when "1010", -- jne
    not reg_status_out(2) when "1011", -- jgt
    reg_status_out(2) when "1100", -- jge
    reg_status_out(1) or reg_status_out(2) when "1101", -- jlt
    reg_status_out(0) when "1110", -- jle
    reg_status_out(0) when "1111", -- jcr
    '0' when others;

inst_REG_A: Reg port map(
  clock       => clock,
  clear       => clear,
  load        => enableA,
  up          => '0',
  down        => '0',
  datain      => ALU_result,
  dataout     => reg_a_out
);

inst_REG_B: Reg port map(
  clock       => clock,
  clear       => clear,
  load        => enableB,
  up          => '0',
  down        => '0',
  datain      => ALU_result,
  dataout     => reg_b_out
);

-- MUX_A
with selA select mux_a_out <=
  "0000000000000000" when "00",
  "0000000000000001" when "01",
  reg_a_out          when "10",
  "0000000000000000" when others;

-- MUX_B
with selB select mux_b_out <=
  "0000000000000000"        when "00",
  -- literal goes into 16 most significant bits
  lit when "01",
  reg_b_out                 when "10",
  ram_dataout               when "11";

inst_ALU: ALU port map(
  a           => mux_a_out,
  b           => mux_b_out,
  sop         => selALU,
  c           => c,
  z           => z,
  n           => n,
  result      => ALU_result
);

inst_REG_PC: Reg port map(
  clock       => clock,
  clear       => clear,
  load        => loadPC,
  up          => not_loadPC,
  down        => '0',
  datain      => lit,
  dataout     => reg_pc_out
);

inst_REG_STATUS: RegStatus port map(
  clock       => clock,
  clear       => clear, -- @TODO deberia siempre limpiarse cuando la ALU hace un nuevo calculo? o solo con un CMP?
  load        => '1', -- @TODO deberia ser siempre 1?
  c           => c,
  z           => z,
  n           => n,
  dataout     => reg_status_out
);

end Behavioral;

