# Package

version       = "0.4.1"
author        = "Jaremy Creechley"
description   = "Widget library built on Fidget written in pure Nim and OpenGL rendered"
license       = "MIT"
srcDir        = "src"

# Dependencies

requires "nim >= 1.6.5"
requires "pixie >= 5.0.1"
requires "cssgrid >= 0.2.7"
# requires "https://github.com/elcritch/fidget.git#head"
requires "zippy >= 0.10.4"
requires "patty >= 0.3.4"
requires "macroutils >= 1.2.0"
requires "cdecl >= 0.5.10"
requires "asynctools >= 0.1.1"

import strutils, strformat

task test, "Run tests":
  for fl in "tests/".listFiles():
    if fl.startsWith("t") and fl.endsWith(".nim"):
      echo "tests: ", fl
      exec fmt"nim c {fl}"
