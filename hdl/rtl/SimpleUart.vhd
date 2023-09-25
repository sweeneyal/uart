library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library work;

entity SimpleUart is
    generic (
        cAddressWidth : natural := 10;
        cNumLeds      : natural := 4
    );
    port (
        Clock  : in std_logic;
        Resetn : in std_logic;
        Rx     : in std_logic;
        Tx     : out std_logic;
        Leds   : out std_logic_vector(cNumLeds - 1 downto 0)
    );
end entity SimpleUart;

architecture rtl of SimpleUart is
    signal rxDataOut   : std_logic_vector(7 downto 0);
    signal rxDone      : std_logic;
    signal txDataIn    : std_logic_vector(7 downto 0);
    signal txReady     : std_logic;
    signal txIsEmpty   : std_logic;
    signal txPop       : std_logic;
    signal txPopd      : std_logic;

    type state_t is (IDLE, WAIT_FOR_DONE);
    signal state : state_t;
begin
    
    -- SimpleUart RX
    SimpleRx : entity work.SimpleUartRx 
    generic map (
        cClockFrequency => 100e6,
        cUartBaudRate   => 9600
    )
    port map (
        Clock  => Clock,
        Rx     => Rx,
        Done   => rxDone,
        RxData => rxDataOut
    );

    -- Uart TX
    SimpleTx : entity work.SimpleUartTx
    generic map (
        cClockFrequency => 100e6,
        cUartBaudRate   => 9600
    )
    port map (
        Clock  => Clock,
        TxData => txDataIn,
        Send   => txPopd,
        Tx     => Tx,
        Ready  => txReady
    );

    BounceLeds : entity work.BouncingLeds
    generic map (
        cNumLeds               => cNumLeds,
        cLedRate_LedsPerSecond => 2,
        cClockRate_Hz          => 100e6
    )
    port map (
        Clock   => Clock,
        Resetn  => Resetn,
        Leds    => Leds
    );

    txPop <= Bool2Bit(txReady = '1' and txIsEmpty = '0');

    ValidSetting: process(Clock)
    begin
        if rising_edge(Clock) then
            txPopd <= txPop;
        end if;
    end process ValidSetting;

    -- TX FIFO
    TxFifo : entity work.SimpleFifo
    generic map (
        cAddressWidth => cAddressWidth
    )
    port map (
        Clock         => Clock,
        Resetn        => Resetn,
        SoftReset     => '0',
        IsAlmostEmpty => open,
        IsAlmostFull  => open,
        IsEmpty       => txIsEmpty,
        IsFull        => open,
        Pop           => txPop,
        WriteEnable   => rxDone,
        DataIn        => rxDataOut,
        DataOut       => txDataIn
    );

    -- ClockedEnabling: process(Clock)
    -- begin
    --     if rising_edge(Clock) then
    --         txEnable <= txPop;        
    --         txPop    <= (txDone or (not txDone and not txActive)) and not txIsEmpty;
    --     end if;
    -- end process ClockedEnabling;
    
    
end architecture rtl;