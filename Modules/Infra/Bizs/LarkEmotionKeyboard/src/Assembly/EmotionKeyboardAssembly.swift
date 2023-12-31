//
//  EmotionKeyboardAssembly.swift
//  LarkEmotionKeyboard
//
//  Created by JackZhao on 2022/3/11.
//

import Foundation
import Swinject
import BootManager
import LarkAssembler
import LarkRustClient
import LarkSetting
import LarkContainer

enum EmotionKeyboardSetting {
    private static var userScopeFG: Bool {
        let v = FeatureGatingManager.shared.featureGatingValue(with: "ios.container.scope.user.emotion")
        return v
    }
    // 是否开启兼容
    public static var userScopeCompatibleMode: Bool { !userScopeFG }
    // 替换.user, FG控制是否开启兼容模式。兼容模式和.user一致
    public static let userScope = UserLifeScope { userScopeCompatibleMode }
    // 替换.graph, FG控制是否开启兼容模式。
    public static let userGraph = UserGraphScope { userScopeCompatibleMode }
}

/// EmotionKeyboardAssembly
public final class EmotionKeyboardAssembly: LarkAssemblyInterface {
    public init() {}

    // 注册启动任务
    public func registLaunch(container: Container) {
        NewBootManager.register(EmojiPanelResouceTask.self)
    }

    // 监听push，数据更新时能实时通知
    public func registRustPushHandlerInUserSpace(container: Container) {
        (Command.pushUserMruReactions, UserMruReactionPushHandler.init(resolver:))
        (Command.pushEmojiPanel, AllReactionPushHandler.init(resolver:))
    }
}
