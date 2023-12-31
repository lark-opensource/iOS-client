//
//  FeatureGatingStorage.swift
//  LarkSetting
//
//  Created by 王元洵 on 2022/7/27.
//

import Foundation
import EEAtomic
import LKCommonsLogging
import LarkCombine
import RxSwift
import LarkStorage
import ThreadSafeDataStructure
import LarkContainer
import LKCommonsTracker

enum FeatureGatingType {
    case `static`
    case dynamic
}

enum FeatureGatingStorage {
    private static let logger = Logger.log(FeatureGatingStorage.self, category: "FeatureGatingStorage")
    private static let onceToken = AtomicOnce()
    private static let featureGatingKey = "featureGating"
    private static let currentVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""

    private static var _defaultFeature: Set<String>?
    private static var syncStrategyEnable: SafeDictionary<String, Bool> = [:] + .readWriteLock
    private static var lazyFeatureGatingBarrier: SafeDictionary<String, LazyLoadFeatureGatingUserBarrier> = [:] + .readWriteLock
    private static var dynamicFeatures: SafeDictionary<String, Set<String>> = [:] + .readWriteLock
    private static var frozenFeatures: SafeDictionary<String, [String: Bool]> = [:] + .readWriteLock
    private static var staticFeatures: SafeDictionary<String, Set<String>> = [:] + .readWriteLock
    private static var defaultFeature: Set<String> {
        onceToken.once {
            _defaultFeature = (try? SettingStorage.setting(with: "",
                                                           type: LarkFeature.self,
                                                           key: LarkFeature.settingKey.stringValue,
                                                           decodeStrategy: .convertFromSnakeCase,
                                                           useDefaultSetting: true))?.stringSet
        }
        return _defaultFeature ?? Set()
    }

    private static func dynamicFeatureValue(of id: String, key: String) -> Bool {
        dynamicFeatures[id]?.contains(key) ?? {
            logger.warn("[FG] memory cache no hit for id: \(id)")
            if !id.isEmpty { updateFeatureFromDiskOrDefault(with: id) }
            return dynamicFeatures[id]?.contains(key) ?? defaultFeature.contains(key)
        }()
    }

    private static func staticFeatureValue(of id: String, key: String) -> Bool {
        staticFeatures[id]?.contains(key) ?? {
            logger.warn("[FG] memory cache no hit for id: \(id)")
            if !id.isEmpty { updateFeatureFromDiskOrDefault(with: id) }
            return staticFeatures[id]?.contains(key) ?? defaultFeature.contains(key)
        }()
    }

    private static func lazyFeatureValue(of id: String, key: String) -> Bool {
        frozenFeatures[id]?[key] ?? {
            let useImmutableFeatureGating = syncStrategyEnable[id] ?? false
            Self.logger.debug("lazyFeatureValue, useImmutableFeatureGating: \(useImmutableFeatureGating), id: \(id)")
            let result = useImmutableFeatureGating ? {
                do {
                    if let barrier = lazyFeatureGatingBarrier[id] {
                        barrier.waitForBarrier(key: key)
                    }else {
                        Self.logger.warn("not have, barrier: id: \(id)")
                    }
                    return try featureGatingDatasource?.fetchImmutableFeatureGating(with: id, and: key) ?? false
                } catch {
                    DispatchQueue.global(qos: .background).async {
                        Tracker.post(
                            TeaEvent("lazy_load_fg_error_dev", params: ["fg_key": key, "error_msg": "use client value"])
                        )
                    }
                    return staticFeatureValue(of: id, key: key)
                 }
            }() : staticFeatureValue(of: id, key: key)
            frozenFeatures[id] = (frozenFeatures[id] ?? [:]).merging([key: result]) { $1 }
            return result
        }()
    }

    private static func updateFeatureFromDiskOrDefault(with id: String) {
        guard !dynamicFeatures.keys.contains(id) || !staticFeatures.keys.contains(id) else { return }

        let feature = DiskCache.object(of: LarkFeature.self, key: featureGatingKey + id)?.stringSet ?? defaultFeature
        if !dynamicFeatures.keys.contains(id) { dynamicFeatures[id] = feature }
        if !staticFeatures.keys.contains(id) { staticFeatures[id] = feature }
    }

    private static func notifyFGUpdate(with id: String, and type: FeatureGatingType) {
        fgRxSubject.onNext((id, type))
        fgCombineSubject.send((id, type))
    }
}

// MARK: internal interfaces
extension FeatureGatingStorage {
    static let fgRxSubject = PublishSubject<(String, FeatureGatingType)>()
    static let fgCombineSubject = PassthroughSubject<(String, FeatureGatingType), Never>()
    static var featureGatingKeySubjects: SafeDictionary<String, [String: PublishSubject<Bool>]> = [:] + .readWriteLock

    static var featureGatingDatasource: FeatureGatingDatasource?

    static func update(with feature: LarkFeature, and id: String) {
        let lastDynamicFeatures = dynamicFeatures[id] ?? []
        FeatureGatingSyncEventCollector.shared.calculateDiff(for: id, old: lastDynamicFeatures, new: feature.stringSet)
        dynamicFeatures[id] = feature.stringSet
        notifyFGUpdate(with: id, and: .dynamic)
        DiskCache.setObject(of: feature, key: featureGatingKey + id)
        triggerFeatureGatingUpdate(userID: id, lastDynamicFeatures: lastDynamicFeatures)
    }

    static func triggerFeatureGatingUpdate(userID: String, lastDynamicFeatures: Set<String>) {
        let userSubjects: [String: PublishSubject<Bool>] = featureGatingKeySubjects[userID] ?? [:]
        var featureGatingUpdated: [(String, Bool)] = []
        logger.info("trigger FeatureGatingUpdate start")
        for (featureKey, subject) in userSubjects {
            let oldValue = lastDynamicFeatures.contains(featureKey)
            let newValue = featureValue(of: userID, key: featureKey, type: .dynamic)
            if newValue != oldValue {
                featureGatingUpdated.append((featureKey, newValue))
                subject.onNext(newValue)
            }
        }
        logger.info("trigger FeatureGatingUpdate end: \(featureGatingUpdated.map{ "\($0.0): \($0.1)" }.joined(separator: ", "))")
    }

    static func updateStaticCache(with features: Set<String>, and id: String) {
        staticFeatures[id] = features
        notifyFGUpdate(with: id, and: .static)
    }
    
    
    static func immutableFeatures(of id: String) -> [String: Bool] { frozenFeatures[id] ?? [:] }
    
    static func mutableFeatures(of id: String) -> Set<String> { DiskCache.object(of: LarkFeature.self, key: featureGatingKey + id)?.stringSet ?? Set() }

    static func featureValue(of id: String, key: String, type: FeatureGatingType) -> Bool {
        let latest = dynamicFeatureValue(of: id, key: key)
        #if ALPHA
        let current = debugFeatures(of: id)[key] ?? (type == .static ? lazyFeatureValue(of: id, key: key) : latest)
        #else
        let current = type == .static ? lazyFeatureValue(of: id, key: key) : latest
        #endif
        FeatureGatingTracker.record(key: key, value: current, serverValue: latest, userID: id, type: type)
        return current
    }
    
    static func changeSyncStrategy(enable: Bool, of userID: String) {
        if !enable {
            lazyFeatureGatingBarrier.removeValue(forKey: userID)
        }
        let oldValue = syncStrategyEnable[userID] ?? false
        syncStrategyEnable[userID] = enable
        if enable {
            lazyFeatureGatingBarrier[userID] = LazyLoadFeatureGatingUserBarrier(of: userID)
            lazyFeatureGatingBarrier[userID]?.asyncWaitUntilPermissionOrTimeout()
        }
        logger.debug(
            "switch syncStrategyEnable: \(oldValue) -> \(syncStrategyEnable), userID: \(userID)"
        )
    }

    static func observeKey(of id: String, key: String) -> Observable<Bool>? {
        featureGatingKeySubjects.safeWrite(for: id) { value in
            if value == nil {
                value = [:]
            }
            if value?[key] == nil {
                value?[key] = PublishSubject<Bool>()
            }
        }
        return featureGatingKeySubjects[id]?[key]?.asObservable()
    }
}

#if ALPHA

// MARK: debug
import LarkStorage
extension FeatureGatingStorage {
    private static var debugCache = debugDiskCache { didSet { debugDiskCache = debugCache } }
    
    @KVConfig(key: "debugDiskCache", default: [String: [String: Bool]](), store: KVStores.FG.global.simplified())
    private static var debugDiskCache

    private static func debugFeatures(of id: String) -> [String: Bool] { debugCache[id + currentVersion] ?? [:] }

    static func debugFeatureDict(of id: String) -> [String: Bool] {
        Dictionary(uniqueKeysWithValues: (dynamicFeatures[id] ?? defaultFeature)
            .map { ($0, true) }).merging(debugFeatures(of: id)) { $1 }
    }

    static func updateDebugFeatureGating(fg: String, isEnable: Bool, id: String) {
        debugCache[id + currentVersion] = debugFeatures(of: id).merging([fg: isEnable]) { $1 }
        notifyFGUpdate(with: id, and: .static)
        notifyFGUpdate(with: id, and: .dynamic)
    }
}

#endif
