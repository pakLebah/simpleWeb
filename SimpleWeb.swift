/**
 SimpleWeb
 ---------
 This is a module for simple CGI web programming using Swift 3.
 v.1.0 - Oct, 2016
 © pak.lebah
 */

import Foundation

/* --- INTERNAL --- */

var webInput    = ""
var webQuery    = [String]()
var inputIndex  = 0
var leftWidth   = 0
var listOrdered = false
var start: Date? = nil

// various basic print methods
func write  (_ x: Any...) { for i in x { print(i, terminator:"") } }
func writeln(_ x: Any...) { for i in x { print(i, terminator:"") }; print("") }
func write  <T>(_ x: T) { print(x, terminator:"") }
func writeln<T>(_ x: T) { print(x) }
func writeln() { print("") }

// string extension
extension String {
  // decode http text to plain string
  func decodeHTTP() -> String {
    return self.removingPercentEncoding!.replacingOccurrences(of:"+",with:" ")
  }
  // encode plain string to html text
  func encodeHTML() -> String {
    return self.replacingOccurrences(of:"&",with:"&amp;")
               .replacingOccurrences(of:"<",with:"&lt;")
               .replacingOccurrences(of:">",with:"&gt;")
  }
}

// remove empty elements from an array of string
func removeEmptyString(from array: inout [String]) {
  if array.count > 0 {
    for (i, element) in array.enumerated().reversed() {
      if element.isEmpty { array.remove(at: i) }
    }
  }
}

/*** web input/output operation ***/

// read all web request values
func readInput() -> String {
  // read from get and post methods
  var g, p: String
  if let s = String(utf8String: getenv("QUERY_STRING")) { g = s } else { g = "" }
  if let s = readLine() { p = s } else { p = "" }
  return g == "" ? p : (g + (p == "" ? "" : "&" + p)) // combine all
}

// check for input existence by index
func hasInput(at index: Int) -> Bool {
  for item in webQuery {
    if item.hasPrefix("input_\(index)=") { return true }
  }
  return false
}

// read web input value by index
func getInput(at index: Int) -> String {
  for item in webQuery {
    if item.hasPrefix("input_\(index)=") {
      return item.components(separatedBy: "=")[1].decodeHTTP()
    }
  }
  return ""
}

// write hidden var input element
func writeVarInput<T>(name: String, value: T) {
  writeln("<input type='hidden' name='\(name)' value='\(value)'/>")
  // don't forget to increase input counter each time it writes an input element
  inputIndex += 1
}

// write checkbox input element
func writeBoolInput(_ value: Bool, label: String, newLine: Bool) {
  write("<label><input type='checkbox' ")
  write("id='input_\(inputIndex)' name='input_\(inputIndex)' value='true'")
  write(value ? " checked> " : "/> ")
  write(label,"</label>")
  write(newLine ? "<br>\n" : "\n")
  inputIndex += 1
}

// write text input element
func writeTextInput<T>(_ value: T, newLine: Bool, asHolder: Bool) {
  write("<input type='text' id='input_\(inputIndex)' name='input_\(inputIndex)' ")
  write(asHolder ? "value='' placeholder='\(value)'/>" : "value='\(value)'/>")
  write(newLine ? "<br>\n" : "\n")
  inputIndex += 1
}

// write text memo input element
func writeMemoInput(_ value: String, newLine: Bool) {
  write("<textarea id='input_\(inputIndex)' name='input_\(inputIndex)'>\n")
  write(value,"</textarea>\n")
  write(newLine ? "<br>\n" : "\n")
  inputIndex += 1
}

// write radio button input element
func writeOptionInput(_ value: Int, labels: [String], newLine: Bool) {
  for (i, label) in labels.enumerated() {
    if newLine && i > 0 {
      if leftWidth > 0 {
        write("<span class='input' style='width:\(leftWidth)px'> </span>")
      } else {
        write("<span class='input'> </span>") // left alignment from css
      }
    }
    write("<label><input type='radio' id='input_\(inputIndex)' name='input_\(inputIndex)' ")
    write("value='option_\(i)'")
    write(i == value ? " checked/> " : "/> ")
    write(label,"</label>")
    write(newLine ? "<br>\n" : (i < labels.count-1 ? " │ \n" : "\n"))
  }
  inputIndex += 1
}

// write combo box input element
func writeSelectInput(_ value: Int, items: [String], newLine: Bool) {
  write("<select id='input_\(inputIndex)' name='input_\(inputIndex)'>\n")
  if value < 0 { write("<option></option>\n") } // enable no selection
  for (i, item) in items.enumerated() {
    write("<option value='item_\(i)'")
    write(i == value ? " selected> " : "> ")
    write(item,"</option>\n")
  }
  write("</select>")
  write(newLine ? "<br>\n" : "\n")
  inputIndex += 1
}

// write button input element
func writeButtonInput(caption: String, newLine: Bool ) {
  write("<button type='submit' id='input_\(inputIndex)' name='input_\(inputIndex)' ")
  write("value='clicked'>\(caption)</button>")
  write(newLine ? "<br>\n" : "\n")
  inputIndex += 1
}

// write default html header
func writeHeader(_ appName: String, cssFile: [String], jsFile: [String]) {
  writeln("cache-control: no-cache, no-store, must-revalidate");
  writeln("pragma: no-cache");
  writeln("vary:*");
  writeln("content-type: text/html;")
  writeln()
  writeln("<!DOCTYPE html>")
  writeln("<html lang='en'>")
  writeln("  <head>")
  writeln("    <meta charset='utf-8'>")
  writeln("    <meta name='viewport' content='width=device-width,initial-scale=1'>")
  writeln("    <style>span.input { display:inline-block; vertical-align:top; }</style>")
  for css in cssFile { writeln("    <link rel='stylesheet' href='\(css)'>")}
  for js  in jsFile  { writeln("    <script type='text/javascript' src='\(js)'></script>")}
  writeln("    <title>\(appName) - SimpleWeb</title>")
  writeln("  </head>")
  writeln("  <body>")
}

// write default html footer
func writeFooter(cssFile: [String], jsFile: [String]) {
  for css in cssFile { writeln("  <link rel='stylesheet' href='\(css)'>")}
  for js  in jsFile  { writeln("  <script type='text/javascript' src='\(js)'></script>")}
  writeln("  </body>")
  write  ("</html>")
}

/* --- PUBLIC --- */

public enum HTTPMethod { case GET, HEAD, POST, PUT, DELETE }
public private(set) var webHasInput = false // read only var

/* basic web template */

// open html doc
public func openHTML(title: String = "", method: HTTPMethod = .POST, cssFile: [String] = [], jsFile: [String] = []) {
  // start timer
  start = Date()
  // read local CGI executable URL
  let exeURL  = URL(fileURLWithPath: CommandLine.arguments[0])
  // let exeFull = exeURL.absoluteString
  // let exePath = exeURL.deletingLastPathComponent().path
  let exeName = exeURL.deletingPathExtension().lastPathComponent
  let exeExt  = exeURL.pathExtension
  // read web input and save them into an array
  webInput = readInput()
  webHasInput = !webInput.isEmpty
  if webHasInput { 
    // save web input as array
    webQuery = webInput.components(separatedBy: "&")
    removeEmptyString(from: &webQuery)
  }
  // check for default css/js file
  var cssFiles = cssFile
  var jsFiles = jsFile
  if FileManager.default.fileExists(atPath: "\(exeName).css") { cssFiles += ["\(exeName).css"] }
  if FileManager.default.fileExists(atPath: "\(exeName).js") { jsFiles += ["\(exeName).js"] }
  // write web header and create form
  writeHeader((title.isEmpty ? exeName : title), cssFile: cssFiles, jsFile: jsFiles)
  writeln("  <form method='\(method == .POST ? "post" : "get")' action='\(exeName).\(exeExt)'>")
  writeln("  <!-- ***** user code begin here ***** --!>")
}

// close hmtl doc
public func closeHTML(cssFile: [String] = [], jsFile: [String] = []) {
  writeln("  <!-- ***** user code end here ***** --!>")
  writeln("  <hr>")
  // close form and write web footer
  if inputIndex > 0 { writeln("  <input type='submit' value=' SUBMIT '/>") }
  writeln("  </form>")
  // stop timer
  let stop = String(format: "%.1f", abs(start!.timeIntervalSinceNow)*100) // in ms
  writeln("  <p align='right'><small><i>This page is served in \(stop) ms.</i></small>")
  writeFooter(cssFile: cssFile, jsFile: jsFile) 
}

/* common value read/write operation */

// check for a web var using its name
public func webHasVar(_ name: String) -> Bool {
  for item in webQuery {
    if item.hasPrefix("\(name)=") { return true }
  }
  return false
}

// write value into a web variable
public func writeWebVar<T>(_ name: String, value: T) {
  writeVarInput(name: name, value: value)
}

// read value from a web variable
public func readWebVar(_ name: String) -> String {
  for item in webQuery {
    if item.hasPrefix("\(name)=") {
      return item.components(separatedBy: "=")[1].decodeHTTP()
    }
  }
  return ""
}

// write output without new line into html doc
public func webWrite<T>(_ value: T, width: Int = leftWidth) {
  if width == 0 { write(value) }
    else if width < 0 { write("<span class='input'>\(value)</span>"); }
    else { write("<span class='input' style='width:\(width)px'>\(value)</span>"); }
  leftWidth = width
}

// write output with new line into html doc and reset left alignment
public func webWriteln<T>(_ value: T) { writeln(value,"<br>"); leftWidth = 0 }
public func webWriteln() { writeln("<br>"); leftWidth = 0 }

// read boolean value from web input
public func webRead(_ value: Bool = false, label: String, newLine: Bool = false) -> Bool {
  let webValue = webHasInput ? (getInput(at: inputIndex) == "true") : value
  if webHasInput {
    writeBoolInput(webValue, label: label, newLine: newLine)
    return webValue
  } else {
    writeBoolInput(value, label: label, newLine: newLine)
    return value
  }
}

public func webReadln(_ value: Bool = false, label: String) -> Bool {
  return webRead(value, label: label, newLine: true)
}

// read string value from web input
public func webRead(_ value: String = "", newLine: Bool = false) -> String {
  let webValue = webHasInput ? getInput(at: inputIndex) : value
  if webHasInput { 
    writeTextInput(webValue, newLine: newLine, asHolder: false)
    return webValue
  } else {
    writeTextInput(value, newLine: newLine, asHolder: false)
    return value
  }
}

public func webReadln(_ value: String = "") -> String {
  return webRead(value, newLine: true)
}

// read integer value from web input
public func webRead(_ value: Int = 0, newLine: Bool = false) -> Int {
  let webValue = getInput(at: inputIndex)
  if webHasInput {
    if webValue.isEmpty {
      writeTextInput(value, newLine: newLine, asHolder: true)
    } else {
      if let int = Int(webValue) {
        writeTextInput(webValue, newLine: newLine, asHolder: false)
        return int
      } else {
        writeTextInput("<invalid input>", newLine: newLine, asHolder: true)
      }
    }
  } else {
    writeTextInput(value == 0 ? "" : String(value), newLine: newLine, asHolder: false)
  }
  return value
}

public func webReadln(_ value: Int = 0) -> Int { 
  return webRead(value, newLine: true) 
}

// read floating point value from web input
public func webRead(_ value: Double = 0.0, newLine: Bool = false) -> Double {
  let webValue = getInput(at: inputIndex)
  if webHasInput {
    if webValue.isEmpty {
      writeTextInput(value, newLine: newLine, asHolder: true)
    } else {
      if let float = Double(webValue) {
        writeTextInput(webValue, newLine: newLine, asHolder: false)
        return float
      } else {
        writeTextInput("<invalid input>", newLine: newLine, asHolder: true)
      }
    }
  } else {
    writeTextInput(value == 0.0 ? "" : String(value), newLine: newLine, asHolder: false)
  }
  return value
}

public func webReadln(_ value: Double = 0.0) -> Double {
  return webRead(value, newLine: true)
}

// read long text from web input
public func webReadMemo(_ value: String = "", newLine: Bool = true) -> String {
  let webValue = getInput(at: inputIndex)
  if webHasInput {
    writeMemoInput(webValue, newLine: newLine)
    return webValue
  } else {
    writeMemoInput(value, newLine: newLine)
    return value
  }
}

// read options from web input
public func webReadOption(_ value: Int = -1, labels: [String], newLine: Bool = true) -> Int {
  let webValue = getInput(at: inputIndex)
  if webHasInput {
    var option = -1 // non chosen
    if !webValue.isEmpty {
      // read picked option
      if let r = webValue.range(of: "_") {
        let s = webValue[webValue.index(r.lowerBound, offsetBy:1) ..< webValue.endIndex]
        if let n = Int(s) { option = n }
      }
    }
    writeOptionInput(option, labels: labels, newLine: newLine)
    return option
  } else {
    writeOptionInput(value, labels: labels, newLine: newLine)
    return value
  }
}

// read selection from web input
public func webReadSelect(_ value: Int = -1, items: [String], newLine: Bool = true) -> Int {
  let webValue = getInput(at: inputIndex)
  if webHasInput {
    var selected = -1 // non selected
    if !webValue.isEmpty {
      // read selected item
      if let r = webValue.range(of: "_") {
        let s = webValue[webValue.index(r.lowerBound, offsetBy:1) ..< webValue.endIndex]
        if let n = Int(s) { selected = n }
      }
    }
    writeSelectInput(selected, items: items, newLine: newLine)
    return selected
  } else {
    writeSelectInput(value, items: items, newLine: newLine)
    return value
  }
}

// read button clicked state
public func webReadButton(_ caption: String, newLine: Bool = true) -> Bool {
  let clicked = (getInput(at: inputIndex) == "clicked")
  writeButtonInput(caption: caption, newLine: newLine)
  return clicked
}

/* common html output tags */

// write web page header
public func webPageHeader(_ text: String, level: Int = 3) {
  writeln("<h\(level)>\(text)</h\(level)>")
}

// write blockquoted text
public func webWriteBlock(_ text: String) {
  writeln("<blockquote>\(text)</blockquote>")
}

// get link text
public func webGetLink(_ url: String, caption: String = "", newTab: Bool = false) -> String {
  var result = "<a href='\(url)'"
  if newTab { result += " target=_blank>"} else { result += ">"}
  if !caption.isEmpty { result += caption } else { result += url }
  result += "</a>"
  return result
}

/* html table operation */

// open a html table tag with header
public func webOpenTable(_ headers: [String], tClass: String = "", tID: String = "") {
  write("<table")
  if !tClass.isEmpty { write(" class='\(tClass)'") }
  if !tID.isEmpty { write(" id='\(tID)'") }
  writeln(">")
  if headers.count > 0 {
    write("<tr>")
    for header in headers { write("<th>\(header)</th>") }
    writeln("</tr>")
  }
}

// write a table row
public func webTableRow(_ cells: [String]) {
  write("<tr>")
  if cells.count > 0 {
    for cell in cells { write("<td>\(cell)</td>") }
  }
  writeln("</tr>")
}

// close html table tag
public func webCloseTable() {
  writeln("</table>")
}

/* html list operation */

// open html list tag
public func webOpenList(ordered: Bool = true, lClass: String = "", lID: String = "" ) {
  listOrdered = ordered
  if listOrdered { write("<ol") } else { write("<ul") }
  if !lClass.isEmpty { write(" class='\(lClass)'") }
  if !lID.isEmpty { write(" id='\(lID)'")}
  writeln(">")
}

// add list item
public func webListItem(_ item: String) {
  writeln("<li>\(item)</li>")
}

// close html list tag
public func webCloseList() {
  if listOrdered { writeln("</ol>") } else { writeln("</ul>") }
}

/* other html operation */

// insert stylesheet into html
public func webWriteCSS(_ css: String) {
  writeln("\n<style>\(css)</style>")
}

// insert javascript into html
public func webWriteJS(_ js: String) {
  writeln("\n<script>\(js)</script>")
}

// check user agent to check whether user device type is mobile
public func isMobile() -> Bool {
  if let s = String(utf8String: getenv("HTTP_USER_AGENT")) {
    return s.lowercased().range(of: "mobile") != nil ? true : false
  }
  return false
}