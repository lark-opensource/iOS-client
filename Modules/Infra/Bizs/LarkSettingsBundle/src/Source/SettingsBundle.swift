//
//  SettingsBundle.swift
//  Lark
//
//  Created by Miaoqi Wang on 2020/3/27.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import LKCommonsLogging

/// Settings.bundle need load when app first install
final class SettingsBundle {
    static let logger = Logger.log(SettingsBundle.self, category: "Module.SettingsBundle")

    enum SystemKey {
        static let preferenceItem = "PreferenceSpecifiers"
        static let preferenceKey = "Key"
        static let preferenceDefaultValue = "DefaultValue"
    }

    class func loadPreferenceIfNeed() {
        if UserDefaults.standard.object(forKey: CustomKey.resetCache) == nil {
            loadPreference()
        } else {
            logger.debug("Settings.bundle is loaded")
        }
    }

    class func loadPreference() {
        guard let settingsBundle = Bundle.main.path(forResource: "Settings", ofType: "bundle") else {
            logger.error("not found Settings.bundle")
            return
        }
        let plistFilePath = "\(settingsBundle)/Root.plist"
        guard let plistData = FileManager.default.contents(atPath: plistFilePath) else {
            logger.error("read plist data failed", additionalData: ["filePath": plistFilePath])
            return
        }
        do {
            var propertyListFormat = PropertyListSerialization.PropertyListFormat.xml
            let settingsPlist = try PropertyListSerialization.propertyList(from: plistData, options: .mutableContainersAndLeaves, format: &propertyListFormat)

            guard let settings = settingsPlist as? [String: Any] else {
                logger.error("cast setting plist to [String: Any] failed")
                return
            }
            guard let preferenceItem = settings[SystemKey.preferenceItem] as? [[String: Any]] else {
                logger.error("not found preference item")
                return
            }
            preferenceItem.forEach { (dict) in
                if let key = dict[SystemKey.preferenceKey] as? String {
                    let value = dict[SystemKey.preferenceDefaultValue]
                    logger.info("set user default", additionalData: [key: "\(String(describing: value))"])
                    UserDefaults.standard.set(value, forKey: key)
                } else {
                    logger.debug("this item doesnt contain SystemKey.preferenceKey")
                }
            }
        } catch {
            logger.error("settings dictionary init failed", error: error)
        }
    }
}

// MARK: - settings

extension SettingsBundle {
    enum CustomKey {
        static let resetCache = "settings.bundle.troubleShooting.resetCache"
    }

    class func needResetCache() -> Bool {
        return UserDefaults.standard.bool(forKey: CustomKey.resetCache)
    }

    class func setNeedResetCache(_ newValue: Bool) {
        UserDefaults.standard.set(newValue, forKey: CustomKey.resetCache)
    }
}
