//
//  LauncherObserver.swift
//  Launcher
//
//  Created by nine on 2020/1/2.
//  Copyright © 2020 nine. All rights reserved.
//

import Foundation

protocol LauncherObserverManagerDelegate: AnyObject {
    func checkStageIsReady(with isLeisure: Bool)
    func launcherState() -> LauncherState
}

protocol LauncherObserver {
    var identifier: LauncherSystemStateKey { get set }
    func reset()
    func isLeisure() -> Bool
    func clear()
}

class LauncherObserverManager: NSObject {
    var observers = [LauncherObserver]()
    weak var delegate: LauncherObserverManagerDelegate?
    let dispatchQueue = DispatchQueue(label: "com.bytedance.docs.launcherObserverManager")
    var timer: Timer?
    var isObserving = false
    var isCancel = false

    override init() {
        super.init()
        observers.append(CPULauncherObserver())
    }

    func startObserver() {
        if isObserving {
            DocsLogger.info("【DocsLauncher】Launcher startObserver, Observing already")
            return
        }
        DocsLogger.info("【DocsLauncher】Launcher startObserver")
        resetObserver()
        self.isCancel = false
        dispatchQueue.async {
            self.isObserving = true
            DocsLogger.info("【DocsLauncher】create timer")
            self.timer = Timer(timeInterval: Launcher.shared.config.monitorInterval, repeats: true) { [weak self] (_) in
                guard let self = self else { return }
                guard self.isCancel == false else {
                    DocsLogger.info("【DocsLauncher】isCancel, stop timer")
                    self.timer?.invalidate()
                    self.timer = nil
                    CFRunLoopStop(CFRunLoopGetCurrent())
                    return
                }
                self.runTask()
            }
            
            if let t = self.timer {
                //https://juejin.cn/post/6844903486677581831
                RunLoop.current.add(t, forMode: .common)
                RunLoop.current.run(until: .distantFuture)
            }
            self.isObserving = false
            DocsLogger.info("【DocsLauncher】RunLoop exit")
        }
    }

    func stopObserver() {
        DocsLogger.info("【DocsLauncher】Launcher stopObserver")
        self.isCancel = true
        clearObserver()
    }

    private func resetObserver() {
        for observer in observers {
            observer.reset()
        }
    }

    private func clearObserver() {
        for observer in observers {
            observer.clear()
        }
    }

    func runTask() {
        guard let launcherState = delegate?.launcherState(), launcherState == .ready else {
            DocsLogger.info("【DocsLauncher】runTask but not ready")
            return
        }
        var isLeisure = true
        // Determine current is Leisure
        for observer in observers {
            guard isLeisure else { return }
            isLeisure = isLeisure && observer.isLeisure()
        }
        // Notice Launcher current is Leisure
        delegate?.checkStageIsReady(with: isLeisure)
    }
}
