library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity SimpleUartTx is
    generic (
        cClockFrequency : natural := 10000000;
        cUartBaudRate   : natural := 115200;
        cNumBits        : natural := 8;
        cClocksPerBit   : natural := cClockFrequency / cUartBaudRate
    );
    port (
        Clock  : in  std_logic;
        TxData : in  std_logic_vector(cNumBits - 1 downto 0);
        Enable : in  std_logic;
        Tx     : out std_logic;
        Done   : out std_logic;
        Active : out std_logic
    );
end entity SimpleUartTx;

architecture rtl of SimpleUartTx is
    type state_t is (IDLE, START, DATA, STOPBITS, CLEANUP);
    signal state        : state_t;
    signal txActiveData : std_logic_vector(cNumBits - 1 downto 0);
    signal clockCounter : natural range 0 to cClocksPerBit - 1 := 0;
    signal bitIndex     : natural range 0 to cNumBits - 1 := 0;
begin
    
    UartTxStateMachine : process(Clock)
    begin
        if rising_edge(Clock) then
            case state is
                when IDLE =>
                    Done         <= '0';
                    Active       <= '0';
                    Tx           <= '1';
                    clockCounter <= 0;
                    bitIndex     <= 0;

                    if Enable = '1' then
                        txActiveData <= TxData;
                        state        <= START;
                    else
                        state <= IDLE;
                    end if;
                when START =>
                    Active <= '1';
                    Tx     <= '0';

                    if clockCounter < cClocksPerBit - 1 then
                        clockCounter <= clockCounter + 1;
                        state        <= START;
                    else
                        clockCounter <= 0;
                        state        <= DATA;
                    end if;
                when DATA =>
                    Tx <= txActiveData(bitIndex);

                    if clockCounter < cClocksPerBit - 1 then
                        clockCounter <= clockCounter + 1;
                        state        <= DATA;
                    else
                        clockCounter <= 0;

                        if bitIndex < cNumBits - 1 then
                            bitIndex <= bitIndex + 1;
                            state    <= DATA;
                        else
                            bitIndex <= 0;
                            state    <= STOPBITS;
                        end if;
                    end if;
                when STOPBITS =>
                    Tx <= '1';

                    if clockCounter < cClocksPerBit - 1 then
                        clockCounter <= clockCounter + 1;
                        state        <= STOPBITS;
                    else
                        Done         <= '1';
                        clockCounter <= 0;
                        state        <= CLEANUP;
                    end if;
                when CLEANUP =>
                    state  <= IDLE;
                    Done   <= '1';
                    Active <= '0';
                when others =>
                    state <= IDLE;
            end case;
        end if;
    end process UartTxStateMachine ;
    
end architecture rtl;