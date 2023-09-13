library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library universal;
    use universal.TypeUtilityPkg.all;

library work;

entity SimpleFifo is
    generic (
        cDataWidth : natural := 8;
        cAddressWidth : natural := 5
    );
    port (
        Clock         : in  std_logic;
        Resetn        : in  std_logic;
        SoftReset     : in  std_logic;
        IsAlmostEmpty : out std_logic;
        IsAlmostFull  : inout std_logic;
        IsEmpty       : inout std_logic;
        IsFull        : inout std_logic;
        Pop           : in  std_logic;
        WriteEnable   : in  std_logic;
        DataIn        : in  std_logic_vector(cDataWidth-1 downto 0);
        DataOut       : out std_logic_vector(cDataWidth-1 downto 0)
    );
end entity SimpleFifo;

architecture rtl of SimpleFifo is
    constant cMaxAddress  : integer := 2 ** cAddressWidth - 1;
    signal startAddress   : integer range 0 to 2 ** cAddressWidth - 1;
    signal startAddress_v : std_logic_vector(cAddressWidth - 1 downto 0);
    signal address        : integer range 0 to 2 ** cAddressWidth - 1;
    signal address_v      : std_logic_vector(cAddressWidth - 1 downto 0);
    signal size           : integer range 0 to 2 ** cAddressWidth;
begin
    
    address_v <= ToStdLogicVector(address, cAddressWidth);
    startAddress_v <= ToStdLogicVector(startAddress, cAddressWidth);

    BlockRam : entity work.SimpleBlockRam
    generic map 
    (
        cDataWidth    => cDataWidth,
        cAddressWidth => cAddressWidth
    )
    port map
    (
        WriteClock   => Clock,
        WriteAddress => address_v,
        WriteEnable  => WriteEnable and not IsFull,
        WriteData    => DataIn,
        ReadClock    => Clock,
        ReadEnable   => Pop and not IsEmpty,
        ReadAddress  => startAddress_v,
        ReadData     => DataOut
    );

    SizeCounter: process(Clock, Resetn, SoftReset)
    begin
        if Resetn = '0' then
            size <= 0;
        elsif rising_edge(Clock) then
            if SoftReset = '1' then
                size <= 0;
            elsif WriteEnable = '1' and IsFull = '0' then
                size <= size + 1;
            elsif Pop = '1' and IsEmpty = '0' then
                size <= size - 1;
            end if;
        end if;
    end process SizeCounter;

    ErrorGuarding: process(size)
    begin
        if size = 0 then
            IsEmpty       <= '1';
            IsFull        <= '0';
            IsAlmostEmpty <= '0';
            IsAlmostFull  <= '0';
        elsif size = 1 then
            IsEmpty       <= '0';
            IsFull        <= '0';
            IsAlmostEmpty <= '1';
            IsAlmostFull  <= '0';
        elsif size = cMaxAddress + 1 then
            IsEmpty       <= '0';
            IsFull        <= '1';
            IsAlmostEmpty <= '0';
            IsAlmostFull  <= '0';
        elsif size = cMaxAddress then
            IsEmpty       <= '0';
            IsFull        <= '0';
            IsAlmostEmpty <= '0';
            IsAlmostFull  <= '1';
        else
            IsEmpty       <= '0';
            IsFull        <= '0';
            IsAlmostEmpty <= '0';
            IsAlmostFull  <= '0';
        end if;
    end process ErrorGuarding;

    AddressCounter: process(Clock, Resetn)
    begin
        if Resetn = '0' then
            address <= 0;
        elsif rising_edge(Clock) then
            if SoftReset = '1' then
                address <= 0;
            elsif WriteEnable = '1' and IsFull = '0' then
                if address + 1 > cMaxAddress then
                    address <= 0;
                else
                    address <= address + 1;
                end if;
            end if;
        end if;
    end process AddressCounter;

    StartingAddressCounter: process(Clock, Resetn)
    begin
        if Resetn = '0' then
            startAddress <= 0;
        elsif rising_edge(Clock) then
            if SoftReset = '1' then
                startAddress <= 0;
            elsif Pop = '1' and IsEmpty = '0' then
                if startAddress + 1 > cMaxAddress then
                    startAddress <= 0;
                else
                    startAddress <= startAddress + 1;
                end if;
            end if;
        end if;
    end process StartingAddressCounter;
    
end architecture rtl;