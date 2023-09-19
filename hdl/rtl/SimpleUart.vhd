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
    signal txDataValid : std_logic;
    signal txReady     : std_logic;

    type state_t is (IDLE, WAIT_FOR_DONE);
    signal state : state_t;
begin
    
    -- SimpleUart TX
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

    RxDataBuff: process(Clock)
    begin
        if rising_edge(Clock) then
            if Resetn = '0' then
                state       <= IDLE;
                txDataIn    <= (others => '0');
                txDataValid <= '0';
            elsif rxDone = '1' and state = IDLE then
                txDataIn  <= rxDataOut;
                if txReady = '0' then
                    state       <= WAIT_FOR_DONE;
                    txDataValid <= '0';
                else
                    txDataValid <= '1';
                end if;
            elsif state = WAIT_FOR_DONE and txReady = '1' then
                txDataValid <= '1';
                state       <= IDLE;
            end if;
        end if;
    end process RxDataBuff;

    -- Uart RX
    SimpleTx : entity work.SimpleUartTx
    generic map (
        cClockFrequency => 100e6,
        cUartBaudRate   => 9600
    )
    port map (
        Clock  => Clock,
        TxData => txDataIn,
        Send   => txDataValid,
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

    -- -- TX FIFO
    -- TxFifo : entity work.SimpleFifo
    -- generic map (
    --     cAddressWidth => cAddressWidth
    -- )
    -- port map (
    --     Clock         => Clock,
    --     Resetn        => Resetn,
    --     SoftReset     => '0',
    --     IsAlmostEmpty => open,
    --     IsAlmostFull  => open,
    --     IsEmpty       => txIsEmpty,
    --     IsFull        => open,
    --     Pop           => txPop,
    --     WriteEnable   => rxDone,
    --     DataIn        => rxDataOut,
    --     DataOut       => txDataIn
    -- );

    -- ClockedEnabling: process(Clock)
    -- begin
    --     if rising_edge(Clock) then
    --         txEnable <= txPop;        
    --         txPop    <= (txDone or (not txDone and not txActive)) and not txIsEmpty;
    --     end if;
    -- end process ClockedEnabling;
    
    
end architecture rtl;