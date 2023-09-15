library vunit_lib;
context vunit_lib.vunit_context;

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library universal;
    use universal.TypeUtilityPkg.all;

package TbUartPkg is

    procedure Nominal_HelloWorld(
        signal Clock   : in  std_logic;
        signal Resetn  : out std_logic;
        signal Rx      : out std_logic;
        signal Tx      : in  std_logic
    );
    
end package TbUartPkg;

package body TbUartPkg is

    procedure Startup(
        signal Clock   : in  std_logic;
        signal Resetn  : out std_logic;
        signal Rx      : out std_logic;
        signal Tx      : in  std_logic
    ) is
    begin
        Resetn <= '0';
        wait until rising_edge(clock);
        Resetn <= '1';
        wait until falling_edge(clock);
        assert Tx = '1';
    end procedure;

    procedure UartWriteByte (
        variable Data : in  std_logic_vector(7 downto 0);
        signal Rx     : out std_logic
    ) is
        constant cClocksPerBit : natural := 125000000 / 115200;
        constant cBitPeriod    : time    := cClocksPerBit * 8 ns;
    begin
        Rx <= '0';
        wait for cBitPeriod;

        for ii in 0 to 7 loop
            Rx <= Data(ii);
            wait for cBitPeriod;
        end loop;

        Rx <= '1';
        wait for cBitPeriod;
    end procedure;

    procedure UartReadByte (
        variable Data : out std_logic_vector(7 downto 0);
        signal Tx   : in  std_logic
    ) is
        constant cClocksPerBit : natural := 125000000 / 115200;
        constant cBitPeriod    : time    := cClocksPerBit * 8 ns;
    begin
        wait until Tx = '0';
        wait for cBitPeriod;

        for ii in 0 to 7 loop
            Data(ii) := Tx;
            wait for cBitPeriod;
        end loop;

        wait until Tx = '1';
        wait for cBitPeriod;
    end procedure;

    procedure Transmit (
        signal Clock             : in std_logic;
        signal Rx                : out std_logic;
        constant cOutgoingString : in string
    ) is
        variable Data : std_logic_vector(7 downto 0);
    begin
        for ii in 1 to cOutgoingString'length loop
            Data := std_logic_vector(ToByte(cOutgoingString(ii)));
            UartWriteByte(Data => Data, Rx => Rx);
        end loop;
    end procedure;

    procedure Receive (
        signal Clock            : in std_logic;
        signal Tx               : in std_logic;
        variable recievedString : out string
    ) is
        variable Data : std_logic_vector(7 downto 0);
    begin
        for ii in 1 to recievedString'length loop
            UartReadByte(Data => Data, Tx => Tx);
            recievedString(ii) := ToCharacter(byte(Data));
        end loop;
    end procedure;

    procedure Nominal_HelloWorld(
        signal Clock   : in  std_logic;
        signal Resetn  : out std_logic;
        signal Rx      : out std_logic;
        signal Tx      : in  std_logic
    ) is
        variable str : string(1 to 14);
    begin
        Startup(Clock=>Clock, Resetn=>Resetn, Rx=>Rx, Tx=>Tx);
        Transmit(Clock=>Clock, Rx=>Rx, cOutgoingString=>"Hello World!" & CR & LF);
        Receive(Clock=>Clock, Tx=>Tx, recievedString=>str);
        info(str);
        assert CheckStringEqual(str, "Hello World!" & CR & LF);
    end procedure;
    
end package body TbUartPkg;