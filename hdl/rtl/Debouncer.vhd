library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity Debouncer is
    generic (
        cDebounceClocks : natural range 2 to (natural'high);
        cPortWidth      : natural
    );
    port (
        Clock  : in std_logic;
        SigIn  : in std_logic_vector(cPortWidth - 1 downto 0);
        SigOut : out std_logic_vector(cPortWidth - 1 downto 0)
    );
end entity Debouncer;

architecture rtl of Debouncer is
    type vector_t is array (natural range <>) of natural range 0 to cDebounceClocks - 1;
    signal counters : vector_t(0 to cPortWidth - 1) := (others => (others => 0));
    signal sigOutReg : std_logic_vector(cPortWidth - 1 downto 0) := (others => '0');
begin
    
    Debounce: process(Clock)
    begin
        if rising_edge(Clock) then
            for ii in 0 to cPortWidth - 1 loop
                if (counters(ii) = cDebounceClocks - 1) then
                    sigOutReg(ii) <= not(sigOutReg(ii));
                end if;
            end loop;
        end if;
    end process Debounce;

    CounterControl: process(Clock)
    begin
        if rising_edge(Clock) then
            for ii in 0 to cPortWidth - 1 loop
                if ((signalOutReg(ii) = '1') xor (SigIn(ii) = '1')) then
                    if (counters(ii) = cDebounceClocks - 1) then
                        counters(ii) <= 0;
                    else
                        counters(ii) <= counters(ii) + 1;
                    end if;
                else
                    counters(ii) <= 0;
                end if;
            end loop;
        end if;
    end process CounterControl;

    SigOut <= signalOutReg;
    
end architecture rtl;