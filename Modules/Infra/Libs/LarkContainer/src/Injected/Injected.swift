//
//  Injected.swift
//  LarkContainer
//
//  Created by SuPeng on 8/24/19.
//

import Foundation
import Swinject
import EEAtomic

// swiftlint:disable missing_docs unused_setter_value

public var implicitResolver: Resolver? = Container.shared.synchronize()

public protocol InjectedProtocol {
    associatedtype Value
    var wrappedValue: Value { get }
}

@propertyWrapper
public struct Injected<Value>: InjectedProtocol {
    public let wrappedValue: Value

    public init() {
        wrappedValue = Container.shared.resolve(Value.self)!
    }

    public init<Root>(_ keyPath: Swift.KeyPath<Root, Value>) {
        wrappedValue = Container.shared.resolve(Root.self)![keyPath: keyPath]
    }

    public init<Root>(_ block: (Root) -> Value) {
        wrappedValue = block(Container.shared.resolve(Root.self)!)
    }

    public init(_ name: String) {
        wrappedValue = Container.shared.resolve(Value.self, name: name)!
    }
}

@propertyWrapper
public struct InjectedOptional<Value>: InjectedProtocol {
    public let wrappedValue: Value?

    public init() {
        wrappedValue = Container.shared.resolve(Value.self)
    }

    public init<Root>(_ keyPath: Swift.KeyPath<Root, Value>) {
        wrappedValue = Container.shared.resolve(Root.self)?[keyPath: keyPath]
    }

    public init<Root>(_ block: (Root) -> Value) {
        wrappedValue = Container.shared.resolve(Root.self).flatMap { block($0) }
    }

    public init(_ name: String) {
        wrappedValue = Container.shared.resolve(Value.self, name: name)
    }
}

@available(*, deprecated, message: "本版本会一直持有初始化闭包, 请显示的使用UnsafeLazy(单线程版本)和SafeLazy(多线程安全版本)")
@propertyWrapper
public struct InjectedLazy<Value> {

    private let intialBlock: () -> Value
    private var _wrappedValue: Value?
    public var wrappedValue: Value {
        mutating get {
            if let value = _wrappedValue {
                return value
            } else {
                _wrappedValue = intialBlock()
                return _wrappedValue ?? intialBlock() // 加 `intialBlock()` 避免 force unwrap
            }
        }
    }

    public init(initialBlock: @escaping @autoclosure () -> Value) {
        self.intialBlock = initialBlock
    }

    public init() {
        self.intialBlock = { Injected<Value>().wrappedValue }
    }

    public init<T>(_ initialBlock: @escaping @autoclosure () -> T)
    where T: InjectedProtocol, T.Value == Value {
        self.intialBlock = { initialBlock().wrappedValue }
    }
}

@propertyWrapper
public struct InjectedUnsafeLazy<Value> {
    @usableFromInline
    @frozen
    enum Storage {
        case uninitialized(() -> Value)
        case initialized(Value)
    }
    @usableFromInline var storage: Storage

    public var wrappedValue: Value {
        mutating get {
            switch storage {
            case .uninitialized(let initializer):
                let value = initializer()
                self.storage = .initialized(value)
                return value
            case .initialized(let value):
                return value
            }
        }
    }

    public init(initialBlock: @escaping @autoclosure () -> Value) {
        self.storage = .uninitialized(initialBlock)
    }

    public init() {
        self.storage = .uninitialized({ Injected<Value>().wrappedValue })
    }

    public init<T>(_ initialBlock: @escaping @autoclosure () -> T)
    where T: InjectedProtocol, T.Value == Value {
        self.storage = .uninitialized({ initialBlock().wrappedValue })
    }
}
@propertyWrapper
public struct InjectedSafeLazy<Value> {

    @SafeLazy public var wrappedValue: Value

    public init(initialBlock: @escaping @autoclosure () -> Value) {
        _wrappedValue = SafeLazy(block: initialBlock)
    }

    public init() {
        _wrappedValue = SafeLazy { Injected<Value>().wrappedValue }
    }

    public init<T>(_ initialBlock: @escaping @autoclosure () -> T)
    where T: InjectedProtocol, T.Value == Value {
        _wrappedValue = SafeLazy { initialBlock().wrappedValue }
    }
}

@propertyWrapper
public struct Provider<Value> {
    private let intialBlock: () -> Value

    public var wrappedValue: Value { intialBlock() }

    public init(initialBlock: @escaping @autoclosure () -> Value) {
        self.intialBlock = initialBlock
    }

    public init() {
        self.intialBlock = { Injected<Value>().wrappedValue }
    }

    public init<T>(_ initialBlock: @escaping @autoclosure () -> T)
    where T: InjectedProtocol, T.Value == Value {
        self.intialBlock = { initialBlock().wrappedValue }
    }
}

// MARK: - Scoped Resolver API

/// a resolver binding object. to ensure dependency in same container.
public protocol ResolverWrapper: AnyObject {
    // alias for avoid import Swinject
    typealias Resolver = Swinject.Resolver
    var resolver: Resolver { get }
}
public protocol UserResolverWrapper: ResolverWrapper {
    var userResolver: UserResolver { get }
}
extension UserResolverWrapper {
    public var resolver: Resolver { userResolver }
}

/// 隔离容器里的lazy属性wrapper，可以传入context，比如self或者resolver
@propertyWrapper
open class ScopedLazy<Value, Context> {
    @usableFromInline let once = c_dispatch_once_token.create()
    @usableFromInline var stored: Storage
    public typealias InitFunc = (Context) -> Value
    @usableFromInline
    @frozen
    enum Storage {
        case uninitialized(InitFunc)
        case initialized(Value)
    }
    deinit {
        c_dispatch_once_token.destroy(once)
    }
    public init(_ initializer: @escaping InitFunc) {
        stored = .uninitialized(initializer)
    }
    @inlinable
    public func value(_ context: Context) -> Value {
        c_dispatch_once_token.exec(once) {
            switch stored {
            case .uninitialized(let initializer):
                stored = .initialized(initializer(context))
            case .initialized:
                #if ALPHA || DEBUG
                fatalError("should be initalized once in this code")
                #endif
            }
        }
        if case let .initialized(value) = stored {
            return value
        } else {
            fatalError("should already initalized")
        }
    }

    @available(*, unavailable)
    public var wrappedValue: Value {
        get { fatalError("should call static subscript api") }
        set { fatalError("should call static subscript api") }
    }
    public static subscript(
        _enclosingInstance observed: Context,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<Context, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<Context, ScopedLazy>
        ) -> Value {
            @inlinable get { observed[keyPath: storageKeyPath].value(observed) }
            @available(*, unavailable)
            set {}
    }
}

/// a isolate inject version, use resolver from self.
/// return value must be optional. since the resolver may be dispose
@propertyWrapper
public final class ScopedInjectedLazy<Value>: ScopedLazy<Value?, Resolver> {
    public init(name: String? = nil, assert: Bool = true) {
        if assert {
            super.init({
                return try? $0.resolve(assert: Value.self, name: name)
            })
        } else {
            super.init({
                return try? $0.resolve(type: Value.self, name: name)
            })
        }
    }
    public init<Root>(_ keyPath: Swift.KeyPath<Root, Value>, name: String? = nil, assert: Bool = true) {
        if assert {
            super.init({
                return try? $0.resolve(assert: Root.self, name: name)[keyPath: keyPath]
            })
        } else {
            super.init({
                return try? $0.resolve(type: Root.self, name: name)[keyPath: keyPath]
            })
        }
    }
    @available(*, unavailable)
    public var wrappedValue: Value? {
        get { fatalError("should call static subscript api") }
        set { fatalError("should call static subscript api") }
    }
    public static subscript<Wrapped: ResolverWrapper>(
        _enclosingInstance observed: Wrapped,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<Wrapped, Value?>,
        storage storageKeyPath: ReferenceWritableKeyPath<Wrapped, ScopedInjectedLazy>
        ) -> Value? {
            @inlinable get { observed[keyPath: storageKeyPath].value(observed.resolver) }
            @available(*, unavailable)
            set {}
    }
}

/// 隔离版本的Provider
/// 注意包装的类型一定是Type?或者Type！, 并进行对应的容错处理
@propertyWrapper
public struct ScopedProvider<Value> {
    let getter: (Resolver) -> Value?
    public init(name: String? = nil, assert: Bool = true) {
        if assert {
            getter = {
                return try? $0.resolve(assert: Value.self, name: name)
            }
        } else {
            getter = {
                return try? $0.resolve(type: Value.self, name: name)
            }
        }
    }
    public init<Root>(_ keyPath: Swift.KeyPath<Root, Value>, name: String? = nil, assert: Bool = true) {
        if assert {
            getter = {
                return try? $0.resolve(assert: Root.self, name: name)[keyPath: keyPath]
            }
        } else {
            getter = {
                return try? $0.resolve(type: Root.self, name: name)[keyPath: keyPath]
            }
        }
    }

    @available(*, unavailable)
    public var wrappedValue: Value? {
        get { fatalError("should call static subscript api") }
        set { fatalError("should call static subscript api") }
    }

    public static subscript<OuterSelf: ResolverWrapper>(
        _enclosingInstance observed: OuterSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<OuterSelf, Value?>,
        storage storageKeyPath: ReferenceWritableKeyPath<OuterSelf, ScopedProvider>
        ) -> Value? {
            get {
                let resolver = observed.resolver
                let wrapper = observed[keyPath: storageKeyPath]
                return wrapper.getter(resolver)
            }
            @available(*, unavailable)
            set {}
    }
}
