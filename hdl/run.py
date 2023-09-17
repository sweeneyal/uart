import os
from vunit import VUnit

use_xilinx = True

# Create VUnit instance by parsing command line arguments
vu = VUnit.from_argv()

# Optionally add VUnit's builtin HDL utilities for checking, logging, communication...
# See http://vunit.github.io/hdl_libraries.html.
vu.add_vhdl_builtins()
# or
# vu.add_verilog_builtins()

dirname = os.path.dirname(__file__)

# Create library 'lib'
osvvm     = vu.add_external_library("osvvm", "/opt/ghdl/lib/ghdl/vendors/osvvm/v08")
universal = vu.add_external_library("universal", "libraries/universal")
unisim    = vu.add_external_library("unisim", "/opt/ghdl/lib/ghdl/vendors/xilinx-vivado/unisim/v08")
lib       = vu.add_library("lib")

# Add all files ending in .vhd in current working directory to library
if use_xilinx:
    lib.add_source_files(dirname + "/vivado/*.vhd")
else:
    lib.add_source_files(dirname + "/rtl/*.vhd")
lib.add_source_files(dirname + "/tb/*.vhd")

vu.set_sim_option("ghdl.elab_flags", ["-frelaxed", "-fsynopsys"])

# Run vunit function
vu.main()