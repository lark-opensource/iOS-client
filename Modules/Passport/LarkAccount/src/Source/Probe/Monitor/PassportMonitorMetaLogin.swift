//
//  PassportMonitorMetaLogin.swift
//  LarkAccount
//
//  Created by au on 2023/3/8.
//

import ECOProbeMeta
import Foundation

final class PassportMonitorMetaLogin: OPMonitorCodeBase {

    static let domain = "client.monitor.passport.login"

    private init(code: Int, level: OPMonitorLevel, message: String) {
        super.init(domain: PassportMonitorMetaLogin.domain, code: code, level: level, message: message)
    }

}

extension PassportMonitorMetaLogin {
    static let qrcodeLoginEnter = PassportMonitorMetaLogin(code: 10010,
                                                           level: OPMonitorLevelNormal,
                                                           message: "qrcode_login_enter")

    static let qrcodeLoginCancel = PassportMonitorMetaLogin(code: 10011,
                                                            level: OPMonitorLevelNormal,
                                                            message: "qrcode_login_cancel")

    static let startQrcodeLoginVerify = PassportMonitorMetaLogin(code: 10012,
                                                                 level: OPMonitorLevelNormal,
                                                                 message: "start_qrcode_login_verify")

    static let qrcodeLoginVerifyResult = PassportMonitorMetaLogin(code: 10013,
                                                                  level: OPMonitorLevelNormal,
                                                                  message: "qrcode_login_verify_result")

    static let oneKeyLoginEnter = PassportMonitorMetaLogin(code: 10020,
                                                           level: OPMonitorLevelNormal,
                                                           message: "one_key_login_enter")

    static let oneKeyLoginCancel = PassportMonitorMetaLogin(code: 10021,
                                                            level: OPMonitorLevelNormal,
                                                            message: "one_key_login_cancel")

    static let startOneKeyLoginRequestToken = PassportMonitorMetaLogin(code: 10022,
                                                                       level: OPMonitorLevelNormal,
                                                                       message: "start_one_key_login_request_token")

    static let oneKeyLoginRequestTokenResult = PassportMonitorMetaLogin(code: 10023,
                                                                        level: OPMonitorLevelNormal,
                                                                        message: "one_key_login_request_token_result")

    static let startOneKeyLoginVerify = PassportMonitorMetaLogin(code: 10024,
                                                                 level: OPMonitorLevelNormal,
                                                                 message: "start_one_key_login_verify")

    static let oneKeyLoginVerifyResult = PassportMonitorMetaLogin(code: 10025,
                                                                  level: OPMonitorLevelNormal,
                                                                  message: "one_key_login_verify_result")

    static let startOnekeyLoginNumberPrefetch = PassportMonitorMetaLogin(code: 10026,
                                                                  level: OPMonitorLevelNormal,
                                                                  message: "start_one_key_login_number_prefetch")

    static let onekeyLoginNumberPrefetchResult = PassportMonitorMetaLogin(code: 10027,
                                                                  level: OPMonitorLevelNormal,
                                                                  message: "one_key_login_number_prefetch_result")

    static let startOneKeyLoginPrepare = PassportMonitorMetaLogin(code: 10028,
                                                                  level: OPMonitorLevelNormal,
                                                                  message: "start_one_key_login_prepare")

    static let oneKeyLoginPrepareResult = PassportMonitorMetaLogin(code: 10029,
                                                                  level: OPMonitorLevelNormal,
                                                                  message: "one_key_login_prepare_result")

    static let idpLoginEnter = PassportMonitorMetaLogin(code: 10030,
                                                        level: OPMonitorLevelNormal,
                                                        message: "idp_login_enter")

    static let idpLoginCancel = PassportMonitorMetaLogin(code: 10031,
                                                         level: OPMonitorLevelNormal,
                                                         message: "idp_login_cancel")

    static let startIdpLoginPrepare = PassportMonitorMetaLogin(code: 10032,
                                                               level: OPMonitorLevelNormal,
                                                               message: "start_idp_login_prepare")

    static let idpLoginPrepareResult = PassportMonitorMetaLogin(code: 10033,
                                                                level: OPMonitorLevelNormal,
                                                                message: "idp_login_prepare_result")

    static let startIdpLoginVerify = PassportMonitorMetaLogin(code: 10034,
                                                              level: OPMonitorLevelNormal,
                                                              message: "start_idp_login_verify")

    static let idpLoginVerifyResult = PassportMonitorMetaLogin(code: 10035,
                                                               level: OPMonitorLevelNormal,
                                                               message: "idp_login_verify_result")

    static let startIdpLoginDispatch = PassportMonitorMetaLogin(code: 10036,
                                                                level: OPMonitorLevelNormal,
                                                                message: "start_idp_login_dispatch")

    static let idpLoginDispatchSuccess = PassportMonitorMetaLogin(code: 10037,
                                                                  level: OPMonitorLevelNormal,
                                                                  message: "idp_login_dispatch_success")

    static let startCommonLoginVerify = PassportMonitorMetaLogin(code: 10040,
                                                                 level: OPMonitorLevelNormal,
                                                                 message: "start_common_login_verify")

    static let commonLoginVerifyResult = PassportMonitorMetaLogin(code: 10041,
                                                                  level: OPMonitorLevelNormal,
                                                                  message: "common_login_verify_result")
}
