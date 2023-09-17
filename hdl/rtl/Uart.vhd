library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library work;

entity Uart is
    generic (
        cAddressWidth : natural := 5
    );
    port (
        Clock  : in std_logic;
        Resetn : in std_logic;
        Rx     : in std_logic;
        Tx     : out std_logic
    );
end entity Uart;

architecture rtl of Uart is
    signal txDataOut         : std_logic_vector(7 downto 0);
    signal txDataIn          : std_logic_vector(7 downto 0);
    signal txIsFull          : std_logic;
    signal txIsNotFull       : std_logic;
    signal txIsEmpty         : std_logic;
    signal rxIsEmpty         : std_logic;
    signal rxIsNotEmpty      : std_logic;
    signal txEnable          : std_logic;
    signal rxWriteEnable     : std_logic;
    signal txWriteEnable     : std_logic;
    signal rxPop             : std_logic;
    signal txPop             : std_logic;
    signal rxDataIn          : std_logic_vector(7 downto 0);
    signal rxDataOut         : std_logic_vector(7 downto 0);
    signal startSending      : std_logic;
    signal uartTxDone        : std_logic;
    signal numBytesOut       : natural range 0 to 2**cAddressWidth;
    signal numBytesRemaining : natural range 0 to 2**cAddressWidth;

    type state_t is (IDLE, GET_NEXT, WAIT_FOR_DONE);
    signal state : state_t;
begin
    
    -- Uart TX
    UartTx : entity work.SimpleUartTx 
    generic map (
        cClockFrequency => 100e6,
        cUartBaudRate   => 115200,
        cNumBits        => 8,
        cClocksPerBit   => 100e6 / 115200
    )
    port map (
        Clock  => Clock,
        TxData => txDataOut,
        Enable => txEnable,
        Tx     => Tx,
        Done   => uartTxDone,
        Active => open
    );

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
        IsFull        => txIsFull,
        Pop           => txPop,
        WriteEnable   => txWriteEnable,
        DataIn        => txDataIn,
        DataOut       => txDataOut
    );

    -- Uart RX
    UartRx : entity work.SimpleUartRx 
    generic map (
        cClockFrequency => 100e6,
        cUartBaudRate   => 115200,
        cNumBits        => 8,
        cClocksPerBit   => 100e6 / 115200
    )
    port map (
        Clock   => Clock,
        Rx      => Rx,
        Done    => rxWriteEnable,
        RxData  => rxDataIn
    );
    
    -- RX FIFO
    RxFifo : entity work.SimpleFifo
    generic map (
        cAddressWidth => cAddressWidth
    )
    port map (
        Clock         => Clock,
        Resetn        => Resetn,
        SoftReset     => '0',
        IsAlmostEmpty => open,
        IsAlmostFull  => open,
        IsEmpty       => rxIsEmpty,
        IsFull        => open,
        Pop           => rxPop,
        WriteEnable   => rxWriteEnable,
        DataIn        => rxDataIn,
        DataOut       => rxDataOut
    );

    txIsNotFull <= not txIsFull;
    rxIsNotEmpty <= not rxIsEmpty;

    -- Echo
    Echo : entity work.SimpleEcho
    generic map (
        cAddressWidth => cAddressWidth
    )
    port map (
        Clock          => Clock,
        DataAvailable  => rxIsNotEmpty,
        GetNext        => rxPop,
        InputChar      => rxDataOut,
        OutputChar     => txDataIn,
        WriteEnable    => txWriteEnable,
        StartSending   => startSending,
        WriteAvailable => txIsNotFull,
        NumBytesOut    => numBytesOut
    );

    IntermediateControl: process(Clock)
    begin
        if rising_edge(Clock) then
            case state is
                when IDLE =>
                    txEnable <= '0';
                
                    if startSending = '1' then
                        txPop             <= '1';
                        numBytesRemaining <= numBytesOut;
                        state             <= GET_NEXT;
                    else 
                        txPop <= '0';
                    end if;
                when GET_NEXT =>
                    txEnable <= '1';
                    txPop    <= '0';

                    state <= WAIT_FOR_DONE;
                when WAIT_FOR_DONE =>
                    txEnable <= '0';

                    if uartTxDone = '1' then
                        if numBytesRemaining > 0 then
                            numBytesRemaining <= numBytesRemaining - 1;
                            state             <= GET_NEXT;
                            txPop             <= '1';
                        else
                            txPop <= '0';
                            state <= IDLE;
                        end if;
                    else
                        txPop <= '0';
                        state <= WAIT_FOR_DONE;
                    end if;
                when others =>
                    state <= IDLE;
            end case;
        end if;
    end process IntermediateControl;
    
end architecture rtl;