//
//  OPTask.swift
//  OPSDK
//
//  Created by yinyuan on 2020/11/10.
//

import Foundation
import LarkOPInterface
import LKCommonsLogging

fileprivate let logger = Logger.oplog(OPTask.self, category: "OPTask")

/// 任务状态
public enum OPTaskState {
    
    // 任务等待开始
    case pending
    
    // 任务已开始正在执行
    case executing
    
    // 终止态：任务执行完成，结果：成功
    case succeeded
    // 终止态：任务执行完成，结果：失败
    case failed
    // 终止态：任务已取消
    case cancelled
    // 终止态：任务已超时
    case timeout
    
}

/// 任务输入，应当在开始运行前被设置为合适的内容
open class OPTaskInput {
    
    public init() {
        
    }
}

/// 任务输出，应当在被依赖的任务开始执行前设置未合适的内容
open class OPTaskOutput {
    
    public init() {
        
    }
}


/// 抽象任务，支持任务依赖关系设置
public protocol OPTaskProtocol {

    var taskID: String { get }
    
    /// 用于标识任务，会打印在日志、埋点中
    var name: String { get set}
    
    /// 超时时间
    var timeout: TimeInterval { get set }

    /// 状态
    var state: OPTaskState { get }

    /// 进度
    var progress: Progress { get }

//    /// 任务执行统计数据
//    var metrics: OPTaskMetrics? { get }

    /// 任务开始执行通知
    var taskDidStartedBlock: ((_ task: OPTaskProtocol) -> Void)? { get set}
    
    /// 任务进度更新通知
    var taskDidProgressChangeBlock: ((_ task: OPTaskProtocol, _ progress: Progress) -> Void)? { get set}
    
    /// 任务结束执行通知
    var taskDidFinshedBlock: ((_ task: OPTaskProtocol, _ state: OPTaskState,_ error: OPError?) -> Void)? { get set}

    /// 启动任务，重复调用无效（会自动递归启动依赖任务）
    func start()

    /// 取消任务，会自动递归取消依赖任务
    func cancel(monitorCode: OPMonitorCode)

    /// 任务是否已经结束
    func isFinished() -> Bool

    /// 添加依赖任务
    func addDependencyTask(dependencyTask: OPTaskProtocol) -> Bool
}

open class OPBaseTask {
    
    open var name: String = "OPBaseTask"
    
    /// 超时时间，默认60s
    public var timeout: TimeInterval = 60
    
    public let progress: Progress = Progress(totalUnitCount: 100)
    
    public var state: OPTaskState = .pending
    
    public var taskDidStartedBlock: ((_ task: OPTaskProtocol) -> Void)?
    
    public var taskDidProgressChangeBlock: ((_ task: OPTaskProtocol, _ progress: Progress) -> Void)?
    
    public var taskDidFinshedBlock: ((_ task: OPTaskProtocol, _ state: OPTaskState,_ error: OPError?) -> Void)?
    
    
    // MARK: - 私有属性
    private var completionBlock: ((_ task: OPTaskProtocol, _ error: OPError?) -> Void)?
    
    private var dependencyTasks: [OPTaskProtocol]
    
    /// 是否已经调用过 start 启动任务（内部状态不对外）
    private var started: Bool = false
    
    private static let taskIDIndexSemaphore = DispatchSemaphore(value: 1)
    private static var taskIDIndex = 0
    
    public let taskID: String

    /// 对metrics赋值时上锁，避免多线程操作引起的不一致
    private let taskLock = DispatchSemaphore(value: 1)
    
    public init(dependencyTasks: [OPTaskProtocol]) {
        logger.info("init")
        self.dependencyTasks = dependencyTasks
        
        // 创建唯一ID
        Self.taskIDIndexSemaphore.wait();
        let iTaskID = Self.taskIDIndex
        Self.taskIDIndex += 1;
        Self.taskIDIndexSemaphore.signal()
        
        taskID = String(iTaskID)
    }
    
    /// 任务即将启动，返回值决定是否准备工作正常
    open func taskWillStart() -> OPError? {
        logger.info("taskWillStart. task:\(name)")
        // 此处进行一些任务启动前的准备工作
        return nil
    }
    
    open func taskDidStarted(dependencyTasks: [OPTaskProtocol]) {
        logger.info("taskDidStarted. task:\(name)")
        guard state == .pending else {
            // 任务不能重复开始
            logger.warn("taskDidStarted state is pending already. task:\(name)")
            return
        }
        
        // 开始超时计时
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) { [weak self] in
            self?.taskDidTimeout()
        }
        
        progress.completedUnitCount = 5
        state = .executing
        taskDidStartedBlock?(self)
    }
    
    open func taskDidSucceeded() {
        logger.info("taskDidSucceeded. task:\(name)")
        guard !isFinished() else {
            // 终止态不能再取消
            logger.warn("taskDidStarted state is finished already. task:\(name)")
            return
        }
        // 更新进度
        progress.completedUnitCount = progress.totalUnitCount
        state = .succeeded
        taskDidFinished(error: nil)
    }
    
    open func taskDidFailed(error: OPError) {
        logger.error("taskDidFailed. task:\(name)", tag: "", additionalData: nil, error: error)
        guard !isFinished() else {
            // 终止态不能再取消
            logger.warn("taskDidStarted state is finished already. task:\(name)")
            return
        }
        // 错误状态不用更新进度
        state = .failed
        taskDidFinished(error: error)
    }
    
    open func taskDidCancelled(error: OPError) {
        logger.warn("taskDidCancelled. task:\(name)", tag: "", additionalData: nil, error: error)
        guard !isFinished() else {
            // 终止态不能再取消
            logger.warn("taskDidCancelled state is finished already. task:\(name)")
            return
        }
        // 取消状态不用更新进度
        state = .cancelled
        taskDidFinished(error: error)
    }
    
    open func taskDidTimeout(error: OPError? = nil) {
        logger.warn("taskDidTimeout. task:\(name)", tag: "", additionalData: nil, error: error)
        guard !isFinished() else {
            // 终止态不能再取消
            logger.warn("taskDidTimeout state is finished already. task:\(name)")
            return
        }
        // 超时状态不用更新进度
        state = .timeout
        taskDidFinished(error: error ?? OPError.error(monitorCode: OPSDKMonitorCode.timeout, userInfo: ["task_name": name]))
    }
    
    open func taskDidFinished(error: OPError?) {
        logger.warn("taskDidFinished. task:\(name)", tag: "", additionalData: nil, error: error)
        
        taskDidFinshedBlock?(self, state, error)
        completionBlock?(self, error)
    }
}

// MARK: - OPTaskProtocol接口实现
extension OPBaseTask: OPTaskProtocol {
    
    public func start() {
        logger.info("start. task:\(name)")
        // start 只允许调用一次
        guard !started else {
            logger.warn("start has been called. task:\(name)")
            return
        }
        started = true
        
        if let error = taskWillStart() {
            logger.error("taskWillStart error. task:\(name)")
            taskDidFailed(error: error)
            return
        }
        
        // 只有未启动的应用可以启动
        guard state == .pending else {
            logger.warn("taskDidStarted state is pending already. task:\(name)")
            return
        }
        
        let dependencyTasks = self.dependencyTasks
        
        /// 计算依赖任务进度总量
        var totolDependencyTasksProgress: Int64 = 0
        dependencyTasks.forEach { (task) in
            totolDependencyTasksProgress += task.progress.totalUnitCount
        }
        
        dependencyTasks.forEach { (task) in
            guard let baseTask = task as? OPBaseTask else {
                logger.warn("task is not OPBaseTask. task:\(name)")
                return
            }
            baseTask.completionBlock = { [weak self] (task, error) in
                guard let self = self else {
                    logger.warn("self released")
                    return
                }
                if task.state == .succeeded {
                    logger.info("task succeeded. \(task.name)")
                    let dependencyTasks = self.dependencyTasks
                    let finishedTasks = dependencyTasks.filter { (task) -> Bool in
                        task.isFinished()
                    }
                    if finishedTasks.count == dependencyTasks.count {
                        // 所有依赖任务已全部执行完成
                        self.taskDidStarted(dependencyTasks: dependencyTasks)
                    }
                } else {
                    var tError: OPError
                    if let error = error {
                        tError = error
                    } else {
                        tError = OPError.error(monitorCode: OPSDKMonitorCode.unknown_error, userInfo: ["task_name": self.name])
                    }
                    
                    logger.error("task error. \(task.name)", tag: "", additionalData: nil, error: tError)
                    
                    if task.state == .cancelled {
                        self.taskDidCancelled(error: tError)
                    } else if task.state == .failed {
                        self.taskDidFailed(error: tError)
                    } else if task.state == .timeout {
                        self.taskDidTimeout(error: tError)
                    } else {
                        self.taskDidFailed(error: tError)
                        OPAssertionFailureWithLog("completion block state wrong")
                    }
                }
            }
            
            // 设置子进度关系
            self.progress.addChild(task.progress, withPendingUnitCount: task.progress.totalUnitCount / totolDependencyTasksProgress * self.progress.totalUnitCount)
        }
        
        if dependencyTasks.count > 0 {
            // 有依赖项，先启动依赖项，待依赖任务全部执行完成后再启动
            dependencyTasks.forEach { (task) in
                task.start()
            }
        } else {
            // 没有依赖项，则直接启动
            logger.info("start with no dependencies. task:\(name)")
            taskDidStarted(dependencyTasks: dependencyTasks)
        }
    }
    
    public func cancel(monitorCode: OPMonitorCode) {
        logger.info("cancel. task:\(name)")
        guard !isFinished() else {
            logger.warn("cancel state is finished already. task:\(name)")
            return
        }
        
        // 先取消本任务
        taskDidCancelled(error: OPError.error(monitorCode: monitorCode, userInfo: ["task_name": name]))
        
        // 再递归取消所有依赖任务
        let dependencyTasks = self.dependencyTasks
        dependencyTasks.forEach { (task) in
            task.cancel(monitorCode: monitorCode)
        }
    }
    
    public func isFinished() -> Bool {
        return state != .pending && state != .executing
    }
    
    public func addDependencyTask(dependencyTask: OPTaskProtocol) -> Bool {
        guard state == .pending else {
            // 已启动的任务不再允许添加依赖任务
            logger.warn("can not addDependencyTask after taskt started. task:\(name)")
            return false
        }
        dependencyTasks.append(dependencyTask)
        return true
    }
}

open class OPTask<TaskInput: OPTaskInput, TaskOutput: OPTaskOutput>: OPBaseTask {
    
    public var input: TaskInput?
    
    public var output: TaskOutput?
}
