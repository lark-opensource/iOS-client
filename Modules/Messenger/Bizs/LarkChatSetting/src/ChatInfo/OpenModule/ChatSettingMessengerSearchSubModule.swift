//
//  ChatSettingSearchSubModule.swift
//  LarkChatSetting
//
//  Created by JackZhao on 2021/8/30.
//

import Foundation
import LarkModel
import LarkOpenChat

// 搜索模块Module，通过chatSetting open能力注入
final class ChatSettingMessengerSearchSubModule: ChatSettingSubModule {
    override class func canInitialize(context: ChatSettingContext) -> Bool {
        return true
    }

    override func canHandle(model: ChatSettingMetaModel) -> Bool {
        return true
    }

    override var searchItemFactoryTypes: [ChatSettingSerachDetailItemsFactory.Type]? {
        [MessengerChatSettingSerachDetailItemsFactory.self]
    }
}
