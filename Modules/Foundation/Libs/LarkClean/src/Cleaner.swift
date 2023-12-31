//
//  Executor.swift
//  LarkClean
//
//  Created by 7Up on 2023/6/28.
//

import Foundation
import Dispatch
import LarkStorage
import MMKV
import LKCommonsLogging

public let cleanLogger = Logger.log(Cleaner.self, category: "LarkClean")

public protocol CleanerDependency: AnyObject {
    func deepClean(completion: @escaping (_ succeed: Bool) -> Void)
}

public class Cleaner {
    public static var dependency: CleanerDependency?
    /// 清理成功
    public struct Success { }

    var log: Log { cleanLogger }

    /// 清理失败（包括部分失败）
    public struct Failure: Swift.Error {
        /// 错误码（每个失败的任务都对应一个错误码）
        public var errorCodes: [Int]
        init(errorCodes: [Int]) {
            self.errorCodes = errorCodes
        }
    }

    /// Event Sequeue:
    ///  - begin(total: N) ─►
    ///  - progress(ratio:) × N
    ///    - progress(ratio: 1/N) ─►
    ///    - progress(ratio: 2/N) ─►
    ///    - ...
    ///    - progress(ratio: N-1/N) ─►
    ///    - progress(ratio: N/N) ─►
    ///  - end(result:) ─►
    public enum Event {
        // 开始
        case begin(total: Int)
        // 进行中，ratio - 完成比例 - 0.0~1.0
        case progress(ratio: Float)
        // 结束
        case end(result: Result<Success, Failure>)
    }

    public typealias EventHandler = (_ event: Event) -> Void

    public static let shared = Cleaner()

    /// serial event queue
    public let eventQueue = DispatchQueue(label: "LarkClean.Event", qos: .default)

    // protect executors from releasing
    private var cachedExecutors = [String: [String: Executor]]()

    /// Starting clean
    ///
    /// - Parameters:
    ///   - context: clean context
    ///   - retryCount: retry count
    ///   - handler: event handler. event will be delivered in `Cleaner#eventQueue`
    /// - Returns: uniquely identify
    public func start(
        withContext context: CleanContext,
        retryCount: Int,
        handler: @escaping (Event) -> Void
    ) -> String {
        let identifier = makeIdentifier()
        log.info("[cleaner_start] identifier: \(identifier), ctx: \(context.logInfo)")
        let params = ExecutorParams.create(
            identifier: identifier,
            context: context,
            retryCount: retryCount
        )
        #if !LARK_NO_DEBUG
        DebugSwitches.lastCleanIdentifier = identifier
        #endif
        let executors = executors(forParams: params)
        DispatchQueue.global().async {
            self.runExecutors(executors, with: handler)
        }

        cancelAll(excluding: identifier)
        return identifier
    }

    /// Resuming clean
    ///
    /// - Parameters:
    ///   - identifier: uniquely identify
    ///   - handler: event handler. event will be delivered in `Cleaner#eventQueue`
    public func resume(withIdentifier identifier: String, handler: @escaping EventHandler) {
        guard let params = ExecutorParams.resume(with: identifier) else {
            log.info("[cleaner_resume] identifier: \(identifier). guard return")
            return
        }

        log.info("[cleaner_resume] identifier: \(identifier). ctx: \(params.context.logInfo)")
        let executors = self.executors(forParams: params)
        DispatchQueue.global().async {
            self.runExecutors(executors, with: handler)
        }
    }

    /// Cancel clean
    public func cancel(withIdentifier identifier: String) {
        guard let params = ExecutorParams.resume(with: identifier) else {
            log.info("[cleaner_cancel] identifier: \(identifier), guard return")
            return
        }
        log.info("[cleaner_cancel] identifier: \(identifier), ctx: \(params.context.logInfo)")

        let executors = executors(forParams: params)
        for (_, executor) in executors {
            executor.dropAll()
        }

        try? ExecutorParams.rootPath(forIdentifier: identifier).removeItem()
    }

    /// 判断是否需要 resume
    public func needsResume(withIdentifier identifier: String) -> Bool {
        guard let params = ExecutorParams.resume(with: identifier) else {
            log.info("[cleaner_check_resume] identifier: \(identifier), guard return")
            return false
        }
        log.info("[cleaner_check_resume] identifier: \(identifier), ctx: \(params.context.logInfo)")

        // 触发删除其他的历史数据
        cancelAll(excluding: identifier)

        let uncompleteCounts = executors(forParams: params).mapValues { $0.uncompletedCount() }
        log.info("[cleaner_check_resume] uncompleteCounts: \(uncompleteCounts)")
        return uncompleteCounts.values.contains(where: { $0 > 0 })
    }

    /// 深度清理
    public func deepClean(with completion: @escaping (Bool) -> Void) {
        #if !LARK_NO_DEBUG
        guard !DebugSwitches.resumeResetFail else {
            DispatchQueue.global().async { completion(false) }
            return
        }
        #endif
        guard let dep = Self.dependency else {
            log.error("[cleaner_deep_clean] missing dependency")
            completion(false)
            return
        }
        DispatchQueue.global().async {
            dep.deepClean(completion: completion)
            self.cancelAll()
        }
    }

    private func cancelAll(excluding excludeIdentifier: String? = nil) {
        // cancel other identifiers
        DispatchQueue.global().async {
            let allIdentifiers = ExecutorParams.allLocalIdentifiers()
            let otherIdentifiers: [String]
            if let excludeIdentifier {
                otherIdentifiers = allIdentifiers.filter { $0 != excludeIdentifier }
            } else {
                otherIdentifiers = allIdentifiers
            }
            otherIdentifiers.forEach(self.cancel(withIdentifier:))
        }
    }

    private func executors(forParams params: ExecutorParams) -> [String: Executor] {
        let cacheKey: String
        switch params.scene {
        case .create:
            cacheKey = "create_\(params.identifier)"
        case .resume:
            cacheKey = "resume_\(params.identifier)"
        }
        if let cached = cachedExecutors[cacheKey] {
            return cached
        } else {
            let executors: [String: Executor] = [
                "path": CleanPathExecutor(params: params),
                "task": CleanTaskExecutor(params: params),
                "vkey": CleanVkeyExecutor(params: params)
            ]
            executors.values.forEach { $0.setup() }
            cachedExecutors[cacheKey] = executors
            return executors
        }
    }

    private func runExecutors(_ executors: [String: Executor], with handler: @escaping EventHandler) {
        let totalCounts = executors.mapValues { $0.uncompletedCount() }

        eventQueue.async { [weak self] in
            self?.log.info("[cleaner_run_executors] begin: \(totalCounts)")
            handler(.begin(total: totalCounts.values.reduce(0, +)))
        }

        // 记录各个 executor 已完成的情况
        var finishCounts = executors.mapValues { _ in 0 }
        // 记录各个 executor 结束的结果；value: failCodes
        var endResults = [String: [Int]]()
        let expectEndCount = executors.count
        for (name, executor) in executors {
            executor.runOnce { [weak self] event in
                guard let self = self else { return }
                self.eventQueue.async {
                    switch event {
                    case .progress(let finished, let total):
                        assert(total == totalCounts[name])
                        self.log.info("[cleaner_run_executors] name: \(name), progress: \(finished)/\(total)")
                        finishCounts[name] = finished

                        let ratio = Float(finishCounts.values.reduce(0, +))
                            / Float(max(1, totalCounts.values.reduce(0, +)))
                        handler(.progress(ratio: ratio))
                    case .end(let failCodes):
                        assert(endResults[name] == nil)
                        let failCodeContent = failCodes.map { String($0) }.joined(separator: ",")
                        self.log.info("[cleaner_run_executors] name: \(name), end one, failCodes: [\(failCodeContent)]")
                        endResults[name] = failCodes

                        guard endResults.count == expectEndCount else { break }

                        // 已结束
                        let allFailCodes = endResults.values.flatMap { $0 }
                        let allFailCodeContent = failCodes.map { String($0) }.joined(separator: ",")
                        self.log.info("[cleaner_run_executors] name: \(name), end all, failCodes: [\(allFailCodeContent)]")
                        if allFailCodes.isEmpty {
                            handler(.end(result: .success(.init())))
                        } else {
                            handler(.end(result: .failure(.init(errorCodes: allFailCodes))))
                        }
                    }
                }
            }
        }
    }

}
