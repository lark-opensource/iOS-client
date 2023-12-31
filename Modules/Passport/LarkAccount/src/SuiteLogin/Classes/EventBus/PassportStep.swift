//
//  PassportStep.swift
//  SuiteLogin
//
//  Created by tangyunfei.tyf on 2020/8/23.
//

import Foundation
import LKCommonsLogging

enum PassportStep: String, PassportStepInfoProtocol {
    static let logger = Logger.log(PassportStep.self, category: "EventStep")

    case simpleResponseSuccess
    case login = "login"
    case verifyIdentity = "verify_identity_new"
    case newVerifyIdentity = "new_verify_identity"
    case recoverAccountCarrier = "recover_account_carrier"
    case recoverAccountBank = "recover_account_bank"
    case verifyChoose = "verify_choose"
    case bioAuth = "bio_auth"
    case bioAuthTicket = "auth_ticket"
    case verifyFace = "verify_face"
    case setInputCredential = "set_input_credential"
    case prepareTenant = "prepare_tenant"
    case userList = "user_list"
    case appPermission = "no_permission"
    case applyForm = "approval_form"
    case v3SetPwd = "set_pwd"
    case setPwd = "set_pwd_new"
    case setName = "set_name"
    case dispatchSetName = "dispatch_set_name"
    case operationCenter = "operation_center"
    case joinTenant = "dispatch_register"
    case joinTenantCode = "join_by_code"
    case joinTenantScan = "join_by_scan"
    case joinTenantReview = "join_tenant_review"
    case webStep = "web_step"
    case idpLogin = "idp_authentication"
    case idpLoginPage = "idp_login_page"
    case switchIdentity = "switch_identity"
    case accountSafety = "clear_page_stack"
    case magicLink = "magic_link"
    case enterApp = "enter_app"
    case accountAppeal = "account_appeal"
    case closeAll = "close_all" // 关闭当前视图回到首页
    case setPersonalInfo = "set_personal_info"
    case showDialog = "show_dialog"
    case guideDialog = "guide_dialog"
    case retrieveOpThree = "op_three_and_gov_face"
    case setCredential = "set_credential"
    case verifyCode = "verify_code"
    case authType = "auth_type"
    case qrLoginScan = "qrlogin_scan"
    case qrLoginPolling = "qr_login_polling"
    case qrLoginConfirm = "qr_login_confirm"
    case resetOtp = "reset_otp"
    case getAuthURL = "get_auth_url"
    case verificationCompleted = "verification_completed"
    case ok = "ok"
    case checkSecPwd = "check_sec_pwd"
    case setSecPwd = "set_sec_pwd"
    case verifySecPwd = "verify_sec_pwd"
    case chooseOptIn = "choose_opt_in"
    case realNameGuideWay = "real_name_guide_way"
    case webUrl = "web_url"
    case addEmail = "add_email"
    case ugCreateTenant = "ug_create_tenant"
    case setSpareCredential = "set_spare_credential"
    case showPage = "show_page"
    case ugJoinByCode = "ug_join_by_code"
    case changeGeo = "change_geo"
    case exemptRemind = "exempt_remind"
    case multiVerify = "verify_list"

    #if LarkAccount_Authorization
    case userConfirm = "user_confirm"
    #endif

    func pageInfo(with stepInfo: [String: Any]) -> ServerInfo? {
        guard let data = try? JSONSerialization.data(withJSONObject: stepInfo, options: .prettyPrinted) else {
            Self.logger.error("PassportStep: can not get pageInfo from none jsonDic)")
            return nil
        }

        var result: ServerInfo?
        do {
            let decoder = JSONDecoder()
            switch self {
            case .simpleResponseSuccess:
                result = PlaceholderServerInfo()
            case .setPersonalInfo:
                result = try decoder.decode(V4PersonalInfo.self, from: data)
            case .login:
                result = V3LoginInfo.default
            case .closeAll:
                result = try decoder.decode(CloseAllInfo.self, from: data)
            case .verifyIdentity,.verifyCode:
                result = try decoder.decode(V4VerifyInfo.self, from: data)
            case .checkSecPwd:
                result = try decoder.decode(CheckSecurityPasswordStepInfo.self, from: data)
            case .setSecPwd:
                result = try decoder.decode(SetSecurityPasswordStepInfo.self, from: data)
            case .verifySecPwd:
                result = try decoder.decode(VerifySecurityPasswordStepInfo.self, from: data)
            case .newVerifyIdentity:
                result = try decoder.decode(V3VerifyInfo.self, from: data)
            case .recoverAccountCarrier:
                result = try decoder.decode(V3RecoverAccountCarrierInfo.self, from: data)
            case .recoverAccountBank:
                result = try decoder.decode(V3RecoverAccountBankInfo.self, from: data)
            case .verifyFace:
                result = try decoder.decode(V3RecoverAccountFaceInfo.self, from: data)
            case .verifyChoose:
                result = try decoder.decode(V3RecoverAccountChooseInfo.self, from: data)
            case .setInputCredential:
                result = try decoder.decode(V3SetInputCredentialInfo.self, from: data)
            case .prepareTenant:
                result = try decoder.decode(V3CreateTenantInfo.self, from: data)
            case .userList:
                result = try decoder.decode(V4SelectUserInfo.self, from: data)
            case .appPermission:
                result = try decoder.decode(AppPermissionInfo.self, from: data)
            case .applyForm:
                result = try decoder.decode(ApplyFormInfo.self, from: data)
            case .setPwd:
                result = try decoder.decode(V4SetPwdInfo.self, from: data)
            case .v3SetPwd:
                result = try decoder.decode(V3SetPwdInfo.self, from: data)
            case .setName:
                result = try decoder.decode(V4SetNameInfo.self, from: data)
            case .dispatchSetName:
                result = try decoder.decode(V4DispatchSetNameInfo.self, from: data)
            case .operationCenter:
                result = try decoder.decode(V4UserOperationCenterInfo.self, from: data)
            case .joinTenant:
                result = try decoder.decode(V4JoinTenantInfo.self, from: data)
            case .joinTenantCode:
                result = try decoder.decode(V4JoinTenantCodeInfo.self, from: data)
            case .joinTenantScan:
                result = try decoder.decode(V4JoinTenantScanInfo.self, from: data)
            case .joinTenantReview:
                result = try decoder.decode(V4JoinTenantReviewInfo.self, from: data)
            case .bioAuth:
                result = try decoder.decode(V4BioAuthInfo.self, from: data)
            case .bioAuthTicket:
                result = try decoder.decode(V4BioAuthTicketInfo.self, from: data)
            case .webStep:
                result = V3WebStepInfo.from(stepInfo)
            case .idpLogin:
                result = IDPLoginInfo.from(stepInfo)
            case .idpLoginPage:
                // 服务端没有返回数据，只要跳转到 SSO 登录页面就好
                result = V3EnterpriseInfo(nextInString: nil, flowType: nil, isAddCredential: false)
            case .switchIdentity:
                result = try decoder.decode(SwitchIdentityStepInfo.self, from: data)
            case .accountSafety:
                result = try decoder.decode(AccountMessage.self, from: data)
            case .magicLink:
                result = try decoder.decode(V3MagicLinkInfo.self, from: data)
            case .enterApp:
                result = try decoder.decode(V4EnterAppInfo.self, from: data)
            case .accountAppeal:
                result = try decoder.decode(V3AccountAppeal.self, from: data)
            case .showDialog:
                result = try decoder.decode(V4ShowDialogStepInfo.self, from: data)
            case .guideDialog:
                result = try decoder.decode(GuideDialogStepInfo.self, from: data)
            case .retrieveOpThree:
                result = try decoder.decode(V4RetrieveOpThreeInfo.self, from: data)
            case .authType:
                result = try decoder.decode(AuthTypeInfo.self, from: data)
            case .qrLoginScan:
                // 这个 step 返回的结构不是 ServerInfo，由上层业务解析
                throw V3LoginError.clientError("Should never happen")
            case .qrLoginPolling:
                result = try decoder.decode(QRCodeLoginInfo.self, from: data)
            case .qrLoginConfirm:
                result = try decoder.decode(QRCodeLoginConfirmInfo.self, from: data)
            case .resetOtp:
                result = try decoder.decode(ResetOtpInfo.self, from: data)
            case .getAuthURL:
                result = try decoder.decode(GetAuthURLInfo.self, from: data)
            case .verificationCompleted:
                result = try decoder.decode(VerificationCompletedInfo.self, from: data)
            case .chooseOptIn:
                result = try decoder.decode(ChooseOptInInfo.self, from: data)
            case .ok:
                result = try decoder.decode(OKInfo.self, from: data)
            case .realNameGuideWay:
                result = try decoder.decode(RealNameGuideWayInfo.self, from: data)
            case .webUrl:
                result = try decoder.decode(V3WebUrl.self, from: data)
            case .addEmail:
                result = try decoder.decode(AddMailStepInfo.self, from: data)
            case .setSpareCredential:
                result = try decoder.decode(SetSpareCredentialInfo.self, from: data)
            case .showPage:
                result = try decoder.decode(ShowPageInfo.self, from: data)
            case .changeGeo:
                result = try decoder.decode(ChangeGeoStepInfo.self, from: data)
            case .multiVerify:
                result = try decoder.decode(MultiVerifyBaseStepInfo.self, from: data)
            #if LarkAccount_Authorization
            case .userConfirm:
                result = try decoder.decode(V3UserConfirm.self, from: data)
            case .setCredential:
                result = try decoder.decode(SetCredentialInfo.self, from: data)
            case .ugCreateTenant:
                result = try decoder.decode(UGCreateTenantInfo.self, from: data)
            case .ugJoinByCode:
                result = try decoder.decode(UGJoinByCodeInfo.self, from: data)
            case .exemptRemind:
                result = try decoder.decode(OKInfo.self, from: data)
            #endif
            }
        } catch {
            Self.logger.error("login wrong step info step: \(self) error: \(error)")
            result = nil
        }
        var nextInfoString = ""
        if let nextInfoDict = stepInfo["next"] as? [String: Any] {
            nextInfoString = nextInfoDict.jsonString()
        }
        result?.nextInString = nextInfoString
        if var info = result as? (RawStepInfoKeepable & ServerInfo) {
            info.rawStepInfo = stepInfo
            return info
        }
        return result
    }
}

protocol ServerInfo: Codable {
    /// 下一 step 名称，老模型中 step info 中包含 next 字段
    var nextInString: String? { get set }

    /// 服务端用于串联一个流程
    var flowType: String? { get }

    /// 是否使用包环境域名，目前在注册团队阶段生效
    var usePackageDomain: Bool? { get }
}

extension ServerInfo {
    // 返回的ServerInfo如果需要进行二次修改，需要子类自行保存
    func nextServerInfo(for step: String) -> ServerInfo? {
        if let nextInString = self.nextInString {
            let data = Data(nextInString.utf8)
            if let nextInDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                let passportStep = PassportStep(rawValue: step),
                let nextStepInfoDict = nextInDict[step] as? [String: Any],
                let nextServerInfo = passportStep.pageInfo(with: nextStepInfoDict) {
                    return nextServerInfo
            }
        }
        return nil
    }
}

/// 遵循该协议的 step info 会带上原始返回的所有 key-value dictionary
protocol RawStepInfoKeepable {
    var rawStepInfo: [String: Any]? { get set }
}
