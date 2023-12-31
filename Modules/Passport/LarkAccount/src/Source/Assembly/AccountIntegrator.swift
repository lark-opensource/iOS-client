//
//  AccountIntegrator.swift
//  LarkAccount
//
//  Created by Miaoqi Wang on 2021/3/23.
//

import Foundation
import LarkContainer
import LarkAccountInterface
import AppContainer
import Logger

/// Account 集成操作
class AccountIntegrator {

    public static let shared = AccountIntegrator()

    @Provider private var unloginProcessHandler: UnloginProcessHandler // user:checked (global-resolve)

    @Provider private var loginService: V3LoginService
    @Provider private var logoutService: LogoutService

    /// 注册拦截信号（切换租户 登出时候检查是否有阻断事件）
    func registerLogoutInterrupt() {
        loginService.register(interruptOperation: AccountInterruptOperation())
    }

    /// 更新V3Config
    func refreshConfig() {
        loginService.refreshLoginConfig()
        PassportGray.shared.refreshConfig()
    }

    /// 登录后处理登录前的OpenUrl事件
    func processUnloginHandlerAfterLogin() {
        loginService.removeAllInterruptOperations()
        unloginProcessHandler.handleLaunchHome()
    }
}

// MARK: - preload

extension AccountIntegrator {
    /// 预加载
    func preload() {
        OfflineLogoutHelper.shared.start()
    }
}

// MARK: - Logger

extension AccountIntegrator {
    /// 设置登录相关Logger的Appender
    func setupLogger() {
        var config: [LogCenter.Config] = []
        SuiteLoginBackendType.backends.forEach { (backend) in
            let logConfig = LogCenter.Config(
                backend: backend,
                appenders: [],
                forwardToDefault: true
            )
            config.append(logConfig)
        }
        LogCenter.setup(configs: config)
    }

    /// 调整登录相关Appender
    func adjustLogger() {
        PassportDelegateRegistry.resolver(LogAppenderPassportDelegate.self)?
            .adjustLogAppenders()
    }
}

// MARK: - app log

extension AccountIntegrator {
    /// 初始化AppLog
    func setupAppLog() {
        RangersAppLogDeviceServiceImpl.hasSetupAppLog = true
        AppLogIntegrator.setupAppLog()
    }

    /// 更新AppLog
    func updateAppLog() {
        AppLogIntegrator.updateAppLog()
    }
}

// MARK: - life cycle

extension AccountIntegrator {
    /// 非BootManager集成时候的初始化
    func setup() {
        DispatchQueue.global().async {
            self.preload()
        }
        setupAppLog()
        setupLogger()
        refreshConfig()
    }

    /// 非BootManager集成时候进入首页任务
    func mainViewLoaded() {
        adjustLogger()
    }
}

class AccountIntegratorDelegate: PassportDelegate {
    let name: String = "AccountIntegratorLauncherDelegate"

    func userDidOnline(state: PassportState) {
        if state.action == .login {
            AccountIntegrator.shared.processUnloginHandlerAfterLogin()
            AccountIntegrator.shared.registerLogoutInterrupt()
        }
    }
}

class AccountIntegratorLauncherDelegate: LauncherDelegate { // user:checked
    let name: String = "AccountIntegratorLauncherDelegate"

    func afterLoginSucceded(_ context: LauncherContext) {
        AccountIntegrator.shared.processUnloginHandlerAfterLogin()
        AccountIntegrator.shared.registerLogoutInterrupt()
    }
}
