//
//  BootContext.swift
//  BootManager
//
//  Created by KT on 2020/6/9.
//

import UIKit
import Foundation

public final class GlobalBootContext {
    // MARK: - public
    /// 是否后台启动
    /// 目前iOS不需要lightlyActive，开启后可能导致置顶Stream接口不返回、Push被拦截
    public var isLightlyActive = false

    /// 是否启动直接登录
    public internal(set) var isFastLogin = false
    
    /// 是否启动完成
    public internal(set) var hasBootFinish = false

    /// 当前UserID
    /// userID一开始是nil，登录后变为对应的值
    /// 每次登录，对应launcher都需要重建, 保证旧流程即时终止，避免生命周期过长，串用户.
    /// 因此oldValue有值时变化，必须配对同时调用customBoot替换launcher
    /// TODO: 进一步精确规范launcher的生命周期，并有相关的检查。
    /// 最好把currentUserID的更新，和launcher的创建绑定在一起, 避免意外更改currentUser
    public internal(set) var currentUserID: String? {
        didSet {
            assert(Thread.isMainThread, "should occur on main thread!")
            if oldValue != currentUserID {
                printVerbose("[Info] boot currentUserID changed from \(oldValue) to \(currentUserID)")
                // 用户相关的所有状态，通过主线程来保证串行。
                // 这样保证切换后之前使用它的对象生命周期都正常结束，没有并发.
                NewBootManager.shared.globalTaskRepo.onceUserScopeTasks.removeAll()
            }
        }
    }

    /// 是否切租户
    public internal(set) var isSwitchAccount = false
    
    ///首屏是否渲染完成
    public internal(set) var hasFirstRender: Bool = false

    /// 是否来自启动页
    public var isBootFromGuide = false

    /// 是否是回滚登出
    public var isRollbackLogout = false

    /// 是否是切换租户失败后的回滚；此状态下 isSwitchAccount = true
    public var isRollbackSwitchUser = false

    /// session是否创建后的第一次启动；切换租户后非第一次启动
    public var isSessionFirstActive = false

    /// 启动项
    public var launchOptions: [UIApplication.LaunchOptionsKey: Any]?

    // MARK: - 暂停Dispatcher，如didBecomeActive
    /// 暂停Dispatcher消息派发
    public var blockDispatcher = false {
        didSet {
            self.blockDispatcherCallBack?(blockDispatcher)
        }
    }
    /// Dispatcher消息派发回调
    public var blockDispatcherCallBack: ((Bool) -> Void)?

    //MARK: internal
    // TODO: 清理各种 options
    internal func reset() {
        currentUserID = nil
        isFastLogin = false
        isSwitchAccount = false
        isRollbackLogout = false
        isRollbackSwitchUser = false
        hasFirstRender = false
        self.resetUser()
    }

    /// 切租户的场景调用
    internal func resetUser() {
        blockDispatcher = false
    }

    /// 切租户的场景调用
    internal func resetOnceUserScopeTasks() {
        NewBootManager.shared.globalTaskRepo.onceUserScopeTasks.removeAll()
    }
}

/// 启动上下文
@dynamicMemberLookup
public final class BootContext {

    /// 本次启动上下文唯一 ID
    public var contextID: String

    /// 启动时间
    public let launchTime = Date().timeIntervalSince1970

    /// Window
    public internal(set) weak var window: UIWindow?

    /// 第一个Tab
    public var firstTab: String? {
        didSet {
            guard oldValue != firstTab else { return }
            self.updateScopeByTab(firstTab)
        }
    }

    // MARK: - internal
    /// 根据firstTab、launchOption解析的业务范围，会和Task的scope匹配
    public var scope: Set<BizScope> = [] {
        didSet {
            NewBootManager.logger.info("boot_update_scope_with: \(scope)")
        }
    }

    @available(iOS 13.0, *)
    public var scene: UIScene? {
        set { _scene = newValue }
        get { return _scene as? UIScene }
    }
    private weak var _scene: AnyObject?

    @available(iOS 13.0, *)
    public weak var session: UISceneSession? {
        set { _session = newValue }
        get { return _session as? UISceneSession }
    }
    private weak var _session: AnyObject?

    @available(iOS 13.0, *)
    public internal(set) var connectionOptions: UIScene.ConnectionOptions? {
        set { _connectionOptions = newValue }
        get { return _connectionOptions as? UIScene.ConnectionOptions }
    }
    private var _connectionOptions: AnyObject?

    public subscript<T>(dynamicMember keyPath: KeyPath<GlobalBootContext, T>) -> T {
        globelContext[keyPath: keyPath]
    }
    public subscript<T>(dynamicMember keyPath: ReferenceWritableKeyPath<GlobalBootContext, T>) -> T {
        get { globelContext[keyPath: keyPath] }
        set { globelContext[keyPath: keyPath] = newValue }
    }
    public let globelContext: GlobalBootContext

    init(contextID: String, globelContext: GlobalBootContext) {
        self.contextID = contextID
        self.globelContext = globelContext
        self.updateScopeByLaunchOptions(globelContext.launchOptions)
    }

    /// 切租户的场景调用
    internal func resetUser() {
        firstTab = nil
        scope = []
    }

    fileprivate func updateScopeByTab(_ tab: String?) {
        guard let firstTab = tab else { return }
        NewBootManager.logger.info("boot_update_first_Tab: \(firstTab)")
        let dependency = NewBootManager.shared.dependency
        guard let scope = dependency.tabStringToBizScope(firstTab) else { return }
        self.scope.insert(scope)
    }

    fileprivate func updateScopeByLaunchOptions(
        _ launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        let dependency = NewBootManager.shared.dependency
        guard let scope = dependency.launchOptionToBizScope(launchOptions) else { return }
        self.scope.insert(scope)
    }

    // forward to GlobalBootContext
    public var currentUserID: String? { globelContext.currentUserID }
    public var isFastLogin: Bool { globelContext.isFastLogin }
    public var isSwitchAccount: Bool { globelContext.isSwitchAccount }
}
