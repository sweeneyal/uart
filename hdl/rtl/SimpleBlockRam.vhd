library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library universal;
    use universal.TypeUtilityPkg.all;

entity SimpleBlockRam is
    generic (
        cDataWidth : natural := 8;
        cAddressWidth : natural := 10
    );
    port (
        WriteClock   : in  std_logic;
        WriteAddress : in  std_logic_vector(cAddressWidth - 1 downto 0);
        WriteEnable  : in  std_logic;
        WriteData    : in  std_logic_vector(cDataWidth-1 downto 0);
        ReadClock    : in  std_logic;
        ReadAddress  : in  std_logic_vector(cAddressWidth - 1 downto 0);
        ReadEnable   : in  std_logic;
        ReadData     : out std_logic_vector(cDataWidth-1 downto 0)
    );
end entity SimpleBlockRam;

architecture rtl of SimpleBlockRam is
    type ram_t is array (2**cAddressWidth - 1 downto 0) of std_logic_vector(cDataWidth-1 downto 0);
    signal Ram : ram_t;
begin
    
    WriteToRam: process(WriteClock)
    begin
        if rising_edge(WriteClock) then
            if WriteEnable = '1' and not (ReadAddress = WriteAddress and ReadEnable = '1') then
                Ram(ToInteger(WriteAddress)) <= WriteData;
            end if;
        end if;
    end process WriteToRam;

    ReadFromRam: process(ReadClock)
    begin
        if rising_edge(ReadClock) then
            if ReadEnable = '1' then
                ReadData <= Ram(ToInteger(ReadAddress));
            else
                ReadData <= (others => '0');
            end if;
        end if;
    end process ReadFromRam;
    
end architecture rtl;