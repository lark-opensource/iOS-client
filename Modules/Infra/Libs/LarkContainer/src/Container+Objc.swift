//
//  Container+Objc.swift
//  LarkContainer
//
//  Created by SolaWing on 2023/3/30.
//

import Foundation
import Swinject
import EEAtomic

/// example:
///
/// ```swift
/// let container = Container()
/// container.register(XXX.self) { _ in
///     return XXX()
/// }.objc()
///
/// let userResolver: UserResolver
/// let objcUserResolver: userResolver.objc
/// var service = objcUserResolver.resolve(assert: XXX.self)
/// ```
///

/// Container Wrapper to used in objc
/// 暂时要求都在swift側，实现LarkAssemblyInterface协议统一注册，所以不提供给objc
// @objc(LKContainer)
// public class LKContainer: NSObject {
//     public var rawValue: Container
//     public init(rawValue: Container) {
//         self.rawValue = rawValue
//     }
//     @objc public static let shared: LKContainer = LKContainer(rawValue: Container.shared)
// }

/// UserResolver objc Wrapper
/// Example:
/// ```swift
///   let v = try resolver.resolve(assert: XXX.self)
/// ```
/// ```objc
/// id v = [resolver resolveAssert: XXX.class]; assert(v.class == XXX.class)
/// ```
@objc(LKUserResolver)
public class LKUserResolver: LKResolver, UserResolverWrapper {
    public var userResolver: UserResolver { return resolver as! UserResolver } // swiftlint:disable:this all
    public init(_ userResolver: UserResolver) {
        super.init(userResolver)
    }
    @objc public var userID: String { userResolver.userID }
}
@objc(LKResolver)
public class LKResolver: NSObject, ResolverWrapper {
    @objc public static let shared: LKResolver = LKResolver(Container.shared)
    public let resolver: Resolver
    public init(_ resolver: Resolver) {
        self.resolver = resolver
    }

    @objc(resolveAssert:name:error:)
    public func resolve(assert type: AnyObject, name: String? = nil) throws -> Any {
        guard let factory = SwiftTypeBridge.shared.getFactory(type: type) else {
            throw SwiftTypeBridge.InvalidResolveType(type: type)
        }
        return try factory.resolve(self, assert: type, name: name)
    }
    @objc(resolveAssert:name:)
    public func resolve(assert type: AnyObject, _ name: String?) -> Any? {
        return try? resolve(assert: type, name: name)
    }
    @objc(resolveAssert:)
    public func resolve(assert type: AnyObject) -> Any? {
        return try? resolve(assert: type, name: nil)
    }
    @objc(resolveType:name:error:)
    public func resolve(type: AnyObject, name: String? = nil) throws -> Any {
        guard let factory = SwiftTypeBridge.shared.getFactory(type: type) else {
            throw SwiftTypeBridge.InvalidResolveType(type: type)
        }
        return try factory.resolve(self, assert: type, name: name)
    }
    @objc(resolveType:name:)
    public func resolve(type: AnyObject, _ name: String?) -> Any? {
        return try? resolve(type: type, name: name)
    }
    @objc(resolveType:)
    public func resolve(type: AnyObject) -> Any? {
        return try? resolve(type: type, name: nil)
    }

    /// 全局服务应该使用这个方法，显示的传递userid来获取UserResolver. 和上面仅用于转换的做区分
    /// 如果传入userID无效（比如对应的storage还没有创建, nil会直接当作无效处理），则会抛出异常invalidUserID
    ///
    /// - Parameters:
    ///   - userID: 若为nil，且有开启其中一种兼容模式，会返回当前userResolver
    ///         NOTE: 但最终会加断言，不应该有传空的情况. 允许空只是方面做统一的错误处理
    ///   - compatibleMode: true时返回当前UserResolver，不会抛错
    ///   - threadCompatibleMode: true时本次调用不会抛错，但是返回的当前UserResolver使用有可能会抛错
    ///             (当前UserResolver仅会在切换临界区抛错，概率要小很多..)
    @objc
    public func getUserResolver(
        userID: String?, compatibleMode: Bool, threadCompatibleMode: Bool, identifier: String?
    ) throws -> LKUserResolver {
        return try LKUserResolver(resolver.getUserResolver(userID: userID, compatibleMode: compatibleMode,
                                                           threadCompatibleMode: threadCompatibleMode,
                                                           identifier: { identifier ?? "getUserResolver(OBJC)" }))
    }
    @objc
    public func getUserResolver(userID: String?) -> LKUserResolver? {
        return try? getUserResolver(userID: userID, compatibleMode: false, threadCompatibleMode: false, identifier: nil)
    }
    @objc
    public func getCurrentUserResolver(compatibleMode: Bool) -> LKUserResolver {
        return LKUserResolver(resolver.getCurrentUserResolver(
            compatibleMode: compatibleMode,
            identifier: { "getCurrentUserResolver(objc)" }))
    }
    @objc
    public func getCurrentUserResolver() -> LKUserResolver {
        return LKUserResolver(resolver.getCurrentUserResolver(identifier: { "getCurrentUserResolver(objc)" }))
    }
}

extension ServiceEntry {
    /// bridge this register factory to objc
    /// Service should be a @objc class or protocol
    @discardableResult
    public func objc() -> Self where Service: AnyObject {
        SwiftTypeBridge.shared.bridge(type: Service.self)
        return self
    }
}

class SwiftTypeBridge {
    static var shared: SwiftTypeBridge = SwiftTypeBridge()
    init() {}
    deinit {
        lock.deallocate()
    }
    var lock = UnfairLockCell()
    private var registations: [ObjectIdentifier: FactoryWrapper] = [:]
    func bridge<Service>(type: Service.Type) {
        // https://forums.swift.org/t/metatypes-are-different-than-obj-c-protocols-until-they-are-not/45067
        // NOTE: protocol have to cast to Protocol or AnyObject, to get same ObjectIdentifier as objc @protocol
        let id = ObjectIdentifier(type as AnyObject) // swiftlint:disable:this all
        lock.withLocking {
            if registations.index(forKey: id) == nil {
                registations[id] = TypedFactoryWrapper<Service>()
            }
        }
    }
    func getFactory(type: AnyObject) -> FactoryWrapper? {
        lock.withLocking {
            return registations[ObjectIdentifier(type)]
        }
    }

    /// BaseClass for generic inherit method
    class FactoryWrapper {
        func resolve(_ resolver: LKResolver, assert type: AnyObject, name: String?) throws -> Any {
            fatalError("should implemented by subclass!!")
        }
    }
    class TypedFactoryWrapper<T>: FactoryWrapper {
        override func resolve(_ resolver: LKResolver, assert type: AnyObject, name: String?) throws -> Any {
            #if DEBUG || ALPHA
            // 这个应该进不来，前面根据type获取wrapper就应该直接拦截了..
            precondition(type === (T.self as AnyObject), "should pass same class as registered")
            #endif
            return try resolver.resolver.resolve(assert: T.self, name: name)
        }
    }
    struct InvalidResolveType: Error {
        var type: AnyObject
    }
}
