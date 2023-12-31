//
//  MessageCardIdentify.swift
//  LarkOpenPlatform
//
//  Created by ByteDance on 2023/10/24.
//

import Foundation
import LarkModel
import RustPB
import LarkMessageCard

public struct MessageCardIdentify: EquatableIdentify {

    public let contentVersion: Int32
    public let translateState: Message.TranslateState
    public let displayRule: RustPB.Basic_V1_DisplayRule
    public let translateLanguage: String
    public let preferWidth: CGFloat
    public let messageID: String

    public static func == (lhs: MessageCardIdentify, rhs: MessageCardIdentify) -> Bool {
        return (lhs.contentVersion == rhs.contentVersion) && (lhs.displayRule == rhs.displayRule) && (lhs.translateLanguage == rhs.translateLanguage ) && (lhs.preferWidth == rhs.preferWidth ) && ( lhs.messageID == rhs.messageID)
    }

    public func isEqual(identify : EquatableIdentify?) -> Bool {
        guard let identify = identify as? MessageCardIdentify else {
            return false
        }
        return self == identify
    }
    public init(message: Message ,preferWidth: CGFloat) {
        self.contentVersion = message.contentVersion
        self.translateState = message.translateState
        self.displayRule = message.displayRule
        self.translateLanguage = message.translateLanguage
        self.preferWidth = preferWidth
        self.messageID = message.id
    }
}
