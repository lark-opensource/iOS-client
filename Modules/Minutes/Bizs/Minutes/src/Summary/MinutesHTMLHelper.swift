//
//  MinutesHTMLHelper.swift
//  Minutes
//
//  Created by Todd Cheng on 2021/5/20.
//

import Foundation

struct MinutesHTMLHelper {
    public static func getResultsFromHTMLString(_ htmlString: String) -> String {
        if htmlString.isEmpty { return "" }

        let prefixPattern: String = "<[a-zA-Z]+.*?>"
        let suffixPattern: String = "</[a-zA-Z]*?>"
        guard let prefixRegex = try? NSRegularExpression(pattern: prefixPattern) else { return htmlString }
        guard let suffixRegex = try? NSRegularExpression(pattern: suffixPattern) else { return htmlString }

        var returnValue = htmlString

        while MinutesHTMLHelper.isMatchHTMLStyle(returnValue) {
            let prefixRange = NSRange(location: 0, length: returnValue.count)
            if let someMatch = prefixRegex.firstMatch(in: returnValue, options: [], range: prefixRange) {
                returnValue = (returnValue as NSString).replacingCharacters(in: someMatch.range, with: "")
            }
            let suffixRange = NSRange(location: 0, length: returnValue.count)
            if let someMatch = suffixRegex.firstMatch(in: returnValue, options: [], range: suffixRange) {
                returnValue = (returnValue as NSString).replacingCharacters(in: someMatch.range, with: "")
            }
        }

        return returnValue
    }

    public static func isMatchHTMLStyle(_ htmlString: String) -> Bool {
        if htmlString.isEmpty { return false }

        let pattern: String = "<[a-zA-Z]+.*?>([\\s\\S]*?)</[a-zA-Z]*?>"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return false }
        let range = NSRange(location: 0, length: htmlString.count)
        return regex.firstMatch(in: htmlString, options: [], range: range) != nil
    }

    public typealias UserNameIdTuple = (name: String, userId: String)
    static func getUsersFrom(htmlString: String) -> [UserNameIdTuple] {
        if htmlString.isEmpty { return [] }

        var id: String = ""
        var name: String = ""
        var isInruleRange: Bool = false

        var returnValue: [UserNameIdTuple] = []
        let compomentList = htmlString.components(separatedBy: ["<", "\"", "=", ">"])
        for i in 0..<compomentList.count {
            if compomentList[i].contains("at type") {
                isInruleRange = true
            }

            if isInruleRange {
                if compomentList[i].contains("token") || compomentList[i].contains("id") {
                    let curID = compomentList[i + 2]
                    id = MinutesHTMLHelper.idCleanAndCheck(usrID: curID)
                } else if compomentList[i].contains("@") {
                    name = compomentList[i]
                } else if compomentList[i].contains("/at") {
                    returnValue.append((name, id))
                    id = ""
                    name = ""
                    isInruleRange = false
                }
            }
        }

        return returnValue
    }

    private static func idCleanAndCheck(usrID: String) -> String {
        var id: String = ""
        for i in usrID {
            if i < "0" || i > "9" {
                continue
            }
            id.append(i)
        }
        return id
    }
}
