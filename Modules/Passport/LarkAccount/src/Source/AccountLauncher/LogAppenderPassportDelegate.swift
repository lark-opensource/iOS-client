//
//  SuiteLoginLaunchDelegate.swift
//  LarkApp
//
//  Created by quyiming@bytedance.com on 2019/7/10.
//
import Swinject
import Logger
import RxSwift
import LarkAccountInterface
import RunloopTools
import LarkContainer
import LKCommonsLogging

class LogAppenderPassportDelegate: PassportDelegate {

    static let logger = LKCommonsLogging.Logger.plog(LogAppenderPassportDelegate.self, category: "SuiteLogin.RangersAppLog.LaunchDelegate")

    private let resolver: Resolver

    // MARK: Logger
    private var isFirstLaunch: Bool = true

    private var logEnable: Bool = PassportSwitch.shared.enableLogInLogin

    let disposeBag = DisposeBag()

    public init(resolver: Resolver) {
        self.resolver = resolver
    }

    func userDidOnline(state: PassportState) {
        self.removeAppenders()
    }

    func userDidOffline(state: PassportState) {
        if self.logEnable {
            self.addAppenders()
        }
    }

    func adjustLogAppenders() {
        if isFirstLaunch {
            isFirstLaunch = false
            if !self.logEnable {
                self.removeAppenders()
            }
        }
    }

    // MARK: Logger

    private func addAppenders() {
        let uploadLogAppender = getUploadLogAppender()
        LogAppenderPassportDelegate.add(appender: uploadLogAppender)
    }

    private func removeAppenders() {
        LogAppenderPassportDelegate.remove(appenderType: UploadLogAppender.self)
    }

    private func getUploadLogAppender() -> UploadLogAppender {
        let uploadLogAppender = UploadLogAppender(UploadLogConfig(logLevel: .debug))
        do {
            let logger = try resolver.resolve(assert: UploadLog.self)
            uploadLogAppender.logger = logger
        } catch {
            Self.logger.error("getUploadLogAppender cannot resolve logger")
        }
        return uploadLogAppender
    }

    static func add(appender: Appender) {
        SuiteLoginBackendType.backends.forEach {
            Logger.add(appender: appender, persistent: true, backendType: $0)
        }
    }

    static func remove<T: Appender>(appenderType: T.Type) {
        SuiteLoginBackendType.backends.forEach {
            Logger.remove(appenderType: appenderType, persistent: true, backendType: $0)
        }
    }
}

class SuiteLoginLaunchDelegate: LauncherDelegate { // user:checked

    static let logger = LKCommonsLogging.Logger.plog(SuiteLoginLaunchDelegate.self, category: "SuiteLogin.RangersAppLog.LaunchDelegate")

    public var name: String = "SuiteLogin"

    private let resolver: Resolver

    // MARK: Logger
    private var isFirstLaunch: Bool = true

    private var logEnable: Bool = PassportSwitch.shared.enableLogInLogin

    @Provider private var loginService: V3LoginService

    let disposeBag = DisposeBag()

    public init(resolver: Resolver) {
        self.resolver = resolver
    }

    public func beforeLogin(_ context: LauncherContext, onLaunchGuide: Bool) {
        if logEnable {
            self.addAppenders()
        }
        adjustLogAppenders()
    }

    public func afterLoginSucceded(_ context: LauncherContext) {
        self.removeAppenders()
    }

    public func afterLogout(_ context: LauncherContext) {
        if logEnable {
            self.addAppenders()
        }
    }

    func adjustLogAppenders() {
        if isFirstLaunch {
            isFirstLaunch = false
            if !self.logEnable {
                self.removeAppenders()
            }
        }
    }

    // MARK: Logger

    private func addAppenders() {
        let uploadLogAppender = getUploadLogAppender()
        SuiteLoginLaunchDelegate.add(appender: uploadLogAppender)
    }

    private func removeAppenders() {
        SuiteLoginLaunchDelegate.remove(appenderType: UploadLogAppender.self)
    }

    private func getUploadLogAppender() -> UploadLogAppender {
        let uploadLogAppender = UploadLogAppender(UploadLogConfig(logLevel: .debug))
        do {
            let logger = try resolver.resolve(assert: UploadLog.self)
            uploadLogAppender.logger = logger
        } catch {
            Self.logger.error("getUploadLogAppender cannot resolve logger")
        }
        return uploadLogAppender
    }

    static func add(appender: Appender) {
        SuiteLoginBackendType.backends.forEach {
            Logger.add(appender: appender, persistent: true, backendType: $0)
        }
    }

    static func remove<T: Appender>(appenderType: T.Type) {
        SuiteLoginBackendType.backends.forEach {
            Logger.remove(appenderType: appenderType, persistent: true, backendType: $0)
        }
    }
}

struct SuiteLoginBackendType {
    public static let jsSDK: String = "Module.JSSDK"
    public static let web: String = "Module.Web"
    public static let suiteLogin: String = "SuiteLogin."
    public static let webcache: String = "LarkWebCacheUpload."

    public static let backends: [String] = [SuiteLoginBackendType.jsSDK,
                                     SuiteLoginBackendType.web,
                                     SuiteLoginBackendType.suiteLogin,
                                     SuiteLoginBackendType.webcache]
}
