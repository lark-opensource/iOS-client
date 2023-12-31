//
//  SwitchUserWithoutServerInteractionFlow.swift
//  LarkAccount
//
//  Created by bytedance on 2021/12/27.
//

import Foundation
import LarkAccountInterface

/// 不调用 switch_identity 接口
/// 只操作 Rust Offline 和 Online 的 Flow
class SwitchUserWithoutServerInteractionFlow: SwitchUserDefaultFlow {

    /// flow 的 task 配置
    override var tasks: [SUTaskConfig] {

        if MultiUserActivitySwitch.enableMultipleUser {
            return [SUTaskConfig(SwitchUserRustEnterBarrierTask.self), //设置rustSDK开始拦截请求
                    SUTaskConfig(SwitchUserFetchDeviceInfoTask.self),   //获取目标用户deviceInfo（包含did，iid；不跨端也获取）
                    SUTaskConfig(SwitchUserUpdateForegroundUserTask.self)] //refresh activity user list 并更新容器前台和passport前台用户
        }

        return [SUTaskConfig(SwitchUserRustEnterBarrierTask.self), //设置rustSDK开始拦截请求
                SUTaskConfig(SwitchUserFetchDeviceInfoTask.self),   //获取目标用户deviceInfo（包含did，iid；不跨端也获取）
                SUTaskConfig(SwitchUserRustOfflineTask.self), //当前用户 rust offline
                SUTaskConfig(SwitchUserRustSetEnvTask.self), // 设置目标用户Env和did，iid 给 rustSDK
                SUTaskConfig(SwitchUserRustOnlineTask.self), // 目标用户 rust online
                SUTaskConfig(SwitchUserFinalUpdateTask.self)] // 切换成功，更新前台用户和 env 信息
    }
    
}
