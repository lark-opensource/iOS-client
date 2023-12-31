//
//  BaseDeviceService.swift
//  LarkAccount
//
//  Created by Yiming Qu on 2020/10/21.
//

import Foundation
import RxRelay
import RxSwift
import LarkAccountInterface
import KeychainAccess
import LarkEnv
import LarkContainer
import EEAtomic

class DeviceInfoStore {
    
    private lazy var store = PassportStore.shared

    private(set) var deviceId: String? {
        get {
            store.getDeviceID(unit: unit)
        }
        set {
            if let newValue = newValue {
                store.setDeviceID(deviceID: newValue, unit: unit)
            }
        }
    }
    
    var deviceIdMap: [String: String]? {
        get {
            store.deviceIDMap
        }
    }

    private(set) var installId: String? {
        get {
            store.getInstallID(unit: unit)
        }
        set {
            if let newValue = newValue {
                store.setInstallID(installID: newValue, unit: unit)
            }
        }
    }
    
    var installIdMap: [String: String]? {
        get {
            store.installIDMap
        }
    }

    var deviceLoginId: String? {
        get { store.foregroundUser?.deviceLoginID } // user:current
        set {
            if let user = store.foregroundUser { // user:current
                store.updateUser(V4UserInfo(user: user.user, currentEnv: user.currentEnv, logoutToken: user.logoutToken, suiteSessionKey: user.suiteSessionKey, suiteSessionKeyWithDomains: user.suiteSessionKeyWithDomains, deviceLoginID: newValue, isAnonymous: user.isAnonymous, latestActiveTime: user.latestActiveTime, isSessionFirstActive: user.isSessionFirstActive)) // user:current
            }
        }
    }

    func getDeviceID(unit: String) -> String? {
        store.getDeviceID(unit: unit)
    }

    func getInstallID(unit: String) -> String? {
        store.getInstallID(unit: unit)
    }

    func getDidHost(unit: String) -> String? {
        getHost(with: unit)
    }

    /// 3.27.0 版本开始弃用
    private let deviceIDInternalKey: String = genKey("com.bytedance.ee.deviceIDInternal")
    private let installIDInternalKey: String = genKey("com.bytedance.ee.installIDInternal")
    private let deviceIDOverseaKey: String = genKey("com.bytedance.ee.deviceIDOversea")
    private let installIDOverseaKey: String = genKey("com.bytedance.ee.installIDOversea")
    private let deviceLoginIDInternalKey: String = genKey("com.bytedance.ee.deviceLoginIDInternal")
    private let deviceLoginIDOverseaKey: String = genKey("com.bytedance.ee.deviceLoginIDOversea")

    private let keychain: Keychain
    private let userDefaults: UserDefaults

    private var _deviceInfo: DeviceInfo? {
        guard let did = self.deviceId,
              let iid = self.installId else {
            SuiteLoginStore.keychainLogger.error("Cannot get deviceInfo, did: \(self.deviceId ?? ""), iid: \(self.installId ?? "")")
            return nil
        }
        let dlid = self.deviceLoginId
        return DeviceInfo(
            deviceId: did,
            installId: iid,
            deviceLoginId: dlid ?? DeviceInfo.emptyValue,
            isValidDeviceID: DeviceInfo.isDeviceIDValid(did),
            isValid: DeviceInfo.isDeviceIDValid(did) && DeviceInfo.isInstallIDValid(iid)
        )
    }

    var deviceInfo: DeviceInfo {
        return _deviceInfo ?? DeviceInfo(
            deviceId: "",
            installId: "",
            deviceLoginId: "",
            isValidDeviceID: false,
            isValid: false
        )
    }

    private lazy var deviceInfoVariable: BehaviorRelay<DeviceInfo?> = {
        return BehaviorRelay(value: _deviceInfo)
    }()
    var deviceInfoObservable: Observable<DeviceInfo?> {
        return deviceInfoVariable.asObservable().distinctUntilChanged { (old, new) -> Bool in
            return old?.deviceId == new?.deviceId &&
                old?.installId == new?.installId &&
                old?.deviceLoginId == new?.deviceLoginId
        }
    }

    init() {
        keychain = Keychain(service: PassportConf.shared.groupId)
            .synchronizable(false)
            .accessibility(.alwaysThisDeviceOnly) // device id should not sync to other device
        userDefaults = SuiteLoginUtil.userDefault()
    }

    public func deviceInfoUpdated() {
        deviceInfoVariable.accept(_deviceInfo)
    }

    // MARK: Device ID Host & Unit

    /// [unit: host]
    @AtomicObject
    private var unitHostMap = [String: String]()
    
    @discardableResult
    func set(deviceID: String, installID: String, with host: String) -> Bool {
        if store.enableInstallIDUpdatedSeparately {
            return _set(deviceID: deviceID, installID: installID, with: host)
        } else {
            return _previousSet(deviceID: deviceID, installID: installID, with: host)
        }
    }
    
    @discardableResult
    private func _set(deviceID: String, installID: String, with host: String) -> Bool {
        // 通过 host 获取对应的 unit，在 SaaS 的场景下，返回数量为 1
        // KA 特例场景下，存在一个 host 对应多个 unit 的可能（一个 SaaS unit，一个 KA 专属 unit）
        // 这个时候更新全部存在的 units
        let cachedUnits = getUnitList(with: host)
        if cachedUnits.isEmpty {
            SuiteLoginStore.keychainLogger.error("n_action_device_store: cannot get cached unit from host: \(host)")
            return false
        }
        SuiteLoginStore.keychainLogger.info("n_action_device_store: units count \(cachedUnits.count)")
        
        func updateDID(_ value: String, unit: String) {
            let didKey = cacheKeyFor(unit: unit, cacheType: .deviceID)
            set(key: didKey, value: value, type: .deviceID)
            store.setDeviceID(deviceID: value, unit: unit)
            SuiteLoginStore.keychainLogger.info("n_action_device_store: set deviceID: \(value) with host: \(host), in unit: \(unit)")
        }
        
        func updateIID(_ value: String, unit: String) {
            let iidKey = cacheKeyFor(unit: unit, cacheType: .installID)
            set(key: iidKey, value: value, type: .installID)
            store.setInstallID(installID: value, unit: unit)
            SuiteLoginStore.keychainLogger.info("n_action_device_store: set installID: \(value) with host: \(host), in unit: \(unit)")
        }
        
        var changed = false
        cachedUnits.forEach { cachedUnit in
            if store.getDeviceID(unit: cachedUnit)?.isEmpty ?? true {
                // 当 did 为空时，更新 did 和匹配的 iid
                SuiteLoginStore.keychainLogger.info("n_action_device_store: store is empty")
                updateDID(deviceID, unit: cachedUnit)
                updateIID(installID, unit: cachedUnit)
                changed = true
            }
            if let cachedDID = store.getDeviceID(unit: cachedUnit),
               cachedDID == deviceID {
                // 当本地 did 和返回的 did 相同，iid 进行一次更新
                SuiteLoginStore.keychainLogger.info("n_action_device_store: iid changed")
                updateIID(installID, unit: cachedUnit)
                changed = true
            }
            if !changed {
                SuiteLoginStore.keychainLogger.warn("n_action_device_store: store already had did and iid in unit: \(cachedUnit)")
            }
        }
        return changed
    }

    /// 根据返回的 host，获取匹配的 unit 后存储 deviceID 和 installID
    /// 返回 true 表示有更新，false 表示未更新
    @available(*, deprecated, message: "Starting with v5.22, iid will updated separately and this method will be removed soon.")
    @discardableResult
    private func _previousSet(deviceID: String, installID: String, with host: String) -> Bool {
        SuiteLoginStore.keychainLogger.warn("n_action_device_store: previous set workflow")
        let cachedUnits = getUnitList(with: host)
        if cachedUnits.isEmpty {
            SuiteLoginStore.keychainLogger.error("Cannot get cached unit from host: \(host)")
            return false
        }
        if cachedUnits.count == 1, let cachedUnit = cachedUnits.first {
            // SaaS 包目前只会走这个场景
            SuiteLoginStore.keychainLogger.info("n_action_device_only_one_cached_unit_found")
            if (store.getDeviceID(unit: cachedUnit)?.isEmpty ?? true) || (store.getInstallID(unit: cachedUnit)?.isEmpty ?? true) {
                let didKey = cacheKeyFor(unit: cachedUnit, cacheType: .deviceID)
                set(key: didKey, value: deviceID, type: .deviceID)
                store.setDeviceID(deviceID: deviceID, unit: cachedUnit)
                SuiteLoginStore.keychainLogger.info("Set deviceID: \(deviceID) with host: \(host), in unit: \(cachedUnit)")
                
                let iidKey = cacheKeyFor(unit: cachedUnit, cacheType: .installID)
                set(key: iidKey, value: installID, type: .installID)
                store.setInstallID(installID: installID, unit: cachedUnit)
                SuiteLoginStore.keychainLogger.info("Set installID: \(installID) with host: \(host), in unit: \(cachedUnit)")
                
                return true
            }
            SuiteLoginStore.keychainLogger.warn("Store already had did and iid in unit: \(cachedUnit)")
            return false
        }
        SuiteLoginStore.keychainLogger.info("n_action_device_multiple_cached_unit_found")
        var flag = false
        cachedUnits.forEach { cachedUnit in
            if (store.getDeviceID(unit: cachedUnit)?.isEmpty ?? true) || (store.getInstallID(unit: cachedUnit)?.isEmpty ?? true) {
                let didKey = cacheKeyFor(unit: cachedUnit, cacheType: .deviceID)
                set(key: didKey, value: deviceID, type: .deviceID)
                store.setDeviceID(deviceID: deviceID, unit: cachedUnit)
                SuiteLoginStore.keychainLogger.info("Set deviceID: \(deviceID) with host: \(host), in unit: \(cachedUnit)")
                
                let iidKey = cacheKeyFor(unit: cachedUnit, cacheType: .installID)
                set(key: iidKey, value: installID, type: .installID)
                store.setInstallID(installID: installID, unit: cachedUnit)
                SuiteLoginStore.keychainLogger.info("Set installID: \(installID) with host: \(host), in unit: \(cachedUnit)")
                
                flag = true
            } else {
                // 5.4 后，如果 store 中对应的 unit 已经有 did & iid，将不再接收后续的更新
                SuiteLoginStore.keychainLogger.warn("Store already had did and iid in unit: \(cachedUnit)")
            }
        }
        return flag
    }

    /// 存储某个 host 所属的 unit
    func set(unit: String, with host: String) {
        hostUnitLock.wait()
        defer {
            hostUnitLock.signal()
        }
        var cachedMap = [String: String]()
        if let udMap = userDefaults.dictionary(forKey: unitHostMapKey) as? [String: String] {
            cachedMap = udMap
        }
        cachedMap[unit] = host

        unitHostMap = cachedMap
        userDefaults.set(cachedMap, forKey: unitHostMapKey)

        SuiteLoginStore.keychainLogger.info("Set unit: \(unit), with host: \(host).")
        SuiteLoginStore.keychainLogger.info("All unit-host map now is \(cachedMap).")
    }

    func fetchCurrentHost() -> String? {
        return getHost(with: unit)
    }

    /// 获取某个 host 所属的 unit
    /// 由于缓存的是 [unit: host] 键值对，通过 host 去找 unit 有可能有多个（KA 包中，SaaS unit 和 KA unit 可能会保有同一个 host）
    /// 所以这里返回一个 unit 数组
    private func getUnitList(with host: String) -> [String] {
        if !unitHostMap.isEmpty {
            let unitList = unitHostMap.filter { element in
                element.value == host
            }.map { key, value in
                return key
            }
            if !unitList.isEmpty {
                SuiteLoginStore.keychainLogger.info("Get memory cache Unit List: \(unitList), using host value: \(host).")
                return unitList
            }
        }

        let udMap = getUnitHostMap()
        let udUnitList = udMap.filter { element in
            element.value == host
        }.map { key, value in
            return key
        }

        if !udUnitList.isEmpty {
            udUnitList.forEach { unitHostMap[$0] = udMap[$0] }
            SuiteLoginStore.keychainLogger.info("Get userDefaults cache Unit List: \(udUnitList), using host value: \(host).")
            return udUnitList
        }
        SuiteLoginStore.keychainLogger.info("Cannot get any Unit List via host value: \(host).")
        return []
    }

    /// 获取某个 unit 下的 host
    private func getHost(with unit: String) -> String? {
        if let host = unitHostMap[unit] {
            SuiteLoginStore.keychainLogger.info("Get memory cached Host: \(host), using key Unit: \(unit).")
            return host
        }
        let udMap = getUnitHostMap()
        if let udHost = udMap[unit] {
            unitHostMap[unit] = udHost
            SuiteLoginStore.keychainLogger.info("Get userDefaults cached Host: \(udHost), key Unit: \(unit).")
            return udHost
        }
        SuiteLoginStore.keychainLogger.info("Cannot get any Host via key Unit: \(unit).")
        return nil
    }

    private func getUnitHostMap() -> [String: String] {
        hostUnitLock.wait()
        defer {
            hostUnitLock.signal()
        }
        var cachedMap = [String: String]()
        if let udMap = userDefaults.dictionary(forKey: unitHostMapKey) as? [String: String] {
            cachedMap = udMap
        }
        return cachedMap
    }

    private func resetUnitHostMap() {
        hostUnitLock.wait()
        defer {
            hostUnitLock.signal()
        }
        let empty = [String: String]()

        unitHostMap = empty
        userDefaults.set(empty, forKey: unitHostMapKey)

        SuiteLoginStore.keychainLogger.info("Reset unit-host map.")
    }

    private var unitHostMapKey: String {
        let prefix = cachePrefix()
        let suffix = "DeviceIDHost"
        return "\(prefix)_map_\(suffix)"
    }

    // MARK: keychain data memory & userDefault & keychain cache

    private var unit: String { EnvManager.env.unit }

    func cacheKeyFor(unit: String, cacheType: CacheType) -> String {
        let prefix = cachePrefix()
        return "\(prefix)_\(unit)_\(cacheType.cacheKeySuffix)"
    }

    private var cache: [String: String] = [:]

    /// 用于 deviceID
    private let lock = DispatchSemaphore(value: 1)

    /// 用于 host unit 映射
    private let hostUnitLock = DispatchSemaphore(value: 1)

    enum CacheType: CustomStringConvertible, CaseIterable {

        case installID
        case deviceID
        case deviceLoginID

        var cacheKeySuffix: String { description }

        var description: String {
            switch self {
            case .installID:
                return "installId"
            case .deviceID:
                return "deviceId"
            case .deviceLoginID:
                return "deviceLoginId"
            }
        }
    }

    private func isValid(value: String, type: CacheType) -> Bool {
        switch type {
        case .installID:
            return DeviceInfo.isInstallIDValid(value)
        case .deviceID:
            return DeviceInfo.isDeviceIDValid(value)
        case .deviceLoginID:
            return DeviceInfo.isDeviceLoginIDValid(value)
        }
    }

    private func set(key: String, value: String?, type: CacheType) {
        lock.wait()
        defer {
            lock.signal()
        }
        cache[key] = value
        userDefaults.set(value, forKey: key)
        userDefaults.synchronize()
        var params: [String: String] = [
            "key": key,
            "value": String(describing: value)
        ]
        if needKeychainCache(type) {
            let success = AvoidWatchDogKeychainAccess.set(key: key, value: value, keychain: keychain, source: type.description)
            params["keychain_success"] = "\(success)"
        }
        SuiteLoginStore.keychainLogger.info("set value", additionalData: params)
    }

    private func get(key: String, type: CacheType) -> String? {
        lock.wait()
        defer {
            lock.signal()
        }
        if let value = cache[key], isValid(value: value, type: type) {
            SuiteLoginStore.keychainLogger.info("get memory cache key: \(key) value: \(value) type: \(type)")
            return value
        } else {
            SuiteLoginStore.keychainLogger.info("get memory cache fail key: \(key) value: \(String(describing: cache[key])) type: \(type)")
        }
        let userDefaultValue = userDefaults.string(forKey: key)
        if let value = userDefaultValue, isValid(value: value, type: type) {
            SuiteLoginStore.keychainLogger.info("get userDefaults cache key: \(key) value: \(value) type: \(type)")
            cache[key] = value
            return cache[key]
        } else {
            SuiteLoginStore.keychainLogger.info("get userDefaults cache fail key: \(key) value: \(String(describing: userDefaultValue)) type: \(type)")
        }
        guard needKeychainCache(type) else {
            return nil
        }
        cache[key] = AvoidWatchDogKeychainAccess.get(key: key, keychain: keychain, source: type.description)
        userDefaults.set(cache[key], forKey: key)
        userDefaults.synchronize()
        return cache[key]
    }

    func reset() {
        // MultiGeo updated
        store.removeDeviceData()
        resetUnitHostMap()
    }
}
// MARK: Config
extension DeviceInfoStore {

    func cachePrefix() -> String {
        return "com.bytedance.ee.rangers.app.log"
    }

    func needKeychainCache(_ cacheType: CacheType) -> Bool {
        return false
    }
}

// MARK: - Migrate

extension DeviceInfoStore: PassportStoreMigratable {
    private func get(unit: String, type: CacheType) -> String? {
        let key = cacheKeyFor(unit: unit, cacheType: type)
        return get(key: key, type: type)
    }

    private func migrate(units: [String]) -> Bool {
        var deviceIDMap = [String : String]()
        var installIDMap = [String : String]()
        // MultiGeo updated
        for unit in units {
            if let deviceID = get(unit: unit, type: .deviceID) {
                deviceIDMap[unit] = deviceID
            }
            if let installID = get(unit: unit, type: .installID) {
                installIDMap[unit] = installID
            }
        }
        store.deviceIDMap = deviceIDMap
        store.installIDMap = installIDMap
        // deviceLoginId 在迁移用户信息时一并处理

        return true
    }

    func startMigration() -> Bool {
        return migrate(units: LarkEnv.Env.legacyUnits)
    }

    func migrate(additionalUnit: String) -> Bool {
        var units = LarkEnv.Env.legacyUnits
        if !additionalUnit.isEmpty, !units.contains(additionalUnit) {
            units.insert(additionalUnit, at: 0)
        }

        return migrate(units: units)
    }
}

extension Env {
    /// 仅用于旧版本 did 数据迁移
    fileprivate static let legacyUnits: [String] = {
        return [
            "eu_nc",
            "eu_ea",
            "boecn",
            "boeva"
        ]
    }()
}
