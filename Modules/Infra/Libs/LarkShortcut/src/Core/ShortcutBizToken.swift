//
//  ShortcutBizToken.swift
//  LarkShortcut
//
//  Created by kiri on 2023/12/7.
//

import Foundation

public enum ShortcutBizToken: String {
    case messenger
    case vc
    case calendar
    case openPlatform
    case ccm
    case myai

    var token: String {
        "lark.\(rawValue)"
    }
}
