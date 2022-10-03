import std/strformat, std/sequtils, std/strutils
import std/asyncdispatch
import asynctools

import fidgetty
import fidgetty/[themes, button, dropdown]

proc verExamples(): string

proc log[T](self: T, msg: string) =
  const logCnt = 1000
  self.output.add(msg)
  self.updateLines = 1
  if self.output.len() > logCnt:
    self.output = self.output[^logCnt..^1]
  refresh()

proc log[T](self: T, msg: seq[string]) =
  for line in msg:
    self.log(line)

type
  AppStatus = ref object
    output: seq[string]
    updateLines: int
    versions: seq[string]
    versionSelected: int
    listPid: Future[void] 
    runPid: Future[void]
    initialized: bool

proc runInstall(self: AppStatus, version: string) {.async.}
proc doInstallNim(self: AppStatus)
proc listVersions(self: AppStatus) {.async.}

loadFont("IBM Plex Sans", "IBMPlexSans-Regular.ttf")

proc new*(_: typedesc[AppStatus]): AppStatus =
  new result
  result.versionSelected = -1
  result.log "getting versions..."
  result.runPid = emptyFuture() 
  result.listPid = listVersions(result)

proc chooseNimApp*() =
  ## defines a stateful app widget
  useState[AppStatus](self)

  setTitle(fmt"Fidget Animated Progress Example")
  textStyle theme
  fill palette.background.lighten(0.02)
  strokeWeight 1

  font "IBM Plex Sans", 16, 200, 0, hCenter, vCenter

  frame "autoLayout":
    # setup frame for css grid
    setWindowBounds(vec2(440, 460), vec2(1200, 800))
    box 2'pp, 2'pp, 98'pp, 98'pp
    fill clearColor
    cornerRadius 0.5'em
    # clipContent true
    
    # Setup CSS Grid Template
    gridTemplateColumns ["edge-l"]  40'ux \
                        ["outer-l"] 50'ux \
                        ["inner-l"] 1'fr \
                        ["inner-r"] 50'ux \
                        ["outer-r"] 40'ux \
                        ["edge-r"]

    gridTemplateRows  ["header"] 30'ux \
                      ["top"]    70'ux \
                      ["middle"] 1'fr \ 
                      ["footer"] 1'fr \
                      ["bottom"]

    # draw debug lines
    # gridTemplateDebugLines true

    Theme(infoPalette({txtHighlight, bgDarken})):
      rectangle "banner":
        fill palette.background
        cornerRadius 1'em
        gridColumn "outer-l" // "outer-r"
        gridRow "top" // "middle"
        # echo "banner: box: ", current.box.repr
        text "header":
          font "IBM Plex Sans", 32, 200, 0, hCenter, vCenter
          size 100'pp, 100'pp
          fill palette.text
          characters "Choose Nim!"
          textAutoResize tsHeight

    frame "footer-box":
      font "IBM Plex Sans", 12, 200, 0, hCenter, vCenter
      gridColumn "outer-l" // "outer-r"
      gridRow "footer" // "bottom"
      # size 80'vw, 200'ui
      # echo "footer-box: box: ", current.box.repr

      rectangle "footer":
        fill palette.background.lighten(0.03)
        cornerRadius 1'em
        clipContent true
        scrollBars true
        size 100'pp, self.output.len().UICoord * 22'ui

        if self.updateLines == 2:
          current.offset.y =
            (current.screenBox.h - parent.screenBox.h) * 1.0.UICoord
          self.updateLines = 0
          refresh()

        text "footer-txt":
          size 100'pp, 100'pp
          fill palette.text
          textAutoResize tsHeight
          size 100'pp, self.output.len().float * lineHeight()
          if self.updateLines == 1:
            self.updateLines = 2
            characters self.output.join("\n")
            refresh()
          # echo "footer-txt: box: ", current.box.repr

    rectangle "css grid item":
      # Setup CSS Grid Template
      cornerRadius 1'em
      gridColumn "outer-l" // "outer-r"
      gridRow "middle" // "footer"
      # some color stuff
      fill palette.background

      frame "options":
        # centeredXY 90'pw, 90'ph
        gridTemplateColumns 1'fr 3'fr 250'ux 3'fr 1'fr
        gridTemplateRows 16'ux 4'fr 2'fr 40'ux 1'fr 40'ux 1'fr 40'ux 1'fr 1'fr
        # gridTemplateDebugLines true

        font "IBM Plex Sans", 22, 200, 0, hCenter, vCenter

        Dropdown:
          disabled: self.versions.len() == 0
          items: self.versions
          defaultLabel: "Available Versions"
          selected: self.versionSelected
          gridColumn 3 // 4
          gridRow 4 // 5
          size 250'ui, 40'ui
        do -> ChangeEvent[int]:
          Changed(idx):
            self.versionSelected = idx
            refresh()

        Button:
          label: fmt"Install Nim"
          disabled: self.versionSelected < 0
          onClick:
            self.doInstallNim()
          gridColumn 3 // 4
          gridRow 6 // 7
          size 250'ui, 40'ui

        # make a textbox behind the above
        rectangle "button-bg":
          height 6'em
          gridColumn 2 // 5
          gridRow 3 // 10
          fill palette.background

        text "info":
          font "IBM Plex Sans", 14, 200, 0, hCenter, vCenter
          height 6'em
          gridColumn 2 // 5
          gridRow 2 // 3
          fill palette.text
          characters """
          ChooseNimApp installs the Nim programming language from official downloads and sources, enabling you to easily switch between stable and development compilers.
          """

proc runInstall(self: AppStatus, version: string) {.async.} =
  self.log "installing version: " & version
  let opts = {poStdErrToStdOut, poUsePath, poEvalCommand}
  when defined(debugExample):
    # let p = startProcess("ping", @["127.0.0.1"], nil, opts)
    # let p = startProcess("ping 127.0.0.1", args, nil, options=opts)
    let p = startProcess("ping 127.0.0.1 ", options=opts)
  else:
    # let p = startProcess("ping 127.0.0.1",  options=opts)
    let cmd = "choosenim --noColor " & version & " "
    echo "cmd: ", cmd
    let p = startProcess(cmd, options=opts)

  self.log "running install "
  echo "running..."
  let bufferSize = 4
  var data = newString(bufferSize)
  var msg = ""
  while true:
    let res = await p.outputHandle.readInto(addr data[0], bufferSize)
    echo "reading..."
    if res > 0:
      data.setLen(res)
      msg &= data
      if "\n" in msg:
        var m = msg.split("\n")
        msg = m.pop()
        self.log m
      data.setLen(bufferSize)
    else:
      break
  # result.exitcode = await p.waitForExit()
  let code = await p.waitForExit
  self.log "exited: " & $code
  refresh()

proc doInstallNim(self: AppStatus) =
  try:
    let selected = self.versionSelected
    let version = self.versions[selected]
    let pid = self.runInstall(version)
    self.runPid = pid
  except Exception as err:
    self.log "Error installing: "
    self.log err.msg

proc listVersions(self: AppStatus) {.async.} =
  ## This simple procedure will "tick" ten times delayed 1,000ms each.
  ## Every tick will increment the progress bar 10% until its done. 
  self.log "getting versions..."
  await sleepAsync(100)
  when defined(debugExample):
    let (res, output) = (0, verExamples())
  else:
    let (res, output) = await execProcess("choosenim --noColor versions")
  
  var avails = false
  for line in output.split("\n").mapIt(strutils.strip(it)):
    if avails and line.len() > 0:
      self.versions.add(line)
      self.log(line)
    if line == "Available:":
      avails = true
  self.log "versions loaded..."
  self.updateLines = 1
  refresh()


startFidget(
  chooseNimApp,
  setup = 
    setup(darkNimTheme),
  w = 800,
  h = 600
)

const verExample = " Channel: stable\n \n Installed:  \n * 1.6.6 (latest)\n \n Available:  \n 1.6.4\n 1.6.2\n 1.6.0\n 1.4.8\n 1.4.6\n 1.4.4\n 1.4.2\n 1.4.0\n 1.2.18\n 1.2.16\n 1.2.14\n 1.2.12\n 1.2.10\n 1.2.8\n 1.2.6\n 1.2.4\n 1.2.2\n 1.2.0\n 1.0.10\n 1.0.8\n 1.0.6\n 1.0.4\n 1.0.2\n 1.0.0\n 0.20.2\n 0.20.0\n 0.19.6\n 0.19.4\n 0.19.2\n \n \n \n "

proc verExamples(): string =
  echo "fake version..."
  verExample
