//
//  Container+User.swift
//  LarkContainer
//
//  Created by SolaWing on 2022/7/13.
//

import Foundation
import Swinject
import EEAtomic

// swiftlint:disable missing_docs

public typealias Container = Swinject.Container
public typealias Resolver = Swinject.Resolver

public protocol LarkContainerDelegate { // swiftlint:disable:this all
    /// 记录异常信息，可选打印日志，上报埋点，上报sladar等等
    func log(exception: UserExceptionInfo)
    /// 关键异常信息记录
    func warn(_ message: String, file: String, line: Int)
    /// 关键信息日志
    func info(_ message: String, file: String, line: Int)

    /// 基础组件，FG重启生效... 启用时，全部启用兼容模式
    /// 这个FG启用的可能性不大..
    var disabledUserFG: Bool { get }
    /// compatibleMode的UserResolver始终返回当前userID的回滚fg
    var disabledVariableCompatibleUserID: Bool { get }
}

extension Resolver {
    /// NOTE: 该方法需要动态转换，且不太好控制使用范围，不推荐直接使用。
    /// 应该使用封装且确定时机的`Container.inObjectScope`方法来获取UserResolver
    /// 因此这个方法暂时不public，避免误用.
    ///
    /// 该方法仅应当对用户空间内注册的工厂方法传入resolver调用，且必定成功
    /// 非工厂传入resolver调用会抛错.
    /// NOTE: UserResolver会绑定具体的用户，如果该用户登出销毁，后续的Resolve也会失败报错。
    /// 所以需要做容错处理
    ///
    /// NOTE: 该方法不应该用于非用户空间对象工厂传入resolver调用转换
    /// 外部应该显示使用`getUserResolver`显示传递UserID获取对应的UserResolver
    /// SEE ALSO: getUserResolver(userID:)
    func asUserResolver() throws -> UserResolver {
        if let value = self as? UserResolver { return value }

        #if DEBUG || ALPHA
        fatalError("only call asUserResolver in user-related registerd factory")
        #else
        // Release环境进行兼容, 迁移完成后变成throw
        // throw UserScopeError.userNotFound
        return UserResolver.make(storage: UserStorageManager.shared.currentStorage(),
                                 resolver: self, compatible: true)
        #endif
    }
    public func getUserResolver(storage: UserStorage, compatibleMode: Bool = false) -> UserResolver {
        var resolver: Resolver = self
        if let value = self as? UserResolver {
            if value.storage === storage { return value.changeCompatibleMode(to: compatibleMode) }
            resolver = value.resolver // 解包UserResolver，避免多层wrap
        }
        return UserResolver.make(storage: storage, resolver: resolver, compatible: compatibleMode)
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
    public func getUserResolver(
        userID: String?, type: UserScopeType = .foreground,
        compatibleMode: Bool = false, threadCompatibleMode: Bool = false,
        identifier: (() -> String)? = nil, file: String = #fileID, line: UInt = #line
    ) throws -> UserResolver {
        let compatible = compatibleMode || threadCompatibleMode
        let userStorage = try UserStorageManager.shared.getStorage(
            userID: userID, nilAsCurrent: compatible, type: type, compatibleMode: compatible,
            identifier: identifier, file: file, line: line)
        return getUserResolver(storage: userStorage, compatibleMode: compatibleMode)
    }
    @_disfavoredOverload
    public func getUserResolver(
        userID: String?,
        compatibleMode: Bool = false, threadCompatibleMode: Bool = false,
        identifier: (() -> String)? = nil, file: String = #fileID, line: UInt = #line
    ) throws -> UserResolver {
        return try getUserResolver(userID: userID, type: .foreground, compatibleMode: compatibleMode,
                                  threadCompatibleMode: threadCompatibleMode,
                                  identifier: identifier, file: file, line: line)
    }
    /// 迁移期间直接获取当前userResolver的过渡方法..,
    /// 部分短时间内不太好改的可以先临时使用这个方法兼容
    /// 并且通过这个方法调用标记更容易发现候选的迁移项
    public func getCurrentUserResolver(
        compatibleMode: Bool = false, identifier: (() -> String)? = nil,
        file: String = #fileID, line: UInt = #line
    ) -> UserResolver {
        return try! getUserResolver( // swiftlint:disable:this all
            userID: nil, compatibleMode: compatibleMode, threadCompatibleMode: true,
            identifier: identifier, file: file, line: line)
    }
}
public enum UserScopeLifeTime {
    case user /// 用户生命周期
    case graph /// resolve期间共享的生命周期
    case transient /// 临时生命周期，每次都创建
}
extension ObjectScope {
    /// 兼容模式的user, 理论上和原来的行为一致.., 使用当前user不会抛错
    /// 通过这个的引用数可以判断还有多少代码没有迁移完成..
    public static let user = UserLifeScope { true }
    /// 新的非兼容模式的user, 用户退出后会抛错
    /// 业务方可以自己创建UserLifeScope对象，控制工厂内是否传入兼容模式的UserResolver
    public static let userV2 = UserLifeScope { false }
    /// graph生命周期的service，且按用户隔离，工厂内传入的是UserResolver
    public static let userGraph = UserGraphScope { false }
    /// 用户容器内transient生命周期的服务
    public static let userTransient = UserTransientScope { false }

    public static func user(type: UserScopeType, lifetime: UserScopeLifeTime = .user) -> UserSpaceScope {
        UserScopeManager.shared.user(type: type, lifetime: lifetime)
    }
    public static func userGraph(type: UserScopeType) -> UserSpaceScope {
        UserScopeManager.shared.user(type: type, lifetime: .graph)
    }
    public static func userTransient(type: UserScopeType) -> UserSpaceScope {
        UserScopeManager.shared.user(type: type, lifetime: .transient)
    }

    /// 通用参数缓存复用scope，避免重复创建对象
    class UserScopeManager {
        struct ID: Hashable { // swiftlint:disable:this all
            let type: UserScopeType
            let lifetime: UserScopeLifeTime
        }
        var storage: [ID: UserSpaceScope] = [:]
        let lock = UnfairLockCell()
        static let shared = UserScopeManager()

        func user(type: UserScopeType, lifetime: UserScopeLifeTime) -> UserSpaceScope {
            let id = ID(type: type, lifetime: lifetime)
            lock.lock(); defer { lock.unlock() }
            if let scope = storage[id] { return scope }
            let scope = make()
            storage[id] = scope
            return scope

            func make() -> UserSpaceScope {
                switch lifetime {
                case .transient: return UserTransientScope(type: type, compatible: { false })
                case .user:      return UserLifeScope(type: type, compatible: { false })
                case .graph:     return UserGraphScope(type: type, compatible: { false })
                }
            }
        }

        deinit {
            lock.deallocate()
        }
    }
}

extension Container {
    public func inObjectScope(_ objectScope: ObjectScope) -> ContainerWithScope<Resolver> {
        return ContainerWithScope(container: self, scope: objectScope)
    }
    public func inObjectScope(_ objectScope: UserSpaceScope) -> ContainerWithScope<UserResolver> {
        return ContainerWithScope(container: self, scope: objectScope)
    }
    /// 全局共享的Container.
    /// 考虑到Container只是存factory，需要看见具体的类型才能resolve
    /// 所以拆分多个隔离的container的作用不大..
    /// 隔离可以用scope做..
    #if WAIT_REGISTER
    // 集成前的容器使用需要等待，避免返回nil强解崩溃
    public static let shared = { () -> Container in
        let container = Container()
        container.canCallResolve = false
        // after assembly, should set canCallResolve to true
        return container
    }()
    #else
    public static let shared = Container()
    #endif
}

// MARK: UserResolver

/// 给UserScope提供user信息
/// NOTE:FIXME: 这种wrap只支持一层, 如果有其他的多层wrap的话，即无法as转换，context强转也会丢失外层wrapper的信息
/// 暂时应该只有UserResolver这一种wrapper..
public class UserResolver: Resolver {
    public func _resolve<Service, Arguments>(context: ResolverContext<Service, Arguments>) throws -> Service { // swiftlint:disable:this identifier_name
        /// 考虑到Resolver可能被wrapper，所以通过context来传递链路上的关键信息..
        #if DEBUG || ALPHA
        precondition(context[.userResolver] == nil)
        #endif
        // 非特定的scope，都传原始的resolver给factory
        // 这样可以避免非用户容器的服务隐式获取到用户容器内的对象
        // 需要使用用户容器的，必须显式的使用对应的标记scope获取

        context.resolver = self.resolver
        context[.userResolver] = self
        /// 拦截跨前后台状态的服务和未标记安全的全局服务
        /// FIXME: 看这个拦截是否要弄成ALPHA only的..
        func validator(entry: ServiceEntry<Service>) throws {
            // for background UserResolver, not use compatible. global need to mark safe
            // for user service, type must match
            if background {
                #if ALPHA
                precondition(_compatibleMode == false)
                #endif
                if let scope = entry.objectScope as? UserSpaceScope {
                    try checkSameUserType(scope: scope)
                } else {
                    guard ServiceEntryUserSafeMarker.shared.valid(entry: entry) else {
                        warn("未确认的全局服务调用: \(String(reflecting: Service.self))")
                        throw UserScopeError.unsafeCall
                    }
                }
            } else {
                if let scope = entry.objectScope as? UserSpaceScope {
                    try checkSameUserType(scope: scope)
                }
            }
            func checkSameUserType(scope: UserSpaceScope) throws {
                if !scope.type.contains(storageType) {
                    warn("用户服务支持的类型不匹配: \(String(reflecting: Service.self)) need to support \(storage.type)")
                    throw UserScopeError.unsafeCall
                }
            }
        }
        if context.replace(key: .entryValidator, value: validator) != nil {
            #if ALPHA
            fatalError("not supported overwrite exist entryValidator!")
            #endif
        }

        return try resolver._resolve(context: context)
    }

    public let storage: UserStorage
    public let resolver: Resolver
    init(storage: UserStorage, resolver: Resolver) {
        self.storage = storage
        self.resolver = resolver
    }
    static func make(storage: UserStorage, resolver: Resolver, compatible: Bool) -> UserResolver {
        // background类型需要严格隔离，不能支持compatible的前台兼容能力.
        if compatible && storage.type != .background {
            return CompatibleUserResolver(storage: storage, resolver: resolver)
        } else {
            return UserResolver(storage: storage, resolver: resolver)
        }
    }
    func make(storage: UserStorage, resolver: Resolver, compatible: Bool) -> UserResolver {
        let compatible = compatible && foreground
        if storage === self.storage, resolver === self.resolver, compatible == _compatibleMode {
            return self
        }
        return Self.make(storage: storage, resolver: resolver, compatible: compatible)
    }
    @inlinable public var userID: String { storage.userID }
    @inlinable public var storageType: UserStorageType { storage.type }
    @inlinable public var foreground: Bool { storage.type == .foreground }
    @inlinable public var background: Bool { storage.type == .background }

    /// 是否占位兜底的用户容器. 通过userID判断.
    /// compatible的情况下userID取当前可变userID，该属性会产生相应的变化
    public var isPlaceholder: Bool { userID == UserStorageManager.placeholderUserID }
    /// 该用户空间是否可用.., 可以用来判断并提前return，避免走入相关的异常分支
    public var valid: Bool { !storage.disposed || compatibleMode }
    /// 控制是否启用兼容模式，默认为false。兼容模式下会尽量避免抛出异常
    /// 兼容模式的配置在迁移完成并确认无误后会下线。
    ///
    /// NOTE: 新的用户隔离框架下，相对原来的主要变化为:
    /// 1. 需要显示传递userStorage(userID)，用于隔离, 且调用全局验证函数时可能抛出用户验证异常
    /// 2. userStorage可能被销毁，这个时候需要抛出异常，防止后续的异常调用
    ///
    /// 而抛出错误后，如果还是原来的强resolve强解包，就会导致程序崩溃
    public var compatibleMode: Bool {
        // 只有前台resolver可以开启兼容模式
        foreground && (_compatibleMode || Self.compatibleMode || UserStorageManager.delegate.disabledUserFG)
    }
    /// 控制这个对象的Resolve是否可以抛错
    fileprivate var _compatibleMode: Bool { false }
    /// 当前调用链上是否可以throw用户错误, 区分于同步调用链不能抛错，但是异步factory进行了容错处理.
    public static private(set) var compatibleMode: Bool {
        get {
            (Thread.current.threadDictionary["UserResolver.compatibleMode"] as? Bool) ?? false
        }
        set {
            if newValue {
                Thread.current.threadDictionary["UserResolver.compatibleMode"] = true
            } else {
                Thread.current.threadDictionary.removeObject(forKey: "UserResolver.compatibleMode")
            }
        }
    }
    /// 首次用兼容模式调用的需要保证调用链上不抛错，虽然后续异步调用可以抛错。
    /// 所以用thread标记来和对象上的compatible做区分..
    public static func ensureThreadCompatibleMode<R>(_ value: Bool, action: () throws -> R) rethrows -> R {
        if value && !compatibleMode {
            compatibleMode = true
            defer { compatibleMode = false }
            return try action()
        }
        return try action()
    }
    public func changeCompatibleMode(to compatibleMode: Bool) -> UserResolver {
        if (_compatibleMode == compatibleMode) || background { return self } // background不支持兼容模式
        return Self.make(storage: storage, resolver: resolver, compatible: compatibleMode)
    }
}
/// 兼容模式的UserResolver，表现行为和Resolver一致，使用当前UserStorage，不会抛错.
/// 用于FG启用兼容模式，并区分还有多少代码仍然使用Resolver，没有迁移完成
final class CompatibleUserResolver: UserResolver {
    override var userID: String {
        if UserStorageManager.delegate.disabledVariableCompatibleUserID {
            return super.userID
        }
        return UserStorageManager.shared.currentUserID
    }
    override var _compatibleMode: Bool { true }
}

public enum UserStorageType: UInt8 {
    case foreground = 0
    case background = 1
}

/// UserStorage should be thread safe
/// non public api should called by internal code
///
/// NOTE: userID是无生命周期的，一个userID可以对应多个不同生命周期的UserStorage. 不利于把UserStorage的隔离透传。
/// 所以能依赖LarkContainer的地方，**推荐都直接传递**UserStorage或者UserResolver
///
/// NOTE: 部分业务可能会有延长容器生命周期的需求，比如保证一些关键数据一定保存上..
/// 现在初步想法是用类似引用计数的方法来实现，可能包装为一个owner的对象被持有。有具体需求是再来实现
public final class UserStorage {
    public let userID: String // swiftlint:disable:this all
    public let type: UserStorageType

    @usableFromInline var storage: [ObjectIdentifier: Any] = [:]
    public internal(set) var disposed = false
    /// 内部代码用来保护可变状态的线程安全
    @usableFromInline var lock = UnfairLockCell()

    /// lifetime managered by UserStorageManager. can't be created or disposed by user
    /// UserStorage的生命周期应该收到严格管控。
    /// 理论上只可能从当前user创建
    init(userID: String, type: UserStorageType) {
        self.userID = userID
        self.type = type
    }
    /// may throws disposed error
    public func get<T>(key: ObjectIdentifier) throws -> T? {
        return try withLocking { return $0.get(key: key) }
    }
    /// assign nil to remove it
    public func set(key: ObjectIdentifier, value: Any?) throws {
        try withLocking { $0.set(key: key, value: value) }
    }
    /// batch version within lock. limited API..
    @usableFromInline
    final class InLocking {
        /// 通过withLocking创建
        @usableFromInline
        init(base: UserStorage) {
            self.base = base
        }
        @usableFromInline var base: UserStorage
        /// 延迟到锁外释放
        @usableFromInline var delayRelease: [Any] = []
        @inlinable
        public func get<T>(key: ObjectIdentifier) -> T? {
            base.storage[key] as? T
        }
        @inlinable
        public func set(key: ObjectIdentifier, value: Any?) {
            if let value {
                let old = base.storage.updateValue(value, forKey: key)
                if let old { delayRelease.append(old) }
            } else {
                let old = base.storage.removeValue(forKey: key)
                if let old { delayRelease.append(old) }
            }
        }
    }
    /// may raise disposed error
    /// 内部锁不开放出去，可能导致重入.., 有需求再review..
    @usableFromInline
    func withLocking<R>(_ body: (InLocking) throws -> R) throws -> R {
        return try withExtendedLifetime(InLocking(base: self)) { proxy in
            lock.lock(); defer { lock.unlock() }
            try checkDisposed()
            return try body(proxy)
        }
    }

    @inlinable
    func checkDisposed() throws {
        if disposed {
            throw UserScopeError.disposed
        }
    }

    // 该方法应该manager移除对应的引用的时候调用
    func dispose() {
        let old: [ObjectIdentifier: Any]
        do {
            lock.lock(); defer { lock.unlock() }
            if disposed { return }
            old = storage
            disposed = true
            // 清空所有的缓存, 后续的Resolve都应该抛出异常
            storage.removeAll()
        }
        // release old without lock
        // NOTE: 异步释放可能打乱顺序，或者在子线程上运行dealloc代码，可能导致相应的并发线程安全问题
        _ = old
        info("disposed UserStorage \(userID)")
        #if DEBUG || ALPHA
        // disable-lint-next-line: magic_number
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) { [weakObjects] in
            for v in weakObjects.allObjects {
                let key = String(reflecting: Swift.type(of: v))
                UserExceptionInfo.log(.init(scene: "ExpiredObject", key: key,
                                            message: "user storage for \(key) still alive!",
                                            calleeState: .ready, isError: true))
            }
        }
        #endif
    }
    deinit {
        lock.deallocate()
    }
    #if DEBUG || ALPHA
    var weakObjects = NSHashTable<AnyObject>.weakObjects()
    #endif
}

/// 用于管理用户容器的生命周期
public final class UserStorageManager {
    /// 使用方集成注入。用于埋点，日志等可选信息
    public static var delegate: LarkContainerDelegate = DefaultLarkContainerDelegate()
    public static let shared = UserStorageManager() // swiftlint:disable:this all
    private init() {} // 单例，外部不可创建

    private let lock = UnfairLockCell()
    private var storages: [String: UserStorage] = [:] // userID -> Storage

    /// NOTE: 需要区分新旧storage，对应用户的生命周期，不要混用。
    /// 所以一般来说不应该使用这个接口，而应该使用resolver上绑定传递的storage
    public subscript(userID: String) -> UserStorage? {
        lock.lock(); defer { lock.unlock() }
        return storages[userID]
    }
    /// current valid user ids
    public var userIDs: [String] { lock.withLocking { Array(storages.keys) } }
    /// current valid user storages
    public var userStorages: [UserStorage] { lock.withLocking { Array(storages.values) } }
    @_disfavoredOverload
    @discardableResult
    public func makeStorage(userID: String, overwrite: Bool = false) -> UserStorage {
        return makeStorage(userID: userID, type: .foreground)
    }
    /// 用户创建时应该调用这个方法。会强制覆盖旧的. 所以需要确保旧的offline后再调用
    /// 可能创建的时机：
    /// 1. 用户创建后显示的调用该方法创建
    /// 2. 使用currentStorage, 用当前用户ID，lazy创建(不应该出现过期当前用户ID创建的情况)
    @discardableResult
    public func makeStorage(userID: String, type: UserStorageType = .foreground) -> UserStorage {
        let storage: UserStorage
        let old: UserStorage?
        do {
            lock.lock(); defer { lock.unlock() }
            (storage, old) = _makeStorage(userID: userID, overwrite: true, type: type)
            #if ALPHA
            if old?.type == .foreground, type == .background, self.currentUserID == userID {
                fatalError("should change currentUserID before overwrite foreground storage \(userID)")
            }
            #endif
        }
        old?.dispose()
        return storage
    }
    /// - Returns: (newStorage, overwritedStorage), overwritedStorage should call dispose
    private func _makeStorage(userID: String, overwrite: Bool, type: UserStorageType) -> (UserStorage, UserStorage?) {
        let oldStorage = storages[userID]
        if !overwrite, let storage = oldStorage, !storage.disposed {
            #if ALPHA
            // 同一时间，相同userID只能有一个storage.., 需要管控入口和生命周期
            guard storage.type == type else {
                // TODO: 避免出现current指向background的时机
                fatalError("storage type mismatch for \(userID): \(storage.type) != \(type)")
            }
            #endif
            return (storage, nil)
        }
        info("_makeStorage: \(userID), type: \(type), overwrite: \(overwrite)")
        let storage = UserStorage(userID: userID, type: type)
        storages[userID] = storage
        return (storage, oldStorage)
    }
    /// 清理掉对应用户的storage
    @discardableResult
    public func disposeStorage(userID: String) -> UserStorage? {
        if let storage = lock.withLocking(action: { storages.removeValue(forKey: userID) }) {
            // 后续对该storage的引用都会抛出异常
            // 且除了已经持有的外，不会再有新增持有.
            storage.dispose()
            return storage
        }
        return nil
    }
    /// 清理掉所有返回false的storage
    public func keepStorages(shouldKeep: (String) -> Bool) {
        let storages: [UserStorage] = lock.withLocking {
            let keys = self.storages.keys.filter { !shouldKeep($0) }
            return keys.compactMap { self.storages.removeValue(forKey: $0) }
        }
        for storage in storages {
            storage.dispose()
        }
    }
    @_disfavoredOverload
    public func getStorage(
        userID: String, compatibleMode: Bool = false,
        identifier: (() -> String)? = nil, file: String = #fileID, line: UInt = #line
    ) throws -> UserStorage {
        return try getStorage(userID: userID, type: .foreground, compatibleMode: compatibleMode,
                              identifier: identifier, file: file, line: line)
    }
    /// 获取storage，可选不会抛错的当前storage的兼容模式
    ///
    /// - Parameters:
    ///   - compatibleMode: 当前storage兼容的不会抛错的模式，未来会中断言
    public func getStorage(
        userID: String, type: UserScopeType = .foreground, compatibleMode: Bool = false,
        identifier: (() -> String)? = nil, file: String = #fileID, line: UInt = #line
    ) throws -> UserStorage {
        return try getStorage(userID: userID, nilAsCurrent: compatibleMode, type: type,
                              compatibleMode: compatibleMode, identifier: identifier,
                              file: file, line: line)
    }

    /// 获取storage，并可选进行兼容..
    /// 上层封装应该保证storage的传递性
    /// Resolver可能会用不同的container重建，也可能改变compatibleMode
    ///
    /// NOTE: 相对于直接获取storage，这里主要统一封装了兼容模式和异常抛错处理
    ///
    /// - Parameters:
    ///   - userID: 用户ID，nil值用于内部兼容，外部必定要显示的传一个值..
    ///   - compatibleMode: 兼容不存在的过期userID模式, 但**不兼容空ID**
    ///   - nilAsCurrent: 兼容没传userID的旧API
    func getStorage(
        userID: String?, nilAsCurrent: Bool, type: UserScopeType, compatibleMode: Bool = false,
        identifier: (() -> String)? = nil, file: String = #fileID, line: UInt = #line
    ) throws -> UserStorage {
        lazy var id = identifier?() ?? "\(file):\(line)"
        let userStorage: UserStorage
        if let userID = userID {
            if let v = self[userID] {
                if type.contains(v.type) {
                    userStorage = v
                } else {
                    userStorage = try mismatch(error: .unsafeCall)
                }
            } else {
                userStorage = try mismatch(error: .invalidUserID)
            }
            func mismatch(error: UserScopeError) throws -> UserStorage {
                // NOTE: FG在调用这个，切用户时userID不一致，这个调用量也不小..
                let compatibleMode = compatibleMode && type.contains(UserScopeType.foreground)
                UserExceptionInfo.log(.init(
                    scene: "GetStorage", key: id, message: "pass invalid userID",
                    callerState: compatibleMode ? .compatible : .ready))
                if compatibleMode {
                    // 只有前台用户支持compatibleMode
                    // threadCompatibleMode只用于使用当前storage，但不对返回UserResolver启用compatibleMode.
                    // 如果当前UserResolver返回后切换了用户，仍然有可能报错，但可能性较小。
                    // 主要用于区分FG和未适配的情况，区分上报。
                    return self.currentStorage()
                } else {
                    throw error
                }
            }
        } else {
            UserExceptionInfo.log(.init(
                scene: "GetStorage", key: id, message: "pass invalid nil userID",
                callerState: nilAsCurrent ? .old : .ready,
                recordStack: true, isError: true))
            guard nilAsCurrent else { throw UserScopeError.userNotFound }
            /// 主要是路由需要兼容一段时间的nil用户
            userStorage = self.currentStorage()
        }
        return userStorage
    }

    /// NOTE:TODO: 当前用户的兼容逻辑，目前需要用户登录后才算一个有效的storage
    /// 返回当前用户的storage，可能lazy创建。
    /// 这个方法保证了storage获取的原子性。
    /// 不会出现旧用户storage dispose后，用旧userid(过期当前UserID)重建的情况
    func currentStorage() -> UserStorage {
        let storage: UserStorage
        let old: UserStorage?
        do {
            lock.lock(); defer { lock.unlock() }
            let userID = self.currentUserID
            (storage, old) = _makeStorage(userID: userID, overwrite: false, type: .foreground)
        }
        old?.dispose()
        return storage
    }
    /// 兼容逻辑，获取一个已经在locking中，没有被dispose的当前storage
    func withCurrentStorageLocking<T>(action: (UserStorage) throws -> T) rethrows -> T {
        let storage: UserStorage
        let old: UserStorage?
        do {
            lock.lock(); defer { lock.unlock() }
            let userID = self.currentUserID
            (storage, old) = _makeStorage(userID: userID, overwrite: false, type: .foreground)
            storage.lock.lock()
            // 锁定storage后再释放manager锁, 避免storage被提前销毁
        }
        defer {
            storage.lock.unlock()
            old?.dispose() // dispose without lock
        }
        return try action(storage)
    }

    /// NOTE:TODO: 当前用户兼容逻辑, 原来resetScope的地方需要修改当前用户和对应的storage
    /// NOTE：因为没有保证和account那边的原子性，所以可能有一段时间存在不一致的情况
    /// 另外使用的地方也没有任何保证currentUserID随时可能变. 其依赖的状态也可能变
    /// NOTE: placeholder和空，nil等值都不相当，可能报错
    /// NOTE: 需要保证该属性对应的storage是nil或者前台storage，否则算致命异常
    @AtomicObject public var currentUserID: String = UserStorageManager.placeholderUserID
    static public let placeholderUserID = "placeholder.user.id"

    deinit {
        lock.deallocate()
    }
}

/// 用于执行用户相关的task。如果用户还没有初始化完毕，会延迟到初始化后。
/// NOTE: 用户生命周期管理需要外部集成调用
public final class UserTask {
    public static let shared = UserTask() // swiftlint:disable:this all
    public typealias Task = (String) -> Void
    enum State {
    case offline([String: Task])
    case online
    }
    @AtomicObject var state: [String: State] = [:]

    /// - Parameters:
    ///     - userID: 执行任务需要的用户
    ///     - id: 任务标识, 相同id会覆盖
    ///     - task: 用户上线后要执行的任务.
    ///         NOTE: 不同任务间没有时序保证. 执行线程也不一定在主线程上..
    ///         NOTE: 如果已经online，task会被马上运行
    ///
    /// TODO: 如果该用户最终长时间没有上线，需要有对应的清理机制
    public static func add(userID: String, id: String, task: @escaping Task) {
        UserTask.shared.add(userID: userID, id: id, task: task)
    }
    public func add(userID: String, id: String, task: @escaping Task) {
        var run: Task?
        _state.withLocking { state in
            switch state[userID] {
            case .offline(var tasks):
                state[userID] = .offline([:]) // 释放避免copy
                tasks[id] = task
                state[userID] = .offline(tasks)
            case nil:
                state[userID] = .offline([id: task])
            case .online:
                run = task // 已经online，马上调用
            }
        }
        run?(userID)
    }

    public func online(userID: String) {
        var tasks: [String: Task]?
        _state.withLocking { state in
            if case .offline(let v) = state[userID] {
                tasks = v
            }
            state[userID] = .online
        }
        tasks?.values.forEach { $0(userID) }
    }
    public func offline(userID: String) {
        _state.withLocking { state in
            state.removeValue(forKey: userID)
        }
    }
}

public enum ContainerError: Error {
    case noResolver /// 没有提供resolver
}

// MARK: Scope

public enum UserScopeError: Error {
    case userNotFound /// 没有给UserID, 不是UserResolver
    case invalidUserID /// UserID无效, 一般是全局服务用于userid验证. 多用户服务没有用户ID也使用这个错误.
    case disposed /// 已经被销毁，一般是因为用户登出
    case unsafeCall /// 调用了预期外的服务，比如期望的type不一致(服务不支持后台)，或者全局服务没有标记为用户安全.
}
extension ServiceEntry {
    /// 确认非用户态服务可以被用户态服务安全调用。安全是指：
    /// 1. 该服务本身用户安全：用户相关状态进行了正确封装处理
    /// 2. 该服务的依赖链也是用户安全的
    @discardableResult
    public func userSafe() -> Self {
        ServiceEntryUserSafeMarker.shared.add(entry: self)
        return self
    }

}
class ServiceEntryUserSafeMarker {
    static let shared = ServiceEntryUserSafeMarker()
    private let safeEntries = NSHashTable<AnyObject>.weakObjects()
    let lock = UnfairLockCell()
    deinit {
        lock.deallocate()
    }

    func add(entry: ServiceEntryProtocol) {
        lock.lock(); defer { lock.unlock() }
        safeEntries.add(entry)
    }
    func valid(entry: ServiceEntryProtocol) -> Bool {
        lock.lock(); defer { lock.unlock() }
        return safeEntries.contains(entry)
    }
}

@frozen
public struct UserScopeType: OptionSet, Hashable {
    public typealias Element = Self
    @inlinable
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    @inlinable
    public init(type: UserStorageType) {
        self.rawValue = (1 << type.rawValue)
    }
    public let rawValue: Int
    public static let foreground = UserScopeType(type: .foreground)
    public static let background = UserScopeType(type: .background)
    public static let both: UserScopeType = [.foreground, .background]
    public func contains(_ member: UserStorageType) -> Bool { self.contains(UserScopeType(type: member)) }
}
/// 用于标记用户空间的类型。用户空间的类型和外部的全局类型需要显式的传递。
/// 只有用户空间scope能够传递UserResolver.
/// 非用户空间scope不能够隐式传递UserResolver，避免全局隐式依赖上调用方的用户.
/// 非用户scope如果确实需要Resolve用户服务，需要使用UserID显式的获取UserResolver.
///
/// NOTE: 外部注入的逻辑需要注意避免引起循环引用..
/// 比如FeatureGating可能依赖account, 导致相关依赖链提前初始化
/// 目前注入的逻辑有compatible开关, 异常日志（可能依赖logger和fg）
public class UserSpaceScope: ObjectScope {
    /// 每一次resolve给一个唯一递增的counter代表顺序，仅最后resolve抛错的记录error，避免重复记录
    static var counter = AtomicUInt(0)
    /// 使用counter来确定是否是首次抛出(>= threadErrorCounter)
    static var threadErrorCounter: UInt {
        get { Thread.current.threadDictionary["UserResolver.counter"] as? UInt ?? 0 }
        set { Thread.current.threadDictionary["UserResolver.counter"] = newValue }
    }
    // 要结合storage前后台才能知道这个compatbile参数能不能用。所以scope上可以标记未compatible
    let compatible: () -> Bool
    let type: UserScopeType
    /// 用户可以创建自定义的scope，用于区分是否开启兼容模式. 主要用于FG回滚..
    public init(type: UserScopeType = .foreground, compatible: @escaping () -> Bool) {
        self.type = type
        self.compatible = compatible
    }

    @_disfavoredOverload
    public init(compatible: @escaping () -> Bool) {
        self.type = .foreground
        self.compatible = compatible
    }

    public override func get<Service, Arguments>(entry: ServiceEntry<Service>, context: ResolverContext<Service, Arguments>) throws -> Service {
        let wrapper = UserResolverContext<Service>(base: self, context: context)
        do {
            let userResolver = try wrapper.getUserResolver()
            return try UserResolver.ensureThreadCompatibleMode(wrapper.threadCompatibleMode) {
                return try invoke(entry: entry, arguments: context.arguments(userResolver))
            }
        } catch {
            wrapper.logCatchError(error)
            throw error
        }
    }
}
/// 用户容器内transient生命周期的服务, 不会保存，但会透传UserResolver。
/// 推荐使用这一个名字来创建对应的scope
public typealias UserTransientScope = UserSpaceScope

/// 存储到用户空间, 和用户生命周期一致的容器对象
public final class UserLifeScope: UserSpaceScope {
    public override func get<Service, Arguments>(entry: ServiceEntry<Service>, context: ResolverContext<Service, Arguments>) throws -> Service { // swiftlint:disable:this all
        /// 考虑到迁移的稳定性，需要对各种情况进行动态兼容。未迁移的代码，会进行强解包，异常可能crash.
        ///
        /// 主要影响因素有：(可以通过FG控制兼容开关)
        /// 1. 调用方是否未迁移完毕，需要兼容，但只需要同步调用不抛错即可.
        /// 2. 实现方是否未迁移完毕，需要兼容，传递兼容UserResolver
        /// 3. 其他scope的传递兼容情况
        ///
        /// 兼容方式都是使用CurrentStorage，并打印相关的异常日志方便迁移.
        ///
        /// 具体Case有：
        /// 1. 显示标记需要兼容(UserResolver.compatible = true)
        /// 2. 未适配的Resolver调用
        /// 3. 未适配的oldAPI调用(user相关的都应该换成assert的API并进行容错)
        /// 4. 初始调用不兼容，不能抛错。(Thread.compatible = true)
      let wrapper = UserResolverContext<Service>(base: self, context: context)
      do {
        func getStorage(inlock userStorage: UserStorage) throws -> AtomicObject<Service?> {
            #if DEBUG || ALPHA
            userStorage.lock.assertOwner()
            #endif
            try userStorage.checkDisposed()
            let key = ObjectIdentifier(entry)
            if let storage = userStorage.storage[key] as? AtomicObject<Service?> {
                return storage
            }
            // lazy created storage
            let storage = AtomicObject<Service?>(wrappedValue: nil)
            userStorage.storage[key] = storage
            return storage
        }
        var threadCompatibleMode = false
        /// 兼容模式下不能抛错，使用始终存在的当前storage
        func currentStorage() throws -> (AtomicObject<Service?>, UserStorage) {
            threadCompatibleMode = true
            return try UserStorageManager.shared.withCurrentStorageLocking {
                do {
                    return try (getStorage(inlock: $0), $0)
                } catch {
                    #if DEBUG || ALPHA
                    fatalError("withCurrentStorageLocking shouldn't throw error")
                    #endif
                    throw error
                }
            }
        }

        // get object storage
        let objectStorage: AtomicObject<Service?>
        let storage: UserStorage
        let getResolver: () -> UserResolver
        if let v = wrapper.callerUserResolver {
            if wrapper.threadCompatibleMode {
                (objectStorage, storage) = try currentStorage()
                wrapper.logCompatible(caller: v, current: storage)
            } else {
                /// 本身可以接受抛错。但factory内看用户的配置进行compatible标记的转换
                objectStorage = try wrapper.withLogDispose(caller: v) {
                    return try v.storage.lock.withLocking {
                        return try getStorage(inlock: v.storage)
                    }
                }
                storage = v.storage
            }
            getResolver = {
                v.make(storage: storage, resolver: context.container ?? v.resolver, compatible: wrapper.serviceCompatible)
            }
        } else {
            // 没传userID说明没有适配，会始终兼容，但迁移结束后改成assert
            try wrapper.throwUserNotFoundForBackgroundUser()
            // fatalError
            (objectStorage, storage) = try currentStorage()
            wrapper.logNonUser(current: storage)
            getResolver = { UserResolver.make(storage: storage, resolver: context.container ?? context.resolver,
                                              compatible: wrapper.serviceCompatible) }
        }
        // get or make service
        return try objectStorage.withLocking { (current) -> Service in
            // 使用独立的隔离storage创建，这样避免创建方法长时间占用公共的entry：value锁, 以及可能的死锁
            if let value = current { return value }

            // 保证当前同步调用不会抛错，但不保证异步调用不抛错
            return try UserResolver.ensureThreadCompatibleMode(threadCompatibleMode) {
                // factory还没适配的，需要启用兼容模式，避免抛错崩溃
                // 并且factory中传入的，保证始终是UserResolver
                let resolver = getResolver()

                // NOTE: 原来设想能够通过线程变量获取到context，然后获取一致的userResolver.
                // 目前既然都保证一定作为参数传递，就没必要更新userResolver了.. 先不放开这段逻辑
                // context[.userResolver] = resolver // update to newer pass in userResolver

                let value = try invoke(entry: entry, arguments: context.arguments(resolver))
                current = value
                #if DEBUG || ALPHA
                if resolver._compatibleMode == false, Swift.type(of: value) is AnyClass {
                    storage.lock.lock(); defer { storage.lock.unlock() }
                    storage.weakObjects.add(value as AnyObject)
                }
                #endif
                return value
            }
        }
      } catch {
          wrapper.logCatchError(error)
          throw error
      }
    }
    /// 一般用户存储的生命周期应该是和用户登录的生命周期一致，而不是和容器绑定..
    /// 考虑是否要由用户生命周期和容器共同决定生命周期，即先得通过容器加用户来拿到对应的storage..(entry本身就是容器相关的..)
    /// NOTE: 这里兼容原来userscope的行为，清理当前用户的数据，但没有清理其他用户的数据
    /// 这样之前的userscope管控方法和现在新的方法都可以混用
    public override func reset<Service>(entry: ServiceEntry<Service>) {
        // NOTE:TODO: 完全的用户隔离后，这个方法不应该被调用
        let userID = UserStorageManager.shared.currentUserID
        if let userStorage = UserStorageManager.shared[userID] {
            _ = userStorage.lock.withLocking {
                userStorage.storage.removeValue(forKey: ObjectIdentifier(entry))
            }
        }
    }
    public override func reset(entries: [ServiceEntryProtocol]) {
        let userID = UserStorageManager.shared.currentUserID
        if let userStorage = UserStorageManager.shared[userID] {
            var hold = [Any]() // for release out lock
            userStorage.lock.withLocking {
                for entry in entries {
                    if let old = userStorage.storage.removeValue(forKey: ObjectIdentifier(entry)) {
                        hold.append(old)
                    }
                }
            }
        }
    }
}
/// 用户空间，resolve链上临时共享的对象
public final class UserGraphScope: UserSpaceScope {
    public final class Storage<Service> {
        var storage: [String: Service] = [:]
    }

    public override func get<Service, Arguments>(entry: ServiceEntry<Service>, context: ResolverContext<Service, Arguments>) throws -> Service {
        let wrapper = UserResolverContext<Service>(base: self, context: context)
        do {
            let userResolver = try wrapper.getUserResolver()
            // get storage
            let storage: Storage<Service>
            let graph = GraphObjectScope.Storage.threadLocal
            let key = ObjectIdentifier(entry)
            if let v = graph[key] as? Storage<Service> {
                storage = v
            } else {
                storage = .init()
                graph[key] = storage
            }

            // NOTE: 兼容模式storage可能变化，导致重建, 但即时这里不变也可能在resolve user时变化..
            // get or make
            if let value = storage.storage[userResolver.userID] {
                return value
            } else {
                return try UserResolver.ensureThreadCompatibleMode(wrapper.threadCompatibleMode) {
                    let result = try invoke(entry: entry, arguments: context.arguments(userResolver))
                    storage.storage[userResolver.userID] = result
                    return result
                }
            }
        } catch {
            wrapper.logCatchError(error)
            throw error
        }
    }
    public override func reset<Service>(entry: ServiceEntry<Service>) {
        let graph = GraphObjectScope.Storage.threadLocal
        let key = ObjectIdentifier(entry)
        if let v = graph[key] as? Storage<Service> {
            v.storage.removeAll()
        }
    }
}

// MARK: Helper
final class UserResolverContext<Service> {
    let base: UserSpaceScope
    let context: AnyResolverContext
    lazy var serviceCompatible: Bool = base.compatible()
    lazy var serviceDescription = String(reflecting: Service.self)
    lazy var callerUserResolver = context[.userResolver] as? UserResolver
    var userID: String? { callerUserResolver?.userID }
    lazy var callerState: UserExceptionInfo.CodeState = {
        if let callerUserResolver {
            if callerUserResolver.background { return .ready }
            // 旧API先用兼容模式，避免返回空崩溃
            if (context[.oldAPI] as? Bool) == true {
                return .old
            } else {
                return callerUserResolver.compatibleMode ? .compatible : .ready
            }
        } else {
            return .old
        }
    }()
    var calleeState: UserExceptionInfo.CodeState {
        if base === ObjectScope.user { return .old }
        return serviceCompatible ? .compatible : .ready
    }
    var threadCompatibleMode: Bool { callerState != .ready }
    lazy var baseType = String(describing: type(of: base))
    let counter: UInt
    /// 排除自身能控制的storage dispose，已经记录error的情况
    var alreadyLogThrow = false

    init(base: UserSpaceScope, context: AnyResolverContext) {
        self.base = base
        self.context = context
        counter = UserSpaceScope.counter.increment()
    }

    /// 返回兼容的userResolver，可能会抛出dispose错误
    func getUserResolver() throws -> UserResolver {
        if let v = callerUserResolver {
            if threadCompatibleMode {
                let storage = UserStorageManager.shared.currentStorage()
                logCompatible(caller: v, current: storage)
                if v.storage !== storage { /// change to current storage to avoid hold a expired storage
                    return UserResolver.make(storage: storage, resolver: v.resolver, compatible: serviceCompatible)
                } else {
                    return v.changeCompatibleMode(to: serviceCompatible)
                }
            } else {
                try withLogDispose(caller: v) {
                    try v.storage.checkDisposed()
                }
                return v.changeCompatibleMode(to: serviceCompatible)
            }
        } else {
            try throwUserNotFoundForBackgroundUser()

            let userResolver = UserResolver.make(storage: UserStorageManager.shared.currentStorage(),
                                                 resolver: context.resolver, compatible: serviceCompatible)
            logNonUser(current: userResolver.storage)
            return userResolver
        }
    }
    func logCompatible(caller: UserResolver, current storage: UserStorage) {
        assert(callerState != .ready)
        let isOld = callerState == .old || calleeState == .old
        if caller.storage !== storage {
            // 发现不一致的case，记录并变更为当前storage(可以避免后续也出现不一致的问题)
            UserExceptionInfo.log(.init(
                scene: "Resolve.\(baseType)", key: serviceDescription,
                message: "兼容 userResolver.storage != currentStorage",
                callerState: callerState, calleeState: calleeState,
                recordStack: callerState == .old, isError: isOld))
        } else if isOld {
            // 调用方进行了迁移，但是有遗漏的旧API调用，或者实现方是旧API。进行上报
            // 这个调用量级应该没有NonUser高
            UserExceptionInfo.log(.init(
                scene: "Resolve.\(baseType)", key: serviceDescription,
                message: callerState == .old ? "应该使用新的resolve(assert:) API"
                                             : "应该迁移user scope",
                callerState: callerState, calleeState: calleeState,
                recordStack: isOld, isError: isOld))
        }
    }
    func withLogDispose<T>(caller: UserResolver, action: () throws -> T) rethrows -> T {
        assert(callerState == .ready)
        // 调用方可以接受抛错，如果已经dispose了直接抛错
        // NOTE: 即时这里没有dispose，之后也可能dispose，或者调用到全局的自定义验证然后抛错..
        do {
            return try action()
        } catch {
            UserExceptionInfo.log(.init(
                scene: "Resolve.\(baseType)", key: serviceDescription,
                message: "userResolver.storage.disposed",
                callerState: callerState, calleeState: calleeState))
            alreadyLogThrow = true
            throw error
        }
    }
    func throwUserNotFoundForBackgroundUser() throws {
        // 如果支持前台，不传可以用当前用户兜底. 现有大量代码没有传.
        // 如果强制要求传，只能针对新代码，或者把旧代码改完..
        // 又因为目前的运行时检查本来也没法防止全局调用，所以支持前台的就先兼容不拦截了..
        if base.type == .background {
            // background only的服务不兼容不传user
            logNonUser(current: nil)
            alreadyLogThrow = true
            throw UserScopeError.userNotFound
        }
    }
    func logNonUser(current: UserStorage?) {
        assert(callerState == .old)
        UserExceptionInfo.log(.init(
            scene: "Resolve.\(baseType)", key: serviceDescription,
            message: "应该使用UserResolver来获取用户服务",
            callerState: callerState, calleeState: calleeState,
            recordStack: true, isError: true))
    }
    func logCatchError(_ error: Error) {
        // 仅记录首次抛出的错误，避免反复的记录相同的error
        // NOTE: 如果设置了compatible, 或者userID一致还会抛错，属于异常情况，需要关注一下
        if UserSpaceScope.threadErrorCounter < counter {
            UserSpaceScope.threadErrorCounter = counter
            if !alreadyLogThrow {
                UserExceptionInfo.log(.init(
                    scene: "Error.\(baseType))", key: serviceDescription,
                    message: "用户服务获取出错: \(error)",
                    callerState: callerState, calleeState: calleeState))
                return // 上报异常埋点同时打印
            }
        }
        // 没处理异常，打印一下日志协助排查问题
        warn("用户服务获取出错: \(serviceDescription) \(error)")
    }
}

extension ResolverContextKey {
    static let userResolver = Self(rawValue: "UserResolver")
}

public struct ContainerWithScope<ResolverType> {
    public let container: Container
    public let scope: ObjectScope
    public init(container: Container, scope: ObjectScope) {
        self.container = container
        self.scope = scope
    }
}

/// 异常信息上报，方便统计和排查问题
/// EXCEPTION: userID是必传的，没传userID没抛错的，都是需要修复的情况，会进行异常上报
public struct UserExceptionInfo: CustomStringConvertible, Hashable, Equatable {
    /// 场景ID, 用于塞选具体上报的位置, 可以按一定规范拼接. 用于识别实现ID
    public var scene: String
    /// 调用方关键特征，用于过滤和分组
    public var key: String = ""
    /// 日志提示信息，用于参考, 最好有一定规范特征方便过滤。一般是对应的补充额外信息
    public var message: String
    /// 调用方给予的userID，可能没给(nil), nil的情况都是需要具体查看的
    // public var userID: String?
    /// 当前容器对应的userID, 可能没有或者是占位userID, 也可能不需要上报
    // public var currentUserID: String? = UserStorageManager.shared.currentUserID
    /// 调用方代码状态
    public var callerState: CodeState = .unknown
    /// 实现方(被调用方)代码状态
    public var calleeState: CodeState = .unknown
    public enum CodeState: UInt8, RawRepresentable {
        /// 未设置情况, 没有提供方也会留空
        case unknown = 0
        /// 新代码，非兼容模式, 接受/抛出错误
        case ready = 1
        /// 新代码，开启兼容模式
        case compatible = 2
        /// 未适配需要迁移的代码, 部分能识别出未迁移API的会设置为这个状态，并进行兼容。
        /// 包含没提供user，或者遗漏使用旧API有assert的情况。
        /// old应该只计算直接使用old接口的，记录迁移，间接兼容的不需要额外处理
        case old = 3
    }
    public var recordStack = false
    /// 需要人为处理的异常上报case，通常是因为未迁移或者遗漏..
    public var isError = false
    /// 异常严重级别，error是必须处理的
    public var level: UInt8 {
        if isError { return 1 }
        return 2 // WARNING, 暂时没有其他级别
    }

    public var uploadParams: [String: Any] {
        return [
            "scene": scene,
            "key": key,
            "message": message,
            "callerState": callerState.rawValue,
            "calleeState": calleeState.rawValue,
            "level": level
        ]
    }
    public var description: String {
        // var componets = ["uid=\(userID ?? "")"]
        var componets = [String]()
        if callerState.rawValue != 0 { componets.append("caller=\(callerState.rawValue)") }
        if calleeState.rawValue != 0 { componets.append("callee=\(calleeState.rawValue)") }
        return "\(scene):\(key):\(message); \(componets.joined(separator: ", "))"
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(scene)
        hasher.combine(key)
        hasher.combine(message)
        hasher.combine(callerState)
        hasher.combine(calleeState)
        hasher.combine(level)
    }
    public static func == (lhs: UserExceptionInfo, rhs: UserExceptionInfo) -> Bool {
        return lhs.scene == rhs.scene
        && lhs.key == rhs.key
        && lhs.message == rhs.message
        && lhs.callerState == rhs.callerState
        && lhs.calleeState == rhs.calleeState
        && lhs.level == rhs.level
    }

    public init(scene: String,
                key: String = "",
                message: String,
                callerState: CodeState = .unknown,
                calleeState: CodeState = .unknown,
                recordStack: Bool = false,
                isError: Bool = false) {
        self.scene = scene
        self.key = key
        self.message = message
        self.callerState = callerState
        self.calleeState = calleeState
        self.recordStack = recordStack
        // TODO: old的调用太多了，日志先降级成warnning
        self.isError = isError && callerState != .old && calleeState != .old
    }

    /// 记录该异常信息
    public static func log(_ exception: UserExceptionInfo) {
        UserStorageManager.delegate.log(exception: exception)
    }
}

struct DefaultLarkContainerDelegate: LarkContainerDelegate {
    var disabledUserFG: Bool { false }
    var disabledVariableCompatibleUserID: Bool { false }

    func log(exception: UserExceptionInfo) {
        print(exception.description)
    }
    func warn(_ message: String, file: String, line: Int) {
        print("[WARNING]" + message)
    }
    func info(_ message: String, file: String, line: Int) {
        print("[INFO]" + message)
    }
}

func warn(_ message: String, file: String = #fileID, line: Int = #line) {
    UserStorageManager.delegate.warn(message, file: file, line: line)
}
func info(_ message: String, file: String = #fileID, line: Int = #line) {
    UserStorageManager.delegate.info(message, file: file, line: line)
}

#if DEBUG
func registContainer(container: Container) {
    let bothUserScope = container.inObjectScope(.user(type: .both))
    let backgroundOnlyUserScope = container.inObjectScope(.user(type: .background))
    bothUserScope.register(PushNotificationCenter.self) { resolver in
            let scope = ScopedPushNotificationCenter()
            scope.userID = resolver.userID
            return scope
    }
}
#endif
// swiftlint:enable missing_docs
