//
//  AnimatedTabBarAssembly.swift
//  AnimatedTabBar
//
//  Created by phoenix on 2023/7/18.
//

import Foundation
import LarkAccountInterface
import AppContainer
import LarkContainer
import LarkAssembler
import LarkSetting
import LarkEnv
import LarkTab

public enum AnimatedTabBarContainerSettings {
    private static var userScopeFG: Bool {
        let featureOn = FeatureGatingManager.shared.featureGatingValue(with: "ios.container.scope.user.animatedTabBar")
        return featureOn
    }
    public static var userScopeCompatibleMode: Bool { !userScopeFG }
    /// 替换.user, FG控制是否开启兼容模式。兼容模式和.user一致
    public static let userScope = UserLifeScope { userScopeCompatibleMode }
    /// 替换.graph, FG控制是否开启兼容模式。
    public static let userGraph = UserGraphScope { userScopeCompatibleMode }
}

public final class AnimatedTabBarAssembly: LarkAssemblyInterface {

    public init() {}

    public func registContainer(container: Container) {
        let user = container.inObjectScope(AnimatedTabBarContainerSettings.userScope)
        
        user.register(OpenPlatformConfigService.self) { (r) -> OpenPlatformConfigService in
            return OpenPlatformConfigService(userResolver: r,
                                             passportService: try r.resolve(assert: PassportService.self))
        }
    }
}

// 忽略魔法数检查
// nolint: magic number

// 开平配置
public class OpenPlatformConfigService: NSObject, UserResolverWrapper {
    // 用户态容器
    public var userResolver: UserResolver
    // Passport服务
    private var passportService: PassportService
    // 开平应用商店Tab
    public var asTab: Tab
    
    init(userResolver: UserResolver,
         passportService: PassportService) {
        self.userResolver = userResolver
        self.passportService = passportService
        /*
         应用目录的应用 ID：
         - 飞书boe：cli_a0ba01113838d01b
         - 飞书online：cli_9ddca2af1b3d5104
         - lark boe： cli_a289d08023f8d017
         - lark online： cli_9e0af9a9c171100a
        */
        // 默认是飞书线上
        var appId = "cli_9ddca2af1b3d5104"
        if passportService.isFeishuBrand {
            // 根据租户维度判断，是否是国内飞书
            if EnvManager.env.isStaging {
                appId = "cli_a0ba01113838d01b"
            } else {
                appId = "cli_9ddca2af1b3d5104"
            }
        } else {
            // 根据租户维度判断，是否是海外Lark
            if EnvManager.env.isStaging {
                appId = "cli_a289d08023f8d017"
            } else {
                appId = "cli_9e0af9a9c171100a"
            }
        }
        var asUrl = ""
        if let domain = DomainSettingManager.shared.currentSetting["applink"]?.first {
            asUrl = "https://\(domain)/client/mini_program/open?appId=\(appId)&path=pages/index/index?visit_from=navigation_add_app"
        }
        
        self.asTab = Tab(url: asUrl, appType: .appTypeOpenApp, key: Tab.asKey, openMode: .pushMode, source: .userSource)
    }
}
