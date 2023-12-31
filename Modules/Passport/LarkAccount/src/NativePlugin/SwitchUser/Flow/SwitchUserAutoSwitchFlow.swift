//
//  SwitchUserAutoSwitchFlow.swift
//  LarkAccount
//
//  Created by bytedance on 2021/9/2.
//

import Foundation
import LarkContainer
import ECOProbeMeta
import LarkAccountInterface

class SwitchUserAutoSwitchFlow: SwitchUserFlow {

    /// flow 执行前的 task
    override var beforeRunTasks: [SUPreTaskConfig] {
        return [SUPreTaskConfig(SwitchUserCheckNetTask.self),
                SUPreTaskConfig(SwitchUserInterruptTask.self),
                SUPreTaskConfig(SwitchUserCheckSessionTask.self),
                SUPreTaskConfig(SwitchUserRustEnterBarrierPreTask.self) //设置rustSDK开始拦截请求
        ]
    }

    /// 自动切换 flow 的 task 配置
    override var tasks: [SUTaskConfig] {

        if MultiUserActivitySwitch.enableMultipleUser {
            return [SUTaskConfig(SwitchUserGetUserInfoTask.self), //获取目标用户的userInfo或是credential
                    SUTaskConfig(SwitchUserSwitchIdentityAutoSwitchTask.self), // 发起switch identity接口请求换取session
                    SUTaskConfig(SwitchUserFetchDeviceInfoTask.self),  //获取目标用户deviceInfo（包含did，iid；不跨端也获取）
                    SUTaskConfig(SwitchUserSwitchIdentityAfterCrossEnvTaskV2.self), //获取对端did之后，再次请求switch identify换取正式的session  (自动切换场景理论不需要，防御性task)
                    SUTaskConfig(SwitchUserUpdateForegroundUserTask.self)] //refresh activity user list 并更新容器前台和passport前台用户
        }

        return [SUTaskConfig(SwitchUserGetUserInfoTask.self), //获取目标用户的userInfo或是credential
                SUTaskConfig(SwitchUserSwitchIdentityAutoSwitchTask.self), // 发起switch identity接口请求换取session
                SUTaskConfig(SwitchUserFetchDeviceInfoTask.self),  //获取目标用户deviceInfo（包含did，iid；不跨端也获取）
                SUTaskConfig(SwitchUserSwitchIdentityAfterCrossEnvTaskV2.self), //获取对端did之后，再次请求switch identify换取正式的session  (自动切换场景理论不需要，防御性task)
                SUTaskConfig(SwitchUserRustOfflineTask.self), //当前用户 rust offline
                SUTaskConfig(SwitchUserRustSetEnvTask.self), // 设置目标用户Env和did，iid 给 rustSDK
                SUTaskConfig(SwitchUserRustOnlineTask.self), // 目标用户 rust online
                SUTaskConfig(SwitchUserFinalUpdateTask.self)] // 切换成功，更新前台用户和 env 信息
    }
    
    @Provider private var userManager: UserManager


    override func run() {

        logger.info(SULogKey.switchCommon, body: "auto flow executing")

        self.lifeCycle?.beginSwitchAccount(flow: self)
        
        let userIDs = self.userManager.getActiveUserList().map({ $0.userID })

        //监控
        SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.autoSwitchStart, timerStart: .autoSwitch, context: monitorContext)
        
        guard !userIDs.isEmpty else {
            logger.info(SULogKey.switchCommon, body: "active user list empty")
            reportAutoSwitchFail()
            SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.autoSwitchResult, timerStop: .autoSwitch, isFailResult: true, context: monitorContext, error: AccountError.autoSwitchFail)
            return
        }

        func internalAutoSwitch(autoSwitchIDs: [String]) {

            guard let switchTo = autoSwitchIDs.first else {
                logger.info(SULogKey.switchCommon, body: "auto flow fail with no next active user")
                reportAutoSwitchFail()
                return
            }

            let switchContext =  SwitchUserContext(userID: switchTo)
            switchContext.additionInfo = self.additionInfo
            self.switchContext = switchContext

            self.logger.info(SULogKey.switchCommon, body: "auto flow execute tasks",
                             additionalData: ["target_userID": switchTo,
                                              "target_session": (UserManager.shared.getUser(userID: switchTo)?.suiteSessionKey ?? "").desensitized()])

            self.executeTasks(switchContext: switchContext) { [weak self] in
                guard let self = self else { return }
                self.logger.info(SULogKey.switchCommon, body: "auto flow succ", additionalData: ["target_userID": switchTo])
                //监控
                SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.autoSwitchResult, timerStop: .autoSwitch, isSuccessResult: true, context: self.monitorContext)

                self.lifeCycle?.switchAccountSucceed(flow: self, switchContext: switchContext)
                
            } failCallback: {[weak self] error in
                guard let self = self else { return }
                self.logger.warn(SULogKey.switchCommon, body: "auto flow fail", additionalData: ["target_userID": switchTo], error: error)

                guard autoSwitchIDs.count > 1 else {
                    self.logger.warn(SULogKey.switchCommon, body: "auto flow fail with no next active user")
                    //监控
                    SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.autoSwitchResult, timerStop: .autoSwitch, isFailResult: true, context: self.monitorContext, error: AccountError.autoSwitchFail)

                    self.reportAutoSwitchFail()
                    return
                }
                // 切换失败，依次继续自动切到下一个身份
                var ids = autoSwitchIDs
                ids.removeFirst()

                internalAutoSwitch(autoSwitchIDs: ids)
            }
        }

        internalAutoSwitch(autoSwitchIDs: userIDs)
    }

    /// 没有找到可以切换的用户,  回调一个autoSwitchFail 的错误; 现象为重新回到登录页面
    func reportAutoSwitchFail() {
        logger.info(SULogKey.switchCommon, body: "report autoSwitchFail")

        lifeCycle?.switchAccountFailed(flow: self, error: AccountError.autoSwitchFail)
    }
}

