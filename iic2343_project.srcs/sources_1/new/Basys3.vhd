library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Basys3 is
    Port (
        sw          : in   std_logic_vector (15 downto 0); -- Señales de entrada de los interruptores -- Arriba   = '1'   -- Los 16 swiches.
        btn         : in   std_logic_vector (4 downto 0);  -- Señales de entrada de los botones       -- Apretado = '1'   -- 0 central, 1 arriba, 2 izquierda, 3 derecha y 4 abajo.
        led         : out  std_logic_vector (15 downto 0); -- Señales de salida  a  los leds          -- Prendido = '1'   -- Los 16 leds.
        clk         : in   std_logic;                      -- Señal de entrada del clock              -- 100Mhz.
        seg         : out  std_logic_vector (7 downto 0);  -- Salida de las señales de segmentos.
        an          : out  std_logic_vector (3 downto 0);  -- Salida del selector de diplay.
        tx          : out  std_logic;                      -- Señal de salida para UART Tx.
        rx          : in   std_logic                       -- Señal de entrada para UART Rx.
          );
end Basys3;

architecture Behavioral of Basys3 is

component Clock_Divider
    Port (
        clk         : in    std_logic;
        speed       : in    std_logic_vector (1 downto 0);
        clock       : out   std_logic
          );
    end component;

component Display_Controller
    Port (
        dis_a       : in    std_logic_vector (3 downto 0);
        dis_b       : in    std_logic_vector (3 downto 0);
        dis_c       : in    std_logic_vector (3 downto 0);
        dis_d       : in    std_logic_vector (3 downto 0);
        clk         : in    std_logic;
        seg         : out   std_logic_vector (7 downto 0);
        an          : out   std_logic_vector (3 downto 0)
          );
    end component;

component Debouncer
    Port (
        clk         : in    std_logic;
        signal_in      : in    std_logic;
        signal_out     : out   std_logic
          );
    end component;


component ROM
    Port (
        clk         : in    std_logic;
        write       : in    std_logic;
        disable     : in    std_logic;
        address     : in    std_logic_vector (11 downto 0);
        dataout     : out   std_logic_vector (35 downto 0);
        datain      : in    std_logic_vector(35 downto 0)
          );
    end component;

component RAM
    Port (
        clock       : in    std_logic;
        write       : in    std_logic;
        address     : in    std_logic_vector (11 downto 0);
        datain      : in    std_logic_vector (15 downto 0);
        dataout     : out   std_logic_vector (15 downto 0)
          );
    end component;

component Programmer
    Port (
        rx          : in    std_logic;
        tx          : out   std_logic;
        clk         : in    std_logic;
        clock       : in    std_logic;
        bussy       : out   std_logic;
        ready       : out   std_logic;
        address     : out   std_logic_vector(11 downto 0);
        dataout     : out   std_logic_vector(35 downto 0)
        );
    end component;

component CPU is
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


component Timer is
  Port (
    clk : in STD_LOGIC;
    clear   : in STD_LOGIC;
    seconds : out STD_LOGIC_VECTOR (15 downto 0);
    mseconds: out STD_LOGIC_VECTOR (15 downto 0);
    useconds: out STD_LOGIC_VECTOR (15 downto 0));
  end component;


signal clock            : std_logic;                     -- Señal del clock reducido.

signal dis_a            : std_logic_vector(3 downto 0);  -- Señales de salida al display A.
signal dis_b            : std_logic_vector(3 downto 0);  -- Señales de salida al display B.
signal dis_c            : std_logic_vector(3 downto 0);  -- Señales de salida al display C.
signal dis_d            : std_logic_vector(3 downto 0);  -- Señales de salida al display D.

signal d_btn            : std_logic_vector(4 downto 0);  -- Señales de botones con anti-rebote.

signal write_rom        : std_logic;                     -- Señal de escritura de la ROM.
signal pro_address      : std_logic_vector(11 downto 0); -- Señales del direccionamiento de programación de la ROM.
signal rom_datain       : std_logic_vector(35 downto 0); -- Señales de la palabra a programar en la ROM.

signal clear            : std_logic;                     -- Señal de limpieza de registros durante la programación.

signal cpu_rom_address  : std_logic_vector(11 downto 0); -- Señales del direccionamiento de lectura de la ROM.
signal rom_address      : std_logic_vector(11 downto 0); -- Señales del direccionamiento de la ROM.
signal rom_dataout      : std_logic_vector(35 downto 0); -- Señales de la palabra de salida de la ROM.

signal write_ram        : std_logic;                     -- Señal de escritura de la RAM.
signal ram_address      : std_logic_vector(11 downto 0); -- Señales del direccionamiento de la RAM.
signal ram_datain       : std_logic_vector(15 downto 0); -- Señales de la palabra de entrada de la RAM.
signal ram_dataout      : std_logic_vector(15 downto 0); -- Señales de la palabra de salida de la RAM.
signal mux_in_out       : std_logic_vector(15 downto 0);

signal seconds : std_logic_vector(15 downto 0);
signal mseconds : std_logic_vector(15 downto 0);
signal useconds : std_logic_vector(15 downto 0);

signal reg_led_out : std_logic_vector(15 downto 0);
signal reg_dis_out : std_logic_vector(15 downto 0);

signal write_reg_led : std_logic;
signal write_reg_dis : std_logic;

begin

dis_a <= reg_dis_out(15 downto 12);
dis_b <= reg_dis_out(11 downto 8);
dis_c <= reg_dis_out(7 downto 4);
dis_d <= reg_dis_out(3 downto 0);

led <= reg_led_out;

with clear select
    rom_address <= cpu_rom_address when '0',
                   pro_address when '1',
                  cpu_rom_address when others;

-- mux IN
with ram_address select -- OUT
  mux_in_out <= "0000000000000000" when "000000000000", -- led, IN
                sw when "000000000001",
                "0000000000000000" when "000000000010", -- display, IN
                "00000000000" & d_btn when "000000000011",
                seconds when "000000000100",
                mseconds when "000000000101",
                useconds when "000000000110",
                "0000000000000000" when "000000000111", -- lcd, IN
                ram_dataout when others;

-- demux OUT
with ram_address select
  write_reg_led <= write_ram when "000000000000",
                  '0' when others;
with ram_address select
  write_reg_dis <= write_ram when "000000000010",
                  '0' when others;

inst_CPU: CPU port map(
    clock       => clock,
    clear       => clear,
    ram_address => ram_address,
    ram_datain  => ram_datain,
    ram_dataout => mux_in_out,
    ram_write   => write_ram,
    rom_address => cpu_rom_address,
    rom_dataout => rom_dataout,
    dis         => open,
    led         => open
    );

inst_ROM: ROM port map(
    clk         => clk,
    disable     => clear,
    write       => write_rom,
    address     => rom_address,
    dataout     => rom_dataout,
    datain      => rom_datain
    );

inst_RAM: RAM port map(
    clock       => clock,
    write       => write_ram,
    address     => ram_address,
    datain      => ram_datain,
    dataout     => ram_dataout
    );

inst_Clock_Divider: Clock_Divider port map(
    speed       => "00",                    -- Selector de velocidad: "00" full, "01" fast, "10" normal y "11" slow.
    clk         => clk,                     -- Entrada de la señal del clock completo (100Mhz).
    clock       => clock                    -- Salida de la señal del clock reducido: 25Mhz, 8hz, 2hz y 0.5hz.
    );

inst_Display_Controller: Display_Controller port map(
    dis_a       => dis_a,                   -- Entrada de señales para el display A.
    dis_b       => dis_b,                   -- Entrada de señales para el display B.
    dis_c       => dis_c,                   -- Entrada de señales para el display C.
    dis_d       => dis_d,                   -- Entrada de señales para el display D.
    clk         => clk,                     -- Entrada del clock completo (100Mhz).
    seg         => seg,                     -- Salida de las señales de segmentos.
    an          => an                       -- Salida del selector de diplay.
	);

inst_Debouncer0: Debouncer port map( clk => clk, signal_in => btn(0), signal_out => d_btn(0) );
inst_Debouncer1: Debouncer port map( clk => clk, signal_in => btn(1), signal_out => d_btn(1) );
inst_Debouncer2: Debouncer port map( clk => clk, signal_in => btn(2), signal_out => d_btn(2) );
inst_Debouncer3: Debouncer port map( clk => clk, signal_in => btn(3), signal_out => d_btn(3) );
inst_Debouncer4: Debouncer port map( clk => clk, signal_in => btn(4), signal_out => d_btn(4) );

inst_Programmer: Programmer port map(
    rx          => rx,                       --  Salida de la señal de transmición.
    tx          => tx,                       --  Entrada de la señal de recepción.
    clk         => clk,                      --  Entrada del clock completo (100Mhz).
    clock       => clock,                    --  Entrada del clock reducido.
    bussy       => clear,                    --  Salida de la señal de programación.
    ready       => write_rom,                --  Salida de la señal de escritura de la ROM.
    address     => pro_address(11 downto 0), --  Salida de señales del address de la ROM.
    dataout     => rom_datain                --  Salida de señales palabra de entrada de la ROM.
        );

inst_Timer: Timer port map(
  clk => clk,
  clear => clear,
  seconds => seconds,
  mseconds => mseconds,
  useconds => useconds
);

inst_REG_DIS : REG port map(
    clock => clock,
    clear => clear,
    load => write_reg_dis,
    up => '0',
    down => '0',
    datain => ram_datain,
    dataout => reg_dis_out
  );

inst_REG_LED : REG port map(
    clock => clock,
    clear => clear,
    load => write_reg_led,
    up => '0',
    down => '0',
    datain => ram_datain,
    dataout => reg_led_out
  );

end Behavioral;
