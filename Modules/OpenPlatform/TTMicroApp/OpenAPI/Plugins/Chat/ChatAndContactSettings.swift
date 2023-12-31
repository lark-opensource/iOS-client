//
//  ChatAndContactSettings.swift
//  TTMicroApp
//
//  Created by 刘焱龙 on 2022/12/14.
//

import Foundation
import LarkSetting

private struct ChatAndContactStandardizeSetting: SettingDecodable {
    static var settingKey  = UserSettingKey.make(userKeyLiteral: "contact_chat_standardize")
    let chooseContact: Bool
    let enterChat: Bool
    let getChatInfo: Bool
}

@objcMembers public final class ChatAndContactSettings: NSObject {
    private static var setting: ChatAndContactStandardizeSetting = {
        (try? SettingManager.shared.setting(with: ChatAndContactStandardizeSetting.self))
        ?? ChatAndContactStandardizeSetting(chooseContact: false, enterChat: false, getChatInfo: false)
    }()

    @objc
    public static var isChooseContactStandardizeEnabled: Bool {
        return setting.chooseContact
    }

    @objc
    public static var isEnterChatStandardizeEnabled: Bool {
        return setting.enterChat
    }

    @objc
    public static var isGetChatInfoStandardizeEnabled: Bool {
        return setting.getChatInfo
    }
}
