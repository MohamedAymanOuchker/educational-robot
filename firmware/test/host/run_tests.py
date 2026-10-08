"""Compile production firmware against host hardware/RTOS doubles and run regressions."""
from pathlib import Path
import os
import shutil
import subprocess
import tempfile

root = Path(__file__).resolve().parent
compiler = os.environ.get("CXX") or shutil.which("g++") or shutil.which("clang++")
if not compiler:
    raise SystemExit("Install a C++17 host compiler (g++ or clang++), or set CXX.")
with tempfile.TemporaryDirectory(prefix="ebug-host-", dir=root) as directory:
    binary = Path(directory) / ("regressions.exe" if os.name == "nt" else "regressions")
    subprocess.run([compiler, "-std=c++17", "-pthread", "-Wall", "-Wextra", "-Wno-unused-parameter",
                    "-I" + str(root / "stubs"), str(root / "harness.cpp"), "-o", str(binary)], check=True)
    subprocess.run([str(binary)], check=True)
