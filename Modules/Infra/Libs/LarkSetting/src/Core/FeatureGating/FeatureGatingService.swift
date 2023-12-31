//
//  FeatureGatingService.swift
//  LarkSetting
//
//  Created by 王元洵 on 2022/8/4.
//

import Foundation
import LarkContainer
import RxSwift
import LarkCombine
import LKCommonsLogging
import ThreadSafeDataStructure

/// 注册进容器的FG服务
public protocol FeatureGatingService {
    /// 获取生命周期内不变的FG
    /// 根据type取FG的值，优先返回debug页面修改的值，其次是内存缓存--磁盘缓存--打包内置
    ///
    /// - Parameters:
    ///   - key: FeatureGatingManager.Key，可传字符串字面量
    /// - Returns: FG的bool值
    ///
    /// ```swift
    /// let someFG = resolver.resolve(FeatureGatingService.self).staticFeatureGatingValue("someKey")
    /// ```
    func staticFeatureGatingValue(with key: FeatureGatingManager.Key) -> Bool

    /// 获取生命周期内可变的FG
    /// 根据type取FG的值，优先返回debug页面修改的值，其次是内存缓存--磁盘缓存--打包内置
    ///
    /// - Parameters:
    ///   - key: FeatureGatingManager.Key，可传字符串字面量
    /// - Returns: FG的bool值
    ///
    /// ```swift
    /// let someFG = resolver.resolve(FeatureGatingService.self).dynamicFeatureGatingValue("someKey")
    /// ```
    func dynamicFeatureGatingValue(with key: FeatureGatingManager.Key) -> Bool

    /// 监听生命周期内可变的FG，每次更新时向业务方推送最新的值
    ///
    /// - Parameters:
    ///   - key: FeatureGatingManager.Key，可传字符串字面量
    /// - Returns: FG的bool值
    ///
    /// ```swift
    /// let ob = resolver.resolve(FeatureGatingService.self).observe(key: "xxx").subscribe(onNext: { print($0) })
    /// ```
    func observe(key: FeatureGatingManager.Key) -> Observable<Bool>

    /// 监听生命周期内可变的FG，每次更新时向业务方推送最新的值
    ///
    /// - Parameters:
    ///   - key: FeatureGatingManager.Key，可传字符串字面量
    /// - Returns: FG的bool值
    ///
    /// ```swift
    /// let ob = resolver.resolve(FeatureGatingService.self).observe(key: "xxx").sink { print($0) }
    /// ```
    func observe(key: FeatureGatingManager.Key) -> AnyPublisher<Bool, Never>

    ///  Key粒度监听可变的FG,  FG发生变更时, 向业务方推送最新的值
    /// - Parameters:
    ///     - key:FeatureGatingManager.Key, 可传入FG Key的字符串字面量
    /// - returns: 被监听的FG Key对应的观察者对象
    /// ```swift
    /// let ob = resolver.resolve(FeatureGatingService.self).observeKey(key: "xxx")
    ///     .observeOn(MainScheduler.instance)
    ///     .subscribe(onNext: { print($0) })
    /// ```
    func observeKey(key: FeatureGatingManager.Key) -> Observable<Bool>?

    /// 登录状态下获取无用户态的FG, 支持设备did、userID维度作为灰度
    /// - 取值方式:
    ///   - 有用户身份(携带UserID): 先从线上用户态配置中取, 兜底时从包内配置中读取
    /// - Parameters:
    ///   - userID: String, 用户ID, 无用户时传空
    ///   - key: GlobalFeatureGatingKey, 无用户态FG的Key
    /// - returns: FG Key对当前用户或设备灰度的值
    func getUserGlobalFeatureGatingValue(key: GlobalFeatureGatingKey) -> Bool

    /// 订阅用户登录状态的无用户态FG值变更
    /// 支持设备did、userID维度作为灰度, 支持跨登录态访问
    /// 取值方式: 与`getUserGlobalFeatureGatingValue`方法一致
    /// 响应时机: 1.首次订阅会返回初始值 2.值变更后触发
    /// - Parameters:
    ///   - userID: String, 用户ID, 无用户时传空
    ///   - key: GlobalFeatureGatingKey, 无用户态FG的Key
    /// - returns: 登录状态下的全局FG Key的响应式对象
    func observeUserGlobalFeatureGatingKey(key: GlobalFeatureGatingKey) -> Observable<Bool>

    func getAllUserGlobalFeatureGatingKeysNeedFetch() -> [String]

    func updateUserGlobalFeatureGatings(new values: [String: Bool])
}

struct FeatureGatingServiceImpl: FeatureGatingService {

    // 容器内用户ID
    let id: String
    let userResolver: UserResolver

    init(id: String, userResolver: UserResolver) {
        self.id = id
        self.userResolver = userResolver
    }

    // 用户登录后的无用户态FG
    let userGlobalFeatureGatingManager: UserGlobalFeatureGatingManager = UserGlobalFeatureGatingManager()

    func staticFeatureGatingValue(with key: FeatureGatingManager.Key) -> Bool { FeatureGatingStorage.featureValue(of: id, key: key.rawValue, type: .static) }

    func dynamicFeatureGatingValue(with key: FeatureGatingManager.Key) -> Bool { FeatureGatingStorage.featureValue(of: id, key: key.rawValue, type: .dynamic) }

    func observe(key: FeatureGatingManager.Key) -> Observable<Bool> {
        FeatureGatingStorage.fgRxSubject.filter { $0.0 == id }.map { _ in dynamicFeatureGatingValue(with: key) }.asObservable()
    }

    func observe(key: FeatureGatingManager.Key) -> AnyPublisher<Bool, Never> {
        FeatureGatingStorage.fgCombineSubject.filter { $0.0 == id }.map { _ in dynamicFeatureGatingValue(with: key) }.eraseToAnyPublisher()
    }

    func observeKey(key: FeatureGatingManager.Key) -> Observable<Bool>? {
        return FeatureGatingStorage.observeKey(of: id, key: key.rawValue)
    }

    func getUserGlobalFeatureGatingValue(key: GlobalFeatureGatingKey) -> Bool {
        return self.userGlobalFeatureGatingManager
            .getFeatureGatingValue(key: key.stringValue)
    }

    func observeUserGlobalFeatureGatingKey(key: GlobalFeatureGatingKey) -> Observable<Bool> {
        return self.userGlobalFeatureGatingManager
            .register(key: key.stringValue)
    }

    func getAllUserGlobalFeatureGatingKeysNeedFetch() -> [String] {
        return self.userGlobalFeatureGatingManager.getAllUserGlobalFeatureGatingKeysNeedFetch()
    }

    func updateUserGlobalFeatureGatings(new values: [String: Bool]) {
        self.userGlobalFeatureGatingManager.update(userID: self.id, new: values)
    }
}

class UserGlobalFeatureGatingManager {
    private static let logger = Logger.log(UserGlobalFeatureGatingManager.self, category: "UserGlobalFeatureGatingManager")

    private let userGlobalFeatureGatingKey = "userGlobalFeatureGating"
    private var memoryCache: [String: Bool]? = nil
    private var subjects: BehaviorSubject<()> = BehaviorSubject(value: ())
    private let rwLock = SynchronizationType.readWriteLock.generateSynchronizationDelegate()

    internal func getFeatureGatingValue(key: String) -> Bool {
        onceInit()
        let featureValueFromCache: Bool? = rwLock.readOperation {
            if let values = memoryCache, !values.isEmpty {
                Self.logger.debug("userGlobalFeatureValue: key: \(key), memory cache value: \(String(describing: values[key]))")
                return values[key] ?? false
            }
            return nil
        }
        if let value = featureValueFromCache {
            Self.logger.debug("userGlobalFeatureValue: key: \(key), return memory cache value: \(value)")
            return value
        }
        let value = (try? SettingStorage.setting(
            with: "",
            type: Bool.self,
            key: key,
            decodeStrategy: .convertFromSnakeCase,
            useDefaultSetting: true)) ?? false
        // 线上配置为空, 从包内配置中读取
        Self.logger.debug("userGlobalFeatureValue: key: \(key), return package default value: \(value)")
        return value
    }

    internal func update(
        userID: String,
        new userGlobalFeatureGatings: [String: Bool]
    ) {
        Self.logger.debug("update UserGlobalFeatureGatingCache, new: \(userGlobalFeatureGatings)")
        DiskCache.setObject(of: userGlobalFeatureGatings, key: userGlobalFeatureGatingKey + userID)
        rwLock.writeOperation {
            memoryCache = userGlobalFeatureGatings
        }
        triggerUpdateEvent()
    }

    private func triggerUpdateEvent() {
        let existMemoryCache = rwLock.readOperation() {
            if let _ = memoryCache {
                return true
            }else {
                return false
            }
        }
        if existMemoryCache {
            self.subjects.onNext(())
        }
    }

    internal func register(
        key: String
    ) -> Observable<Bool> {
        return subjects.asObserver()
            .flatMap{ [weak self] _ -> Observable<Bool> in
                guard let _self = self else { return Observable.error(UserFeatureGatingError.UserFeatureGatingNotExists) }
                return Observable.just(_self.getFeatureGatingValue(key: key))
            }
            .distinctUntilChanged()
            .startWith(self.getFeatureGatingValue(key: key))
    }

    internal func getAllUserGlobalFeatureGatingKeysNeedFetch() -> [String] {
        onceInit()
        return rwLock.readOperation {
            if let cache = memoryCache {
                return cache.map{ key, _ in key }
            }else {
                return []
            }
        }
    }

    private func onceInit() {
        let isFirstInit = rwLock.readOperation {
            return memoryCache == nil
        }
        if isFirstInit {
            rwLock.writeOperation {
                if memoryCache == nil {
                    let dataFromDisk = DiskCache.object(of: [String: Bool].self, key: userGlobalFeatureGatingKey) ?? [:]
                    memoryCache = dataFromDisk
                }
            }
        }
    }
}

public enum UserFeatureGatingError: Error {
    case UserFeatureGatingNotExists
    case BarrierError
}
