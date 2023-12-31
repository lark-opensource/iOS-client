import Foundation
import LarkAssembler
import LarkStorage
import LKKeyValueExternal
import LKCommonsLogging

public class LKKAKeyValueAssembly: LarkAssemblyInterface {
    public init() {
        KAKeyValueExternal.shared.store = KAKVStore()
    }
}

fileprivate class KAKVStore: KAKeyValueProtocol {
    let store = KVStores.mmkv(space: .global, domain: Domain.biz.ka).usingCipher(suite: .aes)
    let logger = Logger.log(KAKVStore.self, category: "Module.KAKVStore")

    func getData(key: String) -> Data {
        logger.info("KA---Watch: get Data for key: \(key)")
        return store.value(forKey: key) ?? Data()
    }

    func set(key: String, dataValue: Data) -> Bool {
        logger.info("KA---Watch: set Data for key: \(key)")
        store.set(dataValue, forKey: key)
        return true
    }

    func has(key: String) -> Bool {
        let hasKey = store.contains(key: key)
        logger.info("KA---Watch: check \(key) available \(hasKey)")
        return hasKey
    }

    func set(key: String, stringValue: String) -> Bool {
        logger.info("KA---Watch: set stringValue for key: \(key)")
        store.set(stringValue, forKey: key)
        return true
    }

    func set(key: String, intValue: Int) -> Bool {
        logger.info("KA---Watch: set intValue for key: \(key)")
        store.set(intValue, forKey: key)
        return true
    }

    func set(key: String, floatValue: Float) -> Bool {
        logger.info("KA---Watch: set floatValue for key: \(key)")
        store.set(floatValue, forKey: key)
        return true
    }

    func set(key: String, doubleValue: Double) -> Bool {
        logger.info("KA---Watch: set doubleValue for key: \(key)")
        store.set(doubleValue, forKey: key)
        return true
    }

    func set(key: String, boolValue: Bool) -> Bool {
        logger.info("KA---Watch: set boolValue for key: \(key)")
        store.set(boolValue, forKey: key)
        return true
    }

    func getString(key: String) -> String {
        logger.info("KA---Watch: get stringValue for key: \(key)")
        return store.value(forKey: key) ?? ""
    }

    func getInt(key: String) -> Int {
        logger.info("KA---Watch: set intValue for key: \(key)")
        return store.value(forKey: key) ?? 0
    }

    func getFloat(key: String) -> Float {
        logger.info("KA---Watch: set floatValue for key: \(key)")
        return store.value(forKey: key) ?? 0.1
    }

    func getDouble(key: String) -> Double {
        logger.info("KA---Watch: set doubleValue for key: \(key)")
        return store.value(forKey: key) ?? 0.1
    }

    func getBool(key: String) -> Bool {
        logger.info("KA---Watch: set boolValue for key: \(key)")
        return store.value(forKey: key) ?? true
    }

    func clear(key: String) -> Bool {
        logger.info("KA---Watch: clear key: \(key)")
        store.removeValue(forKey: key)
        return true
    }

    func clearAll() -> Bool {
        logger.info("KA---Watch: clear all")
        store.clearAll()
        return true
    }
}
