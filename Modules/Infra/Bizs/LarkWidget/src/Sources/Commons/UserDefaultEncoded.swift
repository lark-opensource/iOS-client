//
//  UserDefaultEncoded.swift
//  LarkWidget
//
//  Created by Hayden Wang on 2022/3/7.
//

import Foundation

#if DEBUG
public let appGrounpName = "group.com.bytedance.ee.lark.yzj"
#else
public let appGrounpName = Bundle.main.infoDictionary?["EXTENSION_GROUP"] as? String ?? ""
#endif

/// 通过 UserDefault 存储数据的 Keys
public enum WidgetDataKeys {

    public static var authInfo: String { "authInfo" }
    public static var legacyData: String { "smartWidgetData" }
    public static var calendarData: String { "calendarWidgetData" }
    public static var displayedCalendarData: String { "calendarWidgetData_display" }
    public static var utilityData: String { "utilityWidgetData" }
    public static var todoData: String { "todoWidgetData" }
    public static var displayedTodoData: String { "todoWidgetData_display" }
    public static var docsWidgetConfig: String { "docsWidgetConfig" }
}

@propertyWrapper
public struct UserDefaultEncoded<T: Codable> {
    let key: String
    let defaultValue: T

    public init(key: String, default: T) {
        self.key = key
        defaultValue = `default`
    }

    public var wrappedValue: T {
        get {
            guard let jsonString = UserDefaults(suiteName: appGrounpName)?.string(forKey: key) else {
                return defaultValue
            }
            guard let jsonData = jsonString.data(using: .utf8) else {
                return defaultValue
            }
            guard let value = try? JSONDecoder().decode(T.self, from: jsonData) else {
                return defaultValue
            }
            return value
        }
        set {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            guard let jsonData = try? encoder.encode(newValue) else { return }
            let jsonString = String(bytes: jsonData, encoding: .utf8)
            assert(!appGrounpName.isEmpty, "App Group ID is empty. Please check it in info.plist contains key: EXTENSION_GROUP.")
            let userDefault = UserDefaults(suiteName: appGrounpName)
            userDefault?.set(jsonString, forKey: key)
            userDefault?.synchronize()
        }
    }
}

public enum WidgetDataManager {

    public static func getWidgetData<T: Codable>(byKey key: String, defaultValue: T) -> T {
        guard let jsonString = UserDefaults(suiteName: appGrounpName)?.string(forKey: key) else {
            return defaultValue
        }
        guard let jsonData = jsonString.data(using: .utf8) else {
            return defaultValue
        }
        guard let value = try? JSONDecoder().decode(T.self, from: jsonData) else {
            return defaultValue
        }
        return value
    }

    public static func setWidgetData<T: Codable>(_ data: T, byKey key: String) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let jsonData = try? encoder.encode(data) else { return }
        let jsonString = String(bytes: jsonData, encoding: .utf8)
        assert(!appGrounpName.isEmpty, "App Group ID is empty. Please check it in info.plist contains key: EXTENSION_GROUP.")
        UserDefaults(suiteName: appGrounpName)?.set(jsonString, forKey: key)
    }

    public static func syncImmediately() {
        UserDefaults(suiteName: appGrounpName)?.synchronize()
    }
}
