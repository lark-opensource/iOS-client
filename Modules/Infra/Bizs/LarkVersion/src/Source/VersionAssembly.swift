//
//  MineAssembly.swift
//  LarkVersion
//
//  Created by 姚启灏 on 2018/6/20.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import Swinject
import LarkContainer
import BootManager
import LarkAccountInterface
import LarkAppConfig
import LarkSDKInterface
import LarkAssembler

public final class VersionAssembly: LarkAssemblyInterface {
    public init() { }

    public func registContainer(container: Container) {
        let user = container.inObjectScope(Version.userScope)
        let userGraph = container.inObjectScope(Version.userGraph)

        userGraph.register(VersionUpdateService.self) { r in
            let versionManager = try r.resolve(assert: VersionManager.self)
            return VersionServiceImpl(versionManager: versionManager)
        }

        user.register(VersionManager.self) { (r) in
            let accountService = AccountServiceAdapter.shared
            let versionHelper = VersionControlHelper(
                userResolver: r,
                currentChatterId: accountService.currentChatterId,
                currentTenantId: accountService.currentTenant.tenantId
            )
            return try VersionManager(
                userResolver: r,
                versionHelper: versionHelper,
                dependency: try r.resolve(assert: LarkVersionDependency.self)
            )
        }
    }

    public func registLaunch(container: Container) { NewBootManager.register(KAUpgradeLaunchTask.self) }
}

import LarkSetting

/// 用于FG控制UserResolver的迁移, 控制Resolver类型.
/// 使用UserResolver后可能抛错，需要控制对应的兼容问题
public enum Version {
    private static var userScopeFG: Bool {
        let v = FeatureGatingManager.shared.featureGatingValue(with: "ios.container.scope.user.version")
        return v
    }
    public static var userScopeCompatibleMode: Bool { !userScopeFG }
    /// 替换.user, FG控制是否开启兼容模式。兼容模式和.user一致
    public static let userScope = UserLifeScope { userScopeCompatibleMode }
    /// 替换.graph, FG控制是否开启兼容模式。
    public static let userGraph = UserGraphScope { userScopeCompatibleMode }
}
