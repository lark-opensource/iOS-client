//
//  UUIDManager.swift
//  SuiteLogin
//
//  Created by Yiming Qu on 2019/11/12.
//

import Foundation
import KeychainAccess
import LarkReleaseConfig
import LKCommonsLogging

class UUIDManager {

    static let shared = UUIDManager()

    static let source: String = "UUID"

    private init() {
        userDefault = SuiteLoginUtil.userDefault()
    }

    var uuid: UUID {
        lock.wait()
        defer { lock.signal() }
        let res: UUID
        let cacheType: CacheType
        if let memUUID = memoryUUID {
            res = memUUID
            cacheType = .memory
        } else if let uuid = userDefaultUUID {
            memoryUUID = uuid
            res = uuid
            cacheType = .userDefault
        } else {
            let id = Foundation.UUID().uuidString
            let uuid = UUID(from: .uuid, value: id)
            memoryUUID = uuid
            userDefaultUUID = uuid
            res = uuid
            cacheType = .uuid
        }
        UUIDManager.logger.info("read uuid: \(res) cacheType: \(cacheType)")
        return res
    }

    private static let logger = Logger.log(UUIDManager.self, category: "UUIDManager")

    private var memoryUUID: UUID?

    private var userDefaultUUID: UUID? {
        set {
            set(value: newValue, key: uuidKey)
        }
        get {
            return get(key: uuidKey)
        }
    }

    private func get(key: String) -> UUID? {
        if let jsonStr = pureGet(key: key) {
            if let uuid = UUID.from(jsonStr) {
                UUIDManager.logger.info("get uuid: \(uuid)")
                return uuid
            } else {
                UUIDManager.logger.info("decode uuid from jsonStr get nil")
                return nil
            }
        } else {
            UUIDManager.logger.info("read uuid get nil")
            return nil
        }
    }

    private func set(value: UUID?, key: String) {
        if let jsonStr = value?.toJSONString() {
            UUIDManager.logger.info("set uuid jsonStr: \(jsonStr)")
            pureSetValue(jsonStr, key: key)
        } else {
            UUIDManager.logger.warn("set uuid is nil")
            pureSetValue(nil, key: key)
        }
    }

    private let userDefault: UserDefaults

    private let uuidKey: String = "SuiteLoginUUIDKey"

    private let lock = DispatchSemaphore(value: 1)

    enum CacheType {
        case memory
        case userDefault
        case keycahin
        case idfv
        case uuid
    }

    enum From: String, Codable, CustomStringConvertible {
        case idfv
        case uuid
        var description: String {
            switch self {
            case .idfv:
                return "idfv"
            case .uuid:
                return "uuid"
            }
        }
    }

    struct UUID: Codable, CustomStringConvertible {
        let from: From
        let value: String
        enum CodingKeys: String, CodingKey {
            case from
            case value
        }

        var description: String {
            return "[\(value.description), \(from.description)]"
        }

        func toJSONString() -> String? {
            do {
                let data = try JSONEncoder().encode(self)
                if let jsonStr = String(data: data, encoding: .utf8) {
                    return jsonStr
                } else {
                    UUIDManager.logger.error("uuid data: \(data) decode to JSONString fail)")
                    return nil
                }
            } catch {
                UUIDManager.logger.error("UUID obj encode to data fail error: \(error)")
                return nil
            }
        }

        static func from(_ JSONString: String) -> UUID? {
            guard let data = JSONString.data(using: .utf8) else {
                UUIDManager.logger.error("uuid JSONString: \(JSONString) encode to utf8 data fail")
                return nil
            }
            do {
                let uuid = try JSONDecoder().decode(UUID.self, from: data)
                return uuid
            } catch {
                UUIDManager.logger.error("uuid data decode to UUID obj fail error: \(error)")
                return nil
            }
        }
    }
}

// MARK: Get & Set

extension UUIDManager {
    private func pureSetValue(_ value: String?, key: String) {
        userDefault.setValue(value, forKey: key)
        userDefault.synchronize()
    }

    private func pureGet(key: String) -> String? {
        return userDefault.string(forKey: key)
    }
}
