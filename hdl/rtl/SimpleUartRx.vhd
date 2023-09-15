library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity SimpleUartRx is
    generic (
        cClockFrequency : natural := 10000000;
        cUartBaudRate   : natural := 115200;
        cNumBits        : natural := 8;
        cClocksPerBit   : natural := cClockFrequency / cUartBaudRate
    );
    port (
        Clock  : in  std_logic;
        Rx     : in  std_logic;
        Done   : out std_logic;
        RxData : out std_logic_vector(cNumBits - 1 downto 0)
    );
end entity SimpleUartRx;

architecture rtl of SimpleUartRx is
    type state_t is (IDLE, START, DATA, STOPBITS, CLEANUP);
    signal state        : state_t;
    signal rxSample0    : std_logic;
    signal rxSample1    : std_logic;
    signal clockCounter : natural range 0 to cClocksPerBit - 1 := 0;
    signal bitIndex     : natural range 0 to cNumBits - 1 := 0;
begin
    
    SampleRx: process(Clock)
    begin
        if rising_edge(Clock) then
            rxSample1 <= rxSample0;
            rxSample0 <= Rx;
        end if;
    end process SampleRx;

    UartRxStateMachine: process(Clock)
    begin
        if rising_edge(Clock) then
            case state is
                when IDLE =>
                    Done         <= '0';
                    clockCounter <= 0;
                    bitIndex     <= 0;

                    if rxSample1 = '0' then
                        state <= START;
                    else
                        state <= IDLE;
                    end if;
                when START =>
                    if clockCounter = (cClocksPerBit - 1)/2 then
                        if rxSample1 = '0' then
                            clockCounter <= 0;
                            state        <= DATA;
                        else
                            state <= IDLE;
                        end if;
                    else
                        clockCounter <= clockCounter + 1;
                        state        <= START;
                    end if;
                when DATA =>
                    if clockCounter < cClocksPerBit - 1 then
                        clockCounter <= clockCounter + 1;
                        state        <= DATA;
                    else
                        clockCounter     <= 0;
                        RxData(bitIndex) <= rxSample1;

                        if bitIndex < cNumBits - 1 then
                            bitIndex <= bitIndex + 1;
                            state    <= DATA;
                        else
                            bitIndex <= 0;
                            state    <= STOPBITS;
                        end if;
                    end if;
                when STOPBITS =>
                    if clockCounter < cClocksPerBit - 1 then
                        clockCounter <= clockCounter + 1;
                        state        <= STOPBITS;
                    else
                        done         <= '1';
                        clockCounter <= 0;
                        state        <= CLEANUP;
                    end if;
                when CLEANUP =>
                    state <= IDLE;
                    done  <= '0';
                when others =>
                    state <= IDLE;
            end case;
        end if;
    end process UartRxStateMachine;
    
end architecture rtl;