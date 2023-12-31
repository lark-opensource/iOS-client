//
//  SwitchUserTask.swift
//  LarkAccount
//
//  Created by bytedance on 2021/8/31.
//

import Foundation
import LKCommonsLogging
import ThreadSafeDataStructure

enum SwitchUserTaskStage: Int {
    case ready
    case executing
    case finished
    case rollback
    case rollbackDone
}

class SwitchUserBaseTask: Operation {

    let logger = Logger.plog(SwitchUserBaseTask.self, category: "NewSwitchUserService")
    
    let passportContext: UniContextProtocol

    let monitorContext: SwitchUserMonitorContext
    
    private let _succCallback: SwitchUserSuccCallback
    
    private let _failCallback: SwitchUserFailCallback
    
    func run() {}
    
    init(succCallback: @escaping SwitchUserSuccCallback,
         failCallback: @escaping SwitchUserFailCallback,
         passportContext: UniContextProtocol,
         monitorContext: SwitchUserMonitorContext){

        self.monitorContext = monitorContext
        self.passportContext = passportContext
        self._succCallback = succCallback
        self._failCallback = failCallback
    }

    private(set) var stage: SafeAtomic<SwitchUserTaskStage> = .ready + .readWriteLock

    final func succCallback() {
        guard stage.value != .finished else { return }

        //这里是为了兼容旧的切换流程，旧流程任务执行使用了OperationQueue，
        //在finished之后不确定还能不能获取到执行资源，所以当初是先执行callback再修改的状态
        updateStage(.finished)
        _succCallback()

    }

    final func failCallback(_ error: Error) {
        guard stage.value != .finished else { return }

        //这里是为了兼容旧的切换流程，旧流程任务执行使用了OperationQueue，
        //在finished之后不确定还能不能获取到执行资源，所以当初是先执行callback再修改的状态
        //新版本的任务执行模块变更了，改为正确的逻辑(应该就是先改状态再callback)
        updateStage(.finished)
        _failCallback(error)
    }

    func updateStage(_ newValue: SwitchUserTaskStage) {
        guard newValue != stage.value else { return }

        willChangeValue(forKey: "isExecuting")
        willChangeValue(forKey: "isFinished")
        stage.value = newValue
        didChangeValue(forKey: "isExecuting")
        didChangeValue(forKey: "isFinished")
    }

    final override var isAsynchronous: Bool { true }

    final override var isFinished: Bool { stage.value == .finished }

    final override var isExecuting: Bool { stage.value == .executing }

    final override func start() {
        SuiteLoginUtil.runOnMain { [weak self] in
            guard let self = self else { return }

            if self.isCancelled {
                self.updateStage(.finished)
            } else {
                self.updateStage(.executing)
                self.run()
            }
        }
    }
}

class SwitchUserTask: SwitchUserBaseTask {
    
    let switchContext: SwitchUserContext
    
    var subTasks: [SUTaskConfig]
    
    let scheduler: SwitchUserTaskScheduler
    
    final func executeSubTask(succCallback: @escaping SwitchUserSuccCallback,
                              failCallback: @escaping SwitchUserFailCallback) {
        scheduler.schedule(taskConfigs: subTasks, switchContext: switchContext, passportContext: passportContext, monitorContext: monitorContext, succCallback: succCallback, failCallback: failCallback)
    }
    
    required init(switchContext: SwitchUserContext,
                  subTasks:[SUTaskConfig]?,
                  succCallback: @escaping SwitchUserSuccCallback,
                  failCallback: @escaping SwitchUserFailCallback,
                  passportContext: UniContextProtocol,
                  monitorContext: SwitchUserMonitorContext){
        
        self.switchContext = switchContext
        self.subTasks = subTasks ?? []
        self.scheduler = SwitchUserTaskScheduler()
        super.init(succCallback: succCallback, failCallback: failCallback, passportContext: passportContext, monitorContext: monitorContext)
    }
}

class SwitchUserPreTask: SwitchUserBaseTask {
    
    required override init(succCallback: @escaping SwitchUserSuccCallback,
                           failCallback: @escaping SwitchUserFailCallback,
                           passportContext: UniContextProtocol,
                           monitorContext: SwitchUserMonitorContext){
        super.init(succCallback: succCallback, failCallback: failCallback, passportContext: passportContext, monitorContext: monitorContext)
    }
}

