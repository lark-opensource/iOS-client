//
//  CacheManager.swift
//  LarkCache
//
//  Created by Supeng on 2020/8/11.
//

import UIKit
import Foundation
import LKCommonsLogging
import ThreadSafeDataStructure
import LKLoadable
import LarkStorage

/// Cache总体管理模块
public final class CacheManager: NSObject {
    static let logger = Logger.log(CacheManager.self, category: "LarkCache")
    /// 共享单例
    public internal(set) static var shared = CacheManager()

    /// 所有创建过的cache实例
    private var caches: [Int: Cache] = [:]
    /// 清理缓存全局配置
    private var cleanConfig: CleanConfig?
    /// 是否正在清理
    private var isCleaning = false
    /// 是否是用户触发清理
    private var isUserTriggered = false
    /// 后台任务标识
    private var backgroundTaskID: UIBackgroundTaskIdentifier?
    /// 埋点工具
    private var tracker = TaskCleanTracker()

    private let lock = NSLock()

    /// 执行队列
    private lazy var taskQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    /// 回调队列
    /// 由于使用 performAfter 作为 timeout 方案, 需要 runloop 支持 timer
    /// 且回调队列不会进行耗时的数据操作，可以再主线程执行
    private lazy var queue: OperationQueue = OperationQueue.main
    /// 进后台监听
    private var bgObserver: NSObjectProtocol?
    /// 进前台监听
    private var fgObserver: NSObjectProtocol?

    private var allTaskRegistry: [CleanTaskRegistry.TaskWrapper] {
        SwiftLoadable.startOnlyOnce(key: "LarkCache_CleanTaskRegistry_regist")
        return CleanTaskRegistry.allTasks
    }

    // MARK: 统一缓存

    /// 根据Biz，CacheDirectory返回Cache对象
    /// - Parameters:
    ///   - biz: cache所属业务模块
    ///   - directory: cache对象存储目录
    ///   - cleanIdentifier: 清理任务的ID
    /// - Returns: Cache对象
    public func cache(
        biz: Biz.Type,
        directory: CacheDirectory,
        cleanIdentifier: String? = nil
    ) -> Cache {
        cache(relativePath: biz.fullPath, directory: directory, cleanIdentifier: cleanIdentifier)
    }

    /// 返回 Cache 对象
    public func cache(rootPath: IsoPath, cleanIdentifier: String) -> Cache {
        lock.lock()
        defer { lock.unlock() }
        let homeDir = AbsPath.home.absoluteString
        let rawRootPath = rootPath.absoluteString
        if rawRootPath.hasPrefix(homeDir) && rawRootPath.count > homeDir.count {
            var fromIndex = rawRootPath.index(rawRootPath.startIndex, offsetBy: homeDir.count)
            if rawRootPath[fromIndex] == "/" {
                fromIndex = rawRootPath.index(after: fromIndex)
            }
            let relativeToHomeDir = String(rawRootPath.suffix(from: fromIndex))

            // 保存 path 与 cleanIdentifier 的映射
            KVStates.cachePathToCleanIdentifierMap[relativeToHomeDir] = cleanIdentifier
        }

        let config = Cache.Config(rootPath: rootPath, cleanIdentifier: cleanIdentifier)
        let hashValue = Cache.InnerConfig.new(config).hashValue()
        if let cache = caches[hashValue] {
            return cache
        }
        let cache = Cache(config: config)
        caches[hashValue] = cache

        return cache
    }

    /// 根据Biz，CacheDirectory返回Cache对象
    /// - Parameters:
    ///   - relativePath: 相对directory的路径
    ///   - directory: cache对象存储目录
    ///   - cleanIdentifier: 清理任务的ID
    /// - Returns: Cache对象
    public func cache(
        relativePath: String,
        directory: CacheDirectory,
        cleanIdentifier: String? = nil
    ) -> Cache {
        lock.lock()
        defer { lock.unlock() }

        // 如果外界传入cleanIdentifier，则该cache对应的cleanIdentifier为cleanIdentifier
        // 如果没有传入cleanIdentifier，则尝试在UserDefaults中查找relativeToSandBoxPath对应的cleanIdentifier
        // 如果在UserDefaults中依然没有cleanIdentifier，则默认该cache对应的cleanIdentifier为relativeToSandBoxPath
        let relativeToSandBoxPath = directory.dirName + "/" + relativePath
        let realCleanID = cleanIdentifier
            ?? KVStates.cachePathToCleanIdentifierMap[relativeToSandBoxPath]
            ?? relativeToSandBoxPath
        let config = CacheConfig(relativePath: relativePath,
                                 cacheDirectory: directory,
                                 cleanIdentifier: realCleanID)

        // 保存path于cleanIdentifier的映射
        KVStates.cachePathToCleanIdentifierMap[relativeToSandBoxPath] = config.cleanIdentifier

        let hashValue = Cache.InnerConfig.old(config).hashValue()
        if let cache = caches[hashValue] {
            return cache
        }
        let cache = Cache(config: config)
        caches[hashValue] = cache

        return cache
    }

    // MARK: 清理逻辑

    /// 是否支持自动清理缓存
    public var autoCleanEnable = true

    /// 一天内自动清理缓存最大次数，默认值为 5
    public var autoCleanMaxCount: UInt = 5

    /// 启动自动清理
    /// - Parameter cleanConfig: 自动清理配置
    public func autoClean(cleanConfig: CleanConfig) {
        CacheManager.logger.info("add auto clean config, \(cleanConfig)")

        self.cleanConfig = cleanConfig

        removeObserver()
        addObserver()
    }

    /// 立即清理
    /// - Parameters:
    ///   - config: 清理配置
    ///   - completion: 完成回调
    public func clean(config: CleanConfig, completion: (() -> Void)? = nil) {
        self.isCleaning = true
        self.isUserTriggered = config.isUserTriggered

        let taskCount = allTaskRegistry.count
        CacheManager.logger.info("start clean tasks, number \(taskCount), config \(config)")
        var count = 0
        self.tracker.start(taskCount: taskCount)
        allTaskRegistry.forEach { wrapper in
            self.taskQueue.addOperation { [weak self] in
                let task = wrapper.task()
                // Task状态：开始执行
                wrapper.status = .running
                let taskName = task.name
                CacheManager.logger.info("start clean task \(taskName)")

                DispatchQueue.global().async {
                    task.clean(config: config) { [weak self] result in
                        guard let self = self else { return }
                        self.taskQueue.addOperation { [weak self] in
                            guard let self = self, self.isCleaning else { return }
                            // Task状态：完成
                            wrapper.status = .initial
                            count += 1
                            self.tracker.record(result: result, forTask: taskName)
                            CacheManager.logger.info("clean task \(taskName) finished, result \(result)")
                            if count == taskCount {
                                // 所有任务执行完成：记录本次完成执行时间，结束后台任务，取消超时任务
                                self.queue.addOperation { [weak self] in
                                    self?.cancelTimeoutCallback()
                                }
                                // 所有任务结束后，通知全部 task
                                self.allTaskRegistry.forEach { wrapper in
                                    let task = wrapper.task()
                                    task.allCacheTaskDidCompleted()
                                }

                                self.isCleaning = false
                                self.isUserTriggered = false
                                KVStates.lastCleanTime = Date().timeIntervalSince1970
                                completion?()
                                self.tracker.complete()
                                CacheManager.logger.info("all clean task finished")
                                self.tryEndBackgroundTask(delay: 1)
                            }
                        }
                    }
                }
            }
        }
    }

    func cleanAll() {
        for cache in caches.values {
            cache.yyCache?.memoryCache.removeAllObjects()
            cache.yyCache?.diskCache.closeDB()
        }
    }

    func reinitAll() {
        for cache in caches.values {
            cache.yyCache?.diskCache.reinitialize()
        }
    }

    /// 返回当前缓存 size 大小
    /// - Parameters:
    ///   - config: 清理配置
    ///   - completion: 完成回调
    public func size(config: CleanConfig, completion: @escaping ([TaskResult.Size]) -> Void) {
        let taskCount = allTaskRegistry.count
        CacheManager.logger.info("start calculate tasks size, number \(taskCount), config \(config)")
        var count = 0
        let sizeResults: SafeArray<TaskResult.Size> = [] + .semaphore

        allTaskRegistry.forEach { wrapper in
            self.taskQueue.addOperation { [weak self] in
                let task = wrapper.task()
                let taskName = task.name
                CacheManager.logger.info("start calculate size task \(taskName)")
                task.size(config: config) { [weak self] result in
                    self?.taskQueue.addOperation {
                        count += 1
                        CacheManager.logger.info("clean task \(taskName) size, result \(result)")
                        sizeResults.append(contentsOf: result.sizes)
                        if count == taskCount {
                            completion(sizeResults.getImmutableCopy())
                            CacheManager.logger.info("all clean task calculate size finished")
                        }
                    }
                }
            }
        }
    }

    private func checkAutoCleanEnable() -> Bool {
        if !autoCleanEnable { return false }
        /// autoCleanMaxCount = 0 时，不判断自动清理次数
        if self.autoCleanMaxCount == 0 { return true }

        /// 获取今天0点时间
        let now = Date()
        let calendar = Foundation.Calendar.current
        let time = calendar.startOfDay(for: now).timeIntervalSince1970

        /// 获取上一次 clean 记录，并判断时间间隔是否超过 1 天
        if let record = KVStates.cleanRecord,
            time < record.date + 60 * 60 * 24 {
            /// 如果一天内自动更新次数超过最大上限，此次不进行清除
            if record.times >= self.autoCleanMaxCount {
                return false
            }
            /// 更新当前 record
            KVStates.cleanRecord = CleanRecord(date: time, times: 1 + record.times)
        } else {
            /// 初始化当天 clean record
            KVStates.cleanRecord = CleanRecord(date: time, times: 1)
        }
        return true
    }

    @objc
    private func enterBackground() {
        Self.logger.info("enter background")
        if isUserTriggered {
            // 用户触发的清理，也开启后台任务，防止后台之后停止清理
            self.backgroundTaskID = UIApplication.shared.beginBackgroundTask {
                self.tryEndBackgroundTask()
            }
            return
        }
        // 判断是否支持自动清理缓存
        if !checkAutoCleanEnable() { return }

        if isCleaning { return }
        // 没有配置不处理
        guard let cleanConfig = self.cleanConfig else {
            return
        }
        // 当前时间-上次执行时间<config.cleanInterval，不处理
        let current = Date().timeIntervalSince1970
        if current - (KVStates.lastCleanTime ?? 0) < Double(cleanConfig.global.cleanInterval) {
            return
        }
        // 开启后台任务
        self.backgroundTaskID = UIApplication.shared.beginBackgroundTask {
            CacheManager.logger.info("application background task timeout")
            self.tasksTimeout()
        }
        // timer config.task_cost_limit，停止当前任务，调用取消接口
        self.addTimeoutCallback()
        // 加入队列开始执行
        self.clean(config: cleanConfig)
    }

    private func enterForeground() {
        Self.logger.info("enter foreground")
        // 如果是用户触发，不取消
        if isUserTriggered {
            return
        }
        self.cancelTasks()
    }

    private func tryEndBackgroundTask(delay: TimeInterval = 0) {
        if let backgroundTaskID = self.backgroundTaskID {
            if delay == 0 {
                UIApplication.shared.endBackgroundTask(backgroundTaskID)
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    UIApplication.shared.endBackgroundTask(backgroundTaskID)
                }
            }
            self.backgroundTaskID = nil
        }
    }

    @objc
    private func tasksTimeout() {
        if self.queue == OperationQueue.current {
            self.cancelTasks(timeout: true)
        } else {
            self.queue.addOperation { [weak self] in
                self?.cancelTasks(timeout: true)
            }
            self.queue.waitUntilAllOperationsAreFinished()
        }
    }

    private func cancelTasks() {
        cancelTasks(timeout: false)
    }

    private func cancelTasks(timeout: Bool) {
        if !self.isCleaning { return }
        CacheManager.logger.info("cacncel clean task, timeout \(timeout)")
        // 取消 timeout 回调
        self.cancelTimeoutCallback()
        // 取消未执行完成的任务，停止当前任务，调用取消接口
        self.taskQueue.cancelAllOperations()

        if timeout {
            self.tracker.timeout()
        } else {
            self.tracker.cancel()
        }

        // 有些可能是异步任务，需要调用cancel
        allTaskRegistry
            .filter { $0.status == .running }
            .forEach { wrapper in
                wrapper.task().cancel()
                wrapper.status = .initial
            }
        self.isCleaning = false
        // 停止后台任务
        self.tryEndBackgroundTask()
    }

    private func addTimeoutCallback() {
        assert(OperationQueue.current == self.queue)
        guard let cleanConfig = self.cleanConfig else {
            return
        }
        self.perform(#selector(tasksTimeout), with: nil, afterDelay: Double(cleanConfig.global.taskCostLimit))
    }

    private func cancelTimeoutCallback() {
        assert(OperationQueue.current == self.queue)
        OperationQueue.cancelPreviousPerformRequests(withTarget: self)
    }

    func removeObserver() {
        if let bgObserver = self.bgObserver {
            NotificationCenter.default.removeObserver(bgObserver)
        }
        if let fgObserver = self.fgObserver {
            NotificationCenter.default.removeObserver(fgObserver)
        }
    }

    func addObserver() {
        self.bgObserver = NotificationCenter.default
            .addObserver(
                forName: UIApplication.didEnterBackgroundNotification,
                object: nil,
                queue: self.queue
            ) { [weak self] _ in
                self?.enterBackground()
            }

        self.fgObserver = NotificationCenter.default
            .addObserver(
                forName: UIApplication.willEnterForegroundNotification,
                object: nil,
                queue: self.queue
            ) { [weak self] _ in
                self?.enterForeground()
            }
    }
}

extension Cache.InnerConfig {
    func hashValue() -> Int {
        var hasher = Hasher()
        switch self {
        case .old(let config):
            hasher.combine(config.cachePath)
            hasher.combine(config.cleanIdentifier)
            hasher.combine("old")
        case .new(let config):
            hasher.combine(config.rootPath.absoluteString)
            hasher.combine(config.cleanIdentifier)
            hasher.combine("new")
        }
        return hasher.finalize()
    }
}
