//
//  SwitchUserFlow.swift
//  LarkAccount
//
//  Created by bytedance on 2021/8/31.
//

import Foundation
import LKCommonsLogging

/// flow 基类
class SwitchUserFlow {

    let logger = Logger.plog(SwitchUserFlow.self, category: "NewSwitchUserService")

    /// flow run 方法执行前的 task 配置
    var beforeRunTasks:  [SUPreTaskConfig] { return [] }

    /// flow task 配置
    var tasks: [SUTaskConfig] { return [] }

    ///  flow task 执行器
    private lazy var scheduler: SwitchUserTaskSchedulerProtocol = {
        return SwitchUserTaskSchedulerV2()
    }()

    /// 切换用户上下文
    var switchContext: SwitchUserContext?

    /// passport 流程上下文
    var passportContext: UniContextProtocol

    /// 监控上下文
    var monitorContext: SwitchUserMonitorContext

    /// 切换用户生命周期 delegate
    weak var lifeCycle: SwitchUserLifeCycle?

    /// 切换用户的附加信息
    var additionInfo: SwitchUserContextAdditionInfo?

    /// flow 的成功回调
    var succCallback: SwitchUserSuccCallback?

    /// flow 的失败回调
    var failCallback: SwitchUserFailCallback?

    /// v2版本新增的completionCallback; 为调用方传的callback
    var completionCallback: SwitchUserCompletionCallback?

    /// flow 真正开始执行的方法. 子类需要重写此方法
    func run() {
        logger.error(SULogKey.switchCommon, body: "\(self) not override run() method")
        assertionFailure("should override run() method")
    }
    
    /// 执行 flow, 由外部调用. 会先执行 preTask, 成功的情况下会执行 run()  方法. 失败者直接失败
    final func executeFlow(succCallback: @escaping SwitchUserSuccCallback,
                           failCallback: @escaping SwitchUserFailCallback) {
        logger.info(SULogKey.switchCommon, body: "flow executing preTasks", method: .local)
        self.succCallback = succCallback
        self.failCallback = failCallback

        scheduler.schedule(preTaskConfigs: beforeRunTasks, passportContext: passportContext, monitorContext: monitorContext) { [weak self] in
            guard let self =  self else { return }
            self.logger.info(SULogKey.switchEntry)

            self.run()

        } failCallback: {[weak self] error in
            guard let self = self else { return }
            self.logger.warn(SULogKey.switchBlock, body: "preTasks fail", error: error)

            self.lifeCycle?.switchAccountFailed(flow: self, error: error)
            failCallback(error)
        }
    }
    

    /// 执行 flow 的 tasks
    final func executeTasks(switchContext: SwitchUserContext,
                            succCallback: @escaping SwitchUserSuccCallback,
                            failCallback: @escaping SwitchUserFailCallback) {
        logger.info(SULogKey.switchCommon, body: "flow executing tasks", method: .local)

        scheduler.schedule(taskConfigs: tasks, switchContext: switchContext, passportContext: passportContext, monitorContext: monitorContext, succCallback: succCallback, failCallback: failCallback)
    }
    
    init(passportContext: UniContextProtocol,
         monitorContext: SwitchUserMonitorContext,
         additionInfo: SwitchUserContextAdditionInfo?){
        
        self.passportContext = passportContext
        self.monitorContext = monitorContext
        self.additionInfo = additionInfo
    }
}
