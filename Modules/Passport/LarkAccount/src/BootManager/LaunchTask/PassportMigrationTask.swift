//
//  PassportMigrationTask.swift
//  LarkAccount
//
//  Created by Nix Wang on 2021/12/7.
//

import Foundation
import BootManager
import LarkContainer
import RxSwift
import LarkAccountInterface
import LKCommonsLogging
import UniverseDesignToast

class PassportMigrationTask: AsyncBootTask, Identifiable { // user:checked (boottask)
    static var identify = "PassportMigrationTask"
    
    private let disposeBag = DisposeBag()
    
    static let logger = Logger.log(PassportMigrationTask.self, category: "PassportMigrationTask")

    @Provider private var launcher: Launcher
    
    override var runOnlyOnceInUserScope: Bool { return false }
    
    override func execute(_ context: BootContext) {
        Self.logger.info("n_action_migrate_task_start")
        
        let vc = PassportMigrationViewController()
        context.window?.rootViewController = vc
        
        func onMigrateError(showError: Bool) {
            flowCheckout(.launchGuideFlow)
            if showError, let window = context.window {
                Self.logger.warn("n_action_migrate_upgrade_session_fail_toast")
                UDToast.showTips(with: BundleI18n.suiteLogin.Lark_Passport_InitializeDataFailedToast,
                                 on: window)
            }
        }
        
        PassportStoreMigrationManager.shared.migrateIfNeeded { [weak self] sessionUpgraded in
            guard let `self` = self else { return }
            
            Self.logger.info("n_action_migrate_upgrade_session_end", body: "sessionUpgraded: \(sessionUpgraded)")

            // 升级失败仍然进行 FastLogin，因为 FastLogin 内部有清理逻辑，避免遗漏
            // 需要更新 loginStateSub 信号
            // 由于 login service 初始化比迁移早，在 KAR 5.10 升级场景中，遇到过登录态覆盖安装后，获取的 loginStateSub 是 notLogin 的 case
            self.launcher.fastLogin { [weak self] result in
                isLogining = false
                switch result {
                case .success(let context):
                    Self.logger.info("n_action_migrate_fast_login_succ")

                    let bootContext = NewBootManager.shared.context
                    assert(bootContext.isFastLogin, "should set in login delegate")
                    assert(bootContext.currentUserID == context.foregroundUser.userID, "should set in login delegate") // user:current
                    
                    self?.launcher.loginService.loginStateSub.accept(.logined)
                    self?.flowCheckout(.afterLoginFlow)
                case .failure(let error):
                    Self.logger.error("n_action_migrate_fast_login_fail", error: error)
                    self?.launcher.loginService.loginStateSub.accept(.notLogin)
                    onMigrateError(showError: sessionUpgraded)
                }
            }
        }
    }
}
