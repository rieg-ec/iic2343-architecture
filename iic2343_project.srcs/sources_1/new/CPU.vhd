library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;


entity CPU is
    Port (clock : in STD_LOGIC;
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
  Port (a        : in  std_logic_vector (15 downto 0);
        b        : in  std_logic_vector (15 downto 0);
        sop      : in  std_logic_vector (2 downto 0);
        c        : out std_logic;
        z        : out std_logic;
        n        : out std_logic;
        result   : out std_logic_vector (15 downto 0));
end component;

component Reg
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
end component;

component RegStatus
    Port (clock    : in  std_logic;
          clear    : in  std_logic;
          load     : in  std_logic;
          c     : in  std_logic;
          z     : in  std_logic;
          n     : in  std_logic;
          dataout  : out std_logic_vector (2 downto 0));
end component;

component ControlUnit
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
end component;

component Adder12 is
    Port (
      a  : in  std_logic_vector (11 downto 0);
      b  : in  std_logic_vector (11 downto 0);
      ci : in  std_logic;
      s  : out std_logic_vector (11 downto 0);
      co : out std_logic
    );
end component;

signal signal_ALU_result : std_logic_vector(15 downto 0);
signal signal_mux_a_out : std_logic_vector(15 downto 0);
signal signal_mux_b_out : std_logic_vector(15 downto 0);
signal signal_reg_a_out : std_logic_vector(15 downto 0);
signal signal_reg_b_out : std_logic_vector(15 downto 0);

signal signal_selA : std_logic_vector(1 downto 0);
signal signal_selB : std_logic_vector(1 downto 0);
signal signal_enableA : std_logic;
signal signal_enableB : std_logic;
signal signal_selALU : std_logic_vector(2 downto 0);
signal signal_w : std_logic;
signal signal_loadPC : std_logic;
signal signal_jmp : std_logic_vector(3 downto 0);
signal signal_selAdd : std_logic_vector(1 downto 0);
signal signal_incSP : std_logic;
signal signal_decSP : std_logic;
signal signal_selPC : std_logic;
signal signal_selDin : std_logic;
signal signal_c : std_logic;
signal signal_z : std_logic;
signal signal_n : std_logic;
signal signal_reg_status_out : std_logic_vector(2 downto 0);

signal signal_reg_pc_out : std_logic_vector(11 downto 0);
signal signal_reg_pc_in : std_logic_vector(11 downto 0);
signal signal_reg_sp_out : std_logic_vector(11 downto 0);

signal signal_PC_adder_out : std_logic_vector(15 downto 0);

signal signal_rom_dataout_12_bit_lit : std_logic_vector(11 downto 0);
signal signal_rom_dataout_16_bit_lit : std_logic_vector(15 downto 0);

signal signal_ram_dataout_12_bit : std_logic_vector(11 downto 0);

signal signal_opcode : std_logic_vector(19 downto 0);

begin

rom_address <= signal_reg_pc_out;

dis <= signal_reg_a_out(7 downto 0) & signal_reg_b_out(7 downto 0);
led <= signal_c & signal_z & signal_n & signal_loadPC & signal_reg_pc_out;

signal_rom_dataout_12_bit_lit <= rom_dataout(31 downto 20);
signal_rom_dataout_16_bit_lit <= rom_dataout(35 downto 20);

signal_ram_dataout_12_bit <= ram_dataout(11 downto 0);

ram_write <= signal_w;

signal_opcode <= rom_dataout(19 downto 0);

inst_REG_A: Reg port map(
  clock       => clock,
  clear       => clear,
  load        => signal_enableA,
  up          => '0',
  down        => '0',
  datain      => signal_ALU_result,
  dataout     => signal_reg_a_out
);

inst_REG_B: Reg port map(
  clock       => clock,
  clear       => clear,
  load        => signal_enableB,
  up          => '0',
  down        => '0',
  datain      => signal_ALU_result,
  dataout     => signal_reg_b_out
);

-- MUX_A
with signal_selA select signal_mux_a_out <= -- 16 bit
  "0000000000000000" when "00",
  "0000000000000001" when "01",
  signal_reg_a_out          when "10",
  "0000000000000000" when others;

-- MUX_B
with signal_selB select signal_mux_b_out <= -- 16 bit
  signal_rom_dataout_16_bit_lit when "01",
  signal_reg_b_out when "10",
  ram_dataout when "11",
  "0000000000000000" when others;

-- MUX S
with signal_selAdd select ram_address <= -- 12 bit
  signal_rom_dataout_12_bit_lit when "00",
  signal_reg_b_out(11 downto 0) when "01", -- @TODO does this way of slicing works?
  signal_reg_sp_out when "10",
  "000000000000" when others;

-- MUX PC
with signal_selPC select signal_reg_pc_in <= -- 12 bit
  signal_ram_dataout_12_bit when '1',
  signal_rom_dataout_12_bit_lit when others;

-- Mux Datain
with signal_selDin select ram_datain <= -- 16 bit
  signal_PC_adder_out when '1',
  signal_ALU_result when others;

inst_ALU: ALU port map(
  a           => signal_mux_a_out,
  b           => signal_mux_b_out,
  sop         => signal_selALU,
  c           => signal_c,
  z           => signal_z,
  n           => signal_n,
  result      => signal_ALU_result
);

inst_REG_PC: Reg
  generic map(
    datain_width => 12,
    dataout_width => 12
  )
  port map(
    clock => clock,
    clear => clear,
    load => signal_loadPC,
    up => not signal_loadPC,
    down => '0',
    datain => signal_reg_pc_in,
    dataout => signal_reg_pc_out
  );

inst_REG_SP: Reg
  generic map(
    datain_width => 12,
    dataout_width => 12,
    clear_bit => '1'
  )
  port map(
    clock => clock,
    clear => clear,
    load => '0',
    up => signal_incSP,
    down => signal_decSP,
    datain => "000000000000",
    dataout => signal_reg_sp_out
  );

inst_REG_STATUS: RegStatus port map(
  clock       => clock,
  clear       => clear,
  load        => '1',
  c           => signal_c,
  z           => signal_z,
  n           => signal_n,
  dataout     => signal_reg_status_out
);

inst_CONTROL_UNIT: ControlUnit port map(
  opcode => signal_opcode,
  status => signal_reg_status_out,
  selA => signal_selA,
  selB => signal_selB,
  enableA => signal_enableA,
  enableB => signal_enableB,
  selALU => signal_selALU,
  w => signal_w,
  loadPC => signal_loadPC,
  selAdd => signal_selAdd,
  incSP => signal_incSP,
  decSP => signal_decSP,
  selPC => signal_selPC,
  selDin => signal_selDin
);

inst_PC_ADDER: Adder12 port map(
    a => signal_reg_pc_out,
    b => "000000000001",
    ci => '0',
    s => signal_PC_adder_out(11 downto 0),
    co => open
  );

end Behavioral;
