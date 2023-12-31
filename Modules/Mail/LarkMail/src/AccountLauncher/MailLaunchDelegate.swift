//
//  MailLaunchDelegate.swift
//  LarkMail
//
//  Created by 谭志远 on 2019/5/16.
//  Copyright © 2019年 Bytedance.Inc. All rights reserved.
//

import Foundation
import Swinject
import LarkRustClient
import RxSwift
import LarkFeatureGating
import MailSDK
import LarkAccountInterface
import LarkPerf
import LKCommonsLogging
import RunloopTools
import BootManager
import LarkContainer

final class MailLaunchDelegate: LauncherDelegate {
    static var userId: String = ""
    static let logger = Logger.log(MailLaunchDelegate.self, category: "Module.Mail")

    let name: String = "MailSDK"
    private let resolver: Resolver
    var service: LarkMailService? {
        return resolver.resolve(LarkMailService.self)
    }

    static func mailEnable(resolve r: Resolver,
                                  shouldProtect: Bool = false) -> Bool { // keep same value in this user login life circle
        if shouldProtect && !LarkMailService.sharedHasInit {
            return false
        }
        return true
    }

    init(resolver: Resolver) {
        self.resolver = resolver
    }

    func afterLogout(_ context: LauncherContext) {
        /// 用户态迁移后，LarkMailService 在用户登出后销毁，无法使用实例
        /// 暂时用静态方法清理业务一些还未迁移的单例状态
        if MailLaunchDelegate.mailEnable(resolve: resolver, shouldProtect: true) {
            LarkMailService.larkUserDidLogout(nil)
        }
    }

    func afterSwitchAccout(error: Error?) -> Observable<Void> {
        // this is not safe to init service after logout. because use ! to unwrap the option value account
        // so only mailenble can we use service
        if MailLaunchDelegate.mailEnable(resolve: resolver) {
            service?.didFinishSwitchAccount(error)
        }

        return .just(())
    }
}
