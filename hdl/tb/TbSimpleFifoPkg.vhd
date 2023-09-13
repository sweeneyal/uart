library vunit_lib;
context vunit_lib.vunit_context;

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library universal;
    use universal.TypeUtilityPkg.all;

package TbSimpleFifoPkg is
    type StatusRecord is record
        IsAlmostEmpty : std_logic;
        IsAlmostFull  : std_logic;
        IsEmpty       : std_logic;
        IsFull        : std_logic;
    end record;

    type DriversRecord is record
        SoftReset   : std_logic;
        Pop         : std_logic;
        WriteEnable : std_logic;
    end record;

    procedure Nominal_SingleWriteThenRead(
        signal Clock   : in  std_logic;
        signal Resetn  : out std_logic;
        signal Status  : in  StatusRecord;
        signal Drivers : out DriversRecord;
        signal DataIn  : out std_logic_vector(7 downto 0);
        signal DataOut : in  std_logic_vector(7 downto 0)
    );

    procedure Nominal_LinearWriteThenRead(
        signal Clock   : in  std_logic;
        signal Resetn  : out std_logic;
        signal Status  : in  StatusRecord;
        signal Drivers : out DriversRecord;
        signal DataIn  : out std_logic_vector(7 downto 0);
        signal DataOut : in  std_logic_vector(7 downto 0)
    );
    
end package TbSimpleFifoPkg;

package body TbSimpleFifoPkg is
    
    procedure Startup(
        signal Clock   : in  std_logic;
        signal Resetn  : out std_logic;
        signal Status  : in  StatusRecord;
        signal Drivers : out DriversRecord
    ) is
    begin
        Drivers.WriteEnable <= '0';
        Drivers.Pop         <= '0';
        Drivers.SoftReset   <= '0';
        Resetn              <= '0';
        wait until rising_edge(clock);
        Resetn <= '1';
        wait until falling_edge(clock);
        assert Status.IsEmpty = '1';
    end procedure;

    procedure WriteLinearData(
        signal Clock       : in  std_logic;
        signal Drivers     : out DriversRecord;
        signal DataIn      : out std_logic_vector(7 downto 0);
        constant numWrites : in  natural
    ) is
    begin
        wait until falling_edge(Clock);
        for ii in 0 to numWrites - 1 loop
            DataIn              <= ToStdLogicVector(ii, 8);
            Drivers.WriteEnable <= '1';
            wait until rising_edge(Clock);
        end loop;
        wait until falling_edge(Clock);
        Drivers.WriteEnable <= '0';
        DataIn              <= ToStdLogicVector(0, 8);
    end procedure;

    procedure ReadOnce(
        signal Clock     : in  std_logic;
        signal Drivers   : out DriversRecord;
        signal DataOut   : in  std_logic_vector(7 downto 0);
        variable expectedDataOut : out integer
    ) is
    begin
        wait until falling_edge(Clock);
        Drivers.Pop <= '1';
        wait until falling_edge(Clock);
        Drivers.Pop <= '0';
        expectedDataOut := ToInteger(DataOut);
    end procedure;

    procedure Nominal_SingleWriteThenRead(
        signal Clock   : in  std_logic;
        signal Resetn  : out std_logic;
        signal Status  : in  StatusRecord;
        signal Drivers : out DriversRecord;
        signal DataIn  : out std_logic_vector(7 downto 0);
        signal DataOut : in  std_logic_vector(7 downto 0)
    ) is
        variable expectedDataOut : integer;
    begin
        Startup(Clock=>Clock, Resetn=>Resetn, Status=>Status, Drivers=>Drivers);
        WriteLinearData(Clock=>Clock, Drivers=>Drivers, DataIn=>DataIn, numWrites=>1);
        ReadOnce(Clock=>Clock, Drivers=>Drivers, DataOut=>DataOut, expectedDataOut=>expectedDataOut);
        assert expectedDataOut = 0;
    end procedure;

    procedure Nominal_LinearWriteThenRead(
        signal Clock   : in  std_logic;
        signal Resetn  : out std_logic;
        signal Status  : in  StatusRecord;
        signal Drivers : out DriversRecord;
        signal DataIn  : out std_logic_vector(7 downto 0);
        signal DataOut : in  std_logic_vector(7 downto 0)
    ) is
        variable expectedDataOut : integer;
    begin
        Startup(Clock=>Clock, Resetn=>Resetn, Status=>Status, Drivers=>Drivers);
        WriteLinearData(Clock=>Clock, Drivers=>Drivers, DataIn=>DataIn, numWrites=>32);
        for ii in 0 to 31 loop
            ReadOnce(Clock=>Clock, Drivers=>Drivers, DataOut=>DataOut, expectedDataOut=>expectedDataOut);
            assert expectedDataOut = ii;            
        end loop;
    end procedure;
    
end package body TbSimpleFifoPkg;