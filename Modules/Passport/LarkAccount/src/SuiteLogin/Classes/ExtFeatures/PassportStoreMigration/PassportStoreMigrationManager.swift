//
//  PassportStoreMigrationManager.swift
//  LarkAccount
//
//  Created by Nix Wang on 2021/8/2.
//

import Foundation
import LarkContainer
import LKCommonsLogging
import ECOProbeMeta
import EENavigator
import LarkReleaseConfig

protocol PassportStoreMigratable {
    func startMigration() -> Bool
}

enum PassportStoreMigrationStatus: Int, Codable {
    case notStarted
    case inProgress
    case completed
}

class PassportStoreMigrationManager: PassportStoreMigratable {
    private static let logger = Logger.log(PassportStoreMigrationManager.self, category: "Passport.PassportStoreMigrationManager")
    
    static let shared = PassportStoreMigrationManager()
    @Provider private var idpWebViewService: IDPWebViewServiceProtocol
    @Provider private var userManager: UserManager
    @Provider private var unloginProcessHandler: UnloginProcessHandler // user:checked (global-resolve)

    func shouldMigrate() -> Bool {
        let store = PassportStore.shared
        let status = store.migrationStatus
        
        Self.logger.info("n_action_passportstore_migration", body: "status: \(status)")
        
        // 数据已经迁移过
        if status == .completed  {
            Self.logger.info("n_action_passportstore_migration_skipped", body: "migration completed")

            return false
        }
        
        // 上次迁移失败
        if  status == .inProgress {
            Self.logger.error("n_action_passportstore_migration failed, resetting store")
            
            logoutOldSession(resetStore: true)
            store.migrationStatus = .completed
            return false
        }
        
        // 未迁移过
        let oldStore = SuiteLoginStore.shared
        if !oldStore.isDataValid {
            Self.logger.info("n_action_passportstore_migration_skipped", body: "Data invalid")

            store.migrationStatus = .completed
            return false
        }
        
        // 没有登录态
        if !oldStore.isLoggedIn {
            Self.logger.info("n_action_passportstore_migration_skipped", body: "Not logged in")
            
            store.migrationStatus = .completed
            return false
        }

        Self.logger.info("n_action_passportstore_migration", body: "shouldMigrate true")

        return true
    }
    
    func migrateIfNeeded(completion: @escaping (_ sessionUpgraded: Bool) -> Void) {
        if !shouldMigrate() {
            completion(false)
            return
        }
        
        Self.logger.info("n_action_passportstore_migration started")
        let context = UniContextCreator.create(.login)
        PassportMonitor.flush(EPMClientPassportMonitorUnspecifiedCode.upgrade_session_request_start, categoryValueMap: nil, context: context)
        
        // 防止在迁移期间打开 URL
        URLInterceptorManager.shared.register { [weak self] url, _ in
            Self.logger.info("n_action_passportstore_migration", body: "Handle url: \(url)")
            
            let migrationStatus = PassportStore.shared.migrationStatus
            if migrationStatus == .inProgress {
                // 数据迁移中，正在展示迁移页面，延迟处理 URL
                self?.unloginProcessHandler.lastVisitURL = url
                Self.logger.info("n_action_passportstore_migration", body: "URL delayed")
                return true
            }
            
            return false
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        let store = PassportStore.shared
        store.migrationStatus = .inProgress
        if startMigration() {
            Self.logger.info("n_action_passportstore_migration data migration succeeded")
        } else {
            Self.logger.error("n_action_passportstore_migration failed")
            logoutOldSession(resetStore: true)
        }
        let endTime = CFAbsoluteTimeGetCurrent()
        Self.logger.info("n_action_passportstore_migration", body: "data migration completed in \((endTime - startTime) * 1000)ms")
        
        guard let foregroundUser = store.foregroundUser else { // user:current
            // 没有登录态，仅在有登录态时迁移，理论上不应该出现，此时不需要升级 session
            store.migrationStatus = .completed
            Self.logger.info("n_action_passportstore_migration_end", body: "No foreground user")
            
            PassportMonitor.flush(EPMClientPassportMonitorUnspecifiedCode.upgrade_session_end_fail, categoryValueMap: ["reason": "No foreground user"], context: context)

            completion(false)

            return
        }
        
        /// 迁移私有化 KA 的 did，从前台用户读取特化的 unit
        if ReleaseConfig.isKA, let unit = foregroundUser.user.unit { // user:current
            Self.logger.info("n_action_passportstore_migration_ka", body: "Migrate device info for additional unit: \(unit)")
            let _ = DeviceInfoStore().migrate(additionalUnit: unit)
        }

        userManager.upgradeUserSession { [weak self] success in

            if success {
                PassportMonitor.flush(EPMClientPassportMonitorUnspecifiedCode.upgrade_session_end_succ, categoryValueMap: nil, context: context)
            } else {
                PassportMonitor.flush(EPMClientPassportMonitorUnspecifiedCode.upgrade_session_end_fail, categoryValueMap: ["reason": "Upgrade session failed"], context: context)
            }

            self?.logoutOldSession(resetStore: !success)

            // 迁移完成
            PassportStore.shared.migrationStatus = .completed
            Self.logger.info("n_action_passportstore_migration_end", body: "Session upgrade result: \(success)")

            completion(true)
        }
    }
    
    /// Session 升级完成后，登出所有旧模型 session
    /// 仅清除本地数据，后面会执行 FastLogin 失败会执行 cookie 等其他的清理工作
    /// 因为有顺序依赖关系，所以写在一起
    private func logoutOldSession(resetStore: Bool) {
        let oldUsers = SuiteLoginStore.shared.userInfoMap.values
        let logoutTokens = oldUsers.compactMap { $0.logoutToken }
        
        let userIds = oldUsers.map({ $0.id })
        let desensitizedTokens = logoutTokens.map { $0.desensitized() }
        Self.logger.info("n_action_passportstore_migration_logout_old_session", body: "Offline logout users: \(userIds), logout tokens: \(desensitizedTokens)")
        
        if resetStore {
            SuiteLoginStore.shared.reset()
            PassportStore.shared.reset() /// 内部不会删除 migrationStatus
        }
        
        // 要在 resetAllData 之后 append
        OfflineLogoutHelper.shared.append(logoutTokens: logoutTokens)
    }
    
    internal func startMigration() -> Bool {
        var migratables: Array<PassportStoreMigratable> = []

        Self.logger.info("n_action_passportstore_migration logged in")
        let loginMigratables: Array<PassportStoreMigratable> = [
            SuiteLoginStore.shared,
            UserManager.shared,
        ]
        migratables.append(contentsOf: loginMigratables)
        
        let deviceMigratables: Array<PassportStoreMigratable> = [
            UploadLogManager.shared,
            DeviceInfoStore(),
            IDPConfigModel()
        ]
        migratables.append(contentsOf: deviceMigratables)
        
        if let idpWebViewService = idpWebViewService as? PassportStoreMigratable {
            migratables.append(idpWebViewService)
        }
        
        for store in migratables {
            Self.logger.info("n_action_passportstore_migration: \(String(describing: store)) started")
            if store.startMigration() {
                Self.logger.info("n_action_passportstore_migration: \(String(describing: store)) succeeded")
            } else {
                Self.logger.error("n_action_passportstore_migration: \(String(describing: store)) failed")
                return false
            }
        }
        
        return true
    }
}
