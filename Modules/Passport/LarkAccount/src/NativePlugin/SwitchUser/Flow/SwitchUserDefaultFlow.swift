//
//  SwitchUserDefaultFlow.swift
//  LarkAccount
//
//  Created by bytedance on 2021/9/1.
//

import Foundation
import LarkAccountInterface

/// 默认的用户切换 flow
class SwitchUserDefaultFlow: SwitchUserFlow {

    let internalSwitchContext: SwitchUserContext

    /// flow 执行前的 task 配置
    override var beforeRunTasks: [SUPreTaskConfig] {
        return [SUPreTaskConfig(SwitchUserCheckNetTask.self),
                SUPreTaskConfig(SwitchUserInterruptTask.self),
        ]
    }

    /// flow 的 task 配置
    override var tasks: [SUTaskConfig] {

        if MultiUserActivitySwitch.enableMultipleUser {
            return [SUTaskConfig(SwitchUserRustEnterBarrierTask.self), //设置rustSDK开始拦截请求
                    SUTaskConfig(SwitchUserGetUserInfoTask.self), //获取目标用户的userInfo或是credential
                    SUTaskConfig(SwitchUserSwitchIdentityDefaultTask.self), // 发起switch identity接口请求换取session
                    SUTaskConfig(SwitchUserFetchDeviceInfoTask.self),  //获取目标用户deviceInfo（包含did，iid；不跨端也获取）
                    SUTaskConfig(SwitchUserSwitchIdentityAfterCrossEnvTaskV2.self), //获取对端did之后，再次请求switch identify换取正式的session
                    SUTaskConfig(SwitchUserUpdateForegroundUserTask.self)]  //refresh activity user list 并更新容器前台和passport前台用户
        }

        return [SUTaskConfig(SwitchUserRustEnterBarrierTask.self), //设置rustSDK开始拦截请求
                SUTaskConfig(SwitchUserGetUserInfoTask.self), //获取目标用户的userInfo或是credential
                SUTaskConfig(SwitchUserSwitchIdentityDefaultTask.self), // 发起switch identity接口请求换取session
                SUTaskConfig(SwitchUserFetchDeviceInfoTask.self),  //获取目标用户deviceInfo（包含did，iid；不跨端也获取）
                SUTaskConfig(SwitchUserSwitchIdentityAfterCrossEnvTaskV2.self), //获取对端did之后，再次请求switch identify换取正式的session
                SUTaskConfig(SwitchUserRustOfflineTask.self),  //当前用户 rust offline
                SUTaskConfig(SwitchUserRustSetEnvTask.self), // 设置目标用户Env和did，iid 给 rustSDK
                SUTaskConfig(SwitchUserRustOnlineTask.self), // 目标用户 rust online
                SUTaskConfig(SwitchUserFinalUpdateTask.self)] // 切换成功，更新前台用户和 env 信息
    }
    
    override func run() {

        logger.info(SULogKey.switchCommon, body: "default flow executing", method: .local)
        
        //call delegate lifeCycle
        self.lifeCycle?.beginSwitchAccount(flow: self)
        
        executeTasks(switchContext: internalSwitchContext) {[weak self] in
            guard let self =  self else { return }
            self.logger.info(SULogKey.switchCommon, body: "default flow succ", method: .local)

            //call delegate lifeCycle
            self.lifeCycle?.switchAccountSucceed(flow: self, switchContext: self.internalSwitchContext)

        } failCallback: {[weak self] error in
            guard let self =  self else { return }
            self.logger.error(SULogKey.switchCommon, body: "default flow fail", error: error)

            //call delegate lifeCycle
            self.lifeCycle?.switchAccountFailed(flow: self, error: error)
        }
    }
    
    init(userID: String,
         credentialID: String? = nil,
         additionInfo: SwitchUserContextAdditionInfo?,
         monitorContext: SwitchUserMonitorContext,
         passportContext: UniContextProtocol){
        
        self.internalSwitchContext = SwitchUserContext(userID: userID)
        self.internalSwitchContext.credentialId = credentialID
        super.init(passportContext: passportContext, monitorContext: monitorContext, additionInfo: additionInfo)
        super.switchContext = internalSwitchContext
    }
    
    init(userInfo: V4UserInfo,
         additionInfo: SwitchUserContextAdditionInfo?,
         monitorContext: SwitchUserMonitorContext,
         passportContext: UniContextProtocol){
        
        self.internalSwitchContext = SwitchUserContext(userInfo: userInfo)
        super.init(passportContext: passportContext, monitorContext: monitorContext, additionInfo: additionInfo)
        super.switchContext = internalSwitchContext
    }
}
