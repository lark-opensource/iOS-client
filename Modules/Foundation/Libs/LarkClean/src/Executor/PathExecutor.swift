//
//  PathExecutor.swift
//  LarkClean
//
//  Created by 7Up on 2023/7/9.
//

import Foundation
import EEAtomic
import LarkStorage

extension CleanIndex.Path: AbsPathConvertiable {
    public func asAbsPath() -> AbsPath {
        switch self {
        case .abs(let str): return AbsPath(str)
        }
    }
}

final class CleanPathItem {
    enum State: Int {
        case idle                   = 1
        case stop                   = 99

        case trashReady             = 21
        case trashSucceed           = 22
        case trashFailed            = 23

        case inPlaceDeleteReady     = 31
        case inPlaceDeleteSucceed   = 32
        case inPlaceDeleteFailed    = 33

        case inTrashDeleteReady     = 41
        case inTrashDeleteSucceed   = 42
        case inTrashDeleteFailed    = 43

        var isCompleted: Bool {
            self == .inPlaceDeleteSucceed || self == .inTrashDeleteSucceed || self == .stop
        }

        var isUncompleted: Bool {
            !isCompleted
        }

        fileprivate var logInfo: String {
            switch self {
            case .idle: return "idle"
            case .stop: return "stop"
            case .trashReady: return "trashReady"
            case .trashSucceed: return "trashSucceed"
            case .trashFailed: return "trashFailed"
            case .inPlaceDeleteReady: return "inPlaceDeleteReady"
            case .inPlaceDeleteSucceed: return "inPlaceDeleteSucceed"
            case .inPlaceDeleteFailed: return "inPlaceDeleteFailed"
            case .inTrashDeleteReady: return "inTrashDeleteReady"
            case .inTrashDeleteSucceed: return "inTrashDeleteSucceed"
            case .inTrashDeleteFailed: return "inTrashDeleteFailed"
            }
        }
    }

    private static let keyPrefix = "clean_path_item_"

    let absPath: AbsPath
    var state: State {
        didSet {
            guard oldValue != state else { return }
            syncState()
        }
    }
    var store: KVStore?

    init(absPath: AbsPath, state: State, store: KVStore?) {
        self.absPath = absPath
        self.state = state
        self.store = store
    }

    /// load items from disk
    static func loadItems(from store: KVStore) -> [CleanPathItem] {
        var ret = [CleanPathItem]()
        for key in store.allKeys() {
            guard key.hasPrefix(Self.keyPrefix) else {
                continue
            }

            guard
                let val: Int = store.value(forKey: key),
                let state = State(rawValue: val)
            else {
                continue
            }
            let relativePathToHome = String(key.dropFirst(Self.keyPrefix.count))
            let absPath = AbsPath.home + relativePathToHome
            ret.append(.init(absPath: absPath, state: state, store: store))
        }
        return ret
    }

    /// sync state to disk
    func syncState() {
        guard let relativePathToHome = absPath.relativePath(to: AbsPath.home) else {
            return
        }
        let key = Self.keyPrefix + relativePathToHome
        store?.set(state.rawValue, forKey: key)
    }
}

class CleanPathExecutor: Executor {

    let pathBuilder = IsoPath.in(space: .global, domain: Domain.biz.infra.child("LarkClean"))

    let params: ExecutorParams

    /// 作为垃圾箱使用
    lazy var trashRootPath = pathBuilder.build(forType: .temporary, relativePart: params.identifier)

    var items: [CleanPathItem] = []

    private var runningFlag = false

    init(params: ExecutorParams) {
        self.params = params
    }

    func setup() {
        switch params.scene {
        case .create:
            let indexes = CleanRegistry.allIndexes(with: params.context, cachedKey: params.identifier)
            items = indexes.values.flatMap { indexes in
                return indexes.compactMap { index -> CleanPathItem? in
                    guard case .path(let p) = index else { return nil }
                    return CleanPathItem(absPath: p.asAbsPath(), state: .idle, store: params.store)
                }
            }
            // sync states to disk for first time
            items.forEach { $0.syncState() }
        case .resume:
            items = CleanPathItem.loadItems(from: params.store)
        }
    }

    func uncompletedCount() -> Int {
        return items.filter(\.state.isUncompleted).count
    }

    func runOnce(with handler: @escaping ExecutorEventHandler) {
        assert(!runningFlag)
        runningFlag = true
        let items = items.filter(\.state.isUncompleted)
        guard !items.isEmpty else {
            DispatchQueue.global().async { handler(.endSucceed) }
            return
        }

        let total = items.count
        @AtomicObject var finishedSet = Set<String>()
        let progressUpdater = { (prevState: CleanPathItem.State, item: CleanPathItem) in
            let nextState = item.state
            if prevState.isUncompleted && nextState.isCompleted {
                finishedSet.insert(item.absPath.absoluteString)
                let finished = finishedSet.count
                handler(.progress(finished: finished, total: total))
            }
        }

        #if !LARK_NO_DEBUG
        // 模拟失败
        var mockFail = false
        switch params.scene {
        case .create:
            mockFail = DebugSwitches.logoutCleanFail
        case .resume:
            mockFail = DebugSwitches.resumeCleanFail
        }
        if mockFail {
            handler(.progress(finished: 0, total: total))
            let afterSeconds: TimeInterval = 3.0
            let mockErrorCode = 77
            DispatchQueue.global().asyncAfter(deadline: .now() + afterSeconds) {
                handler(.end(failCodes: [mockErrorCode]))
            }
            return
        }
        #endif

        // 1. prepare trash
        try? trashRootPath.createDirectoryIfNeeded()

        // 2. 将 items 尽可能 move 到 trash 中（state: idle/trashReady -> trashSucceed/trashFailed/stop）
        items.filter({ item in item.state == .idle || item.state == .trashReady })
            .forEach { item in
                let prevState = item.state
                stepState(item, rescueMode: false, terminate: .custom { state in
                    state != .trashSucceed && state != .trashFailed
                })
                progressUpdater(prevState, item)
            }

        // 3. 整体清 trash，比一个个删效率更高
        try? trashRootPath.removeItem()
        try? trashRootPath.createDirectoryIfNeeded()

        // 4. 全面处理
        for i in 0..<max(1, params.retryCount) {
            items.forEach { item in
                let prevState = item.state
                stepState(item, rescueMode: i > 0, terminate: .auto)
                progressUpdater(prevState, item)
            }
        }
        let failCodes = items.filter(\.state.isUncompleted).map(\.state.rawValue)
        handler(.end(failCodes: failCodes))
    }

    func dropAll() {
        DispatchQueue.global().async {
            do {
                try self.trashRootPath.removeItem()
            } catch {
                self.log.error("[PathExecutor] drop trash failed at path: \(self.trashRootPath.absoluteString)")
            }
        }
    }

    /// ** --------------------------------------- state transition --------------------------------------- **
    /// *                                                                                                    *
    /// *                                                          ┌───── rescue ─────┐                      *
    /// *                                                          ▼       ┌─► inTrashDeleteFailed    (✘)    *
    /// *                          ┌─► trashSucceed ─► inTrashDeleteReady ─┤                                 *
    /// *                          │                                       └─► inTrashDeleteSucceed   (✔)    *
    /// *          ┌─► trashReady ─┤                                                                         *
    /// *          │               │                                       ┌─► inPlaceDeleteSucceed   (✔)    *
    /// *          │               └─► trashFailed  ─► inPlaceDeleteReady ─┤                                 *
    /// *    idle ─┤                                               ▲       └─► inPlaceDeleteFailed    (✘)    *
    /// *          │                                               └───── rescue ─────┘                      *
    /// *          │                                                                                         *
    /// *          └───────────────────────────────────────────────────────────► stop                 (✔)    *
    /// *                                                                                                    *
    /// ** ------------------------------------------------------------------------------------------------ **

    enum StepTerminate {
        typealias ContinueChecker = (CleanPathItem.State) -> Bool
        case auto                       // 自动；走不动就不走了
        case steps(Int)                 // 往前走 n 步
        case custom(ContinueChecker)    // 根据 checker 判断
    }

    @inline(__always)
    func stepState(_ item: CleanPathItem, rescueMode: Bool, terminate: StepTerminate = .auto) {
        let prevState = item.state
        switch terminate {
        case .custom(let checkContinue):
            guard checkContinue(prevState) else {
                return
            }
        case .steps(let count):
            if count <= 0 {
                return
            }
        case .auto:
            // do nothing
            break
        }
        let trashPath = trashPath(for: item)

        switch prevState {
        case .idle:
            item.state = item.absPath.exists ? .trashReady : .stop
        case .trashReady:
            if let dstPath = trashPath {
                do {
                    try dstPath.deletingLastPathComponent.createDirectoryIfNeeded()
                    try dstPath.notStrictly.moveItem(from: item.absPath)
                    item.state = .trashSucceed
                } catch {
                    log.error("[PathExecutor] rename failed. srcPath: \(item.absPath.absoluteString), dstPath: \(dstPath.absoluteString), err: \(error)")
                    item.state = .trashFailed
                }
            } else {
                item.state = .trashFailed
                log.error("[PathExecutor] rename failed. cannot parse dstPath")
                assertionFailure("unexpected error")
            }
        case .trashFailed:
            item.state = .inPlaceDeleteReady
        case .trashSucceed:
            item.state = .inTrashDeleteReady
        case .inPlaceDeleteReady:
            // delete in place
            if item.absPath.exists {
                do {
                    try item.absPath.notStrictly.removeItem()
                    item.state = .inPlaceDeleteSucceed
                } catch {
                    log.error("[PathExecutor] in-place delete failed. path: \(item.absPath.absoluteString), err: \(error)")
                    item.state = .inPlaceDeleteFailed
                }
            } else {
                item.state = .inPlaceDeleteSucceed
            }
        case .inTrashDeleteReady:
            // delete in trash
            if let path = trashPath, path.exists {
                do {
                    try path.removeItem()
                    item.state = .inTrashDeleteSucceed
                } catch {
                    item.state = .inTrashDeleteFailed
                }
            } else {
                item.state = .inTrashDeleteSucceed
            }
        case .inPlaceDeleteFailed:
            if rescueMode {
                item.state = .inPlaceDeleteReady
            }
        case .inTrashDeleteFailed:
            if rescueMode {
                item.state = .inTrashDeleteReady
            }
        case .inPlaceDeleteSucceed, .inTrashDeleteSucceed, .stop:
            break
        }
        let `continue` = prevState != item.state

        guard `continue` else { return }

        log.info("[PathExecutor] state changed: \(prevState.logInfo)->\(item.state.logInfo), path: \(item.absPath.absoluteString)")
        var nextRescueMode = rescueMode
        // rescue only once
        if prevState == .inPlaceDeleteFailed || prevState == .inTrashDeleteFailed {
            nextRescueMode = false
        }
        let nextTerminate: StepTerminate
        if case .steps(let count) = terminate {
            nextTerminate = .steps(count - 1)
        } else {
            nextTerminate = terminate
        }
        stepState(item, rescueMode: nextRescueMode, terminate: nextTerminate)
    }

    @inline(__always)
    func trashPath(for item: CleanPathItem) -> IsoPath? {
        guard let relativePathToHome = item.absPath.relativePath(to: AbsPath.home) else {
            return nil
        }
        return trashRootPath + relativePathToHome
    }
}
