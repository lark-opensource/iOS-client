//
//  EmotionAssembly.swift
//  LarkEmotion
//
//  Created by 李勇 on 2021/3/3.
//

import Foundation
import Swinject
import LarkAccountInterface
import LarkRustClient
import BootManager
import LarkAssembler
import LarkSetting
import LarkContainer

enum EmotionSetting {
    private static var userScopeFG: Bool {
        let v = FeatureGatingManager.shared.featureGatingValue(with: "ios.container.scope.user.emotion") //Global
        return v
    }
    // 是否开启兼容
    public static var userScopeCompatibleMode: Bool { !userScopeFG }
    // 替换.user, FG控制是否开启兼容模式。兼容模式和.user一致
    public static let userScope = UserLifeScope { userScopeCompatibleMode }
    // 替换.graph, FG控制是否开启兼容模式。
    public static let userGraph = UserGraphScope { userScopeCompatibleMode }
}

/// EmotionAssembly
public final class EmotionAssembly: LarkAssemblyInterface {
    public init() {}

    // 注册启动任务
    public func registLaunch(container: Container) {
        NewBootManager.register(EmotionResouceTask.self)
    }
    // 监听账号生命周期，切租户/冷启动/重新登陆会重新加载一次兜底数据
    public func registPassportDelegate(container: Container) {
        (PassportDelegateFactory {
            return EmotionLauncherDelegate()
        }, PassportDelegatePriority.low)
    }
    // 监听push，数据更新时能实时通知
    public func registRustPushHandlerInUserSpace(container: Container) {
            (Command.pushEmojis, EmotionResoucesPushHandler.init(resolver:))
    }
}
