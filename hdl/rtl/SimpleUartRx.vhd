library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity SimpleUartRx is
    generic (
        cClockFrequency : natural := 100000000;
        cUartBaudRate   : natural := 9600
    );
    port (
        Clock  : in  std_logic;
        Rx     : in  std_logic;
        Done   : out std_logic;
        RxData : out std_logic_vector(7 downto 0)
    );
end entity SimpleUartRx;

architecture rtl of SimpleUartRx is
    constant cClocksPerBit     : natural := cClockFrequency / cUartBaudRate;
    constant cClocksPerBit_uns : unsigned(15 downto 0) := unsigned(cClocksPerBit, 16);
    constant cBitIndexMax      : natural := 7;

    type state_t is (IDLE, START_BIT, DATA, STOP_BIT);
    signal state : state_t := IDLE;

    signal rxSampleVector : std_logic_vector(1 downto 0);
    signal rxd            : std_logic;
    signal bitTimer       : unsigned(15 downto 0) := (others => '0');
    signal bitIndex       : natural range 0 to cBitIndexMax := 0;
    signal bitDone        : std_logic;
    signal rxDataReg      : std_logic_vector(cBitIndexMax downto 0);
begin
    
    ClockDomainCrosser: process(Clock)
    begin
        if rising_edge(Clock) then
            rxd <= rxSampleVector(1);
            rxSampleVector(1) <= rxSampleVector(0);
            rxSampleVector(0) <= Rx;
        end if;
    end process SampleRx;

    RxStateMachine: process(Clock)
    begin
        if rising_edge(Clock) then
            case state is
                when IDLE =>
                    if (rxd = '0') then
                        state <= START_BIT;
                    end if;
                when START_BIT =>
                    if (bitDone = '1') then
                        state <= DATA;
                    end if;
                when DATA =>
                    if (bitDone = '1') then
                        if (bitIndex = cBitIndexMax) then
                            state <= STOP_BIT;
                        end if;
                    end if;
                when STOP_BIT =>
                    if (bitDone = '1') then
                        state <= IDLE;
                    end if;
                when others =>
                    state <= IDLE;
            end case;
        end if;
    end process RxStateMachine;

    BitTimerControl : process(Clock)
    begin
        if rising_edge(Clock) then
            if (state = READY_STATE) or (bitDone = '1') then
                bitTimer <= (others => '0');
            else
                bitTimer <= bitTimer + 1;
            end if;
        end if;
    end process BitTimerControl;

    bitDone <= Bool2Bit(bitTimer = cClocksPerBit_uns);

    BitCountingControl : process(Clock)
    begin
        if rising_edge(Clock) then
            if (state = IDLE) or (bitDone = '1') then
                bitIndex <= 0;
            elsif (state = DATA) then
                bitIndex <= bitIndex + 1;
            end if;
        end if;
    end process BitCountingControl;

    RxBitControl: process(Clock)
    begin
        if rising_edge(Clock) then
            if (state = DATA) and (bitDone = '1') then
                rxDataReg(bitIndex) <= rxd;
            end if;
        end if;
    end process RxBitControl;

    RxData <= rxDataReg;
    Done   <= Bool2Bit(state = STOP_BIT and bitDone = '1');
    
end architecture rtl;