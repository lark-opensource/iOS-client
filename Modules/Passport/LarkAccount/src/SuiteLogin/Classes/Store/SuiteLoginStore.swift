//
//  SuiteLoginStore.swift
//  SuiteLogin
//
//  Created by qihongye on 2019/1/21.
//

import Foundation
import CommonCrypto
import LKCommonsLogging
import LarkReleaseConfig
import LarkExtensions
import LarkAccountInterface
import LarkContainer
import LarkFoundation
import ThreadSafeDataStructure

private let logger = Logger.log(SuiteLoginStore.self, category: "Store")

public final class SuiteLoginStore {

    public static let shared: SuiteLoginStore = SuiteLoginStore()

    static let keychainLogger = Logger.log(SuiteLoginStore.self, category: "keychain")
    private let accountKey: String = genKey("com.bytedance.ee.account")
    private var countryCodeKey: String = genKey("countryCodeKey")

    private let currentUserIDKey: String = genKey("com.bytedance.ee.currentUserID")

    private var loginConfigKey: String = genKey("com.bytedance.ee.loginConfig")

    private var configInfoKey: String = genKey("com.bytedance.ee.configInfo")

    private var loggedInMethodKey: String = genKey("com.bytedance.ee.loggedInMethod")

    private let derivedUserKey: String = genKey("com.bytedance.ee.derivedUser")

    private let v3ConfigEnvKey: String = genKey("com.bytedance.ee.v3ConfigEnv")

    private let dataIdentifierKey: String = genKey("com.bytedance.ee.dataIdentifer")
    //新标识.改用 modelName 的元数据 作为设备标识 e.g. iPhone12,1
    private let deviceIdentifierKey: String = genKey("com.bytedance.ee.deviceIdentifer")

    private let ssoPrefixKey: String = genKey("com.bytedance.ee.sso_prefix")
    private let ssoSuffixKey: String = genKey("com.bytedance.ee.sso_suffix")

    private let useRangersAppLogKey: String = genKey("com.bytedance.ee.useAppLog")

    /// 15天内免登录
    private lazy var keepLoginInKey: String = genKey("com.bytedance.ee.keeyLoginIn")

    private let lock = NSRecursiveLock()

    let userDefaults: UserDefaults

    @Provider var deviceService: InternalDeviceServiceProtocol

    init() {
        if let ud = UserDefaults(suiteName: PassportConf.shared.groupId) {
            userDefaults = ud
        } else {
            userDefaults = UserDefaults.standard
            logger.error("UserDefaults init with suiteName failed.")
        }

        if PassportSwitch.shared.value(.keepLoginOption) {
            userDefaults.register(defaults: [keepLoginInKey: true])
        }
        // 过渡期: 新老一起判断. DataIdentifier 存在正常变动的可能. 逐步迁移到新的 DeviceIdentifier
        //判断老的标识是否有效
        let dataIdentifierValid = checkDataIdentifierValid()
        //判断新的标识是否有效
        let deviceIdentifierValid = checkDeviceIdentifierValid()
        // 新老都不一致时,才认为无效
        if (!dataIdentifierValid && !deviceIdentifierValid) {
            self.isDataValid = false
        } else {
            self.isDataValid = true
        }
    }

    private var _currentUserID: SafeAtomic<String?> = nil + .readWriteLock
    private var currentUserID: String? {
        get {
            if let uid = _currentUserID.value, !uid.isEmpty {
                return uid
            }
            if keepLoginIn {
                if PassportSwitch.shared.value(.encryptAuthData) {
                    guard var infoData = userDefaults.data(forKey: currentUserIDKey) else {
                        logger.error("get currentUserID from userDefaults with nil")
                        return nil
                    }
                    do {
                        infoData = try aes(.decrypt, infoData)
                        guard let uid = String(data: infoData, encoding: .utf8) else {
                            logger.error("decripted currentUserID with nil")
                            return nil
                        }
                        _currentUserID.value = uid
                        return uid
                    } catch {
                        userDefaults.removeObject(forKey: currentUserIDKey)
                        logger.error("get userId has an error: \(error)")
                        return nil
                    }
                } else {
                    guard let currentUserID = userDefaults.string(forKey: currentUserIDKey) else {
                        logger.error("get currentUserID from userDefaults with nil")
                        return nil
                    }
                    logger.info("get currentUserID is \(currentUserID)")
                    _currentUserID.value = currentUserID
                    return currentUserID
                }

            }
            return nil
        }
        set {
            _currentUserID.value = newValue
            if keepLoginIn {
                logger.info("set currentUserID is \(String(describing: newValue))")
                if PassportSwitch.shared.value(.encryptAuthData) {
                    if newValue == nil {
                        userDefaults.set(nil, forKey: currentUserIDKey)
                        userDefaults.synchronize()
                    }
                    guard var infoData = newValue?.data(using: .utf8) else {
                        logger.error("uid can't encode utf8")
                        return
                    }
                    do {
                        infoData = try aes(.encrypt, infoData)
                        userDefaults.set(infoData, forKey: currentUserIDKey)
                        userDefaults.synchronize()
                        logger.info("set currentUseID is: \(infoData)")
                    } catch let error {
                        userDefaults.removeObject(forKey: currentUserIDKey)
                        logger.error("set currentUseID has an error: \(error)")
                    }

                } else {
                    userDefaults.set(newValue, forKey: currentUserIDKey)
                    userDefaults.synchronize()
                }

            }
        }
    }

    private var v3ConfigEnv: String {
        get {
            if let value = userDefaults.string(forKey: v3ConfigEnvKey) {
                return value
            } else {
                let configEnv: String
                if ReleaseConfig.isLark {
                    configEnv = V3ConfigEnv.lark
                } else if ReleaseConfig.isFeishu {
                    configEnv = V3ConfigEnv.feishu
                } else {
                    configEnv = V3ConfigEnv.feishu
                }
                return configEnv
            }
        }
        set {
            userDefaults.set(newValue, forKey: v3ConfigEnvKey)
        }
    }

    private var keepLoginIn: Bool {
        get {
            if PassportSwitch.shared.value(.keepLoginOption) {
                return userDefaults.bool(forKey: keepLoginInKey)
            } else {
                return true
            }
        }
        set {
            if PassportSwitch.shared.value(.keepLoginOption) {
                userDefaults.set(newValue, forKey: keepLoginInKey)
            }
        }
    }

    private var _userInfoMap: [String: V3UserInfo] = [:]
    var userInfoMap: [String: V3UserInfo] {
        get {
            lock.lock()
            defer { lock.unlock() }
            if !self._userInfoMap.isEmpty {
                return self._userInfoMap
            }
            if keepLoginIn {
                do {
                    guard var infoData = userDefaults.data(forKey: accountKey) else {
                        logger.error("get all UserInfo from userDefaults with nil")
                        return [:]
                    }
                    let decoder = JSONDecoder()
                    do {
                        if PassportSwitch.shared.value(.encryptAuthData) {
                            infoData = try aes(.decrypt, infoData)
                        }
                        let userInfoMap = try decoder.decode([String: V3UserInfo].self, from: infoData)
                        logger.info("get all UserInfoMap is: \(userInfoMap)")
                        self._userInfoMap = userInfoMap
                        return userInfoMap
                    } catch {
                        let userInfoMap = try decoder.decode([String: AccountUserInfo].self, from: infoData)
                        logger.info("get all UserInfo is: \(userInfoMap)")

                        var newUserInfoMap: [String: V3UserInfo] = [:]
                        userInfoMap.forEach { (userId, accountUserInfo) in
                            newUserInfoMap[userId] = accountUserInfo.toV3UserInfo()
                        }
                        self._userInfoMap = newUserInfoMap
                        return newUserInfoMap
                    }
                } catch let error {
                    userDefaults.removeObject(forKey: accountKey)
                    logger.error("get all UserInfo has an error: \(error)")
                }
            }
            return [:]
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            self._userInfoMap = newValue
            if keepLoginIn {
                do {
                    let encoder = JSONEncoder()
                    var infoData = try encoder.encode(newValue)
                    if PassportSwitch.shared.value(.encryptAuthData) {
                        infoData = try aes(.encrypt, infoData)
                    }
                    userDefaults.set(infoData, forKey: accountKey)
                    userDefaults.synchronize()
                    logger.info("set all UserInfo is: \(infoData)")
                } catch let error {
                    userDefaults.removeObject(forKey: accountKey)
                    logger.error("set UserInfo has an error: \(error)")
                }
            }
        }
    }

    private var _derivedUserMap: SafeAtomic<[String: V3DerivedUser]> = [:] + .readWriteLock
    private var derivedUserMap: [String: V3DerivedUser] {
        get {
            if !_derivedUserMap.value.isEmpty {
                return _derivedUserMap.value
            }
            if keepLoginIn {
                do {
                    guard var infoData = userDefaults.data(forKey: derivedUserKey) else {
                        logger.error("get all derivedUsers from userDefaults with nil")
                        return [:]
                    }
                    if PassportSwitch.shared.value(.encryptAuthData) {
                        infoData = try aes(.decrypt, infoData)
                    }
                    let decoder = JSONDecoder()
                    let derivedUserMap = try decoder.decode([String: V3DerivedUser].self, from: infoData)
                    logger.info("get all derivedUsers is: \(derivedUserMap)")
                    self._derivedUserMap.value = derivedUserMap
                    return derivedUserMap
                } catch let error {
                    userDefaults.removeObject(forKey: derivedUserKey)
                    logger.error("get all derivedUsers has an error: \(error)")
                }
            }
            return [:]
        }
        set {
            self._derivedUserMap.value = newValue
            if keepLoginIn {
                do {
                    let encoder = JSONEncoder()
                    var infoData = try encoder.encode(newValue)
                    if PassportSwitch.shared.value(.encryptAuthData) {
                        infoData = try aes(.encrypt, infoData)
                    }
                    userDefaults.set(infoData, forKey: derivedUserKey)
                    userDefaults.synchronize()
                    logger.info("set all derivedUsers is: \(infoData)")
                } catch let error {
                    userDefaults.removeObject(forKey: derivedUserKey)
                    logger.error("set derivedUsers has an error: \(error)")
                }
            }
        }
    }

    private var countryCode: String? {
        get {
            return userDefaults.string(forKey: countryCodeKey)
        }
        set {
            userDefaults.set(newValue, forKey: countryCodeKey)
        }
    }

    private var loggedInMethod: SuiteLoginMethod? {
        get {
            if let method = userDefaults.string(forKey: loggedInMethodKey) {
                return SuiteLoginMethod(rawValue: method)
            } else {
                return nil
            }
        }
        set {
            userDefaults.set(newValue?.rawValue, forKey: loggedInMethodKey)
        }
    }

    private var configInfo: V3ConfigInfo? {
        get {
            do {
                guard let infoData = userDefaults.data(forKey: configInfoKey) else {
                    logger.error("get configInfo from userDefaults with nil")
                    return nil
                }
                let decoder = JSONDecoder()
                let configInfo = try decoder.decode(V3ConfigInfo.self, from: infoData)
                logger.info("get configInfo is: \(configInfo)")
                return configInfo
            } catch let error {
                userDefaults.removeObject(forKey: configInfoKey)
                logger.error("get configInfo with error: \(error)")
                return nil
            }
        }
        set {
            do {
                let encoder = JSONEncoder()
                let infoData = try encoder.encode(newValue)
                userDefaults.set(infoData, forKey: configInfoKey)
                userDefaults.synchronize()
                logger.info("set configInfo is: \(infoData)")
            } catch let error {
                userDefaults.removeObject(forKey: configInfoKey)
                logger.error("set configINfo with error: \(error)")
            }
        }
    }

    /// identify data, help to handle data sychronization when device change
    private var dataIdentifier: String? {
        get {
            return userDefaults.string(forKey: dataIdentifierKey)
        }
        set {
            userDefaults.set(newValue, forKey: dataIdentifierKey)
        }
    }

    private var deviceIdentifier: String? {
        get {
            return userDefaults.string(forKey: deviceIdentifierKey)
        }
        set {
            userDefaults.set(newValue, forKey: deviceIdentifierKey)
        }
    }
    // 老的标识. 使用的是 modelName. e.g iPhone13,2/iPhone 11. 存在变动的问题.
    func checkDataIdentifierValid() -> Bool {

        if let identifier = self.dataIdentifier {
            let current = makeDataIdentifier()
            let valid = identifier == current
            if !valid {
                logger.warn("store data not valid current id:\(current) stored id: \(identifier)")
            }
            return valid
        } else {
            self.dataIdentifier = makeDataIdentifier()
            return true
        }
    }
    // 因为老的标识会有变动的情况存在, 启用新的标识.用来区分是否迁移了设备. 过渡期: 新老一起判断
    func checkDeviceIdentifierValid() -> Bool {

        if let identifier = self.deviceIdentifier {
            let current = makeDeviceIdentifier()
            let valid = identifier == current
            if !valid {
                logger.warn("store device not valid current id:\(current) stored id: \(identifier)")
            }
            return valid
        } else {
            self.deviceIdentifier = makeDeviceIdentifier()
            return true
        }
    }

    /// sso域名前缀
    /// ${ssoPrefix}.feishu.cn
    /// e.g.,  zijie.feishu.cn
    private var ssoPreffix: String? {
        get {
            return userDefaults.string(forKey: ssoPrefixKey)
        }
        set {
            userDefaults.set(newValue, forKey: ssoPrefixKey)
        }
    }

    /// sso域名后缀
    /// e.g.,  ".feishu.cn", ".larksuite.com"
    private var ssoSuffix: String? {
        get {
            return userDefaults.string(forKey: ssoSuffixKey)
        }
        set {
            userDefaults.set(newValue, forKey: ssoSuffixKey)
        }
    }

    private func removeAll() {
        for key in [accountKey, currentUserIDKey] {
            userDefaults.removeObject(forKey: key)
            UserDefaults.standard.removeObject(forKey: key)
        }
        userDefaults.synchronize()
        UserDefaults.standard.synchronize()
    }

    // MARK: global account

    private var userLoginConfig: V3UserLoginConfig? {
        get {
            guard let data = userDefaults.data(forKey: loginConfigKey) else {
                return nil
            }
            return try? JSONDecoder().decode(V3UserLoginConfig.self, from: data)
        }
        set {
            let data = try? JSONEncoder().encode(newValue)
            userDefaults.set(data, forKey: loginConfigKey)
            userDefaults.synchronize()
        }
    }

    private(set) var isDataValid: Bool = true

    func reset() {
        deviceService.reset()
        removeAll()
        dataIdentifier = makeDataIdentifier()
        deviceIdentifier = makeDeviceIdentifier()
        isDataValid = true
    }

}

extension SuiteLoginStore {

    var isLoggedIn: Bool {
        if let currentUserId = self.currentUserID,
           let user = self.userInfoMap[currentUserId] {
            if let session = user.session,
               !session.isEmpty {
                return true
            }
            return false
        } else {
            return false
        }
    }

}

/// generate data identifier according to current device
@inline(__always)
private func makeDataIdentifier() -> String {
    return UIDevice.current.lu.modelName()
}

@inline(__always)
private func makeDeviceIdentifier() -> String {
    var systemInfo = utsname()
    uname(&systemInfo)
    let mirror = Mirror(reflecting: systemInfo.machine)
    let identifier = mirror.children.reduce("") { identifier, element in
        guard let value = element.value as? Int8, value != 0 else { return identifier }
        return identifier + String(UnicodeScalar(UInt8(value)))
    }
    return identifier
}

@inline(__always)
func genKey(_ salt: String) -> String {
    let uuid = UUIDManager.shared.uuid.value
    let keyValue = "\(uuid)_\(salt)"
    let str = keyValue.cString(using: String.Encoding.utf8)
    let strLen = CC_LONG(keyValue.lengthOfBytes(using: String.Encoding.utf8))
    let digestLen = Int(CC_MD5_DIGEST_LENGTH)
    let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLen)
    // swiftlint:disable ForceUnwrapping
    CC_MD5(str!, strLen, result)
    // swiftlint:enable ForceUnwrapping
    let hash = NSMutableString()
    for i in 0..<digestLen {
        hash.appendFormat("%02x", result[i])
    }
    result.deallocate()

    return String(format: hash as String)
}

extension SuiteLoginStore: PassportStoreMigratable {
    func startMigration() -> Bool {
        let passportStore = PassportStore.shared
        
        passportStore.configEnv = v3ConfigEnv
        passportStore.keepLogin = keepLoginIn
        passportStore.regionCode = countryCode
        passportStore.loginMethod = loggedInMethod
        passportStore.configInfo = configInfo
        passportStore.ssoPrefix = ssoPreffix
        passportStore.ssoSuffix = ssoSuffix
        passportStore.userLoginConfig = userLoginConfig
        passportStore.foregroundUserID = currentUserID // user:current
        
        if let currentUserId = self.currentUserID,
           let v3User = self.userInfoMap[currentUserId] {
            if let tenant = v3User.tenant {
                let responseTenant = V4ResponseTenant(id: tenant.id, name: tenant.name, i18nNames: nil, iconURL: tenant.iconUrl, iconKey: "", tag: tenant.tag, brand: TenantBrand.feishu, geo: nil, domain: tenant.domain, fullDomain: tenant.fullDomain)
                let responseUser = V4ResponseUser(id: v3User.id, name: v3User.name, displayName: v3User.name, i18nNames: nil, i18nDisplayNames: nil, status: .unknown, avatarURL: v3User.avatarUrl, avatarKey: v3User.avatarKey, tenant: responseTenant, createTime: 0, credentialID: "", unit: v3User.unit, geo: "", excludeLogin: false, userCustomAttr: [], isTenantCreator: nil)
                
                let deviceLoginID = DeviceInfoStore().deviceLoginId
                passportStore.addActiveUser(V4UserInfo(user: responseUser, currentEnv: v3User.env, logoutToken: v3User.logoutToken, suiteSessionKey: v3User.session, suiteSessionKeyWithDomains: v3User.sessions, deviceLoginID: deviceLoginID, isAnonymous: false, isSessionFirstActive: nil))
            }
        } else {
            logger.error("PassportStore migration failed to mirgrate SuiteLoginStore: current user is nil, userID: \(String(describing: self.currentUserID))")
            return false
        }
        
        // Clear old store
        userDefaults.removeObject(forKey: v3ConfigEnvKey)
        userDefaults.removeObject(forKey: keepLoginInKey)
        userDefaults.removeObject(forKey: countryCodeKey)
        userDefaults.removeObject(forKey: loggedInMethodKey)
        userDefaults.removeObject(forKey: configInfoKey)
        userDefaults.removeObject(forKey: dataIdentifierKey)
        userDefaults.removeObject(forKey: ssoPrefixKey)
        userDefaults.removeObject(forKey: ssoSuffixKey)
        userDefaults.removeObject(forKey: loginConfigKey)
        userDefaults.removeObject(forKey: currentUserIDKey)
        userDefaults.removeObject(forKey: accountKey)

        return true
    }
}
