import os
from vunit import VUnit

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
lib       = vu.add_library("lib")

# Add all files ending in .vhd in current working directory to library
lib.add_source_files(dirname + "/rtl/*.vhd")
lib.add_source_files(dirname + "/tb/*.vhd")

# Run vunit function
vu.main()