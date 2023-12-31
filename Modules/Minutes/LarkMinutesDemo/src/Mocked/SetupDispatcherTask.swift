//
//  SetupDispatcherTask.swift
//  LarkBaseService
//
//  Created by KT on 2020/7/1.
//

import Foundation
import BootManager
import AppContainer
import RunloopTools
import LarkMonitor
import LarkContainer
import LarkRustClient
import RustPB
import RxSwift

//class SetupDispatcherTask: FlowBootTask, Identifiable {
//    static var identify = "SetupDispatcherTask"
//
//    private let disposeBag = DisposeBag()
//
//    @InjectedLazy private var rustClient: RustService
//
//    override var runOnlyOnceInUserScope: Bool { return false }
//
//    override func execute(_ context: BootContext) {
//        RunloopDispatcher.enable = true
//
//        let checker = DispatcherCPUChecker()
//        RunloopDispatcher.shared.addCommitChecker(checker)
//        RunloopDispatcher.shared.addObserver(checker)
//
//        RunloopDispatcher.shared.addTask(
//            priority: .required,
//            scope: .user,
//            identify: "afterFirstRender") {
//                self.noticeRustFirstRender()
//
//            NewBootManager.shared.trigger(with: .afterFirstRender, contextID: context.contextID)
//        }
//
//        RunloopDispatcher.shared.addTask(
//            priority: .required,
//            scope: .user,
//            identify: "idle") {
//            NewBootManager.shared.trigger(with: .idle, contextID: context.contextID)
//        }.waitCPUFree()
//    }
//
//    // 通知Rust首屏渲染完成
//    private func noticeRustFirstRender() {
//        var request = RustPB.Basic_V1_NoticeClientEventRequest()
//        request.event = .firstScreenFinished
//        rustClient.sendAsyncRequest(request).subscribe().disposed(by: disposeBag)
//    }
//}
//
//public class DispatcherCPUChecker: DispatcherChecker, RunloopDispatcherResponseable {
//    private var cpu: CPU?
//    private let initTime = CACurrentMediaTime()
//
//    public func didRemoveTriggerObserver() {
//        guard let cpu = self.cpu else { return }
//        LKCExceptionCPUMonitor.unRegistCallback(cpu.monitor)
//        self.cpu = nil
//    }
//
//    init() { }
//    public func enable(task: Task) -> Bool {
//        guard self.afterLauncher else { return false }
//        self.setupCPUMonitorIfNeeded()
//        guard let value = self.cpu?.cpuPercentage else { return false }
//        return value < CPU.threshold
//    }
//
//    private func setupCPUMonitorIfNeeded() {
//        guard self.cpu == nil else { return }
//        let monitor = LKCExceptionCPUMonitor.registCallback({ [weak self] (value) in
//            self?.cpu?.value = value
//        }, timeInterval: CPU.sample)
//        self.cpu = CPU(monitor: monitor)
//    }
//
//    // 启动不监测CPU，错开启动高峰期
//    private var afterLauncher: Bool {
//        if _afterLauncher { return true }
//        if CACurrentMediaTime() - initTime > CPU.afterLaunchInterval {
//            _afterLauncher = true
//            return true
//        }
//        return false
//    }
//    // 避免每次比较时间，存变量
//    private var _afterLauncher: Bool = false
//}
//
//class CPU {
//    /// CPU空闲的标准
//    static let threshold = 0.1
//
//    /// CPU采样间隔
//    static let sample: Int32 = 1
//
//    /// 启动至少等待3s再执行
//    static let afterLaunchInterval: CFTimeInterval = 3
//
//    let monitor: Any   // LKCExceptionCPUMonitor.callback
//    var value: Double? // all threads cpu_usage
//
//    /// 所有线程cpu_usage/CPU核数，反应整体CPU使用水平
//    var cpuPercentage: Double? {
//        guard let value = value else { return nil }
//        return value / Double(core)
//    }
//
//    /// 当前CPU核数
//    lazy var core: Int = {
//        return ProcessInfo.processInfo.activeProcessorCount
//    }()
//
//    init(monitor: Any) {
//        self.monitor = monitor
//    }
//}
