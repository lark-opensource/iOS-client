//
//  ContainerManager.swift
//  LarkRustClientAssembly
//
//  Created by SolaWing on 2023/10/20.
//

import Foundation
import LarkContainer
import LarkAccountInterface
import EEAtomic
import LKCommonsLogging
import RustPB
import LarkRustClient
import BootManager
import LarkSetting
#if LarkPushTokenUploader
import LarkPushTokenUploader
#endif

/// 容器生命周期管理类。负责端上和Rust容器的上下线管理
/// 设计文档：https://bytedance.feishu.cn/docx/ECwfdXcT4oBVLfxdPN8chX0gnYg#S66SdY5SfoP6BLxJ83ucLcQ0n7C
public final class LarkContainerManager: LarkContainerManagerInterface {
    static let logger = Logger.log(LarkContainerManager.self, category: "LarkAccount.LarkContainerManager")
    public static let shared = LarkContainerManager()
    init() {
        queue.setSpecific(key: queueKey, value: true)
    }
    /// input: user list change
    /// 触发用户列表变化流程。该流程为串行执行，新的变化流程需要等之前的流程中断后才能开始..
    /// - Parameters:
    ///     - userList: 要上线的用户列表，包含前台用户.. 如果用户的sessionKey和当前不一致，会强制重新登录
    ///     - delegate: 会持有到流程结束。调用方应该创建隔离实例避免不同的调用之间串回调
    public func userListChange(userList: [User], foregroundUser: User?, action: PassportUserAction,
                               delegate: LarkContainerManagerFlowProgressDelegate) {
        let flow = Flow(userList: userList, foregroundUser: foregroundUser, action: action, delegate: delegate)
        LarkContainerManager.logger.info("userListChange - \(action): \(userList.map { $0.userID }.joined(separator: ", "))")
        queue.async { [self] in
            if let currentFlow { // 标记打断等待运行
                // 考虑事件原因是否要分用户继承最初的原因，这样不同用户的流程可以完全独立
                currentFlow.interrupted()
                let oldNextFlow = nextFlow
                self.nextFlow = flow
                if let oldNextFlow {
                    oldNextFlow.completeWithError(.cancelled, isCurrent: false)
                }
            } else {
                #if ALPHA
                precondition(nextFlow == nil)
                #endif
                nextFlow = flow
                _runNextFlow()
            }
        }
    }

    private func _runNextFlow() {
        assertOnQueue()
        guard let nextFlow else { return }
        self.nextFlow = nil
        currentFlow = nextFlow
        nextFlow.run()
    }

    /// flow can only finish by itself. so delegate and state already handled
    /// here only check for next flow
    func finishCurrentFlow(_ flow: Flow) {
        queue.async { [self] in
            guard flow === currentFlow else {
                // 堆积的flow可能被取消提前结束, 其他情况都是当前的flow一个个结束
                // 非当前flow结束的情况不应该调用这个方法
                preconditionAlpha(false, "finish flow is not current flow")
                return
            }
            currentFlow = nil
            /// 控制FG的变化。重启生效
            MultiUserActivitySwitch.Observer.shared.observeEnableFG()
            _runNextFlow()
        }
    }

    // MARK: state
    /// 用于保证主流程的串行，以及状态的线程安全。同时事件通知是异步的不占用调用线程
    /// 需要注意该queue不应该有耗时的占用
    let state = State()
    var currentFlow: Flow?
    var nextFlow: Flow?
    let queueKey = DispatchSpecificKey<Bool>()
    let queue = DispatchQueue(label: "LarkContainerManager", qos: .userInitiated)
    func run(inQueue action: @escaping () -> Void) {
        let inQueue = DispatchQueue.getSpecific(key: queueKey) == true
        if inQueue {
            action()
        } else {
            queue.async(execute: action)
        }
    }
    func assertOnQueue() {
        #if DEBUG || ALPHA
        dispatchPrecondition(condition: .onQueue(queue))
        #endif
    }
}
func assertOnFlowQueue() {
    #if DEBUG || ALPHA
    LarkContainerManager.shared.assertOnQueue()
    #endif
}

extension LarkContainerManager {
    class State {
        deinit {
            lock.deallocate()
        }
        let lock = UnfairLockCell()
        var users = [String: UserState]()
        /// FIXME: 也许可以直接用端上容器里的?
        /// 可能停留在中间状态，然后出现foregroundUser offline的情况?
        /// rust和native是否可能出现foregroundUser不一致的现象？
        var foregroundUserID: String?

        func locking<T>(action: (State) -> T) -> T {
            lock.lock(); defer { lock.unlock() }
            return action(self)
        }
        func modify(action: (State) -> Void) {
            lock.lock(); defer { lock.unlock() }
            action(self)
        }
        func rustOffline(userID: String) {
            modify {
                guard var userState = $0.users[userID] else { return }
                if case .offline = userState.native {
                    $0.users.removeValue(forKey: userID)
                } else {
                    userState.rust = .offline
                    $0.users[userID] = userState
                }
            }
        }
        func nativeOffline(userID: String) {
            modify {
                guard var userState = $0.users[userID] else { return }
                if case .offline = userState.rust {
                    $0.users.removeValue(forKey: userID)
                } else {
                    userState.native = .offline
                    $0.users[userID] = userState
                }
            }
        }
    }
    enum ContainerState: Equatable {
        case offline
        case foreground(User)
        case background(User)

        func bridge() -> Tool_V1_UserLoginState {
            switch self {
            case .offline: return .offline
            case .background: return .backgroundOnline
            case .foreground: return .foregroundOnline
            }
        }
        static func userEqual(lhs: User, rhs: User) -> Bool {
            lhs.userID == rhs.userID && lhs.sessionKey == rhs.sessionKey
        }
        static func == (lhs: ContainerState, rhs: ContainerState) -> Bool {
            switch (lhs, rhs) {
            case (.offline, .offline): return true
            case (.foreground(let lhsUser), .foreground(let rhsUser)): return userEqual(lhs: lhsUser, rhs: rhsUser)
            case (.background(let lhsUser), .background(let rhsUser)): return userEqual(lhs: lhsUser, rhs: rhsUser)
            default: return false
            }
        }
        static func diffInfo(lhs: ContainerState, rhs: ContainerState) -> String? {
            switch (lhs, rhs) {
            case (.offline, .offline): return nil
            case (.foreground(let lhsUser), .foreground(let rhsUser)),
                 (.background(let lhsUser), .background(let rhsUser)):
                if userEqual(lhs: lhsUser, rhs: rhsUser) { return nil }
                return "user change"
            default:
                return "\(lhs.bridge()) --> \(rhs.bridge())"
            }
        }

        var isForeground: Bool {
            if case .foreground = self { return true }
            return false
        }
        var user: User? {
            switch self {
            case .offline: return nil
            case .foreground(let user): return user
            case .background(let user): return user
            }
        }
        var sessionKey: String? {
            switch self {
            case .offline: return nil
            case .foreground(let user): return user.sessionKey
            case .background(let user): return user.sessionKey
            }
        }
    }
    struct UserState: Equatable {
        init(native: LarkContainerManager.ContainerState = .offline,
             rust: LarkContainerManager.ContainerState = .offline) {
            self.native = native
            self.rust = rust
        }
        /// 两端一起变，状态就是一致。不一致说明中间打断或者出错了..
        ///
        /// NOTE: 最终决定：通过原子性的步骤检查，来保证双端状态停留在预期范围内，包括双端的一致性，具体允许出现的状态为：
        /// 1. 一致的上线或者下线状态(包括有当前用户, 但还没清理成nil的下线状态)
        /// 2. rust上线，native还未上线状态(rustOnlinePaired==false)
        /// 3. (fastLogin)native上线, rust上线失败状态(当成成功状态，但其实rust状态已经异常了)
        /// 打断和错误中止的时候，需要注意状态变化符合预期..

        var native: ContainerState // 端上容器状态
        var rust: ContainerState // rust容器状态
        /// 双端都开始进行online步骤后，该值为true(端上online开始在rustonline开始后，但不一定等结束)
        /// 配对状态下, 任意一端需要新登录，另一端都需要强制重新登录
        // 需要保证rust和端上上线状态一致，登录次数不能1对N，所以native和rust的最终状态还要计数一致
        var rustOnlinePaired = false // native登录时设置，rust变化时检查

        // equal state consider no change and not need action
        static func == (lhs: UserState, rhs: UserState) -> Bool {
            return lhs.native == rhs.native &&
                lhs.rust == rhs.rust
        }
        static func diffInfo(lhs: UserState, rhs: UserState) -> String {
            var desc = [String]()
            if let diff = ContainerState.diffInfo(lhs: lhs.native, rhs: rhs.native) {
                desc.append("native: \(diff)")
            }
            if let diff = ContainerState.diffInfo(lhs: lhs.rust, rhs: rhs.rust) {
                desc.append("rust: \(diff)")
            }
            if desc.isEmpty { return "no change" }
            return desc.joined(separator: ", ")
        }
    }
    class Flow {

        init(userList: [User], foregroundUser: User?, action: PassportUserAction,
             delegate: LarkContainerManagerFlowProgressDelegate) {
            self.userList = userList
            self.foregroundUser = foregroundUser
            self.action = action
            self.delegate = delegate
        }
        deinit {
            lock.deallocate()
        }

        let userList: [User]
        let foregroundUser: User?
        let action: PassportUserAction
        // NOTE: delegate现在就foregroundChange和finish两个调用。且finish必定是在最后的..
        let delegate: LarkContainerManagerFlowProgressDelegate

        private var _state = FlowState.idle
        var state: FlowState {
            get { lock.withLocking { _state } }
            set { lock.withLocking { _state = newValue } }
        }
        var lock = UnfairLockCell()

        enum FlowState: Comparable {
        case idle
        case running
        case interrupt // 标记被打断，等待原子性步骤结束后，中断流程..
        case completed
        }

        func interrupted() {
            lock.withLocking {
                if _state < .interrupt { _state = .interrupt }
            }
        }
        /// 原子性步骤开始点可以检查是否打断, 需要主动打断保证原子性
        /// NOTE: 原子性步骤打断节点确认, 目前看backgroundOnline很快，可能不需要打断.., 除非后面优化性能
        func checkInterrupt() throws {
            if self.state == .interrupt {
                throw LarkContainerManagerFlowError.interruptted
            }
        }

        private func _markComplete() -> Bool {
            lock.withLocking {
                if _state == .completed {
                    preconditionAlpha(false, "already completed")
                    return false
                }
                _state = .completed
                return true
            }
        }
        func complete() {
            guard _markComplete() else { return }
            assertOnFlowQueue()
            delegate.didCompleteWithError(nil)
            // TODO: 可能需要移除单例依赖
            LarkContainerManager.shared.finishCurrentFlow(self)
        }
        func completeWithError(_ error: LarkContainerManagerFlowError, isCurrent: Bool = true) {
            guard _markComplete() else { return }
            assertOnFlowQueue()
            delegate.didCompleteWithError(error)
            if isCurrent {
                LarkContainerManager.shared.finishCurrentFlow(self)
            }
        }

        // MARK: Main Biz Logic
        func run() {
            preconditionAlpha(state == .idle, "state should be idle")
            self.state = .running
            var graph = {
                var differ = Differ(base: self)
                preconditionAlpha(isKnownUniquelyReferenced(&differ), "differ wrapper class shouldn't be captured")
                return differ.graph
            }()
            preconditionAlpha(isKnownUniquelyReferenced(&graph), "graph shouldn't be captured!")
            // run graph until all rootActions finished
            #if ALPHA
            weak var weakRun: RunGraph?
            weak var weakGraph = graph
            let check = {
                precondition(weakRun == nil)
                precondition(weakGraph == nil)
            }
            #endif
            let run = RunGraph(graph: graph, flow: self, finishCallback: { [self] result in
                switch result {
                case .success:
                    self.complete()
                case .failure(let error):
                    switch error {
                    case let error as LarkContainerManagerFlowError:
                        self.completeWithError(error)
                    default:
                        self.completeWithError(.other(error))
                    }
                }
                #if ALPHA
                assertOnFlowQueue()
                LarkContainerManager.shared.queue.async { check() }
                #endif
            })
            #if ALPHA
            weakRun = run
            #endif
            run.tick()
        }
        // NOTE: memory retain graph
        // RunGraph -> (Flow, Graph)
        // StepFinish -> RunGraph(only when Run), deinit after all finished.
        // StepFinish -> Flow(maybe)
        // StepImplementation -> StepFinish(maybe) 不应该长时间持有。需要保证有一次回调且要清理回调.
        // Graph -> Action(release after success) -> Flow
        class RunGraph {
            init(graph: FlowGraph, flow: Flow, finishCallback: @escaping FinishCallback<Void>) {
                self.finishCallback = finishCallback
                self.graph = graph
                self.flow = flow
                self.rootActions = graph.rootActions()
                LarkContainerManager.logger.info(graph.debugDescription)
            }

            // 生命周期：finish持有状态.., 但是finish后需要释放。
            //      finish无法保证一定释放，所以这里通过临时持有兜底
            let graph: FlowGraph
            let flow: Flow
            var rootActions: Set<FlowGraph.ID>
            let finishCallback: FinishCallback<Void>
            var runningActions = AtomicInt64(0)
            var failure: [FlowGraph.ID: Error] = [:]
            /// 目前先一个个运行，后面要改成并发, 另外串行可能还得有一定顺序的倾向性
            /// 线程安全：通过在串行的LarkContainerManager.shared.queue来保证
            static let concurrency = 8
            func tick() {
                assertOnFlowQueue()
                // TODO: 调度策略, 另外可能需要注意按user并发增加完成度，而不是都只有部分的步骤进行
                let concurrency = Self.concurrency
                if runningActions.value >= concurrency { return }
                guard let id = rootActions.first else {
                    if runningActions.value == 0 {
                        finish() // nomore actions..
                    }
                    return
                }
                rootActions.remove(id)
                guard let vertex = graph.actions[id] else {
                    LarkContainerManager.logger.warn("Flow \(id) not found")
                    return tick() // retry next action
                }
                // run action
                guard let task = vertex.task else {
                    /// 没有action的只是一个单纯的时机节点
                    LarkContainerManager.logger.info("Flow Event: \(id)")
                    handleSuccess(id: id)
                    return
                }
                LarkContainerManager.logger.info("Flow Start: \(id)")

                let context = Context(me: self, id: id)
                /// 支持并发，但仅当任务开启异步线程，避免线程切换耗时影响启动性能
                task(context, context.finish)
                if concurrency > 1 {
                    tick()
                }
                return

                class Context: TaskContext {
                    var me: RunGraph? // 运行期间临时持有
                    var id: FlowGraph.ID
                    let startTime = CACurrentMediaTime()
                    var totalWaiting: CFTimeInterval = 0
                    init(me: RunGraph, id: FlowGraph.ID) {
                        self.id = id
                        push(me: me)
                    }
                    deinit {
                        preconditionAlpha(me == nil, "me should consume before finish!")
                    }

                    func push(me: RunGraph) {
                        self.me = me
                        me.runningActions.increment()
                    }

                    func pop(action: @escaping (RunGraph) -> Void) {
                        LarkContainerManager.shared.queue.async { [self] in
                            guard let me else {
                                // 只有运行期间可以回调一次，不应该有多次回调..
                                preconditionAlpha(false, "shouldn't call after finish")
                                return
                            }
                            self.me = nil
                            me.runningActions.decrement()
                            action(me)
                        }
                    }
                    func finish(_ result: (Result<Void, Error>)) {
                        pop { self._finish(result, me: $0) }
                    }
                    private func _finish(_ result: (Result<Void, Error>), me: RunGraph) {
                        switch result {
                        case .success:
                            LarkContainerManager.logger.info("Flow Success: \(id) \(durationDesc(CACurrentMediaTime() - startTime - totalWaiting))")
                            me.handleSuccess(id: id)
                        case .failure(let error):
                            let duration = durationDesc(CACurrentMediaTime() - startTime - totalWaiting)
                            LarkContainerManager.logger.warn("Flow Failed: \(id) \(duration)", error: error)
                            me.handleFailure(id: id, error: error)
                        }
                    }

                    func wait(id wid: String, when: @escaping (@escaping () -> Void) -> Void, next: @escaping () -> Void) {
                        pop { self._wait(me: $0, id: wid, when: when, next: next) }
                    }
                    private func _wait(me: RunGraph, id wid: String, when: @escaping (@escaping () -> Void) -> Void, next: @escaping () -> Void) {
                        let startTime = CACurrentMediaTime()
                        LarkContainerManager.logger.info("Flow Waiting: \(id) => \(wid)")
                        var called = false
                        when { [weak me, self] in
                            // NOTE: 该回调需要在finish调用前调用，保证恢复了任务，
                            // 避免发出信号因为异步晚于调度，而被认为阻塞finish的情况
                            guard let me, !called else { return }
                            called = true // 一次性回调
                            push(me: me) // me在wait时临时释放，不阻塞整体流程

                            let waitingTime = CACurrentMediaTime() - startTime
                            totalWaiting += waitingTime
                            LarkContainerManager.logger.info("Flow Resume: \(id) => \(wid) \(durationDesc(waitingTime))")
                            // FIXME: 这个resume可能也需要按线程数限制进行调度。
                            // 不过目前这个waiting功能只给特殊等待信号节点使用，没有实际的并发任务，所以还好
                            next()
                        }
                        if !called { // 不是直接满足要求，先开始下一次任务, 避免阻塞
                            me.tick()
                        }
                    }
                }

                func durationDesc(_ duration: CFTimeInterval) -> String {
                    return String(format: "%.0fms", duration * 1_000)
                }
            }
            func handleSuccess(id: FlowGraph.ID) {
                /// 成功后移除当前节点，添加新root节点等待运行
                if let vertex = graph.remove(id: id) {
                    for sid in vertex.successors {
                        if let v = graph.actions[sid], v.predecessors.isEmpty {
                            rootActions.update(with: sid)
                        }
                    }
                } else {
                    preconditionAlpha(false, "action \(id) not found when finish")
                }
                tick() // run next action
            }
            func handleFailure(id: FlowGraph.ID, error: Error) {
                /// 失败后节点保留，由此只阻塞后续依赖任务的运行
                ///
                /// 但前台相关重要任务失败后，需要主动标记打断所有流程(少数敏感错误)
                /// 为了保证依赖任务的原子性状态改变和打断时机的可控性.
                /// 节点只能自行检查打断标记主动终止运行
                failure[id] = error
                tick()
            }
            func finish() {
                struct GraphNotfinish: Error {}
                // NOTE: 错误情况下，graph的步骤没有被清理，还会被graph持有.
                // 但graph应该随着self释放而释放, 最终把action都释放
                if graph.actions.isEmpty && failure.isEmpty {
                    LarkContainerManager.logger.info("Graph Finish Success!")
                    finishCallback(.success(()))
                } else if failure.isEmpty {
                    // NOTE: 这种情况是有等待的没有结束，无错误的情况下的确不应该进来
                    // 等待中的持有关系: 相关action -> condition(用于set) -> observed next(by wait)
                    preconditionAlpha(false, "Graph NOT FINISH!\n\(graph.debugDescription)")
                    finishCallback(.failure(GraphNotfinish()))
                } else {
                    var finalError = LarkContainerManagerFlowError.other(nil)
                    var level = 0 // 1 interrupted, 2 other
                    mergeError: for (_, error) in failure {
                        switch error {
                        case let error as LarkContainerManagerFlowError:
                            switch error {
                            case .foregroundOnlineFailed:
                                finalError = error
                                break mergeError // highest priority
                            case .other:
                                finalError = error
                                level = 2
                            case .interruptted:
                                if level < 1 {
                                    level = 1
                                    finalError = error
                                }
                            default:
                                if level == 0 {
                                    finalError = error
                                }
                            }
                        default:
                            finalError = LarkContainerManagerFlowError.other(error)
                            level = 2
                        }
                    }
                    LarkContainerManager.logger.warn("Graph Finish With Errors: ", error: finalError)
                    finishCallback(.failure(finalError))
                }
            }
        }
        /// Diff逻辑比较复杂，将状态按class进行封装，方法进行拆分隔离
        /// NOTE: 修改代码时注意闭包捕获范围，最小化捕获, 并注意引用关系
        class Differ {
            let base: Flow
            let globalState = LarkContainerManager.shared.state

            /// calculate base state
            let newStates: [String: UserState]
            let oldStates: [String: UserState]
            let oldForegroundUserID: String?
            let newForegroundUserID: String?

            /// generated graph
            let graph = FlowGraph()
            init(base: Flow) {
                self.base = base

                /// collect targetState
                var newStates: [String: UserState] = [:]
                let foregroundUserID = base.foregroundUser?.userID
                func markOnline(user: User) {
                    let isForeground = foregroundUserID == user.userID
                    if isForeground {
                        newStates[user.userID] = UserState(native: .foreground(user), rust: .foreground(user))
                    } else {
                        newStates[user.userID] = UserState(native: .background(user), rust: .background(user))
                    }
                }
                for user in base.userList { markOnline(user: user) }

                if let foregroundUser = base.foregroundUser, newStates.index(forKey: foregroundUser.userID) == nil {
                    preconditionAlpha(false, "foregroundUser must in userList")
                    markOnline(user: foregroundUser)
                }

                globalState.lock.lock(); defer { globalState.lock.unlock() }
                let oldStates = globalState.users

                for (userID, curState) in oldStates {
                    if let target = newStates[userID] {
                        // ignore unchanged state
                        if target == curState { newStates.removeValue(forKey: userID) }
                    } else {
                        let newState = UserState(native: .offline, rust: .offline)
                        if curState != newState {
                            // offline for unneed state
                            newStates[userID] = newState
                        }
                    }
                }

                self.newStates = newStates
                self.oldStates = oldStates
                self.newForegroundUserID = foregroundUserID
                self.oldForegroundUserID = globalState.foregroundUserID

                self.build()
            }

            func build() {
                let base = self.base
                /// calculate action for common state change
                /// 先按单个用户编排流程顺序，再加前台导致的时序依赖(通过用户依赖和时机信号)
                for (userID, newState) in newStates {
                    let oldState = oldStates[userID] ?? UserState(native: .offline, rust: .offline)
                    LarkContainerManager.logger.info("will change user state \(userID): \(UserState.diffInfo(lhs: oldState, rhs: newState)))")

                    changeRustState(userID: userID, oldState: oldState, newState: newState)
                    changeNativeState(userID: userID, oldState: oldState, newState: newState)
                }
                /// 协调前台用户间依赖关系
                /// 后台用户需要先等前台用户任务结束
                /// 前台用户online, 需要等之前的前台用户下线让出位置

                // NOTE: 存在有foreground，只变后台的情况. 这样里面的应该只会有空步骤..
                // 但是可以让afterForegroundChange始终调用
                if let newForegroundUserID { patch(foregroundUserID: newForegroundUserID) }
                if let oldForegroundUserID, oldForegroundUserID != newForegroundUserID {
                    patch(oldForegroundUserID: oldForegroundUserID)
                }
                let waitFastLoginFinishSignal = base.action == .fastLogin && newForegroundUserID != nil && (graph.actions["backgroundStart"]?.successors.count ?? 0) > 0
                graph.wrap(id: "backgroundStart") { (old) in
                    wrapBackgroundStart(old: old, waitFastLogin: waitFastLoginFinishSignal)
                }
            }
            // 需要保证每一个步骤都一定有结束调用.., 不会卡死也不会忽略不调用..
            func changeRustState(userID: String, oldState: UserState, newState: UserState) {
                guard oldState != newState else {
                    preconditionAlpha(false, "应该在前面过滤好。只有状态变化的需要处理")
                    return
                }
                let base = self.base
                // 外部信号依赖.. NOTE: 接收信号的不应该给其添加额外依赖
                let rustCanOffline = StepID(user: userID, id: "rustCanOffline")
                let rustOnline = StepID(user: userID, id: "rustOnline")

                /// NOTE: 前台相关的会在后面移除backgroundStart的前置依赖
                var flow = graph.flow(start: "backgroundStart")
                flow.next(id: StepID(user: userID, id: "start"))
                defer { flow.next(id: StepID(user: userID, id: "end")) }
                flow.next(id: StepID(user: userID, id: "rustStart"))
                defer { flow.next(id: StepID(user: userID, id: "rustEnd")) }
                if oldState.rust.sessionKey == newState.rust.sessionKey {
                    if oldState.rust != newState.rust {
                        let changeState = StepID(user: userID, id: "rustChangeState")
                        if oldState.rust != .offline {
                            // 在线状态切换，需要等待offline ready
                            graph.addEdge(from: rustCanOffline, to: changeState)
                        }
                        flow.next(id: changeState) {  finish in
                            base.rustChangeState(
                                from: oldState.rust, to: newState.rust,
                                finish: finish)
                        }
                        if newState.rust != .offline {
                            flow.next(id: rustOnline) // online是一个信号，没有action
                        }
                    } else if oldState.rust != .offline, oldState.rustOnlinePaired == true {
                        preconditionAlpha(oldState.native != newState.native, "rust状态没有变化，native的状态应该有变化。都没变化的不应该进来")
                        preconditionAlpha(false, "目前应该不会出现这样不配对的情况, 除非支持了前台打断单独登出或者前台失败, 需要检查代码!")
                        // rust状态期望不变，但在线状态已经配对，且native有登录，需要强制重登
                        // 离线状态或者还没有配对的情况，状态一致可以跳过
                        forceRelogin()
                    }
                } else {
                    forceRelogin()
                }
                func forceRelogin() {
                    // session key变化时强制下线重登
                    if oldState.rust != .offline {
                        let offline = StepID(user: userID, id: "rustOffline")
                        graph.addEdge(from: rustCanOffline, to: offline)
                        flow.next(id: offline) { finish in
                            base.rustChangeState(from: oldState.rust, to: .offline, finish: finish)
                        }
                    }
                    if newState.rust != .offline {
                        flow.next(id: rustOnline) { finish in
                            base.rustChangeState(from: .offline, to: newState.rust, finish: finish)
                        }
                    }
                }
            }
            func changeNativeState(userID: String, oldState: UserState, newState: UserState) {
                let base = self.base
                var flow = graph.flow(start: "backgroundStart")
                flow.next(id: StepID(user: userID, id: "start"))
                defer { flow.next(id: StepID(user: userID, id: "end")) }
                flow.next(id: StepID(user: userID, id: "nativeStart"))

                // 外部信号依赖
                let rustCanOffline = StepID(user: userID, id: "rustCanOffline")
                let rustOnline = StepID(user: userID, id: "rustOnline")
                /// 端上和rust同时下线，端上的上线在Rust的上线后，所以理论上不存在端上在线, rust需要改变状态的情况..
                /// 另外端上下线重登后，rust也一定下线过了，不存在复用之前上线状态的情况..
                if oldState.native == newState.native {
                    if oldState.native == .offline { // 已经offline状态没有改变，不用处理
                        return
                    }
                    preconditionAlpha(oldState.rust != newState.rust, "native状态没有变化，rust的状态应该有变化。都没变化的不应该进来")
                    // 端上上线状态没有发生改变，那就是rust改变了. rust重新登录需要一起重登
                    // fallback to reonline
                    preconditionAlpha(oldState.rust == .offline, "expection case: rust should in offline state")
                }

                if oldState.native != .offline {
                    if shouldUnregisterPush(userID: userID, oldState: oldState, newState: newState) {
                        flow.next(id: StepID(user: userID, id: "nativeWillOffline")) { finish in
                            base.nativeWillOffline(
                                oldState: oldState.native, newState: newState.native
                            ) { finish(.success(())) }
                        }
                        flow.next(id: rustCanOffline)
                    }
                    flow.next(id: StepID(user: userID, id: "nativeOffline")) { finish in
                        base.nativeChangeState(from: oldState.native, to: .offline, finish: finish)
                    }
                    // 旧前台用户的容器在前台user变化后销毁
                    // 后台用户的容器可以在下线后马上销毁
                } // rustCanOffline没有加前置依赖，就相当于可以直接运行
                if newState.native != .offline {
                    let online = StepID(user: userID, id: "nativeOnline")
                    // fastLogin可能需要同时登录, 但也要等rust开始后才能进行, 以此保证rustClient的创建时机
                    // fastLogin也应该只有foreground这种性能敏感情况可以不等rust..
                    // 另外fastLogin需要在rust成功前就给出回调.. 目前由请求时给出不等的nowait参数进行控制, 这样可以保证rustService创建时序
                    graph.addEdge(from: rustOnline, to: online)
                    flow.next(id: online) { finish in
                        base.nativeChangeState(from: .offline, to: newState.native, finish: finish)
                    }
                }
            }

            fileprivate func patch(foregroundUserID: String) {
                let base = self.base
                graph.removeEdge(from: "backgroundStart", to: StepID(user: foregroundUserID, id: "start"))

                let end = StepID(user: foregroundUserID, id: "end")
                graph.addEdge(from: end, to: "backgroundStart")
                graph.update(id: end) { finish in
                    base.delegate.afterForegroundChange() // 目前先保证这个调用在background处理前
                    finish(.success(()))
                }
                // error wrapper
                graph.actions.keys.compactMap {
                    if case let id as StepID = $0, id.user == foregroundUserID {
                        return id
                    }
                    return nil
                }.forEach { graph.wrap(id: $0, action: base.foregroundErrorWrapper(action:)) }
            }
            fileprivate func patch(oldForegroundUserID: String) {
                let base = self.base
                graph.removeEdge(from: "backgroundStart", to: StepID(user: oldForegroundUserID, id: "start"))

                /// NOTE: 之前background只是时序依赖，但不关心结果是否成功，只要保证下线，都是可以继续运行的
                /// 所以在几个相关流程节点都检查一下状态是否发生了改变.
                let oldForegroundUserOffline = Future<Bool>()
                let oldForegroundUserDidOffline: () -> Bool = {
                    guard let state =
                        LarkContainerManager.shared.state.locking(action: { return $0.users[oldForegroundUserID] })
                    else { return true }
                    return !state.native.isForeground && !state.rust.isForeground
                }
                let runCheck = {
                    if oldForegroundUserDidOffline() {
                        oldForegroundUserOffline.fulfill(true)
                    }
                }
                let oldForegroundUserOnlineNotifyWrapper: (FlowGraph.Task?) -> FlowGraph.Task? = { old in
                    if let old {
                        return { cont, finish in
                            old(cont) {
                                runCheck() // 不关心成功失败，下线保证强制重置到下线状态.
                                finish($0)
                            }
                        }
                    } else {
                        return { _, finish in
                            runCheck()
                            finish(.success(()))
                        }
                    }
                }
                /// rust的Offline要等端上的can offline，所以最终是保证都offline了
                graph.wrap(id: StepID(user: oldForegroundUserID, id: "rustChangeState"),
                           action: oldForegroundUserOnlineNotifyWrapper)
                graph.wrap(id: StepID(user: oldForegroundUserID, id: "rustOffline"),
                           action: oldForegroundUserOnlineNotifyWrapper)
                graph.wrap(id: StepID(user: oldForegroundUserID, id: "nativeOffline"),
                           action: oldForegroundUserOnlineNotifyWrapper)
                // 可能都已经下线了，但上线失败，没有清理oldForegroundUserID, 重新进来. 这样上面的条件都不会被触发..
                DispatchQueue.global(qos: .userInitiated).async {
                    // 延迟避免死锁
                    runCheck()
                }
                // NOTE: 当前oldForegroundUserID的变化:
                // 1. 如果只是下线，在rust和native都下线完成后，追加清理为nil(placeholderUser)的逻辑和通知
                // 2. 如果要上线，在native上线后，业务通知前统一变化
                // 3. 上线场景，可能切换时下线成功，上线失败, 停留在当前用户下线状态, 这时不会清理
                if let foregroundUserID = newForegroundUserID {
                    graph.update(id: StepID(user: foregroundUserID, id: "rustStart")) { cont, finish in
                        cont.wait(id: "oldForegroundUser offline",
                                  when: { cont in oldForegroundUserOffline.wait { _ in cont() } },
                                  next: { finish(.success(())) })
                    }
                } else {
                    // 只有当前用户下线, 在当前用户下线后即可开始后台任务
                    graph.update(id: "foregroundOffline") { cont, finish in
                        // 修改当前用户至nil...
                        cont.wait(id: "oldForegroundUser offline",
                                  when: { cont in oldForegroundUserOffline.wait { _ in cont() } },
                                  next: { base.foregroundOfflineToNil(oldForegroundUserID: oldForegroundUserID, finish: finish) })
                    }
                    graph.addEdge(from: "foregroundOffline", to: "backgroundStart")
                }
                // 如果是前台变全后台的场景，上线也需要等端上的offline完成后，避免currentUserID指向后台用户
                // NOTE: 还有session变化，自己切自己的场景, 但这种情况oldID一致会被拦截不会走这里的逻辑
                graph.addEdge(from: "backgroundStart", to: StepID(user: oldForegroundUserID, id: "nativeOnline"))
            }
            fileprivate func wrapBackgroundStart(old: FlowGraph.Task?, waitFastLogin: Bool) -> FlowGraph.Task? {
                let base = self.base
                var actions: [FlowGraph.Task] = [ { (_, finish) in
                    /// 多用户启动时可能比较耗时，后台登录延后到特定时机后..
                    if waitFastLogin {
                        notify(when: { NewBootManager.shared.context.hasFirstRender || (try? base.checkInterrupt()) != nil },
                            interval: 0.01, timeout: 20,
                            action: { _ in
                            finish(.init { try base.checkInterrupt() })
                        })
                    } else {
                        finish(.init { try base.checkInterrupt() })
                    }}]
                if let old { actions.append(old) }
                return FlowGraph.serialWhenSuccess(tasks: actions)
            }

            lazy var offlineAllBackgroundUser: Bool = {
                /// newStates状态一致的会被清理，所以用userList判断无后台
                !base.userList.contains {
                    newStates[$0.userID]?.native.bridge() == .backgroundOnline
                }
            }()
            func shouldUnregisterPush(userID: String, oldState: UserState, newState: UserState) -> Bool {
                #if LarkPushTokenUploader
                // 后台下线场景（最终没有online）且非session失效，且没有前台相关的token注销，进行pushToken的取消。
                if case .background = oldState.native, newState.native == .offline {
                    if let oldForegroundUserID, oldForegroundUserID != newForegroundUserID {
                        // 前台用户有下线场景下会换token，不需要解绑
                        return false
                    }
                    if base.action == .settingsMultiUserUpdating, offlineAllBackgroundUser {
                        // 切换配置导致全部下线时，会换token，不需要解绑
                        return false
                    }
                    if userSessionInvalid(userID: userID) {
                        // session失效时也不用上报了
                        return false
                    }
                    return true
                }
                #endif
                return false
            }
            /// 是否session已经失效，需要实时的到passport取最新的状态
            @InjectedUnsafeLazy var passport: PassportService
            func userSessionInvalid(userID: String) -> Bool {
                guard let user = passport.getUser(userID) else {
                    LarkContainerManager.logger.warn("can't get passportUserService",
                                                     additionalData: ["userID": userID])
                    return false
                }
                return user.userStatus == .invalid
            }
        }
        func foregroundErrorWrapper(action: FlowGraph.Task?) -> FlowGraph.Task? {
            guard let action else { return nil } // 没有action的不会错误不用管
            return { cont, finish in
                action(cont) { finish($0.mapError {
                    self.interrupted()
                    return LarkContainerManagerFlowError.foregroundOnlineFailed($0)
                })}
            }
        }

        // MARK: Actions
        // diff状态并决定此次flow的步骤
        func nativeWillOffline(oldState: ContainerState, newState: ContainerState,
                               finish: @escaping FinishCallbackNoThrow<Void>) {
            // 调用登出前的一些准备方法，目前只有注销push token
            #if LarkPushTokenUploader
            guard let userID = oldState.user?.userID,
                let userResolver = try? Container.shared.getUserResolver(userID: userID, type: .background)
            else {
                LarkContainerManager.logger.warn("can't get userResolver in nativeWillOffline!")
                return finish(())
            }
            guard let push = try? userResolver.resolve(type: LarkBackgroundUserResetTokenService.self)
            else { return finish(()) }
            LarkContainerManager.logger.info("unregister push token", additionalData: ["userID": userID])
            push.backgroundUserWillOffline(userId: userID) { finish(()) }
            #else
            finish(())
            #endif
        }
        func foregroundOfflineToNil(oldForegroundUserID: String, finish: @escaping FinishCallback<Void>) {
            // NOTE: offline没有支持失败
            LarkContainerManager.logger.info("foreground user will change to nil")
            @Injected var passport: PassportContainerAfterRustOnlineWorkflow
            passport.runlogoutForgroundUserWorkflow {
                DispatchQueue.main.async {
                    defer { LarkContainerManager.logger.info("foreground user did change to nil") }
                    // 修改到nil再上报一次当前用户的变化
                    let newState = PassportState(user: nil, loginState: .offline, action: self.action)
                    let factories = PassportDelegateRegistry.factories()
                    factories.map { $0.delegate }.forEach {
                        $0.stateDidChange(state: newState)
                    }
                    // 容器跟随修改foreground, 避免nil时没有用户容器，使用
                    // 占位的不用创建，会通过currentUserID, lazy获取
                    UserStorageManager.shared.currentUserID = UserStorageManager.placeholderUserID
                    UserStorageManager.shared.disposeStorage(userID: oldForegroundUserID)
                    @Injected var rustClient: LarkRustClient // global
                    rustClient.didOfflineForegroundRustService(userID: oldForegroundUserID)

                    LarkContainerManager.shared.state.modify {
                        $0.foregroundUserID = nil
                    }

                    self.delegate.afterForegroundChange()
                    // 无论成功失败，最终状态都是offline，但错误正常回应给passport
                    finish(.success(()))
                }}
        }
        func nativeChangeState(from: ContainerState, to: ContainerState, finish: @escaping FinishCallback<Void>) {
            if from == to {
                preconditionAlpha(false, "state not change shouldn't enter here")
                finish(.success(()))
                return
            }
            @Injected var rustClient: LarkRustClient // global
            func online(finish: @escaping FinishCallback<Void>) {
                guard let user = to.user else { return }
                let userID = user.userID
                let foreground = to.isForeground

                LarkContainerManager.shared.state.modify {
                    $0.users[userID, default: .init()].rustOnlinePaired = true
                }
                /// 这里online，旧的offline应该已经执行过了..，所以可以替换的同时进行storage的清理
                UserStorageManager.shared.makeStorage(userID: userID, type: foreground ? .foreground : .background)
                // NOTE: online需要保证在rust online后(创建了Service)
                rustClient.didOnlineRustService(userID: userID, foreground: foreground)
                if foreground {
                    // TODO: LauncherDelegate的回调写法
                    // TODO: BootManager回调兼容
                    LarkContainerManager.logger.info("foreground user \(userID) will Online")
                    @Injected var passport: PassportContainerAfterRustOnlineWorkflow
                    passport.runForgroundUserChangeWorkflow(action: self.action, foregroundUser: user) { (result) in
                        guard case .success = result else {
                            // NOTE: 正常这里不应该失败, 上面已经上线的状态进行下线..(但onlinePaired已经被消耗了)
                            rustClient.didOfflineRustService(userID: userID, foreground: foreground)
                            rustClient.didOfflineForegroundRustService(userID: userID)
                            UserStorageManager.shared.disposeStorage(userID: userID)
                            return finish(result)
                        }
                        DispatchQueue.main.async {
                            defer {
                                LarkContainerManager.logger.info("foreground user \(userID) did Online")
                                finish(result)
                            }

                            UserStorageManager.shared.currentUserID = userID
                            let oldForegroundUserID = LarkContainerManager.shared.state.locking { $0.foregroundUserID }
                                ?? UserStorageManager.placeholderUserID
                            if oldForegroundUserID != userID {
                                // 清理旧前台用户的容器, 前台上线时旧前台用户已经下线过了
                                UserStorageManager.shared.disposeStorage(userID: oldForegroundUserID)
                            }

                            let newState = PassportState(user: user, loginState: .online, action: self.action)
                            let factories = PassportDelegateRegistry.factories()
                            factories.map { $0.delegate }.forEach {
                                $0.stateDidChange(state: newState)
                                $0.userDidOnline(state: newState)
                            }

                            LarkContainerManager.shared.state.modify {
                                $0.foregroundUserID = userID
                                $0.users[userID, default: .init()].native = to
                            }
                        }
                    }
                } else {
                    LarkContainerManager.logger.info("background user \(userID) will Online")
                    defer {
                        LarkContainerManager.logger.info("background user \(userID) did Online")

                        rustClient.loginFinish(userID: userID) // foreground called by BootManager
                        finish(.success(()))
                    }

                    let newState = PassportState(user: user, loginState: .online, action: self.action)
                    let factories = PassportDelegateRegistry.factories()
                    factories.map { $0.delegate }.forEach {
                        $0.backgroundStateDidChange(state: newState)
                        $0.backgroundUserDidOnline(state: newState)
                    }

                    LarkContainerManager.shared.state.modify {
                        $0.users[userID, default: .init()].native = to
                    }
                }
            }
            // switch和offline场景，需要保证rust能拿到旧的state, 并填上对应的containerID
            func offline(finish: @escaping FinishCallback<Void>) {
                guard let user = from.user else { return }
                let userID = user.userID
                let foreground = from.isForeground

                let newState = PassportState(user: user, loginState: .offline, action: self.action)
                let factories = PassportDelegateRegistry.factories()

                // offline这里没改currentUserID，外面调度判断仅offline时再改currentUserID
                if foreground {
                    // 前台用户相关的通知保证在主线程进行，避免潜在的UI和线程安全问题
                    DispatchQueue.main.async {
                        // NOTE: 按原来的逻辑，应该在这里执行当前user的下线清理, 但现在统一在结束后`foregroundOfflineToNil`处理
                        // 所以这里需要区分有不有后续的步骤
                        LarkContainerManager.logger.info("foreground user \(userID) will Offline")
                        defer {
                            LarkContainerManager.logger.info("foreground user \(userID) did Offline")
                            finish(.success(()))
                        }

                        factories.map { $0.delegate }.forEach {
                            $0.stateDidChange(state: newState)
                            $0.userDidOffline(state: newState)
                        }
                        // 容器正常offline结束就应该清理，但是foregroundUser还有引用，所以延迟到该当前userID的地方..
                        didOffline()
                    }
                } else {
                    LarkContainerManager.logger.info("background user \(userID) will Offline")
                    defer {
                        LarkContainerManager.logger.info("background user \(userID) did Offline")
                        finish(.success(()))
                    }

                    factories.map { $0.delegate }.forEach {
                        $0.backgroundStateDidChange(state: newState)
                        $0.backgroundUserDidOffline(state: newState)
                    }

                    UserStorageManager.shared.disposeStorage(userID: userID)
                    didOffline()
                }
                func didOffline() {
                    rustClient.didOfflineRustService(userID: userID, foreground: foreground)
                    UserTask.shared.offline(userID: userID)
                    LarkContainerManager.shared.state.nativeOffline(userID: userID)
                }
            }
            switch (from, to) {
            case (.offline, _): online(finish: finish)
            case (_, .offline): offline(finish: finish)
            default:
                preconditionAlpha(false, "native can only support change between offline and online")
                var action: [(@escaping FinishCallback<Void>) -> Void] = []
                if from != .offline { action.append(offline(finish:)) }
                if to != .offline { action.append(online(finish:)) }
                LarkContainerManager.serialWhenSuccess(actions: action)(finish)
            }
        }
        func rustChangeState(from: ContainerState, to: ContainerState, finish: @escaping FinishCallback<Void>) {
            if from == to {
                preconditionAlpha(false, "state not change shouldn't enter here")
                finish(.success(()))
            }
            @Injected var rustClient: LarkRustClient // global
            func online(userID: String, action: (@escaping (Result<Void, LarkRustClient.LifeCycleError>) -> Void) -> Void) { // or switch
                LarkContainerManager.shared.state.modify {
                    $0.users[userID, default: .init()].rustOnlinePaired = false
                }
                action { result in
                    switch result {
                    case .success:
                        LarkContainerManager.shared.state.modify {
                            $0.users[userID, default: .init()].rust = to
                        }
                        finish(.success(()))
                    case .failure(let error):
                        if case .rust = error {
                            /// rust上线错误，应该是offline状态。这里强制offline保证对齐状态预期..
                            /// 没有正确online，设置上containerID也算是rust的错误, 需要强制下线兜底
                        } else {
                            preconditionAlpha(false, "不应该有其他类型的错误!!")
                            // NOTE: 其他错误没有到rust，不应该出现，还是兜底到offline状态比较保险
                        }
                        rustClient.makeUserOffline(userID: userID, priorState: .offline, forceOffline: true) { _ in
                            LarkContainerManager.shared.state.rustOffline(userID: userID)
                            finish(.failure(error))
                        }
                    }
                }
            }
            switch (from, to) {
            case (.offline, _):
                guard let user = to.user else { finish(.failure(ErrorMessage("no user"))); return }
                let foreground = to.isForeground
                online(userID: user.userID) { (finish) in
                    // fastLogin不等rust返回结果，但需要保证rustService的正常创建和端上请求的拦截
                    var nowait = foreground && self.action == .fastLogin
                    var finishOnline = finish
                    var featureGatingSyncScene: FeatureGatingSyncScene = nowait ? .notSyncUpdate : .firstLogin
                    if nowait { // 升级版本首次fastLogin需要等待online成功并加载FG&Settings
                        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
                        let lastVersion = UserDefaults.standard.string(forKey: "LK.fastLoginLastVersion")
                        if lastVersion != appVersion {
                            LarkContainerManager.logger.info("upgrade app version. fastLogin will wait online.")
                            nowait = false
                            featureGatingSyncScene = .upgradeVersion
                            finishOnline = { result in
                                if case .success = result {
                                    UserDefaults.standard.set(appVersion, forKey: "LK.fastLoginLastVersion")
                                }
                                /// fastLogin失败也无法处理。目前和passport协商结果是让其始终成功，和现状保持一致..
                                finish(.success(()))
                            }
                        }
                    }
                    FeatureGatingSyncEventCollector.shared.syncScene(user.userID, featureGatingSyncScene)
                    rustClient.makeUserOnline(user: user, foreground: foreground, nowait: nowait,
                                              priorState: .offline, callback: finishOnline)
                }
            case (_, .offline):
                guard let user = from.user else { finish(.failure(ErrorMessage("no user"))); return }
                let userID = user.userID
                rustClient.makeUserOffline(userID: userID, priorState: from.bridge()) { result in
                    LarkContainerManager.shared.state.rustOffline(userID: userID)
                    finish(result.mapError { $0 })
                }
            case let (_, to): // foreground <-> background online
                guard let user = to.user else { finish(.failure(ErrorMessage("no user"))); return }
                online(userID: user.userID) { finish in
                    rustClient.switchUserState(user: user, state: to.bridge(), callback: finish)
                }
            }
        }
    }
    struct StepID: Hashable, CustomDebugStringConvertible {
        var user: String
        var id: String
        var debugDescription: String { "Step \(id): \(user)" }
    }
    struct ErrorMessage: Error {
        internal init(_ message: String) {
            self.message = message
        }
        var message: String
    }
    /// 流程图，方便指定和修改依赖关系
    class FlowGraph: CustomDebugStringConvertible {
        typealias ID = AnyHashable // swiftlint:disable:this all
        /// 流程节点。节点可能包含action，也可能只是一个依赖时机节点
        /// 没有前置依赖的节点，即可以直接运行
        typealias Task = (_ context: TaskContext, _ finish: @escaping FinishCallback<Void>) -> Void
        static func serialWhenSuccess(tasks: [Task]) -> Task {
            switch tasks.count {
            case 1: return tasks[0]
            default:
                // build action from last to first, so when call, will be first to last
                var it = tasks.reversed().makeIterator()
                guard var action = it.next() else { return { $1(.success(())) } }
                while let previous = it.next() {
                    action = { [next = action](cont, finish) in
                        previous(cont) {
                            switch $0 {
                            case .success: next(cont, finish)
                            case .failure: finish($0)
                            }
                        }
                    }
                }
                return action
            }
        }

        struct Vertex {
            var task: Task?
            // set保证没有重复依赖
            var successors: Set<ID> = []
            var predecessors: Set<ID> = []
        }
        // NOTE: 注意线程安全和循环依赖。另外运行时需要即时清理已经运行过的结点, 释放捕获的内存
        // Vertex结点需要自动lazy创建, 这样可以分开指定action和依赖关系
        private(set) var actions: [ID: Vertex] = [:]
        /// return actions id with no predecessors
        func rootActions() -> Set<ID> {
            actions.reduce(into: Set()) { (s, pair) in
                if pair.value.predecessors.isEmpty {
                    s.update(with: pair.key)
                }
            }
        }
        func update(id: ID, action: @escaping Action) {
            update(id: id, task: { action($1) })
        }
        func update(id: ID, task: @escaping Task) {
            actions[id, default: .init()].task = task
        }
        func update(parent: ID?, id: ID, action: @escaping Action) {
            actions[id, default: .init()].task = { action($1) }
            if let parent {
                addEdge(from: parent, to: id)
            }
        }
        /// modify old action, no-op when no this id
        func wrap(id: ID, action: (Task?) -> Task?) {
            if var vertex = actions[id] {
                vertex.task = action(vertex.task)
                actions[id] = vertex
            }
        }
        /// the removed vertex is a copy of original. the successors and predecessors is old state and not paired..
        func remove(id: ID) -> Vertex? {
            guard let vertex = actions.removeValue(forKey: id) else { return nil }
            vertex.successors.forEach { actions[$0]?.predecessors.remove(id) }
            vertex.predecessors.forEach { actions[$0]?.successors.remove(id) }
            return vertex
        }
        func addEdge(from: ID, to: ID) {
            // remove to avoid COW
            var fromV = actions.removeValue(forKey: from) ?? .init()
            var toV = actions.removeValue(forKey: to) ?? .init()
            fromV.successors.insert(to)
            toV.predecessors.insert(from)
            actions[from] = fromV
            actions[to] = toV
        }
        func removeEdge(from: ID, to: ID) {
            guard var fromV = actions[from], var toV = actions[to] else { return }
            // remove to avoid COW
            actions.removeValue(forKey: from)
            actions.removeValue(forKey: to)
            fromV.successors.remove(to)
            toV.predecessors.remove(from)
            actions[from] = fromV
            actions[to] = toV
        }

        /// 用于快速建立顺序依赖关系和action的辅助类
        struct FlowBuilder {
            var base: FlowGraph
            var current: ID
            mutating func next(id: ID, action: Action? = nil) {
                if let action {
                    base.update(id: id, action: action)
                }
                base.addEdge(from: current, to: id)
                current = id
            }
        }
        func flow(start: ID) -> FlowBuilder {
            return .init(base: self, current: start)
        }
        var debugDescription: String {
            var desc = "<FlowGraph>:\n"
            for i in actions {
                desc.append("Flow \(i.key) -> \(i.value.predecessors.map { $0.description })\n")
            }
            return desc
        }
    }
    typealias FinishCallback<R> = (Result<R, Error>) -> Void
    typealias FinishCallbackNoThrow<R> = (R) -> Void
    // TODO: 需要保证finish只有一次.. 但是finish还可能发出特殊的control，那样会有多次..
    typealias Action = (_ finish: @escaping FinishCallback<Void>) -> Void
    /// merge multiple actions into a single action
    static func serialWhenSuccess(actions: [Action]) -> Action {
        switch actions.count {
        case 1: return actions[0]
        default:
            // build action from last to first, so when call, will be first to last
            var it = actions.reversed().makeIterator()
            guard var action = it.next() else { return { $0(.success(())) } }
            while let previous = it.next() {
                action = { [next = action](finish) in
                    previous {
                        switch $0 {
                        case .success: next(finish)
                        case .failure: finish($0)
                        }
                    }
                }
            }
            return action
        }
    }
    /// a simple Future Value wrapper
    class Future<T> {
        enum Either {
        case observers([(T) -> Void])
        case value(T)
        }
        fileprivate var storage: Either = .observers([])
        fileprivate var lock = UnfairLockCell()
        deinit {
            lock.deallocate()
        }
        /// get value immediately, or wait notify
        func wait(_ observer: @escaping (T) -> Void) {
            lock.lock()
            switch storage {
            case .value(let v):
                lock.unlock()
                observer(v)
            case .observers(var observers):
                storage = .observers([]) // release old array, avoid copy
                observers.append(observer)
                storage = .observers(observers)
                lock.unlock()
            }
        }
        func fulfill(_ value: T) {
            lock.lock()
            let obsevers = _fulfill(value)
            lock.unlock()
            obsevers.forEach { $0(value) }
        }
        private func _fulfill(_ value: T) -> [(T) -> Void] {
            switch storage {
            case .value:
                storage = .value(value)
                return [] // already fulfilled, only change it
            case .observers(let observers):
                storage = .value(value)
                return observers
            }
        }
    }
    class CanncelableFuture<V>: Future<Result<V, Error>> {
        struct Cancel: Error { }
        deinit {
            switch storage {
            case .observers(let observers):
                let value = Result<V, Error>.failure(Cancel())
                observers.forEach { $0(value) }
            default: break
            }
        }
        func cancel() {
            lock.lock()
            switch storage {
            case .observers(let observers):
                let value = Result<V, Error>.failure(Cancel())
                storage = .value(value)
                lock.unlock()
                observers.forEach { $0(value) }
            default:
                lock.unlock()
            }
        }
    }
}

protocol TaskContext {
    /// 用于通知流程总控, 等待特定条件后运行。避免发出信号因为异步晚于调度，而被认为阻塞finish的情况. 这样可以识别卡住未完结的任务
    func wait(id: String, when: @escaping (_ cont: @escaping () -> Void) -> Void, next: @escaping () -> Void)
}
