//
//  ServerInfoProvider.swift
//  LarkAccountInterface
//
//  Created by Yiming Qu on 2021/1/13.
//

import Foundation
import LarkEnv

// swiftlint:disable missing_docs
@frozen
public enum DomainAliasKey: CaseIterable {
    /// 使用服务环境的 .api 动态域名
    case api
    /// 跟随包环境使用 .api 域名
    case apiUsingPackageDomain

    /// 使用服务环境的 .passportAccounts 动态域名
    case passportAccounts
    /// 跟随包环境使用 .passportAccounts 域名
    case passportAccountsUsingPackageDomain

    /// 以下全部使用动态环境

    case ttGraylog
    case privacy
    case device
    case ttApplog
    // 使用包环境的ttApplog域名
    case ttApplogUsingPackageDomain
    case passportTuring
    case passportTuringUsingPackageDomain
    case privacyUsingPackageDomain
    case open
}

@frozen
public enum URLKey: CaseIterable {
    /// 使用服务环境的 .api 动态域名
    case api
    /// 跟随包环境使用 .api 域名
    case apiUsingPackageDomain

    /// 使用服务环境的 .passportAccounts 动态域名
    case passportAccounts
    /// 跟随包环境使用 .passportAccounts 域名
    case passportAccountsUsingPackageDomain

    /// 以下全部使用动态环境

    case privacyPolicy
    case serviceTerm
    case deviceId
    case userDeletionAgreement
    case open
}

@frozen
public enum ServerInfoProviderType {
    /// rust动态域名
    case rustDynamicDomain
    /// 客户端静态编译配置
    case nativeStaticSettings
    /// Rust静态编译配置
    case rustStaticSettings
    /// 运行时注入配置
    case runtimeInjectConfig
    /// SDK V1 运行时注入配置
    case oldRuntimeInjectConfig
    case notFound
}

public struct DomainValue: CustomStringConvertible {
    public let value: String?
    public let provider: ServerInfoProviderType

    public var description: String {
        "[val: \(String(describing: value)); provider: \(provider)]"
    }

    public init(
        value: String?,
        provider: ServerInfoProviderType
    ) {
        self.value = value
        self.provider = provider
    }
}

public struct URLValue: CustomStringConvertible {
    public let value: String?
    public let provider: ServerInfoProviderType

    public var description: String {
        "[val: \(String(describing: value)); provider: \(provider)]"
    }

    public init(
        value: String?,
        provider: ServerInfoProviderType
    ) {
        self.value = value
        self.provider = provider
    }
}

public typealias RegistryPriority = Int

public protocol DomainProviderProtocol {
    func getDomain(_ key: DomainAliasKey) -> DomainValue
    //异步获取指定env brand的域名
    func asyncGetDomain(_ env: Env, brand: String, key: DomainAliasKey, completionHandler: @escaping (DomainValue) -> Void)
}

public protocol URLProviderProtocol {
    func getUrl(_ key: URLKey) -> URLValue
}

public extension RegistryPriority {
    static let highest: Int = 1_000
    static let high: Int = 750
    static let medium: Int = 500
    static let low: Int = 250
    static let lowest: Int = 100
}

public final class DomainProviderRegistry {

    public static var registered: [(value: DomainProviderProtocol, priority: RegistryPriority)] = []

    public static func register(value: DomainProviderProtocol, priority: RegistryPriority) {
        registered.append((value: value, priority: priority))
    }

    public static var providers: [DomainProviderProtocol] {
        registered.sorted { $0.priority > $1.priority }.map({ $0.value })
    }
}

public final class URLProviderRegistry {

    public static var registered: [(value: URLProviderProtocol, priority: RegistryPriority)] = []

    public static func register(value: URLProviderProtocol, priority: RegistryPriority) {
        registered.append((value: value, priority: priority))
    }

    public static var providers: [URLProviderProtocol] {
        registered.sorted { $0.priority > $1.priority }.map({ $0.value })
    }
}

// swiftlint:enable missing_docs
