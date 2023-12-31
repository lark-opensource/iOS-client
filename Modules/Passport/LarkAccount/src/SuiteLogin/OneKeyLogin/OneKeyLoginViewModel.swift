//
//  OneKeyLoginViewModel.swift
//  SuiteLogin
//
//  Created by Miaoqi Wang on 2020/6/12.
//

import Foundation
import RxSwift
import Homeric
import LarkAccountInterface
import ECOProbeMeta
import RxRelay
import LarkContainer

enum OneKeyLoginType: String, Codable {
    case register
    case login
}

extension Process {
    var oneKeyLoginType: OneKeyLoginType {
        switch self {
        case .register, .join: return .register
        case .login: return .login
        }
    }
}

class OneKeyLoginViewModel: V3ViewModel {

    let number: String
    let type: OneKeyLoginType
    let oneKeyService: OneKeyLoginService
    var needRefetch: Bool {
        // prefetch number need refetch to confirm
        return OneKeyLogin.needPrefetch(for: oneKeyService)
    }

    var needCheckBox: Bool {
        return true
    }

    var otherLoginAction: (() -> Void)?

    @Provider var ugService: AccountServiceUG

    //是否启用 ug 注册流程; 默认为 true
    public var ugRegistEnable: BehaviorRelay<Bool> = BehaviorRelay(value: true)

    init(type: OneKeyLoginType,
         number: String,
         oneKeyService: OneKeyLoginService,
         service: V3LoginService,
         otherLoginAction: (() -> Void)?,
         context: UniContextProtocol
    ) {
        self.type = type
        self.number = number
        self.otherLoginAction = otherLoginAction
        self.oneKeyService = oneKeyService
        super.init(
            step: "",
            stepInfo: PlaceholderServerInfo(),
            context: context
        )

        if let _ = UserManager.shared.foregroundUser { // user:current
            // 端内登录
            ugRegistEnable.accept(false)
        } else {
            ugService.getABTestValueForUGRegist { [weak self] result in
                self?.ugRegistEnable.accept(result)
            }
        }
    }

    func login() -> Observable<Void> {
        return Observable<String>.create { (ob) -> Disposable in
            OneKeyLogin.getLoginToken(success: { (token) in
                Self.logger.info("n_action_onekey_get_auth_token")
                ob.onNext(token)
                ob.onCompleted()
            }) { (error) in
                ob.onError(error)
            }
            return Disposables.create()
        }.flatMap {[weak self] (token) -> Observable<Void> in
            guard let self = self else { return .empty() }

            PassportMonitor.flush(EPMClientPassportMonitorLoginCode.onekey_mobile_auth_request_start, context: self.context)
            Self.logger.info("n_action_onekey_get_auth_token", body: "action: \(self.ugRegistEnable.value)", method: .timeline)

            let newContext = self.context.trace.newProcessSpan()
            return self.service
                .passportAPI
                .oneKeyLogin(OneKeyLoginReqBody(token: token, type: self.type, action: self.ugRegistEnable.value ? 1 : 0,  service: self.oneKeyService, context: newContext))
                .do(onNext: { step in
                    PassportMonitor.flush(EPMClientPassportMonitorLoginCode.onekey_mobile_auth_request_succ, context: newContext)
                    PassportMonitor.flush(EPMClientPassportMonitorLoginCode.onekey_login_end_succ,
                                          categoryValueMap: ["next_step" : step.stepData.nextStep],
                                          context: newContext)
                })
                .post(self.additionalInfo, context: newContext)
        }
    }
}

// MARK: - i18n
extension OneKeyLoginViewModel {
    var loginBtnTitle: String {
        switch type {
        case .register:
            return I18N.Lark_Login_NumberDetectSignUpButton1
        case .login:
            return I18N.Lark_Login_NumberDetectLogInButton1
        }
    }

    var otherBtnTitle: String {
        switch type {
        case .register:
            return I18N.Lark_Login_NumberDetectSignUpButton2
        case .login:
            return I18N.Lark_Login_NumberDetectLogInButton2
        }
    }

    var serviceTip: String {
        return I18N.Lark_Login_NumberDetectOperatorDesc(oneKeyService.carrierName)
    }

    var agreementPlainString: String {
        return I18N.Lark_Login_NumberDetectSignUpTerms(I18N.Lark_Login_V3_TermService, I18N.Lark_Login_V3_PrivacyPolicy, carrierPolicyName)
    }
    
    var alertPolicyPlainString: String {
        return I18N.Lark_Login_NumberDetectSignUpPopUpContent(I18N.Lark_Login_V3_TermService, I18N.Lark_Login_V3_PrivacyPolicy, carrierPolicyName)
    }

    var carrierPolicyName: String {
        switch oneKeyService {
        case .mobile: return I18N.Lark_Login_operatorAgreementChinaMobile
        case .unicom: return I18N.Lark_Login_operatorAgreementChinaUnicom
        case .telecom: return I18N.Lark_Login_operatorAgreementChinaTelecom
        }
    }

    var agreementLinks: [(String, URL)] {
        return [
            (I18N.Lark_Login_V3_TermService, Link.termURL),
            (I18N.Lark_Login_V3_PrivacyPolicy, Link.privacyURL),
            (carrierPolicyName, Link.oneKeyLoginPolicyURL)
        ]
    }

    var alertAgreementLinks: [(String, URL)] {
        return [
            (I18N.Lark_Login_V3_TermService, Link.termURL),
            (I18N.Lark_Login_V3_PrivacyPolicy, Link.privacyURL),
            (carrierPolicyName, Link.alertOneKeyLoginPolicyURL)
        ]
    }

    var policyURL: String {
        return service.config.getOneKeyLoginConfig().getPolicyURL(oneKeyService)
    }

    var timeoutContent: String {
        switch type {
        case .register: return I18N.Lark_Login_NumberDetectOverTimePopupContentSignup
        case .login: return I18N.Lark_Login_NumberDetectOverTimePopupContentLogin
        }
    }

    var serverErrorContent: String {
        switch type {
        case .register: return I18N.Lark_Login_NumberDetectOperatorErrorPopupContentSignup
        case .login: return I18N.Lark_Login_NumberDetectOperatorErrorPopupContentLogin
        }
    }
}

// MARK: - track
extension OneKeyLoginViewModel {
    func trackSwitchToOther() {
        SuiteLoginTracker.track(Homeric.ONE_CLICK_LOGIN_SWITCH_OTHER,
                               params: [TrackConst.loginType: type.rawValue, TrackConst.carrier: oneKeyService.trackName])
    }

    func trackResult(success: Bool, error: Error?) {
        var params: [String: Any] = [
            TrackConst.loginType: type.rawValue,
            TrackConst.carrier: oneKeyService.trackName,
            TrackConst.resultValue: success ? 1 : 0
        ]

        if let codeAndMsg = error?.loginCodeAndMsg() {
            params[TrackConst.errorCode] = codeAndMsg.code
            params[TrackConst.errorMsg] = codeAndMsg.msg
        }
        SuiteLoginTracker.track(Homeric.ONE_CLICK_LOGIN_RESULT, params: params)
    }
}
