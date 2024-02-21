-- Import standard libraries
library ieee;
use ieee.std_logic_1164.all; -- Standard logic types
use ieee.numeric_std.all; -- Numeric types for logic vectors

-- Declaration of the fcs_check_serial entity with its I/O ports
entity fcs_check_serial is
  port (
    clk            : in  std_logic; -- Input clock
    reset          : in  std_logic; -- Reset input, active high
    start_of_frame : in  std_logic; -- Indicates the start of an ethernet frame
    end_of_frame   : in  std_logic; -- Indicates the end of an ethernet frame
    data_in        : in  std_logic; -- Serial data input
    fcs_error      : out std_logic  -- Output flag for FCS error detection
  );
end fcs_check_serial;

-- Behavioral architecture of the fcs_check_serial entity
architecture behavioral of fcs_check_serial is
  -- Internal signal declarations
  signal reg           : std_logic_vector(31 downto 0); -- CRC register

  signal fcs_finished    : std_logic; -- Flag to indicate FCS checking is complete
  signal data        : std_logic; -- Processed data bit
  signal counter_32 : unsigned(4 downto 0); -- Count for tracking bit shifts

begin

  -- Process handling data inversion based on frame signals and shift count
  process (counter_32, start_of_frame, end_of_frame, data_in)
  begin
    data <= data_in; -- Default assignment

    -- Invert data when not in the middle of frame processing or at frame boundaries
    if counter_32 < 31 or start_of_frame = '1' or end_of_frame = '1' then
      data <= not data_in;
    end if;
  end process;

  -- Main CRC checking process, triggered by clock and reset
  process (clk, reset)
  begin
    -- Synchronous reset
    if reset = '1' then
      reg           <= (others => '0'); -- Clear CRC register
      counter_32 <= (others => '0'); -- Reset shift count
      fcs_error   <= '1'; -- Indicate error by default until proven otherwise
    elsif rising_edge(clk) then -- Edge-triggered behavior
      -- Mark FCS check as done at end of frame
      if end_of_frame = '1' then
        fcs_finished <= '1';
      end if;

      -- Reset shift count at the start or end of a frame
      if start_of_frame = '1' or end_of_frame = '1' then
        counter_32 <= (others => '0');
      elsif counter_32 < 31 then -- Increment shift count until 32 bits have been shifted
        counter_32 <= counter_32 + 1;
      end if;

      -- CRC calculation logic using a specified generator polynomial
      reg(0) <= data xor reg(31); -- Initial polynomial computation step
      for i in 1 to 31 loop
            case i is
                -- Specific polynomial terms affecting CRC bits
                when 1 | 2 | 4 | 5 | 7 | 8 | 10 | 11 | 12 | 16 | 22 | 23 | 26 =>
                    reg(i) <= reg(i-1) xor reg(31);
                when others =>
                    reg(i) <= reg(i-1); -- Carry forward for non-affecting terms
            end case;
        end loop;

        -- Determine FCS error status at the end of frame processing
        if reg = "00000000000000000000000000000000" and fcs_finished = '1' then
            fcs_error <= '0'; -- No error if CRC matches expected zero output
        end if;
    end if;
  end process;

end behavioral;
