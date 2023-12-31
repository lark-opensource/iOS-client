//
//  PassportMonitorMetaStep.swift
//  LarkAccount
//
//  Created by ZhaoKejie on 2023/4/27.
//

import Foundation
import ECOProbeMeta

internal let PassportMonitorMetaStepEnterAppWorkflowProcessType = 2

final class PassportMonitorMetaStep: OPMonitorCodeBase {

    static let domain = "client.monitor.passport.step"

    private init(code: Int, level: OPMonitorLevel, message: String) {
        super.init(domain: PassportMonitorMetaStep.domain, code: code, level: level, message: message)
    }

}

extension PassportMonitorMetaStep {
    static let tenantInfoEnter = PassportMonitorMetaStep(code: 10000,
                                                     level: OPMonitorLevelNormal,
                                                     message: "tenant_info_enter")

    static let tenantInfoCancel = PassportMonitorMetaStep(code: 10001,
                                                       level: OPMonitorLevelNormal,
                                                       message: "tenant_info_cancel")

    static let startTenantInfoCommit = PassportMonitorMetaStep(code: 10002,
                                                       level: OPMonitorLevelNormal,
                                                       message: "start_tenant_info_commit")

    static let tenantInfoCommitResult = PassportMonitorMetaStep(code: 10003,
                                                       level: OPMonitorLevelNormal,
                                                       message: "tenant_info_commit_result")

    static let personalInfoEnter = PassportMonitorMetaStep(code: 10004,
                                                       level: OPMonitorLevelNormal,
                                                       message: "personal_info_enter")

    static let personalInfoCancel = PassportMonitorMetaStep(code: 10005,
                                                       level: OPMonitorLevelNormal,
                                                       message: "personal_info_cancel")

    static let startPersonalInfoCommit = PassportMonitorMetaStep(code: 10006,
                                                       level: OPMonitorLevelNormal,
                                                       message: "start_personal_info_commit")

    static let personalInfoCommitResult = PassportMonitorMetaStep(code: 10007,
                                                       level: OPMonitorLevelNormal,
                                                       message: "personal_info_commit_result")

    static let setNameEnter = PassportMonitorMetaStep(code: 10008,
                                                       level: OPMonitorLevelNormal,
                                                       message: "set_name_enter")

    static let setNameCancel = PassportMonitorMetaStep(code: 10009,
                                                       level: OPMonitorLevelNormal,
                                                       message: "set_name_cancel")

    static let startSetNameCommit = PassportMonitorMetaStep(code: 10010,
                                                       level: OPMonitorLevelNormal,
                                                       message: "start_set_name_commit")

    static let setNameCommitResult = PassportMonitorMetaStep(code: 10011,
                                                       level: OPMonitorLevelNormal,
                                                       message: "set_name_commit_result")

    static let setPasswordEnter = PassportMonitorMetaStep(code: 10012,
                                                       level: OPMonitorLevelNormal,
                                                       message: "set_password_enter")

    static let setPasswordCancel = PassportMonitorMetaStep(code: 10013,
                                                       level: OPMonitorLevelNormal,
                                                       message: "set_password_cancel")

    static let startSetPasswordCommit = PassportMonitorMetaStep(code: 10014,
                                                       level: OPMonitorLevelNormal,
                                                       message: "start_set_password_commit")

    static let setPasswordCommitResult = PassportMonitorMetaStep(code: 10015,
                                                       level: OPMonitorLevelNormal,
                                                       message: "set_password_commit_result")

    static let startSetPasswordSkip = PassportMonitorMetaStep(code: 10016,
                                                       level: OPMonitorLevelNormal,
                                                       message: "start_set_password_skip")

    static let setPasswordSkipResult = PassportMonitorMetaStep(code: 10017,
                                                       level: OPMonitorLevelNormal,
                                                       message: "set_password_skip_result")

    static let chooseTenantEnter = PassportMonitorMetaStep(code: 10018,
                                                           level: OPMonitorLevelNormal,
                                                           message: "choose_tenant_enter")

    static let chooseTenantCancel = PassportMonitorMetaStep(code: 10019,
                                                            level: OPMonitorLevelNormal,
                                                            message: "choose_tenant_cancel")

    static let startChooseTenant = PassportMonitorMetaStep(code: 10020,
                                                           level: OPMonitorLevelNormal,
                                                           message: "start_choose_tenant")

    static let chooseTenantResult = PassportMonitorMetaStep(code: 10021,
                                                            level: OPMonitorLevelNormal,
                                                            message: "choose_tenant_result")

    static let codeVerifyEnter = PassportMonitorMetaStep(code: 10022,
                                                         level: OPMonitorLevelNormal,
                                                         message: "code_verify_enter")

    static let codeVerifyCancel = PassportMonitorMetaStep(code: 10023,
                                                          level: OPMonitorLevelNormal,
                                                          message: "code_verify_cancel")

    static let startCodeApply = PassportMonitorMetaStep(code: 10024,
                                                        level: OPMonitorLevelNormal,
                                                        message: "start_code_apply")

    static let codeApplyResult = PassportMonitorMetaStep(code: 10025,
                                                         level: OPMonitorLevelNormal,
                                                         message: "code_apply_result")

    static let startCodeVerify = PassportMonitorMetaStep(code: 10026,
                                                         level: OPMonitorLevelNormal,
                                                         message: "start_code_verify")

    static let codeVerifyResult = PassportMonitorMetaStep(code: 10027,
                                                          level: OPMonitorLevelNormal,
                                                          message: "code_verify_result")

    static let passwordVerifyEnter = PassportMonitorMetaStep(code: 10028,
                                                             level: OPMonitorLevelNormal,
                                                             message: "password_verify_enter")

    static let passwordVerifyCancel = PassportMonitorMetaStep(code: 10029,
                                                              level: OPMonitorLevelNormal,
                                                              message: "password_verify_cancel")

    static let startPasswordVerify = PassportMonitorMetaStep(code: 10030,
                                                             level: OPMonitorLevelNormal,
                                                             message: "start_password_verify")

    static let passwordVerifyResult = PassportMonitorMetaStep(code: 10031,
                                                              level: OPMonitorLevelNormal,
                                                              message: "password_verify_result")

    static let otpVerifyEnter = PassportMonitorMetaStep(code: 10032,
                                                        level: OPMonitorLevelNormal,
                                                        message: "otp_verify_enter")

    static let otpVerifyCancel = PassportMonitorMetaStep(code: 10033,
                                                         level: OPMonitorLevelNormal,
                                                         message: "otp_verify_cancel")

    static let startOtpVerify = PassportMonitorMetaStep(code: 10034,
                                                        level: OPMonitorLevelNormal,
                                                        message: "start_otp_verify")

    static let otpVerifyResult = PassportMonitorMetaStep(code: 10035,
                                                         level: OPMonitorLevelNormal,
                                                         message: "otp_verify_result")

    static let fidoVerifyEnter = PassportMonitorMetaStep(code: 10036,
                                                         level: OPMonitorLevelNormal,
                                                         message: "fido_verify_enter")

    static let fidoVerifyCancel = PassportMonitorMetaStep(code: 10037,
                                                          level: OPMonitorLevelNormal,
                                                          message: "fido_verify_cancel")

    static let startFidoVerify = PassportMonitorMetaStep(code: 10038,
                                                         level: OPMonitorLevelNormal,
                                                         message: "start_fido_verify")

    static let fidoVerifyResult = PassportMonitorMetaStep(code: 10039,
                                                          level: OPMonitorLevelNormal,
                                                          message: "fido_verify_result")

    static let moVerifyEnter = PassportMonitorMetaStep(code: 10040,
                                                       level: OPMonitorLevelNormal,
                                                       message: "mo_verify_enter")

    static let moVerifyCancel = PassportMonitorMetaStep(code: 10041,
                                                        level: OPMonitorLevelNormal,
                                                        message: "mo_verify_cancel")

    static let startMoVerify = PassportMonitorMetaStep(code: 10042,
                                                       level: OPMonitorLevelNormal,
                                                       message: "start_mo_verify")

    static let moVerifyResult = PassportMonitorMetaStep(code: 10043,
                                                        level: OPMonitorLevelNormal,
                                                        message: "mo_verify_result")

    static let backupCodeVerifyEnter = PassportMonitorMetaStep(code: 10044,
                                                               level: OPMonitorLevelNormal,
                                                               message: "backup_code_verify_enter")

    static let backupCodeVerifyCancel = PassportMonitorMetaStep(code: 10045,
                                                                level: OPMonitorLevelNormal,
                                                                message: "backup_code_verify_cancel")

    static let startBackupCodeApply = PassportMonitorMetaStep(code: 10046,
                                                              level: OPMonitorLevelNormal,
                                                              message: "start_backup_code_apply")

    static let backupCodeApplyResult = PassportMonitorMetaStep(code: 10047,
                                                               level: OPMonitorLevelNormal,
                                                               message: "backup_code_apply_result")

    static let startBackupCodeVerify = PassportMonitorMetaStep(code: 10048,
                                                               level: OPMonitorLevelNormal,
                                                               message: "start_backup_code_verify")

    static let backupCodeVerifyResult = PassportMonitorMetaStep(code: 10049,
                                                                level: OPMonitorLevelNormal,
                                                                message: "backup_code_verify_result")

    static let startEnterApp = PassportMonitorMetaStep(code: 10050,
                                                       level: OPMonitorLevelNormal,
                                                       message: "start_enter_app")

    static let enterAppResult = PassportMonitorMetaStep(code: 10051,
                                                        level: OPMonitorLevelNormal,
                                                        message: "enter_app_result")

    static let bidpVerifyEnter = PassportMonitorMetaStep(code: 10052,
                                                         level: OPMonitorLevelNormal,
                                                         message: "bidp_verify_enter")

    static let bidpVerifyCancel = PassportMonitorMetaStep(code: 10053,
                                                         level: OPMonitorLevelNormal,
                                                         message: "bidp_verify_cancel")

    static let startBidpVerify = PassportMonitorMetaStep(code: 10054,
                                                         level: OPMonitorLevelNormal,
                                                         message: "start_bidp_verify")

    static let bidpVerifyResult = PassportMonitorMetaStep(code: 10055,
                                                        level: OPMonitorLevelNormal,
                                                        message: "bidp_verify_result")

    static let appleVerifyEnter = PassportMonitorMetaStep(code: 10056,
                                                         level: OPMonitorLevelNormal,
                                                         message: "apple_verify_enter")

    static let appleVerifyCancel = PassportMonitorMetaStep(code: 10057,
                                                         level: OPMonitorLevelNormal,
                                                         message: "apple_verify_cancel")

    static let startAppleVerify = PassportMonitorMetaStep(code: 10058,
                                                         level: OPMonitorLevelNormal,
                                                         message: "start_apple_verify")

    static let appleVerifyResult = PassportMonitorMetaStep(code: 10059,
                                                        level: OPMonitorLevelNormal,
                                                        message: "apple_verify_result")

    static let googleVerifyEnter = PassportMonitorMetaStep(code: 10060,
                                                         level: OPMonitorLevelNormal,
                                                         message: "google_verify_enter")

    static let googleVerifyCancel = PassportMonitorMetaStep(code: 10061,
                                                         level: OPMonitorLevelNormal,
                                                         message: "google_verify_cancel")

    static let startGoogleVerify = PassportMonitorMetaStep(code: 10062,
                                                         level: OPMonitorLevelNormal,
                                                         message: "start_google_verify")

    static let googleVerifyResult = PassportMonitorMetaStep(code: 10063,
                                                        level: OPMonitorLevelNormal,
                                                        message: "google_verify_result")


}
