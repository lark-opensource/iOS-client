//
//  SettingService.swift
//  LarkSetting
//
//  Created by 王元洵 on 2022/8/4.
//
import RxSwift
import LarkCombine
import LarkContainer

/// 注册进容器的Setting服务
import Foundation
public protocol SettingService {
    /// core property use to distinguish the setting service and call inner implementation
    var id: String { get }
}

private extension SettingService {
    func observe<T>(current: Bool, ignoreError: Bool, getter: @escaping () throws -> T) -> Observable<T> {
        do {
            let signal = SettingStorage.settingRxSubject.filter { $0 == id }
            return ignoreError ? {
                var ob = signal.compactMap { _ in return try? getter() }
                if current, let current = try? getter() { ob = ob.startWith(current) }
                return ob
            }() : try {
                var ob = signal.map { _ in try getter() }
                if current { ob = ob.startWith(try getter()) }
                return ob
            }()
        } catch { return Observable<T>.error(error) }
    }

    func observe<T>(current: Bool, ignoreError: Bool, getter: @escaping () throws -> T) -> AnyPublisher<T, SettingError> {
        do {
            let signal = SettingStorage.settingCombineSubject.filter { $0 == id }
            return ignoreError ? {
                let ob = signal.compactMap { _ in try? getter() }
                if current, let current = try? getter() { return ob.prepend(current).eraseToAnyPublisher() }
                return ob.eraseToAnyPublisher()
            }() : try {
                let ob = signal.tryMap { _ in try getter() }.mapError { SettingError.error(with: $0) }
                if current { return ob.prepend(try getter()).eraseToAnyPublisher() }
                return ob.eraseToAnyPublisher()
            }()
        } catch { return Fail(error: .error(with: error)).eraseToAnyPublisher() }
    }
}

/// 实时setting相关接口
public extension SettingService {
    /// 获取生命周期内可变的setting，返回外部传入的类型，业务方可自定义返回值
    /// 以指定解码策略获取Setting的值，返回外部定义类型，外部类型满足SettingDefaultDecodable
    ///
    /// - Parameters:
    ///   - type: 外部自定义结构体的元类型
    ///   - key: UserSettingKey枚举类型, 用户维度的配置Key
    ///   - decodeStrategy: 解码策略，类型为JSONDecoder.KeyDecodingStrategy
    /// - Returns: 外部自定义类型实例
    ///
    /// ```swift
    /// let a: SettingDefaultDecodable? = resolver.resolve(SettingService.self)?.setting(type: SettingDefaultDecodable.self, defaultValue: someSettingDefaultDecodable)
    /// ```
    func setting<T: SettingDefaultDecodable>(decodeStrategy: JSONDecoder.KeyDecodingStrategy = .convertFromSnakeCase) -> T where T.Key == UserSettingKey { (try? setting(with: T.self, key: T.settingKey, decodeStrategy: decodeStrategy)) ?? T.defaultValue }
    
    /// 获取生命周期内可变的setting，返回外部传入的类型，增加了默认参数
    /// 以指定解码策略获取Setting的值，返回外部定义类型，外部类型满足SettingDecodable
    ///
    /// - Parameters:
    ///   - type: 外部自定义结构体的元类型
    ///   - key: UserSettingKey枚举类型, 用户维度的配置Key
    ///   - decodeStrategy: 解码策略，类型为JSONDecoder.KeyDecodingStrategy
    /// - Returns: 外部自定义类型实例
    ///
    /// ```swift
    /// let a: someSettingDecodable? = resolver.resolve(SettingService.self)?.setting(type: SomeSettingDecodable.self)
    /// ```
    func setting<T: SettingDecodable>(with type: T.Type, decodeStrategy: JSONDecoder.KeyDecodingStrategy = .convertFromSnakeCase) throws -> T  where T.Key == UserSettingKey { try setting(with: type, key: T.settingKey, decodeStrategy: decodeStrategy) }

    /// 获取生命周期内可变的Setting，返回 [String: Any]
    /// 从获取Setting的值，返回原始字典
    ///
    /// - Parameters:
    ///   - key: Setting的key
    /// - Returns: Setting的原始字典
    ///
    /// ```swift
    /// let a: [String: Any]? = resolver.resolve(SettingService.self)?.setting(with: "someKey")
    /// ```
    /// 请勿使用String类型的setting接口获取新增配置
    /// 请在`UserSettingKey`中配置枚举值, 并使用`setting(with key: UserSettingKey)`接口
    @available(*, deprecated, message: "Use setting(with key: UserSettingKey) instead.")
    func setting(with key: String) throws -> [String: Any] { try SettingStorage.setting(with: id, and: key) }

    /// 获取生命周期内可变的Setting，返回 [String: Any]
    /// 从获取Setting的值，返回原始字典
    ///
    /// - Parameters:
    ///   - key: UserSettingKey枚举类型, 用户维度的配置Key
    /// - Returns: Setting的原始字典
    ///
    /// ```swift
    /// let a: [String: Any]? = resolver.resolve(SettingService.self)?.setting(with: UserSettingKey.someKey)
    /// ```
    func setting(with key: UserSettingKey) throws -> [String: Any] { try SettingStorage.setting(with: id, and: String(describing: key.key)) }

    /// 获取生命周期内可变的setting，返回外部传入的类型
    /// 以指定解码策略获取Setting的值，返回外部定义类型，外部类型满足Decodable
    ///
    /// - Parameters:
    ///   - type: 外部自定义结构体的元类型
    ///   - key: Setting的key
    ///   - decodeStrategy: 解码策略，类型为JSONDecoder.KeyDecodingStrategy
    /// - Returns: 外部自定义类型实例
    ///
    /// ```swift
    /// let a: someDecodable? = resolver.resolve(SettingService.self)?.setting(type: SomeSettingDecodable.self,
    ///                                                                       key: "someSettingKey",
    ///                                                                       decodeStrategy:
    ///                                                                       .someDecodeStrategy)
    /// ```
    /// 请勿使用String类型的setting接口获取新增配置
    /// 请在`UserSettingKey`中配置枚举值, 并使用`setting(with key: UserSettingKey)`接口
    @available(*, deprecated, message: "Use setting<T: Decodable>(with type: T.Type, key: UserSettingKey, decodeStrategy: JSONDecoder.KeyDecodingStrategy = .convertFromSnakeCase) instead.")
    func setting<T: Decodable>(with type: T.Type, of key: String, decodeStrategy: JSONDecoder.KeyDecodingStrategy = .convertFromSnakeCase) throws -> T { try SettingStorage.setting(with: id, type: type, key: key, decodeStrategy: decodeStrategy) }


    /// 获取生命周期内可变的setting，返回外部传入的类型
    /// 以指定解码策略获取Setting的值，返回外部定义类型，外部类型满足Decodable
    ///
    /// - Parameters:
    ///   - type: 外部自定义结构体的元类型
    ///   - key: UserSettingKey枚举类型, 用户维度的配置Key
    ///   - decodeStrategy: 解码策略，类型为JSONDecoder.KeyDecodingStrategy
    /// - Returns: 外部自定义类型实例
    ///
    /// ```swift
    /// let a: someDecodable? = resolver.resolve(SettingService.self)?.setting(type: SomeSettingDecodable.self,
    ///                                                                       key: UserSettingKeysomeSettingKey,
    ///                                                                       decodeStrategy:
    ///                                                                       .someDecodeStrategy)
    /// ```
    func setting<T: Decodable>(with type: T.Type, key: UserSettingKey, decodeStrategy: JSONDecoder.KeyDecodingStrategy = .convertFromSnakeCase) throws -> T { try SettingStorage.setting(with: id, type: type, key: key.stringValue, decodeStrategy: decodeStrategy) }
}

/// 静态setting相关接口
public extension SettingService {
    /// 获取生命周期内不变的setting，返回外部传入的类型，业务方可自定义返回值
    /// 以指定解码策略获取Setting的值，返回外部定义类型，外部类型满足SettingDefaultDecodable
    ///
    /// - Parameters:
    ///   - type: 外部自定义结构体的元类型
    ///   - key: Setting的key
    ///   - decodeStrategy: 解码策略，类型为JSONDecoder.KeyDecodingStrategy
    /// - Returns: 外部自定义类型实例
    ///
    /// ```swift
    /// let a: SettingDefaultDecodable? = resolver.resolve(SettingService.self)?.staticSetting(type: SettingDefaultDecodable.self, defaultValue: someSettingDefaultDecodable)
    /// ```
    func staticSetting<T: SettingDefaultDecodable>(decodeStrategy: JSONDecoder.KeyDecodingStrategy = .convertFromSnakeCase) -> T  where T.Key == UserSettingKey { (try? staticSetting(with: T.self, key: T.settingKey, decodeStrategy: decodeStrategy)) ?? T.defaultValue }

    /// 获取生命周期内不变的setting，返回外部传入的类型，增加了默认参数
    /// 以指定解码策略获取Setting的值，返回外部定义类型，外部类型满足Decodable
    ///
    /// - Parameters:
    ///   - type: 外部自定义结构体的元类型
    ///   - key: Setting的key
    ///   - decodeStrategy: 解码策略，类型为JSONDecoder.KeyDecodingStrategy
    /// - Returns: 外部自定义类型实例
    ///
    /// ```swift
    /// let a: someSettingDecodable? = resolver.resolve(SettingService.self)?
    ///                                 .staticSetting(type: SomeSettingDecodable.self)
    /// ```
    func staticSetting<T: SettingDecodable>(with type: T.Type, decodeStrategy: JSONDecoder.KeyDecodingStrategy = .convertFromSnakeCase) throws -> T where T.Key == UserSettingKey { try staticSetting(with: type, key: T.settingKey, decodeStrategy: decodeStrategy) }

    /// 获取生命周期内不变的setting，返回外部传入的类型
    /// 以指定解码策略获取Setting的值，返回外部定义类型，外部类型满足Decodable
    ///
    /// 不保证业务方第一次获取一定是最新值，因为之前可能有其它业务方取过该key
    ///
    /// - Parameters:
    ///   - type: 外部自定义结构体的元类型
    ///   - key: UserSettingKey枚举类型, 用户维度的配置Key
    ///   - decodeStrategy: 解码策略，类型为JSONDecoder.KeyDecodingStrategy
    /// - Returns: 外部自定义类型实例
    ///
    /// ```swift
    /// let a: someDecodable? = resolver.resolve(SettingService.self)?.staticSetting(type: SomeSettingDecodable.self,
    ///                                                                             key: UsersSettingKey.meSettingKey,
    ///                                                                             decodeStrategy: .someDecodeStrategy)
    /// ```
    func staticSetting<T: Decodable>(with type: T.Type, key: UserSettingKey, decodeStrategy: JSONDecoder.KeyDecodingStrategy = .convertFromSnakeCase) throws -> T {
        try SettingStorage.staticSetting(with: id, type: type, key: String(describing: key.key), decodeStrategy: decodeStrategy, useDefaultSetting: false)
    }


    /// 获取生命周期内不变的setting，返回外部传入的类型
    /// 以指定解码策略获取Setting的值，返回外部定义类型，外部类型满足Decodable
    ///
    /// 不保证业务方第一次获取一定是最新值，因为之前可能有其它业务方取过该key
    ///
    /// - Parameters:
    ///   - type: 外部自定义结构体的元类型
    ///   - key: Setting的key
    ///   - decodeStrategy: 解码策略，类型为JSONDecoder.KeyDecodingStrategy
    /// - Returns: 外部自定义类型实例
    ///
    /// ```swift
    /// let a: someDecodable? = resolver.resolve(SettingService.self)?.staticSetting(type: SomeSettingDecodable.self,
    ///                                                                             key: "meSettingKey",
    ///                                                                             decodeStrategy: .someDecodeStrategy)
    /// ```
    @available(*, deprecated, message: "Use staticSetting<T: Decodable>(with type: T.Type, key: UserSettingKey, decodeStrategy: JSONDecoder.KeyDecodingStrategy = .convertFromSnakeCase)  instead.")
    func staticSetting<T: Decodable>(with type: T.Type, of key: String, decodeStrategy: JSONDecoder.KeyDecodingStrategy = .convertFromSnakeCase) throws -> T {
        try SettingStorage.staticSetting(with: id, type: type, key: key, decodeStrategy: decodeStrategy, useDefaultSetting: false)
    }

    /// 获取生命周期内不变的Setting，返回 [String: Any]
    /// 从获取Setting的值，返回原始字典
    ///
    /// - Parameters:
    ///   - key: Setting的key
    /// - Returns: Setting的原始字典
    ///
    /// ```swift
    /// let a: [String: Any]? = resolver.resolve(SettingService.self)?.staticSetting(with: "someKey")
    /// ```
    @available(*, deprecated, message: "Use staticSetting(with key: UserSettingKey) instead.")
    func staticSetting(of key: String) throws -> [String: Any] { try SettingStorage.staticSetting(with: id, and: key) }

    /// 获取生命周期内不变的Setting，返回 [String: Any]
    /// 从获取Setting的值，返回原始字典
    ///
    /// - Parameters:
    ///   - key: UserSettingKey枚举类型, 用户维度的配置Key
    /// - Returns: Setting的原始字典
    ///
    /// ```swift
    /// let a: [String: Any]? = resolver.resolve(SettingService.self)?.staticSetting(with: UserSettingKey.someKey)
    /// ```
    func staticSetting(with key: UserSettingKey) throws -> [String: Any] { try SettingStorage.staticSetting(with: id, and: String(describing: key.key)) }
}

/// observe methods
public extension SettingService {
    /// 以指定的解码方式监听Setting数据变化，返回外部定义类型的Observable，外部类型满足SettingDecodable
    ///
    /// - Parameters:
    ///   - type: 自定义类型的元类型
    ///   - key: Setting的key
    ///   - current: 是否先推送当前值, 默认为true
    ///   - ignoreError: 是否忽略错误，默认为false
    ///   - decodeStrategy: 指定的解码策略
    /// - Returns: 外部定义类型的Observable
    func observe<T: SettingDecodable>(type: T.Type, current: Bool = true, ignoreError: Bool = false, decodeStrategy: JSONDecoder.KeyDecodingStrategy = .convertFromSnakeCase)
    -> Observable<T> where T.Key == UserSettingKey { observe(type: type, key: T.settingKey, current: current, ignoreError: ignoreError, decodeStrategy: decodeStrategy) }

    /// 以指定的解码方式监听Setting数据变化，返回外部定义类型的Observable，外部类型满足Decodable
    ///
    /// - Parameters:
    ///   - type: 自定义类型的元类型
    ///   - key: Setting的key
    ///   - current: 是否先推送当前值, 默认为true
    ///   - ignoreError: 是否忽略错误，默认为false
    ///   - decodeStrategy: 指定的解码策略
    /// - Returns: 外部定义类型的Observable
    func observe<T: Decodable>(type: T.Type, key: UserSettingKey, current: Bool = true, ignoreError: Bool = false, decodeStrategy: JSONDecoder.KeyDecodingStrategy = .convertFromSnakeCase) -> Observable<T> {
        observe(current: current, ignoreError: ignoreError) { try setting(with: T.self, key: key, decodeStrategy: decodeStrategy) }
    }

    /// 监听Setting数据变化，返回[String: Any]的Observable
    ///
    /// - Parameters:
    ///   - key: Setting的key
    ///   - current: 是否先推送当前值, 默认为true
    ///   - ignoreError: 是否忽略错误，默认为false
    /// - Returns: [String: Any]的Observable
    func observe(key: UserSettingKey, current: Bool = true, ignoreError: Bool = false) -> Observable<[String: Any]> {
        observe(current: current, ignoreError: ignoreError) { try setting(with: key) }
    }

    /// 以指定的解码方式监听Setting数据变化，返回外部定义类型的AnyPublisher，外部类型满足SettingDecodable
    ///
    /// - Parameters:
    ///   - type: 自定义类型的元类型
    ///   - key: Setting的key
    ///   - current: 是否先推送当前值, 默认为true
    ///   - ignoreError: 是否忽略错误，默认为false
    ///   - decodeStrategy: 指定的解码策略
    /// - Returns: 外部定义类型的AnyPublisher
    func observe<T: SettingDecodable>(type: T.Type, current: Bool = true, ignoreError: Bool = false, decodeStrategy: JSONDecoder.KeyDecodingStrategy = .convertFromSnakeCase) -> AnyPublisher<T, SettingError> where T.Key == UserSettingKey {
        observe(type: type, key: T.settingKey, current: current, ignoreError: ignoreError, decodeStrategy: decodeStrategy)
    }

    /// 以指定的解码方式监听Setting数据变化，返回外部定义类型的AnyPublisher，外部类型满足Decodable
    ///
    /// - Parameters:
    ///   - type: 自定义类型的元类型
    ///   - key: Setting的key
    ///   - current: 是否先推送当前值, 默认为true
    ///   - ignoreError: 是否忽略错误，默认为false
    ///   - decodeStrategy: 指定的解码策略
    /// - Returns: 外部定义类型的AnyPublisher

    func observe<T: Decodable>(type: T.Type, key: UserSettingKey, current: Bool = true, ignoreError: Bool = false, decodeStrategy: JSONDecoder.KeyDecodingStrategy = .convertFromSnakeCase) -> AnyPublisher<T, SettingError> {
        observe(current: current, ignoreError: ignoreError) {
            try setting(with: T.self, key: key, decodeStrategy: decodeStrategy) }
    }
    /// 监听Setting数据变化，返回[String: Any]的AnyPublisher
    ///
    /// - Parameters:
    ///   - key: Setting的key
    ///   - current: 是否先推送当前值, 默认为true
    ///   - ignoreError: 是否忽略错误，默认为false
    /// - Returns: [String: Any]的AnyPublisher
    func observe(key: UserSettingKey, current: Bool = true, ignoreError: Bool = false) -> AnyPublisher<[String: Any], SettingError> { observe(current: current, ignoreError: ignoreError) { try setting(with: key) } }
}

struct SettingServiceImpl: SettingService {
    let id: String
    let userResolver: UserResolver
}
