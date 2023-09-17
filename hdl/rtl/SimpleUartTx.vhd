library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library universal;
    use universal.TypeUtilityPkg.all;

entity SimpleUartTx is
    generic (
        cClockFrequency : natural := 100000000;
        cUartBaudRate   : natural := 115200
    );
    port (
        Clock  : in  std_logic;
        Resetn : in  std_logic;
        TxData : in  std_logic_vector(7 downto 0);
        Valid  : in  std_logic;
        Tx     : out std_logic;
        Ready  : out std_logic
    );
end entity SimpleUartTx;
        
architecture rtl of SimpleUartTx is
    attribute DONT_TOUCH : boolean;
    attribute DONT_TOUCH of rtl : architecture is true;
    
    constant cClocksPerBit : natural := 100000000 / 115200;
    signal txDataReg       : std_logic_vector(7 downto 0) := "00000000";
    signal clockCounter    : natural range 0 to cClocksPerBit - 1 := 0;
    signal bitCounter      : natural range 0 to 9 := 0;
begin
    
    UartTxStateMachine : process(Clock)
    begin
        Ready <= Bool2Bit(bitCounter = 0 and clockCounter = 0 and Valid = '0')
                 or Bool2Bit(bitCounter = 0 and clockCounter = 1);

        if rising_edge(Clock) then
            if Resetn = '0' then
                clockCounter <= 0;
                bitCounter   <= 0;
                Tx           <= '1';
            elsif clockCounter > 0 then
                clockCounter <= clockCounter - 1;
            elsif bitCounter > 0 then
                Tx <= txDataReg(0);
                txDataReg    <= '1' & txDataReg(7 downto 1);
                clockCounter <= cClocksPerBit - 1;
                bitCounter   <= bitCounter - 1;
            elsif valid = '1' then
                clockCounter <= cClocksPerBit - 1;
                bitCounter   <= 9;
                Tx           <= '0';
                txDataReg    <= TxData;
            else
                Tx <= '1';
            end if;
        end if;
    end process UartTxStateMachine ;
    
end architecture rtl;