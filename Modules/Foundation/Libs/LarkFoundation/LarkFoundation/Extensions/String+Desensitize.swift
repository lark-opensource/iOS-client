//
//  String+Desensitize.swift
//  LarkFoundation
//
//  Created by Hayden on 18/10/2023.
//

import Foundation

public extension String {

    /// 字符串简单的脱敏处理，保留头部、尾部若干字符，中间用 * 代替
    /// - Parameters:
    ///   - headLength: 头部保留的字符数，默认为 0
    ///   - tailLength: 尾部保留的字符数，默认为 0
    /// - Returns: 脱敏后的字符串，e.g. `"Hel**(5)**rld"`
    func desensitized(keepingHead headLength: Int = 0, tail tailLength: Int = 0) -> Self {
        let stringLength = self.count
        if self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "****(E)****"
        }
        if headLength == 0, tailLength == 0 {
            return "****(\(stringLength))****"
        }
        if headLength + tailLength >= stringLength {
            return self
        }
        var desensitizedString = self
        let startIndex = desensitizedString.index(desensitizedString.startIndex, offsetBy: headLength)
        let endIndex = desensitizedString.index(desensitizedString.endIndex, offsetBy: -tailLength)
        desensitizedString.replaceSubrange(startIndex..<endIndex, with: "**(\(stringLength - headLength - tailLength))**")
        return desensitizedString
    }
}
