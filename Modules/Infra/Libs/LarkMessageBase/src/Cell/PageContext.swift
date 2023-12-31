//
//  PageContext.swift
//  LarkThread
//
//  Created by liuwanlin on 2019/3/12.
//

import Foundation
import RxSwift
import RxCocoa
import Swinject
import AsyncComponent
import EENavigator
import LarkFeatureGating
import LarkInteraction
import LarkContainer
import ThreadSafeDataStructure
import EEAtomic
import RustPB
import RichLabel
import LarkModel
import UIKit
import ServerPB
import LKCommonsLogging
import LarkSetting
import LarkNavigation
import LarkAccountInterface

// swiftlint:disable missing_docs
public enum ContextScene {
    /// 小组 带有Chat特性
    case threadChat
    /// 话题详情页
    case threadDetail
    /// 私有话题群转发
    case threadPostForwardDetail
    /// 新Chat
    case newChat
    /// 合并转发详情页
    case mergeForwardDetail
    /// 消息详情页
    case messageDetail
    /// chat中的话题回复
    case replyInThread

    case pin

    public func isThreadScence() -> Bool {
        if self == .threadChat || self == .threadDetail || self == .threadPostForwardDetail || self == .replyInThread {
            return true
        }
        return false
    }
}

public protocol DataSourceAPI: AnyObject, CellConfigProxy {
    /// 场景
    var scene: ContextScene { get }

    /// 过滤模型（特别注意，context需要传对）
    ///
    /// - Parameter predicate: 过滤方法
    func filter<M: CellMetaModel, D: CellMetaModelDependency, T: PageContext>
        (_ predicate: (MessageCellViewModel<M, D, T>) -> Bool) -> [MessageCellViewModel<M, D, T>]

    /// 锁数据队列
    ///
    /// - Parameter pause: 是否锁住
    func pauseDataQueue(_ pause: Bool)

    /// 刷新列表
    func reloadTable()

    /// 更新某一行cell
    ///
    /// - Parameter messageId: 消息id
    func reloadRow(by messageId: String, animation: UITableView.RowAnimation)
    /// 更新一组message
    ///
    /// - Parameter messageIds: 需要更新的消息的id
    /// - Parameter doUpdate: 更新数据操作
    func reloadRows(by messageIds: [String], doUpdate: @escaping (Message) -> Message?)

    /// 更新某一行cell
    func reloadRow(byViewModelId viewModelId: String, animation: UITableView.RowAnimation)

    /// 删除某一行cell
    ///
    /// - Parameter messageId: 消息id
    func deleteRow(by messageId: String)
    /// TODO @: zhaodong 即将优化的到ChatVM。本期因为依赖太多，暂时不重构
    /// get cell selected enable
    ///
    /// - Parameter message: 消息
    func processMessageSelectedEnable(message: Message) -> Bool

    /// - Parameter message: 当前chat置顶信息信号
    func currentTopNotice() -> BehaviorSubject<ChatTopNotice?>?
}
public extension DataSourceAPI {
    func reloadRow(byViewModelId viewModelId: String, animation: UITableView.RowAnimation) {}
}

@frozen
public struct HostUIConfig {
    /// 宿主页面宽度
    public var size: CGSize
    /// SafeAreaInsets for device.
    public var safeAreaInsets: UIEdgeInsets

    public init(size: CGSize, safeAreaInsets: UIEdgeInsets) {
        self.size = size
        self.safeAreaInsets = safeAreaInsets
    }
}

public protocol CellConfigProxy {
    /// 宿主UI配置
    var hostUIConfig: HostUIConfig { get }

    /// 窗口CR属性
    var traitCollection: UITraitCollection? { get }

    /// 是否支持头像左右布局
    var supportAvatarLeftRightLayout: Bool { get }
}

public extension CellConfigProxy {
    var supportAvatarLeftRightLayout: Bool {
        return false
    }
}

public enum ToastType {
    case loading
    case success
    case fail
    case tips
}

public typealias ChatThemeScene = ServerPB_Entities_ChatTheme.Scene

/// 通用的页面能力
public protocol PageAPI: UIViewController {
    /// 插入at
    func insertAt(by chatter: Chatter?)

    /// 回复某一条消息
    ///
    /// - Parameter message: 要回复的消息
    /// - Parameter partialReplyInfo: 局部回复的内容 如果回复整条消息PartialReplyInfo = nil
    func reply(message: Message, partialReplyInfo: PartialReplyInfo?)

    /// 重新编辑一条撤回的消息
    ///
    /// - Parameter message: 消息
    func reedit(_ message: Message)

    /// 二次编辑一条消息
    ///
    /// - Parameter message: 消息
    func multiEdit(_ message: Message)

    /// description: get keyboard is display or not
    /// jira: https://jira.bytedance.com/browse/SUITE-50825
    /// reason: some pages have reply menu but not have keyboard, so need this property to determine
    var pageSupportReply: Bool { get }

    var topNoticeSubject: BehaviorSubject<ChatTopNotice?>? { get }
    /// other view cover UIViewController.view
    func viewWillEndDisplay()

    /// from other views cover UIViewController.view to no othre views cover
    func viewDidDisplay()

    /// 获取 label 选中态 delegate
    func getSelectionLabelDelegate() -> LKSelectionLabelDelegate?

    /// 拉取会话最后一条消息，然后跳转到最后；目前只在ChatMessagesViewController有实现，其他场景请自己按需添加
    func jumpToChatLastMessage(tableScrollPosition: UITableView.ScrollPosition, needDuration: Bool)

    func showGuide(key: String)
    // 获取聊天主题场景
    func getChatThemeScene() -> ChatThemeScene
}

public extension PageAPI {
    func showGuide(key: String) {}
    var topNoticeSubject: BehaviorSubject<ChatTopNotice?>? { nil }
    func getChatThemeScene() -> ChatThemeScene { .defaultScene }
    func jumpToChatLastMessage(tableScrollPosition: UITableView.ScrollPosition, needDuration: Bool) {}
}

open class ResolverWrapper {
    fileprivate let resolver: UserResolver
    public let userPushCenter: PushNotificationCenter
    private var serviceCache = [ObjectIdentifier: Any]()
    private var rwlock: pthread_rwlock_t = pthread_rwlock_t()

    fileprivate var nav: EENavigator.Navigatable { resolver.navigator }

    init(resolver: UserResolver) {
        pthread_rwlock_init(&rwlock, nil)
        self.resolver = resolver
        if let pushCenter = try? resolver.userPushCenter {
            self.userPushCenter = pushCenter
        } else {
            PageContext.logger.warn("not find userPushCenter")
            self.userPushCenter = resolver.globalPushCenter
        }
    }

    /// cache：为true则会优先返回上一次resolve的结果，不存在则会从容器中resolve一个，并且本次结果会被cache；
    /// 如果为false，则不会有任何额外逻辑，每次都从容器中resolve，默认值为false，保持和容器一致的行为。
    @available(*, deprecated, message: "use `resolve assert` instead")
    public func resolve<Service>(_ serviceType: Service.Type, cache: Bool = false) -> Service? {
        return try? self.getService(serviceType: serviceType, cache: cache, fromResolver: {
            if let v = self.resolver.resolve(serviceType) { return v } //Global
            throw NoServiceError()
        })
    }
    struct NoServiceError: Error {}

    /// cache：为true则会优先返回上一次resolve的结果，不存在则会从容器中resolve一个，并且本次结果会被cache；
    /// 如果为false，则不会有任何额外逻辑，每次都从容器中resolve，默认值为false，保持和容器一致的行为。
    public func resolve<Service>(assert serviceType: Service.Type, cache: Bool = false) throws -> Service {
        return try self.getService(serviceType: serviceType, cache: cache, fromResolver: {
            return try self.resolver.resolve(assert: serviceType)
        })
    }

    public func resolve<Service, Arg1>(assert serviceType: Service.Type, name: String? = nil, argument arg1: Arg1) throws -> Service {
        return try self.getService(serviceType: serviceType, cache: false, fromResolver: {
            return try self.resolver.resolve(assert: serviceType, argument: arg1)
        })
    }

    public func resolve<Service, Arg1, Arg2>(assert serviceType: Service.Type, name: String? = nil, arguments arg1: Arg1, _ arg2: Arg2) throws -> Service {
        return try self.getService(serviceType: serviceType, cache: false, fromResolver: {
            return try self.resolver.resolve(assert: serviceType, arguments: arg1, arg2)
        })
    }

    public func resolve<Service, Arg1, Arg2, Arg3>(assert serviceType: Service.Type, name: String? = nil, arguments arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3) throws -> Service {
        return try self.getService(serviceType: serviceType, cache: false, fromResolver: {
            return try self.resolver.resolve(assert: serviceType, arguments: arg1, arg2, arg3)
        })
    }

    private func getService<Service>(serviceType: Service.Type, cache: Bool, fromResolver: () throws -> Service) rethrows -> Service {
        if !cache { return try fromResolver() }

        let indentifier = ObjectIdentifier(serviceType)
        // 加读锁：有缓存直接返回
        pthread_rwlock_rdlock(&rwlock)
        if let service = self.serviceCache[indentifier] as? Service {
            pthread_rwlock_unlock(&rwlock)
            return service
        }
        pthread_rwlock_unlock(&rwlock)

        // 加写锁：首先读取是否已写入缓存，有则返回；否则初始化一个返回
        pthread_rwlock_wrlock(&rwlock)
        defer { pthread_rwlock_unlock(&rwlock) }
        if let service = (self.serviceCache[indentifier] as? Service) {
            return service
        }
        let service = try fromResolver()
        self.serviceCache[indentifier] = service
        return service
    }
}

/// 通用上下文（屏蔽Thread、Chat和MessageDetail的差异）
open class PageContext {
    static let logger = Logger.log(PageContext.self, category: "PageContext")

    public struct GuideKey {
        public static let typingTranslateOnboarding = "typing_translate_onboarding"
    }

    /// 可以获取全局服务
    public let resolver: ResolverWrapper
    public var userResolver: UserResolver { resolver.resolver }
    /// 页面级别容器
    public let pageContainer: PageContainer & PageService
    /// 页面接口
    public weak var pageAPI: PageAPI?
    /// 数据源接口
    public weak var dataSourceAPI: DataSourceAPI? {
        didSet {
            self._dataSourceAPI = dataSourceAPI
        }
    }

    @available(*, deprecated, message: "please use dataSourceAPI")
    // swiftlint:disable:next identifier_name
    public weak var _dataSourceAPI: DataSourceAPI?

    @SafeLazy
    private var colorService: ColorConfigService

    public var downloadFileScene: Media_V1_DownloadFileScene?

    public var trackParams: [String: Any] = [:]

    public struct TrackKey {
        public static let sceneKey: String = "scene"
    }

    public convenience init(
        resolver: UserResolver,
        dragManager: DragInteractionManager,
        defaulModelSummerizeFactory: MetaModelSummerizeFactory
    ) {
        self.init(resolver: resolver, defaulModelSummerizeFactory: defaulModelSummerizeFactory)
        self.pageContainer.register(DragInteractionManager.self) {
            return dragManager
        }
    }

    public init(
        resolver: UserResolver,
        defaulModelSummerizeFactory: MetaModelSummerizeFactory
    ) {
        self.resolver = ResolverWrapper(resolver: resolver)
        let container = PageServiceContainer()
        self.pageContainer = container
        self.pageContainer.register(MetaModelSummerizeRegistry.self) {
            return MetaModelSummerizeRegistry(default: defaulModelSummerizeFactory)
        }
        self._colorService = SafeLazy {
            return container.resolve(ColorConfigService.self)! //Global
        }
    }
}

public extension PageContext {
    var userID: String { resolver.resolver.userID }

    func getStaticFeatureGating(_ key: FeatureGatingKey) -> Bool {
        return getStaticFeatureGating(FeatureGatingManager.Key(stringLiteral: key.rawValue))
    }
    func getStaticFeatureGating(_ key: FeatureGatingManager.Key) -> Bool {
        resolver.resolver.fg.staticFeatureGatingValue(with: key)
    }

    func getDynamicFeatureGating(_ key: FeatureGatingKey) -> Bool {
        return getDynamicFeatureGating(FeatureGatingManager.Key(stringLiteral: key.rawValue))
    }
    func getDynamicFeatureGating(_ key: FeatureGatingManager.Key) -> Bool {
        resolver.resolver.fg.dynamicFeatureGatingValue(with: key)
    }
}

/// 组件上下文
public typealias ComponentContext = AsyncComponent.Context

/// 路由类型
public enum NavigatorType {
    case open
    case push
    case present
    case showDetail
}

/// EENavigator 路由参数
public struct NavigatorParams {
    public var naviParams: NaviParams?
    public var context: [String: Any]
    /// 是否有动画
    public var animated: Bool
    /// 结束回调
    public var completion: Handler?
    /// 定制 vc，在 present 生效
    public var prepare: ((UIViewController) -> Void)?
    /// 是否对 vc 进行 wrap，在 present 和 showDetail 生效
    public var wrap: UINavigationController.Type?

    public init(
        naviParams: NaviParams? = nil,
        context: [String: Any] = [:],
        wrap: UINavigationController.Type? = nil,
        prepare: ((UIViewController) -> Void)? = nil,
        animated: Bool = true,
        completion: Handler? = nil) {
        self.naviParams = naviParams
        self.context = context
        self.wrap = wrap
        self.animated = animated
        self.prepare = prepare
        self.completion = completion
    }
}

/// 系统原生路由参数
public struct SystemNavigatorParams {
    /// 是否有动画
    public var animated: Bool
    /// 结束回调
    public var completion: Completion?
    /// 定制 vc，在 present 生效
    public var prepare: ((UIViewController) -> Void)?
    /// 是否对 vc 进行 wrap，在 present 和 showDetail 生效
    public var wrap: UINavigationController.Type?

    public init(
        wrap: UINavigationController.Type? = nil,
        prepare: ((UIViewController) -> Void)? = nil,
        animated: Bool = true,
        completion: Completion? = nil) {
        self.wrap = wrap
        self.animated = animated
        self.prepare = prepare
        self.completion = completion
    }
}

/// ViewModel上下文
public protocol ViewModelContext: AsyncComponent.Context {
    var targetVC: UIViewController? { get }
    var trackParams: [String: Any] { get }
    var navigationService: NavigationService? { get }

    func reloadTable()
    func reloadRow(by messageId: String, animation: UITableView.RowAnimation)
    func reloadRows(by messageIds: [String], doUpdate: @escaping (Message) -> Message?)
    func reloadRow(byViewModelId viewModelId: String, animation: UITableView.RowAnimation)
    func deleteRow(by messageId: String)

    func viewWillEndDisplay()
    func viewDidDisplay()

    func navigator<T: Body>(type: NavigatorType, body: T, params: NavigatorParams?)
    func navigator(type: NavigatorType, url: URL, params: NavigatorParams?)
    func navigator(type: NavigatorType, controller: UIViewController, params: SystemNavigatorParams?)

    func getStaticFeatureGating(_ key: FeatureGatingManager.Key) -> Bool
}

extension PageContext: ViewModelContext {
    public var navigationService: NavigationService? {
        return try? self.resolver.resolve(assert: NavigationService.self, cache: true)
    }

    public func viewWillEndDisplay() {
        pageAPI?.viewWillEndDisplay()
    }

    public func viewDidDisplay() {
        pageAPI?.viewDidDisplay()
    }

    public var targetVC: UIViewController? {
        return pageAPI
    }

    public func reloadTable() {
        dataSourceAPI?.reloadTable()
    }

    public func reloadRow(by messageId: String, animation: UITableView.RowAnimation = .fade) {
        dataSourceAPI?.reloadRow(by: messageId, animation: animation)
    }

    public func reloadRows(by messageIds: [String], doUpdate: @escaping (Message) -> Message?) {
        dataSourceAPI?.reloadRows(by: messageIds, doUpdate: doUpdate)
    }

    public func reloadRow(byViewModelId viewModelId: String, animation: UITableView.RowAnimation = .fade) {
        dataSourceAPI?.reloadRow(byViewModelId: viewModelId, animation: animation)
    }

    public func deleteRow(by messageId: String) {
        dataSourceAPI?.deleteRow(by: messageId)
    }

    public var navigator: Navigatable { resolver.nav }
    public func navigator(type: NavigatorType, url: URL, params: NavigatorParams?) {
        guard let targetVC: UIViewController = self.pageAPI else { return }
        let params = params ?? NavigatorParams()

        switch type {
        case .open:
            self.resolver.nav.open(
                url,
                context: params.context,
                from: targetVC,
                completion: params.completion)
        case .push:
            self.resolver.nav.push(
                url,
                context: params.context,
                from: targetVC,
                animated: params.animated,
                completion: params.completion)
        case .present:
            self.resolver.nav.present(
                url,
                context: params.context,
                wrap: params.wrap,
                from: targetVC,
                prepare: params.prepare,
                animated: params.animated,
                completion: params.completion)
        case .showDetail:
            self.resolver.nav.showDetail(
                url,
                context: params.context,
                wrap: params.wrap,
                from: targetVC,
                completion: params.completion)
        }
    }

    public func navigator(type: NavigatorType, controller: UIViewController, params: SystemNavigatorParams?) {
        guard let targetVC: UIViewController = self.pageAPI else { return }
        let params = params ?? SystemNavigatorParams()

        switch type {
        case .open:
            assertionFailure()
        case .push:
            self.resolver.nav.push(
                controller,
                from: targetVC,
                animated: params.animated,
                completion: params.completion)
        case .present:
            self.resolver.nav.present(
                controller,
                wrap: params.wrap,
                from: targetVC,
                prepare: params.prepare,
                animated: params.animated,
                completion: params.completion)
        case .showDetail:
            self.resolver.nav.showDetail(
                controller,
                wrap: params.wrap,
                from: targetVC,
                completion: params.completion)
        }
    }

    public func navigator<T: Body>(type: NavigatorType, body: T, params: NavigatorParams?) {
        guard let targetVC: UIViewController = self.pageAPI else { return }
        let params = params ?? NavigatorParams()

        switch type {
        case .open:
            self.resolver.nav.open(
                body: body,
                naviParams: params.naviParams,
                context: params.context,
                from: targetVC,
                completion: params.completion)
        case .push:
            self.resolver.nav.push(
                body: body,
                naviParams: params.naviParams,
                context: params.context,
                from: targetVC,
                animated: params.animated,
                completion: params.completion)
        case .present:
            self.resolver.nav.present(
                body: body,
                naviParams: params.naviParams,
                context: params.context,
                wrap: params.wrap,
                from: targetVC,
                prepare: params.prepare,
                animated: params.animated,
                completion: params.completion)
        case .showDetail:
            self.resolver.nav.showDetail(
                body: body,
                naviParams: params.naviParams,
                context: params.context,
                wrap: params.wrap,
                from: targetVC,
                completion: params.completion)
        }
    }
}

extension PageContext {

    public var dragManager: DragInteractionManager {
        return pageContainer.resolve(DragInteractionManager.self)!
    }
}

public typealias DragInteractionManager = LarkInteraction.DragInteractionManager

public extension DragContextKey {
    static let chat: DragContextKey = "chat_list_chat_value"
    static let message: DragContextKey = "chat_list_message_value"
    static let downloadFileScene: DragContextKey = "downloadFileScene"
}

/// 抽成独立的protocol，需要使用的地方直接impl即可
public protocol ColorConfigContext {
    /// 获取某个key对应的颜色
    func getColor(for key: ColorKey, type: Type) -> UIColor
}

extension PageContext: ColorConfigContext {
    /// 获取某个key对应的颜色
    public func getColor(for key: ColorKey, type: Type) -> UIColor {
        return colorService.getColor(for: key, type: type)
    }
}

// resolve propertyWrapper
extension PageContext {
    /// property Wrapper lazy init by context.resolver.resolve(...)
    @propertyWrapper
    public class InjectedLazy<Value>: ScopedLazy<Value?, PageContext> {
        public init(cache: Bool = false) {
            super.init {
                try? $0.resolver.resolve(assert: Value.self, cache: cache)
            }
        }
        @available(*, unavailable)
        public var wrappedValue: Value? {
            get { fatalError("should call static subscript api") }
            // swiftlint:disable:next unused_setter_value
            set { fatalError("should call static subscript api") }
        }
        public static subscript<Wrapped: PageContextWrapper>(
            _enclosingInstance observed: Wrapped,
            wrapped wrappedKeyPath: ReferenceWritableKeyPath<Wrapped, Value?>,
            storage storageKeyPath: ReferenceWritableKeyPath<Wrapped, InjectedLazy>
            ) -> Value? {
                @inlinable get { observed[keyPath: storageKeyPath].value(observed.pageContext) }
                @available(*, unavailable)
                set {}
        }
    }
    /// property Wrapper lazy get by context.resolver.resolve(...)
    @propertyWrapper
    public struct Provider<Value> {
        let cache: Bool
        public init(cache: Bool = false) {
            self.cache = cache
        }
        @usableFromInline
        func value(_ pageContext: PageContext) -> Value? {
            try? pageContext.resolver.resolve(assert: Value.self, cache: cache)
        }
        @available(*, unavailable)
        public var wrappedValue: Value? {
            get { fatalError("should call static subscript api") }
            // swiftlint:disable:next unused_setter_value
            set { fatalError("should call static subscript api") }
        }
        public static subscript<Wrapped: PageContextWrapper>(
            _enclosingInstance observed: Wrapped,
            wrapped wrappedKeyPath: ReferenceWritableKeyPath<Wrapped, Value?>,
            storage storageKeyPath: ReferenceWritableKeyPath<Wrapped, Provider>
            ) -> Value? {
                @inlinable get {
                    observed[keyPath: storageKeyPath].value(observed.pageContext)
                }
                @available(*, unavailable)
                set {}
        }
    }
}

public protocol PageContextWrapper {
    var pageContext: PageContext { get }
}

// swiftlint:enable missing_docs
