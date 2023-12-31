//
//  LarkPushCardAssembly.swift
//  LarkPushCard
//
//  Created by 白镜吾 on 2023/11/7.
//

import Foundation
import BootManager
import Swinject
import LarkAssembler
import LarkAccountInterface

public final class LarkPushCardAssembly: LarkAssemblyInterface {

    public init() {}

    public func registPassportDelegate(container: Container) {
        (PassportDelegateFactory(delegateProvider: {
            RegisterPushCardDelegate(resolver: container)
        }), PassportDelegatePriority.high)
    }
}

/// 切租户/冷启动/重新登陆会重新加载一次兜底数据
final class RegisterPushCardDelegate: PassportDelegate {
    var name: String = "PushCardLaunchDelegate"

    private let resolver: Resolver

    public init(resolver: Resolver) {
        self.resolver = resolver
    }

    /// 切租户，清除上个租户的卡片数据
    func userDidOffline(state: PassportState) {
        guard state.loginState == .offline,
            state.user?.userID != nil else { return } // 避免fastLogin走到这里
        PushCardManager.shared.removeAll()
    }
}
