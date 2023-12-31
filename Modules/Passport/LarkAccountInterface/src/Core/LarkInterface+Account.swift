//
//  LarkInterface+Account.swift
//  LarkInterface
//
//  Created by Yuguo on 2018/6/27.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import EENavigator
import LarkContainer
import Swinject
import ThreadSafeDataStructure
import LarkLocalizations

// swiftlint:disable missing_docs

public protocol LauncherContext: AnyObject {
    /// 是否启动直接登录
    var isFastLogin: Bool { get }

    /// 当前UserID
    var currentUserID: String? { get }
}

public protocol LauncherDelegate: AnyObject { // user:checked
    var name: String { get }

    func beforeLogin(_ context: LauncherContext, onLaunchGuide: Bool)
    func afterLoginSucceded(_ context: LauncherContext)
    /// 注: fastLogin 阶段请用 fastLoginAccount 回调
    func beforeSetAccount(_ account: Account)
    /// 注: fastLogin 阶段请用 fastLoginAccount 回调
    func afterSetAccount(_ account: Account)
    /// 注: fastLogin 阶段请用 fastLoginAccount 回调
    func updateAccount(_ account: Account) -> Observable<Void>
    func beforeLogout()
    func beforeLogout(conf: LogoutConf)
    func logoutUserList(by userIDs: [String])
    func beforeLogoutClearAccount(_ account: Account?)
    func afterLogoutClearAccoount(_ account: Account?)
    /// 老版本 Logout 还有业务在用
    func afterLogout(_ context: LauncherContext)
    /// 新版本 Logout
    func afterLogout(context: LauncherContext, conf: LogoutConf)
    func beforeSwitchAccout()
    func beforeSwitchSetAccount(_ account: Account)
    func afterSwitchSetAccount(_ account: Account)
    func afterSwitchAccout(error: Error?) -> Observable<Void>
    func switchAccountSucceed(context: LauncherContext)
    /**
        fastlogin 成功的 delegate 回调. fastLogin 阶段不再执行 beforeSetAccount, afterSetAccount 等操作
     */
    func fastLoginAccount(_ account: Account)
}

public extension LauncherDelegate { // user:checked
    func beforeLogin(_ context: LauncherContext, onLaunchGuide: Bool) {}
    func afterLoginSucceded(_ context: LauncherContext) {}
    func beforeSetAccount(_ account: Account) {}
    func afterSetAccount(_ account: Account) {}
    func beforeLogoutClearAccount(_ account: Account?) {}
    func afterLogoutClearAccoount(_ account: Account?) {}
    func updateAccount(_ account: Account) -> Observable<Void> { .just(()) }
    func beforeLogout() {}
    func beforeLogout(conf: LogoutConf) {}
    func logoutUserList(by userIDs: [String]) {}
    func afterLogout(_ context: LauncherContext) {}
    func afterLogout(context: LauncherContext, conf: LogoutConf) {}
    func beforeSwitchAccout() {}
    func beforeSwitchSetAccount(_ account: Account) {}
    func afterSwitchSetAccount(_ account: Account) {}
    func afterSwitchAccout(error: Error?) -> Observable<Void> {
        return .just(())
    }
    func switchAccountSucceed(context: LauncherContext) {}
    func fastLoginAccount(_ account: Account) {}
}

public final class LauncherDelegateFactory {
    private let delegateProvider: () -> LauncherDelegate // user:checked

    // swiftlint:disable weak_delegate
    public lazy var delegate: LauncherDelegate = {
        let launchDelegate = self.delegateProvider()
        let identify = ObjectIdentifier(type(of: launchDelegate))
        LauncherDelegateRegistery.delegates[identify] = launchDelegate
        return launchDelegate
    }()
    // swiftlint:enable weak_delegate

    public init(delegateProvider: @escaping () -> LauncherDelegate) { // user:checked
        self.delegateProvider = delegateProvider
    }
}

public enum LauncherDelegateRegisteryPriority: String {
    case high = "LauncherDelegateRegisteryPriorityHigh"
    case middle = "LauncherDelegateRegisteryPrioritymiddle"
    case low = "LauncherDelegateRegisteryPrioritylow"
}

public final class LauncherDelegateRegistery {

    public private(set) static var factoriesDict = [String: [LauncherDelegateFactory]]()

    public static func factories() -> [LauncherDelegateFactory] {
        let sortedKey: [String] = [LauncherDelegateRegisteryPriority.high.rawValue,
                                   LauncherDelegateRegisteryPriority.middle.rawValue,
                                   LauncherDelegateRegisteryPriority.low.rawValue]
        var ret = [LauncherDelegateFactory]()
        sortedKey.forEach { (key) in
            if let value = self.factoriesDict[key] {
                ret.append(contentsOf: value)
            }
        }
        return ret
    }

    /// get LaunchDelegate instance
    /// - Parameter delegate: LaunchDelegate
    private static let lock = NSRecursiveLock()
    public static func resolver<T: LauncherDelegate>(_ delegate: T.Type) -> T? { // user:checked
        lock.lock()
        defer { lock.unlock() }
        // none Launcher Event has been sended
        if delegates.isEmpty ||
            !delegates.keys.contains(ObjectIdentifier(delegate)) {
            factories().forEach { _ = $0.delegate }
        }
        return delegates[ObjectIdentifier(delegate)] as? T
    }

    internal static var delegates: [ObjectIdentifier: LauncherDelegate] = [:] // user:checked

    /// register account launcher
    /// - Parameters:
    ///   - factory: LauncherDelegateFactory
    ///   - priority: exec order: hight -> middle -> low
    public static func register(factory: LauncherDelegateFactory, priority: LauncherDelegateRegisteryPriority) {
        var execQueue = factoriesDict[priority.rawValue]
        if execQueue == nil {
            execQueue = [LauncherDelegateFactory]()
        }
        execQueue?.append(factory)
        factoriesDict[priority.rawValue] = execQueue
    }
}

public struct TenantConfig {
    public static let `default` = TenantConfig()
    public static let other = TenantConfig(
        debugEnable: true,
        checkTelPermissionEnable: false
    )

    public var debugEnable: Bool = false                       // 是否支持点击头像唤起 debug 页面
    public var checkTelPermissionEnable: Bool = true           // 在打电话的时候是否需要检查权限
}

public struct PhoneNumber {
    public let contryCode: String
    public let phoneNumber: String

    public init(_ code: String, _ phone: String) {
        contryCode = code
        phoneNumber = phone
    }
}

public struct SecurityConfig {

    public let modifyPwd: SecurityConfigItem
    public let accountManagement: SecurityConfigItem
    public let securityVerification: SecurityConfigItem
    public let deviceManagement: SecurityConfigItem
    public let twoFactorAuth: SecurityConfigItem

    public init (
        modifyPwd: SecurityConfigItem,
        accountManagement: SecurityConfigItem,
        securityVerification: SecurityConfigItem,
        deviceManagement: SecurityConfigItem,
        twoFactorAuth: SecurityConfigItem
    ) {
        self.modifyPwd = modifyPwd
        self.accountManagement = accountManagement
        self.securityVerification = securityVerification
        self.deviceManagement = deviceManagement
        self.twoFactorAuth = twoFactorAuth
    }

    static var placeholder: SecurityConfig {
        return SecurityConfig(
            modifyPwd: SecurityConfigItem.placeholder,
            accountManagement: SecurityConfigItem.placeholder,
            securityVerification: SecurityConfigItem.placeholder,
            deviceManagement: SecurityConfigItem.placeholder,
            twoFactorAuth: SecurityConfigItem.placeholder
        )
    }

    public var logDescription: String {
        let res: [String: String] = [
            "modifyPwd": modifyPwd.logDescription,
            "accountManage": accountManagement.logDescription,
            "securityVerify": securityVerification.logDescription,
            "deviceManage": deviceManagement.logDescription,
            "twoFactor": twoFactorAuth.logDescription
        ]
        return res.description
    }
}

public struct SecurityConfigItem {

    public let switchStatus: Int
    public let moduleInfo: [String: String]

    public static let statusDefaultValue: Int = 1
    public static let infoDefaultValue: [String: String] = [:]

    public init(status: Int, info: [String: String]) {
        self.switchStatus = status
        self.moduleInfo = info
    }

    public static var placeholder: SecurityConfigItem {
        return SecurityConfigItem(
            status: SecurityConfigItem.statusDefaultValue,
            info: SecurityConfigItem.infoDefaultValue
        )
    }

    public var logDescription: String {
        let res: [String: String] = [
            "status": "\(switchStatus)",
            "info": moduleInfo.description
        ]
        return res.description
    }
}

public typealias TenantSingleProductType = Int32

public struct PendingUser {
    public let userName: String
    public let userEnv: String
    public let userUnit: String
    public let tenantID: String
    public let tenantName: String
    public let tenantIconURL: String

    public init(userName: String,
                userEnv: String,
                userUnit: String,
                tenantID: String,
                tenantName: String,
                tenantIconURL: String) {
        self.userName = userName
        self.userEnv = userEnv
        self.userUnit = userUnit
        self.tenantID = tenantID
        self.tenantName = tenantName
        self.tenantIconURL = tenantIconURL
    }
}

public enum UnregisterScope: Int, Codable {
    case quitTeam = 0 // 退出团队
}

public final class CheckUnRegisterStatusModel: Codable {
    public let enabled: Bool
    public var buttonText: String = ""
    public let notice: String
    public let urlString: String

    public init(enabled: Bool,
                notice: String,
                urlString: String,
                buttonText: String = "") {
        self.enabled = enabled
        self.buttonText = buttonText
        self.notice = notice
        self.urlString = urlString
    }

    enum CodingKeys: String, CodingKey {
        case enabled, notice
        case buttonText = "title"
        case urlString = "url"
    }
}

public extension AccountServiceCore { // user:checked
    var currentChatterId: String {
        return currentAccountInfo.userID
    }
    var currentAccessToken: String {
        return currentAccountInfo.accessToken ?? ""
    }
    var currentTenantConfig: TenantConfig {
        return currentAccountInfo.tenantConfig
    }
    var currentTenant: TenantInfo {
        return currentAccountInfo.tenantInfo
    }
    /// 当前是否登录
    var isLogin: Bool {
        return !currentAccountIsEmpty
    }
}

public enum InterruptOperationType {
    case switchAccount
    case relogin
    case sessionInvalid
}

public protocol InterruptOperation: AnyObject, CustomStringConvertible {
    func getInterruptObservable(type: InterruptOperationType) -> Single<Bool>
}

public extension InterruptOperation {
    var description: String {
        return "InterruptOperation"
    }
}

// public typealias AccountUserList = (normal: [Account], pending: [PendingUser])

public struct AccountUserList: PushMessage {
    public let normal: [Account]
    public let pending: [PendingUser]

    public init(normal: [Account], pending: [PendingUser]) {
        self.normal = normal
        self.pending = pending
    }
}

@available(*, deprecated, message: "Will be removed soon. Use `PassportFastLoginUserContext` instead.")
public struct PassportUsersInfo {
    public let accounts: [Account]
    public let currentAccount: Account
    public let currentAccountIndex: Int

    public init(accounts: [Account], currentAccount: Account, currentAccountIndex: Int) {
        self.accounts = accounts
        self.currentAccount = currentAccount
        self.currentAccountIndex = currentAccountIndex
    }
}

public struct PassportFastLoginUserContext {
    public let foregroundUser: User
    public let userList: [User]

    public init(foregroundUser: User, userList: [User]) {
        self.foregroundUser = foregroundUser // user:current
        self.userList = userList
    }
}

public struct LoginConf {
    public var register: Bool = false
    public var fromLaunchGuide: Bool = false
    public var isRollbackLogout: Bool = false

    public static let `default` = LoginConf()
    public static let toRegister = LoginConf(register: true)

    public init(register: Bool = false, fromLaunchGuide: Bool = false, isRollbackLogout: Bool = false) {
        self.register = register
        self.fromLaunchGuide = fromLaunchGuide
        self.isRollbackLogout = isRollbackLogout
    }
}

private class AccountServiceImp { // user:checked
    static let shared = AccountServiceImp() // user:checked
    @Provider public var accountService: AccountService // user:checked
}

/// AccountService NameSpace
@available(*, deprecated, message: "You should use PassportService or PassportUserService instead.")
public enum AccountServiceAdapter {
    /// singleton
    public static let shared: AccountService = AccountServiceImp.shared.accountService // user:checked

    /// 已废弃
    @available(*, deprecated, message: "Will be removed soon.")
    public static func setup(accountServiceImp: AccountService) {} // user:checked
}

public struct DeviceInfo {
    public let deviceId: String
    public let installId: String
    public let deviceLoginId: String

    public let isValidDeviceID: Bool
    public let isValid: Bool

    public init(
        deviceId: String,
        installId: String,
        deviceLoginId: String,
        isValidDeviceID: Bool,
        isValid: Bool
    ) {
        self.deviceId = deviceId
        self.installId = installId
        self.deviceLoginId = deviceLoginId
        self.isValidDeviceID = isValidDeviceID
        self.isValid = isValid
    }

    public static let emptyValue = "0"

    public static func isDeviceIDValid(_ deviceID: String) -> Bool {
        return !deviceID.isEmpty && deviceID != Self.emptyValue
    }

    public static func isInstallIDValid(_ installID: String) -> Bool {
        return !installID.isEmpty && installID != Self.emptyValue
    }

    public static func isDeviceLoginIDValid(_ deviceLoginId: String) -> Bool {
        return !deviceLoginId.isEmpty && deviceLoginId != Self.emptyValue
    }

}

public typealias DeviceInfoTuple = (deviceId: String, installId: String)

public protocol DeviceService {
    var deviceInfo: DeviceInfo { get }
    var deviceInfoObservable: Observable<DeviceInfo?> { get }
}

public extension DeviceService {
    var deviceId: String {
        return deviceInfo.deviceId
    }
    var installId: String {
        return deviceInfo.installId
    }
    var deviceLoginId: String {
        return deviceInfo.deviceLoginId
    }
}

public struct ExtraIdentity: Codable {
    
    public let externalToken, refreshToken, tokenExpires, refreshTokenExpires, openId: String

    enum CodingKeys: String, CodingKey {
        case externalToken = "external_token"
        case refreshToken = "refresh_token"
        case tokenExpires = "token_expires"
        case refreshTokenExpires = "refresh_token_expires"
        case openId = "open_id"
    }
    
    public init(externalToken: String, refreshToken: String, tokenExpires: String, refreshTokenExpires: String, openId: String) {
        self.externalToken = externalToken
        self.refreshToken = refreshToken
        self.tokenExpires = tokenExpires
        self.refreshTokenExpires = refreshTokenExpires
        self.openId = openId
    }
}

public protocol KaLoginService: AnyObject {

    func getKaConfig() -> [String: Any]?

    func getExtraIdentity(onSuccess: @escaping ([String: Any]) -> Void, onError: @escaping (Error) -> Void)

    func kaLoginResult(args: [String: Any])

    func switchIdp(_ idp: String)
    
    func updateExtraIdentity(_ extraIdentity: ExtraIdentity)
}

public protocol PassportWebViewDependency {

    var unsupportErrorTip: String { get }

    func open(data: [String: Any], success: @escaping () -> Void, failure: @escaping (Error) -> Void)

    func getAppInfo() -> [String: Any]

    func finishedLogin(_ args: [String: Any])

    func getIDPConfig() -> [String: Any]?

    func getIDPAuthConfig() -> [String: Any]?

    func switchIDP(_ idp: String, completion: @escaping (Bool, Error?) -> Void)

    func getAppLanguage() -> [String: Any]

    func setAppLanguage(_ args: [String: Any])

    func startFaceIdentify(_ args: [String: Any], success: @escaping () -> Void, failure: @escaping (Error) -> Void)

    func getStepInfo() -> [String: Any]

    func nativeHttpRequest(_ args: [String: Any], success: @escaping ([String: Any]) -> Void, failure: @escaping ([String: Any]) -> Void)

    func openNativeScanVC(_ stepInfo: [String: Any], complete: @escaping (String) -> Void)

    func registerFido(_ args: [String: Any], success: @escaping ([String: Any]) -> Void, failure: @escaping ([String: Any]) -> Void)
    
    func enableLeftNaviButtonsRootVCOptObservable() -> Observable<Bool>

    func enableCheckSensitiveJsApi() -> Bool

    func monitorSensitiveJsApi(apiName: String, sourceUrl: URL?, from: String)

    func getSaasLoginVC() -> UIViewController
}

public enum Level: String {
    case error = "ERROR"
    case warn = "WARN"
    case info = "INFO"
    case debug = "DEBUG"
}

public let clientDataWrapperQueue: DispatchQueue = {
    let queue = DispatchQueue(label: "clientDataWrapperQueue", qos: .utility)
    return queue
}()

public let scheduler = SerialDispatchQueueScheduler(
    queue: clientDataWrapperQueue,
    internalSerialQueueName: clientDataWrapperQueue.label
)

/// App ID ， 按名称区分
///
/// - lark: lark app
/// - bear: docs app
/// - calendar: calendar app
public struct LarkAppID {
    public static let lark = 1
    public static let bear = 2
    public static let calendar = 3
}

public protocol SuiteLoginWebViewFactory {
    func createWebViewController(_ url: URL, customUserAgent: String?) -> UIViewController
    func createFailView() -> UIView
}

public protocol LaunchGuidePassportDependency {
    func ugTrack(_ event: String, eventParams: [String: Any])

    var enableJoinMeeting: Bool { get }
}

public extension LaunchGuidePassportDependency {
    func ugTrack(_ event: String, eventParams: [String: Any]) {}
}

public enum SecurityResultCode {
    /// 成功
    public static let success: Int = 0
    /// 用户取消，验证失败
    public static let userCancelOrFailed: Int = 1
    /// 密码错误，验证失败
    public static let passwordError: Int = 2
    /// 密码输入次数超限制
    public static let retryTimeLimit: Int = 3
}

public typealias SecurityResult = (_ code: Int, _ errorMessage: String?, _ token: String?) -> Void

public enum ContactType: Int {
    case phone = 1
    case mail = 2
}

public protocol PassportCookieDependency {
    func clearCookie()
    func setupCookie(user: User) -> Bool
}

public protocol PassportContactDependency {
    func openProfile(_ userID: String, hostViewController: UIViewController)
}

public struct LeanModeInfo {
    public let deviceHaveAuthority: Bool
    public let isLockScreenEnabled: Bool
    public let lockScreenPwd: String?
    public let allDevicesInLeanMode: Bool
    public let canUseLeanMode: Bool
    public let lockScreenCfgUpdateTime: Int64
    public let leanModeCfgUpdateTime: Int64
    
    public init(deviceHaveAuthority: Bool, isLockScreenEnabled: Bool, lockScreenPwd: String?, allDevicesInLeanMode: Bool, canUseLeanMode: Bool, lockScreenCfgUpdateTime: Int64, leanModeCfgUpdateTime: Int64) {
        self.deviceHaveAuthority = deviceHaveAuthority
        self.isLockScreenEnabled = isLockScreenEnabled
        self.lockScreenPwd = lockScreenPwd
        self.allDevicesInLeanMode = allDevicesInLeanMode
        self.canUseLeanMode = canUseLeanMode
        self.lockScreenCfgUpdateTime = lockScreenCfgUpdateTime
        self.leanModeCfgUpdateTime = leanModeCfgUpdateTime
    }
}


public protocol PassportContainerAfterRustOnlineWorkflow {
    //rust online成功后，passport的任务编排
    func runForgroundUserChangeWorkflow(action: PassportUserAction, foregroundUser: User, completion: @escaping (Result<Void, Error>) -> Void)

    func runlogoutForgroundUserWorkflow(completion: @escaping () -> Void)
}

// swiftlint:enable missing_docs


