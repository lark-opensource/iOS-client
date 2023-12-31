import LKCommonsLogging
import LarkContainer
import LarkStorageCore

internal func excludeFromBackup(kvStore: KVStore, logger: Log) {
    do {
        try kvStore.excludeFromBackup()
    } catch {
        assert(false)
        logger.error("excludeFromBackup error.", error: error)
    }
}

private func getKvStorage(logger: Log) -> KVStore {
    var kvStorage = KVStores.mmkv(space: .global, domain: Domain.biz.passport, mode: .shared).usingCipher()
    excludeFromBackup(kvStore: kvStorage, logger: logger)

    return kvStorage
}

internal func set<T: Codable>(kvStore: KVStore, key: String, value: T?) {
    if let value = value {
        kvStore.set(value, forKey: key)
    } else {
        kvStore.removeValue(forKey: key)
    }
}

internal struct GlobalKvStorageServiceImpl: GlobalKvStorageService {
    
    internal static let shared: GlobalKvStorageService = GlobalKvStorageServiceImpl()

    private let logger = Logger.plog(GlobalKvStorageServiceImpl.self)

    internal func get<T>(key: String, userId: String?) -> T? where T : Decodable, T : Encodable {
        if let userId = userId {
            return get(userId: userId, key: key)
        } else {
            return get(key: key)
        }
    }

    internal func set<T>(key: String, value: T?, userId: String?) where T : Decodable, T : Encodable {
        if let userId = userId {
            set(userId: userId, key: key, value: value)
        } else {
            set(key: key, value: value)
        }
    }

    internal func clear(userId: String?) {
        if let userId = userId {
            getKvStorage(userId: userId, logger: logger).clearAll()
        } else {
            kvStore.clearAll()
        }
    }

    private let kvStore: KVStore

    internal init() {
        kvStore = getKvStorage(logger: logger)
    }

    private func get<T: Codable>(key: String) -> T? {
        return kvStore.value(forKey: key)
    }

    private func get<T: Codable>(userId: String, key: String) -> T? {
        return getKvStorage(userId: userId, logger: logger).value(forKey: key)
    }

    private func set<T: Codable>(key: String, value: T?) {
        LarkAccount.set(kvStore: kvStore, key: key, value: value)
    }

    private func set<T: Codable>(userId: String, key: String, value: T?) {
        LarkAccount.set(kvStore: getKvStorage(userId: userId, logger: logger), key: key, value: value)
    }
}
