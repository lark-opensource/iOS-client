//
//  Character+Extension.swift
//  LarkChatSetting
//
//  Created by 李勇 on 2020/4/30.
//

import Foundation

extension Character {
    /// 是否为Emoji表情 https://stackoverflow.com/questions/30757193/find-out-if-character-in-string-is-emoji
    /// 所有Emoji表情 https://unicode.org/Public/emoji/13.0/
    func isEmoji() -> Bool {
        guard let scalar = unicodeScalars.first else { return false }
        return scalar.properties.isEmoji && (scalar.value > 0x238C || unicodeScalars.count > 1)
    }

    /// 是否为图片（飞书表情）
    func isReaction() -> Bool {
        return self == "\u{FFFC}"
    }

    /// 是否为中文
    func isChinese() -> Bool {
        return "\u{4E00}" <= self && self <= "\u{9FA5}"
    }

    /// 是否为日文
    func isJapanese() -> Bool {
        return ("\u{3040}" <= self && self <= "\u{309F}") || ("\u{30A0}" <= self && self <= "\u{30FF}")
    }

    /// 是大些或者宽的英文字母
    func isWideEnglish() -> Bool {
        let wideCharater: [Character] = ["m", "w"]
        return ("A" <= self && self <= "Z") || wideCharater.contains(self)
    }

    /// 是否为中文标点符号 + 宽大的特殊字符
    /// https://gist.github.com/shingchi/64c04e0dd2cbbfbc1350
    fileprivate func isWildPunctuation() -> Bool {
        let wildPunctuation: [Character] = ["\u{FF1A}", "\u{FF1B}", "\u{FF20}"]
        return ("\u{FF01}" <= self && self <= "\u{FF0D}") || ("\u{3001}" <= self && self <= "\u{303F}") || wildPunctuation.contains(self)
    }

    func isWideCharacter() -> Bool {
        return self.isEmoji() || self.isChinese() || self.isJapanese() || self.isWideEnglish() || self.isReaction() || self.isWildPunctuation()
    }
}
