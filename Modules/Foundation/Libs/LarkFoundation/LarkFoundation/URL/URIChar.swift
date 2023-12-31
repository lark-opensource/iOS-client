//
//  URIChar.swift
//  LarkFoundation
//
//  Created by qihongye on 2020/1/14.
//

import Foundation

typealias URIChar = String.UTF8View.Element
typealias URICharPtr = [URIChar]

// swiftlint:disable identifier_name
let NULL_URICharPtr: URICharPtr = []
// swiftlint:enable identifier_name

@inline(__always)
func isNullURICharPtr(_ ptr: URICharPtr) -> Bool {
    return ptr.isEmpty
}

extension Array where Element == URIChar {
    @inline(__always)
    func get(_ idx: Int) -> Element? {
        if idx < 0 || idx >= endIndex {
            return nil
        }
        return self[idx]
    }
}

struct Letter {
    /// a
    static let a: URIChar = 97
    /// f
    static let f: URIChar = 102
    /// z
    static let z: URIChar = 122
    /// A
    static let A: URIChar = 65
    /// F
    static let F: URIChar = 70
    /// Z
    static let Z: URIChar = 90
    /// 0
    static let num0: URIChar = 48
    /// 1
    static let num1: URIChar = 49
    /// 2
    static let num2: URIChar = 50
    /// 4
    static let num4: URIChar = 52
    /// 5
    static let num5: URIChar = 53
    /// 9
    static let num9: URIChar = 57
    /// +
    static let plus: URIChar = 43
    /// -
    static let minus: URIChar = 45
    /// .
    static let dot: URIChar = 46
    /// :
    static let colon: URIChar = 58
    /// /
    static let slash: URIChar = 47
    /// \
    static let backslash: URIChar = 92
    /// _
    static let underscore: URIChar = 95
    /// !
    static let exclamation: URIChar = 33
    /// ~
    static let tilde: URIChar = 126
    /// *
    static let asterisk: URIChar = 42
    /// '
    static let apostrophe: URIChar = 39
    /// (
    static let parenthesesL: URIChar = 40
    /// )
    static let parenthesesR: URIChar = 41
    /// ;
    static let semicolon: URIChar = 59
    /// ?
    static let question: URIChar = 63
    /// @
    static let at: URIChar = 64
    /// &
    static let apersand: URIChar = 38
    /// =
    static let equals: URIChar = 61
    /// $
    static let dollar: URIChar = 36
    /// [
    static let bracketsL: URIChar = 91
    ///]
    static let bracketsR: URIChar = 93
    /// {
    static let bracesL: URIChar = 123
    /// |
    static let vertical: URIChar = 124
    /// }
    static let bracesR: URIChar = 125
    /// ,
    static let comma: URIChar = 44
    /// %
    static let percent: URIChar = 37
    /// #
    static let number: URIChar = 35
    /// ^
    static let caret: URIChar = 94
    /// `
    static let backquote: URIChar = 96
    /// space
    static let space: URIChar = 32
}

// MARK: URIChar operators
func + (_ lhs: URIChar, _ rhs: String) -> URICharPtr {
    return [lhs] + rhs.utf8
}

// MARK: URICharPtr operators
func == (_ lhs: URICharPtr, _ rhs: String) -> Bool {
    if lhs.count != rhs.utf16.count {
        return false
    }
    let count = lhs.count
    for i in 0..<count where rhs.utf16[rhs.utf16.index(rhs.utf16.startIndex, offsetBy: i)] != lhs[i] {
        return false
    }
    return true
}

func + (_ lhs: URICharPtr, _ rhs: URIChar) -> URICharPtr {
    return lhs + [rhs]
}

func += (_ lhs: inout URICharPtr, _ rhs: URIChar) {
    lhs += [rhs]
}

@inline(__always)
func encodeURI(_ char: URIChar) -> URICharPtr {
    let hi = char / 0x10
    let lo = char % 0x10
    return [
        Letter.percent,
        hi + (hi > 9 ? Letter.A - 10 : Letter.num0),
        lo + (lo > 9 ? Letter.A - 10 : Letter.num0)
    ]
}

/**
 * Old rule from 2396 used in legacy handling code
 * alpha    = lowalpha | upalpha
 */
@inline(__always)
func isAlpha(_ char: URIChar) -> Bool {
    return isLowAlpha(char) || isUpAlpha(char)
}

/**
 * lowalpha = "a" | "b" | "c" | "d" | "e" | "f" | "g" | "h" | "i" | "j" |
 *            "k" | "l" | "m" | "n" | "o" | "p" | "q" | "r" | "s" | "t" |
 *            "u" | "v" | "w" | "x" | "y" | "z"
 */
@inline(__always)
func isLowAlpha(_ char: URIChar) -> Bool {
    return char >= Letter.a && char <= Letter.z
}

/**
 * upalpha = "A" | "B" | "C" | "D" | "E" | "F" | "G" | "H" | "I" | "J" |
 *           "K" | "L" | "M" | "N" | "O" | "P" | "Q" | "R" | "S" | "T" |
 *           "U" | "V" | "W" | "X" | "Y" | "Z"
 */
@inline(__always)
func isUpAlpha(_ char: URIChar) -> Bool {
    return char >= Letter.A && char <= Letter.Z
}

/**
 * digit = "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9"
 */
@inline(__always)
func isDigit(_ char: URIChar) -> Bool {
    return char >= Letter.num0 && char <= Letter.num9
}

/**
 * alphanum = alpha | digit
 */
@inline(__always)
func isAlphanum(_ char: URIChar) -> Bool {
    return isAlpha(char) || isDigit(char)
}

/**
 * mark = "-" | "_" | "." | "!" | "~" | "*" | "'" | "(" | ")"
 */
@inline(__always)
func isMark(_ char: URIChar) -> Bool {
    switch char {
    case Letter.minus, Letter.underscore, Letter.dot, Letter.exclamation, Letter.tilde,
         Letter.asterisk, Letter.apostrophe, Letter.parenthesesL, Letter.parenthesesR:
        return true
    default:
        return false
    }
}

/**
 * unreserved = alphanum | mark
 */
@inline(__always)
func isUnreserved(_ char: URIChar) -> Bool {
    return isAlphanum(char) || isMark(char)
}

/**
 * reserved = ";" | "/" | "?" | ":" | "@" | "&" | "=" | "+" | "$" | "," |
 *            "[" | "]"
 */
@inline(__always)
func isReserved(_ char: URIChar) -> Bool {
    switch char {
    case Letter.semicolon, Letter.slash, Letter.question, Letter.colon, Letter.at, Letter.apersand,
         Letter.equals, Letter.plus, Letter.dollar, Letter.comma, Letter.bracketsL, Letter.bracketsR:
        return true
    default:
        return false
    }
}

/**
 * sub-delims = "!" / "$" / "&" / "'" / "(" / ")"
 *              / "*" / "+" / "," / ";" / "="
 */
@inline(__always)
func isSubDelim(_ char: URIChar) -> Bool {
    switch char {
    case Letter.exclamation, Letter.dollar, Letter.apersand, Letter.apostrophe, Letter.parenthesesL,
         Letter.parenthesesR, Letter.asterisk, Letter.plus, Letter.comma, Letter.semicolon, Letter.equals:
        return true
    default:
        return false
    }
}

/**
 * unwise = "{" | "}" | "|" | "\" | "^" | "`" | "[" | "]"
 */
@inline(__always)
func isUnwise(_ char: URIChar?) -> Bool {
    switch char {
    case Letter.bracesL, Letter.bracesR, Letter.vertical, Letter.apostrophe, Letter.caret,
         Letter.backquote, Letter.bracketsL, Letter.bracketsR:
        return true
    default:
        return false
    }
}

/**
 * isHedDigit = isDigit / a b c d e f / A B C D E F
 */
@inline(__always)
func isHexDigit(_ char: URIChar) -> Bool {
    return isDigit(char) || (char >= Letter.a && char <= Letter.f) || (char >= Letter.A && char <= Letter.F)
}

/**
 * pct-encoded = "%" HEXDIG HEXDIG
 */
@inline(__always)
func isPCTEncoded(_ ptr: URICharPtr, _ idx: Int) -> Bool {
    if ptr.endIndex <= idx + 2 {
        return false
    }
    return ptr[idx] == Letter.percent && isHexDigit(ptr[idx + 1]) && isHexDigit(ptr[idx + 2])
}

/**
 * pchar = unreserved / pct-encoded / sub-delims / ":" / "@"
 */
@inline(__always)
func isPChar(_ ptr: URICharPtr, _ idx: Int) -> Bool {
    if ptr.endIndex <= idx {
        return false
    }
    return isUnreserved(ptr[idx]) || isPCTEncoded(ptr, idx) || isSubDelim(ptr[idx]) ||
        ptr[idx] == Letter.colon || ptr[idx] == Letter.at
}

/**
 * Skip to next pointer char.
 * return the char after skipped one.
 */
@inline(__always)
func next(_ ptr: URICharPtr, _ idx: inout Int) -> URIChar? {
    if ptr.get(idx) == Letter.percent {
        idx += 3
    } else {
        idx += 1
    }
    return ptr.get(idx)
}

/// uriUnescape
/// - Parameter ptr: URICharPtr
/// - Parameter idx: unescape start index
/// - Parameter len: unescape length
/// `Note`: Part of language (go, java) uri implaments will replace `+` to `space`,
///         so this function will deal with this case.
func uriUnescape(_ ptr: URICharPtr, _ idx: Int, _ len: Int) -> URICharPtr {
    if ptr.endIndex < idx + len || len <= 0 {
        return NULL_URICharPtr
    }
    var out = NULL_URICharPtr
    var len = len
    var curIdx = idx
    var continueUnescapeFlag: UInt8 = 0b0
    var continueUnescape = false
    var containsPCTEncode = false
    for i in idx..<idx + len where isPCTEncoded(ptr, i) {
        containsPCTEncode = true
        break
    }
    if !containsPCTEncode {
        return Array(ptr[idx..<idx + len])
    }
    while len > 0 {
        var val: UInt8 = 0
        if len > 2 && ptr[curIdx] == Letter.percent && isHexDigit(ptr[curIdx + 1]) && isHexDigit(ptr[curIdx + 2]) {
            curIdx += 1
            if ptr[curIdx] >= Letter.num0 && ptr[curIdx] <= Letter.num9 {
                val = ptr[curIdx] - Letter.num0
            } else if ptr[curIdx] >= Letter.a && ptr[curIdx] <= Letter.f {
                val = ptr[curIdx] - Letter.a + 10
            } else if ptr[curIdx] >= Letter.A && ptr[curIdx] <= Letter.F {
                val = ptr[curIdx] - Letter.A + 10
            }
            curIdx += 1
            // disable-lint: magic number
            if ptr[curIdx] >= Letter.num0 && ptr[curIdx] <= Letter.num9 {
                val = ptr[curIdx] - Letter.num0 + 16 * val
            } else if ptr[curIdx] >= Letter.a && ptr[curIdx] <= Letter.f {
                val = ptr[curIdx] - Letter.a + 10 + 16 * val
            } else if ptr[curIdx] >= Letter.A && ptr[curIdx] <= Letter.F {
                val = ptr[curIdx] - Letter.A + 10 + 16 * val
            }
            // enable-lint: magic number
            curIdx += 1
            len -= 3
            out += val
        } else {
            val = ptr[curIdx]
            out += val == Letter.plus ? Letter.space : val
            curIdx += 1
            len -= 1
        }
        if val == Letter.percent, continueUnescapeFlag == 0b0 {
            continueUnescapeFlag = 0b100
        } else if isHexDigit(val), continueUnescapeFlag == 0b100 {
            continueUnescapeFlag = 0b110
        } else if isHexDigit(val), continueUnescapeFlag == 0b110 {
            continueUnescapeFlag = 0b111
        } else {
            continueUnescapeFlag = 0b0
        }
        if continueUnescapeFlag == 0b111 {
            continueUnescape = true
        }
    }

    if continueUnescape {
        return uriUnescape(out, 0, out.count)
    }

    return out
}
