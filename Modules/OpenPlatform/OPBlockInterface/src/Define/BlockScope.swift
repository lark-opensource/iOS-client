//
//  BlockScope.swift
//  OPBlockInterface
//
//  Created by Meng on 2023/7/3.
//

import Foundation
import LarkSetting
import LKCommonsLogging
import LarkContainer

public final class BlockScope {
    static let logger = Logger.log(BlockScope.self)

    private static var userScopeFG: Bool {
        let enable = FeatureGatingManager.shared.featureGatingValue(with: BlockFGKey.userScopeFG.key)
        logger.info("get user scope fg: \(enable)")
        return enable
    }

    public static var userScopeCompatibleMode: Bool { !userScopeFG }
    /// 替换 .user scope，FG 控制是否开启兼容模式。兼容模式和 .user 一致。
    public static let userScope = UserLifeScope { userScopeCompatibleMode }
    /// 替换 .graph scoep，FG 控制是否开启兼容模式。
    public static let userGraph = UserGraphScope { userScopeCompatibleMode }
}
