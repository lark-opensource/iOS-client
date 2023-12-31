//
//  Module.swift
//  LarkOpenChat
//
//  Created by qihongye on 2020/11/22.
//

import Foundation
import Swinject
import LKLoadable
import LarkContainer
import EENavigator
import LarkNavigator
import LarkAccountInterface
import LarkFeatureGating
import LarkSetting

/// 所有Module所具备的基础能力
public protocol IModuleContext {
    /// 全局容器
    var resolver: Resolver { get }
    /// 用户容器
    var userResolver: UserResolver { get }
    /// 页面级别KV存储
    var store: Store { get }
}

public extension IModuleContext {
    var pushCenter: PushNotificationCenter {
        (try? userResolver.userPushCenter) ?? userResolver.globalPushCenter
    }

    var nav: EENavigator.Navigatable {
        userResolver.navigator
    }
    var userID: String {
        userResolver.userID
    }

    func getFeatureGating(_ key: FeatureGatingKey) -> Bool {
        return getFeatureGating(FeatureGatingManager.Key(stringLiteral: key.rawValue))
    }
    func getFeatureGating(_ key: FeatureGatingManager.Key) -> Bool {
        userResolver.fg.staticFeatureGatingValue(with: key)
    }
}

/// 数据信息，用于canHandle、handle
public protocol MetaModel {}

/// 关键方法执行顺序：
///                       ChatVC init
///                           ↓
///                         onLoad
///                           ↓
///                     registGlobalServices，注册ChatVC级别的服务
///                           ↓
///                       canInitialize   →(false)→  end
///                           ↓
///                          (true)
///                           ↓
///                           init
///                           ↓
///                       registServices，注册Module级别的服务
///                           ↓
///                        onInitialize
///                           ↓
///                        canHandle  →(false)→  end
///                           ↓
///                          (true)
///                           ↓
///                         handler
///                           ↓
///                        onDestroy
///                           ↓
///                          deinit

open class Module<C: IModuleContext, M: MetaModel>: UserResolverWrapper {

    public var userResolver: UserResolver {
        return context.userResolver
    }

    /// objectID
    public let objectID: ObjectIdentifier
    /// context
    public let context: C

    /// name
    open class var name: String {
        assertionFailure("Must be overrided.")
        return "Module"
    }
    /// name
    public var name: String { return Self.name }
    /// id
    open var id: Int { return objectID.hashValue }

    /// Module在此处控制哪些SubModule应执行load，可实现白名单功能
    /// SubModule不能决定自己是否被load，如果要决定则应该在register处进行处理，不应load的不应该register
    open class func onLoad(context: C) {
    }

    //https://bytedance.feishu.cn/docx/doxcnyo40YshyZwRzYk5X0gptS1
    // 启动框架_silgen_name使用的key
    open class var loadableKey: String {
        return ""
    }

    // 供子类在load中调用，加载启动任务
    open class func launchLoad() {
        if !loadableKey.isEmpty {
            SwiftLoadable.startOnlyOnce(key: "\(loadableKey)")
        }
    }

    /// Regist global services ability.
    /// - Parameter injector: container. Root container for Chat scope
    /// 注册全局服务的能力
    /// - Parameter injector: .container. 整个Chat域内的根容器，用于某些不需要实例化就能regist的场景
    /// Examples:
    /// ```
    /// protocol IMyService {}
    ///
    /// override class func registGlobalServices(container: Container) {
    ///     container.regist(IMyService.self, {
    ///         return MyServiceImpl()
    ///     })
    /// }
    /// ```
    open class func registGlobalServices(container: Container) {}

    /// 决定自己是否应该初始化，只会被调用一次
    open class func canInitialize(context: C) -> Bool { return false }

    /// init
    public required init(context: C) {
        self.objectID = ObjectIdentifier(Self.self)
        self.context = context
        self.onInitialize()
    }

    /// Regist services into module's container.
    /// - Parameter container: container. Root container for Chat scope
    /// 注册服务到module的私有容器中
    /// - Parameter container: container. 整个Chat域内的根容器，用于某些需要实例化后才能regist的场景
    open func registServices(container: Container) {}

    /// initialize，可用于初始化内部的一些数据，在init中自动被调用
    open func onInitialize() {}

    /// SubModule决定自己是否能处理
    open func canHandle(model: M) -> Bool { return false }

    /// Module在此处收集所有能处理的SubModule，SubModule在此处返回自身或自己的SubModule，在canHandle后执行
    open func handler(model: M) -> [Module<C, M>] { return [self] }

    /// model变化事件
    open func modelDidChange(model: M) {}

    /// 当前是否处于激活状态：canHandle = true & 被选中进行handle
    public private(set) var activated: Bool = false
    open func beginActivaty() { self.activated = true; }
    open func endActivaty() { self.activated = false; }
    /// 是否允许被切到activated状态
    open func shouldActivatyChanged(to activated: Bool) -> Bool { return true }

    /// 触发时机：
    /// reload：canHandle -> handler -> refresh(activated == true) -> ...
    /// refresh：refresh(activated == true) -> ...
    open func onRefresh() {}

    /// 不同于deinit由系统调用，onDestroy可以在确定不需要使用时主动调用
    open func onDestroy() {}
}

extension Module: Hashable {
    public static func == (lhs: Module<C, M>, rhs: Module<C, M>) -> Bool {
        return lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        objectID.hash(into: &hasher)
    }
}

/// 通用环境基础类，避免重复代码
open class BaseModuleContext: IModuleContext {
    /// 隔离K-V 存储
    public let store: Store
    @available(*, deprecated, message: "please use userResolver!")
    public var resolver: Resolver { userResolver }
    /// 用户隔离的容器依赖
    public let userResolver: UserResolver
    /// 子隔离容器环境, 注意不要污染父容器
    public let container: Container

    public init(parent: Container, store: Store, userStorage: UserStorage, compatibleMode: Bool = false) {
        self.container = parent
        self.userResolver = container.getUserResolver(storage: userStorage, compatibleMode: compatibleMode)
        self.store = store
    }
}
