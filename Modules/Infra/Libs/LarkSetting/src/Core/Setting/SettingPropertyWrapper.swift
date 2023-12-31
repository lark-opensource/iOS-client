//
//  SettingPropertyWrapper.swift
//  LarkSetting
//
//  Created by Supeng on 2021/6/18.
//

/// 取setting值的propertyWrapper，返回外部自定义类型，创建变量的时候会去取最新setting值
/// 之后每一次返回值都和第一次相同
import Foundation
@propertyWrapper
public struct Setting<T: Decodable> {
    /// 实际返回的值
    public let wrappedValue: T?

    /// 外部可以使用@Setting(key: )声明setting变量
    ///
    /// ```swift
    /// @Setting(key: UserSettingKey.someSettingKey) private var someSetting: someDecodeable?
    /// ```
    public init(key: UserSettingKey, _ decodeStrategy: JSONDecoder.KeyDecodingStrategy = .convertFromSnakeCase) {
        wrappedValue = try? SettingManager.shared.setting(with: T.self, key: key, decodeStrategy: decodeStrategy) //Global
    }

    /// 外部可以使用@Setting声明setting变量
    ///
    /// ```swift
    /// @Setting private var someSetting: someSettingDecodable?
    /// ```
    public init(_ decodeStrategy: JSONDecoder.KeyDecodingStrategy = .convertFromSnakeCase) where T: SettingDecodable, T.Key == UserSettingKey {
        wrappedValue = try? SettingManager.shared.setting(with: T.self, //Global
                                                          key: T.settingKey,
                                                          decodeStrategy: decodeStrategy)
    }
}

/// 取setting值的propertyWrapper，返回外部自定义类型，创建变量的时候会去取setting值，取不到返回自定义默认值
/// 之后每一次返回值都和第一次相同
@propertyWrapper
public struct SettingValue<T: Decodable> {
    /// 实际返回的值
    public let wrappedValue: T

    /// 外部可以使用@SettingValue(key:defaultValue:)声明setting变量
    ///
    /// ```swift
    /// @SettingValue(key: UserSettingKey.someSettingKey, defaultValue: value)
    /// private var someSetting: someDecodeable
    /// ```
    public init(key: UserSettingKey,
                defaultValue: T,
                _ decodeStrategy: JSONDecoder.KeyDecodingStrategy = .convertFromSnakeCase) {
        wrappedValue = (try? SettingManager.shared.setting(with: T.self, //Global
                                                          key: key,
                                                          decodeStrategy: decodeStrategy)) ?? defaultValue
    }

    /// 外部可以使用@SettingValue(default:)声明setting变量，取不到返回自定义默认值
    ///
    /// ```swift
    /// @SettingValue(defaultValue: value)
    /// private var someSetting: someSettingDecodable
    /// ```
    public init(defaultValue: T,
                _ decodeStrategy: JSONDecoder.KeyDecodingStrategy = .convertFromSnakeCase) where T: SettingDecodable, T.Key == UserSettingKey {
        wrappedValue = (try? SettingManager.shared.setting(with: T.self, //Global
                                                           key: T.settingKey,
                                                           decodeStrategy: decodeStrategy)) ?? defaultValue
    }

    /// 外部可以使用 @SettingValue 声明setting变量，取不到返回自定义默认值
    ///
    /// ```swift
    /// @SettingValue
    /// private var someSetting: someSettingDefaultDecodable
    /// ```
    public init(_ decodeStrategy: JSONDecoder.KeyDecodingStrategy = .convertFromSnakeCase)
    where T: SettingDefaultDecodable, T.Key == UserSettingKey {
        wrappedValue = (try? SettingManager.shared.setting(with: T.self, //Global
                                                           key: T.settingKey,
                                                           decodeStrategy: decodeStrategy)) ?? T.defaultValue
    }
}

/// 取setting值的propertyWrapper，返回外部自定义类型，第一次访问变量的时候才会去取setting值
/// 之后每一次返回值都和第一次相同
@propertyWrapper
public struct LazySetting<T: Decodable> {

    /// 实际返回的值
    public lazy var wrappedValue: T? = try? SettingManager.shared.setting(with: T.self, //Global
                                                                          key: key,
                                                                          decodeStrategy: decodeStrategy)

    private let key: UserSettingKey
    private let decodeStrategy: JSONDecoder.KeyDecodingStrategy

    /// 外部可以使用@LazySetting(key: )声明setting变量
    ///
    /// ```swift
    /// @LazySetting(key: UserSettingKey.someSettingKey) private var someSetting: someDecodeable?
    /// ```
    public init(key: UserSettingKey, _ decodeStrategy: JSONDecoder.KeyDecodingStrategy = .convertFromSnakeCase) {
        self.key = key
        self.decodeStrategy = decodeStrategy
    }

    /// 外部可以使用@LazySetting声明setting变量
    ///
    /// ```swift
    /// @LazySetting private var someSetting: someSettingDecodable?
    /// ```
    public init(_ decodeStrategy: JSONDecoder.KeyDecodingStrategy = .convertFromSnakeCase)
    where T: SettingDecodable, T.Key == UserSettingKey  {
        self.key = T.settingKey
        self.decodeStrategy = decodeStrategy
    }

    /// 外部可以使用"$"符号访问原始字典
    ///
    /// e.g.: let a = $someSetting (a为[String: Any]?)
    public var projectedValue: [String: Any]? { try? SettingManager.shared.setting(with: key) } //Global
}

/// 取setting值的propertyWrapper，返回外部自定义类型，第一次访问变量的时候才会去取setting值，取不到返回默认值
/// 之后每一次返回值都和第一次相同
@propertyWrapper
public struct LazySettingValue<T: Decodable> {

    /// 实际返回的值
    public lazy var wrappedValue: T = {
        (try? SettingManager.shared.setting(with: T.self, key: key, decodeStrategy: decodeStrategy)) ?? defaultValue //Global
    }()

    private let key: UserSettingKey
    private let defaultValue: T
    private let decodeStrategy: JSONDecoder.KeyDecodingStrategy

    /// 外部可以使用@LazySettingValue(key:defaultValue:)声明setting变量，取不到返回自定义默认值
    ///
    /// ```swift
    /// @LazySettingValue(key: UserSettingKey.someSettingKey, defaultValue: value)
    /// private var someSetting: someDecodeable
    /// ```
    public init(key: UserSettingKey,
                defaultValue: T, _ decodeStrategy: JSONDecoder.KeyDecodingStrategy = .convertFromSnakeCase) {
        self.key = key
        self.defaultValue = defaultValue
        self.decodeStrategy = decodeStrategy
    }

    /// 外部可以使用 @LazySettingValue(defaultValue:) 声明setting变量，取不到返回自定义默认值
    ///
    /// ```swift
    /// @LazySettingValue(defaultValue: value)
    /// private var someSetting: someSettingDecodable
    /// ```
    public init(defaultValue: T,
                _ decodeStrategy: JSONDecoder.KeyDecodingStrategy = .convertFromSnakeCase)
    where T: SettingDecodable, T.Key == UserSettingKey {
        self.key = T.settingKey
        self.defaultValue = defaultValue
        self.decodeStrategy = decodeStrategy
    }

    /// 外部可以使用 @LazySettingValue 声明setting变量，取不到返回自定义默认值
    ///
    /// ```swift
    /// @LazySettingValue
    /// private var someSetting: someSettingDecodable
    /// ```
    public init(_ decodeStrategy: JSONDecoder.KeyDecodingStrategy = .convertFromSnakeCase)
    where T: SettingDefaultDecodable, T.Key == UserSettingKey {
        self.key = T.settingKey
        self.defaultValue = T.defaultValue
        self.decodeStrategy = decodeStrategy
    }
}

/// 取setting值的propertyWrapper，返回外部自定义类型，每一次访问变量的时候都会去取setting值
@propertyWrapper
public struct ProviderSetting<T: Decodable> {

    /// 实际返回的值
    public var wrappedValue: T? {
        try? SettingManager.shared.setting(with: T.self, key: key, decodeStrategy: decodeStrategy) //Global
    }

    private let key: UserSettingKey
    private let decodeStrategy: JSONDecoder.KeyDecodingStrategy

    /// 外部可以使用@ProviderSetting(key: )声明setting变量
    ///
    /// ```swift
    /// @ProviderSetting(key:"someSettingKey") private var someSetting: someDecodeable?
    /// ```
    public init(key: UserSettingKey, _ decodeStrategy: JSONDecoder.KeyDecodingStrategy = .convertFromSnakeCase) {
        self.key = key
        self.decodeStrategy = decodeStrategy
    }

    /// 外部可以使用@ProviderSetting声明setting变量
    ///
    /// ```swift
    /// @ProviderSetting private var someSetting: someSettingDecodable?
    /// ```
    public init(_ decodeStrategy: JSONDecoder.KeyDecodingStrategy = .convertFromSnakeCase)
    where T: SettingDecodable, T.Key == UserSettingKey {
        self.key = T.settingKey
        self.decodeStrategy = decodeStrategy
    }

    /// 外部可以使用"$"符号访问原始字典
    ///
    /// e.g.: let a = $someSetting (a为[String: Any]?)
    public var projectedValue: [String: Any]? { try? SettingManager.shared.setting(with: key) } //Global
}

/// 取setting值的propertyWrapper，返回外部自定义类型，每一次访问变量的时候都会去取setting值，取不到返回自定义默认值
@propertyWrapper
public struct ProviderSettingValue<T: Decodable> {

    /// 实际返回的值
    public var wrappedValue: T {
        (try? SettingManager.shared.setting(with: T.self, key: key, decodeStrategy: decodeStrategy)) ?? defaultValue //Global
    }

    private let key: UserSettingKey
    private let defaultValue: T
    private let decodeStrategy: JSONDecoder.KeyDecodingStrategy

    /// 外部可以使用@ProviderSettingValue(key: )声明setting变量，取不到返回自定义默认值
    ///
    /// ```swift
    /// @ProviderSettingValue(key: UserSettingKey.someSettingKey, defaultValue: value)
    /// private var someSetting: someDecodeable
    /// ```
    public init(key: UserSettingKey,
                defaultValue: T, _ decodeStrategy: JSONDecoder.KeyDecodingStrategy = .convertFromSnakeCase) {
        self.key = key
        self.defaultValue = defaultValue
        self.decodeStrategy = decodeStrategy
    }

    /// 外部可以使用 @ProviderSetting(defaultValue:) 声明setting变量，取不到返回自定义默认值
    ///
    /// ```swift
    /// @ProviderSettingValue(defaultValue: value)
    /// private var someSetting: someSettingDecodable
    /// ```
    public init(defaultValue: T, _ decodeStrategy: JSONDecoder.KeyDecodingStrategy = .convertFromSnakeCase)
    where T: SettingDecodable, T.Key == UserSettingKey {
        self.key = T.settingKey
        self.defaultValue = defaultValue
        self.decodeStrategy = decodeStrategy
    }

    /// 外部可以使用 @ProviderSettingValue 声明setting变量
    ///
    /// ```swift
    /// @ProviderSettingValue
    /// private var someSetting: someSettingDecodable
    /// ```
    public init(_ decodeStrategy: JSONDecoder.KeyDecodingStrategy = .convertFromSnakeCase)
    where T: SettingDefaultDecodable, T.Key == UserSettingKey {
        self.key = T.settingKey
        self.defaultValue = T.defaultValue
        self.decodeStrategy = decodeStrategy
    }
}

/// 取setting值的propertyWrapper，返回原始字典，创建变量的时候会去取setting值
/// 之后每一次返回值都和第一次相同
@propertyWrapper
public struct RawSetting {
    /// 实际返回的值
    public let wrappedValue: [String: Any]?

    /// 外部可以使用@RawSetting(key: )声明setting变量
    ///
    /// ```swift
    /// @RawSetting(key:"someSettingKey") private var someSetting: [String: Any]?
    /// ```
    public init(key: UserSettingKey) { wrappedValue = try? SettingManager.shared.setting(with: key) } //Global
}

/// 取setting值的propertyWrapper，返回原始字典，第一次访问变量的时候才会去取setting值
/// 之后每一次返回值都和第一次相同
@propertyWrapper
public struct LazyRawSetting {
    /// 实际返回的值
    public lazy var wrappedValue: [String: Any]? = try? SettingManager.shared.setting(with: key) //Global

    private let key: UserSettingKey

    /// 外部可以使用@LazyRawSetting(key: )声明setting变量
    ///
    /// ```swift
    /// @LazyRawSetting(key:"someSettingKey") private var someSetting: [String: Any]?
    /// ```
    public init(key: UserSettingKey) { self.key = key }
}

/// 取setting值的propertyWrapper，返回原始字典，每一次访问变量的时候都会去取setting值
@propertyWrapper
public struct ProviderRawSetting {
    /// 实际返回的值
    public var wrappedValue: [String: Any]? {
        try? SettingManager.shared.setting(with: key) //Global
    }

    private let key: UserSettingKey

    /// 外部可以使用@ProviderRawSetting(key: )声明setting变量
    ///
    /// ```swift
    /// @ProviderRawSetting(key:"someSettingKey") private var someSetting: [String: Any]?
    /// ```
    public init(key: UserSettingKey) { self.key = key }
}
