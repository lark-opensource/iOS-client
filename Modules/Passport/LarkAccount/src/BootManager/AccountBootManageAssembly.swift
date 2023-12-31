//
//  AccountBootManageAssembly.swift
//  LarkAccount
//
//  Created by Miaoqi Wang on 2021/3/24.
//

import Foundation
import BootManager
import Swinject
import LarkAccountInterface
import LKCommonsLogging
import RxSwift
import LarkContainer
import LarkAssembler

class AccountBootManageAssembly: LarkAssemblyInterface {

    public func registPassportDelegate(container: Container) {
        (PassportDelegateFactory {
            if PassportUserScope.enableUserScope {
                return BootManagerPassportDelegate()
            } else {
                return DummyPassportDelegate()
            }
        }, PassportDelegatePriority.high)
    }

    public func registLauncherDelegate(container: Swinject.Container) {
        (LauncherDelegateFactory {
            if PassportUserScope.enableUserScope {
                return DummyLauncherDelegate()
            } else {
                return BootManagerLauncherDelegate()
            }
        }, LauncherDelegateRegisteryPriority.high)
    }

    public func registLaunch(container: Swinject.Container) {
        NewBootManager.register(FastLoginTask.self)
        NewBootManager.register(LogoutPreviousInstallUserTask.self)
        NewBootManager.register(PassportFirstRenderTask.self)
        NewBootManager.register(LoginTask.self)
        NewBootManager.register(CreateTeamTask.self)
        NewBootManager.register(SuiteLoginLoggerTask.self)
        NewBootManager.register(SuiteLoginFetchConfig.self)
        NewBootManager.register(SuiteLoginAfterAccountLoaded.self)
        NewBootManager.register(UnloginProcessHandlerTask.self)
        NewBootManager.register(SetupAppLogTask.self)
        NewBootManager.register(AccountInterrupstHandlerTask.self)
        NewBootManager.register(PassportGetUserListTask.self)
        NewBootManager.register(AccountAssemblyTask.self)
        NewBootManager.register(PassportMigrationTask.self)
        NewBootManager.register(PassportMonitorTask.self)
        NewBootManager.register(PassportPreloadLaunchTask.self)
        NewBootManager.register(PassportCheckDIDUpgradeTask.self)
        NewBootManager.register(PassportDIDUpgradeTask.self)
        NewBootManager.register(SetupCookieTask.self)
        NewBootManager.register(PassportLogoutUserDataEraseTask.self)
        NewBootManager.register(PassportBootupUserDataEraseTask.self)
        NewBootManager.register(PassportBootupUserDataEraseForemostTask.self)
    }
}

extension GlobalBootContext: LauncherContext {}

class BootManagerPassportDelegate: PassportDelegate {
    var name: String = "BootManagerPassportDelegate"

    @InjectedLazy private var logoutService: LogoutService

    static let logger = Logger.plog(BootManagerPassportDelegate.self, category: "LarkAccount")

    func userDidOnline(state: PassportState) {
        let action = state.action
        guard let userID = state.user?.userID else {
            assertionFailure()
            Self.logger.error("n_action_bootmanager_online", body: "user is nil")
            return
        }

        if action == .login || action == .fastLogin {
            NewBootManager.shared.didLogin(userID: userID, fastLogin: action == .fastLogin)
        }

        Self.logger.info("n_action_bootmanager_update_context",
                         additionalData: ["uid": NewBootManager.shared.context.currentUserID ?? "",
                                          "isFastLogin": "\(NewBootManager.shared.context.isFastLogin)"],
                         method: .local)
    }
}

class BootManagerLauncherDelegate: LauncherDelegate {
    var name: String = "BootManagerLauncherDelegate"

    @InjectedLazy private var logoutService: LogoutService

    static let logger = Logger.plog(BootManagerLauncherDelegate.self, category: "LarkAccount")

    func fastLoginAccount(_ account: Account) {
        NewBootManager.shared.didLogin(userID: account.userID, fastLogin: true)
    }

    func afterLoginSucceded(_ context: LauncherContext) {
        guard let userID = context.currentUserID else {
            assertionFailure("afterLoginSucceded must have userID")
            Self.logger.error("afterLoginSucceded must have userID. isFastLogin: \(context.isFastLogin)")
            return
        }
        NewBootManager.shared.didLogin(userID: userID, fastLogin: context.isFastLogin)
        Self.logger.info(
            "afterLoginSucceded update BootManager context",
            additionalData: ["uid": context.currentUserID ?? "", "isFastLogin": "\(context.isFastLogin)"]
        )
    }

    func afterLogout(context: LauncherContext, conf: LogoutConf) {
        switch conf.destination {
        case .login:
            if conf.needEraseData {
                NewBootManager.shared.logoutAndLogin(isRollback: conf.isRollbackLogout)
            } else {
                NewBootManager.shared.login(conf.isRollbackLogout)
            }
        case .launchGuide:
            NewBootManager.shared.launchGuide(conf.isRollbackLogout)
        case .switchUser:
            Self.logger.info("logout with switch user")
        @unknown default:
            Self.logger.error("unhandle logout destination \(conf.description)")
        }
    }

    func switchAccountSucceed(context: LauncherContext) {
        //新账号模型支持同一个 userid 的切换, 如果 userid 一样, 重置 bootmanager 的 userid,从而重新初始化 user scope 的 services
        guard let userID = context.currentUserID else {
            assertionFailure("switchAccountSucceed must have userID")
            Self.logger.error("switchAccountSucceed must have userID")
            return
        }
        NewBootManager.shared.switchAccount(userID: userID)
        Self.logger.info(
            "switchAccountSucceed update BootManager context",
            additionalData: ["uid": context.currentUserID ?? ""], method: .local
        )
    }

    func afterSwitchAccout(error: Error?) -> Observable<Void> {
        if case .autoSwitchFail? = error as? AccountError {
            Self.logger.info("n_action_bootmanager", body: "autoSwitchFail logout start")
            //登出所有租户
            logoutService.relogin(conf: LogoutConf.toLogin) { message in
                Self.logger.error("n_action_bootmanager", body: "autoSwitchFail logout error\(message)")
            } onSuccess: { _ in
                Self.logger.info("n_action_bootmanager", body: "autoSwitchFail logout succ")
            } onInterrupt: {
                Self.logger.error("n_action_bootmanager", body: "autoSwitchFail logout interruptted")
            }
        } else if case .switchUserRustFailed(_)  = error as? AccountError {
            //rust执行出错，进行回滚的初始化操作
            guard let userID = UserManager.shared.foregroundUser?.userID else { // user:current
                assertionFailure("switch should have userID")
                Self.logger.error("switch should have userID")
                return .just(())
            }
            NewBootManager.shared.switchAccountV2(userID: userID,
                                                  isRollbackSwitchUser: true,
                                                  isSessionFirstActive: UserManager.shared.getUser(userID: userID)?.isSessionFirstActive ?? false)
        }
        return .just(())
    }

    func afterSetAccount(_ account: Account) {
        var domainsWithSession = ""
        if let accessTokens = account.accessTokens {
            for (domain, value) in accessTokens {
                domainsWithSession.append(contentsOf: "\(domain) : \(value["value"]?.desensitized() ?? "null"), ")
            }
        }
        Self.logger.info("n_action_bootmanager", body: "afterSetAccount domains with session: \(domainsWithSession)")
    }
}
