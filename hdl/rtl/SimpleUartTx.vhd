library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library universal;
    use universal.TypeUtilityPkg.all;

entity SimpleUartTx is
    generic (
        cClockFrequency : natural := 100000000;
        cUartBaudRate   : natural := 9600
    );
    port (
        Clock  : in  std_logic;
        TxData : in  std_logic_vector(7 downto 0);
        Send   : in  std_logic;
        Tx     : out std_logic;
        Ready  : out std_logic
    );
end entity SimpleUartTx;
        
architecture rtl of SimpleUartTx is    
    constant cClocksPerBit     : natural := cClockFrequency / cUartBaudRate;
    constant cClocksPerBit_uns : unsigned(15 downto 0) := to_unsigned(cClocksPerBit, 16);
    constant cBitIndexMax      : natural := 10;

    type state_t is (READY_STATE, LOAD_BIT, SEND_BIT);
    signal state : state_t := READY_STATE;
    
    signal txDataReg : std_logic_vector(cBitIndexMax - 1 downto 0);
    signal bitTimer  : unsigned(15 downto 0) := (others => '0');
    signal bitIndex  : natural range 0 to cBitIndexMax := 0;
    signal bitDone   : std_logic;
    signal txBit     : std_logic := '1';
begin
    
    TxStateMachine: process(Clock)
    begin
        if rising_edge(Clock) then
            case state is
                when READY_STATE =>
                    if (Send = '1') then
                        state <= LOAD_BIT;
                    end if;
                when LOAD_BIT =>
                    state <= SEND_BIT;
                when SEND_BIT =>
                    if (bitDone = '1') then
                        if (bitIndex = cBitIndexMax) then
                            state <= READY_STATE;
                        else
                            state <= LOAD_BIT;
                        end if;
                    end if;
                when others =>
                    state <= READY_STATE;
            end case;
        end if;
    end process TxStateMachine;

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
            if (state = READY_STATE) then
                bitIndex <= 0;
            elsif (state = LOAD_BIT) then
                bitIndex <= bitIndex + 1;
            end if;
        end if;
    end process BitCountingControl;

    DataLatch: process(Clock)
    begin
        if rising_edge(Clock) then
            if (Send = '1') and (state = READY_STATE) then
                txDataReg <= '1' & TxData & '0';
            end if;
        end if;
    end process DataLatch;

    TxBitControl: process(Clock)
    begin
        if rising_edge(Clock) then
            if (state=READY_STATE) then
                txBit <= '1';
            elsif (state=LOAD_BIT) then
                txBit <= txDataReg(bitIndex);
            end if;
        end if;
    end process TxBitControl;

    Tx <= txBit;
    Ready <= Bool2Bit(state = READY_STATE);
    
end architecture rtl;