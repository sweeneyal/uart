import os, sys
from vunit import VUnit
from pathlib import Path

dirname = os.path.dirname(__file__)

path = Path(dirname)
parent = path.parent.absolute()

sys.path.append(str(parent) + "/libraries")
from hdlscriptkit import utility;

print("Initiating test procedures...")
print("Finding xilinx VHDL functional simulation directory ('.xilinx')...")
xilinx_exists = utility.find_xilinx_directory(dirname)
if xilinx_exists:
    print("Note: '.xilinx' directory found. Xilinx functional tests will be performed after standard functional tests.")
else:
    print("Note: no '.xilinx' directory found. No Xilinx functional simulation will be performed.")

print("Finding xilinx Verilog timing simulation directory ('.xilinx_verilog')...")
xilinx_exists = utility.find_xilinx_directory(dirname)
if xilinx_exists:
    print("Note: '.xilinx_verilog' directory found. Xilinx timing tests will be performed after standard functional tests.")
else:
    print("Note: no '.xilinx_verilog' directory found. No Xilinx timing simulation will be performed.")

use_xilinx = False

# Create VUnit instance by parsing command line arguments
vu = VUnit.from_argv()

# Optionally add VUnit's builtin HDL utilities for checking, logging, communication...
# See http://vunit.github.io/hdl_libraries.html.
vu.add_vhdl_builtins()
# or
# vu.add_verilog_builtins()

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