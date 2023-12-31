//
//  PassportMonitorMetaCommon.swift
//  LarkAccount
//
//  Created by au on 2023/7/21.
//

import Foundation
import ECOProbeMeta


enum CommonMonitorDurationFlow: String {
    case fetchDeviceId
}


// 用于一些零散业务场景的监控
final class PassportMonitorMetaCommon: OPMonitorCodeBase {

    static let domain = "client.monitor.passport.common"

    private init(code: Int, level: OPMonitorLevel, message: String) {
        super.init(domain: PassportMonitorMetaCommon.domain, code: code, level: level, message: message)
    }

}

extension PassportMonitorMetaCommon {

    /// 前台用户是否是匿名 session
    static let foregroundUserIsAnonymous = PassportMonitorMetaCommon(code: 10000,
                                                                     level: OPMonitorLevelNormal,
                                                                     message: "foreground_user_is_anonymous")

    /// 获取did开始
    static let getDeviceIDStart = PassportMonitorMetaCommon(code: 10001,
                                                                     level: OPMonitorLevelNormal,
                                                                     message: "get_did_start")

    /// 获取did结果
    static let getDeviceIDResult = PassportMonitorMetaCommon(code: 10002,
                                                                     level: OPMonitorLevelNormal,
                                                                     message: "get_did_result")

    static let ssoTransferByAuto = PassportMonitorMetaCommon(code: 10004,
                                                                    level: OPMonitorLevelNormal,
                                                                    message: "sso_transfer_by_auto")

    static let ssoTransferByManual = PassportMonitorMetaCommon(code: 10005,
                                                                    level: OPMonitorLevelNormal,
                                                                    message: "sso_transfer_by_manual")
    
    static let finishLarkGlobalRegist = PassportMonitorMetaCommon(code: 10006,
                                                                  level: OPMonitorLevelNormal,
                                                                  message: "finish_lark_global_regist")

    static let callSensitiveJsApi = PassportMonitorMetaCommon(code: 10007,
                                                                    level: OPMonitorLevelNormal,
                                                                    message: "call_sensitive_js_api")

}
