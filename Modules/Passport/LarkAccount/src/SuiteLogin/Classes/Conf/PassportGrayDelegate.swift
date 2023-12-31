//
//  PassportGrayDelegate.swift
//  LarkAccount
//
//  Created by au on 2023/3/21.
//

import Foundation

protocol PassportGrayDelegate {
    func grayConfigDidSet(map: [String: Bool])
}

extension PassportGrayDelegate {
    func grayConfigDidSet(map: [String: Bool]) {}
}

final class PassportGrayDelegateFactory {

    private let delegateProvider: () -> PassportGrayDelegate

    // swiftlint:disable weak_delegate
    lazy var delegate: PassportGrayDelegate = {
        let delegate = self.delegateProvider()
        let identify = ObjectIdentifier(type(of: delegate))
        PassportGrayDelegateRegistry.delegates[identify] = delegate
        return delegate
    }()
    // swiftlint:enable weak_delegate
    
    init(delegateProvider: @escaping () -> PassportGrayDelegate) {
        self.delegateProvider = delegateProvider
    }
}

final class PassportGrayDelegateRegistry {
    
    private(set) static var factories = [PassportGrayDelegateFactory]()
    
    private static let lock = NSRecursiveLock()
    
    static func resolver<T: PassportGrayDelegate>(_ delegate: T.Type) -> T? {
        lock.lock()
        defer { lock.unlock() }
        if delegates.isEmpty ||
            !delegates.keys.contains(ObjectIdentifier(delegate)) {
            factories.forEach { _ = $0.delegate }
        }
        return delegates[ObjectIdentifier(delegate)] as? T
    }

    static var delegates: [ObjectIdentifier: PassportGrayDelegate] = [:]

    static func register(factory: PassportGrayDelegateFactory) {
        factories.append(factory)
    }
}
