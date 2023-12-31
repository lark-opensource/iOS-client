//
//  LarkInterface+FeatureSwitchDebug.swift
//  LarkInterface
//
//  Created by Chang Rong on 2019/9/3.
//

import UIKit
import Foundation

// Debug 工具代码，无需进行统一存储规则检查
// lint:disable lark_storage_check

extension Feature {
    static func getByName(name: String) -> Feature? {
        for i in 0 ..< allCases.count {
            let feature = Feature(rawValue: i)!
            if "\(feature)" == name {
                return feature
            }
        }
        return nil
    }
}

extension ApplyConfig {
    static func getByName(name: String) -> ApplyConfig? {
        if name == "on" {
            return .on
        } else if name == "off" {
            return .off
        } else if name == "downgraded" {
            return .downgraded
        } else {
            return nil
        }
    }
}

// swiftlint:disable missing_docs
public struct FeatureSwitchDebug {

    private static let featureSwitchKey = "padFeatureSwitchDebugKey"

    private static var featureSwitchDebug: [Feature: ApplyConfig] {
        if let confg = _featureSwitchDebug {
            return confg
        }
        _featureSwitchDebug = getFeatureSwitchFromStorage()
        return _featureSwitchDebug!
    }

    private static var _featureSwitchDebug: [Feature: ApplyConfig]?

    public static func write(feature: Feature, value: String) {
        guard let config = ApplyConfig.getByName(name: value) else {
            clear(feature: feature)
            return
        }
        var fsInStorage = getFeatureSwitchFromStorage()
        fsInStorage[feature] = config
        save(cache: fsInStorage)
    }

    public static func clear() {
        UserDefaults.standard.removeObject(forKey: featureSwitchKey)
        UserDefaults.standard.synchronize()
    }

    public static func clear(feature: Feature) {
        var fsInStorage = getFeatureSwitchFromStorage()
        fsInStorage.removeValue(forKey: feature)
        save(cache: fsInStorage)
    }

    static func getFeatureFromDebug(feature: Feature) -> ApplyConfig? {
        guard UIDevice.current.userInterfaceIdiom == .pad else { return nil }
        return featureSwitchDebug[feature]
    }

    static func getFeatureSwitchFromStorage() -> [Feature: ApplyConfig] {
        guard let data = UserDefaults.standard.object(forKey: featureSwitchKey) as? [String: String] else {
            return [:]
        }
        var fs: [Feature: ApplyConfig] = [:]
        data.forEach { (key, value) in
            guard let feature = Feature.getByName(name: key),
                let config = ApplyConfig.getByName(name: value) else {
                    return
            }
            fs[feature] = config
        }
        return fs
    }

    static func save(cache: [Feature: ApplyConfig]) {
        var data: [String: String] = [:]
        cache.forEach { (feature, config) in
            data["\(feature)"] = "\(config)"
        }
        UserDefaults.standard.set(data, forKey: featureSwitchKey)
        UserDefaults.standard.synchronize()
    }
}
// swiftlint:enable missing_docs
