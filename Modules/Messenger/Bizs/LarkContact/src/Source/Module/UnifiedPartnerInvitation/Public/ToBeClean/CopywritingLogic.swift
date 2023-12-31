//
//  CopywritingLogic.swift
//  LarkContact
//
//  Created by shizhengyu on 2020/4/29.
//

import Foundation
import LarkLocalizations

final class CopyWritingLogic {
    // 多个contact间的分隔符，适配国际化
    static func contactSplitter() -> String {
        let lang = LanguageManager.currentLanguage
        switch lang {
        case .en_US: return ", "
        case .zh_CN, .ja_JP: return "、"
        default: return ", "
        }
    }
}
