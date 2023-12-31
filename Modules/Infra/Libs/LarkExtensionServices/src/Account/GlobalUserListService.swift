import LarkStorageCore

public struct UserDao: Codable, Equatable {
    
    let session: String
        
    let tenantId: String
    
    let unit: String
        
    let encryptedUserId: String
    
    internal init(session: String, tenantId: String, unit: String, encryptedUserId: String) {
        self.session = session
        self.tenantId = tenantId
        self.unit = unit
        self.encryptedUserId = encryptedUserId
    }
}

internal struct GlobalUserService {

    private let extensionProcessUserKey = "extensionProcessUser"

    static internal var shared = GlobalUserService()

    private lazy var kvStore: KVStore = KVStores.mmkv(space: .global, domain: Domain.biz.passport, mode: .shared).usingCipher()

    private init() {
        setupMMKVIfNeeded()
    }

    internal mutating func getUserDao(userId: String) -> UserDao? {
        let userDao: UserDao? = self.queryUserDaoFromKVStore(userId: userId)
        return userDao
    }

    private func queryUserDaoFromKVStore(userId: String) -> UserDao? {
        return KVStores.mmkv(space: .user(id: userId), domain: Domain.biz.passport, mode: .shared)
            .usingCipher()
            .value(forKey: extensionProcessUserKey)
    }

    internal mutating func getDeviceIdAndInstallId(unit: String) -> (String, String)? {
        // Default fg value is false.
        if kvStore.value(forKey: "universalDeviceServiceUpgraded") ?? false,
            let deviceId: String = kvStore.value(forKey: "deviceId"),
            let installId: String = kvStore.value(forKey: "installId") {
            return (deviceId, installId)
        } else if let unitDeviceIdMap: [String: String] = kvStore.value(forKey: "unitDeviceIdMap"),
                    let unitInstallIdMap: [String: String] = kvStore.value(forKey: "unitInstallIdMap"),
                    let deviceId = unitDeviceIdMap[unit], let installId = unitInstallIdMap[unit] {
            return (deviceId, installId)
        }
        return nil
    }
}
