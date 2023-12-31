//
//  GlobalFeatureGatingService.swift
//  LarkSetting
//
//  Created by ByteDance on 2023/10/30.
//

import Foundation
import RxSwift
import Swinject
import LKCommonsLogging
import ThreadSafeDataStructure
import EEAtomic

public protocol GlobalFeatureGatingService {

    /// 获取无用户态的FG的值, 只支持设备did作为灰度
    /// - Parameters:
    ///   - key: GlobalFeatureGatingKey, 无用户态FG的Key
    /// - returns: 无用户态FG Key对当前设备灰度的值
    /// 先从线上静态配置中取, 兜底时从包内配置中取
    func getGlobalFeatureGatingValue(key: GlobalFeatureGatingKey) -> Bool

    /// 监听无用户态的FG, 只支持设备did作为灰度
    /// - Parameters:
    ///   - key: GlobalFeatureGatingKey, 无用户态FG的Key
    /// - returns: 无用户态FG Key对当前设备灰度的值
    /// 先从线上静态配置中取, 兜底时从包内配置中取
    func observe(key: GlobalFeatureGatingKey) -> Observable<Bool>?

    func update(new globalFeatureGatings: [String: Bool])

    func getGlobalFeatureGatingKeysNeedFetch() -> [String]
}

struct GlobalFeatureGatingServiceImpl: GlobalFeatureGatingService {
    let resolver: Resolver
    let manager: GlobalFeatureGatingManager

    init(resolver: Resolver) {
        self.resolver = resolver
        self.manager = GlobalFeatureGatingManager.shared
    }

    func getGlobalFeatureGatingValue(key: GlobalFeatureGatingKey) -> Bool {
        self.manager.globalFeatureValue(of: key)
    }

    func observe(key: GlobalFeatureGatingKey) -> Observable<Bool>? {
        self.manager.register(key: key)
    }

    func update(new globalFeatureGatings: [String: Bool]) {
        self.manager.update(new: globalFeatureGatings)
        self.manager.triggerUpdateEvent()
    }

    func getGlobalFeatureGatingKeysNeedFetch() -> [String] {
        return self.manager.allGlobalFeatureGatingKeys()
    }
}

public class GlobalFeatureGatingManager {
    private static let logger = Logger.log(GlobalFeatureGatingManager.self, category: "GlobalFeatureGatingCache")
    private let globalFeatureGatingKey = "globalFeatureGating"
    private let rwLock = SynchronizationType.readWriteLock.generateSynchronizationDelegate()
    private var globalFeatureGatingMemoryCache: [String: Bool]?
    private let globalSubjects: BehaviorSubject<()> = BehaviorSubject(value: ())
    private let lock = UnfairLock()

    public static let shared = GlobalFeatureGatingManager()

    /// 获取无用户态FG值
    public func globalFeatureValue(of globalFeatureGatingKey: GlobalFeatureGatingKey) -> Bool {
        ensureDataExists()
        let key = globalFeatureGatingKey.stringValue
        let featureValueFromCache: Bool? = rwLock.readOperation {
            if let values = globalFeatureGatingMemoryCache, !values.isEmpty {
                return values[key] ?? false
            }
            return nil
        }
        if let value = featureValueFromCache {
            Self.logger.debug("globalFeatureValue: key: \(key), cache value: \(value)")
            return value
        }
        let value = (try? SettingStorage.setting(
            with: "",
            type: Bool.self,
            key: key,
            decodeStrategy: .convertFromSnakeCase,
            useDefaultSetting: true)) ?? false
        Self.logger.debug("globalFeatureValue: key: \(key), use default value: \(value)")
        return value
    }

    /// 监听无用户态FG
    internal func register(key: GlobalFeatureGatingKey) -> Observable<Bool> {
        lock.lock()
        defer { lock.unlock() }
        return globalSubjects.asObserver()
            .flatMap { [weak self] _ -> Observable<Bool> in
                guard let _self = self else { return Observable.error(GlobalFeatureGatingError.GlobalFeatureGatingNotExists) }
                return Observable.just(_self.globalFeatureValue(of: key))
            }
            .distinctUntilChanged()
            .startWith(self.globalFeatureValue(of: key))
    }

    /// 更新无用户态FG
    /// 触发响应事件
    internal func update(new globalFeatureGatings: [String: Bool]) {
        Self.logger.debug("update GlobalFeatureGatingCache, new: \(globalFeatureGatings)")
        DiskCache.setObject(of: globalFeatureGatings, key: globalFeatureGatingKey)
        rwLock.writeOperation {
            globalFeatureGatingMemoryCache = globalFeatureGatings
        }
    }

    /// 未更新过用户态配置时, GlobalFeatureGatingCache更新触发响应全局创建的监听对象
    internal func triggerUpdateEvent() {
        let existMemoryCache = rwLock.readOperation {
            if let _ = globalFeatureGatingMemoryCache {
                return true
            } else {
                return false
            }
        }
        if existMemoryCache {
            lock.lock()
            self.globalSubjects.onNext(())
            lock.unlock()
        }
    }

    internal func allGlobalFeatureGatingKeys() -> [String] {
        ensureDataExists()
        return rwLock.readOperation {
            if let cache = globalFeatureGatingMemoryCache {
                return cache.map { key, _ in key }
            } else {
                return []
            }
        }
    }

    private func ensureDataExists() {
        let isFirstInit = rwLock.readOperation {
            return globalFeatureGatingMemoryCache == nil
        }
        if isFirstInit {
            rwLock.writeOperation {
                if globalFeatureGatingMemoryCache == nil {
                    let dataFromDisk = DiskCache.object(of: [String: Bool].self, key: globalFeatureGatingKey) ?? [:]
                    globalFeatureGatingMemoryCache = dataFromDisk
                }
            }
        }
    }
}

public enum GlobalFeatureGatingError: Error {
    case GlobalFeatureGatingNotExists
}

public struct GlobalFeatureGatingKey {
    public let key: StaticString

    public init(_ key: GlobalSettingKey) {
        self.key = key.key
    }

    public var stringValue: String {
        return key.description
    }
}
