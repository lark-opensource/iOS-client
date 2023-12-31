//
//  LKCharacterCPUtil.swift
//  EEAtomic
//
//  Created by sniperj on 2020/8/4.
//

import Foundation
import MMKV

extension Character {
    func isValid() -> Bool {
        return isChinese() || isLetter()
    }

    func isChinese() -> Bool {
        return "\u{4E00}" <= self && self <= "\u{9FEF}"
    }

    func isLetter() -> Bool {
        return self >= "A" && self <= "z"
    }
}

/// crash protect util by character
public struct LKCharacterCPUtil {
    static let util = LKCPProxy.sharedInterface.registCPUtil(by: "Character")
    /// Determine whether the string is safe
    /// For external use
    /// - Parameter key: key
    public static func isUnSafeKey(character: Character) -> Bool {
        return util.isUnSafeKey(key: String(character))
    }

    /// Mark this string when rendering starts
    /// For external use
    /// - Parameter key: key
    public static func increaseCrashCountWithKey(character: Character) {
        if character.isValid() {
            return
        }
        util.increaseCrashCountWithKey(key: String(character))
    }

    /// Mark this string when rendering end
    /// For external use
    /// - Parameter key: key
    public static func decreaseCrashCountWithKey(character: Character) {
        if character.isValid() {
            return
        }
        util.decreaseCrashCountWithKey(key: String(character))
    }
}
