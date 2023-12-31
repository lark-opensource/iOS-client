//
//  StrategyAssembly.swift
//  LarkMeegoStrategy
//
//  Created by shizhengyu on 2023/4/5.
//

import Foundation
import LarkAssembler
import LarkContainer
import LarkSetting

private enum Strategy {
    public static var userScopeCompatibleMode: Bool {
        return !FeatureGatingManager.shared.featureGatingValue(with: "ios.container.scope.user.meego")
    }
    // 用于替换 .user, FG 控制是否开启兼容模式。兼容模式下和 .user 表现一致
    public static let userScope = UserLifeScope { userScopeCompatibleMode }
}

public class StrategyAssembly: LarkAssemblyInterface {
    public init() {}

    public func registContainer(container: Container) {
        let user = container.inObjectScope(Strategy.userScope)

        user.register(MeegoStrategyService.self) { r in
            return try MeegoStrategyServiceImpl(userResolver: r)
        }
    }
}
