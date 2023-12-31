//
//  MinimumAssembly.swift
//  LarkMinimumMode
//
//  Created by zc09v on 2021/5/8.
//

import Foundation
import Swinject
import BootManager
import LarkRustClient
import LarkAssembler
import LarkContainer
import LarkSetting

enum Minimum {
    private static var userScopeFG: Bool {
        let v = FeatureGatingManager.shared.featureGatingValue(with: "lark.ios.messeger.userscope.refactor") //Global
        return v
    }
    static var userScopeCompatibleMode: Bool { !userScopeFG }
    /// 替换.user, FG控制是否开启兼容模式。兼容模式和.user一致
    static let userScope = UserLifeScope { userScopeCompatibleMode }
    /// 替换.graph, FG控制是否开启兼容模式。
    static let userGraph = UserGraphScope { userScopeCompatibleMode }
}

public final class MinimumAssembly: LarkAssemblyInterface {
    public init() {}

    public func registLaunch(container: Container) {
        NewBootManager.register(MinimumModeTask.self)
    }

    public func registContainer(container: Container) {
        let user = container.inObjectScope(Minimum.userScope)

        user.register(MinimumModeInterface.self, factory: { r in
            return MinimumModeInterfaceImpl(userResolver: r)
        })

        user.register(MinimumModeAPI.self) { (r) -> MinimumModeAPI in
            return MinimumModeAPIImpl(client: try r.resolve(assert: RustService.self))
        }
    }
}
