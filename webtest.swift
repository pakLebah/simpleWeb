/**
 SimpleWeb Swift Demo
 v.1.0 - Oct, 2016
 © pak.lebah
 */

import Foundation
import SimpleWeb

/* --- CUSTOM METHODS --- */

func p() { webWrite("<p>", width: 0) }  // start a html paragraph
func bold(_ s: String)      -> String { return "<b>\(s)</b>" }
func italic(_ s: String)    -> String { return "<i>\(s)</i>" }
func underline(_ s: String) -> String { return "<u>\(s)</u>" }
func strike(_ s: String)    -> String { return "<s>\(s)</s>" }
func sub(_ s: String)       -> String { return "<sub>\(s)</sub>" }
func sup(_ s: String)       -> String { return "<sup>\(s)</sup>" }
func big(_ s: String)       -> String { return "<big>\(s)</big>" }
func small(_ s: String)     -> String { return "<small>\(s)</small>" }

/* --- MAIN WEB PROGRAM --- */

let leftWidth = -1 // left alignment is from css

openHTML(title: "Test")
webPageHeader("Hello World from Swift on Linux!", level:2)

webWriteln(bold("Read input:"))
p()
webWrite("String: ", width: leftWidth)
let str = webRead("")
let btn = webReadButton(" ► ")
webWrite("Integer: ")
let int = webReadln(0)
webWrite("Double: ")
let float = webReadln(0.0)
webWrite("Boolean: ")
let bool = webReadln(true, label: "boolean")
webWrite("Option: ")
let options = ["option 1","option 2","option 3"]
let opt = webReadOption(labels: options)
webWrite("Select: ")
let sel = webReadSelect(-1, items: ["item 1","item 2","item 3"])
webWriteln("Text: ")
let txt = webReadMemo("Lorem ipsum dolor sit amet, consectetur adipiscing elit.")
webWrite("Output: ", width: leftWidth)
let out = webReadOption(0, labels: ["table","list"], newLine: false)
webWriteln()

if webHasInput {
  p()
  webWriteln(bold("Write output:"))
  switch (out == 0) {
    case true:  // table
      webOpenTable(["Type",  "Value"])
      webTableRow(["Button", btn ? "[clicked]" : "[not clicked]"])
      webTableRow(["String", str.isEmpty ? "[empty]" : str])
      webTableRow(["Integer","\(int)"])
      webTableRow(["Double", "\(float)"])
      webTableRow(["Boolean","\(bool)"])
      webTableRow(["Option", opt < 0 ? "[none]" : "\(options[opt])"])
      webTableRow(["Select", sel < 0 ? "[none]" : "\(sel)"])
      webTableRow(["Text",   txt.isEmpty ? "[empty]" : txt])
      webCloseTable()
    case false: // list
      webOpenList(ordered: false)
      webListItem("Button:  \(btn ? "[clicked]" : "[not clicked]")")
      webListItem("String:  \(str.isEmpty ? "[empty]" : str)")
      webListItem("Integer: \(int)")
      webListItem("Double:  \(float)")
      webListItem("Boolean: \(bool)")
      webListItem("Option:  \(opt < 0 ? "[none]" : "\(options[opt])")")
      webListItem("Select:  \(sel < 0 ? "[none]" : "\(sel)")")
      webListItem("Text:    \(txt.isEmpty ? "[empty]" : "")")
      if !txt.isEmpty { webWriteBlock(txt) }
      webCloseList()
  }
  let linkMod  = webGetLink("viewcode.cgi?file=SimpleWeb.swift", caption: "here")
  let linkDemo = webGetLink("viewcode.cgi?file=webtest.swift", caption: "here")
  webWriteln("<p>Source code of the module is \(linkMod) and the demo is \(linkDemo).")
}

closeHTML()

/* --- END OF PROGRAM --- */