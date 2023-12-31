//
//  SequeuePreloader.swift
//  SpaceKit
//
//  Created by guotenghu on 2019/8/6.
//  
// 序列预加载通用
// 响应网络变化
// 响应用户登入登出

import Foundation
import SKFoundation
import LKCommonsTracker
import SKInfra
import RxRelay
import SpaceInterface

public struct Preload {
    public enum Err: Error {
        case currentNetCarrier
        case netUnReachable
        case other
        case cancel

        var shouldRetry: Bool {
            switch self {
            case .other:
                return false
            case .currentNetCarrier, .netUnReachable, .cancel:
                return true
            }
        }
    }
}

protocol PreloadTask: Hashable {
    var key: PreloadKey { get }
    var canUseCarrierNet: Bool { get }

    func currentPriority() -> PreloadPriority
    func getEnqueueTime() -> TimeInterval
    mutating func updatePriority(_ newPriority: PreloadPriority)
    mutating func updateEnqueueTime(_ enqueueTime: TimeInterval)
    mutating func cancel()
    mutating func start(complete: @escaping (Result<Any, Preload.Err>) -> Void)
}

extension PreloadTask {
    
    func canStartOnNet(_ netType: NetworkType) -> Bool {
        guard netType != .notReachable else {
            return false
        }
        if netType.isWifi() {
            return true
        } else if netType.isWwan() {
            return canUseCarrierNet
        } else {
            spaceAssertionFailure("unkonwn netType \(netType)")
            return false
        }
    }
}

final class SequeuePreloader<Task: PreloadTask> {
    enum State {
        case notRunning
        case running
        case paused
        case finished
    }
    enum SequeuePreloaderType {
        case common //常驻Preloader，用于运行时预加载
        case single //非常驻Preloader，用于确定任务预加载
    }

    init(logPrefix: String = "", preloadQueue: DispatchQueue, preloaderType: SequeuePreloaderType = .common) {
        self.preloadQueue = DispatchQueue(label: "preloadQueue.\(logPrefix).\(UUID())", target: preloadQueue)
        self.targetQueue = preloadQueue
        self.preloaderType = preloaderType
        self.logPrefix = "sequencePreloader " + logPrefix
        if self.isHtmlSeQueue() {
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(finishHtmlTask),
                                                   name: Notification.Name.Docs.preloadDocsHtmlFinished,
                                                   object: nil)
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(pauseHtmlTask),
                                                   name: Notification.Name.Docs.showingDocsViewController,
                                                   object: nil)
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(startHtmlTask),
                                                   name: Notification.Name.Docs.didHideDocsViewController,
                                                   object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(finishLoadJS(_:)), name: Notification.Name.Docs.preloadDocsFinished, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(startLoadJS(_:)), name: Notification.Name.Docs.preloadDocsStart, object: nil)
        }
    }
    public var preloaderType: SequeuePreloaderType
    public var completeBlock: (() -> Void)? //全部任务执行完毕
    private var isReadyJS = true
    private var isPause: Bool = false
    private let logPrefix: String
    private let preloadQueue: DispatchQueue
    private weak var targetQueue: DispatchQueue?
    private var state: State = .notRunning {
        didSet {
            DocsLogger.info("\(self.logPrefix) state change:\(state)", component: LogComponents.preload)
            expectOnQueue()
        }
    }
    private var waitingTaskSet = Set<Task>()
    private var waitingTasks = [Task]() {
        didSet {
            expectOnQueue()
            if oldValue.isEmpty, !waitingTasks.isEmpty, preloaderType == .common {
                start()
            }
        }
    }
    private var currentTask: Task?
    var netStatus: NetworkType = DocsNetStateMonitor.shared.accessType {
        didSet {
            if netStatus == .notReachable {
                pause()
            } else {
                guard preloaderType == .common  else { return }
                start()
            }
        }
    }
    
    func executeQueue() -> DispatchQueue {
        return self.targetQueue != nil ? self.targetQueue! : self.preloadQueue
    }

    func addTasks(_ tasks: [Task], inFront: Bool = false) {
        preloadQueue.async {
            // 筛选出不在队列里的任务
            let filtered = tasks.filter { !self.waitingTaskSet.contains($0) && $0 != self.currentTask }
            // 更新已经在队列中任务的优先级，取最高优先级
            if UserScopeNoChangeFG.GXY.docxPreloadTaskPriorityEnable {
                self.updateTaskInfo(tasks)
            }
            if inFront {
                self.waitingTasks.insert(contentsOf: filtered, at: 0)
            } else {
                self.waitingTasks.append(contentsOf: filtered)
            }
            self.waitingTaskSet = self.waitingTaskSet.union(filtered)
            DocsLogger.debug("\(self.logPrefix) taskCount:\(self.waitingTasks.count)", component: LogComponents.preload)
        }
    }
    
    private func updateTaskInfo(_ tasks: [Task]) {
        let filter = self.waitingTasks.filter { tasks.contains($0) && $0 != self.currentTask }
        for i in 0..<filter.count {
            var oldTask = filter[i]
            if let oriIndex = self.waitingTasks.firstIndex(of: oldTask),
                let index = tasks.firstIndex(of: oldTask) {
                self.waitingTasks[oriIndex].updateEnqueueTime(tasks[index].getEnqueueTime())
                if tasks[index].currentPriority().rawValue > self.waitingTasks[oriIndex].currentPriority().rawValue {
                    self.waitingTasks[oriIndex].updatePriority(tasks[index].currentPriority())
                }
            }
        }
    }

    func clear() {
        preloadQueue.async {
            self.pause()
            self.waitingTasks.removeAll()
            self.waitingTaskSet.removeAll()
            self.state = .finished
        }
    }
    
    func remove(task: Task, compareFrom: Bool = false) {
        preloadQueue.async {
            if compareFrom == false {
                self.waitingTasks = self.waitingTasks.filter {
                    $0 != task
                }
                self.waitingTaskSet = self.waitingTaskSet.filter {
                    $0 != task
                }
            } else {
                // 需要from也相同，才可以移除
                let filter = self.waitingTasks.filter { $0 == task && $0.key.fromSource == task.key.fromSource }
                self.waitingTasks = self.waitingTasks.filter { !filter.contains($0) }
                self.waitingTaskSet = self.waitingTaskSet.filter { !filter.contains($0) }
            }
        }
    }
    
    func currentTasksFinished() -> Bool {
        return state == .finished || state == .notRunning
    }

    //暴露启动任务接口
    func startWholeTask() {
        guard preloaderType == .single, self.state != .running else { return }
        DocsLogger.info("start single task: \(self.logPrefix)", component: LogComponents.preload)
        preloadQueue.async { [weak self] in
            guard let self = self, self.state != .running else { return }
            self.state = .running
            self.isPause = false
            self.loadNext()
        }
    }
    
    func pauseWholeTask() {
        guard preloaderType == .single, self.state == .running else { return }
        DocsLogger.info("pause single task: \(self.logPrefix)", component: LogComponents.preload)
        self.pause()
        self.isPause = true
    }
    
    private func canOpenPrioriy() -> Bool {
        guard UserScopeNoChangeFG.GXY.docxPreloadTaskPriorityEnable else {
            return false
            
        }
#if DEBUG
        return true
#else
        // 获取AB测试
        guard let abEnable = Tracker.experimentValue(key: "docs_preload_priority_enable_ios", shouldExposure: true) as? Int, abEnable == 1 else {
            if self.logPrefix == "sequencePreloader htmlNativePreload" {
                DocsLogger.info("priority ABtest disable ", component: LogComponents.preload)
            }
            return false
        }
        if self.logPrefix == "sequencePreloader htmlNativePreload" {
            DocsLogger.info("priority ABtest able ", component: LogComponents.preload)
        }
        return true
#endif
    }
    
    private func canOpenFILO() -> Bool {
#if DEBUG
        return true
#else
        // 获取AB测试,支持FILO的话，用加入队列时间做一次排序
        guard let abEnable = Tracker.experimentValue(key: "docs_preload_filo_enable_ios", shouldExposure: true) as? Int, abEnable == 1 else {
            if self.logPrefix == "sequencePreloader htmlNativePreload" {
                DocsLogger.info("FILO ABtest disable ", component: LogComponents.preload)
            }
            return false
        }
        if self.logPrefix == "sequencePreloader htmlNativePreload" {
            DocsLogger.info("FILO ABtest able ", component: LogComponents.preload)
        }
        return true
#endif
    }
    
    private func getNextTaskIndex() -> Int? {
        expectOnQueue()
        guard canOpenPrioriy() else {
            // 获取AB测试,支持FILO的话，用加入队列时间做做一次排序
            if canOpenFILO() {
                waitingTasks = waitingTasks.sorted(by: { $0.getEnqueueTime() > $1.getEnqueueTime() })
            }
            return waitingTasks.firstIndex {
                return $0.canStartOnNet(self.netStatus)
            }
        }
        
        // 获取AB测试,支持FILO的话，用加入队列时间做做一次排序
        if canOpenFILO() {
            waitingTasks = waitingTasks.sorted(by: { $0.getEnqueueTime() > $1.getEnqueueTime() })
        }
        // 根据任务优先级，获取下一个任务的index
        var index = waitingTasks.firstIndex {
            return $0.canStartOnNet(self.netStatus) && $0.currentPriority() == .high
        }
        if index == nil {
            index = waitingTasks.firstIndex {
                return $0.canStartOnNet(self.netStatus) && $0.currentPriority() == .middle
            }
            if index == nil {
                index = waitingTasks.firstIndex {
                    return $0.canStartOnNet(self.netStatus) && $0.currentPriority() == .low
                }
            }
        }
        return index
    }

    private func expectOnQueue() {
        #if DEBUG
        //dispatchPrecondition(condition: .onQueue(preloadQueue))
        #endif
    }

    private func start() {
        preloadQueue.async { [weak self] in
            guard let self = self, self.state != .running, self.isPause == false else { return }
            self.state = .running
            self.loadNext()
        }
    }

    private func loadNext() {
        guard self.isPause == false else { return }
        expectOnQueue()
        if currentTask == nil, !waitingTasks.isEmpty, let currentTaskIndex = getNextTaskIndex() {
            currentTask = waitingTasks.remove(at: currentTaskIndex)
            _ = currentTask.map {
                waitingTaskSet.remove($0)
            }
        } else if currentTask == nil {
            DocsLogger.info("\(self.logPrefix) allPreloadTask has finished", component: LogComponents.preload)
            state = .finished
            self.completeBlock?()
        }
        DocsLogger.info("\(self.logPrefix) currentTaskPriority:\(currentTask?.currentPriority().rawValue ?? nil)", component: LogComponents.preload)
        currentTask?.start(complete: { [weak self] (result) in
            guard let self = self else { return }
            self.preloadQueue.async {
                if case let .failure(error) = result, error.shouldRetry, self.state != .finished {
                    // 网络原因导致，重试
                    self.currentTask.map { self.addTasks([$0], inFront: true) }
                }
                self.currentTask = nil
                if case let .failure(error) = result {
                    guard error != .cancel else { return }
                }
                self.loadNext()
            }
        })
    }

    private func pause() {
        preloadQueue.async { [weak self] in
            guard let self = self else { return }
            self.state = .paused
            self.currentTask?.cancel()
            DocsLogger.info("\(self.logPrefix) pause Sequeue", component: LogComponents.preload)
        }
    }

    ///html直出需要等到web告诉客户端直出完成，所以这里使用抛通知出来
    ///task暴露了didFinish给sequeue
    @objc
    private func finishHtmlTask(_ notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: String] else { return }
        guard let token = userInfo["token"]else { return }
        preloadQueue.asyncAfter(deadline: DispatchTime.now() + 2) {
            if self.currentTask is PreloadHtmlTask {
                let task = self.currentTask as? PreloadHtmlTask
                if task?.key.objToken == token {
                    task?.didFinish()
                }
            }
        }
    }

    // Doc1.0
    @objc
    private func pauseHtmlTask() {
        DocsLogger.info("pauseHtmlTask, receive pause notificaton", component: LogComponents.preload)
        guard self.isHtmlSeQueue() == true else { return }
        self.pause()
        self.isPause = true

        DocsLogger.info("pauseHtmlTask", component: LogComponents.preload)
    }

    // Doc1.0
    @objc
    private func startHtmlTask() {
        DocsLogger.info("startHtmlTask, receive start notificaton", component: LogComponents.preload)
        guard self.isHtmlSeQueue() == true else { return }
        self.isPause = false
        guard self.isReadyJS == true else { return }
        guard preloaderType == .common else { return }
        self.start()
        DocsLogger.info("startHtmlTask", component: LogComponents.preload)
    }

    @objc
    private func startLoadJS(_ notification: Notification) {
        DocsLogger.info("receive startLoadJS notificaton", component: LogComponents.preload)
        self.isReadyJS = false
    }

    @objc
    private func finishLoadJS(_ notification: Notification) {
        DocsLogger.info("receive finishLoadJS notificaton", component: LogComponents.preload)
        if !(DocsContainer.shared.resolve(SKBrowserInterface.self)?.browsersStackIsEmptyObsevable ?? BehaviorRelay<Bool>(value: true)).value {
            self.isReadyJS = true
        }
    }

    private func isHtmlSeQueue() -> Bool { return self.logPrefix.contains("htmlPreload") }
}
