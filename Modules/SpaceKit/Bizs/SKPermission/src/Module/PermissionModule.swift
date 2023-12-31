//
//  PermissionModule.swift
//  SKPermission
//
//  Created by Weston Wu on 2023/5/8.
//

import Foundation
import SKFoundation
import SpaceInterface
// 依赖 ModuleService 定义
import SKCommon
import SKInfra
import LarkContainer
import LarkOpenSetting
import EENavigator
import LarkNavigator

public final class PermissionModule: ModuleService {
    public init() {}

    public func setup() {
        DocsLogger.info("PermissionModule setup")
        DocsContainer.shared.register(PermissionSDK.self) { _ in
            // TODO: 等用户态改造后调整读取 user 的方式
            let basicInfo = User.current.basicInfo
            spaceAssert(basicInfo != nil, "failed to get user info")
            let permissionSDK = PermissionSDKImpl(userID: basicInfo?.userID ?? "0",
                                                  tenantID: basicInfo?.tenantID ?? "0")
            return permissionSDK
        }
        .inObjectScope(.user)

        // 隐私设置中的上级可阅读开关
        if UserScopeNoChangeFG.PLF.managerDefaultviewSubordinateEnable {
            PageFactory.shared.register(page: .privacy, moduleKey: ModulePair.Privacy.leaderLinkShareEntry.moduleKey, provider: leaderShareLinkModuleProvider)
        }

        // 设置 - 文档 - 上级自动授权开关
        PageFactory.shared.register(page: .ccm, moduleKey: ModulePair.CCM.imShareLeader.moduleKey, provider: IMShareLeaderSettingModule.moduleProvider)

        // 设置 - 文档 - 默认链接分享范围设置
        PageFactory.shared.register(page: .ccm, moduleKey: ModulePair.CCM.linkShareType.moduleKey, provider: LinkSharePermissionTypeStateModule.moduleProvider)
    }

    /// 注册路由
    public func registerURLRouter() {
        Navigator.shared.registerRoute.type(CCMShareLeaderGuideBody.self)
            .factory(CCMShareLeaderGuideHandler.init(resolver:))
    }
}
