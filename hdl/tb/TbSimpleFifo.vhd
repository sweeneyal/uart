library vunit_lib;
context vunit_lib.vunit_context;

use std.env.finish;

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library osvvm;
    use osvvm.TbUtilPkg.all;

library work;
    use work.TbSimpleFifoPkg.all;

entity TbSimpleFifo is
    generic(runner_cfg : string);
end entity TbSimpleFifo;

architecture rtl of TbSimpleFifo is
    signal clock   : std_logic;
    signal resetn  : std_logic;
    signal status  : StatusRecord;
    signal drivers : DriversRecord;
    signal dataIn  : std_logic_vector(7 downto 0);
    signal dataOut : std_logic_vector(7 downto 0);
begin
    
    CreateClock(
        clk    => clock,
        period => 5 ns
    );

    dut : entity work.SimpleFifo port map (
        Clock         => clock,
        Resetn        => resetn,
        SoftReset     => drivers.SoftReset,
        IsAlmostEmpty => status.IsAlmostEmpty,
        IsAlmostFull  => status.IsAlmostFull,
        IsEmpty       => status.IsEmpty,
        IsFull        => status.IsFull,
        Pop           => drivers.Pop,
        WriteEnable   => drivers.WriteEnable,
        DataIn        => dataIn,
        DataOut       => dataOut
    );

    TestBench: process
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("Nominal_SingleWriteThenRead") then
                work.TbSimpleFifoPkg.Nominal_SingleWriteThenRead(
                    Clock   => clock,
                    Resetn  => resetn,
                    Status  => status,
                    Drivers => drivers,
                    DataIn  => dataIn,
                    DataOut => dataOut
                );
            elsif run("Nominal_LinearWriteThenRead") then
                work.TbSimpleFifoPkg.Nominal_LinearWriteThenRead(
                    Clock   => clock,
                    Resetn  => resetn,
                    Status  => status,
                    Drivers => drivers,
                    DataIn  => dataIn,
                    DataOut => dataOut
                );
            end if;
        end loop;
        test_runner_cleanup(runner);
    end process TestBench;
    
end architecture rtl;