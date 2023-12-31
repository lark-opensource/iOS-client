//
//  LarkContactComponentAssembly.swift
//  LarkContactComponent
//
//  Created by ByteDance on 2023/3/22.
//

import Foundation
import LarkAssembler
import LarkSetting
import LarkContainer

public enum BaseComponentContainerSettings {
    private static var userScopeFG: Bool {
        let v = FeatureGatingManager.shared.featureGatingValue(with: "ios.container.scope.base.component")
        return v
    }
    public static var userScopeCompatibleMode: Bool { !userScopeFG }
    /// 替换.user, FG控制是否开启兼容模式。兼容模式和.user一致
    public static let userScope = UserLifeScope { userScopeCompatibleMode }
    /// 替换.graph, FG控制是否开启兼容模式。
    public static let userGraph = UserGraphScope { userScopeCompatibleMode }
}

public final class LarkContactComponentAssembly: LarkAssemblyInterface {
    
    public init() {}

    public func registContainer(container: Container) {
        let user = container.inObjectScope(BaseComponentContainerSettings.userScope)
        let userGraph = container.inObjectScope(BaseComponentContainerSettings.userGraph)
        
        user.register(LarkTenantNameService.self) { r in
            return LarkTenantNameImp()
        }
    }
}
