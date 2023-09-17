library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity SimpleUartRx is
    generic (
        cClockFrequency : natural := 100000000;
        cUartBaudRate   : natural := 115200
    );
    port (
        Clock  : in  std_logic;
        Resetn : in  std_logic;
        Rx     : in  std_logic;
        Done   : out std_logic;
        RxData : out std_logic_vector(7 downto 0)
    );
end entity SimpleUartRx;

architecture rtl of SimpleUartRx is
    attribute DONT_TOUCH : boolean;
    attribute DONT_TOUCH of rtl : architecture is true;
    
    constant cClocksPerBit : natural := 100000000 / 115200;
    signal rxSample0       : std_logic := '1';
    signal rxSample1       : std_logic := '1';
    signal rxSample2       : std_logic := '1';
    signal clockCounter    : natural range 0 to cClocksPerBit - 1 := 0;
    signal bitCounter      : natural range 0 to 9 := 0;
    signal data            : std_logic_vector(7 downto 0);
begin
    
    SampleRx: process(Clock)
    begin
        if rising_edge(Clock) then
            rxSample2 <= rxSample1;
            rxSample1 <= rxSample0;
            rxSample0 <= Rx;
        end if;
    end process SampleRx;

    UartRxStateMachine: process(Clock)
    begin
        if rising_edge(Clock) then
            if clockCounter = 1 and bitCounter > 0 then
                data <= rx & data(7 downto 1);
            end if;

            if clockCounter = 1 and bitCounter = 0 then
                Done <= rx;
            else
                Done <= '0';
            end if;

            if Resetn = '0' then
                bitCounter <= 0;
                clockCounter <= 0;
            elsif clockCounter > 0 then
                clockCounter <= clockCounter - 1; 
            elsif bitCounter > 0 then
                bitCounter <= bitCounter - 1;
            elsif rxSample1 = '0' and rxSample2 = '1' then
                bitCounter   <= 9;
                clockCounter <= cClocksPerBit - 1;
            end if;
        end if;
    end process UartRxStateMachine;

    RxData <= data;
    
end architecture rtl;