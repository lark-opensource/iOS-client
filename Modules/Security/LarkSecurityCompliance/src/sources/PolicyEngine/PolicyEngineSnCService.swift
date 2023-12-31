//
//  PolicyEngineSnCService.swift
//  LarkSecurityCompliance
//
//  Created by 汤泽川 on 2023/1/12.
//

import Foundation
import LarkContainer
import LarkAccountInterface
import LarkSnCService
import LarkSecurityComplianceInfra

public protocol PolicyEngineSnCService: SnCService { }

final class PolicyEngineSnCServiceImpl: PolicyEngineSnCService {

    let client: LarkSnCService.HTTPClient? = HTTPClientImp()
    let storage: LarkSnCService.Storage?
    let logger: LarkSnCService.Logger? = LoggerImpl(category: "lark.snc.policy_engine")
    let tracker: LarkSnCService.Tracker? = TrackerImpl()
    let monitor: LarkSnCService.Monitor? = MonitorImpl(business: .policy_engine)
    let settings: LarkSnCService.Settings?
    let environment: Environment? = EnvironmentImpl()

    init(userID: String) {
        settings = SettingsImpl()
        storage = PolicyEngineStorage(uid: userID)
    }
}

final class PolicyEngineStorage: LarkSnCService.Storage {

    let userStorage: SCKeyValueStorage
    let globalStorage: SCKeyValueStorage
    init(uid: String) {
        userStorage = SCKeyValue.MMKVEncrypted(userId: uid)
        globalStorage = SCKeyValue.globalMMKVEncrypted()
    }

    func set<T>(_ value: T?, forKey: String, space: StorageSpace) throws where T: Codable {
        switch space {
        case .global:
            globalStorage.set(value, forKey: forKey)
        case .user:
            userStorage.set(value, forKey: forKey)
        @unknown default:
            assertionFailure()
        }
    }

    func get<T>(key: String, space: StorageSpace) throws -> T? where T: Codable {
        switch space {
        case .global:
            return globalStorage.value(forKey: key)
        case .user:
            return userStorage.value(forKey: key)
        @unknown default:
            assertionFailure()
            return globalStorage.value(forKey: key)
        }
    }

    func remove<T>(key: String, space: StorageSpace) throws -> T? where T: Codable {
        switch space {
        case .global:
            let tmp: T? = globalStorage.value(forKey: key)
            globalStorage.removeObject(forKey: key)
            return tmp
        case .user:
            let tmp: T? = userStorage.value(forKey: key)
            userStorage.removeObject(forKey: key)
            return tmp
        @unknown default:
            assertionFailure()
            return try remove(key: key, space: .global)
        }
    }

    func clearAll(space: StorageSpace) {
        assertionFailure("This api is temporarily prohibited.")
        switch space {
        case .global:
            globalStorage.clearAll()
        case .user:
            userStorage.clearAll()
        @unknown default:
            assertionFailure()
        }
    }
}
