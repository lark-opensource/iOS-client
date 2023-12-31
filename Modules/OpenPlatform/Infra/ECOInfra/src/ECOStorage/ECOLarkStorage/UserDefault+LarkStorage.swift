//
//  UserDefault+LarkStorage.swift
//  ECOInfra
//
//  Created by ByteDance on 2023/2/16.
//

import Foundation
import LarkStorage
// lint:disable lark_storage_migrate_check
@objcMembers
public class LSUserDefault: NSObject {
    ///基于UserDefaults.standard且global space的封装
    public static let standard = LSUserDefault()
    ///基于UserDefaults.standard且global space的封装,在key是动态配置的时候使用
    public static let dynamic = LSUserDefault(isDynamic: true)
    
    private var isDynamic: Bool
    
    //LarkStorage UserDefault fg
    static var lsUserDefaultEnable: Bool = {
        return EMAFeatureGating.boolValue(forKey: "openplatform.userdefault.larkstorage.enable")
    }()
    
    fileprivate override init() {
        self.isDynamic = false
        super.init()
    }
    
    fileprivate init(isDynamic: Bool) {
        self.isDynamic = isDynamic
        super.init()
    }
    
    private static let globalStore = KVStores.udkv(space: .global, domain: Domain.biz.microApp)
    private static let dynamicStore = KVStores.udkv(space: .global, domain: Domain.biz.microApp)
    
    
    lazy private var dynamicOPUserDefault: MicroAppUserDefault = {
        if !Self.lsUserDefaultEnable {
            Self.dynamicStore.clearMigrationMarks()
            return .old
        } else {
            return .new(Self.dynamicStore)
        }
    }()
    
    lazy private var globalOPUserDefault: MicroAppUserDefault = {
        if !Self.lsUserDefaultEnable {
            Self.globalStore.clearMigrationMarks()
            return .old
        } else {
            return .new(Self.globalStore)
        }
    }()

    fileprivate func microAppUserDefault() -> MicroAppUserDefault {
        return isDynamic ? self.dynamicOPUserDefault : self.globalOPUserDefault
    }
    
    fileprivate func registerDynamicKeyIfNeeded(key: String){
        if isDynamic {
            dynamicAppendMigration(forKey: key)
        }
    }

    public func getBool(forKey key: String) -> Bool {
        registerDynamicKeyIfNeeded(key: key)
        return microAppUserDefault().getBool(forKey: key)
    }

    public func setBool(_ boolValue: Bool, forKey key: String) {
        registerDynamicKeyIfNeeded(key: key)
        microAppUserDefault().setBool(boolValue, forKey: key)
    }
    
    public func getInteger(forKey key: String) -> Int {
        registerDynamicKeyIfNeeded(key: key)
        return microAppUserDefault().getInteger(forKey: key)
    }
    
    public func setInteger(_ intValue: Int, forKey key: String) {
        registerDynamicKeyIfNeeded(key: key)
        microAppUserDefault().setInteger(intValue, forKey: key)
    }

    public func getFloat(forKey key: String) -> Float {
        registerDynamicKeyIfNeeded(key: key)
        return microAppUserDefault().getFloat(forKey: key)
    }
    
    public func setFloat(_ floatValue: Float, forKey key: String) {
        registerDynamicKeyIfNeeded(key: key)
        microAppUserDefault().setFloat(floatValue, forKey: key)
    }

    public func getDouble(forKey key: String) -> Double {
        registerDynamicKeyIfNeeded(key: key)
        return microAppUserDefault().getDouble(forKey: key)
    }

    public func setDouble(_ doubleValue: Double, forKey key: String) {
        registerDynamicKeyIfNeeded(key: key)
        microAppUserDefault().setDouble(doubleValue, forKey: key)
    }
    
    public func getString(forKey key: String) -> String? {
        registerDynamicKeyIfNeeded(key: key)
        return microAppUserDefault().getString(forKey: key)
    }

    public func setString(_ strValue: String?, forKey key: String) {
        registerDynamicKeyIfNeeded(key: key)
        microAppUserDefault().setString(strValue, forKey: key)
    }
    
    public func getData(forKey key: String) -> Data? {
        registerDynamicKeyIfNeeded(key: key)
        return microAppUserDefault().getData(forKey: key)
    }
    
    public func setData(_ dataValue: Data?, forKey key: String) {
        registerDynamicKeyIfNeeded(key: key)
        microAppUserDefault().setData(dataValue, forKey: key)
    }
    
    public func getDictionary(forKey key: String) -> [String: Any]? {
        registerDynamicKeyIfNeeded(key: key)
        return microAppUserDefault().getDictionary(forKey: key)
    }
    
    public func setDictionary(_ dictValue: [String: Any], forKey key: String) {
        registerDynamicKeyIfNeeded(key: key)
        microAppUserDefault().setDictionary(dictValue, forKey: key)
    }
    
    public func getArray(forKey key: String) -> [Any]? {
        registerDynamicKeyIfNeeded(key: key)
        return microAppUserDefault().getArray(forKey: key)
    }
    
    public func setArray(_ arrValue: [Any], forKey key: String) {
        registerDynamicKeyIfNeeded(key: key)
        microAppUserDefault().setArray(arrValue, forKey: key)
    }
    
    public func getValue<T: Codable>(forKey key: String) -> T? {
        registerDynamicKeyIfNeeded(key: key)
        return microAppUserDefault().value(forKey: key)
    }
    
    public func set<T: Codable>(_ value: T, forKey key: String) {
        registerDynamicKeyIfNeeded(key: key)
        microAppUserDefault().set(value, forKey: key)
    }
    
    public func synchronize(){
        microAppUserDefault().synchronize()
    }
    
    public func contains(key: String) -> Bool{
        registerDynamicKeyIfNeeded(key: key)
        return microAppUserDefault().contains(key: key)
    }
    
    public func removeObject(key: String){
        registerDynamicKeyIfNeeded(key: key)
        microAppUserDefault().removeObject(key: key)
    }
    
    ///禁用
    @available(*, unavailable)
    public override func setValue(_ value: Any?, forKey key: String) {
        assertionFailure("use set instead")
    }
    
    ///禁用
    @available(*, unavailable)
    public override func value(forKey key: String) -> Any? {
        assertionFailure("use getValue instead")
    }

}

extension LSUserDefault{
    ///注册动态key，需要保证在get/set使用前注册
    fileprivate func dynamicAppendMigration(forKey key: String){
        _ = Self.dynamicStore.usingMigration(
            config: .from(userDefaults: .standard, items: [.init(stringLiteral: "\(key)")]),
            strategy: .sync,
            shouldMerge: true
        )
    }
}

enum MicroAppUserDefault {
    case old
    case new(KVStore)
}

extension MicroAppUserDefault {
    public func getBool(forKey key: String) -> Bool {
        switch self {
        case .old:
            return UserDefaults.standard.bool(forKey: key)
        case .new(let kvStore):
            return kvStore.bool(forKey: key)
        }
    }

    public func setBool(_ boolValue: Bool, forKey key: String) {
        switch self {
        case .old:
            UserDefaults.standard.set(boolValue, forKey: key)
        case .new(let kvStore):
            kvStore.set(boolValue, forKey: key)
        }
    }
    
    public func getInteger(forKey key: String) -> Int {
        switch self {
        case .old:
            return UserDefaults.standard.integer(forKey: key)
        case .new(let kvStore):
            return kvStore.integer(forKey: key)
        }
    }
    
    public func setInteger(_ intValue: Int, forKey key: String) {
        switch self {
        case .old:
            return UserDefaults.standard.set(intValue, forKey: key)
        case .new(let kvStore):
            return kvStore.set(intValue, forKey: key)
        }
    }

    public func getFloat(forKey key: String) -> Float {
        switch self {
        case .old:
            return UserDefaults.standard.float(forKey: key)
        case .new(let kvStore):
            return kvStore.float(forKey: key)
        }
    }
    
    public func setFloat(_ floatValue: Float, forKey key: String) {
        switch self {
        case .old:
            return UserDefaults.standard.set(floatValue, forKey: key)
        case .new(let kvStore):
            return kvStore.set(floatValue, forKey: key)
        }
    }

    public func getDouble(forKey key: String) -> Double {
        switch self {
        case .old:
            return UserDefaults.standard.double(forKey: key)
        case .new(let kvStore):
            return kvStore.double(forKey: key)
        }
    }

    public func setDouble(_ doubleValue: Double, forKey key: String) {
        switch self {
        case .old:
            return UserDefaults.standard.set(doubleValue, forKey: key)
        case .new(let kvStore):
            return kvStore.set(doubleValue, forKey: key)
        }
    }
    
    public func getString(forKey key: String) -> String? {
        switch self {
        case .old:
            return UserDefaults.standard.string(forKey: key)
        case .new(let kvStore):
            return kvStore.string(forKey: key)
        }
    }

    public func setString(_ strValue: String?, forKey key: String) {
        switch self {
        case .old:
            return UserDefaults.standard.set(strValue, forKey: key)
        case .new(let kvStore):
            return kvStore.set(strValue, forKey: key)
        }
    }
    
    public func getData(forKey key: String) -> Data? {
        switch self {
        case .old:
            return UserDefaults.standard.data(forKey: key)
        case .new(let kvStore):
            return kvStore.data(forKey: key)
        }
    }
    
    public func setData(_ dataValue: Data?, forKey key: String) {
        switch self {
        case .old:
            return UserDefaults.standard.set(dataValue, forKey: key)
        case .new(let kvStore):
            return kvStore.set(dataValue, forKey: key)
        }
    }
    
    public func getDictionary(forKey key: String) -> [String: Any]? {
        switch self {
        case .old:
            return UserDefaults.standard.dictionary(forKey: key)
        case .new(let kvStore):
            return kvStore.dictionary(forKey: key)
        }
    }
    
    public func setDictionary(_ dictValue: [String: Any], forKey key: String) {
        switch self {
        case .old:
            return UserDefaults.standard.set(dictValue, forKey: key)
        case .new(let kvStore):
            return kvStore.setDictionary(dictValue, forKey: key)
        }
    }
    
    public func getArray(forKey key: String) -> [Any]? {
        switch self {
        case .old:
            return UserDefaults.standard.array(forKey: key)
        case .new(let kvStore):
            return kvStore.array(forKey: key)
        }
    }
    
    public func setArray(_ arrValue: [Any], forKey key: String) {
        switch self {
        case .old:
            return UserDefaults.standard.set(arrValue, forKey: key)
        case .new(let kvStore):
            return kvStore.setArray(arrValue, forKey: key)
        }
    }
    
    
    public func value<T: Codable>(forKey key: String) -> T? {
        switch self {
        case .old:
            return UserDefaults.standard.object(forKey: key) as? T
        case .new(let kvStore):
            return kvStore.value(forKey: key)
        }
    }

    public func set<T: Codable>(_ value: T, forKey key: String) {
        switch self {
        case .old:
            UserDefaults.standard.set(value, forKey: key)
        case .new(let kvStore):
            kvStore.set(value, forKey: key)
        }
    }
    
    public func synchronize() {
        switch self {
        case .old:
            UserDefaults.standard.synchronize()
        case .new(let kvStore):
            kvStore.synchronize()
        }
    }

    public func contains(key: String) -> Bool{
        switch self {
        case .old:
            return UserDefaults.standard.object(forKey: key) != nil
        case .new(let kvStore):
            return kvStore.contains(key: key)
        }
    }
    
    public func removeObject(key: String){
        switch self {
        case .old:
            UserDefaults.standard.removeObject(forKey: key)
        case .new(let kvStore):
            kvStore.removeValue(forKey: key)
        }
    }
}
// lint:enable lark_storage_migrate_check
