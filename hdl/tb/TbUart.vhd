library vunit_lib;
context vunit_lib.vunit_context;

use std.env.finish;

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library osvvm;
    use osvvm.TbUtilPkg.all;

library work;
    use work.TbUartPkg.all;

entity TbUart is
    generic(runner_cfg : string);
end entity TbUart;

architecture rtl of TbUart is
    signal clock  : std_logic;
    signal resetn : std_logic;
    signal rx     : std_logic;
    signal tx     : std_logic;
begin
    
    CreateClock(
        clk    => clock,
        period => 8 ns
    );

    dut : entity work.Uart port map (
        Clock  => clock,
        Resetn => resetn,
        Rx     => rx,
        Tx     => tx
    );

    TestBench: process
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            -- This test fails, I believe because the first transmit happens before the end of the last receive.
            -- The test procedure needs a rework to ensure that it works.
            if run("Nominal_HelloWorld") then
                work.TbUartPkg.Nominal_HelloWorld(
                    Clock  => clock,
                    Resetn => resetn,
                    Rx     => rx,
                    Tx     => tx
                );
            end if;
        end loop;
        test_runner_cleanup(runner);
    end process TestBench;
    
end architecture rtl;