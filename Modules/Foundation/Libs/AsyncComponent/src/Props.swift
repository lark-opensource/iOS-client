//
//  Props.swift
//  AsyncComponent
//
//  Created by qihongye on 2019/1/29.
//

import Foundation
import EEFlexiable

public protocol ASComponentPropsProtocol {
    var key: String? { get set }
    var children: [Component] { get set }
    func equalTo(_ props: Self) -> Bool
}

open class ASComponentProps: ASComponentPropsProtocol {
    public class var empty: ASComponentProps {
        return ASComponentProps()
    }

    public var key: String?

    public var children: [Component] = []

    public init(key: String? = nil, children: [Component] = []) {
        self.key = key
        self.children = children
    }

    public func getChildren<C: Context>() -> [ComponentWithContext<C>] {
        return children.compactMap({ $0 as? ComponentWithContext<C> })
    }

    open func equalTo(_ props: ASComponentProps) -> Bool {
        if let key1 = key, let key2 = props.key, key1 != key2 {
            return false
        }
        return true
    }
}

open class SafeASComponentProps: ASComponentProps {
    public override class var empty: ASComponentProps {
        return SafeASComponentProps()
    }

    let lock: UnsafeMutablePointer<os_unfair_lock_s>

    public override init(key: String? = nil, children: [Component] = []) {
        self.lock = UnsafeMutablePointer.allocate(capacity: 1)
        self.lock.initialize(to: os_unfair_lock_s())
        super.init(key: key, children: children)
    }

    public func safeWrite(_ write: () -> Void) {
        os_unfair_lock_lock(lock)
        write()
        os_unfair_lock_unlock(lock)
    }

    public func safeRead<T>(_ read: () -> T) -> T {
        os_unfair_lock_lock(lock)
        defer {
            os_unfair_lock_unlock(lock)
        }
        return read()
    }
    
    deinit {
        self.lock.deallocate()
    }
}

public protocol ASComponentState: Equatable {
    static var `nil`: Self { get }
    init()
}

public extension ASComponentState {
    static var `nil`: Self {
        return self.init()
    }
}

public struct EmptyState: ASComponentState {
    public init() {}
}
