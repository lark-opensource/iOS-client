//
//  ChatSettingToken.swift
//  LarkChatSetting
//
//  Created by Yaoguoguo on 2023/10/25.
//

import Foundation
import LarkSensitivityControl

enum ChatSettingToken: String {
    case savePhoto

    var token: Token {
        switch self {
        case .savePhoto:
            return Token("LARK-PSDA-ChatSetting_savephoto")
        }
    }
}
