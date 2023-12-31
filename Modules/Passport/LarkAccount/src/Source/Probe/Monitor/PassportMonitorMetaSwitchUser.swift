//
//  PassportMonitorMetaSwitchUser.swift
//  LarkAccount
//
//  Created by ByteDance on 2023/4/25.
//

import Foundation
import ECOProbeMeta

enum SwitchUserMonitorDurationFlow: String {
    case switchUser
    case getUserInfo
    case switchIdentity
    case getDeviceInfo
    case rustOffline
    case rustOnline
    case rustSetEnv
    case rustSetDeviceInfo
    case afterSwitchNotify
    case rollback
    case autoSwitch
    case checkStatus
}

final class PassportMonitorMetaSwitchUser: OPMonitorCodeBase {

    private static let domain = "client.passport.monitor.switch_user"

    private init(code: Int, level: OPMonitorLevel, message: String) {
        super.init(domain: PassportMonitorMetaSwitchUser.domain, code: code, level: level, message: message)
    }

}

extension PassportMonitorMetaSwitchUser {

    //开始退出登录流程
    static let switchUserEntry = PassportMonitorMetaSwitchUser(code: 10000,
                                                     level: OPMonitorLevelNormal,
                                                     message: "switch_user_entry")
    //开始切换租户
    static let switchUserStart = PassportMonitorMetaSwitchUser(code: 10001,
                                                     level: OPMonitorLevelNormal,
                                                     message: "switch_user_start")
    //切换租户完成
    static let switchUserResult = PassportMonitorMetaSwitchUser(code: 10002,
                                                     level: OPMonitorLevelNormal,
                                                     message: "switch_user_result")
    //开始检测当前是否有网络
    static let startCheckNet = PassportMonitorMetaSwitchUser(code: 10003,
                                                     level: OPMonitorLevelNormal,
                                                     message: "check_net_start")

    //网络检测结果
    static let checkNetResult = PassportMonitorMetaSwitchUser(code: 10004,
                                                     level: OPMonitorLevelNormal,
                                                     message: "check_net_result")

    //开始执行切换租户拦截逻辑
    static let startInterrupt = PassportMonitorMetaSwitchUser(code: 10005,
                                                     level: OPMonitorLevelNormal,
                                                     message: "start_interrupt")

    //切换租户拦截逻辑结果
    static let interruptResult = PassportMonitorMetaSwitchUser(code: 10006,
                                                     level: OPMonitorLevelNormal,
                                                     message: "interrupt_result")

    //rustSDK设置网络请求拦截耗时
    static let rustBarrierCost = PassportMonitorMetaSwitchUser(code: 10007,
                                                     level: OPMonitorLevelNormal,
                                                     message: "rust_barrier_cost")
    //开始获取目标用户UserInfo
    static let getUserInfoStart = PassportMonitorMetaSwitchUser(code: 10008,
                                                     level: OPMonitorLevelNormal,
                                                     message: "get_user_info_start")

    //目标用户UserInfo获取结果
    static let getUserInfoResult = PassportMonitorMetaSwitchUser(code: 10009,
                                                     level: OPMonitorLevelNormal,
                                                     message: "get_user_info_result")

    //switch_identity请求开始
    static let switchIdentityStart = PassportMonitorMetaSwitchUser(code: 10010,
                                                     level: OPMonitorLevelNormal,
                                                     message: "switch_identity_start")

    //switch_identity请求结果
    static let switchIdentityResult = PassportMonitorMetaSwitchUser(code: 10011,
                                                     level: OPMonitorLevelNormal,
                                                     message: "switch_identity_result")

    //开始获取目标用户did，iid
    static let getDeviceInfoStart = PassportMonitorMetaSwitchUser(code: 10012,
                                                     level: OPMonitorLevelNormal,
                                                     message: "get_device_info_start")

    //获取目标用户did，iid 结果
    static let getDeviceInfoResult = PassportMonitorMetaSwitchUser(code: 10013,
                                                     level: OPMonitorLevelNormal,
                                                     message: "get_device_info_result")

    //开始 执行rustSDK offline 操作
    static let rustOfflineStart = PassportMonitorMetaSwitchUser(code: 10014,
                                                     level: OPMonitorLevelNormal,
                                                     message: "rust_offline_start")

    //rustSDK offline 执行完成
    static let rustOfflineResult = PassportMonitorMetaSwitchUser(code: 10015,
                                                     level: OPMonitorLevelNormal,
                                                     message: "rust_offline_result")

    //开始执行 rustSDK set env
    static let rustSetEnvStart = PassportMonitorMetaSwitchUser(code: 10016,
                                                     level: OPMonitorLevelNormal,
                                                     message: "rust_set_env_start")

    //rustSDK set env 执行完成
    static let rustSetEnvResult = PassportMonitorMetaSwitchUser(code: 10017,
                                                     level: OPMonitorLevelNormal,
                                                     message: "rust_set_env_result")

    //开始执行 rustSDK set deviceInfo
    static let rustSetDeviceInfoStart = PassportMonitorMetaSwitchUser(code: 10018,
                                                     level: OPMonitorLevelNormal,
                                                     message: "rust_set_device_info_start")

    //rustSDK set deviceInfo 执行完成
    static let rustSetDeviceInfoResult = PassportMonitorMetaSwitchUser(code: 10019,
                                                     level: OPMonitorLevelNormal,
                                                     message: "rust_set_device_info_result")

    //开始执行 rustSDK online
    static let rustOnlineStart = PassportMonitorMetaSwitchUser(code: 10020,
                                                     level: OPMonitorLevelNormal,
                                                     message: "rust_online_start")

    //rustSDK online 执行完成
    static let rustOnlineResult = PassportMonitorMetaSwitchUser(code: 10021,
                                                     level: OPMonitorLevelNormal,
                                                     message: "rust_online_result")

    //开始push切换租户完成状态通知
    static let afterSwitchNotifyStart = PassportMonitorMetaSwitchUser(code: 10022,
                                                     level: OPMonitorLevelNormal,
                                                     message: "after_switch_notify_start")
    //切换租户完成状态任务执行完成
    static let afterSwitchNotifyComplete = PassportMonitorMetaSwitchUser(code: 10023,
                                                     level: OPMonitorLevelNormal,
                                                     message: "after_switch_notify_complete")

    //开始回滚
    static let rollbackStart = PassportMonitorMetaSwitchUser(code: 10024,
                                                     level: OPMonitorLevelNormal,
                                                     message: "rollback_start")

    //回滚执行完成
    static let rollbackResult = PassportMonitorMetaSwitchUser(code: 10025,
                                                     level: OPMonitorLevelNormal,
                                                     message: "rollback_result")

    //自动切换开始
    static let autoSwitchStart = PassportMonitorMetaSwitchUser(code: 10026,
                                                     level: OPMonitorLevelNormal,
                                                     message: "auto_switch_start")

    //自动切换完成
    static let autoSwitchResult = PassportMonitorMetaSwitchUser(code: 10027,
                                                     level: OPMonitorLevelNormal,
                                                     message: "auto_switch_result")

    //自动切换开始
    static let checkStatusStart = PassportMonitorMetaSwitchUser(code: 10028,
                                                     level: OPMonitorLevelNormal,
                                                     message: "check_status_start")

    //自动切换完成
    static let checkStatusResult = PassportMonitorMetaSwitchUser(code: 10029,
                                                     level: OPMonitorLevelNormal,
                                                     message: "check_status_result")


}
