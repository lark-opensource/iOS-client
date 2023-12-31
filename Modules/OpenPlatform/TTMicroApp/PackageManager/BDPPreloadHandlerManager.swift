//
//  BDPPreloadHandlerManager.swift
//  EEMicroAppSDK
//
//  Created by Nicholas Tau on 2022/8/1.
//

import Foundation
import LKCommonsLogging
import OPFoundation
import ECOProbe
import OPSDK

/// 拦截器block
public typealias BDPPreHandleInterceptor = ((BDPPreloadHandleInfo) -> BDPInterceptorResponse)

///预加载任务生产模型的场景来源
public final class BDPPreloadScene: Equatable {
    public let priority: Int
    public let sceneName: String

    public init(priority: Int, sceneName: String) {
        self.priority = priority
        self.sceneName = sceneName
    }

    public static func == (lhs: BDPPreloadScene, rhs: BDPPreloadScene) -> Bool {
        return lhs.sceneName == rhs.sceneName && lhs.priority == rhs.priority
    }
}

// 通用场景来源
public extension BDPPreloadScene {
    /// 应用启动
    static let AppLaunch = BDPPreloadScene(priority: 0, sceneName: "app_launch")
    /// 止血推送
    static let SilenceUpdatePush = BDPPreloadScene(priority: 1, sceneName: "silence_update_push")
    /// 预推
    static let PreloadPush = BDPPreloadScene(priority: 2, sceneName: "preload_push")
    /// 止血拉取
    static let SilenceUpdatePull = BDPPreloadScene(priority: 3, sceneName: "silence_update_pull")
    /// 预拉取
    static let PreloadPull = BDPPreloadScene(priority: 4, sceneName: "preload_pull")
    /// Meta过期拉取
    static let MetaExpired = BDPPreloadScene(priority: 5, sceneName: "meta_expired")
}

/// 任务生产模型的调度形式，由外部指定
public enum BDPPreloadScheduleType: Int {
    case directHandle = 0
    case toBeScheduled
}

/// 预加载任务执行阶段
public enum BDPScheduleTaskExecuteStep: Int {
    case prepare = 0
    case inject
    case meta
    case pkg
}

/// 预加载任务调度状态
public enum BDPScheduleTaskStatus: Int {
    case idle = 0
    case running
    case abort
}

/// 拦截类型 (用于埋点上报)
public enum BDPInterceptType: Int {
    // 其他错误
    case error = -1
    // 小程序包已经存在缓存
    case cached = 0
    // 网络不可用
    case networkUnavailable
    // 非wifi环境下,不在豁免白名单中,不允许更新
    case notWifiAllow
    // 超过一天下载总量
    case exceedMaxDownloadTimesOneDay
}

// 预安装拉取数据来源枚举
public enum BDPPrehandleDataSource: Int {
    case local = 0
    case sever = 1
    case settings = 2
}

/// 提供预安装重构后新增的一些实现
public protocol BDPPreloadHandleListener: AnyObject {
    //meta回调
    func onMetaResult(metaResult: OPBizMetaProtocol?, handleInfo: BDPPreloadHandleInfo, error: OPError?, success: Bool)
    //包回调
    func onPackageResult(success: Bool,  handleInfo: BDPPreloadHandleInfo, error: OPError?)
}

public protocol BDPPreloadHandleInjector: AnyObject {
    ///提供注入入口，允许业务接入方注入meta内容。提包管理实现写入以及拉包等行为
    func onInjectMeta(uniqueID: OPAppUniqueID, handleInfo: BDPPreloadHandleInfo) -> OPBizMetaProtocol?
    //截断器回调
    func onInjectInterceptor(scene: BDPPreloadScene,  handleInfo: BDPPreloadHandleInfo) -> [BDPPreHandleInterceptor]?
}

public extension BDPPreloadHandleListener {
    func onMetaResult(metaResult: OPBizMetaProtocol?, handleInfo: BDPPreloadHandleInfo, error: OPError?, success: Bool){}
    func onPackageResult(success: Bool,  handleInfo: BDPPreloadHandleInfo, error: OPError?) {}
}


public extension BDPPreloadHandleInjector {
    func onInjectMeta(uniqueID: OPAppUniqueID, handleInfo: BDPPreloadHandleInfo) -> OPBizMetaProtocol? {
        return nil
    }
    func onInjectInterceptor(scene: BDPPreloadScene,  handleInfo: BDPPreloadHandleInfo) -> [BDPPreHandleInterceptor]? {
        return nil
    }
}


//基础类型，处理遇预加载事务
public struct BDPPreloadHandleInfo {
    public let uniqueID: BDPUniqueID
    public let scene: BDPPreloadScene
//    let priority: UInt  //优先级，默认可为0。相同场景、调度形式下的任务判断完后
    public let scheduleType: BDPPreloadScheduleType
    public let extra: [String: Any]?
    public let listener: BDPPreloadHandleListener?
    public let injector: BDPPreloadHandleInjector?
    public fileprivate(set) var existedMeta: OPBizMetaProtocol? = nil
    public fileprivate(set) var remoteMeta: OPBizMetaProtocol? = nil
    public init(uniqueID: BDPUniqueID,
                scene: BDPPreloadScene,
                scheduleType: BDPPreloadScheduleType,
                extra: [String: Any]? = nil,
                listener: BDPPreloadHandleListener? = nil,
                injector: BDPPreloadHandleInjector? = nil) {
        self.uniqueID = uniqueID
        self.scene = scene
        self.scheduleType = scheduleType
        self.extra = extra
        self.listener = listener
        self.injector = injector
    }
    
    //判断是否属于同一个预加载任务的标识
    func identifier() -> String {
        return uniqueID.fullString + "_scheduleType:\(scheduleType)"
    }
}

/// 拦截器返回的数据模型
public struct BDPInterceptorResponse {
    /// 是否需要拦截
    public let intercepted: Bool
    /// 拦截类型
    public let interceptedType: BDPInterceptType?
    /// 拦截原因
    public let interceptedMsg: String?
    /// 保留参数
    public let customInfo: [String : Any]?

    public init(intercepted: Bool,
         interceptedType: BDPInterceptType? = nil,
         interceptedMsg: String? = nil,
         customInfo: [String : Any]? = nil) {
        self.intercepted = intercepted
        self.interceptedType = interceptedType
        self.interceptedMsg = interceptedMsg
        self.customInfo = customInfo
    }
}

/// 公开协议，提供API给预安装接入方调用
public protocol BDPPreloadHandlerManagerProtocol {
    /// 处理预安装的请求，并提供回调
    func handlePkgPreloadEvent(preloadInfoList: [BDPPreloadHandleInfo])
    /// 取消并清楚所有当前任务，在用户切换登录时需要执行该操作，切租户时有脏数据遗留
    func cancelAndCleanAllTasks()
}

//新增一个集合的扩展
//https://stackoverflow.com/questions/46519004/can-somebody-give-a-snippet-of-append-if-not-exists-method-in-swift-array
//只在列表中不存在时，往列表里新增 element，且返回（true/新增element）
//其他情况，返回 （false/已存在element的index）
fileprivate extension Array where Element ==  BDPPreloadHandleListener  {
    //warning inhibited
    @discardableResult
    mutating func appendIfNotContains(_ element: BDPPreloadHandleListener) -> (appended: Bool, memberAfterAppend: AnyObject) {
        if let matchedElement = first(where: { $0 === element }) {
            return (false, matchedElement)
        } else {
            append(element)
            return (true, element)
        }
    }
}

fileprivate extension Array where Element ==  BDPPreloadHandleInjector  {
    //warning inhibited
    @discardableResult
    mutating func appendIfNotContains(_ element: BDPPreloadHandleInjector) -> (appended: Bool, memberAfterAppend: AnyObject) {
        if let matchedElement = first(where: { $0 === element }) {
            return (false, matchedElement)
        } else {
            append(element)
            return (true, element)
        }
    }
}

class BDPPreloadInfoTask {
    //任务挂载的预处理信息
    //私有的 handleInfo，存储真正的预加载对象
    private var _handleInfo: BDPPreloadHandleInfo
    //computed property，读写都加锁。防止 replaceHanleInfo 时出现多线程问题（outlined release）
    fileprivate (set) var handleInfo: BDPPreloadHandleInfo {
        set {
            defer{
                handleInfoLock.unlock()
            }
            handleInfoLock.lock()
            self._handleInfo = newValue
        }
        get {
            defer{
                handleInfoLock.unlock()
            }
            handleInfoLock.lock()
            return self._handleInfo
        }
    }
    /// 任务执行状态
    private(set) var taskStatus: BDPScheduleTaskStatus = .idle
    
    private(set) var listeners: [BDPPreloadHandleListener] = []
    private(set) var injectors: [BDPPreloadHandleInjector] = []
    
    var queueIdentifier: String  {
        return "com.openplatform.preload.type_\(handleInfo.uniqueID.appType.rawValue).scheduleType.\(handleInfo.scheduleType)"
    }
    fileprivate var syncLock: DispatchSemaphore?
    
    private let handleInfoLock = NSLock()
    private let callbackLock = NSLock()
    private let statuesLock = NSLock()
    
    init(handleInfo: BDPPreloadHandleInfo) {
        self._handleInfo = handleInfo
    }
    
    func replaceHanleInfo(_ handleInfo: BDPPreloadHandleInfo) {
        self.handleInfo = handleInfo
    }
    
    func updateTaskStatus(status: BDPScheduleTaskStatus) {
        //状态不变时不需要锁来锁去
        if status == self.taskStatus {
            return
        }
        defer{
            statuesLock.unlock()
        }
        statuesLock.lock()
        self.taskStatus = status
    }
    //安全的向listenrs里添加监听的便携方法
    func appendListeners(_ listeners: [BDPPreloadHandleListener])  {
        defer{
            callbackLock.unlock()
        }
        callbackLock.lock()
        //appendIfNotContains 保证listener 在列表内唯一
        listeners.forEach{ self.listeners.appendIfNotContains($0)}
    }
    
    //安全的向listenrs里添加监听的便携方法
    func appendInjectors(_ injectors: [BDPPreloadHandleInjector])  {
        defer{
            callbackLock.unlock()
        }
        callbackLock.lock()
        //appendIfNotContains 保证 injector 在列表内唯一
        injectors.forEach{ self.injectors.appendIfNotContains($0)}
    }
    
    //便携方法，触发所有的监听操作
    func onAllMetaResult(metaResult: OPBizMetaProtocol?, handleInfo: BDPPreloadHandleInfo, error: OPError?, success: Bool){
        defer{
            callbackLock.unlock()
        }
        callbackLock.lock()
        listeners.forEach {
            $0.onMetaResult(metaResult: metaResult, handleInfo:handleInfo, error: error, success: success)
        }
    }
    //便携方法，触发所有的监听操作
    func onAllPackageResult(success: Bool, handleInfo: BDPPreloadHandleInfo, error: OPError?) {
        defer{
            callbackLock.unlock()
        }
        callbackLock.lock()
        listeners.forEach {
            $0.onPackageResult(success: success, handleInfo: handleInfo, error: error)
        }
    }
    
    func onInjectedInterceptResponse() -> BDPInterceptorResponse? {
        defer{
            callbackLock.unlock()
        }
        callbackLock.lock()
        for injector in injectors {
            // 获取拦截器数组
            guard let intercepters = injector.onInjectInterceptor(scene: handleInfo.scene, handleInfo: handleInfo) else {
                continue
            }

            // 遍历拦截器
            for intercepter in intercepters {
                let interceptResponse = intercepter(handleInfo)
                //需要被拦截，则将拦截响应返回
                if interceptResponse.intercepted {
                    return interceptResponse
                }
            }
        }
        return nil
    }
    
    func onInjectedMeta() -> OPBizMetaProtocol? {
        defer{
            callbackLock.unlock()
        }
        callbackLock.lock()
        for injector in injectors {
            //先尝试向调用方向询问是否有需要注入的meta
            if let meta = injector.onInjectMeta(uniqueID: handleInfo.uniqueID, handleInfo:handleInfo) {
                //只要找到一个需要注入的meta之后的就不需要查了，可以认为都是一样的
                return meta
            }
        }
        return nil
    }
    
    public func description() -> String {
        return
                """
        {
                taskStatus: \(self.taskStatus),
                queueIdentifier: \(self.queueIdentifier),
                handleInfo.uniqueID: \(self.handleInfo.uniqueID),
                handleInfo.scene: \(self.handleInfo.scene.sceneName),
                handleInfo.scheduleType: \(self.handleInfo.scheduleType),
                handleInfo.extra: \(String(describing: self.handleInfo.extra)),
        }
        """
    }
}

private var associateKey: Void?
fileprivate extension OperationQueue {
    var syncLock: DispatchSemaphore? {
        get {
            return objc_getAssociatedObject(self, &associateKey) as? DispatchSemaphore
        }
        set {
            objc_setAssociatedObject(self, &associateKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    class func operationWithName(_ name: String, concurrentCount: Int) -> OperationQueue {
        let operationQueue = OperationQueue()
        operationQueue.name = name
        operationQueue.maxConcurrentOperationCount = concurrentCount
        return operationQueue
    }
}

@objcMembers
public final class BDPPreloadHandlerManagerBridge : NSObject {
    //开放给Objc类的接口，桥接一下
    public class func cancelAndCleanAllTasks() {
        BDPPreloadHandlerManager.sharedInstance.cancelAndCleanAllTasks()
    }
    
    public class func injectorProvider(provider: OPAppMetaRemoteAccessor & OPAppMetaLocalAccessor, appType: OPAppType) {
        BDPPreloadHandlerManager.sharedInstance.injectProvider(provider: provider, appType: appType)
    }
}

fileprivate extension MetaInfoModule {
    //同步阻塞方法，不能在主线程调用。主要是为了保证线程数据安装
    func requestRemoteMetaSync(
        with context: MetaContext,
        shouldSaveMeta: Bool,
        success: ((AppMetaProtocol?, (() -> Void)?) -> Void)?,
        failure: ((OPError) -> Void)?
    ) {
        //如果FG关闭，恢复原逻辑
        if OPSDKFeatureGating.disablePrehandleConcurrnetFix() {
            self.requestRemoteMeta(with: context, shouldSaveMeta: shouldSaveMeta, success: success, failure: failure)
            return
        }
        //异步改成同步
        let semaphore = DispatchSemaphore(value: 0)
        var appMeta: AppMetaProtocol?
        var saveMetaBlock: (() -> Void)?
        var opError: OPError?
        requestRemoteMeta(with: context, shouldSaveMeta: shouldSaveMeta) {(metaProtocol, saveMetaHandler) in
            appMeta = metaProtocol
            saveMetaBlock = saveMetaHandler
            semaphore.signal()
        } failure: { (error) in
            opError = error
            semaphore.signal()
        }
        //等网络 meta 请求返回了，继续执行
        semaphore.wait()
        if let error = opError {
            failure?(error)
        } else {
            success?(appMeta, saveMetaBlock)
        }
    }
}

fileprivate extension OPAppMetaRemoteAccessor {
    //同步阻塞方法，不能在主线程调用。主要是为了保证线程数据安装
    func fetchRemoteMetaSync(with uniqueID: OPAppUniqueID, previewToken: String, progress: requestProgress?, completion: requestCompletion?) {
        //如果FG关闭，恢复原逻辑
        if OPSDKFeatureGating.disablePrehandleConcurrnetFix() {
            self.fetchRemoteMeta(with: uniqueID, previewToken: previewToken, progress: progress, completion: completion)
            return
        }
        var isSuccess: Bool = false
        var opMeta: OPBizMetaProtocol? = nil
        var opError: OPError? = nil
        let semaphore = DispatchSemaphore(value: 0)
        //异步改成同步
        self.fetchRemoteMeta(with: uniqueID, previewToken: previewToken, progress: progress) { (success, meta, error) in
            isSuccess = success
            opMeta = meta
            opError = error
            semaphore.signal()
        }
        //等网络 meta 请求返回了，继续执行
        semaphore.wait()
        completion?(isSuccess, opMeta, opError)

    }
}

typealias TaskListMap = [OPAppType: [BDPPreloadScheduleType: [BDPPreloadInfoTask]]]

@objcMembers
public final class BDPPreloadHandlerManager {
    private let logger = Logger.oplog(BDPPreloadHandlerManager.self, category: "BDPPreloadHandlerManager")
    //多线程锁，保证任务数据安全
    private let taskListMapLock = NSLock()
    //多线程锁，metaProvider安全
    private let metaProviderLock = NSLock()
    //metaProvider的缓存表
    private var commonMetaProviderMap: [OPAppType: (OPAppMetaRemoteAccessor & OPAppMetaLocalAccessor)] = [:]
    //应用类型不同独占任务调度Queue，不同的应用调度（schedule）类型使用不同的任务
    private(set) var taskListMap: TaskListMap = [:]
    //任务执行的线程queue
    private(set) var queuesMap: [String: OperationQueue] = [:]
    public static let sharedInstance = BDPPreloadHandlerManager()
    //当前任务执行在统一的线程池中，避免多线程的问题
    private let taskPrepareQueue = DispatchQueue(label: "com.lark.openplatform.preload.handler")
    /// 通过 handleInfo 找到需要调度的目标任务队列
    /// - Parameter taskInfoList: 需要添加到任务队列中的任务
    /// - Returns: 真正添加成功的任务（去重后的）
    private func insertTasks(taskInfoList: [BDPPreloadInfoTask]) -> [BDPPreloadInfoTask] {
        defer{
            taskListMapLock.unlock()
        }
        taskListMapLock.lock()
        var appendedTasks: [BDPPreloadInfoTask] = []
        for taskInfo in taskInfoList {
            let handleInfo = taskInfo.handleInfo
            var taskListMapWithScheduleType: [BDPPreloadScheduleType: [BDPPreloadInfoTask]] = taskListMap[handleInfo.uniqueID.appType] ?? [:]
            var taskList = taskListMapWithScheduleType[handleInfo.scheduleType] ?? []
            //先找出已经存在的相同的任务
            let existedSameTasks = taskList.filter{ $0.handleInfo.identifier() ==  taskInfo.handleInfo.identifier() }
            if taskInfo.taskStatus == .idle {
                let reorderTasksBlock = {
                    //新任务需要添加到任务队列中
                    //如果已存在的任务为空，才需要append task
                    //否则只进行优先级排序
                    if existedSameTasks.isEmpty {
                        taskList.append(taskInfo)
                        appendedTasks.append(taskInfo)
                    }
                    //任务根据（场景值）优先级排序，场景值越低的优先级越高
                    let sortedTaskList = taskList.sorted(by: { $0.handleInfo.scene.priority < $1.handleInfo.scene.priority })
                    //重新将Queue数据塞回到map里，以供复用
                    taskListMapWithScheduleType[handleInfo.scheduleType] = sortedTaskList
                    self.taskListMap[handleInfo.uniqueID.appType] = taskListMapWithScheduleType
                }

                //不需要重复添加task，跳过
                if !existedSameTasks.isEmpty {
                    logger.info("insertTasks existedSameTasks founded: \(existedSameTasks.count)")
                    //如果有相同的任务，将监听保留
                    existedSameTasks.forEach {
                        $0.appendListeners(taskInfo.listeners)
                    }
                    existedSameTasks.forEach {
                        $0.appendInjectors(taskInfo.injectors)
                    }
                    //比较一下已存在任务里的 handleInfo 任务优先级
                    existedSameTasks.forEach { existedTask in
                        //如果新增的优先级更高，需要把旧的替换
                        logger.info("insertTasks check if need replace: \(existedTask.description())")
                        if taskInfo.handleInfo.scene.priority < existedTask.handleInfo.scene.priority {
                            logger.info("insertTasks try to replace existedTask:\(existedTask.description()) with: taskInfo\(taskInfo.description())")
                            existedTask.replaceHanleInfo(taskInfo.handleInfo)
                            //(替换完之后需要优先级重排)
                            reorderTasksBlock()
                        }
                    }
                    logger.info("handle info repeated with: \(taskInfo.handleInfo)")
                    continue
                }
                reorderTasksBlock()
            } else {
                //任务应运行，不需要重复添加
                logger.info("task is running, skip it: \(taskInfo.handleInfo)")
                if !existedSameTasks.isEmpty {
                    //如果有相同的任务，将监听保留
                    existedSameTasks.forEach {
                        $0.appendListeners(taskInfo.listeners)
                    }
                    existedSameTasks.forEach {
                        $0.appendInjectors(taskInfo.injectors)
                    }
                    logger.info("handle info repeated with: \(taskInfo.handleInfo)")
                }
            }
        }
        return appendedTasks
    }

    //返回所有相同应用类型和场景下的任务数据
    private func tasksInSameAppTypeAndScheduleType(infoTask: BDPPreloadInfoTask) ->[BDPPreloadInfoTask]? {
        defer{
            taskListMapLock.unlock()
        }
        taskListMapLock.lock()
        if let taskListWithScheduleType = self.taskListMap[infoTask.handleInfo.uniqueID.appType] {
            return taskListWithScheduleType[infoTask.handleInfo.scheduleType]
        }
        return nil
    }

    fileprivate func injectProvider(provider: (OPAppMetaRemoteAccessor & OPAppMetaLocalAccessor), appType: OPAppType) {
        metaProviderLock.lock()
        defer{
            metaProviderLock.unlock()
        }
        logger.info("injectProvider provider:\(provider)  for appType:\(appType) successfully")
        self.commonMetaProviderMap[appType] = provider
    }
    
    private func metaProviderFor(appType: OPAppType) -> (OPAppMetaRemoteAccessor & OPAppMetaLocalAccessor)? {
        metaProviderLock.lock()
        defer{
            metaProviderLock.unlock()
        }
        let metaProvider: (OPAppMetaRemoteAccessor & OPAppMetaLocalAccessor)? = self.commonMetaProviderMap[appType]
        if let metaProvider = metaProvider {
            return metaProvider
        }
        logger.error("there's not sepicific provider appType:\(appType)")
        return nil
    }
    
    /// 根据task模型，返回任务应该处于的调度queue
    /// - Parameter taskInfo: 任务模型
    /// - Returns: OperationQueue
    func queueWithTask(taskInfo: BDPPreloadInfoTask) -> OperationQueue {
        if let queue = self.queuesMap[taskInfo.queueIdentifier] {
            return queue
        }
        //对应不同的调度类型创建不同的queue
        //（并发数限制和Android保持一致，最多为5）
        let operationQueue = taskInfo.handleInfo.scheduleType == .directHandle ? OperationQueue.operationWithName(taskInfo.queueIdentifier, concurrentCount: 5) : OperationQueue.operationWithName(taskInfo.queueIdentifier, concurrentCount: 1)
        //只对schedule类型的需要设置semaphore管控
        operationQueue.syncLock = taskInfo.handleInfo.scheduleType == .toBeScheduled ? DispatchSemaphore(value: 1) : nil
        //缓存一下, 避免重复创建
        self.queuesMap[taskInfo.queueIdentifier] = operationQueue
        return operationQueue
    }
    
    ///  返回当前任务所处在的任务模型队列里所有的任务
    /// - Parameter taskInfo:
    /// - Returns: 下一个需要执行的任务模型
    private func nextTask(taskInfo: BDPPreloadInfoTask) -> BDPPreloadInfoTask? {
        defer{
            taskListMapLock.unlock()
        }
        taskListMapLock.lock()
        //查询相同应用类型，相同调度类型的任务模型列表。没有返回空
        guard let taskListMapWithScheduleType: [BDPPreloadScheduleType: [BDPPreloadInfoTask]] = taskListMap[taskInfo.handleInfo.uniqueID.appType],
              !taskListMapWithScheduleType.isEmpty,
              let tasks = taskListMapWithScheduleType[taskInfo.handleInfo.scheduleType],
              !tasks.isEmpty else {
                  return nil
        }
        //如果有，返回队首的任务
        return tasks.first
    }
    
    private func gadgetMetaProvider() ->  MetaInfoModule? {
        metaProviderLock.lock()
        defer{
            metaProviderLock.unlock()
        }
        guard let metaProvider = BDPModuleManager(of: .gadget)
            .resolveModule(with: MetaInfoModuleProtocol.self) as? MetaInfoModule else {
            logger.error("has no meta module manager for gadget")
            OPAssertionFailureWithLog("has no meta module manager for gadget")
            return nil
        }
        return metaProvider
    }
    
    private func packageProviderFor(appType: OPAppType) -> BDPPackageModuleProtocol? {
        logger.info("packageProviderFor appType: \(appType)")
        guard let packageManager = BDPModuleManager(of: appType).resolveModule(with: BDPPackageModuleProtocol.self) as? BDPPackageModuleProtocol else {
            logger.error("has no pkg module manage for appType \(appType)")
            assertionFailure("has no pkg module manager for appType \(appType)")
            return nil
        }
        return packageManager
    }
    
    private func removeTasks(taskInfoList: [BDPPreloadInfoTask]) {
        defer{
            taskListMapLock.unlock()
        }
        taskListMapLock.lock()
        for taskInfo in taskInfoList {
            let handleInfo = taskInfo.handleInfo
            var taskListMapWithScheduleType: [BDPPreloadScheduleType: [BDPPreloadInfoTask]] = taskListMap[handleInfo.uniqueID.appType] ?? [:]
            var taskList = taskListMapWithScheduleType[handleInfo.scheduleType] ?? []
            //如果两者的identifier相同，表示为同一个任务
            taskList.removeAll{ $0.handleInfo.identifier() == taskInfo.handleInfo.identifier() && $0.taskStatus != .running }
            taskListMapWithScheduleType[handleInfo.scheduleType] = taskList
            taskListMap[handleInfo.uniqueID.appType] = taskListMapWithScheduleType
        }
    }

    //执行任务之前检查一下网络，如果当前网络不可用就挂起任务，供下次恢复
    private func shouldPendingAllTasks() -> Bool {
        return OPNetStatusHelperBridge.opNetStatus == OPNetStatusHelper.OPNetStatus.unavailable.rawValue
    }
    
    ///任务因为某种原因终止，需要从队列中移除，并且更新任务状态
    private func taskTerminated(_ task: BDPPreloadInfoTask, inStep:BDPScheduleTaskExecuteStep, error: OPError?, success: Bool, resultMonitor: OPMonitor?)  {
        logger.info("taskTerminated task:\(task.description()) inStep:\(inStep) hasError:\(error) success:\(success)")
        //上传埋点
        if success {
            resultMonitor?.setResultTypeSuccess()
        } else {
            resultMonitor?.setResultTypeFail().setError(error)
        }
        resultMonitor?.timing().flush()
        //修改任务状态
        task.updateTaskStatus(status: .abort)
        //将任务从任务列表里移除
        removeFromQueue(preloadInfo: task.handleInfo)
        //释放同步锁
        task.syncLock?.signal()
    }
    
    ///开始执行包下载的行为
    func startToPackageDownload(_ meta: OPBizMetaProtocol, taskInfo: BDPPreloadInfoTask, packageProvider: BDPPackageModuleProtocol, completeBlock:((Bool)->Void)? = nil) {
        //package 埋点
        OPMonitor(EPMClientOpenPlatformGadgetPrehandleCode.op_prehandle_package_download_start)
            .setUniqueID(taskInfo.handleInfo.uniqueID)
            .addCategoryValue("prehandle_scene", taskInfo.handleInfo.scene.sceneName)
            .flush()
        let eventMonitor = OPMonitor(EPMClientOpenPlatformGadgetPrehandleCode.op_prehandle_package_download_result)
            .enableThreadSafe()
            .setUniqueID(taskInfo.handleInfo.uniqueID)
            .addCategoryValue("prehandle_scene", taskInfo.handleInfo.scene.sceneName)
            .timing()
        //尝试将 OPBizMetaProtocol 转换为 AppMetaProtocol，因为构建流失包下载上下文需要 AppMetaProtocol
        var appMetaProtocol: AppMetaProtocol? = meta as? AppMetaProtocol
        if appMetaProtocol == nil {
            appMetaProtocol = (meta as? AppMetaAdapterProtocol)?.appMetaAdapter
        }
        guard let appMetaProtocol = appMetaProtocol else {
            let errorMessage = "appMetaProtocol convert failed with uniqueID:\(taskInfo.handleInfo.uniqueID)"
            self.logger.error(errorMessage)
            let opError = OPError.error(monitorCode: OPSDKMonitorCode.unknown_error, message:errorMessage)
            completeBlock?(false)
            self.taskTerminated(taskInfo, inStep: .pkg, error: opError, success: false, resultMonitor: eventMonitor)
            return
        }
        let tracing = BDPTracingManager.sharedInstance().getTracingBy(taskInfo.handleInfo.uniqueID) ?? BDPTracingManager.sharedInstance().generateTracing(by:taskInfo.handleInfo.uniqueID)
        //包类型只有block 是zip，其他都是pkg
        let pkgType: BDPPackageType = appMetaProtocol.uniqueID.appType == .block ? .zip : . pkg
        //构建packageContext，提供pacakgeProvider用于下载pkg
        let packageContext = BDPPackageContext(appMeta: appMetaProtocol,
                                               packageType: pkgType,
                                               packageName: nil,
                                               trace: tracing)
        // pkgCtx挂载预处理相关信息,后续存储到db时需要使用
        packageContext.prehandleSceneName = taskInfo.handleInfo.scene.sceneName
        packageContext.preUpdatePullType = taskInfo.handleInfo.extra?["PreUpdatePullType"] as? Int ?? -1

        //pkg下载完成的callback，不管成功失败都要 invoke onPackageResult 的回调
        let downloadCompletion: BDPPackageDownloaderCompletedBlock = { [eventMonitor] (error, _, reader) in
            eventMonitor
                .addCategoryValue("pkg_url", packageContext.urls.first?.absoluteString ?? "")
                .addCategoryValue("net_status", OPNetStatusHelperBridge.opNetStatus)
            if let streamReader = reader as? BDPPackageStreamingFileHandle {
                let fileSize = LSFileSystem.fileSize(path: streamReader.pkgPath)
                eventMonitor.addCategoryValue("pkg_size", fileSize)
            }
            guard error == nil , reader != nil else {
                let opError = error ?? OPSDKMonitorCode.unknown_error.error(message: "getRemotePackage failed")
                //执行任务里的包下载完成回调
                taskInfo.onAllPackageResult(success: false, handleInfo:taskInfo.handleInfo, error: opError)
                completeBlock?(false)
                self.taskTerminated(taskInfo, inStep: .pkg, error: opError, success: false, resultMonitor: eventMonitor)
                return
            }
            //执行任务里的包下载完成回调
            taskInfo.onAllPackageResult(success: true, handleInfo: taskInfo.handleInfo, error: nil)
            completeBlock?(true)
            self.taskTerminated(taskInfo, inStep: .pkg, error: nil, success: true, resultMonitor: eventMonitor)
        }
        //开始下载pkg
        packageProvider.predownloadPackage(with: packageContext,
                                           priority: OPAppLoaderStrategy.preload.packageDownloadPriority,
                                           begun: nil,
                                           progress: nil,
                                           completed: downloadCompletion)
    }
    
    private func processWithTaskInfo(_ taskInfo: BDPPreloadInfoTask) {
        //任务开始时，开启信号量等待
        taskInfo.syncLock?.wait()
        //meta埋点
        let intercepterMonitor = OPMonitor(EPMClientOpenPlatformGadgetPrehandleCode.op_prehandle_meta_hit)
            .enableThreadSafe()
            .setUniqueID(taskInfo.handleInfo.uniqueID)
            .addCategoryValue("prehandle_scene", taskInfo.handleInfo.scene.sceneName)
            .addCategoryValue("hit_type", "received")

        //所有操作开始之前，先过一遍拦截器，如有有需要拦截的内容，直接种终止当前任务的预下载流程
        if let interceptResponse = interceptResponse(taskInfo: taskInfo), interceptResponse.intercepted {
            intercepterMonitor.addCategoryValue("hit_type", "intercepted")
            if let interceptType = interceptResponse.interceptedType {
                intercepterMonitor.addCategoryValue("intercept_type", interceptType.rawValue).flush()
            }
            let opError = OPError.error(monitorCode: OPSDKMonitorCode.unknown_error, message:"task been intercepted intecepterType:\(String(describing: interceptResponse.interceptedType?.rawValue)) intecepterMsg:\(String(describing: interceptResponse.interceptedMsg))")
            self.taskTerminated(taskInfo, inStep: .pkg, error: opError, success: false , resultMonitor: nil)
            return
        }

        // 获取注入的meta
        let injectedMetaResult = injectedMeta(from: taskInfo)

        //上报不拦截时的埋点
        intercepterMonitor.flush()
        //检查一下是否有网络，没有网络也需要将任务挂起
        //每次任务处理前判断下网络条件，如果处于断网情况下需要终止调度。通过后续的handleEvent恢复任务
        if self.shouldPendingAllTasks() {
            //任务挂起
            OperationQueue.current?.isSuspended = true
            let opError = OPError.error(monitorCode: OPSDKMonitorCode.unknown_error, message:"task been termincated, because of network is unavailable")
            self.taskTerminated(taskInfo, inStep: .prepare, error: opError, success: false , resultMonitor: nil)
            return
        }
        
        //meta埋点
        OPMonitor(EPMClientOpenPlatformGadgetPrehandleCode.op_prehandle_meta_start)
            .setUniqueID(taskInfo.handleInfo.uniqueID)
            .addCategoryValue("prehandle_scene", taskInfo.handleInfo.scene.sceneName)
            .flush()
        let eventMonitor = OPMonitor(EPMClientOpenPlatformGadgetPrehandleCode.op_prehandle_meta_result)
            .enableThreadSafe()
            .setUniqueID(taskInfo.handleInfo.uniqueID)
            .addCategoryValue("prehandle_scene", taskInfo.handleInfo.scene.sceneName)
            .timing()
        guard let packageProvider = packageProviderFor(appType: taskInfo.handleInfo.uniqueID.appType) else {
            let message = "has no pkg module manager for uniqueID:\(taskInfo.handleInfo.uniqueID)"
            self.logger.error(message)
            OPAssertionFailureWithLog(message)
            let opError = OPError.error(monitorCode: OPSDKMonitorCode.unknown_error, message:message)
            self.taskTerminated(taskInfo, inStep: .pkg, error: opError, success: false, resultMonitor: eventMonitor)
            return
        }
        
        //更新任务状态
        taskInfo.updateTaskStatus(status: .running)
        func saveMetaThenStartToDownloadWith(_ meta: OPBizMetaProtocol,
                                             taskInfo: BDPPreloadInfoTask,
                                             metaProvider: (OPAppMetaRemoteAccessor & OPAppMetaLocalAccessor),
                                             packageProvider: BDPPackageModuleProtocol) {
            do {
                ///标记之前本地包的版本，block业务会用来判断是否有更新变化
                ///找不预安装前的本地meta信息，并不阻断流程，可以 try?
                if let localExistedMeta = try? metaProvider.getLocalMeta(with: taskInfo.handleInfo.uniqueID) {
                    taskInfo.handleInfo.existedMeta = localExistedMeta
                } else {
                    self.logger.info("localExistedMeta is not existed")
                }
                //挂载新的meta信息
                taskInfo.handleInfo.remoteMeta = meta
                //保存注入的meta，如果失败抛异常则需要回调 metaResult事件
                try metaProvider.saveMetaToLocal(with: taskInfo.handleInfo.uniqueID, meta: meta)
                //meta保存成功，回调 onMetaResult成功事件
                taskInfo.onAllMetaResult(metaResult: meta, handleInfo:taskInfo.handleInfo ,error: nil, success: true)
                //开始下包逻辑
                self.startToPackageDownload(meta, taskInfo: taskInfo, packageProvider: packageProvider)
            } catch  {
                let opError = error as? OPError ?? error.newOPError(monitorCode: OPSDKMonitorCode.unknown_error, message:"inject meta to local db failed")
                //执行任务里的metaResult事件，这里是失败了
                taskInfo.onAllMetaResult(metaResult: nil, handleInfo: taskInfo.handleInfo, error: opError, success: false)
                self.taskTerminated(taskInfo, inStep: .inject, error: opError, success: false, resultMonitor: eventMonitor)
                self.logger.error("saveMetaToLocal with error for uniqueID:\(taskInfo.handleInfo.uniqueID), error:\(error)")
            }
        }
        
        //如果有需要注入的 meta，先要在本地持久化保存一下
        if let meta = injectedMetaResult {
            //如果是小程序，先下包，成功之后再保存meta
            if taskInfo.handleInfo.uniqueID.appType == .gadget {
                guard let gadgetProvider = gadgetMetaProvider() else {
                    let message = "has no meta module manager for uniqueID:\(taskInfo.handleInfo.uniqueID)"
                    self.logger.error(message)
                    OPAssertionFailureWithLog(message)
                    let opError = OPError.error(monitorCode: OPSDKMonitorCode.unknown_error, message:message)
                    self.taskTerminated(taskInfo, inStep: .prepare, error: opError, success: false, resultMonitor: eventMonitor)
                    return
                }
                //meta注入成功，算success一次。开始下包前需要将 monitor flush
                eventMonitor.timing().setResultTypeSuccess().flush()
                //开始下包逻辑
                self.startToPackageDownload(meta, taskInfo: taskInfo, packageProvider: packageProvider) { isSuccess in
                    //下包成了，把注入的meta持久化
                    if isSuccess,
                       let gadgetMeta = meta as? GadgetMeta {
                        gadgetProvider.saveMeta(gadgetMeta)
                    }
                }
                return
            }
            guard let metaProvider = metaProviderFor(appType: taskInfo.handleInfo.uniqueID.appType) else {
                let message = "has no meta module manager for uniqueID:\(taskInfo.handleInfo.uniqueID)"
                self.logger.error(message)
                let opError = OPError.error(monitorCode: OPSDKMonitorCode.unknown_error, message:message)
                self.taskTerminated(taskInfo, inStep: .prepare, error: opError, success: false, resultMonitor: eventMonitor)
                return
            }
            //meta注入成功，算success一次。开始下包前需要将 monitor flush
            eventMonitor.timing().setResultTypeSuccess().flush()
            saveMetaThenStartToDownloadWith(meta,
                                            taskInfo: taskInfo,
                                            metaProvider: metaProvider,
                                            packageProvider: packageProvider)
        } else {
            //发起网络请求，不走inject操作的流程
            if taskInfo.handleInfo.uniqueID.appType == .gadget {
                //gadget的发起方式和别的不一样，需要特定的gadgetProvider
                let metaContext = MetaContext(uniqueID: taskInfo.handleInfo.uniqueID, token: nil)
                guard let gadgetMetaProvider =  gadgetMetaProvider() else {
                    let opError = OPSDKMonitorCode.unknown_error.error(message: "getRemoteMeta failed, gadgetMetaProvider is nil")
                    taskInfo.onAllMetaResult(metaResult: nil, handleInfo:taskInfo.handleInfo,  error: opError, success: false)
                    self.taskTerminated(taskInfo, inStep: .prepare, error: opError, success: false, resultMonitor: eventMonitor)
                    return
                }
                gadgetMetaProvider.requestRemoteMetaSync(with: metaContext, shouldSaveMeta: false) {(meta, saveMetaHandler) in
                    /// meta completed
                    guard let meta = meta as? OPBizMetaProtocol else {
                        let opError = OPSDKMonitorCode.unknown_error.error(message: "getRemoteMeta failed, meta is nil with uniqueID:\(taskInfo.handleInfo.uniqueID)")
                        taskInfo.onAllMetaResult(metaResult: nil, handleInfo:taskInfo.handleInfo,  error: opError, success: false)
                        self.taskTerminated(taskInfo, inStep: .meta, error: opError, success: false, resultMonitor: eventMonitor)
                        return
                    }
                    //挂载新的meta信息
                    taskInfo.handleInfo.remoteMeta = meta
                    taskInfo.onAllMetaResult(metaResult: meta, handleInfo:taskInfo.handleInfo, error: nil, success: true)
                    //meta 请求成功，算success一次。开始下包前需要将 monitor flush
                    eventMonitor.timing().setResultTypeSuccess().flush()
                    //开始下包逻辑
                    self.startToPackageDownload(meta, taskInfo: taskInfo, packageProvider: packageProvider) { isSuccess in
                        if isSuccess {
                            saveMetaHandler?()
                        }
                    }
                } failure: { [eventMonitor] (error) in
                    /// meta error
                    let opError = error as? OPError ?? error.newOPError(monitorCode: OPSDKMonitorCode.unknown_error, message: "meta request failed when preload")
                    taskInfo.onAllMetaResult(metaResult: nil, handleInfo:taskInfo.handleInfo, error: error, success: false)
                    self.taskTerminated(taskInfo, inStep: .meta, error:opError, success: false , resultMonitor: eventMonitor)
                }
            } else {
                guard let metaProvider = metaProviderFor(appType: taskInfo.handleInfo.uniqueID.appType) else {
                    let message = "has no meta module manager for uniqueID:\(taskInfo.handleInfo.uniqueID)"
                    self.logger.error(message)
                    let opError = OPError.error(monitorCode: OPSDKMonitorCode.unknown_error, message:message)
                    self.taskTerminated(taskInfo, inStep: .prepare, error: opError, success: false , resultMonitor: eventMonitor)
                    return
                }
                //统一类型的走 metaProvider 的fetchRemoteMeta方法
                metaProvider.fetchRemoteMetaSync(with: taskInfo.handleInfo.uniqueID,
                                             previewToken: "",
                                             progress: nil) { [eventMonitor] (success, meta, error) in
                    guard let meta = meta, success == true, error == nil else {
                        let opError = OPSDKMonitorCode.unknown_error.error(message: "getRemoteMeta failed with uniqueID:\(taskInfo.handleInfo.uniqueID)")
                        taskInfo.onAllMetaResult(metaResult: nil, handleInfo:taskInfo.handleInfo,  error: opError, success: false)
                        self.taskTerminated(taskInfo, inStep: .meta, error: opError , success: false , resultMonitor: eventMonitor)
                        return
                    }
                    //meta 请求成功，算success一次。开始下包前需要将 monitor flush
                    eventMonitor.timing().setResultTypeSuccess().flush()
                    //持久化meta后开始下载包
                    saveMetaThenStartToDownloadWith(meta,
                                                    taskInfo: taskInfo,
                                                    metaProvider: metaProvider,
                                                    packageProvider: packageProvider)
                }
            }
        }
    }

    private func addToQueue(preloadInfo: BDPPreloadHandleInfo) {
        if OPSDKFeatureGating.prehandleUnitTestCodeEnable() {
            let _ = insertTasksV2(taskInfoList: [BDPPreloadInfoTask(handleInfo: preloadInfo)])
        } else {
            let _ = insertTasks(taskInfoList: [BDPPreloadInfoTask(handleInfo: preloadInfo)])
        }
    }

    private func removeFromQueue(preloadInfo: BDPPreloadHandleInfo) {
        if OPSDKFeatureGating.prehandleUnitTestCodeEnable() {
            removeTasksV2(taskInfoList: [BDPPreloadInfoTask(handleInfo: preloadInfo)])
        } else {
            removeTasks(taskInfoList: [BDPPreloadInfoTask(handleInfo: preloadInfo)])
        }
    }
}

extension BDPPreloadHandlerManager: BDPPreloadHandlerManagerProtocol {
    /// 处理预安装的事件请求
    /// - Parameters:
    ///   - preloadInfoList: 需要处理的预安装元数据类型
    public func handlePkgPreloadEvent(preloadInfoList: [BDPPreloadHandleInfo]) {
        //先任务生产队列，将任务转换为消费模型，然后逐个执行
        taskPrepareQueue.async {
            let taskList: [BDPPreloadInfoTask] = preloadInfoList.compactMap {
                let infoTask = BDPPreloadInfoTask(handleInfo: $0)
                if let eventListener = $0.listener {
                    infoTask.appendListeners([eventListener])
                }
                if let injector = $0.injector {
                    infoTask.appendInjectors([injector])
                }
                return infoTask
            }
            //添加任务数据，并且根据场景值排序就行了
            let appendedTasks = self.insertTasks(taskInfoList: taskList)
            appendedTasks.forEach {
                self.logger.info("handlePkgPreloadEvent appended task:\($0.description())")
            }
            //如果插入的任务大于0，则该类型的任务重新排序过，需要先变动过的任务operation所有任务中止，重新开始调度
            for task in appendedTasks {
                let taskQueue = self.queueWithTask(taskInfo: task)
                //因为优先级调整需要重新添加，挂起队列
                taskQueue.isSuspended = true
                //取消之前所有的待办操作
                taskQueue.cancelAllOperations()
            }
            //任务添加完毕，开始逐一调度任务
            for task in appendedTasks {
                let taskQueue = self.queueWithTask(taskInfo: task)
                if taskQueue.isSuspended {
                    //重新恢复这个任务类型在队列中的所有待办任务
                    let tasksSuspended = self.tasksInSameAppTypeAndScheduleType(infoTask: task)
                    if let tasksSuspended = tasksSuspended {
                        tasksSuspended.forEach { taskSuspended in
                            //所有在同一个任务队列中的任务，共用一个信号量
                            taskSuspended.syncLock = taskQueue.syncLock
                            //初始化一下状态量
                            taskSuspended.updateTaskStatus(status: .idle)
                            taskQueue.addOperation{ self.processWithTaskInfo(taskSuspended) }
                            self.logger.info("handlePkgPreloadEvent suspended task:\(taskSuspended.description())")
                        }
                    } else {
                        self.logger.info("tasksSuspended is nil, no tasks to do")
                    }
                    //恢复任务
                    taskQueue.isSuspended = false
                } else {
                    //任务已经恢复，不需要再重复添加了
                    self.logger.info("taskQueue\(taskQueue) is not suspended any longer, just skip it")
                }
            }
        }
    }
    
    /// 清理所有任务
    public func cancelAndCleanAllTasks() {
        defer{
            taskListMapLock.unlock()
        }
        taskListMapLock.lock()
        if OPSDKFeatureGating.disablePrehandleQueueMapFix() {
            //先把operatin queue里所有的任务取消
            for (_, operationQueue) in self.queuesMap {
                operationQueue.cancelAllOperations()
            }
        } else {
            taskPrepareQueue.async {
                //先把operatin queue里所有的任务取消
                for (_, operationQueue) in self.queuesMap {
                    operationQueue.cancelAllOperations()
                }
            }
        }
        //清理所有任务列表里的数据
        taskListMap.removeAll()
    }
}

// MARK: 这边是单测改造后的代码, 待全量后会删除改造前的代码
extension BDPPreloadHandlerManager {
    /// 通过 handleInfo 找到需要调度的目标任务队列(V2版本是经过单测改造的)
    /// - Parameter taskInfoList: 需要添加到任务队列中的任务
    /// - Returns: 真正添加成功的任务（去重后的）
    func insertTasksV2(taskInfoList: [BDPPreloadInfoTask]) -> [BDPPreloadInfoTask] {
        defer{
            taskListMapLock.unlock()
        }
        taskListMapLock.lock()
        var appendedTasks: [BDPPreloadInfoTask] = []
        for taskInfo in taskInfoList {
            insertAndReorderTask(taskInfo: taskInfo, taskListMap: taskListMap) { taskInfo, needAppend, sortedTasks in
                if needAppend {
                    appendedTasks.append(taskInfo)
                }

                let handleInfo = taskInfo.handleInfo
                var taskListMapWithScheduleType: [BDPPreloadScheduleType: [BDPPreloadInfoTask]] = self.taskListMap[handleInfo.uniqueID.appType] ?? [:]
                taskListMapWithScheduleType[handleInfo.scheduleType] = sortedTasks
                self.taskListMap[handleInfo.uniqueID.appType] = taskListMapWithScheduleType
            }
        }
        return appendedTasks
    }

    /// 根据传入的Task对缓存taskListMap中相同类型的任务队列按照优先级排序
    /// 如果是重复任务则将task的listeners和injectors添加到已有的task中
    /// - Parameters:
    ///   - taskInfo: 预安装任务
    ///   - taskListMap: 当前缓存Map
    ///   - updateCallback: 更新缓存Map的callback. 回调当前task、是否需要添加和排序后的taskArray
    func insertAndReorderTask(taskInfo: BDPPreloadInfoTask,
                              taskListMap: TaskListMap,
                              updateCallback: @escaping (BDPPreloadInfoTask, Bool, [BDPPreloadInfoTask]) -> Void) {
        let handleInfo = taskInfo.handleInfo
        let taskListMapWithScheduleType: [BDPPreloadScheduleType: [BDPPreloadInfoTask]] = taskListMap[handleInfo.uniqueID.appType] ?? [:]
        var taskList = taskListMapWithScheduleType[handleInfo.scheduleType] ?? []
        //先找出已经存在的相同的任务
        let existedSameTasks = taskList.filter{ $0.handleInfo.identifier() ==  taskInfo.handleInfo.identifier() }

        //将taskInfo中的listeners和injectors添加到已缓存的task中
        taskListAddTaskListenersAndInjectors(taskList: existedSameTasks, taskInfo: taskInfo)

        // 非idle类型的任务, 则不添加到缓存中
        guard taskInfo.taskStatus == .idle else {
            logger.info("task is not idle, skip it: \(taskInfo.handleInfo)")
            return
        }

        // 处理idle状态的task
        logger.info("insertTasks existedSameTasks founded: \(existedSameTasks.count) taskInfo:\(taskInfo.handleInfo)")
        //比较一下已存在任务里的 handleInfo 任务优先级
        taskListReplaceLowPriorityTask(taskList: existedSameTasks, with: taskInfo)

        let needAppend = existedSameTasks.isEmpty
        if needAppend {
            taskList.append(taskInfo)
        }

        //任务根据（场景值）优先级排序，prioty越小的优先级越高
        let sortedTaskList = taskList.sorted(by: { $0.handleInfo.scene.priority < $1.handleInfo.scene.priority })
        //回调需要缓存的数据
        updateCallback(taskInfo, needAppend, sortedTaskList)
    }

    /// 用taskInfo中的handleInfo替换数组中优先级低的handleInfo
    func taskListReplaceLowPriorityTask(taskList: [BDPPreloadInfoTask],
                                        with taskInfo: BDPPreloadInfoTask) {
        guard !taskList.isEmpty else {
            return
        }

        taskList.forEach { existedTask in
            //如果新增的优先级更高，需要把旧的替换
            logger.info("insertTasks check if need replace: \(existedTask.description())")
            if taskInfo.handleInfo.scene.priority < existedTask.handleInfo.scene.priority {
                logger.info("insertTasks try to replace existedTask:\(existedTask.description()) with: taskInfo\(taskInfo.description())")
                existedTask.replaceHanleInfo(taskInfo.handleInfo)
            }
        }
    }

    /// 为数组中每一个task添加传入task的listeners和injectors
    func taskListAddTaskListenersAndInjectors(taskList: [BDPPreloadInfoTask], taskInfo: BDPPreloadInfoTask) {
        guard !taskList.isEmpty else {
            return
        }

        taskList.forEach {
            $0.appendListeners(taskInfo.listeners)
            $0.appendInjectors(taskInfo.injectors)
        }
    }

    /// 移除taskListMap中类型传入的tasks相同的任务(V2版本是经过单测改造的)
    func removeTasksV2(taskInfoList: [BDPPreloadInfoTask]) {
        defer{
            taskListMapLock.unlock()
        }
        taskListMapLock.lock()
        for taskInfo in taskInfoList {
            let handleInfo = taskInfo.handleInfo
            let removedScheduleTaskList = removeTask(taskInfo: taskInfo, in: taskListMap)
            taskListMap[handleInfo.uniqueID.appType] = removedScheduleTaskList
        }
    }

    /// 移除taskListMap中类型传入的taskInfo相同的任务
    /// - Parameters:
    ///   - taskInfo: 需要移除的taskInfo
    ///   - taskListMap: taskListMap
    /// - Returns: 移除类型与taskInfo相同任务后的BDPPreloadScheduleType表
    func removeTask(taskInfo: BDPPreloadInfoTask,
                    in taskListMap: TaskListMap) -> [BDPPreloadScheduleType: [BDPPreloadInfoTask]] {
        let handleInfo = taskInfo.handleInfo
        var taskListMapWithScheduleType: [BDPPreloadScheduleType: [BDPPreloadInfoTask]] = taskListMap[handleInfo.uniqueID.appType] ?? [:]
        var taskList = taskListMapWithScheduleType[handleInfo.scheduleType] ?? []
        //如果两者的identifier相同，表示为同一个任务
        taskList.removeAll{ $0.handleInfo.identifier() == taskInfo.handleInfo.identifier() && $0.taskStatus != .running }
        taskListMapWithScheduleType[handleInfo.scheduleType] = taskList
        return taskListMapWithScheduleType
    }

    /// 当taskInfo中有拦截器满足拦截逻辑时, 返回拦截响应对象
    func interceptResponse(taskInfo: BDPPreloadInfoTask) -> BDPInterceptorResponse? {
        if OPSDKFeatureGating.enableInjectorsProtection() {
            return taskInfo.onInjectedInterceptResponse()
        }
        for injector in taskInfo.injectors {
            // 获取拦截器数组
            guard let intercepters = injector.onInjectInterceptor(scene: taskInfo.handleInfo.scene, handleInfo: taskInfo.handleInfo) else {
                continue
            }

            // 遍历拦截器
            for intercepter in intercepters {
                let interceptResponse = intercepter(taskInfo.handleInfo)
                //需要被拦截，则将拦截响应返回
                if interceptResponse.intercepted {
                    return interceptResponse
                }
            }
        }
        return nil
    }

    /// 获取injector中注入的meta对象
    func injectedMeta(from taskInfo: BDPPreloadInfoTask) -> OPBizMetaProtocol? {
        if OPSDKFeatureGating.enableInjectorsProtection() {
            return taskInfo.onInjectedMeta()
        }
        for injector in taskInfo.injectors {
            //先尝试向调用方向询问是否有需要注入的meta
            if let meta = injector.onInjectMeta(uniqueID: taskInfo.handleInfo.uniqueID, handleInfo:taskInfo.handleInfo) {
                //只要找到一个需要注入的meta之后的就不需要查了，可以认为都是一样的
                return meta
            }
        }
        return nil
    }
}


