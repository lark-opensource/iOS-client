//
//  EnvDelegateRegistry.swift
//  LarkEnv
//
//  Created by Yiming Qu on 2021/1/24.
//

import UIKit
import Foundation

// swiftlint:disable missing_docs

public typealias EnvDelegateProvider = () -> EnvDelegate

public final class EnvDelegateFactory {
    private let delegateProvider: EnvDelegateProvider

    // swiftlint:disable weak_delegate
    public lazy var delegate: EnvDelegate = {
        let envDelegate = self.delegateProvider()
        let identify = ObjectIdentifier(type(of: envDelegate))
        EnvDelegateRegistry.delegatesCache[identify] = envDelegate
        return envDelegate
    }()
    // swiftlint:enable weak_delegate

    public init(delegateProvider: @escaping EnvDelegateProvider) {
        self.delegateProvider = delegateProvider
    }
}

public final class EnvDelegateRegistry {

    public internal(set) static var factories = [EnvDelegateFactory]()

    internal static var delegatesCache: [ObjectIdentifier: EnvDelegate] = [:]

    ///  注册EnvDelegate工厂(线程不安全，请在Assembly中注册)
    /// - Parameter factory: EnvDelegate工厂
    public static func register(factory: EnvDelegateFactory) {
        factories.append(factory)
    }
}

public typealias EnvDelegatePriority = CGFloat

extension EnvDelegatePriority {
    public static let highest: CGFloat = 1_000.0
    public static let high: CGFloat = 750.0
    public static let medium: CGFloat = 500.0
    public static let low: CGFloat = 250.0
    public static let lowest: CGFloat = 0.0
}

public enum EnvDelegateAspect {
    case before
    case after
}

public typealias EnvDelegateConfig = [EnvDelegateAspect: EnvDelegatePriority]

// swiftlint:enable missing_docs
