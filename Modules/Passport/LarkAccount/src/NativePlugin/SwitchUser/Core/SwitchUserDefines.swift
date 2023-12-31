//
//  SwitchUserDefines.swift
//  LarkAccount
//
//  Created by bytedance on 2021/8/31.
//

import Foundation
import LarkAccountInterface

typealias SwitchUserCompletionCallback = (Bool) -> Void
typealias SwitchUserSuccCallback = () -> Void
typealias SwitchUserFailCallback = (Error) -> Void

typealias NewSwitchUserTask = SwitchUserTask & SwitchUserTaskRollback

enum SwitchUserStage: String {
    case idle
    case ready //flow 开始执行前期的检查任务
    case executing //flow 开始执行配置的任务
    case finished // flow 任务执行完成(成功||失败)
}

struct SUTaskConfig {
    
    let task: NewSwitchUserTask.Type
    
    let subTasks: [SUTaskConfig]?
    
    init(_ task: NewSwitchUserTask.Type,
         subTasks: [SUTaskConfig]? = nil) {
        self.task = task
        self.subTasks = subTasks
    }
}

struct SUPreTaskConfig {
    
    let task: SwitchUserPreTask.Type
    
    init(_ task: SwitchUserPreTask.Type) {
        self.task = task
    }
}

protocol SwitchUserLifeCycle: AnyObject {
    func beginSwitchAccount(flow: SwitchUserFlow)
    func switchAccountSucceed(flow: SwitchUserFlow, switchContext: SwitchUserContext)
    func switchAccountFailed(flow: SwitchUserFlow, error: Error)
}

protocol SwitchUserTaskSchedulerProtocol: AnyObject {

    func schedule(taskConfigs: [SUTaskConfig],
                switchContext: SwitchUserContext,
                passportContext: UniContextProtocol,
                monitorContext: SwitchUserMonitorContext,
                succCallback: @escaping SwitchUserSuccCallback,
                failCallback: @escaping SwitchUserFailCallback)

    func schedule(preTaskConfigs: [SUPreTaskConfig],
                passportContext: UniContextProtocol,
                monitorContext: SwitchUserMonitorContext,
                succCallback: @escaping SwitchUserSuccCallback,
                failCallback: @escaping SwitchUserFailCallback)

}

protocol SwitchUserTaskRollback {

    func onRollback(finished: @escaping (Result<Void, Error>) -> Void)
}


struct SULogKey {
    static let switchStart = "n_action_switch_start"
    static let switchEntry = "n_action_switch_entry"
    static let switchBlock = "n_action_switch_block"
    static let switchContinue = "n_action_switch_continue"
    static let switchSucc = "n_action_switch_succ"
    static let switchFail = "n_action_switch_fail"

    static let switchStage = "n_action_switch_stage"

    static let switchNotifyStart = "n_action_switch_notify_start"
    static let switchNotifySucc = "n_action_switch_notify_succ"
    static let switchNotifyFail = "n_action_switch_notify_fail"

    static let switchCommon = "n_action_switch_common"

    static let switchIdentityRequestStart = "n_action_switch_identity_next_req_start"
    static let switchIdentityRequestSucc = "n_action_switch_identity_next_req_succ"
    static let switchIdentityEnterApp = "n_action_enter_app"
    static let switchIdentityOtherStep = "n_action_other_next_step"
}

struct SwitchUserMonitorCategory {

    static let codeVersion: String = {
        if MultiUserActivitySwitch.enableMultipleUser {
            return "3"
        }
        return "2"
    }()
}

extension UniContextProtocol {
    var switchType: CommonConst.SwitchType {
        switch from {
        case .applink, .external, .operationCenter, .operationCenterLogin:
            return .onDemand
        case .login:
            return .login
        case .logout, .invalidSession, .unregister, .sessionReauth:
            return .passive
        default:
            return .onDemand
        }
    }
}

enum SwitchUserType: String {
    // 主动切换
    case onDemand = "on_demand"
    // 被动切换
    case passive = "passive"
    // 快速切换
    case fast = "fast"
    // 自动切换
    case auto = "auto"
    // 重试
    case retry = "retry"
}

struct SwitchUserMonitorContext {
    // 切换租户类型
    let type: SwitchUserType
    // 切换租户原因
    let reason: UniContextFrom

}
