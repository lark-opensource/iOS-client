//
//  MailTracker+Setting.swift
//  MailSDK
//
//  Created by li jiayi on 2021/10/19.
//

import Foundation

extension MailTracker {
    enum MailSettingType: String {
        case mailSettingClick = "email_lark_setting_click"
    }
    class func getMailSettingConversationClickParamKey() -> String {
        return "click"
    }
    class func getMailSettingConversationClickParamValue() -> String {
        return "conversation_switch"
    }
    class func getMailSettingConversationStatusParamKey() -> String {
        return "status"
    }
    class func getMailSettingConversationStatusParmaValue(isConversation: Bool) -> String {
        return isConversation ? "conversational" : "traditional"
    }
}
