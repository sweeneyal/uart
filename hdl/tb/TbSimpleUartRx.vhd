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

entity TbSimpleUartRx is
    generic(runner_cfg : string);
end entity TbSimpleUartRx;

architecture rtl of TbSimpleUartRx is
    signal clock   : std_logic;
    signal rxData  : std_logic_vector(7 downto 0);
    signal done    : std_logic;
    signal rx      : std_logic;
begin
    
    CreateClock(
        clk    => clock,
        period => 10 ns
    );

    dut : entity work.SimpleUartRx generic map(
        cClockFrequency => 100e6,
        cUartBaudRate   => 9600
    )
    port map(
        Clock  => clock,
        Rx     => rx, 
        Done   => done,
        RxData => rxData
    );

    TestBench: process
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("Nominal_ReceiveByte") then
                work.TbUartPkg.Nominal_ReceiveByte(
                    Clock  => clock,
                    Rx     => rx, 
                    Done   => done,
                    RxData => rxData,
                    cClockFrequency => 100e6,
                    cClockPeriod    => 10 ns,
                    cUartBaudRate   => 9600
                );
            end if;
        end loop;
        test_runner_cleanup(runner);
    end process TestBench;

    test_runner_watchdog(runner, 10 ms);
end architecture rtl;