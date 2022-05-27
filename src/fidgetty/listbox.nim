import widgets
import button

# var framecount = 0

proc listbox*(
    items {.property: items.}: seq[string],
    selected {.property: selected.}: var int,
    itemsVisible {.property: itemsVisible.}: int
): ListBoxState {.statefulFidget.} =
  ## dropdown widget 
  init:
    size 8'em, 1.5'em
    cornerRadius theme
    stroke theme.outerStroke
    imageOf theme.gloss

  properties:
    showScrollBars: bool

  render:
    let
      cb = current.box()
      bw = cb.w
      bh = cb.h
      bih = bh * 1.0

    let
      bdh = min(bih * itemsVisible.float32, windowLogicalSize.y/2)

    let evts = useEvents()
    let evtCode = current.code
    # echo fmt"event code: {current.code} {evts.data.keys().toSeq().repr}"

    box 0, bh, bw, bdh
    clipContent true

    group "menuoutline":
      box 0, 0, bw, bdh
      cornerRadius theme
      stroke theme.outerStroke

    inPopup = true
    defer: inPopup = false
    popupBox = current.screenBox

    group "menu":
      box 0, 0, bw, bdh
      layout lmVertical
      counterAxisSizingMode csAuto
      itemSpacing theme.itemSpacing
      scrollBars true

      var menuEvts: seq[Variant]
      if evts.pop(evtCode, menuEvts):
        for me in menuEvts:
          if me.ofType(ScrollEvent):
            match me.get(ScrollEvent):
              ScrollTo(perc: nperc):
                current.offset.y = (current.screenBox.h - parent.screenBox.h) * nperc
                current.scrollPercent = nperc
              ScrollPage(amount: amount):
                current.scrollPercent += amount

      for idx, buttonName in pairs(items):
        group "menuBtn":
          box 0, 0, bw, bih
          layoutAlign laCenter
          # echo fmt"{idx=} => {isCovered(popupBox)=}"

          let clicked = widget button:
            label: buttonName
            isActive: idx == selected
            setup:
              clearShadows()
              imageTransparency 0.1
              boxOf parent
              cornerRadius 0
              stroke theme.innerStroke
          if clicked:
            echo fmt"listbox: set {selected=}"
            selected = idx
