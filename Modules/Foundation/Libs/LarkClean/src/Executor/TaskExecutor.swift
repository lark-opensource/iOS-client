//
//  TaskExecutor.swift
//  LarkClean
//
//  Created by 7Up on 2023/7/9.
//

import Foundation
import LarkStorage
import EEAtomic

class CleanTaskItem {
    enum State: Int {
        case ready      = 11
        case running    = 22
        case succeed    = 31
        case failed     = 32
    }

    private static let keyPrefix = "clean_task_item_"

    let name: String
    var store: KVStore?
    var state: State {
        didSet {
            guard oldValue != state else { return }
            syncState()
        }
    }

    init(name: String, state: State, store: KVStore? = nil) {
        self.name = name
        self.state = state
        self.store = store
    }

    /// sync state to disk
    func syncState() {
        guard let store else { return }
        let key = Self.keyPrefix + name
        store.set(state.rawValue, forKey: key)
    }

    /// load and fix uncompleted items from store
    ///   - ignore: .succeed
    ///   - fix: .running -> .ready
    static func loadAndFixUncompletedItems(from store: KVStore) -> [CleanTaskItem] {
        var ret = [CleanTaskItem]()
        for key in store.allKeys() {
            guard key.hasPrefix(Self.keyPrefix) else { continue }

            let name = String(key.dropLast(Self.keyPrefix.count))
            guard
                let val: Int = store.value(forKey: key),
                let state = State(rawValue: val),
                state != .succeed   // ignore succeed item
            else {
                continue
            }
            let item = CleanTaskItem(name: name, state: state, store: store)
            if item.state == .running {
                item.state = .ready
            }
            ret.append(.init(name: name, state: state, store: store))
        }
        return ret
    }
}

private let taskFailCode = 9999

class CleanTaskItemWrapper: CleanTaskSubscriber {
    private let wrapped: CleanTaskItem
    let handler: CleanTaskHandler

    typealias Completion = (Bool) -> Void

    private let lock = UnfairLock()
    private var completion: Completion?
    private weak var queue: DispatchQueue?

    /// 表示超时 error
    struct TimeoutError: Swift.Error { }

    let intId: Int32

    init(wrapped: CleanTaskItem, handler: @escaping CleanTaskHandler) {
        self.wrapped = wrapped
        self.handler = handler
        self.intId = uuint()
    }

    var name: String { wrapped.name }

    var state: CleanTaskItem.State {
        get { wrapped.state }
        set { wrapped.state = newValue }
    }

    func receive(completion: CleanTaskCompletion) {
        innerComplete(completion: completion)
    }

    // state: ready -> running -> succeed/failed
    func runIfNeeded(with context: CleanContext, queue: DispatchQueue) {
        lock.lock()
        defer { lock.unlock() }
        self.queue = queue
        guard state == .ready else {
            return
        }
        state = .running
        queue.async {
            self.handler(context, self)
        }
        queue.asyncAfter(deadline: .now() + 30.0) {
            self.innerComplete(completion: .failure(TimeoutError()))
        }
    }

    func setCompletion(_ completion: @escaping Completion) {
        lock.lock()
        defer { lock.unlock() }
        self.completion = completion
    }

    func prepareForRun() {
        lock.lock()
        defer { lock.unlock() }
        if state == .failed {
            state = .ready
        }
    }

    private func innerComplete(completion: CleanTaskCompletion) {
        lock.lock()
        defer { lock.unlock() }

        guard state != .failed && state != .succeed else {
            return
        }

        let succeed: Bool
        let callback = self.completion
        switch completion {
        case .finished:
            state = .succeed
            succeed = true
        case .failure(let err):
            state = .failed
            succeed = false
            cleanLogger.error("execute failed. err: \(err)")
        }
        self.completion = nil
        queue?.async {
            callback?(succeed)
        }
    }
}

class CleanTaskExecutor: Executor {
    let params: ExecutorParams

    private var runningFlag = false

    private var items: [CleanTaskItemWrapper] = []
    public let serialQueue = DispatchQueue(label: "LarkClean.CleanTask", qos: .default)

    init(params: ExecutorParams) {
        self.params = params
    }

    func setup() {
        items = []
        let handlers = CleanRegistry.taskHandlers
        switch params.scene {
        case .create:
            for (name, handler) in handlers {
                let wrapped = CleanTaskItem(name: name, state: .ready, store: params.store)
                wrapped.syncState() // save state to disk
                items.append(.init(wrapped: wrapped, handler: handler))
            }
        case .resume:
            let loadedItems = CleanTaskItem.loadAndFixUncompletedItems(from: params.store)
            for wrapped in loadedItems {
                guard let handler = handlers[wrapped.name] else {
                    continue
                }
                items.append(.init(wrapped: wrapped, handler: handler))
            }
        }
    }

    /// 计算需要 clean 的 task count
    func uncompletedCount() -> Int {
        return items.filter( { $0.state != .succeed }).count
    }

    func runOnce(with handler: @escaping ExecutorEventHandler) {
        assert(!runningFlag)
        runningFlag = true

        let items = items.filter { $0.state != .succeed }
        guard !items.isEmpty else {
            serialQueue.async { handler(.end(failCodes: [])) }
            return
        }
        let total = items.count

        // handle callback
        var results = [Int32: Bool]()
        for item in items {
            let id = item.intId
            item.setCompletion { succeed in
                results[id] = succeed
                handler(.progress(finished: results.values.filter({ $0 }).count, total: total))
                if results.count == total {
                    let failCodes: [Int] = results.values.compactMap { succeed in
                        return succeed ? nil : taskFailCode
                    }
                    handler(.end(failCodes: failCodes))
                }
            }
        }

        for item in items {
            item.prepareForRun()
            item.runIfNeeded(with: params.context, queue: serialQueue)
        }
    }

    func dropAll() {
        // do nothing
    }
}
