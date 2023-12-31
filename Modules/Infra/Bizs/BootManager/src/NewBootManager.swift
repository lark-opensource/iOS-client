//
//  NewBootManager.swift
//  BootManager
//
//  Created by sniperj on 2021/4/19.
//

import UIKit
import Foundation
import LKCommonsLogging
import BootManagerConfig
import ThreadSafeDataStructure
import LKCommonsTracker
import LarkStorage
import LarkPreload
import RunloopTools
import LKLoadable

/// 注册式任务触发时机
public enum RegisterTaskTriggerMoment: String {
    case none                    //默认
    case afterFirstRender        //首屏渲染
}

//注册式任务闭包
public typealias RegisterTaskAction = () -> Void

/// 启动管理器，兼容多sence，管理启动的生命周期
/// https://bytedance.larkoffice.com/wiki/wikcnTUiUab9fzooNdDQVKoZkGg
public final class NewBootManager {
    //单例
    public static let shared = NewBootManager()
    
    //启动任务是否通过preload触发-外部注入
    public var bootSchedulerByPreload: Bool = false
    
    //全局启动上下文
    public let context = GlobalBootContext()
    
    //每一次启动上下文
    var connectedContexts: [String: BootContext] = [:]
    //launcher容器
    internal var launchers: [String: Launcher] = [:]
    //上报启动数据
    public var bootTaskCostData: [String: Double] = [:]

    //失联通知
    private var didDisconnectNotiObject: NSObjectProtocol?
    //调度器，选择执行线程
    internal let scheduler = BootTaskScheduler()
    
    //全局任务
    internal var globalTaskRepo = BootGlobalTaskRepo()
    //懒加载任务
    var lazyTasks: SafeArray<BootTask> = [] + .readWriteLock
    //预加载任务
    var preloadTasks: SafeArray<BootTask> = [] + .readWriteLock
    //注册式任务
    var registTaskRepo: SafeDictionary<String, [RegisterTaskAction]> = [:] + .readWriteLock
    
    //外部依赖
    public var dependency: BootDependency = BootManagerDependency()
    //日志
    internal static let logger = Logger.log(NewBootManager.self)

    //启动框架初始化时间
    var bootManagerStartTime: TimeInterval = CACurrentMediaTime()

    init() {
        if #available(iOS 13.0, *) {
            self.observeSceneNotification()
        }
    }
    
    // MARK: Boot
    /// 开始启动，didFinishLaunching调用
    public func boot(rootWindow: UIWindow, scope: Set<BizScope> = [], firstTab: String? = nil) {
        let context = BootContext(
            contextID: UUID().uuidString,
            globelContext: self.context
        )
        context.window = rootWindow
        context.scope = scope
        context.firstTab = firstTab
        connectedContexts[context.contextID] = context
        self.customBoot(context: context)
    }

    /// 开始启动，didFinishLaunching调用
    @available(iOS 13.0, *)
    public func boot(
        rootWindow: UIWindow,
        scene: UIScene,
        session: UISceneSession,
        connectionOptions: UIScene.ConnectionOptions
    ) {
        /// 使用 scene 方式初始化的时候，hook scene 的销毁
        NewBootManager.hookSceneDisconnectIfNeeded()

        let context = BootContext(
            contextID: session.persistentIdentifier,
            globelContext: self.context
        )
        context.window = rootWindow
        context.scene = scene
        context.session = session
        context.connectionOptions = connectionOptions
        connectedContexts[context.contextID] = context
        self.customBoot(context: context)
    }
    
    internal func customBoot(
        flow: FlowType? = nil,
        taskIdentify: TaskIdentify? = nil,
        context: BootContext) {
        weak var old = launchers[context.contextID]
        old?.dispose()
        let launcher = Launcher(context: context)
        self.launchers[context.contextID] = launcher // 同时释放旧的launcher, 旧launcher流程中断
        assert(old == nil, "old launcher should be dealloc!")
        NewBootManager.logger.info("boot_start_with_flow: \(flow?.rawValue ?? "null")")
        if let flow = flow {
            launcher.executeFlow(with: flow, task: taskIdentify)
        } else {
            launcher.defaultExecute()
        }
    }
    
    /// 业务方不应该能够自由触发flow, 只能checkout，保证相关流程的串行
    /// - Parameter stage: StageType
    func trigger(with flow: FlowType, launcher: Launcher) {
        NewBootManager.logger.info("boot_trigger_with_flow:\(flow)")
        /// launcher的运行不应该串生命周期
        if let current = self.launchers[launcher.context.contextID], current === launcher {
            launcher.trigger(with: flow)
            if flow == .cpuIdle {
                // FIXME: 如果idle的有异步任务，其实没有完全结束..
                finished(launcher: launcher)
            }
        }
    }

    //MARK: Regist
    /// 注册启动Task
    /// - Parameters:
    ///   - taskType: Task.Type
    ///   - provider: Task工厂
    @discardableResult
    public static func register<T: BootTask&Identifiable>(
        _ task: T.Type,
        provider: @escaping BootTaskProvider) -> BootTask.Type {
        BootTaskRegistry.register(task, provider: provider)
        return task
    }
    @available(*, deprecated, message: "provider should accept a BootContext to init")
    @discardableResult
    public static func register<T: BootTask&Identifiable>(
        _ task: T.Type,
        provider: @escaping () -> BootTask) -> BootTask.Type {
        BootTaskRegistry.register(task, provider: { _ in provider() })
        return task
    }

    /// 注册启动Task
    /// - Parameter task: Task.Type
    @discardableResult
    public static func register<T: BootTask&Identifiable>(_ task: T.Type) -> BootTask.Type {
        BootTaskRegistry.register(task, provider: task.init(context:))
        return task
    }
    
    /*
     注册指定时机触发的任务，执行的线程默认会在主线程执行，业务方可根据自己的实际场景在action内部做线程切换。
        taskAction: 任务闭包
        triggerMoment: 执行时机
     */
    public func registerTask(taskAction: @escaping RegisterTaskAction, triggerMoment: RegisterTaskTriggerMoment) {
        if let actions = registTaskRepo[triggerMoment.rawValue] {
            var newActions = actions
            newActions.append(taskAction)
            registTaskRepo[triggerMoment.rawValue] = newActions
        } else {
            var actions: [RegisterTaskAction] = []
            actions.append(taskAction)
            registTaskRepo[triggerMoment.rawValue] = actions
        }
    }

    //MARK: Other
    ///首屏UI渲染(UI控件渲染)
   public func afterFirstRender() {
       guard !self.context.hasFirstRender else {
           return
       }
       self.context.hasFirstRender = true
       //启动关键结点-只有快速登录上报
       BootMonitor.shared.doBootKeyNode(keyNode: .firstUIRenderNodel, isEnd: true)
       DispatchQueue.main.async {
           //执行注册到afterFirstRender时机执行的任务
           if let actions = self.registTaskRepo[RegisterTaskTriggerMoment.afterFirstRender.rawValue] {
               actions.forEach({ action in
                   action()
               })
               self.registTaskRepo[RegisterTaskTriggerMoment.afterFirstRender.rawValue]?.removeAll()
           }
          //执行afterFirstRender flow中定义的任务。
          if let launcher = self.launchers.values.first {
              self.trigger(with: .afterFirstRender, launcher: launcher)
          }
        //执行LKLoadable方式指定afterFirstRender时机添加的任务。
        LKLoadableManager.run(LKLoadable.afterFirstRender)

        //埋点和日志
        //原逻辑上报slardar埋点
        let event = SlardarEvent(name: "boot_manager_launch", metric: NewBootManager.shared.bootTaskCostData, category: [:], extra: ["launchType":"firstRender"])
        Tracker.post(event)

        //首屏阶段的task上报完之后清空，闲时的任务在idleflow执行完之后上报
        NewBootManager.shared.bootTaskCostData.removeAll()
       }
   }

    /// 启动完成，清理内存
    internal func finished(launcher: Launcher) {
        launcher.taskRepo.clearAll()
        NewBootManager.logger.info("boot_Finished")
        //上报闲时任务的耗时埋点
        let event = SlardarEvent(name: "boot_manager_launch", metric: NewBootManager.shared.bootTaskCostData, category: [:], extra: ["launchType":"idle"])
        NewBootManager.shared.context.hasBootFinish = true
        Tracker.post(event)
    }

    /// 监听 scene 的销毁
    @available(iOS 13.0, *)
    private func observeSceneNotification() {
        self.didDisconnectNotiObject = NotificationCenter.default.addObserver(
            forName: UIScene.didDisconnectNotification,
            object: nil,
            queue: nil) { [weak self] (noti) in
                guard let scene = noti.object as? UIWindowScene else {
                    return
                }
                self?.destructionWorkSpace(in: scene)
            }
    }

    @available(iOS 13.0, *)
    fileprivate func destructionWorkSpace(in scene: UIScene) {
        assert(Thread.isMainThread, "should occur on main thread!")
        let contextID = scene.session.persistentIdentifier
        weak var old: Launcher?
        if let launcher = self.launchers[contextID] {
            old = launcher
            launcher.dispose()
            self.connectedContexts[contextID] = nil
            self.launchers[contextID] = nil
        }
        assert(old == nil, "old launcher should be dealloc!")
    }

    /// scene 的销毁通知相对滞后，需要提前通过 hook 的方式监听
    private static var hadHookSceneDisconnect: Bool = false
    private static func hookSceneDisconnectIfNeeded() {
        if hadHookSceneDisconnect {
            return
        }
        hadHookSceneDisconnect = true
        if #available(iOS 13.0, *) {
            swizzling(
                forClass: UIApplication.self,
                originalSelector: #selector(UIApplication.requestSceneSessionDestruction(_:options:errorHandler:)),
                swizzledSelector: #selector(UIApplication.my_requestSceneSessionDestruction(_:options:errorHandler:))
            )
        }
    }
}

//MARK: 低端机优化
public extension NewBootManager {
    /*
     是否是懒加载task
        -任务本身是可懒加载的
        -满足运行时lite条件
     */
    func isLazyTask(task: BootTask) -> Bool {
        if task.scope.isEmpty { //如果么有传scope，scope不作为判断条件
            return task.isLazyTask && self.liteConfigEnable()
        } else {
            return task.isLazyTask && self.liteEnable(task: task)
        }
    }
    
    /*
     运行时lite是否可用,同时满足如下几个条件
        -task指定了scope
        -task的scope和首tab的scope不对应
        -快速登录
        -launcher.context.isFastLogin
        -低端机
        -fg开启
     */
    func liteEnable(task: BootTask) -> Bool {
        //首tab不match
        var notMatchFistTabScope = false
        if !task.scope.isEmpty, let contextScope = task.launcher?.context.scope, !contextScope.isEmpty, contextScope.isDisjoint(with: task.scope) {
            notMatchFistTabScope = true
        }
        //登录之后的flow
        var isAfterLoginFlow = false
        if let flowType = task.flow?.flowType {
            isAfterLoginFlow = (flowType == .afterLoginFlow || flowType == .runloopIdle || flowType == .cpuIdle)
        }
        //快速登录
        var isFastLogin = false
        if let isFastLogin_ = task.launcher?.context.isFastLogin {
            isFastLogin = isFastLogin_
        }
        //低端机&FG开启
        let liteConfigEnable = self.liteConfigEnable()
        //同时满足上述条件
        if notMatchFistTabScope, isAfterLoginFlow, liteConfigEnable, isFastLogin {
            return true
        }
        return false
    }
    
    //运行时lite总配置开关是否可用
    func liteConfigEnable() -> Bool {
        //机型是否满足
        var deviceEnable = false
        if let deviceScore = KVPublic.Common.deviceScore.value(), deviceScore > 0, deviceScore < PreloadSettingsManager.liteEnableDeviceScore() {
            deviceEnable = true
        }
        
        //fg是否开启
        let fgOpen = KVPublic.FG.coldStartLiteEnable.value()
        //是否命中实验
        var hitABTest: Bool = true
        if let abEnable = Tracker.experimentValue(key: "lark_lite_enable", shouldExposure: true) as? Int, abEnable == 0 {
            hitABTest = false
        }
        if fgOpen, deviceEnable, hitABTest {
            NewBootManager.logger.info("boot_liteConfigEnable: true")
            return true
        }
        return false
    }
    
    /*
     运行时lite 异步任务是否通过预加载框架触发
     需要同时满足：1.预加载功能开启，2.运行时lite功能开启，3.cpu优化功能开启
     */
    func dispatchByPreload() -> Bool {
        return PreloadMananger.shared.preloadEnable() && NewBootManager.shared.liteConfigEnable() && bootSchedulerByPreload
    }
    
    /*
       设置runloopDispatch通过预加载框架调度
     */
    func runloopDispatchByPreload() {
        //设置runloopTools是否开启CPU优化
        RunloopDispatcher.dispatchByPreload = self.dispatchByPreload()
    }
    
    ///执行layz Task
    @discardableResult
    func triggerLazyTask(taskId: String) -> Bool {
        let tasks = self.lazyTasks.filter { bootTask in
            bootTask.identify == taskId
        }
        if let lazyTask = tasks.first {
            lazyTask.run()
            return true
        } else {
            return false
        }
    }
    
    ///移除预加载启动任务
    func removePreloadTask(task: BootTask){
        //移除对应task
        if let index = self.preloadTasks.firstIndex(where: { bootTask in
            bootTask.identify == task.identify
        }), self.preloadTasks.count > index {
            self.preloadTasks.remove(at: index)
        }
    }
    
    /// 共享并发队列，启动外界可以注入Task
    func addConcurrentTask( _ task: @escaping () -> Void, preloadEnable: Bool = false) {
        if self.dispatchByPreload(), preloadEnable { //通过预加载框架调度
            PreloadMananger.shared.addTask(preloadName: "bootManager.addConcurrentTask", biz: .ClodStart, preloadType: .BootManagerConcurrent, hasFeedback: false, taskAction: task, stateCallBack: nil, scheduler: .concurrent)
        } else {
            self.scheduler.concurrentQueue.addOperation(task)
        }
    }

    /// 共享串行队列，启动外界可以注入Task
    func addSerialTask( _ task: @escaping () -> Void, preloadEnable: Bool = false) {
        if self.dispatchByPreload(), preloadEnable { //通过预加载框架调度
            PreloadMananger.shared.addTask(preloadName: "bootManager.addSerialTask", biz: .ClodStart, preloadType: .BootManagerAsync, hasFeedback: false, taskAction: task, stateCallBack: nil, scheduler: .async)
        } else {
            self.scheduler.serialQueue.async(execute: task)
        }
    }
}

//MARK: Account
public extension NewBootManager {
    /// 触发切租户
    func switchAccount(userID: String) {
        // 先清空代表登出，再登录上去, 另外可能存在switch UserID一致的情况, 也需要先清空
        self.context.currentUserID = nil
        self.context.currentUserID = userID
        self.context.isFastLogin = false
        self.context.isSwitchAccount = true
        self.context.hasFirstRender = false

        self.context.resetUser()
        self.connectedContexts.values.forEach({ (context) in
            context.resetUser()
            self.customBoot(flow: .afterSwitchFlow, context: context)
        })
    }

    /// 新切换租户逻辑
    /// FIXME: 目前看这个可能和上面的一起调用..
    func switchAccountV2(userID: String, isRollbackSwitchUser: Bool, isSessionFirstActive: Bool) {
        self.context.currentUserID = userID
        self.context.isFastLogin = false
        self.context.isSwitchAccount = true
        self.context.hasFirstRender = false
        self.context.isRollbackSwitchUser = isRollbackSwitchUser
        self.context.isSessionFirstActive = isSessionFirstActive

        self.context.resetUser()
        self.context.resetOnceUserScopeTasks()
        self.connectedContexts.values.forEach({ (context) in
            context.resetUser()
            self.customBoot(flow: .afterSwitchFlow, context: context)
        })
    }

    /// 跳转login页面
    func login(_ isRollback: Bool = false) {
        self.context.reset()
        self.context.isRollbackLogout = isRollback
        self.connectedContexts.values.forEach({ (context) in
            context.resetUser()
            self.customBoot(flow: .loginFlow, taskIdentify: "LoginTask", context: context)
        })
    }

    /// 跳转login页面
    func logoutAndLogin(isRollback: Bool = false) {
        self.context.reset()
        self.context.isRollbackLogout = isRollback
        self.connectedContexts.values.forEach({ (context) in
            context.resetUser()
            self.customBoot(flow: .logoutFlow, context: context)
        })
    }

    // login或者launchGuide流程后面会调用，改变当前的UserID
    func didLogin(userID: String, fastLogin: Bool) {
        self.context.isFastLogin = fastLogin
        self.context.currentUserID = userID
    }

    /// 跳转launch guide页面
    func launchGuide(_ isRollback: Bool = false) {
        self.context.reset()
        self.context.isRollbackLogout = isRollback
        self.connectedContexts.values.forEach({ (context) in
            context.resetUser()
            self.customBoot(flow: .launchGuideFlow, taskIdentify: "LaunchGuideTask", context: context)
        })
    }

    func resetOnceUserScopeTasks() {
        self.context.resetOnceUserScopeTasks()
    }
}

extension UIApplication {
    @objc
    @available(iOS 13.0, *)
    func my_requestSceneSessionDestruction(_ sceneSession: UISceneSession,
                                           options: UISceneDestructionRequestOptions?,
                                           errorHandler: ((Error) -> Void)?) {
        if let scene = sceneSession.scene {
            NewBootManager.shared.destructionWorkSpace(in: scene)
        }
        my_requestSceneSessionDestruction(sceneSession, options: options, errorHandler: errorHandler)
    }
}

private func swizzling(
    forClass: AnyClass,
    originalSelector: Selector,
    swizzledSelector: Selector) {
    guard let originalMethod = class_getInstanceMethod(forClass, originalSelector),
        let swizzledMethod = class_getInstanceMethod(forClass, swizzledSelector) else {
            return
    }
    if class_addMethod(
        forClass,
        originalSelector,
        method_getImplementation(swizzledMethod),
        method_getTypeEncoding(swizzledMethod)
        ) {
        class_replaceMethod(
            forClass,
            swizzledSelector,
            method_getImplementation(originalMethod),
            method_getTypeEncoding(originalMethod)
        )
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
}
