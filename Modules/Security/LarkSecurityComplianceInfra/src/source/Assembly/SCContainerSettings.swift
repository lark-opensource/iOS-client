//
//  SCContinerSettings.swift
//  LarkSecurityComplianceInfra
//
//  Created by qingchun on 2023/1/16.
//

import LarkContainer
import LarkSetting

public struct SCContainerSettings {
    private static var userScopeFG: Bool {
        FeatureGatingManager.shared.featureGatingValue(with: "ios.container.scope.user.securitycompliance") // Global
    }
    public static var userScopeCompatibleMode: Bool { !userScopeFG }
    /// 替换.user, FG控制是否开启兼容模式。兼容模式和.user一致
    public static let userScope = UserLifeScope { userScopeCompatibleMode }
}
