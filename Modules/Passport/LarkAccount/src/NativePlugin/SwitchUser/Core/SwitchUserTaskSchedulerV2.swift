//
//  SwitchUserTaskEngine.swift
//  LarkAccount
//
//  Created by bytedance on 2021/9/4.
//

import Foundation
import LKCommonsLogging
import LarkAccountInterface
import EEAtomic
import ECOProbeMeta

/// 切换 tasks 执行器
class SwitchUserTaskSchedulerV2: SwitchUserTaskSchedulerProtocol {

    let logger = Logger.plog(SwitchUserTaskScheduler.self, category: "SwitchUserTaskSchedulerV2")

    let enableRollback: Bool

    @AtomicObject
    var tasks: [NewSwitchUserTask] = []

    @AtomicObject
    var preTasks: [SwitchUserPreTask] = []

    private var _flowSuccCallback: SwitchUserSuccCallback?

    private var _flowFailCallback: SwitchUserFailCallback?

    func schedule(taskConfigs: [SUTaskConfig],
                  switchContext: SwitchUserContext,
                  passportContext: UniContextProtocol,
                  monitorContext: SwitchUserMonitorContext,
                  succCallback: @escaping SwitchUserSuccCallback,
                  failCallback: @escaping SwitchUserFailCallback) {

        logger.info(SULogKey.switchCommon, body: "schedulerV2 executing", method: .local)
        //重新初始化数据
        tasks = []
        _flowSuccCallback = succCallback
        _flowFailCallback = failCallback
        //执行task
        for config in taskConfigs {
            let task = config.task.init(switchContext: switchContext, subTasks: config.subTasks, succCallback: { [weak self] in
                SuiteLoginUtil.runOnMain {
                    self?.executeTask()
                }
            }, failCallback: { [weak self] error in
                SuiteLoginUtil.runOnMain {
                    guard let self = self else { return }
                    if self.enableRollback {
                        //监控
                        SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.rollbackStart, timerStart: .rollback, context: monitorContext)

                        self.loopTaskAndRollback(taskError: error, monitorContext: monitorContext)
                    } else {
                        self._flowFailCallback?(error)
                    }
                }
            }, passportContext: passportContext, monitorContext: monitorContext)
            tasks.append(task)
        }

        SuiteLoginUtil.runOnMain { [weak self] in
            self?.executeTask()
        }
    }

    func schedule(preTaskConfigs: [SUPreTaskConfig],
                  passportContext: UniContextProtocol,
                  monitorContext: SwitchUserMonitorContext,
                  succCallback: @escaping SwitchUserSuccCallback,
                  failCallback: @escaping SwitchUserFailCallback) {

        logger.info(SULogKey.switchCommon, body: "schedulerV2 executing preTask", method: .local)
        //重新初始化数据
        preTasks = []
        _flowSuccCallback = succCallback
        _flowFailCallback = failCallback
        //执行task
        for config in preTaskConfigs {

            let task = config.task.init(succCallback: { [weak self] in
                SuiteLoginUtil.runOnMain {
                    self?.executePreTask()
                }
            }, failCallback: { [weak self] error in
                SuiteLoginUtil.runOnMain {
                    self?._flowFailCallback?(error)
                }
            }, passportContext: passportContext, monitorContext: monitorContext)
            preTasks.append(task)
        }
        SuiteLoginUtil.runOnMain { [weak self] in
            self?.executePreTask()
        }
    }

    final private func executeTask() {
        loopTaskAndRun(tasks)
    }

    final private func executePreTask() {
        loopTaskAndRun(preTasks)
    }

    final private func loopTaskAndRun(_ tasks: [SwitchUserBaseTask]) {

        for task in tasks {

            guard task.stage.value == .ready else {
                continue
            }
            //任务start之后需要return，任务执行完成后会重新进入loopTaskAndRun的方法，执行下一个task
            task.start()
            return

        }
        //所有任务执行完成后，回调succ
        _flowSuccCallback?()
    }

    final private func loopTaskAndRollback(taskError: Error, monitorContext: SwitchUserMonitorContext) {

        for task in tasks.reversed() {

            guard task.stage.value == .finished else {
                continue
            }

            task.updateStage(.rollback)
            task.onRollback { [weak self] result in
                SuiteLoginUtil.runOnMain {
                    switch result {
                    case .success(_):
                        task.updateStage(.rollbackDone)
                        self?.loopTaskAndRollback(taskError: taskError, monitorContext: monitorContext)
                    case .failure(let rollbackError):
                        task.updateStage(.rollbackDone)

                        //监控
                        SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.rollbackResult, timerStop: .rollback, isFailResult: true, context: monitorContext, error: rollbackError)

                        //回滚失败，直接抛出错误
                        self?._flowFailCallback?(AccountError.switchUserRollbackError(rawError: rollbackError))
                    }
                }
            }
            logger.info(SULogKey.switchCommon, body: "schedulerV2 executing fallback \(type(of: task))")
            return
        }
        //监控
        SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.rollbackResult, timerStop: .rollback, isSuccessResult: true, context: monitorContext)

        //所有任务执行完成后，回调fail
        _flowFailCallback?(taskError)
    }

    init(enableRollback: Bool = true) {
        self.enableRollback = enableRollback
    }
}
