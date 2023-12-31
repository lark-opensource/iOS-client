//
//  PassportMonitorMetaLogout.swift
//  LarkAccount
//
//  Created by au on 2023/4/24.
//

import ECOProbeMeta
import Foundation
import LarkAccountInterface

extension LogoutTrigger {
    var monitorDescription: String {
        switch self {
        case .manual:
            return "MANUAL"
        case .sessionExpired:
            return "SESSION_EXPIRED"
        case .unregisterUser:
            return "UNREGISTER_USER"
        case .debugSwitchEnv:
            return "DEBUG_SWITCH_ENV"
        case .setting:
            return "SETTING"
        case .tenantRestrict:
            return "TENANT_RESTRICT"
        case .jsBridge:
            return "JS_BRIDGE"
        case .emm:
            return "EMM"
        case .sessionRiskCountdown:
            return "SESSION_RISK_COUNTDOWN"
        @unknown default:
            return "UNKNOWN"
        }
    }
}

final class PassportMonitorMetaLogout: OPMonitorCodeBase {

    static let domain = "client.monitor.passport.logout"

    private init(code: Int, level: OPMonitorLevel, message: String) {
        super.init(domain: PassportMonitorMetaLogout.domain, code: code, level: level, message: message)
    }

}

extension PassportMonitorMetaLogout {

    static let startLogout = PassportMonitorMetaLogout(code: 10000,
                                                       level: OPMonitorLevelNormal,
                                                       message: "start_logout")

    static let logoutSuccess = PassportMonitorMetaLogout(code: 10001,
                                                         level: OPMonitorLevelNormal,
                                                         message: "logout_success")

    static let logoutFail = PassportMonitorMetaLogout(code: 10002,
                                                      level: OPMonitorLevelNormal,
                                                      message: "logout_fail")

    static let startLogoutRequest = PassportMonitorMetaLogout(code: 10003,
                                                              level: OPMonitorLevelNormal,
                                                              message: "start_logout_request")

    static let logoutRequestResult = PassportMonitorMetaLogout(code: 10004,
                                                               level: OPMonitorLevelNormal,
                                                               message: "logout_request_result")

    static let startLogoutTaskHandle = PassportMonitorMetaLogout(code: 10005,
                                                                 level: OPMonitorLevelNormal,
                                                                 message: "start_logout_task_handle")

    static let logoutTaskHandleResult = PassportMonitorMetaLogout(code: 10006,
                                                                  level: OPMonitorLevelNormal,
                                                                  message: "logout_task_handle_result")

    static let startLogoutRustTaskHandle = PassportMonitorMetaLogout(code: 10007,
                                                                     level: OPMonitorLevelNormal,
                                                                     message: "start_logout_rust_task_handle")

    static let logoutRustTaskHandleResult = PassportMonitorMetaLogout(code: 10008,
                                                                      level: OPMonitorLevelNormal,
                                                                      message: "logout_rust_task_handle_result")

    static let startLogoutOffline = PassportMonitorMetaLogout(code: 10020,
                                                              level: OPMonitorLevelNormal,
                                                              message: "start_logout_offline")

    static let logoutOfflineResult = PassportMonitorMetaLogout(code: 10021,
                                                               level: OPMonitorLevelNormal,
                                                               message: "logout_offline_result")

    static let startLogoutOfflineRequest = PassportMonitorMetaLogout(code: 10022,
                                                                     level: OPMonitorLevelNormal,
                                                                     message: "start_logout_offline_request")

    static let logoutOfflineRequestResult = PassportMonitorMetaLogout(code: 10023,
                                                                      level: OPMonitorLevelNormal,
                                                                      message: "logout_offline_request_result")

}
