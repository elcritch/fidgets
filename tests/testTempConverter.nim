import std/strformat, std/hashes, std/sequtils
import parseutils, memo
import re

import fidgetty
import fidgetty/themes
import fidgetty/textinput
import fidgetty/fields

loadFont("IBM Plex Sans", "IBMPlexSans-Regular.ttf")

type
  Fahrenheit = distinct float
  Celsius = distinct float

func toF*(val: Celsius): Fahrenheit =
  Fahrenheit val.float * (9.0/5.0) + 32.0
func toF*(val: Fahrenheit): Fahrenheit =
  val

func toC*(val: Fahrenheit): Celsius =
  Celsius (val.float - 32.0) * (5.0/9.0)
func toC*(val: Celsius): Celsius =
  val

template parseTemp(val, kind: untyped) =
  if `val`.updated.isSome():
    var res: float
    if parseFloat(`val`.updated.get().strip(), res, 0) > 0:
      self.temp = `kind`(res).toC()

template LabeledTextInput(valName, conv, fstr: untyped) =
    FieldRight(label = fstr.repr()):
      with:
        let valName {.inject.} =
          TextInput:
            value = block:
              let sval {.inject.} = conv(self.temp).float32
              fmt"{sval:5.1f}".strip()
            proc setup() =
              size 5'em, 2'em
            ignorePostfix = true
            pattern = re"[0-9\.]"

proc exampleApp*(): ExampleApp {.appFidget.} =
  ## defines a stateful app widget
  properties:
    temp: Celsius

  render:
    setTitle(fmt"Fidget Animated Progress Example")
    textStyle theme
    fill palette.background
    box 0, 0, 100'vw, 100'vh

    VHBox(Spacer(0, 50'ph-2.Em)):
      rectangle: size 5'pw, 2'em
      LabeledTextInput(cVal, toC, Celsius)
      cVal.parseTemp(Celsius)
      rectangle: size 5'pw, 2'em
      basicLabel(" = ")
      rectangle: size 5'pw, 2'em
      LabeledTextInput(fVal, toF, Fahrenheit)
      fVal.parseTemp(Fahrenheit)
      rectangle: size 5'pw, 2'em


startFidget(
  wrapApp(exampleApp, ExampleApp),
  setup = 
    when defined(demoBulmaTheme): setup(bulmaTheme)
    else: setup(grayTheme),
  w = 440,
  h = 140,
  uiScale = 2.0)
