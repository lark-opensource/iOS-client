//
//  MessageCardMigrateControl.swift
//  LarkOpenPlatform
//
//  Created by ByteDance on 2023/10/24.
//

import Foundation
import LarkContainer
import LarkSetting
import LKCommonsLogging

public final class MessageCardMigrateControl {
    private static let logger = Logger.log(MessageCardMigrateControl.self, category: "MessageCardMigrateControl")
    // 过渡开关, 用于部分(目前仅 MessageCardPinAlertContentView)改造层级较深无法拿到 userResolver 的场景
    private(set) static var useUniversalCard: Bool = false
    public let useUniversalCard: Bool
    public init(resolver: UserResolver) {
        useUniversalCard = resolver.fg.staticFeatureGatingValue(with: "messagecard.use.universalcard.enable")
        Self.useUniversalCard = useUniversalCard
    }
}
