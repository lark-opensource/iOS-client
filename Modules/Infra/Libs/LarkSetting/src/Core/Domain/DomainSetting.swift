//
//  DomainSetting.swift
//  LarkAppConfig
//
//  Created by Supeng on 2021/6/30.
//

import Foundation
import RxSwift
import RxCocoa
import LarkCache
import LKCommonsLogging
import LarkCombine
import EEAtomic
import LarkReleaseConfig
import LarkEnv
import ThreadSafeDataStructure
import LarkAccountInterface
import LarkContainer
import RustPB

// swiftlint:disable no_space_in_method_call

/// 域名配置的别名
public typealias DomainSetting = [DomainKey: [String]]
public typealias DomainPreUpdateHandle = ((new: DomainSetting, old: DomainSetting)) -> Void

public struct DomainPreUpdateHandler {
    let handle: DomainPreUpdateHandle // domain数据更新前执行的同步任务
    let priority: Int // 优先级,值越大越先执行
}


/// 域名管理类，单例，提供域名获取接口
public final class DomainSettingManager {
    private static let logger = Logger.log(DomainSettingManager.self, category: "LarkSetting")

    private let onceToken = AtomicOnce()
    private let domainRxSubject = PublishSubject<Void>()
    private let domainCombineSubject = PassthroughSubject<Void, Never>()
    private let lock = UnfairLock()
    private let packageBrand = ReleaseConfig.isLark ? "lark" : "feishu"
    private var domainPreUpdateHandlers: [DomainPreUpdateHandler] = []
    private static let userDomainPrefix = "user_domain_"

    /// 当前域名配置及其对应环境
    private let currentDomainSettingMap: SafeDictionary<String, DomainSetting> = [:] + .readWriteLock
    private let userDomainsettingRxSubject: SafeDictionary<String, PublishSubject<Void>> = [:] + .readWriteLock

    private var _defaultDomain: DomainSetting?
    private var defaultDomain: DomainSetting {
        onceToken.once {
            // 优先根据当前环境取默认域名，inhouse包由于打进去所有域名所以理论上都能拿到，线上包可能出现拿不到的情况，兜底到唯一的一份默认域名
            _defaultDomain = readDefaultDomainFromPackage(with: EnvManager.env, and: EnvManager.env.brand) ??
            readDefaultDomainFromPackage(with: EnvManager.getPackageEnv(), and: packageBrand)
        }
        Self.logger.info("默认TTApplog域名\((_defaultDomain?[.ttApplog] ?? []).joined(separator: ","))")
        Self.logger.info("默认TNC域名\((_defaultDomain?[.ttnetTNC] ?? []).joined(separator: ","))")
        return _defaultDomain ?? [:]
    }

    private func readDefaultDomainFromPackage(with env: Env, and brand: String) -> DomainSetting? {
        let settingDescription = Env.settingDescription(type: env.type, unit: env.unit, brand: brand)
        let domainSetting = try? SettingStorage
            .setting(with: "",
                     type: [String: [String]].self,
                     key: "\(settingDescription.isEmpty ? "" : (settingDescription + "_"))biz_domain_config",
                     decodeStrategy: .convertFromSnakeCase,
                     useDefaultSetting: true)
        guard let domains = domainSetting else { return nil }

        return Dictionary(uniqueKeysWithValues: domains.map { (DomainKey(stringLiteral: $0.key), $0.value) })
    }

    private init() {}

    /// 从磁盘中获取域名
    func getDomainSettingFromDisk(with env: Env) -> DomainSetting? {
        DiskCache.object(of: DomainSetting.self, key: env.settingDescription) ?? {
            Self.logger.error("Failed to read new disk cache, try to read old cache")
            return DiskCache.object(of: DomainSetting.self, key: env.legacySettingDescription)
        }()
    }

    private func beforeUpdate(new: DomainSetting, old: DomainSetting) {
        for handler in domainPreUpdateHandlers {
            handler.handle((new: new, old: old))
        }
    }

    func getDomainByEnv(with env: Env) -> DomainSetting {
        // 1. 从内存读 env/packageEnv
        if let domainSetting = currentDomainSettingMap[env.settingDescription]  {
            Self.logger.debug("get domain Setting by env domain from memory, env is: \(env.settingDescription)")
            return domainSetting
        }
        // 2. 从磁盘读
        if let domainSettingMap = getDomainSettingFromDisk(with: env) {
            // 尝试从磁盘缓存中读取，并给内存缓存赋值
            Self.logger.info("n_action_domain_setting_from_disk_cache, env: \(env.settingDescription)")
            currentDomainSettingMap[env.settingDescription] = domainSettingMap
            return domainSettingMap
        } else {
            Self.logger.info("n_action_domain_setting_from_default_domain_no_cache")
            currentDomainSettingMap[env.settingDescription] = defaultDomain
            Self.logger.debug("package defaultDomain is: \(defaultDomain.count)")
            return defaultDomain
        }
    }

    func getUserDomainSettings(
        with userID: String,
        fallback userEnv: Env
    ) -> DomainSetting {
        Self.logger.debug("domain Setting get user domain: \(userID)")
        return currentDomainSettingMap[userID] ?? {
            if let userDomain = getUserDomainSettingFromDisk(with: userID) {
                Self.logger.debug("get userDomain success, userID: \(userID), \(userDomain.count)")
                currentDomainSettingMap[userID] = userDomain
                return userDomain
            }else {
                let userEnvDomain = getDomainByEnv(with: userEnv)
                currentDomainSettingMap[userID] = userEnvDomain
                Self.logger.debug("get userEnvDomain success, \(userEnvDomain.count)")
                return userEnvDomain
            }
        }()
    }

    func getUserDomainSettingFromDisk(with userID: String) -> DomainSetting? {
        return DiskCache.object(of: DomainSetting.self, key: Self.userDomainPrefix + userID)
    }

    func observeDomainSettingUpdate(with userID: String) -> Observable<()> {
        return userDomainsettingRxSubject[userID]?.asObserver() ?? {
            let subject = PublishSubject<Void>()
            userDomainsettingRxSubject[userID] = subject
            return subject.asObserver()
        }()
    }

    func triggerDomainSettingUpdate(with userID: String) {
        userDomainsettingRxSubject[userID]?.onNext(())
        Self.logger.debug("triggerDomainSettingUpdate success, userID: \(userID)")
    }
}

// MARK: public interfaces
public extension DomainSettingManager {
    /// shared
    static let shared = DomainSettingManager()

    /// 当前域名配置，返回优先级：内存缓存 > 磁盘缓存 > 默认
    /// 仅支持前台账号, 后台账号请用UserDomainService
    var currentSetting: DomainSetting {
        // 取前台账号域名
        let currentEnv = EnvManager.env
        if let foregroundUserID = Container.shared.resolve(AccountService.self)?.foregroundUser?.userID {
            Self.logger.debug("domain Setting get foregroundUserID success")
            return getUserDomainSettings(with: foregroundUserID, fallback: currentEnv)
        }
        Self.logger.warn("domain Setting get foregroundUserID error, \(EnvManager.env.settingDescription)")
        return getDomainByEnv(with: currentEnv)
    }

    /// 域名更新的信号
    var domainCombineSubjectPublisher: AnyPublisher<Void, Never> { domainCombineSubject.eraseToAnyPublisher() }
    /// 域名更新的信号
    var domainObservable: Observable<Void> { domainRxSubject.asObservable() }

    /// 根据env unit brand从磁盘中获取指定的域名, 提供给 Passport 使用（注册场景下需要指定使用包环境），没有指定环境会返回兜底域名（包域名）
    ///
    /// - Parameters:
    ///   - env: 域名的环境
    ///   - barnd: 域名的MG brand
    /// - Returns: 环境对应的域名配置
    func getDestinedDomainSetting(with env: Env, and brand: String) -> DomainSetting? {
        DiskCache.object(of: DomainSetting.self, key: Env.settingDescription(type: env.type, unit: env.unit, brand: brand))
        ?? readDefaultDomainFromPackage(with: env, and: brand)
    }

    /// 更新域名配置，同步更新内存缓存和磁盘缓存
    ///
    /// - Parameters:
    ///   - domain: 域名配置字典
    ///   - env: 域名对应的环境
    func update(domain: DomainSetting, envString: String) {
        guard !domain.isEmpty else { return }
        currentDomainSettingMap[envString] = domain

        Self.logger.info("n_action_domain_setting_push_update",
                         additionalData: ["passportAccounts": "\(String(describing: domain[.passportAccounts]))",
                                          "ttnetTNC": "\(String(describing: domain[.ttnetTNC]))",
                                          "env": envString])

        DiskCache.setObject(of: domain, key: envString)
    }

    /// 注册域名更新前执行的同步任务
    ///
    /// - Parameters:
    ///   - withPriority: `Int`类型的值, 表示任务执行优先级, 值越大越先被执行, 默认为1
    ///   - handle: 闭包任务, 参数类型为(new, old), 分别表示新域名数据和旧域名数据
    func registerDomainPreUpdateHandler(whitPriority priority: Int = 1, _ handle: @escaping DomainPreUpdateHandle) {
        lock.lock()
        defer { lock.unlock() }
        domainPreUpdateHandlers.append(DomainPreUpdateHandler(handle: handle, priority: priority))
        domainPreUpdateHandlers.sort { $0.priority > $1.priority }
    }

    /// 在前台域名执行前更新
    func beforeFroniterDomainUpdate(domain: DomainSetting) {
        lock.lock()
        defer { lock.unlock() }
        beforeUpdate(new: domain, old: currentSetting)
    }

    /// 触发前台账号域名更新事件
    func triggerFroniterDomainUpdate() {
        lock.lock()
        defer { lock.unlock() }
        domainRxSubject.onNext(())
        domainCombineSubject.send(())
    }

    // 更新用户域名内存和磁盘
    /// - Parameters:
    ///     - userID: String 用户ID
    ///     - new domainSetting: DomainSetting 新域名配置
    /// - Returns: DomainSetting结构
    func updateUserDomainSettings(with userID: String, new domainSetting: DomainSetting) {
        currentDomainSettingMap[userID] = domainSetting
        DiskCache.setObject(of: domainSetting, key: Self.userDomainPrefix + userID)
        Self.logger.debug("updateUserDomainSettings success, userID: \(userID)")
        triggerDomainSettingUpdate(with: userID)
    }

    /// DomainSetting结构转换方法
    /// - Parameters:
    ///     - domains: RustPB.Basic_V1_DomainSettings
    /// - Returns: DomainSetting结构
    static func toDomainSettings(domains: RustPB.Basic_V1_DomainSettings) -> DomainSetting {
        return Dictionary(
            uniqueKeysWithValues: domains.pairs.map { (DomainKey(stringLiteral: $0.aliasStr), $0.domains) }
        )
    }
}
