//
//  ProcessMonitorCode.swift
//  LarkAccount
//
//  Created by Yiming Qu on 2021/2/24.
//

import Foundation
import ECOProbe

struct ProcessMonitorCode {
    let start: OPMonitorCodeProtocol
    let success: OPMonitorCodeProtocol
    let failure: OPMonitorCodeProtocol

    static let loginType: ProcessMonitorCode = .init(
        start: PassportMonitorCodeLogin.passport_login_type_start,
        success: EPMClientPassportMonitorLoginCode.login_credential_request_succ,
        failure: PassportMonitorCodeLogin.passport_login_type_fail
    )

    static let registerType: ProcessMonitorCode = .init(
        start: PassportMonitorCodeLogin.passport_register_type_start,
        success: PassportMonitorCodeLogin.passport_register_type_success,
        failure: PassportMonitorCodeLogin.passport_register_type_fail
    )

    static let bindContact: ProcessMonitorCode = .init(
        start: PassportMonitorCodeLogin.passport_bind_contact_start,
        success: PassportMonitorCodeLogin.passport_bind_contact_success,
        failure: PassportMonitorCodeLogin.passport_bind_contact_fail
    )

    static let applyCode: ProcessMonitorCode = .init(
        start: PassportMonitorCodeLogin.passport_otp_apply_code_start,
        success: PassportMonitorCodeLogin.passport_otp_apply_code_success,
        failure: PassportMonitorCodeLogin.passport_otp_apply_code_fail
    )

    static let verifyCode: ProcessMonitorCode = .init(
        start: PassportMonitorCodeLogin.passport_otp_verify_code_start,
        success: EPMClientPassportMonitorLoginCode.login_auth_code_verify_request_succ,
        failure: PassportMonitorCodeLogin.passport_otp_verify_code_fail
    )

    static let verifyPwd: ProcessMonitorCode = .init(
        start: PassportMonitorCodeLogin.passport_verify_pwd_start,
        success: EPMClientPassportMonitorLoginCode.login_auth_pwd_verify_request_succ,
        failure: PassportMonitorCodeLogin.passport_verify_pwd_fail
    )

    static let verifyOtp: ProcessMonitorCode = .init(
        start: PassportMonitorCodeLogin.passport_otp_verify_otp_start,
        success: EPMClientPassportMonitorLoginCode.login_auth_otp_verify_request_succ,
        failure: PassportMonitorCodeLogin.passport_otp_verify_otp_fail
    )

    static let setPwd: ProcessMonitorCode = .init(
        start: PassportMonitorCodeLogin.passport_set_pwd_start,
        success: PassportMonitorCodeLogin.passport_set_pwd_success,
        failure: PassportMonitorCodeLogin.passport_set_pwd_fail
    )

    static let enterApp: ProcessMonitorCode = .init(
        start: PassportMonitorCodeLogin.passport_app_start,
        success: PassportMonitorCodeLogin.passport_app_success,
        failure: PassportMonitorCodeLogin.passport_app_fail
    )

    static let joinType: ProcessMonitorCode = .init(
        start: PassportMonitorCodeLogin.passport_join_type_start,
        success: PassportMonitorCodeLogin.passport_join_type_success,
        failure: PassportMonitorCodeLogin.passport_join_type_fail
    )

    static let create: ProcessMonitorCode = .init(
        start: PassportMonitorCodeLogin.passport_create_start,
        success: PassportMonitorCodeLogin.passport_create_success,
        failure: PassportMonitorCodeLogin.passport_create_fail
    )

    static let setName: ProcessMonitorCode = .init(
        start: PassportMonitorCodeLogin.passport_set_name_start,
        success: PassportMonitorCodeLogin.passport_set_name_success,
        failure: PassportMonitorCodeLogin.passport_set_name_fail
    )

    static let teamCodeJoin: ProcessMonitorCode = .init(
        start: PassportMonitorCodeLogin.passport_team_code_join_start,
        success: PassportMonitorCodeLogin.passport_team_code_join_success,
        failure: PassportMonitorCodeLogin.passport_team_code_join_fail
    )

    static let officialEmailJoin: ProcessMonitorCode = .init(
        start: PassportMonitorCodeLogin.passport_official_email_join_start,
        success: PassportMonitorCodeLogin.passport_official_email_join_success,
        failure: PassportMonitorCodeLogin.passport_official_email_join_fail
    )

    static let recoverOperator: ProcessMonitorCode = .init(
        start: PassportMonitorCodeLogin.passport_recover_operator_start,
        success: PassportMonitorCodeLogin.passport_recover_operator_success,
        failure: PassportMonitorCodeLogin.passport_recover_operator_fail
    )

    static let recoverBankcard: ProcessMonitorCode = .init(
        start: PassportMonitorCodeLogin.passport_recover_bankcard_start,
        success: PassportMonitorCodeLogin.passport_recover_bankcard_success,
        failure: PassportMonitorCodeLogin.passport_recover_bankcard_fail
    )

    static let recoverFace: ProcessMonitorCode = .init(
        start: PassportMonitorCodeLogin.passport_recover_face_start,
        success: PassportMonitorCodeLogin.passport_recover_face_success,
        failure: PassportMonitorCodeLogin.passport_recover_face_fail
    )

    static let recoverNewMobile: ProcessMonitorCode = .init(
        start: PassportMonitorCodeLogin.passport_recover_newmobile_start,
        success: PassportMonitorCodeLogin.passport_recover_newmobile_success,
        failure: PassportMonitorCodeLogin.passport_recover_newmobile_fail
    )

    static let loginMAuth: ProcessMonitorCode = .init(
        start: PassportMonitorCodeLogin.passport_login_m_auth_start,
        success: PassportMonitorCodeLogin.passport_login_m_auth_success,
        failure: PassportMonitorCodeLogin.passport_login_m_auth_fail
    )

    static let registerMAuth: ProcessMonitorCode = .init(
        start: PassportMonitorCodeLogin.passport_register_m_auth_start,
        success: PassportMonitorCodeLogin.passport_register_m_auth_success,
        failure: PassportMonitorCodeLogin.passport_register_m_auth_fail
    )
}
