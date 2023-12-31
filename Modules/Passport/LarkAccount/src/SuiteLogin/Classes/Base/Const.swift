//
//  Const.swift
//  SuiteLogin
//
//  Created by quyiming@bytedance.com on 2019/9/22.
//

import Foundation

struct CommonConst {
    /// 中国的区号
    static let chinaRegionCode: String = "+86"

    static let USRegionCode: String = "+1"

    // MARK: Domain

    static let aboutBlank: String = "about:blank"

    /// HTTPS 前缀
    static let prefixHTTPS: String = "https://"

    static let passportSubdomain: String = "passport"

    static let slant: String = "/"

    // MARK: Http Header

    /// 登录之前标示用户状态的token
    static let passportToken: String = "X-Passport-Token"

    /// 登录后密码设置的token
    static let passportPWDToken: String = "X-Passport-PWD-Token"

    /// 登录后密码设置的token
    static let verifyToken: String = "X-Verify-Token"

    /// 流程标识，用来串联一个路径的上下文
    static let flowKey: String = "X-Flow-Key"

    /// 流程标识，用来串联一个路径的上下文，目前仅在开平增量授权时使用
    static let authFlowKey: String = "X-Auth-Flow-Key"
    
    /// ttLogID
    static let logID: String = "X-TT-LogID"

    /// 登录之后标示用户状态的session-key
    static let suiteSessionKey: String = "Suite-Session-Key"

    /// https://bytedance.feishu.cn/docs/doccnhO2gcl6imHbCuY9gUZq8Lc
    /// {{flow_type}}:{{unit}}
    static let proxyUnit: String = "X-Proxy-Unit"

    /// 用户列表的sessionkey
    static let sessionKeys: String = "X-Passport-Session-Keys"

    /// 请求id，用于追踪串联，客户端到后台日志
    static let requestId: String = "X-Request-Id"

    /// 功能环境头
    static let ttEnv: String = "X-TT-ENV"

    /// captcha token
    static let captchaToken: String = "X-Sec-Captcha-Token"

    static let contentType: String = "Content-Type"

    static let applicationJson: String = "application/json"

    static let apiVersionValue: String = "1.0.21" // v7.5

    static let passportUnit: String = "X-Passport-Unit"

    static let frontUserUUID: String = "X-Front-Uuid"
    
    static let universalDeviceId: String = "X-Passport-Uni-Did"

    // MARK: Http Params
    static let appId: String = "app_id"
    
    static let logoutTime: String = "logout_time"
    
    static let logoutTokens: String = "logout_tokens"

    static let empty: String = "empty"

    static let appName: String = "app_name"

    static let teamCode: String = "team_code"

    static let tenantCode: String = "tenant_code"

    static let stepInfo: String = "step_info"

    static let checkSessionHTTPCode: Int = 401

    static let passportApiPath: String = "suite/passport"
    static let authApiPath: String = "accounts/auth_login"
//    static let qrloginApiPath: String = passportApiPath + "/qrlogin/m"
    static let qrloginApiPath: String = v4APIPathPrefix + "/qrlogin"

    /// path: suite/passport/authentication/idp
    static let authenticationIdpApiPath: String = "accounts/idp"
    /// path: suite/passport/authentication/idp
    static let kaRIdpApiPath: String = "suite/passport/authentication/idp"
    /// path: suite/passport/v2/users/unregister
    static let userUnreigsterApiPath: String = "suite/passport/v2/users/unregister"
    /// path: suite/passport/unregister/v3
    static let v3UserUnreigsterApiPath: String = "suite/passport/unregister/v3"
    /// path: suite/passport/security
    static let securityApiPath: String = "suite/passport/security"
    /// path: accounts/security
    static let accountSecurityApiPath: String = "accounts/security"
    /// path: accounts/auth
    static let accountAuthApiPath: String = "accounts/auth"
    /// path: /accounts/auth/bio/verify
    static let bioVerifyPath: String = "auth/bio/verify"
    /// v4 path: /accounts/auth/bio/ticket
    static let bioGetTicketPath: String = "auth/bio/ticket"
    /// path: suite/passport/v2/
    static let v3SuiteApiPath: String = "suite/passport/v3"

    /// ****** 账号模型更新内容 ******

    /// V4 新接口都以 accounts 开头
    static let v4APIPathPrefix: String = "accounts"

    /// 增量授权相关接口 path 中不带 accounts，以 authen 开头
    static let authenPathPrefix: String = "authen"

    /// 来源信息，从之前接口的返回中获取
    static let flowType: String = "flow_type"
    static let credential: String = "credential"
    static let credentialType: String = "credential_type"
    static let name: String = "name"

    /// ****** ******

    static let contact: String = "contact"
    static let queryScope: String = "query_scope"
    static let queryScopeAll: String = "all"
    static let queryScopeLocale: String = "locale"
    static let sourceType: String = "source_type"
    static let codeType: String = "code_type"
    static let contactType: String = "contact_type"
    static let verifyScope: String = "scope"
    static let code: String = "code"
    static let pwd: String = "pwd"
    static let rsaToken: String = "rsa_token"
    static let authenticationChannel: String = "channel"
    static let tenantDomain: String = "tenant_domain"
    static let cpId: String = "cp_id"
    static let tenantId: String = "tenant_id"
    static let isTenantCp: String = "is_tenant_cp"
    static let idToken: String = "id_token"
    static let stateTokenKey: String = "state_token_key"
    static let channel: String = "channel"
    static let userId: String = "user_id"
    static let sessionKey: String = "session_key"
    static let bodySessionKeys: String = "session_keys"
    static let targetSessionKey: String = "target_session_key"
    static let credentialId: String = "credential_id"
    static let idpType: String = "idp_type"
    static let idpDomain: String = "tenant_domain"
    static let pattern: String = "pattern"
    static let token: String = "token"
    static let from: String = "from"
    static let mode: String = "mode"
    static let action: String = "action"
    static let usePackageDomain: String = "use_package_domain"
    static let realName: String = "real_name"
    static let idNumber: String = "id_number"
    static let tenant: String = "tenant_name"
    static let identityId: String = "identity_id"
    static let optIn: String = "opt_in"
    static let ugRegistEnable: String = "is_ug_enable"
    static let forceLocal: String = "force_local"
    static let approvalType: String = "approval_type"
    static let xMfaToken: String = "x-mfa-token"
    
    
    /// 精简登录的 pattern
    static let patternSimplifyLogin: String = "4"
    static let regParamsBizVC: [String: String] = ["biz_source": "vc"]

    // MARK: Other
    static let featureIdKey: String = "SuiteLogin.SuiteLoginSDK.stagingFeatureId"
    static let aesKey: String = "FF9pjX1Yb6qdovRq"

    static let logAssociateId: String = "associate_id"
    static let ssoWebUrlMode: String = "openClient"
    static let openInSystemBrowser: String = "open"
    
    static let retrieveChooseIndicator: String = "retrieve_choose_identity"

    /// 中国did服务
    static let euNCDeviceIdUrl: String = "http://toblog.snssdk.com/"
    /// 美国did服务
    static let euVADeviceIdUrl: String = "http://log.isnssdk.com/"
    /// 中国graylog服务
    static let euNCGrayLogDomain: String = "internal-api.feishu.cn"
    /// 美国graylog服务
    static let euVAGrayLogDomain: String = "internal-api.larksuite.com"

    /// 标记 closeAll 起点Key
    static let closeAllStartPointKey: String = "close_all_start_point"

    /// contact point 登录凭证
    static let cp: String = "cp"

    /// BOE Sidecar Key
    static let featureIdHeaderKey: String = "Rpc-Persist-Dyecp-DEFAULT"

    /// 标记CloseAll 起点的参数
    static let closeAllParam: [String: Bool] = [CommonConst.closeAllStartPointKey: true]
}

extension CommonConst {
    enum InjectKey {
        static let pattern: String = CommonConst.pattern
        static let regParams: String = "reg_params"
    }
}

extension CommonConst {
    
    enum SwitchType: String {
        //主动
        case onDemand = "0"
        //被动
        case passive = "1"
        //登录
        case login = "2"
    }

    enum LogoutType: String {
        //主动
        case onDemand = "0"
        //被动
        case passive = "1"
        //安全检测该 Session 存在高风险，倒计时结束后登出
        case sessionRisk = "2"
    }

}


struct TrackConst {

    // MARK: Key
    static let result: String = "result"
    static let countryRegion: String = "country_region"
    static let connectType: String = "connect_type"
    static let loginType: String = "login_type"
    static let path: String = "path"
    static let from: String = "from"
    static let setNameType: String = "set_name_type"
    static let isPersonalUse = "is_personal_use"
    static let carrier: String = "carrier"
    static let resultValue: String = "result_value"
    static let errorCode: String = "error_code"
    static let errorMsg: String = "error_msg"
    static let ugColdScene: String = "ug_cold_scene"
    static let resultSubmit: String = "result_submit"
    static let durationSubmit: String = "duration_submit"
    static let changeSubmit: String = "change_submit"
    static let userType: String = "user_type"
    static let userUniqueId: String = "user_unique_id"
    static let phonePrefix: String = "phone_prefix"
    static let templateID: String = "template_id"
    static let trackingCode: String = "tracking_code"
    static let passportAppID: String = "passport_appid"
    static let flowType: String = "flow_type"


    // MARK: Value
    static let defaultPath: String = ""
    static let pathJoin: String = "join"
    static let pathInappScanQRCode: String = "inapp_scan_qrcode"
    static let pathTokenJoinTeamNotLogin = "token_join_team_not_login"
    static let pathTokenJoinTeamLogin = "token_join_team_login"
    static let pathSelectPage = "select_page"
    static let pathLoginPageJoinMeeting = "login_page_join_meeting"
    static let pathRegisterPageJoinMeeting = "login_page_join_meeting"
    static let yes = "yes"
    static let no = "no"
    static let success = "success"
    static let fail = "fail"
    static let none = "none"

    // MARK: Target
    static let passportLoginView = "passport_login_view"
    static let passportUserInfoSettingView = "passport_user_info_setting_view"
    static let passportTeamInfoSettingView = "passport_team_info_setting_view"
    static let passportVerifyCodeView = "passport_verify_code_view"
    static let passportVerifyListView = "passport_verify_list_view"
    static let passportPwdVerifyView = "passport_pwd_verify_view"
    static let passportSuccessCreateTeamView = "passport_success_create_team_view"
    static let passportTeamCodeInputView = "passport_team_code_input_view"
    static let passportTeamQRCodeScanView = "passport_team_qr_code_sacn_view"
    static let passportCreateTeamOrPersonalUserView = "passport_create_team_or_personal_use_view"
    static let passportSSO = "SSO"
    static let passportGoogle = "google"
    static let passportApple = "apple"
    static let passportAuthedEmailTenantListView = "passport_authed_email_tenant_list_view"
    static let passportJoinTeamView = "passport_join_team_view"
    static let passportBackupVerifySettingView = "passport_backup_verify_setting_view"
    
    
    // MARK: Click
    static let passportClickTrackNext = "next"
    static let passportClickTrackCreateTeam = "create_team"
    static let passportClickTrackJoinTeam = "join_team"
    static let passportClickTrackPersonalUse = "personal_use"
    static let passportClickTrackEnterTeam = "enter_team"
    static let passportClickTrackAppeal = "appeal"
    static let passportClickTrackCheckedPrivacyPolicy = "checked_privacy_policy"
    static let passportClickTrackCancelPrivacyPolicy = "cancel_privacy_policy"
    static let passportClickTrackCreateTenant = "create_tanant"
    static let passportClickTrackPhoneLogin = "phone_login"
    static let passportClickTrackMailLogin = "mail_login"
    static let passportClickTrackMoreLoginType = "more_login_type"
    static let passportClickTrackAuthedEmailTenant = "authed_email_tenant"
    static let passportClickTrackLoginAnother = "login_another"
    static let passportClickTrackResetPwd = "reset_pwd"
    static let passportClickTrackBackupVerifySetting = "passport_backup_verify_setting_click"
}
