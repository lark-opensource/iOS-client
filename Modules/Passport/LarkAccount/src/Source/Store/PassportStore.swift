//
//  PassportStore.swift
//  LarkAccount
//
//  Created by bytedance on 2021/6/18.
//

import Foundation
import LKCommonsLogging
import LarkReleaseConfig
import RxCocoa
import RxSwift
import ThreadSafeDataStructure
import LarkAccountInterface
import Swinject

final class PassportStore {

    // 在passport里加字段，如果需要磁盘存储，要在这里加key, 值的类型要遵守Codable
    struct PassportStoreKey {
        static let migrationStatus = PassportStorageKey<PassportStoreMigrationStatus>(key: "migrationStatus")
        static let shouldUpgradeSession = PassportStorageKey<Bool>(key: "shouldUpgradeSession")
        static let dataIdentifier = PassportStorageKey<String>(key: "dataIdentifier")
        
        static let user = PassportStorageKey<V4UserInfo>(key: "user")
        static let configEnv = PassportStorageKey<String>(key: "configEnv")
        static let configInfo = PassportStorageKey<V3ConfigInfo>(key: "configInfo")
        static let userLoginConfig = PassportStorageKey<V3UserLoginConfig>(key: "userLoginConfig")
        static let regionCode = PassportStorageKey<String>(key: "regionCode")
        static let keepLogin = PassportStorageKey<Bool>(key: "keepLogin")
        static let loginMethod = PassportStorageKey<SuiteLoginMethod>(key: "loginMethod")
        static let ssoPrefix = PassportStorageKey<String>(key: "ssoPrefix")
        static let ssoSuffix = PassportStorageKey<String>(key: "ssoSuffix")
        
        // 设备相关
        static let storedUUID = PassportStorageKey<String>(key: "storedUUID")
        static let logInstallID = PassportStorageKey<String>(key: "logInstallID")
        static let installIDMap = PassportStorageKey<[String: String]>(key: "installIDMap") // [ UNIT: ID]
        internal static let unitInstallIdMap = PassportStorageKey<[String: String]>(key: "unitInstallIdMap")
        static let deviceIDMap = PassportStorageKey<[String: String]>(key: "deviceIDMap")   // [ UNIT: ID]
        internal static let unitDeviceIdMap = PassportStorageKey<[String: String]>(key: "unitDeviceIdMap")
        static let deviceID = PassportStorageKey<String>(key: "deviceID") //统一did
        internal static let deviceId = PassportStorageKey<String>(key: "deviceId")
        static let installID = PassportStorageKey<String>(key: "installID") //统一iid
        internal static let installId = PassportStorageKey<String>(key: "installId")
        static let didChangedMap = PassportStorageKey<[String: String]>(key: "didChangedMap") //[UNIT: legacyDid]
        
        // IDP 相关
        static let indicatedIDP = PassportStorageKey<String>(key: "indicatedIDP")
        static let idpUserProfileMap = PassportStorageKey<[String : String]>(key: "idpUserProfileMap")
        static let idpAuthConfig = PassportStorageKey<IDPAuthConfigModel>(key: "idpAuthConfig")
        static let idpInternalConfig = PassportStorageKey<IDPInternalModel>(key: "idpInternalConfig")
        static let idpExternalConfig = PassportStorageKey<String>(key: "idpExternalConfig")
        
        // user 相关
        static let foregroundUserID = PassportStorageKey<String>(key: "foregroundUserID") // user:checked
        static let userIDList = PassportStorageKey<[String]>(key: "userIDList")
        static let hiddenUserIDList = PassportStorageKey<[String]>(key: "hiddenUserIDList")

        // 回滚开关
        static let enableUserScope = PassportStorageKey<Bool>(key: "enableUserScope")
        // 更新 iid 逻辑控制开关
        static let enableInstallIDUpdatedSeparately = PassportStorageKey<Bool>(key: "enableInstallIDUpdatedSeparately")
        // frontUUID开关
        static let enableUUIDAndNewStoreReset = PassportStorageKey<Bool>(key: "enableUUIDAndNewStoreReset")
        // 本地存储的凭证下的默认验证方式
        static let recordLocalVerifyMethod = PassportStorageKey<LRUQueue<MethodRecordMap>>(key: "recordLocalVerifyMethod")
        // 延迟设置 event register 开关
        static let enableLazySetupEventRegister = PassportStorageKey<Bool>(key: "enableLazySetupEventRegister")
        // TNS URL 正则
        static let tnsAuthURLRegex = PassportStorageKey<String>(key: "tnsAuthURLRegex")
        // 是否开启登录页立即注册入口
        static let enableRegisterEntry = PassportStorageKey<Bool>(key: "enableRegisterEntry")
        // 是否切换到了统一did
        static let universalDeviceServiceUpgraded = PassportStorageKey<Bool>(key: "UniversalDeviceServiceUpgraded")
        internal static let extensionUniversalDeviceServiceUpgraded = PassportStorageKey<Bool>(key: "universalDeviceServiceUpgraded")
        // 是否开启web容器根视图关闭左侧导航栏关闭按钮优化
        static let enableLeftNaviButtonsRootVCOpt = PassportStorageKey<Bool>(key: "enableLeftNaviButtonsRootVCOpt")
        // 是否开启原生webauthn 方案 注册安全密钥
        static let enableNativeWebauthnRegister =  PassportStorageKey<Bool>(key: "enableNativeWebauthnRegister")
        // 是否开启原生webauthn 方案 认证安全密钥
        static let enableNativeWebauthnAuth =  PassportStorageKey<Bool>(key: "enableNativeWebauthnAuth")
        // passportgray 灰度开关键值
        static let passportGaryMap: PassportStorageKey<[String: Bool]> = PassportStorageKey<[String: Bool]>(key: "passportGrayMap")
        // 数据擦除功能-需要擦除的user信息
        static let eraseUserScopeListKey = PassportStorageKey<[EraseUserScope]>(key: "eraseUserScopeList")
        // 数据擦除任务标识
        static let eraseTaskIdentifier = PassportStorageKey<String>(key: "eraseTaskIdentifier")
        // larkglobal注册流程降级超时时间配置
        static let globalRegistrationTimeout = PassportStorageKey<Int>(key: "globalRegistrationTimeout")
        // passport离线化配置
        static let passportOfflineConfig = PassportStorageKey<PassportOfflineConfig>(key: "passportOfflineConfig")
        /// Passport 迁移统一存储后的标记。
        internal static let universalStorageMigrationFlag = PassportStorageKey<Bool>(key: "universalStorageMigrationFlag")
    }

    static let logger = Logger.log(PassportStore.self, category: "Store")

    static let shared: PassportStore = PassportStore()

    private(set) var isDataValid: Bool = true

    private let lock = NSRecursiveLock()

    private init() {
        if let identifier = self.dataIdentifier {
            let current = self.makeDataIdentifier()
            self.isDataValid = identifier == current
            if !self.isDataValid {
                Self.logger.warn("store data not valid current id:\(current) stored id: \(identifier)")
            }
        } else {
            self.dataIdentifier = makeDataIdentifier()
            self.isDataValid = true
        }
        // foregroundUserID不是线程安全的，不过变化频率低问题不大。这里保证初始化的线程安全
        _ = self.foregroundUserID // user:checked
        
        if MultiUserActivitySwitch.enableMultipleUser {
            GlobalKvStorageServiceImpl.shared.set(key: PassportStore.PassportStoreKey.unitDeviceIdMap.cleanValue, value: deviceIDMap, userId: nil)
            GlobalKvStorageServiceImpl.shared.set(key: PassportStore.PassportStoreKey.deviceId.cleanValue, value: deviceID, userId: nil)
            GlobalKvStorageServiceImpl.shared.set(key: PassportStore.PassportStoreKey.installId.cleanValue, value: installID, userId: nil)
            GlobalKvStorageServiceImpl.shared.set(key: PassportStore.PassportStoreKey.unitInstallIdMap.cleanValue, value: installIDMap, userId: nil)
            GlobalKvStorageServiceImpl.shared.set(key: PassportStore.PassportStoreKey.extensionUniversalDeviceServiceUpgraded.cleanValue, value: universalDeviceServiceUpgraded, userId: nil)
            getUserList().forEach { userInfo in
                PassportStore.storeUserInfoToShared(userInfo: userInfo, userId: userInfo.user.id)
            }
        }
    }

    // MARK: - Properties
    lazy var migrationStatus: PassportStoreMigrationStatus = Self.value(forKey: PassportStoreKey.migrationStatus) ?? .notStarted {
        didSet {
            Self.set(migrationStatus, forKey: PassportStoreKey.migrationStatus)
        }
    }
    
    var isLoggedIn: Bool {
        if self.foregroundUser != nil { // user:checked
            return true
        } else {
            return false
        }
    }
    
    lazy var configEnv: String = {
        if let value = Self.value(forKey: PassportStoreKey.configEnv) {
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
    }() {
        didSet {
            Self.set(configEnv, forKey: PassportStoreKey.configEnv)
        }
    }
    
    func resetConfigEnv() {
        Self.set(nil, forKey: PassportStoreKey.configEnv)
    }
    
    // 15天内免登录
    lazy var keepLogin: Bool = {
        if PassportSwitch.shared.value(.keepLoginOption) {
            return Self.value(forKey: PassportStoreKey.keepLogin) ?? true
        } else {
            return true
        }
    }() {
        didSet {
            if PassportSwitch.shared.value(.keepLoginOption) {
                Self.set(keepLogin, forKey: PassportStoreKey.keepLogin)
            }
        }
    }

    lazy var regionCode: String? = Self.value(forKey: PassportStoreKey.regionCode) {
        didSet {
            Self.set(regionCode, forKey: PassportStoreKey.regionCode)
        }
    }
    
    lazy var loginMethod: SuiteLoginMethod? = Self.value(forKey: PassportStoreKey.loginMethod) {
        didSet {
            Self.set(loginMethod, forKey: PassportStoreKey.loginMethod)
        }
    }

    //获取历史登录方式
    func getRecordVerifyMethod(credentialKey: String) -> String? {
        guard let verifyMethodRecord = Self.value(forKey: PassportStoreKey.recordLocalVerifyMethod) else {
            return nil
        }
        return verifyMethodRecord.getRecord(From: credentialKey)?.verifyMethod

    }

    //记录登录方式
    func recordVerifyMethod(credentialKey: String, verifyType: String) {
        let verifyMethodRecord: LRUQueue<MethodRecordMap> = Self.value(forKey: PassportStoreKey.recordLocalVerifyMethod) ?? LRUQueue<MethodRecordMap>(capacity: 20)
        verifyMethodRecord.append(NewRecord: MethodRecordMap(key: credentialKey, verifyMethod: verifyType))
        Self.set(verifyMethodRecord, forKey: PassportStoreKey.recordLocalVerifyMethod)
    }
    
    private lazy var _configInfo: SafeAtomic<V3ConfigInfo?> = Self.value(forKey: PassportStoreKey.configInfo) + .readWriteLock
    var configInfo: V3ConfigInfo? {
        get {
            _configInfo.value
        }
        set {
            _configInfo.value = newValue
            Self.set(newValue, forKey: PassportStoreKey.configInfo)
        }
    }
    
    private lazy var dataIdentifier: String? = Self.value(forKey: PassportStoreKey.dataIdentifier) {
        didSet {
            Self.set(dataIdentifier, forKey: PassportStoreKey.dataIdentifier)
        }
    }
    
    lazy var ssoPrefix: String? = Self.value(forKey: PassportStoreKey.ssoPrefix) {
        didSet {
            Self.set(ssoPrefix, forKey: PassportStoreKey.ssoPrefix)
        }
    }
    
    lazy var ssoSuffix: String? = Self.value(forKey: PassportStoreKey.ssoSuffix) {
        didSet {
            Self.set(ssoSuffix, forKey: PassportStoreKey.ssoSuffix)
        }
    }
    
    lazy var userLoginConfig: V3UserLoginConfig? = Self.value(forKey: PassportStoreKey.userLoginConfig) {
        didSet {
            Self.set(userLoginConfig, forKey: PassportStoreKey.userLoginConfig)
        }
    }
    
    private lazy var storedUUID: String? = Self.value(forKey: PassportStoreKey.storedUUID) {
        didSet {
            Self.set(storedUUID, forKey: PassportStoreKey.storedUUID)
        }
    }
    //UUID,回到登录页会reset后重新生成，现用为服务端的FrontUserUUID
    var frontUUID: String {
        let returnUUID: String
        if let uuid = storedUUID {
            returnUUID = uuid
        } else {
            let newUUID = Foundation.UUID().uuidString
            storedUUID = newUUID
            returnUUID = newUUID
        }
        return returnUUID
    }
    
    lazy var logInstallID: String? = Self.value(forKey: PassportStoreKey.logInstallID) {
        didSet {
            Self.set(logInstallID, forKey: PassportStoreKey.logInstallID)
        }
    }

    private lazy var _deviceIDMap: SafeAtomic<[String: String]?> = Self.value(forKey: PassportStoreKey.deviceIDMap) + .readWriteLock
    var deviceIDMap: [String: String]? {
        get {
            _deviceIDMap.value
        }
        set {
            _deviceIDMap.value = newValue
            Self.set(newValue, forKey: PassportStoreKey.deviceIDMap)
            if MultiUserActivitySwitch.enableMultipleUser {
                (try? Container.shared.resolve(assert: GlobalKvStorageService.self))?.set(key: PassportStoreKey.unitDeviceIdMap.cleanValue, value: newValue, userId: nil)
            }
        }
    }
    
    // 统一did
    private lazy var _deviceID: SafeAtomic<String?> = Self.value(forKey: PassportStoreKey.deviceID) + .readWriteLock
    var deviceID: String? {
        get {
            _deviceID.value
        }
        set {
            _deviceID.value = newValue
            Self.set(newValue, forKey: PassportStoreKey.deviceID)
            //历史原因，需要同步设置统一did，后续重构后去除
            PassportProbeHelper.shared.uniDeviceID = newValue
            if MultiUserActivitySwitch.enableMultipleUser {
                (try? Container.shared.resolve(assert: GlobalKvStorageService.self))?.set(key: PassportStoreKey.deviceId.cleanValue, value: newValue, userId: nil)
            }
        }
    }
    
    // 统一iid
    private lazy var _installID: SafeAtomic<String?> = Self.value(forKey: PassportStoreKey.installID) + .readWriteLock
    var installID: String? {
        get {
            _installID.value
        }
        set {
            _installID.value = newValue
            Self.set(newValue, forKey: PassportStoreKey.installID)
            if MultiUserActivitySwitch.enableMultipleUser {
                (try? Container.shared.resolve(assert: GlobalKvStorageService.self))?.set(key: PassportStoreKey.installId.cleanValue, value: newValue, userId: nil)
            }
        }
    }
    // did变更map[unit: legacyDid]
    lazy var didChangedMap: [String: String]? = Self.value(forKey: PassportStoreKey.didChangedMap) {
        didSet {
            Self.set(didChangedMap, forKey: PassportStoreKey.didChangedMap)
        }
    }
    
    // legacy did
    func setDeviceID(deviceID: String, unit: String) {
        lock.lock()
        defer { lock.unlock() }
        
        var map = deviceIDMap ?? [String : String]()
        Self.logger.info("n_action_passport_store_DID_map_BEFORE_updating: \(map)")
        map[unit] = deviceID
        deviceIDMap = map
        Self.logger.info("n_action_passport_store_DID_map_AFTER_updating: \(map)")
        map.forEach {
            PassportProbeHelper.shared.setDeviceID($0.value, for: $0.key)
        }
    }
    
    func getDeviceID(unit: String) -> String? {
        Self.logger.info("n_action_passport_store_current_DID_map: \(deviceIDMap ?? [:])", method: .local)
        return deviceIDMap?[unit]
    }

    private lazy var _installIDMap: SafeAtomic<[String: String]?> = Self.value(forKey: PassportStoreKey.installIDMap) + .readWriteLock
    var installIDMap: [String: String]? {
        get {
            _installIDMap.value
        }
        set {
            _installIDMap.value = newValue
            Self.set(newValue, forKey: PassportStoreKey.installIDMap)
            if MultiUserActivitySwitch.enableMultipleUser {
                (try? Container.shared.resolve(assert: GlobalKvStorageService.self))?.set(key: PassportStoreKey.unitInstallIdMap.cleanValue, value: newValue, userId: nil)
            }
        }
    }

    func setInstallID(installID: String, unit: String) {
        lock.lock()
        defer { lock.unlock() }

        var map = installIDMap ?? [String : String]()
        Self.logger.info("n_action_passport_store_IID_map_BEFORE_updating: \(map)")
        map[unit] = installID
        installIDMap = map
        Self.logger.info("n_action_passport_store_IID_map_AFTER_updating: \(map)")
    }
    
    func getInstallID(unit: String) -> String? {
        Self.logger.info("n_action_passport_store_current_IID_map: \(installIDMap ?? [:])")
        return installIDMap?[unit]
    }
    
    private lazy var idpUserProfileMap: [String : String]? = Self.value(forKey: PassportStoreKey.idpUserProfileMap) {
        didSet {
            Self.set(idpUserProfileMap, forKey: PassportStoreKey.idpUserProfileMap)
        }
    }
    
    func setIDPUserProfile(profile: String, key: String) {
        lock.lock()
        defer { lock.unlock() }
        
        var map = idpUserProfileMap ?? [String : String]()
        map[key] = profile
        idpUserProfileMap = map
    }
    
    func getIDPUserProfile(key: String) -> String? {
        return idpUserProfileMap?[key]
    }
    
    lazy var indicatedIDP: String? = Self.value(forKey: PassportStoreKey.indicatedIDP) {
        didSet {
            Self.set(indicatedIDP, forKey: PassportStoreKey.indicatedIDP)
        }
    }
    
    lazy var idpAuthConfig: IDPAuthConfigModel? = Self.value(forKey: PassportStoreKey.idpAuthConfig) {
        didSet {
            Self.set(idpAuthConfig, forKey: PassportStoreKey.idpAuthConfig)
        }
    }
    
    lazy var idpInternalConfig: IDPInternalModel? = Self.value(forKey: PassportStoreKey.idpInternalConfig) {
        didSet {
            Self.set(idpInternalConfig, forKey: PassportStoreKey.idpInternalConfig)
        }
    }
    
    lazy var idpExternalConfig: String? = Self.value(forKey: PassportStoreKey.idpExternalConfig) {
        didSet {
            Self.set(idpExternalConfig, forKey: PassportStoreKey.idpExternalConfig)
        }
    }

    // 是否开启用户态改造，由 TCC 下发，为了避免 json 解析影响启动速度
    lazy var enableUserScope: Bool = Self.value(forKey: PassportStoreKey.enableUserScope) ?? true {
        didSet {
            Self.set(enableUserScope, forKey: PassportStoreKey.enableUserScope)
        }
    }
    
    // 是否开启 iid 更新改造，理由同上
    lazy var enableInstallIDUpdatedSeparately: Bool = Self.value(forKey: PassportStoreKey.enableInstallIDUpdatedSeparately) ?? V3NormalConfig.defaultEnableInstallIDUpdatedSeparately {
        didSet {
            Self.set(enableInstallIDUpdatedSeparately, forKey: PassportStoreKey.enableInstallIDUpdatedSeparately)
        }
    }

    //
    // 是否启用FrontUUID需求改动
    lazy var enableUUIDAndNewStoreReset: Bool = Self.value(forKey: PassportStoreKey.enableUUIDAndNewStoreReset) ?? V3NormalConfig.defaultEnableUUIDAndNewStoreReset {
        didSet {
            Self.set(enableUUIDAndNewStoreReset, forKey: PassportStoreKey.enableUUIDAndNewStoreReset)
        }
    }

    // 延迟设置 event register 开关
    lazy var enableLazySetupEventRegister: Bool = Self.value(forKey: PassportStoreKey.enableLazySetupEventRegister) ?? V3NormalConfig.defaultEnableLazySetupEventRegister {
        didSet {
            Self.set(enableLazySetupEventRegister, forKey: PassportStoreKey.enableLazySetupEventRegister)
        }
    }

    // 匹配 TNS 页面后使用 Passport web 容器打开使其可以使用人脸 JSAPI
    lazy var tnsAuthURLRegex: String? = Self.value(forKey: PassportStoreKey.tnsAuthURLRegex) {
        didSet {
            Self.set(tnsAuthURLRegex, forKey: PassportStoreKey.tnsAuthURLRegex)
        }
    }
    
    lazy var universalDeviceServiceUpgraded: Bool = Self.value(forKey: PassportStoreKey.universalDeviceServiceUpgraded) ?? false {
        didSet {
            if MultiUserActivitySwitch.enableMultipleUser {
                (try? Container.shared.resolve(assert: GlobalKvStorageService.self))?.set(key: PassportStoreKey.extensionUniversalDeviceServiceUpgraded.cleanValue, value: universalDeviceServiceUpgraded, userId: nil)
            }
            Self.set(universalDeviceServiceUpgraded, forKey: PassportStoreKey.universalDeviceServiceUpgraded)
            //同步更新埋点相关的字段，用于上报正确的did
            PassportProbeHelper.shared.useUniDID = universalDeviceServiceUpgraded
        }
    }

    //是否展示立即注册按钮，可能需要实时更新
    var enableRegisterEntryObservable: Observable<Bool> { enableRegisterEntryRelay.asObservable() }

    private let enableRegisterEntryRelay = BehaviorRelay<Bool>(value: false)

    lazy var enableRegisterEntry: Bool? = Self.value(forKey: PassportStoreKey.enableRegisterEntry) {
        didSet {
            Self.set(enableRegisterEntry, forKey: PassportStoreKey.enableRegisterEntry)
            enableRegisterEntryRelay.accept(enableRegisterEntry ?? false)
        }
    }

    //是否开启web容器根视图关闭左侧导航栏关闭按钮优化，可能需要实时更新
    var enableLeftNaviButtonsRootVCOptObservable: Observable<Bool> { enableLeftNaviButtonsRootVCOptRelay.asObservable() }

    private let enableLeftNaviButtonsRootVCOptRelay = BehaviorRelay<Bool>(value: false)

    lazy var enableLeftNaviButtonsRootVCOpt: Bool? = Self.value(forKey: PassportStoreKey.enableLeftNaviButtonsRootVCOpt) {
        didSet {
            Self.set(enableLeftNaviButtonsRootVCOpt, forKey: PassportStoreKey.enableLeftNaviButtonsRootVCOpt)
            enableLeftNaviButtonsRootVCOptRelay.accept(enableLeftNaviButtonsRootVCOpt ?? false)
        }
    }

    // 是否开启webauthn原生方案注册安全密钥
    lazy var enableNativeWebauthnRegister: Bool = Self.value(forKey: PassportStoreKey.enableNativeWebauthnRegister) ?? false {
        didSet {
            Self.set(enableNativeWebauthnRegister, forKey: PassportStoreKey.enableNativeWebauthnRegister)
        }
    }

    // 是否开启webauthn原生方案认证安全密钥
    lazy var enableNativeWebauthnAuth: Bool = Self.value(forKey: PassportStoreKey.enableNativeWebauthnAuth) ?? false {
        didSet {
            Self.set(enableNativeWebauthnAuth, forKey: PassportStoreKey.enableNativeWebauthnAuth)
        }
    }

    lazy var globalRegistrationTimeout: Int = Self.value(forKey: PassportStoreKey.globalRegistrationTimeout) ?? 5 {
        didSet {
            Self.set(globalRegistrationTimeout, forKey: PassportStoreKey.globalRegistrationTimeout)
        }
    }

    var passportOfflineConfigObservable: Observable<PassportOfflineConfig> { passportOfflineConfigRelay.asObservable() }

    private let passportOfflineConfigRelay = BehaviorRelay<PassportOfflineConfig>(value: .defaultConfig)

    lazy var passportOfflineConfig: PassportOfflineConfig = Self.value(forKey: PassportStoreKey.passportOfflineConfig) ?? PassportOfflineConfig.defaultConfig {
        didSet {
            Self.set(passportOfflineConfig, forKey: PassportStoreKey.passportOfflineConfig)
            passportOfflineConfigRelay.accept(passportOfflineConfig)
        }
    }

    // MARK: - User

    var foregroundUserUpdateObservable: Observable<String?> { foregroundUserUpdateRelay.asObservable() } // user:checked

    private let foregroundUserUpdateRelay = BehaviorRelay<String?>(value: nil)

    lazy var foregroundUserID: String? = Self.value(forKey: PassportStoreKey.foregroundUserID) { // user:checked
        didSet {
            Self.set(foregroundUserID, forKey: PassportStoreKey.foregroundUserID) // user:checked
            foregroundUserUpdateRelay.accept(foregroundUserID) // user:checked
        }
    }

    /// 请不要直接更新这里的 foregroundUser，使用 UserManager 中的 updateForeground() 方法
    private(set) var foregroundUser: V4UserInfo? { // user:checked
        get {
            if let userID = self.foregroundUserID { // user:checked
                return self.getUser(userID: userID)
            }
            
            return nil
        }
        
        set {
            lock.lock()
            defer { lock.unlock() }
            
            self.foregroundUserID = newValue?.userID // user:checked
            if let user = newValue {
                self.updateUser(user)
            }
        }
    }

    /// 侧边栏展示的用户列表
    /// 这里存储的用户列表不仅包含`数据信息`，也包含`排序信息`
    /// store 本身不负责内部排序的具体逻辑，这部分管理在 UserManager 中
    /// 在 store 的任何方法中处理数据或改变用户列表顺序时，请再三确认
    lazy var userIDList: [String] = Self.value(forKey: PassportStoreKey.userIDList) ?? [] {
        didSet {
            Self.set(userIDList, forKey: PassportStoreKey.userIDList)
        }
    }

    private lazy var userMap: [String: V4UserInfo] = [:]

    /// 添加 session 有效 user
    /// 新添加的 user 会被放在 session 有效列表最后
    func addActiveUser(_ user: V4UserInfo) {
        if userIDList.isEmpty {
            addUser(user, at: 0)
            return
        }
        // 如果是已存在的用户，只更新，不调整顺序
        if userIDList.contains(user.userID) {
            updateUser(user)
            return
        }
        let userList = getUserList()
        if let index = userList.lastIndex(where: { $0.userStatus == .normal }) {
            addUser(user, at: index + 1)
        } else {
            // 如果找不到最后一个 session 有效用户，就放到用户列表最前
            addUser(user, at: 0)
        }
    }

    /// 添加 session 失效 user
    /// 新添加的 user 会被放在 session 失效列表最后
    func addInactiveUser(_ user: V4UserInfo) {
        if userIDList.isEmpty {
            addUser(user, at: 0)
            return
        }
        // 如果是已存在的用户，只更新，不调整顺序
        if userIDList.contains(user.userID) {
            updateUser(user)
            return
        }
        let userList = getUserList()
        if let index = userList.lastIndex(where: { $0.userStatus != .normal }) {
            addUser(user, at: index + 1)
        } else {
            // 如果找不到最后一个 session 失效用户，就放到用户列表最后
            addUser(user, at: userIDList.count)
        }
    }

    /// 将一个已经是 active 的 user 提到`全部列表首位`
    /// 目前在切换前台用户的时候使用
    func bringActiveUserToFront(_ user: V4UserInfo) {
        lock.lock()
        defer { lock.unlock() }
        guard let index = userIDList.firstIndex(where: { $0 == user.userID }) else { return }
        let id = userIDList.remove(at: index)
        userIDList.insert(id, at: 0)
    }

    /// 将一个已经是 inactive 的 user 提到`session 失效列表首位`
    /// 目前在 session 失效的时候使用
    func bringInactiveUserToFront(_ user: V4UserInfo) {
        lock.lock()
        defer { lock.unlock() }
        guard let userIndex = userIDList.firstIndex(where: { $0 == user.userID }) else { return }
        let id = userIDList.remove(at: userIndex)
        let userList = getUserList()
        if let insertIndex = userList.lastIndex(where: { $0.userStatus != .normal }) {
            userIDList.insert(id, at: insertIndex)
        } else {
            // 如果找不到最后一个 session 失效用户，就放到用户列表最后
            userIDList.insert(id, at: userIDList.count)
        }
    }

    /// 添加用户
    /// 外部请不要直接调用这个方法，由于需要维护用户排序逻辑，请使用 addActiveUser 和 addInactiveUser 方法
    private func addUser(_ user: V4UserInfo, at index: Int) {
        lock.lock()
        defer { lock.unlock() }
        let userID = user.userID
        if !userIDList.contains(userID) {
            userIDList.insert(userID, at: index)
            Self.logger.info("Insert user: \(userID) in index: \(index).")
        }
        userMap.updateValue(user, forKey: userID)
        Self.setUserInfoToUserSpace(user, with: user.user.id)
    }

    /// 更新用户数据
    /// 这个方法`不会`调整用户在列表中的顺序，如果需要更新排序，请使用上面的 bring{}ToFront 方法
    func updateUser(_ user: V4UserInfo) {
        lock.lock()
        defer { lock.unlock() }
        let userID = user.userID
        if !userIDList.contains(userID) {
            Self.logger.info("Cannot find user during updating for userID: \(userID)")
            return
        }
        userMap.updateValue(user, forKey: userID)
        Self.setUserInfoToUserSpace(user, with: user.user.id)
    }

    func removeUser(userID: String) {
        lock.lock()
        defer { lock.unlock() }
        
        userIDList = userIDList.filter { $0 != userID }
        userMap.removeValue(forKey: userID)
        Self.removeUserInfo(userID)
    }

    func getUser(userID: String) -> V4UserInfo? {
        lock.lock()
        defer { lock.unlock() }
        
        if let user = userMap[userID] {
            return user
        }
        if let user = Self.userInfoFromUserSpace(userID) {
            userMap.updateValue(user, forKey: userID)
            return user
        }
        userIDList = userIDList.filter { $0 != userID }
        return nil
    }

    func getUserList() -> [V4UserInfo] {
        lock.lock()
        defer { lock.unlock() }
        
        // TODO: Keep Login?
        return userIDList.compactMap { getUser(userID: $0) }
    }

    // MARK: Hidden User

    private lazy var hiddenUserMap: [String: V4UserInfo] = [:]

    /// 记录`登出后`的用户列表，用于侧边栏筛选真正需要显示的用户
    lazy var hiddenUserIDList: [String] = Self.value(forKey: PassportStoreKey.hiddenUserIDList) ?? [] {
        didSet {
            Self.set(hiddenUserIDList, forKey: PassportStoreKey.hiddenUserIDList)
        }
    }

    func addHiddenUser(_ user: V4UserInfo) {
        lock.lock()
        defer { lock.unlock() }
        
        let userID = user.userID
        if !hiddenUserIDList.contains(userID) {
            hiddenUserIDList = hiddenUserIDList + [userID]
        }
        hiddenUserMap.updateValue(user, forKey: userID)
    }

    func removeHiddenUser(userID: String) {
        lock.lock()
        defer { lock.unlock() }
        
        hiddenUserIDList = hiddenUserIDList.filter { $0 != userID }
        hiddenUserMap.removeValue(forKey: userID)
    }

    func getHiddenUser(userID: String) -> V4UserInfo? {
        lock.lock()
        defer { lock.unlock() }
        
        if let user = hiddenUserMap[userID] {
            return user
        }

        if let user = Self.userInfoFromUserSpace(userID) {
            hiddenUserMap.updateValue(user, forKey: userID)
            return user
        }
        hiddenUserIDList = hiddenUserIDList.filter { $0 != userID }
        return nil
    }

    func getHiddenUserList() -> [V4UserInfo] {
        lock.lock()
        defer { lock.unlock() }
        
        return hiddenUserIDList.flatMap { getHiddenUser(userID: $0) }
    }
    
    /// **不要删除 migrationStatus**
    func removeAllData() {
        lock.lock()
        defer { lock.unlock() }
        
        resetConfigEnv()
        configInfo = nil
        userLoginConfig = nil
        regionCode = nil
        userLoginConfig = nil
        regionCode = nil
        keepLogin = true
        ssoPrefix = nil
        ssoSuffix = nil
        
        // 设备相关
        storedUUID = nil
        installIDMap = nil
        deviceIDMap = nil
        
        // IDP 相关
        indicatedIDP = nil
        idpUserProfileMap = nil
        idpAuthConfig = nil
        idpInternalConfig = nil
        idpExternalConfig = nil
        
        // User 相关
        userIDList.forEach {
            self.removeUser(userID: $0)
        }
        userIDList = []
        userMap = [:]
        hiddenUserIDList.forEach {
            self.removeHiddenUser(userID: $0)
        }
        hiddenUserIDList = []
        hiddenUserMap = [:]
        foregroundUserID = nil // user:checked

    }

    // 仅提供给 device info store 使用
    func removeDeviceData() {
        installIDMap = nil
        deviceIDMap = nil
    }
    
    func reset() {
        Self.logger.info("n_action_passport_store_reset")
        removeAllData()
        dataIdentifier = self.makeDataIdentifier()
        isDataValid = true
    }
}

extension PassportStore {
    @inline(__always)
    //使用 modelName rawValue(iPhone 14,2), 飞书公共组件里的是转换后的 (iPhone 13 Pro)
    private func makeDataIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let mirror = Mirror(reflecting: systemInfo.machine)
        let identifier = mirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
}
