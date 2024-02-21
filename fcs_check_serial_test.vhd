library ieee;
use ieee.std_logic_1164.all;

entity fcs_check_serial_test is
end fcs_check_serial_test;

architecture behavior of fcs_check_serial_test is

  component fcs_check_serial
    port(clk            : in  std_logic;
         reset          : in  std_logic;
         start_of_frame : in  std_logic;
         end_of_frame   : in  std_logic;
         data_in        : in  std_logic;
         fcs_error      : out std_logic);
  end component;

  -- Inputs
  signal clk            : std_logic := '0';
  signal reset          : std_logic := '0';
  signal start_of_frame : std_logic := '0';
  signal end_of_frame   : std_logic := '0';
  signal data_in        : std_logic := '0';

  -- Outputs
  signal fcs_error : std_logic;

  -- Clock period definitions
  constant clk_period : time := 10 ns;

  -- Data to feed the FCS check entity.
  constant packet : std_logic_vector(511 downto 0) :=
    x"00_10_A4_7B_EA_80_00_12_34_56_78_90_08_00_45_00_00_2E_B3_FE_00_00_80_11" &
    x"05_40_C0_A8_00_2C_C0_A8_00_04_04_00_04_00_00_1A_2D_E8_00_01_02_03_04_05" &
    x"06_07_08_09_0A_0B_0C_0D_0E_0F_10_11_E6_C5_3D_B2";

begin

  i_fcs_check_1 : fcs_check_serial port map (
    clk            => clk,
    reset          => reset,
    start_of_frame => start_of_frame,
    end_of_frame   => end_of_frame,
    data_in        => data_in,
    fcs_error      => fcs_error
    );

  -- Test clock.
  proc_clk : process
  begin
    clk <= '0';
    wait for clk_period / 2;
    clk <= '1';
    wait for clk_period / 2;
  end process;

  -- Stimulus process.
  proc_reset : process
  begin
    -- Reset the state.
    reset <= '1';
    wait for clk_period;
    reset <= '0';

    -- Start sending data, and indicate we are no longer at the start of the
    -- frame.
    for i in packet'range loop
      if i = (packet'length - 1) then
        start_of_frame <= '1';
      else
        start_of_frame <= '0';
      end if;

      data_in <= packet(i);

      -- Start of last frame (32 bits).
      if i = 31 then
        end_of_frame <= '1';
      else
        end_of_frame <= '0';
      end if;

      wait for clk_period;
    end loop;

    data_in <= '0';

    wait;
  end process;

end;