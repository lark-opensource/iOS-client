//
//  ChatTimeProfile.swift
//  LarkChat
//
//  Created by zc09v on 2019/11/17.
//

import Foundation
import os.signpost

enum ChatTimeProfileCategory: String {
    private static let subsystem = "Chat"
    static let signPost = OSLog(subsystem: subsystem, category: ChatTimeProfileCategory.firstScreen.rawValue)
    case firstScreen

    var osLog: OSLog {
        switch self {
        case .firstScreen:
            return ChatTimeProfileCategory.signPost
        }
    }
}
