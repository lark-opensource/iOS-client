//
//  PassportDelegate.swift
//  LarkAccountInterface
//
//  Created by Nix Wang on 2022/8/8.
//

import Foundation
import RxSwift
import RxCocoa

public protocol PassportDelegate {

    /// online 的原因可能是 login、switch、fastLogin，请注意按需要排除 fastLogin 的场景，避免不需要的逻辑
    func userDidOnline(state: PassportState)

    /// offline 的原因可能是 switch、logout
    func userDidOffline(state: PassportState)

    /// 用户状态发生变化，包含所有状态的变化
    /// 用户状态分为 online、offline 两种
    func stateDidChange(state: PassportState)
    
    /// 后台用户状态变化的新接口，里面包含对应的user
    func backgroundUserDidOnline(state: PassportState)
    func backgroundUserDidOffline(state: PassportState)
    func backgroundStateDidChange(state: PassportState)
}

public extension PassportDelegate {

    func userDidOnline(state: PassportState) {}

    func userDidOffline(state: PassportState) {}

    func stateDidChange(state: PassportState) {}

    func backgroundUserDidOnline(state: PassportState) {}
    func backgroundUserDidOffline(state: PassportState) {}
    func backgroundStateDidChange(state: PassportState) {}
}

public final class PassportDelegateFactory {
    private let delegateProvider: () -> PassportDelegate

    // swiftlint:disable weak_delegate
    public lazy var delegate: PassportDelegate = {
        let delegate = self.delegateProvider()
        let identify = ObjectIdentifier(type(of: delegate))
        PassportDelegateRegistry.delegates[identify] = delegate
        return delegate
    }()
    // swiftlint:enable weak_delegate

    public init(delegateProvider: @escaping () -> PassportDelegate) {
        self.delegateProvider = delegateProvider
    }
}

public enum PassportDelegatePriority: String {
    case high
    case middle
    case low
}

public final class PassportDelegateRegistry {

    public private(set) static var factoriesDict = [String: [PassportDelegateFactory]]()

    public static func factories() -> [PassportDelegateFactory] {
        let sortedKey: [String] = [PassportDelegatePriority.high.rawValue,
                                   PassportDelegatePriority.middle.rawValue,
                                   PassportDelegatePriority.low.rawValue]
        var result = [PassportDelegateFactory]()
        sortedKey.forEach { (key) in
            if let value = self.factoriesDict[key] {
                result.append(contentsOf: value)
            }
        }
        return result
    }

    /// get LaunchDelegate instance
    /// - Parameter delegate: LaunchDelegate
    private static let lock = NSRecursiveLock()
    public static func resolver<T: PassportDelegate>(_ delegate: T.Type) -> T? {
        lock.lock()
        defer { lock.unlock() }
        // none Launcher Event has been sent
        if delegates.isEmpty ||
            !delegates.keys.contains(ObjectIdentifier(delegate)) {
            factories().forEach { _ = $0.delegate }
        }
        return delegates[ObjectIdentifier(delegate)] as? T
    }

    internal static var delegates: [ObjectIdentifier: PassportDelegate] = [:]

    /// Register passport delegate
    /// - Parameters:
    ///   - factory: PassportDelegateFactory
    ///   - priority: exec order: hight -> middle -> low
    public static func register(factory: PassportDelegateFactory, priority: PassportDelegatePriority) {
        var factories = factoriesDict[priority.rawValue]
        if factories == nil {
            factories = [PassportDelegateFactory]()
        }
        factories?.append(factory)
        factoriesDict[priority.rawValue] = factories
    }
}

public final class DummyPassportDelegate: PassportDelegate {
    public init() {}
}

public final class DummyLauncherDelegate: LauncherDelegate { // user:checked
    public var name: String = "DummyLauncherDelegate"
    public init() {}
}
