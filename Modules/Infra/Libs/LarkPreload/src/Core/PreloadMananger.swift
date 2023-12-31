//
//  PreloadMananger.swift
//  Lark
//
//  Created by huanglx on 2023/1/17.
//  Copyright © 2023 Bytedance.Inc. All rights reserved.
//

import Foundation
import ThreadSafeDataStructure
import LKCommonsLogging
import Heimdallr
import LKCommonsTracker

/*
 预加载管理器
    -预加载框架详细设计：https://bytedance.feishu.cn/wiki/B6UEw78TzixieTkyRm0chGiRn6b
 */
public class PreloadMananger {
    // 单例
    public static let shared = PreloadMananger()
    
    //清理缓存通知
    public static let clearCacheNotification: String = "clearCacheNotification"
    //用户级缓存通知
    public static let clearUserCacheNotification: String = "clearUserCacheNotification"
    
    public var needDelayTaskInLowDevice: [TaskIdentify]?

    public var needRemoveTaskInLowDevice: [TaskIdentify]?

    public var needDelayRunloopTaskInLowDevice: [String]?

    public var needRemoveRunloopTaskInLowDevice: [TaskIdentify]?

    // 生命周期只执行一次的Tasks
    var onceTasks: SafeSet<TaskIdentify> = SafeSet<TaskIdentify>([], synchronization: .semaphore)
    // user生命周期只执行一次的
    var onceUserScopeTasks: SafeSet<TaskIdentify> = SafeSet<TaskIdentify>([], synchronization: .semaphore)
    
    //预加载id的映射关系
    var preloadIdKVs: SafeDictionary<String, TaskIdentify> = [:] + .readWriteLock
    
    //日志
    private static var logger = Logger.log(PreloadMananger.self)
    
    //任务队列池
    let lock = NSLock()
    lazy var taskQueuePool: PreloadTaskQueuePool = {
        lock.lock()
        defer { lock.unlock() }
        var taskQueuePool = PreloadTaskQueuePool()
        //内置runloop触发器。
        taskQueuePool.registMomentTrigger(momentTrigger: PreloadRunLoopMonitor())
        return taskQueuePool
    }()
    
    // 任务调度队列
    lazy var scheduleQueue: DispatchQueue = {
        return DispatchQueue(label: "Lark.PreloadManager.scheduleQueue", qos: .utility)
    }()
    
    //注册任务队列
    lazy var registTaskQueue: DispatchQueue = {
        return DispatchQueue(label: "Lark.PreloadManager.registTaskQueue", qos: .utility)
    }()
    
    // 调度器，选择执行线程
    lazy var taskScheduler: PreloadScheduler = {
        let scheduler = PreloadScheduler()
        //注册动态降级监听
        scheduler.registerDynamicDowngrade()
        //注册核心场景监听
        CoreSceneMointor.registObserver(observe: scheduler)
        return scheduler
    }()
    
    init() {
        //监听回到后台
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground(_:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        //监听回到前台
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground(_:)), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        //内存压力监听通知
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(memoryPressureWarningAction(_:)),
                                               name: NSNotification.Name(rawValue: KHMDMemoryMonitorMemoryWarningNotificationName),
                                               object: nil)
    }
    
    //MARK: public业务接口
    /*
     添加任务,不同优先级任务放到不同的queue
     scope: 作用域，默认 .user ,切租户会清空待预加载的任务。
     PreloadName: 预处理名称
     hasFeedback: 是否有命中反馈,对于没有命中反馈的task，不会做优先级调整。默认是true
     scheduler: 调度线程，分主线程，子线程串行，多线程。默认主线程串行
     biz: 业务
     preloadType: 预加载类型
     lowDeviceEnable: 低端机是否允许执行
     diskCache: 是否磁盘缓存
     diskCacheId: 磁盘缓存id
     moment: 添加调度时机
     taskAction: 具体的任务。
     stateCallBack: 状态回调
     */
    @discardableResult
    public func addTask(
        preloadName: String,
        biz: PreloadBiz,
        preloadType: PreloadType,
        hasFeedback: Bool,
        taskAction: @escaping TaskAction,
        stateCallBack: TaskStateCallBack?,
        scope: TaskScope = .user,
        scheduler: Scheduler = .concurrent,
        moment: PreloadMoment = .none,
        lowDeviceEnable: Bool = true,
        diskCacheId: String? = nil,
        priority: PreloadPriority = .middle
    ) -> TaskIdentify {
        guard self.preloadEnable() else { return "" }
        let task = PreloadTask(scope: scope, taskAction: taskAction, scheduler: scheduler, biz: biz, preloadType: preloadType, stateCallBack: stateCallBack, preloadName: preloadName, preloadMoment: moment, lowDeviceEnable: lowDeviceEnable, diskCacheId: diskCacheId, hasFeedback: hasFeedback, priority: priority)
        //传入磁盘缓存id代表磁盘缓存
        if diskCacheId != nil {
            task.diskCache = true
        }
        //直接添加的任务，是常规类型
        task.taskType = .normalType
        self.taskQueuePool.enqueueByPriority(task: task)
        return task.identify
    }
    
    /*
    注册任务，需要业务方指定添加到调度队列时机，框架会在该时机添加到调度队列中。
    priority: 优先级，.hight 高优先级， .middle 中优先级（默认）, .low 低优先级。
    scope: 作用域，默认 .user ,切租户会清空待预加载的任务。
    PreloadName: 预处理名称
    scheduler: 调度线程，分主线程，子线程串行，多线程。
    biz: 业务
    lowDeviceEnable: 低端机是否允许执行
    diskCache: 是否磁盘缓存
    diskCacheId: 磁盘缓存id
    moment: 添加调度时机
    taskAction: 具体的任务。
    stateCallBack: 状态回调
     */
    public func registerTask(
        preloadName: String,
        preloadMoment: PreloadMoment,
        biz: PreloadBiz,
        preloadType: PreloadType,
        hasFeedback: Bool,
        taskAction: @escaping TaskAction,
        stateCallBack: TaskStateCallBack?,
        taskIdCallBack: TaskIdCallBack? = nil,
        scope: TaskScope = .user,
        runOnlyOnce: Bool = false,              //只执行一次
        runOnlyOnceInUserScope: Bool = false,   //user生命周期只执行一次
        scheduler: Scheduler = .concurrent,
        lowDeviceEnable: Bool = true,
        diskCacheId: String? = nil,
        priority: PreloadPriority = .middle
    ) {
        guard self.preloadEnable() else { return }
        self.registTaskQueue.async {
            //传递的参数比较多，延迟创建维护成本高，采用注册的时候就创建。
            let task = PreloadTask(scope: scope, taskAction: taskAction, scheduler: scheduler, biz: biz, preloadType: preloadType, stateCallBack: stateCallBack,preloadName: preloadName, preloadMoment: preloadMoment, lowDeviceEnable: lowDeviceEnable, diskCacheId: diskCacheId, hasFeedback: hasFeedback, priority: priority)
            if diskCacheId != nil {
                task.diskCache = true
            }
            task.runOnlyOnce = runOnlyOnce
            task.runOnlyOnceInUserScope = runOnlyOnceInUserScope
            //指定任务的类型和状态
            task.taskType = .registType
            if let taskIdCallBack = taskIdCallBack {
                taskIdCallBack(task.identify)
            }
            self.taskQueuePool.addRegisterTask(task: task)
        }
    }

    ///注册任务触发时机
    public func registMomentTrigger(momentTrigger: MomentTriggerDelegate) {
        guard self.preloadEnable() else { return }
        self.taskQueuePool.registMomentTrigger(momentTrigger: momentTrigger)
    }
    
    //取消任务-byId
    public func cancelTaskByTaskId(taskId: TaskIdentify) {
        guard self.preloadEnable() else { return }
        self.taskQueuePool.cancelTaskById(taskId: taskId)
    }
    
    //业务主动触发任务，用于兜底
    public func scheduleTaskById(taskId: TaskIdentify) {
        guard self.preloadEnable() else { return }
        self.taskQueuePool.scheduleTaskById(taskId: taskId)
    }
    
    //设置预处理id的映射，用于主动触发和取消场景,业务方使用时需保证key唯一。
    public func setPreloadIdKVs(preloadIdKey: String, preloadIdValue: String) {
        self.preloadIdKVs[preloadIdKey] = preloadIdValue
    }
    
    //获取预处理id
    public func getPreloadId(preloadIdKey: String) -> String? {
        return self.preloadIdKVs[preloadIdKey]
    }
    
    /*
     内存缓存预处理使用反馈
        taskId-预处理ID
        hitPreload-是否真实命中，因为有些预加载任务内部的逻辑是异步的，这个字段用来上报预加载任务执行完但是预加载内部任务失败的场景
     */
    public func preloadFeedback(taskId: TaskIdentify, hitPreload: Bool = true){
        guard self.preloadEnable() else { return }
        PreloadTracker.trackPreloadHit(preloadId: taskId, hitPreload: hitPreload)
    }

    /*
     磁盘缓存预处理反馈
        diskCacheId-磁盘缓存ID
        hitPreload-是否真实命中，因为有些预加载任务内部的逻辑是异步的，这个字段用来上报预加载任务执行完但是预加载内部任务失败的场景
     */
    public func feedbackForDiskCache(diskCacheId: String, preloadBiz: PreloadBiz, preloadType: PreloadType, hitPreload: Bool = true) {
        guard self.preloadEnable() else { return }
        PreloadTracker.trackPreloadHitForDiskCache(diskCacheId: diskCacheId, preloadBiz: preloadBiz, preloadType: preloadType, hitPreload: hitPreload)
    }
    
    ///是否使用新预加载框架 注：业务侧也框架测都需要一个开关，只有同时打开才走新预加载框架。
    public func preloadEnable() -> Bool {
        let preloadEnable = PreloadSettingsManager.enablePreload()
        //是否命中实验
        var hitABTest: Bool = true
        if let abEnable = Tracker.experimentValue(key: "lark_lite_enable", shouldExposure: true) as? Int, abEnable == 0 {
            hitABTest = false
        }
        //只有settings配的开关和AB同时命中才走新框架
        return preloadEnable && hitABTest
    }
    
    //切换租户
    public func switchAccount() {
        guard self.preloadEnable() else { return }
        //清空待处理任务
        self.taskQueuePool.cancelUserTask()
        
        //清理user生命周期执行一次的任务
        self.onceUserScopeTasks.removeAll()

        //清理user生命周期的埋点数据
        PreloadTracker.clearUserScopDate()
        
        //发送清理通知
        NotificationCenter.default.post(name: Notification.Name(PreloadMananger.clearUserCacheNotification), object: nil)
    }
    
    ///切换到后台时进行存盘逻辑
    @objc func applicationDidEnterBackground(_ notification: Notification) {
        if self.preloadEnable() {
            self.taskScheduler.applicationDidEnterBackground()
            DispatchQueue.global().async {
                PreloadTracker.storeToDisk()
                PreloadFeedbackAnalysis.applicationDidEnterBackground()
            }
        }
    }
    
    ///切换到前台
    @objc func applicationWillEnterForeground(_ notification: Notification) {
        if self.preloadEnable() {
            self.taskScheduler.applicationWillEnterForeground()
            PreloadFeedbackAnalysis.applicationDidEnterForeground()
        }
    }
    
    //监听内存压力
    @objc func memoryPressureWarningAction(_ noti: NSNotification) {
        let userInfo = noti.userInfo
        let memoryPressureTypeValue = userInfo?["type"] as? Int32
        //收到内存警告，清理所有处理结果
        if let memoryPressureTypeValue = memoryPressureTypeValue, memoryPressureTypeValue >= 8 {
            //发送清理通知
            NotificationCenter.default.post(name: Notification.Name(PreloadMananger.clearCacheNotification), object: nil)
        }
    }
}

