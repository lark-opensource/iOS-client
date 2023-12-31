//
//  SendMessagecardChooseChatParams.swift
//  EEMicroAppSDK
//
//  Created by 新竹路车神 on 2021/1/6.
//

import Foundation

//发送消息卡片，需要选人时的定制参数
@objc
public final class SendMessagecardChooseChatParams: NSObject {
    public let allowCreateGroup: Bool
    public let multiSelect: Bool
    public let confirmTitle: String
    public let externalChat: Bool
    public let selectType: Int
    public let ignoreSelf: Bool
    public let ignoreBot: Bool
    
    @objc
    public init(
        allowCreateGroup: Bool,
        multiSelect: Bool,
        confirmTitle: String,
        externalChat: Bool,
        selectType: Int,
        ignoreSelf: Bool,
        ignoreBot: Bool
    ) {
        self.allowCreateGroup = allowCreateGroup
        self.multiSelect = multiSelect
        self.confirmTitle = confirmTitle
        self.externalChat = externalChat
        self.selectType = selectType
        self.ignoreSelf = ignoreSelf
        self.ignoreBot = ignoreBot
        super.init()
    }
}
