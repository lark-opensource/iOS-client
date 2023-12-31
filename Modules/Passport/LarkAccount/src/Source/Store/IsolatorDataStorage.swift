//
//  IsolatorDataStorage.swift
//  LarkAccount
//
//  Created by bytedance on 2021/5/19.
//

import Foundation
import LKCommonsLogging

// iOS 12 无法 encode 基本类型
// https://bugs.swift.org/browse/SR-6163
struct JSONWrapper<T: Codable>: Codable {
    let value: T
}

public final class IsolateUserDefaultsData: IsolateDataKVProtocol {
    var config: IsolatorConfig
    var isolatorLayer: String
    private var userDefaults: UserDefaults
    private let logger: Log
    private var shouldEncrypted: Bool

    //基本数据类型（或者自定义类型）转Data
    @inline(__always)
    private static func toData<T>(_ value: T) -> Data? where T: Codable {
        do {
            let wrappedValue = JSONWrapper(value: value)
            return try JSONEncoder().encode(wrappedValue)
        } catch {
            // 此处与 logger 冲突，无法打印日志
            assertionFailure("Failed to encode data, error: \(error)")
            return nil
        }
    }

    // Data 转基本数据类型（或者自定义类型）
    @inline(__always)
    private static func toValue<T>(_ valueType: T.Type, data: Data) -> T? where T: Codable {
        do {
            let wrappedValue = try JSONDecoder().decode(JSONWrapper<T>.self, from: data)
            return wrappedValue.value
        } catch {
            // 此处与 logger 冲突，无法打印日志
            assertionFailure("Failed to encode data, error: \(error)")
            return nil
        }
    }

    //文件地址
    private func isolatorFilePath() -> String {
        NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0].appending("/Preferences/\(self.isolatorLayer).plist")
    }

    required init(config: IsolatorConfig, isolatorLayer: String) {
        self.config = config
        self.isolatorLayer = isolatorLayer
        self.logger = Logger.log(config.loggerClass, category: "IsolateUserDefaultsData")
        self.shouldEncrypted = config.shouldEncrypted
        if let ud = UserDefaults(suiteName: isolatorLayer) {
            self.userDefaults = ud
            SuiteLoginUtil.addSkipBackupForFile(NSURL.init(fileURLWithPath: isolatorFilePath()))
        } else {
            self.userDefaults = UserDefaults.standard
            self.logger.error("UserDefaults init with suiteName failed.")
        }
    }

    func update<T>(key: PassportStorageKey<T>, value: T?) -> IsolateDataKVProtocol where T: Codable {
        var infoData: Data
        guard let data = Self.toData(value) else {
            self.logger.error("Update value for \(key.hashedValue) error: failed when transform to data type")
            return self
        }
        if self.shouldEncrypted {
            do {
                infoData = try aes(.encrypt, data)
                self.userDefaults.setValue(infoData, forKey: key.hashedValue)
            } catch let error {
                self.logger.error("Update value for \(key.hashedValue) error when encrypt: \(error)")
            }
        } else {
            self.userDefaults.setValue(data, forKey: key.hashedValue)
        }

        return self
    }

    func remove<T>(key: PassportStorageKey<T>) -> IsolateDataKVProtocol where T: Codable {
        self.userDefaults.removeObject(forKey: key.hashedValue)
        return self
    }

    public func removeDataStorage() {
        // 删除 userDefaults 的所有内容, 必须项. userDefaults 有内存的缓存
        userDefaults.dictionaryRepresentation().keys.forEach { key in
            userDefaults.removeObject(forKey: key)
        }

        //清除plist文件，可以根据这个path进去本地查看plist文件是否被清除
        let path = isolatorFilePath()
        do {
            if FileManager.default.fileExists(atPath: path) {
                try FileManager.default.removeItem(atPath: path)
            } else {
                self.logger.info("no such plist file for suitenamed: \(self.isolatorLayer)")
            }
        } catch {
            self.logger.info("failed to remove plist file for suitenamed: \(self.isolatorLayer)")
        }
    }

    func get<T>(key: PassportStorageKey<T>) -> T? where T: Codable {
        guard let data = self.userDefaults.value(forKey: key.hashedValue) as? Data else {
            self.logger.info("get nil value for \(key.hashedValue): no such key")
            return nil
        }

        do {
            let infoData: Data
            if self.shouldEncrypted {
                infoData = try aes(.decrypt, data)
            } else {
                infoData = data
            }
            guard let value = Self.toValue(T.self, data: infoData) else {
                self.logger.info("get nil value for \(key.hashedValue): transform failed")
                return nil
            }
            return value
        } catch let error {
            self.logger.info("get nil value for \(key.hashedValue), decrypt failed with error: \(error)")
            return nil
        }
    }
}
