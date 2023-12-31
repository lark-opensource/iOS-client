//
//  WorkplaceContainerScope.swift
//  LarkWorkplace
//
//  Created by Meng on 2023/4/25.
//

import Foundation
import LarkContainer
import LarkSetting
import LarkFeatureGating
import LKCommonsLogging

public enum WorkplaceScope {
    static let logger = Logger.log(WorkplaceScope.self)

    private static var userScopeFG: Bool {
        let enable = FeatureGatingManager.shared.featureGatingValue(with: WPFGKey.enableContainerUserScope.key)
        logger.info("get user scope fg: \(enable)")
        return enable
    }

    public static var userScopeCompatibleMode: Bool { !userScopeFG }

    /// 替换 .user scope，FG 控制是否开启兼容模式。兼容模式和 .user 一致。
    public static var userScope = UserLifeScope { userScopeCompatibleMode }
    /// 替换 .graph scoep，FG 控制是否开启兼容模式。
    public static var userGraph = UserGraphScope { userScopeCompatibleMode }
}
