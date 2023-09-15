library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library universal;
    use universal.TypeUtilityPkg.all;

entity SimpleEcho is
    generic (
        cNumBits : natural := 8;
        cAddressWidth : natural := 10
    );
    port (
        Clock          : in  std_logic;
        DataAvailable  : in  std_logic;
        GetNext        : out std_logic;
        InputChar      : in  std_logic_vector(7 downto 0);
        OutputChar     : out std_logic_vector(7 downto 0);
        WriteEnable    : out std_logic;
        StartSending   : out std_logic;
        WriteAvailable : in  std_logic;
        NumBytesOut    : out natural
    );
end entity SimpleEcho;

architecture rtl of SimpleEcho is
    constant terminationChar : character := LF;
    constant cMaxNumBytes : natural := 2 ** cAddressWidth;
    signal lastChar : character;
    type state_t is (IDLE, READCHAR, EVAL);
    signal state : state_t;
    signal numBytesEncountered : natural range 0 to cMaxNumBytes;
begin
    
    Echo: process(Clock)
    begin   
        -- Figure out the remainder of the data writing section
        -- Need to stop writing data when full, when the buffer is full then go ahead and send.
        if rising_edge(Clock) then
            case state is
                when IDLE =>
                    WriteEnable  <= '0';
                    StartSending <= '0';
                    numBytesOut  <= 0;

                    if DataAvailable = '1' and WriteAvailable = '1' then
                        GetNext <= '1';
                        state   <= READCHAR;
                    else
                        GetNext <= '0';
                        state   <= IDLE;
                    end if;
                when READCHAR =>
                    GetNext  <= '0';
                    if numBytesEncountered < cMaxNumBytes then
                        numBytesEncountered <= numBytesEncountered + 1;
                    end if;
                    state <= EVAL;
                when EVAL => 
                    OutputChar  <= InputChar;
                    WriteEnable <= '1'; 
                    state       <= IDLE;
                    
                    if ToCharacter(InputChar) = terminationChar or numBytesEncountered = cMaxNumBytes then
                        StartSending <= '1';
                        numBytesOut  <= numBytesEncountered;
                        numBytesEncountered <= 0;
                    end if;
                when others =>
                    state <= IDLE;
            end case;
        end if;
    end process Echo;
    

end architecture rtl;