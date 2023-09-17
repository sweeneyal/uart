library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity BouncingLeds is
    generic (
        cNumLeds               : natural := 4;
        cLedRate_LedsPerSecond : natural := 2;
        cClockRate_Hz          : natural := 100e6
    );
    port (
        Clock  : in std_logic;
        Resetn : in std_logic;
        Leds   : out std_logic_vector(cNumLeds-1 downto 0)
    );
end entity BouncingLeds;

architecture rtl of BouncingLeds is
    constant cNumClockCycles : natural := cClockRate_Hz / cLedRate_LedsPerSecond;
    signal counter           : natural range 0 to cNumClockCycles  := 0;
    signal ledIndex          : natural range 0 to cNumLeds - 1     := 0;
    signal ledStates         : std_logic_vector(cNumLeds - 1 downto 0);
begin
    
    CounterControl: process(Clock)
    begin
        if Resetn = '0' then
            counter <= 0;
            ledIndex <= 0;
        elsif rising_edge(Clock) then
            if counter = cNumClockCycles then
                counter <= 0;

                if ledIndex = cNumLeds - 1 then
                    ledIndex <= 0;
                else
                    ledIndex <= ledIndex + 1;
                end if;
            else
                counter <= counter + 1;
            end if;
        end if;
    end process CounterControl;

    SetLeds: process(ledIndex)
    begin
        for ii in 0 to cNumLeds - 1 loop
            if ii = ledIndex then
                Leds(ii) <= '1';
            else
                Leds(ii) <= '0';
            end if;
        end loop;
    end process SetLeds;
    
end architecture rtl;