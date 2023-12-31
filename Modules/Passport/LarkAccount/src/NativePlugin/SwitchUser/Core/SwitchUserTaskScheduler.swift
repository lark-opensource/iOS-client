//
//  SwitchUserTaskEngine.swift
//  LarkAccount
//
//  Created by bytedance on 2021/9/4.
//

import Foundation
import LKCommonsLogging
import LarkAccountInterface

/// 切换 tasks 执行器
class SwitchUserTaskScheduler: SwitchUserTaskSchedulerProtocol {

    let logger = Logger.plog(SwitchUserTaskScheduler.self, category: "NewSwitchUserService")

    var operationQueue: OperationQueue
    
    func schedule(taskConfigs tasks: [SUTaskConfig],
                switchContext: SwitchUserContext,
                passportContext: UniContextProtocol,
                monitorContext: SwitchUserMonitorContext,
                succCallback: @escaping SwitchUserSuccCallback,
                failCallback: @escaping SwitchUserFailCallback) {

        logger.info(SULogKey.switchCommon, body: "scheduler executing", method: .local)

        for config in tasks {

            let operation = config.task.init(switchContext: switchContext, subTasks: config.subTasks, succCallback: {}, failCallback: { [weak self] error in
                guard let self = self else { return }
                //task 执行有错误产生, 终止切换流程
                self.logger.warn(SULogKey.switchCommon, body: "scheduler finished with error", error: error)

                self.operationQueue.cancelAllOperations()
                failCallback(error)
            }, passportContext: passportContext, monitorContext: monitorContext)

            operationQueue.addOperation(operation)
        }

        operationQueue.addOperation { [weak self] in
            guard let self = self else { return }
            self.logger.info(SULogKey.switchCommon, body: "scheduler finished")
            succCallback()
        }
    }

    func schedule(preTaskConfigs preTasks: [SUPreTaskConfig],
                passportContext: UniContextProtocol,
                monitorContext: SwitchUserMonitorContext,
                succCallback: @escaping SwitchUserSuccCallback,
                failCallback: @escaping SwitchUserFailCallback) {

        logger.info(SULogKey.switchCommon, body: "preTasks scheduler executing")

        for config in preTasks {

            let operation = config.task.init(succCallback: {}, failCallback: { [weak self] error in
                guard let self = self else { return }
                self.logger.warn(SULogKey.switchCommon, body: "preTask scheduler finished with error", error: error)

                self.operationQueue.cancelAllOperations()
                failCallback(error)
            }, passportContext: passportContext, monitorContext: monitorContext)

            operationQueue.addOperation(operation)
        }

        operationQueue.addOperation { [weak self] in
            guard let self = self else { return }
            self.logger.info(SULogKey.switchCommon, body: "preTask scheduler finished")
            succCallback()
        }
    }
    
    init(){
        self.operationQueue = OperationQueue()
        self.operationQueue.maxConcurrentOperationCount = 1
        self.operationQueue.qualityOfService = .utility
    }
}
