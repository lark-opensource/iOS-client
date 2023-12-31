//
//  File.swift
//  MailSDK
//
//  Created by tefeng liu on 2019/6/22.
//

import Foundation

// swiftlint:disable line_length
extension String {
    func isLegalForEmail() -> Bool {
        var result = ""
        // 规则
//        let pattern1 = "^\\w+([-.]\\w+)*@\\w+([-.]\\w+)*\\.\\w{2,6}$"
        let pattern1 = "^((?!\\s)[+a-zA-Z0-9_.!#$%&'*\\/=?^`{|}~\\u0080-\\uffffFF-])+@((?!\\s)[a-zA-Z0-9\\u0080-\\u3001\\u3003-\\uff0d\\uff0f-\\uff60\\uff62-\\uffffFF-]+[\\.\\uFF0E\\u3002\\uFF61])+(?!\\s)[a-zA-Z0-9\\u0080-\\u3001\\u3003-\\uff0d\\uff0f-\\uff60\\uff62-\\uffffFF-]{2,63}$"
        let regex1 = try! NSRegularExpression(pattern: pattern1, options: NSRegularExpression.Options.caseInsensitive)
        let res = regex1.matches(in: self, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSRange(location: 0, length: self.count))
        for checkingRes in res {
            result = result + (self as NSString).substring(with: checkingRes.range)
        }
        if result != self || result.isEmpty {
            return false
        } else {
            return true
        }
    }
}
// swiftlint:enable line_length
