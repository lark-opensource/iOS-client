//
//  BootTask.swift
//  BootManager
//
//  Created by sniperj on 2021/4/19.
//

import Foundation
import RunloopTools
import LarkPreload

/// Task 唯一标识¨
public typealias TaskIdentify = String

/// Task执行状态
public enum TaskState: String {
    /// enqueue待执行
    case none
    /// 开始执行run()
    case start
    /// 执行完毕，开始下一任务
    case end
    /// AsyncTask等待信号返回
    case await
    /// BranchTask离开主流程分支
    case checkout
}

/// Task必须提供Identify
public protocol Identifiable {
    /// 唯一标识，配置在plist内，决定执行位置
    static var identify: TaskIdentify { get }
}

/// 任务执行的队列，默认主队列
public enum Scheduler {
    /// 主队列，默认
    case main
    /// 子队列，并发
    case concurrent
    /// 子队列，串行
    case async
}

/// 延迟任务执行的时机
public enum DelayType: String {
    case delayForFirstRender
    case delayForIdle
}

/// 任务基类，外界不能直接继承
open class BootTask {
    // MARK: - Public

    /// 如果提供了Scope，和当前launchOption符合时同步执行，否则延后到首屏
    open var scope: Set<BizScope> { return [] }

    /// App生命周期，是否只执行一次
    open var runOnlyOnce: Bool { return false }

    /// User生命周期，是否只执行一次
    open var runOnlyOnceInUserScope: Bool { return true }

    /// 延迟任务的生命周期，如果是user级别，延迟任务在切租户时会被丢弃
    open var delayScope: RunloopTools.Scope? { return nil }

    /// 延迟任务的优先级
    open var priority: RunloopTools.Priority? { return nil }

    /// 执行线程
    open var scheduler: Scheduler { return .main }

    /// 如果Task里面需要持续监听事件，可以用 deamon = true
    open var deamon: Bool { return false }

    /// 被框架延迟的任务，在哪个阶段执行
    open var delayType: DelayType? { return .delayForFirstRender }
    
    /// 是否是懒加载的task
    open var isLazyTask: Bool { return false }
    
    /// 是否有命中反馈- 仅闲时任务生效，有命中反馈需要调用命中反馈接口。
    open var hasFeedback: Bool { return false }
    
    /// 不受预加载框架调度
    open var forbiddenPreload: Bool { return false }
    
    /// 指定触发时机-使用方式联系 huanglx
    open var triggerMonent: PreloadMoment { return PreloadMoment.none}

    /// 当前Task执行状态
    internal(set) public var state: TaskState = .none {
        didSet {
            guard oldValue != state else { return }
            printVerbose("[Info] Task(\(identify)) state \(oldValue) => \(state) on thread \(Thread.current)")
            BootMonitor.shared.update(task: self, old: oldValue, new: state)
        }
    }

    internal var isFirstTabPreLoad: Bool { return false }

    /// 首Tab预加载服务，需要绑定的Tab url
    open var firstTabURLString: String { fatalError("must override") }

    /// Task具体任务
    open func execute(_ context: BootContext) { fatalError("must override") }

    /// Task的启动器
    weak var launcher: Launcher?

    /// init

    @available(*, deprecated, message: "废弃的init方法，待所有子类的继承方法去掉后废弃")
    /// 不推荐覆盖init方法，required方法的废弃很麻烦，一定会打破源码兼容性。留着也会有额外的覆盖要求
    /// 需要初始化注入新环境变量的，可以初始化后属性赋值注入..
    required public init() {}
    required public convenience init(context: BootContext) throws {
        self.init()
    }

    // MARK: - Internal

    /// 由Flow调用，负责状态的周转
    final internal func run() {
        assert(Thread.isMainThread, "should occur on main thread!")
        // 一个Task只能run一次
        guard self.state == .none else { return }

        // 只执行一次的Task，缓存TaskIdentify
        if self.runOnlyOnce {
            NewBootManager.shared.globalTaskRepo.onceTasks.insert(identify)
        } else if self.runOnlyOnceInUserScope {
            NewBootManager.shared.globalTaskRepo.onceUserScopeTasks.insert(identify)
        }
        _run()
    }
    // override by subclass
    internal func _run() { fatalError("override by subclass") } // swiftlint:disable:this all

    /// 执行Task队列
    internal func scheduleTask() {
        NewBootManager.shared.scheduler.scheduler(self)
    }

    internal weak var flow: BootFlow?

    internal func `contiune`() {
        self.flow?.executeFlow()
    }

    // TaskID，在TaskRegistry中绑定
    internal var identify: TaskIdentify!
}

extension BootTask {
    func runFlow() {
        self.state = .start
        self.scheduleTask()
        self.state = .end
    }
    func runBranch() {
        self.state = .start
        self.scheduleTask()

        // 如果没有checkout，说明是同步执行完成
        // FIXME: 可能不是同步checkout.., 需要assertMain
        if self.state != .checkout {
            self.state = .end
        }
    }
}

extension DispatchQueue {
    /// 确保在主队列，如果当前是主队列，不执行async
    @inline(__always)
    func mainAsyncIfNeeded(_ block: @escaping () -> Void) {
        if self === DispatchQueue.main && Thread.isMainThread {
            block()
        } else {
            async { block() }
        }
    }
}

@inlinable
func printVerbose(_ msg: @autoclosure () -> String) {
}
