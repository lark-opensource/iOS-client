//
//  ContactChatStandardizeMockSetting.swift
//  AppHost-OPPlugin-Unit-Tests
//
//  Created by ByteDance on 2023/11/20.
//

import Foundation
import OPUnitTestFoundation
import OPFoundation
@testable import LarkSetting

struct ContactChatStandardizeMockSetting {
    static let key = "contact_chat_standardize"
    
    static func enableContactChatStandardize() {
        SettingStorage.updateSettingValue(Self.enableValue, with: SettingManager.currentChatterID(), and: Self.key)
    }
    static func disableContactChatStandardize() {
        SettingStorage.updateSettingValue(Self.disableValue, with: SettingManager.currentChatterID(), and: Self.key)
    }
    
    private static let enableValue = """
    {
        "chooseContact": true,
            "enterChat": true,
            "getChatInfo": true
    }
    """
    
    private static let disableValue = """
    {
        "chooseContact": false,
            "enterChat": false,
            "getChatInfo": false
    }
    """
}
