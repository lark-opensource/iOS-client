//
//  EnterpriseNoticeAssembly.swift
//  LarkEnterpriseNotice
//
//  Created by ByteDance on 2023/4/18.
//

import Foundation
import LarkAssembler
import Swinject
import LarkRustClient
import LarkSDKInterface
import BootManager
import ServerPB
import LarkSetting
import LarkContainer

public enum EnterpriseNoticeSetting {
    private static var userScopeFG: Bool {
        let v = FeatureGatingManager.shared.featureGatingValue(with: "ios.container.scope.user.enterpriseNotice")
        return v
    }
    //是否开启兼容
    public static var userScopeCompatibleMode: Bool { !userScopeFG }
    /// 替换.user, FG控制是否开启兼容模式。兼容模式和.user一致
    public static let userScope = UserLifeScope { userScopeCompatibleMode }
    /// 替换.graph, FG控制是否开启兼容模式。
    public static let userGraph = UserGraphScope { userScopeCompatibleMode }
}

public final class EnterpriseNoticeAssembly: LarkAssemblyInterface {
    
    public init() {}

    // 注册启动任务
    public func registLaunch(container: Container) {
        NewBootManager.register(LoadEnterpriseNoticeTask.self)
    }

    // 注册service
    public func registContainer(container: Container) {
        let user = container.inObjectScope(EnterpriseNoticeSetting.userScope)
        user.register(EnterpriseNoticeService.self) { (r) -> EnterpriseNoticeService in
            let rustService = try r.resolve(assert: RustService.self)
            let enterpriseNoticeAPI = EnterpriseNoticeAPI(rustService: rustService)
            let pushEnterpriseNoticeCards = try r.userPushCenter.observable(for: PushEnterpriseNoticeMessage.self)
            let pushWebSocketStatus = try r.userPushCenter.observable(for: PushWebSocketStatus.self)
            return EnterpriseNoticeManager(userResolver: r,
                                           noticeAPI: enterpriseNoticeAPI,
                                           pushEnterpriseNoticeCards: pushEnterpriseNoticeCards,
                                           pushWebSocketStatus: pushWebSocketStatus)
            
        }
    }

    // 注册push监听
    public func registServerPushHandlerInUserSpace(container: Container) {
        (ServerPB_Improto_Command.pushSubscriptionsDialog, EnterpriseNoticePushHandler.init(resolver:))
    }
}
