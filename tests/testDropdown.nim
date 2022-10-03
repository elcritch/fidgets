import fidgetty
import fidgetty/button
import fidgetty/dropdown
  
import print

let dropItems = @["Nim", "UI", "in", "100%", "Nim", "to", 
                  "OpenGL", "Immediate", "mode"]
var dropIndexes = [-1, -1, -1]

loadFont("IBM Plex Sans", "IBMPlexSans-Regular.ttf")

proc drawMain() =
  frame "main":
    font "IBM Plex Sans", 14, 200, 0, hCenter, vCenter
    box 1'em, 1'em, 100'pp - 1.Em, 100'pp - 1.Em

    Vertical:
      itemSpacing 1'em
      text "first desc":
        size 100'pp, 1'em
        fill "#000d00"
        characters "Dropdown example: "
      
      ## we have a few forms of widget event and post widget
      ## handling
      Dropdown:
        size 10'em, 2'em
        defaultLabel "test"
        items dropItems
        selected dropIndexes[0]
      do -> ChangeEvent[int]: # handle events from widget
        Changed(idx):
          dropIndexes[0] = idx
          refresh()

      Dropdown:
        size 10'em, 2'em
        defaultLabel "test"
        items dropItems
        selected dropIndexes[0]
      finally:
        processEvents(ChangeEvent[int]):
          Changed(idx):
            dropIndexes[0] = idx
            refresh()
      
      Dropdown:
        size 10'em, 2'em
        defaultLabel "test"
        items dropItems
        selected dropIndexes[0]
        defer:
          processEvents(ChangeEvent[int]):
            Changed(idx):
              dropIndexes[0] = idx
              refresh()

startFidget(
  drawMain,
  setup = 
    when defined(demoBulmaTheme): setup(bulmaTheme)
    else: setup(grayTheme),
  w = 640,
  h = 700
)
