import Foundation

/* helper methods collection */

/**
 This ..> operator is the reverse of ..< operator.
 - parameter maximum: The left operand.
 - parameter minimum: The right operand.
 - returns: open range decremented from `maximum` to `minimum`.
 */
public func ..> <T>(maximum: T, minimum: T) -> StrideTo<T> {
  return stride(from: maximum, to: minimum, by: -1)
}
infix operator ..> : RangeFormationPrecedence

/**
 This ..= operator is similar to ... operator, except it's also able to go backward.
 - parameter left: The left operand.
 - parameter right: The right operand.
 - returns: closed range incremented from `left` to `right`, or decremented if `left` is greater than `right`.
 */
public func ..= <T>(left: T, right: T) -> StrideThrough<T> {
  if left > right {
    return stride(from: left, through: right, by: -1)
  } else {
    return stride(from: left, through: right, by: +1)
  }
}
infix operator ..= : RangeFormationPrecedence

// integer exponential function
private func exp(base b: Int, power p: Int) -> Int64 {
  if p == 0 { return 1 }
  else if p == 1 { return Int64(b) }
  else {
    var r: Int64 = 1  // = b⁰
    for _ in 1...p { r = r * Int64(b) }
    return r
  }
}

/**
 This ** operator is integer exponential operator.
 - parameter base: The base number.
 - parameter power: The power operand.
 - returns: `base` to `power`.
 */
public func ** (base: Int, power: Int) -> Int64 {
  return exp(base: base, power: power)
}
// exponentiation operator
precedencegroup ExponentiationPrecedence {
  associativity: left
  higherThan: MultiplicationPrecedence
}
infix operator ** : ExponentiationPrecedence

/**
 Boolean extension for boolean operations.
 - parameter bool: The value to operate on.
 - returns: The operation result of given parameter(s).
 */
public extension Bool {
  func and(_ bool: Bool) -> Bool { return self && bool }
  func and(_ bools: Bool..., shorted: Bool = true) -> Bool {
    var and_ = self
    for bool in bools { and_ = and_ && bool
      if shorted { if !and_ { break } }
    }
    return and_
  }
  func or(_ bool: Bool) -> Bool { return self || bool }
  func or(_ bools: Bool..., shorted: Bool = true) -> Bool {
    var or_ = self
    for bool in bools { or_ = or_ || bool
      if shorted { if or_ { break } }
    }
    return or_
  }
}

/**
 Logical 'not' operator as function.
 - parameter bool: The value to operate on.
 - returns: The negation of given parameter.
 */
public func not(_ bool: Bool) -> Bool { return !bool }

/**
 Prints to standard output **without** a trailing new line.
 - parameter x: The value to be printed out.
 */
public func write(_ x: Any...) { for i in x { print(i, terminator: "") } }
public func write<T>(_ x: T) { print(x, terminator: "") }

/**
 Prints to standard output **with** a trailing new line.
 - parameter x: The value to be printed out.
 */
public func writeln(_ x: Any...) { for i in x { print(i) } }
public func writeln<T>(_ x: T) { print(x) }

/**
 Prints a new line.
 */
public func writeln() { print("") }

/**
 Read user input **without** a trailing new line.
 - returns: user input as String.
 */
public func read() -> String { return readLine(strippingNewline: true)! }

/**
 Read user input **with** a trailing new line.
 - returns: user input as String.
 */
public func readln() -> String { return readLine()! }

/**
 Read user input **with** a label.
 - parameter txt: The input label.
 - returns: user input as String.
 */
public func ask(_ txt: String) -> String {
  write(txt)
  return readln()
}

/* datetime management */

/**
 Show formatted elapsed time since given start time.
 - parameter since: The start time.
 - returns: elapsed time as formatted string.
 */
public func elapsedTime(since: Date) -> String {
  let interval  = Date(timeIntervalSince1970: abs(since.timeIntervalSinceNow))
  let formatter = DateFormatter()
  formatter.timeZone   = TimeZone(secondsFromGMT: 0)
  formatter.dateFormat = "HH:mm:ss.SSS"
  return formatter.string(from: interval)
}

/* delimited string management */

/**
 Count number of elements inside a delimited string.
 - parameter of: The delimited string.
 - parameter separatedBy: The separator of the string.
 - returns: Number of elements in the string.
 */
func getCount(of items: String?, separatedBy separator: String = ";") -> Int {
  guard
    let txt = items, !txt.isEmpty, !separator.isEmpty
    else { return 0 }
  return txt.components(separatedBy: separator).count
}

/**
 Get an elements of a delimited string by an index
 - parameter at: Index of the element.
 - parameter separatedBy: The separator of the string.
 - returns: The element at the index.
 */
func getItem(at index: Int, from text: String?, separatedBy separator: String = ";") -> String {
  guard
    let txt = text, index >= 0, !txt.isEmpty, !separator.isEmpty
    else { return "" }
  let result = txt.components(separatedBy: separator)
  if index < result.count { return result[index] } else { return "" }
}

/**
 Search for the name part of name=value pair from a delimited string.
 - parameter name: The name of the searched pair.
 - parameter text: The delimited string.
 - returns: true if the name is found, false if otherwise.
 */
// search for name of name=value pair from a delimited string
func hasVar(name: String, in text: String?, separatedBy separator: String = "=") -> Bool {
  guard
    !name.isEmpty, let txt = text, !separator.isEmpty
    else { return false }
  return txt.range(of: (name+separator), 
                   options: NSString.CompareOptions.caseInsensitive) != nil
}