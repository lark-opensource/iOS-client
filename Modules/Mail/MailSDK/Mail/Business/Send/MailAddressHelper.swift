//
//  MailAddressHelper.swift
//  MailSDK
//
//  Created by tefeng liu on 2020/1/8.
//

import Foundation

class MailAddressHelper {
    static let separatorStrs = ",;՝،፣᠂᠈⹁、，؛፤；､၊"

    struct AddressItem {
        let address: String
        let name: String

        func isValid() -> Bool {
            let test = address
            let regex = "^\\w+([-.]\\w+)*@\\w+([-.]\\w+)*\\.\\w{2,6}$"
            do {
                let RE = try NSRegularExpression(pattern: regex, options: .caseInsensitive)
                let matchs = RE.matches(in: test, options: .reportProgress, range: NSRange(location: 0, length: test.count))
                return matchs.count > 0
            } catch {
                return false
            }
        }
    }
}

extension MailAddressHelper {
    static func createAddressesIfAvailable(str temp: String) -> [MailAddressHelper.AddressItem] {
        var res: [MailAddressHelper.AddressItem] = []
        var f = ""
        var str = replaceSpace(temp)
        var pos = 0
        while pos < str.count {
            let character = getCharacter(str: str, pos: pos)
            if isSeparator(character) || character == " " && createAddressItems(str: f).isValid() {
                if !xo(f) {
                    res.append(createAddressItems(str: f))
                }
                f = ""
                pos = pos + 1
            } else {
                f = f + character
                if character.count <= 0 {
                    pos = pos + 1
                } else {
                    pos = pos + character.count
                }
            }
        }
        if !xo(f) {
            res.append(createAddressItems(str: f))
        }
        return res
    }
}

// MARK: helper
extension MailAddressHelper {

    static private func createAddressItems(str: String) -> AddressItem {
        let hbb = "\\\""
        let jbb = "\\\\"
        var d = ""
        var e = ""
        var f = 0
        while f < str.count {
            var g = getCharacter(str: str, pos: f)
            if let temp = g.firstIndex(of: ">"), "<" == g.charAt(0) {
                let begin = g.safeIndex(g.startIndex, offsetBy: 1)
                e = g.substring(with: begin..<temp)
            } else {
                if "" == e {
                    d = d + g
                }
            }
            f += g.count > 0 ? g.count : 1
        }
        if "" == e && d.firstIndex(of: "@") != nil {
            e = d
            d = ""
        }
        d = replaceSpace(d)
        d = !d.isEmpty ? fFa(b: d, c: "'") : d
        d = !d.isEmpty ? fFa(b: d, c: "\"") : d
        d = replace(validateString: d, regex: hbb, content: "\"")
        d = replace(validateString: d, regex: jbb, content: "\\")
        e = replaceSpace(e)
        return AddressItem(address: e, name: d)
    }

    static private func isSeparator(_ str: String) -> Bool {
        return separatorStrs.contains(str)
    }

    static private func replaceSpace(_ str: String) -> String {
        let regex1 = "[\\s\\xa0]+"
        var res = replace(validateString: str, regex: regex1, content: " ")
        let regex2 = "^\\s+|\\s+$"
        res = replace(validateString: res, regex: regex2, content: "")
        return res
    }

    static private func replace(validateString: String, regex: String, content: String) -> String {
        do {
            let RE = try NSRegularExpression(pattern: regex, options: .caseInsensitive)
            let modified = RE.stringByReplacingMatches(in: validateString, options: .reportProgress, range: NSRange(location: 0, length: validateString.count), withTemplate: content)
            return modified
        } catch {
            return validateString
        }
    }

    static private func getCharacter(str: String, pos: Int) -> String {
        let index = str.safeIndex(str.startIndex, offsetBy: pos)
        let character = str.charAt(pos)
        if let startIndex = "\"<([".firstIndex(of: character) {
            if qbb(str: str, pos: startIndex) {
                return String(character)
            }
            let endChar = "\">)]"[startIndex]
            var i = 1
            let posIndex = str.safeIndex(str.startIndex, offsetBy: pos)
            let from = str.safeIndex(str.startIndex, offsetBy: pos + i)
            if let index = str.indexOf(searchValue: endChar, fromIndex: from) {
                var temp = index
                while str.startIndex <= temp && qbb(str: str, pos: temp) {
                    i = i + 1
                    temp = str.safeIndex(temp, offsetBy: 1)
                    if let next = str.indexOf(searchValue: endChar, fromIndex: temp) {
                        temp = next
                    } else {
                        break
                    }
                }
                return 0 <= pos + i ? str.substring(with: posIndex..<temp) : String(character)
            } else {
                return String(character)
            }
        } else {
            return String(character)
        }
    }

    static private func fFa(b: String, c: String) -> String {
        let d = c.count
        var e = 0
        while e < d {
            let f = 1 == d ? c : String(c.charAt(e))
            if String(b.charAt(0)) == f && String(b.charAt(b.count - 1)) == f {
                let begin = b.safeIndex(b.startIndex, offsetBy: 1)
                let end = b.safeIndex(b.startIndex, offsetBy: b.count - 1)
                return b.substring(with: begin..<end)
            }
            e = e + 1
        }
        return b
    }

    static private func qbb(str: String, pos from: String.Index) -> Bool {
        let pos = from < str.endIndex ? from : str.index(before: str.endIndex)
        if str[pos] != "\"" {
            return false
        }
        var d = 0
        var temp = pos
        if pos != str.startIndex {
            temp = str.safeIndex(pos, offsetBy: -1)
        } else {
            return 0 != d % 2
        }
        while str.startIndex <= temp && "\\" == str[temp] {
            d = d + 1
            if temp == str.startIndex {
                break
            }
            temp = str.safeIndex(temp, offsetBy: -1)
        }
        return 0 != d % 2
    }

    static private func xo(_ b: String) -> Bool {
        let test = b
        let regex = "^[\\s\\xa0]*$"
        do {
            let RE = try NSRegularExpression(pattern: regex, options: .caseInsensitive)
            let matchs = RE.matches(in: test, options: .reportProgress, range: NSRange(location: 0, length: test.count))
            return matchs.count > 0
        } catch {
            return false
        }
    }
}

// MARK: Other extension
extension String {
    fileprivate func charAt(_ pos: Int) -> Character {
        let index = self.safeIndex(self.startIndex, offsetBy: pos)
        let character = self[index]
        return character
    }

    fileprivate func indexOf(searchValue: Character, fromIndex: String.Index) -> String.Index? {
        guard fromIndex < self.endIndex else {
            return nil
        }
        var temp = self[fromIndex]
        var index: String.Index? = fromIndex
        while index != nil && temp != searchValue && index! < self.endIndex && index! >= self.startIndex {
            temp = self[index!]
            index = self.index(after: index!)
        }
        if temp == searchValue {
            return index
        } else {
            return nil
        }
    }

    fileprivate func safeIndex(_ i: String.Index, offsetBy n: String.IndexDistance) -> String.Index {
        var offset = n
        var tempIndex = i
        if tempIndex >= self.endIndex {
            return self.index(before: self.endIndex)
        } else if tempIndex < self.startIndex {
            return self.startIndex
        }
        if offset > 0 {
            while offset != 0 {
                if tempIndex >= self.endIndex {
                    return self.index(before: self.endIndex)
                }
                tempIndex = self.index(after: tempIndex)
                offset = offset - 1
            }
        } else if offset < 0 {
            while offset != 0 {
                if tempIndex <= self.startIndex {
                    return self.startIndex
                }
                tempIndex = self.index(before: tempIndex)
                offset = offset + 1
            }
        }
        if tempIndex >= self.endIndex {
            return self.index(before: self.endIndex)
        } else if tempIndex < self.startIndex {
            return self.startIndex
        }
        return tempIndex
    }
}
