//
//  KAEMMLauncherDelegate.swift
//  LarkBaseService
//
//  Created by kongkaikai on 2021/8/18.
//

import Foundation
import LKCommonsLogging
import LarkAccountInterface
import LarkAppConfig
import LarkContainer
import LarkReleaseConfig
import LarkRustClient
import RustPB
import RxSwift
import UIKit
import Swinject

final class KAEMMLauncherDelegate: LauncherDelegate {
    public var name: String { "KAEMMLauncherDelegate-cjy" }
    static let logger = Logger.log(KAEMMLauncherDelegate.self, category: "Module.LarkKAEMMTask")

    private lazy var accountService: AccountService = AccountServiceAdapter.shared

    private var warpper = KAVPNWrapper()

    private var disposeBag = DisposeBag()

    public init(container: Container) {
        warpper.mainAppLogout = { [weak self] in
            self?.mainAppLogout()
        }
    }

    /// 冷启动回调
    func fastLoginAccount(_ account: Account) {
        afterSetAccount(account)
    }
    /// 飞书重登陆后操作
    public func afterSetAccount(_ account: Account) {
        warpper.ticketAuth { [weak self] result in
            switch result {
            case .success:
                Self.logger.info("KAVPN-cjy: SDK login Success")
            case .failure(let error):
                Self.logger.error("KAVPN-cjy: SDK login Failed", error: error)
                self?.mainAppLogout()
            }
        }
    }

    /// 飞书登出后,SDK也需要登出
    public func afterLogout(context: LauncherContext, conf: LogoutConf) {
        warpper.logout() // 飞书Logout call VPNSDK logout
    }

    /// 提供 Logout 方法共 VPNSDK 踢出飞书时调用
    private func mainAppLogout() {
        let conf = LogoutConf.default
        conf.trigger = .emm
        self.accountService.relogin(
            conf: conf, onError: { errorMessage in
                Self.logger.error("KAVPN-cjy: Feishu logout Failed", additionalData: ["error": errorMessage])
            }, onSuccess: {
                Self.logger.info("KAVPN-cjy: Feishu logout Success")
            }, onInterrupt: {
                Self.logger.error("KAVPN-cjy: Feishu logout Interrupt")
            })
    }
}
