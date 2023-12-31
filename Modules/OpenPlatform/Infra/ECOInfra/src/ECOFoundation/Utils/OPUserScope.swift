//
//  OPUserScope.swift
//  ECOInfra
//
//  Created by justin on 2023/6/8.
//

import Foundation
import LarkContainer
import LarkSetting

public final class OPUserScope {
    
    private static var userScopeFG: Bool { // 每次访问获取，防止登录前访问缓存导致FG一直无法为true
        return FeatureGatingManager.shared.featureGatingValue(with: "openplatform.user_scope_compatible_disable") // Global
    }
    
    /// 是否开启兼容模式
    public static var compatibleModeEnabled: Bool { !userScopeFG }
    
    /// 替换.user, FG控制是否开启兼容模式。兼容模式和.user一致
    public static let userScope = UserLifeScope { compatibleModeEnabled }
    /// 替换.graph, FG控制是否开启兼容模式。
    public static let userGraph = UserGraphScope { compatibleModeEnabled }
    
    /// 获取当前用户对应的UserResolver
    /// - Returns: UserResolver
    public static func userResolver() -> UserResolver {
        // TODOZJX
        return Container.shared.getCurrentUserResolver(compatibleMode: compatibleModeEnabled)
    }
}
