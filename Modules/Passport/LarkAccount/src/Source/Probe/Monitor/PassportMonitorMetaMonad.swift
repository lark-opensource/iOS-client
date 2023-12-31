//
//  PassportMonitorMetaMonad.swift
//  LarkAccount
//
//  Created by ByteDance on 2023/9/20.
//

import Foundation
import ECOProbeMeta

final class PassportMonitorMetaMonad: OPMonitorCodeBase {

    private static let domain = "client.passport.monitor.monad"

    private init(code: Int, level: OPMonitorLevel, message: String) {
        super.init(domain: PassportMonitorMetaMonad.domain, code: code, level: level, message: message)
    }

}

extension PassportMonitorMetaMonad {

    static let rustOnlineStart = PassportMonitorMetaMonad(code: 10000,
                                                     level: OPMonitorLevelNormal,
                                                     message: "rust_online_start")

    static let rustOnlineResult = PassportMonitorMetaMonad(code: 10001,
                                                     level: OPMonitorLevelNormal,
                                                     message: "rust_online_result")

    static let rustOfflineStart = PassportMonitorMetaMonad(code: 10002,
                                                     level: OPMonitorLevelNormal,
                                                     message: "rust_offline_start")

    static let rustOfflineResult = PassportMonitorMetaMonad(code: 10003,
                                                     level: OPMonitorLevelNormal,
                                                     message: "rust_offline_result")

    static let rustSetEnvStart = PassportMonitorMetaMonad(code: 10004,
                                                     level: OPMonitorLevelNormal,
                                                     message: "rust_set_env_start")

    static let rustSetEnvResult = PassportMonitorMetaMonad(code: 10005,
                                                     level: OPMonitorLevelNormal,
                                                     message: "rust_set_env_result")

    static let rustSetDeviceInfoStart = PassportMonitorMetaMonad(code: 10006,
                                                     level: OPMonitorLevelNormal,
                                                     message: "rust_set_device_info_start")

    static let rustSetDeviceInfoResult = PassportMonitorMetaMonad(code: 10007,
                                                     level: OPMonitorLevelNormal,
                                                     message: "rust_set_device_info_result")

    static let getDeviceInfoStart = PassportMonitorMetaMonad(code: 10008,
                                                     level: OPMonitorLevelNormal,
                                                     message: "get_device_info_start")

    static let getDeviceInfoResult = PassportMonitorMetaMonad(code: 10009,
                                                     level: OPMonitorLevelNormal,
                                                     message: "get_device_info_result")

    static let asyncGetDomainStart = PassportMonitorMetaMonad(code: 10010,
                                                     level: OPMonitorLevelNormal,
                                                     message: "async_get_domain_start")

    static let asyncGetDomainResult = PassportMonitorMetaMonad(code: 10011,
                                                     level: OPMonitorLevelNormal,
                                                     message: "async_get_domain_result")

    static let updateForegroundUserStart = PassportMonitorMetaMonad(code: 10012,
                                                     level: OPMonitorLevelNormal,
                                                     message: "update_foreground_user_start")

    static let updateForegroundUserResult = PassportMonitorMetaMonad(code: 10013,
                                                     level: OPMonitorLevelNormal,
                                                     message: "update_foreground_user_result")


    static let removeUsersStart = PassportMonitorMetaMonad(code: 10014,
                                                     level: OPMonitorLevelNormal,
                                                     message: "remove_users_start")

    static let removeUsersStartResult = PassportMonitorMetaMonad(code: 10015,
                                                     level: OPMonitorLevelNormal,
                                                     message: "remove_users_result")

    static let rollbackForegroundUserStart = PassportMonitorMetaMonad(code: 10016,
                                                     level: OPMonitorLevelNormal,
                                                     message: "rollback_foreground_user_start")

    static let rollbackForegroundUserResult = PassportMonitorMetaMonad(code: 10017,
                                                     level: OPMonitorLevelNormal,
                                                     message: "rollback_foreground_user_result")

}
