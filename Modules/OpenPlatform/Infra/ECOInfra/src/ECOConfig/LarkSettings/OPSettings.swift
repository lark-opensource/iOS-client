//
//  OPSettings.swift
//  OPPlugin
//
//  Created by baojianjun on 2023/9/19.
//

import Foundation
import LarkSetting
import LKCommonsLogging

private let kDefaultKey = "default"

public final class OPSettings<T> {
    
    struct Key: Hashable {
        let appID: String?
        let appType: String?
    }
    
    private let logger: Log
    private let settingKey: UserSettingKey
    private let tag: String
    private let localDefault: T
    
    public init(key: UserSettingKey, tag: String, defaultValue: T) {
        self.settingKey = key
        self.tag = tag
        self.localDefault = defaultValue
        self.logger = Logger.log(Self.self, category: "")
    }
    
    private var storage: [OPSettings.Key: T] = [:]
    
    public func getValue(appID: String? = nil, appType: String? = nil) -> T {
        let key = OPSettings.Key(appID: appID, appType: appType)
        if let lazyValue = storage[key] {
            return lazyValue
        }
        
        guard let settingDict = try? SettingManager.shared.setting(with: settingKey), !settingDict.isEmpty else {
            return saveValue(key, localDefault, "localDefault with no settingDict")
        }
        
        let from = settingDict["from"] as? String ?? "local"
        let settingDefault = settingDict[kDefaultKey] as? T
        
        logger.info("\(settingKey.stringValue) from \(from)")
        
        func getDefault() -> T {
            guard let settingDefault else {
                return saveValue(key, localDefault, "localDefault with no settingDefault")
            }
            return saveValue(key, settingDefault, "settingDefault")
        }
        
        guard let tagDict = settingDict[tag] as? [String: Any] else {
            return getDefault()
        }
        
        if let appID = appID, let appIDDict = tagDict["app_id"] as? [String: Any],
           let result = getValue(appType: appType, detailDict: appIDDict[appID]) {
            return saveValue(key, result, "app_id value")
        }
        if let result = getValue(appType: appType, detailDict: tagDict["app_type"]) {
            return saveValue(key, result, "app_type value")
        }
        
        if let innerDefaultValue = tagDict[kDefaultKey] as? T {
            return saveValue(key, innerDefaultValue, "innerDefaultValue")
        }
        
        return getDefault()
    }
    
    private func saveValue(_ key:OPSettings.Key, _ value: T, _ log: String) -> T {
        logger.info("return \(log): \(value)")
        storage[key] = value
        return value
    }
    
    private func getValue(appType: String?, detailDict: Any?) -> T? {
        guard let detailDict = detailDict as? [String: Any] else {
            logger.info("no detailDict")
            return nil
        }
        if let appType = appType, let result = detailDict[appType] as? T {
            logger.info("find result \(appType), result: \(result)")
            return result
        }
        if let defaultValue = detailDict[kDefaultKey] as? T {
            logger.info("find defaultValue: \(defaultValue)")
            return defaultValue
        }
        return nil
    }
}

