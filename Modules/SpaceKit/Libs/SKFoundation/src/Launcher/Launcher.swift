//
//  Launcher.swift
//  Launcher
//
//  Created by nine on 2019/12/30.
//  Copyright © 2019 nine. All rights reserved.
//

import Foundation

public final class Launcher {
    public static let shared = Launcher()

    private let queue = LauncherQueue()
    private let observerManager = LauncherObserverManager()
    private(set) var state: LauncherState = .ready
    public let config = LauncherConfig()

    public func kickOff() {
        Launcher.shared.info("【DocsLauncher】Launcher kickOff")
        // execute sync stage in current Thread
        state = .executeSyncWork
        queue.syncStages.filter({ $0.state == .ready }).forEach { (syncStage) in
            syncStage.kickoff()
        }
        state = .ready
        // execute async stage in other Threads,
        observerManager.delegate = self
        observerManager.startObserver()
    }

    public func addSync(_ stage: StageNode) {
        DocsLogger.info("【DocsLauncher】Launcher addSync \(stage.identifier)")
        queue.syncStages.append(stage)
    }

    
    /// 注意只在启动阶段使用，其它都使用RunloopDispatcher
    public func addAsync(_ stage: AsyncStageNode) {
        DocsLogger.info("【DocsLauncher】Launcher addAsync \(stage.identifier)")
        queue.asyncStages.append(stage)
    }

    public func shutdown() {
        state = .done
        queue.syncStages.forEach { (stage) in
            stage.shutdown()
        }
        queue.syncStages.removeAll()
        queue.asyncStages.forEach { (stage) in
            stage.shutdown()
        }
        queue.asyncStages.removeAll()
        observerManager.stopObserver()
    }

    public init() {}
}

extension Launcher: LauncherObserverManagerDelegate {
    func launcherState() -> LauncherState {
        return state
    }

    func checkStageIsReady(with isLeisure: Bool) {
        DocsLogger.info("【DocsLauncher】 checkStageIsReady")
        let runningStages = queue.asyncStages.filter { $0.state == .running }
        // Make sure no other tasks are being execute
        guard state != .executeSyncWork, state != .done, runningStages.isEmpty else {
            DocsLogger.info("【DocsLauncher】 some stage is running")
            return
        }
        let readyedStages = queue.asyncStages.filter { $0.state == .ready }
        // stopObserver if not have task.
        guard !readyedStages.isEmpty else {
            DocsLogger.info("【DocsLauncher】 all stage is done")
            state = .done
            // 统一放在主线程去做取消
            self.observerManager.stopObserver()
            return
        }
        // Prioritize execute task that not need leisure
        var targetStage: StageNode?
        targetStage = readyedStages.first(where: { $0.isLeisureStage == false })
        // Execute leisure stage if current not have stage that not need leisure
        if isLeisure && targetStage == nil {
            targetStage = readyedStages.first(where: { $0.isLeisureStage == true })
        }
        if targetStage != nil {
            state = .executeAsyncWork
            targetStage?.kickoff()
            targetStage?.finishCallBack = {
                self.state = .ready
            }
        } else {
            DocsLogger.info("【DocsLauncher】 nothing to run")
        }
    }
}
