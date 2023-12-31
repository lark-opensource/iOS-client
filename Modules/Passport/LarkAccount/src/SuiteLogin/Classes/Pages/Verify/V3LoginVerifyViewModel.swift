//
//  LoginVerifyViewModel.swift
//  SuiteLogin
//
//  Created by Miaoqi Wang on 2019/9/18.
//

import Foundation
import RxSwift
import RxCocoa
import Homeric
import LarkPerf

class LoginVerifyState: VerifyStateProtocol {


    var verifyTip: NSAttributedString {
        switch verifyType {
        case .code:
            return verifyLoginCodeState.verifyTip
        case .forgetVerifyCode:
            return verifyForgetCodeState.verifyTip
        case .pwd:
            return verifyPwdState.verifyTip
        case .otp:
            return verifyOtpState.verifyTip
        case .spareCode:
            return verifySpareCodeState.verifyTip
        case .mo:
            return verifyMoState.verifyTip
        case .fido:
            return verifyFidoState.verifyTip
        }
    }

    var title: String {
        if let pageInfo = self.pageInfo, let title = pageInfo.title {
            return title
        }
        return localeTitle
    }

    var subtitle: NSAttributedString {
        guard let pageInfo = self.pageInfo else {
            return NSAttributedString(string: "")
        }
        return V3ViewModel.attributedString(for: pageInfo.subTitle)
    }

    var isVerifying: Bool = false


    var switchBtnTitle: String {
        // 枚举当前验证方式下下发的切换的Button（不包括找回密码、重发验证码等button）
        // 服务端保证每种验证方式只会下发最多一个切换button
        if let currentPageInfo = self.pageInfo {
            if let button = currentPageInfo.codeButton {
                return button.text
            } else if let button = currentPageInfo.otpButton {
                return button.text
            } else if let button = currentPageInfo.spareCodeButton {
                return button.text
            } else if let button = currentPageInfo.fidoButton {
                return button.text
            } else if let button = currentPageInfo.passwordButton {
                return button.text
            } else if let button = currentPageInfo.moButton {
                return button.text
            }
        }
        return ""
    }
    
    var retrieveLinkTitle: String {
        switch verifyType {
        case .code:
            return BundleI18n.suiteLogin.Lark_Login_RecoverAccountTextLink
        case .otp:
            return BundleI18n.suiteLogin.Lark_Passport_OTPVerify_ResetOTP
        case .pwd:
            return BundleI18n.suiteLogin.Lark_Passport_OTPVerify_ResetOTP
        default:
            return BundleI18n.suiteLogin.Lark_Login_RecoverAccountTextLink
        }
    }

    var needSwitchButton: Bool {
        return verifyInfo.enableChange.verifyTypeCount() > 1
    }

    var enableClientLoginMethodMemory: Bool

    var recordVerifyType: VerifyType?

    // MARK: Internal
    var verifyCodeState: VerifyCodeState {
        if verifyInfo.enableChange.contains(.code) {
            return verifyLoginCodeState
        } else if verifyInfo.enableChange.contains(.forgetVerifyCode) {
            return verifyForgetCodeState
        } else if verifyInfo.enableChange.contains(.magicLink) {
            return VerifyCodeState(verifyCodeTip: nil)
        } else {
            return VerifyCodeState(verifyCodeTip: nil)
        }
    }
    var verifyType: VerifyType
    var verifyInfo: VerifyInfoProtocol
    let verifyPwdState: VerifyPwdState
    private let verifyLoginCodeState: VerifyCodeState
    private let verifyForgetCodeState: VerifyCodeState
    let verifyOtpState: VerifyCodeState
    let verifySpareCodeState: VerifyCodeState
    let verifyMoState: VerifyMoState
    let verifyFidoState: VerifyFidoState

    init(verifyInfo: VerifyInfoProtocol,
         verifyPwdState: VerifyPwdState,
         verifyLoginCodeState: VerifyCodeState,
         verifyForgetCodeState: VerifyCodeState,
         verifySpareCodeState: VerifyCodeState,
         verifyOtpState: VerifyCodeState,
         verifyMoState: VerifyMoState,
         verifyFidoState: VerifyFidoState) {
        self.enableClientLoginMethodMemory = verifyInfo.enableClientLoginMethodMemory ?? false
        self.verifyType = verifyInfo.defaultType
        self.verifyInfo = verifyInfo
        self.verifyPwdState = verifyPwdState
        self.verifyLoginCodeState = verifyLoginCodeState
        self.verifyForgetCodeState = verifyForgetCodeState
        self.verifySpareCodeState = verifySpareCodeState
        self.verifyOtpState = verifyOtpState
        self.verifyMoState = verifyMoState
        self.verifyFidoState = verifyFidoState
    }

    var pageInfo: VerifyPageInfo? {
        switch verifyType {
        case .code:
            return verifyInfo.verifyCode
        case .pwd:
            return verifyInfo.verifyPwd
        case .forgetVerifyCode:
            return verifyInfo.forgetVerifyCode
        case .otp:
            return verifyInfo.verifyOtp
        case .spareCode:
            return verifyInfo.verifyCodeSpare
        case .mo:
            return verifyInfo.verifyMo
        case .fido:
            return verifyInfo.verifyFido
        }
    }

    private var localeTitle: String {
        switch verifyType {
        case .pwd:
            return I18N.Lark_Login_V3_InputPassword
        case .code:
            return I18N.Lark_Login_V3_InputVerifyCode
        case .forgetVerifyCode, .otp, .spareCode, .mo, .fido:
            V3ViewModel.logger.error("unepxect use localtile verityType: \(verifyType)")
            return ""
        }
    }

}

class V3LoginVerifyViewModel: V3ViewModel, VerifyViewModelProtocol, VerifyProtocol, WebauthNServiceProtocol {


    let api: VerifyAPIProtocol
    var webAuthNService: PassportWebAuthService?

    var verifyInfo: VerifyInfoProtocol { verifyState.verifyInfo }
    var verifyType: VerifyType {
        get {
            verifyState.verifyType
        }
        set {
            verifyState.verifyType = newValue
        }
    }

    var needSwitchBtn: Bool {
        return verifyInfo.enableChange.verifyTypeCount() > 1
    }

    var state: VerifyStateProtocol {
        return verifyState
    }
    
    var retrieveLinkTitle: String {
        return verifyState.retrieveLinkTitle
    }
    
    let verifyState: LoginVerifyState

    let forgetVerifyCodePageInfo: VerifyPageInfo?

    let switchUserSub: PublishSubject<SwitchUserStatus>?

    var recordVerifyType: VerifyType? {
        get {
            return verifyState.recordVerifyType
        }
        set {
            verifyState.recordVerifyType = newValue
        }
    }


    init(
        step: String,
        api: VerifyAPIProtocol,
        verifyInfo: VerifyInfoProtocol & ServerInfo,
        context: UniContextProtocol,
        switchUserSub: PublishSubject<SwitchUserStatus>? = nil
    ) {
        self.api = api
        self.switchUserSub = switchUserSub
        let enableResetPwd = verifyInfo.enableChange.contains(.forgetVerifyCode) && verifyInfo.forgetVerifyCode != nil
        self.forgetVerifyCodePageInfo = verifyInfo.forgetVerifyCode
        let verifyPwdState = VerifyPwdState(enableResetPwd: enableResetPwd)
        let verifyCodeState = VerifyCodeState(verifyCodeTip: verifyInfo.verifyCode?.verifyCodeTip)
        let verifyForgetCodeState = VerifyCodeState(verifyCodeTip: verifyInfo.forgetVerifyCode?.verifyCodeTip)
        let verifyOtpState = VerifyCodeState(verifyCodeTip: verifyInfo.verifyOtp?.verifyCodeTip, hasApplyCode: true)
        let verifySpareCodeState = VerifyCodeState(verifyCodeTip: verifyInfo.verifyCodeSpare?.verifyCodeTip)
        let verifyMoState = VerifyMoState(verifyMoTip: verifyInfo.verifyMo?.subTitle)
        let verifyFidoState = VerifyFidoState(verifyFidoTip: verifyInfo.verifyFido?.subTitle)
        verifyState = LoginVerifyState(
            verifyInfo: verifyInfo,
            verifyPwdState: verifyPwdState,
            verifyLoginCodeState: verifyCodeState,
            verifyForgetCodeState: verifyForgetCodeState,
            verifySpareCodeState: verifySpareCodeState,
            verifyOtpState: verifyOtpState,
            verifyMoState: verifyMoState,
            verifyFidoState: verifyFidoState
        )
        super.init(
            step: step,
            stepInfo: verifyInfo,
            context: context
        )
    }

    func trackSwitchLoginWay() {
        switch nextVerityType() {
        case .code,.spareCode:
            if verifyInfo.enableChange.contains(.magicLink) {
                SuiteLoginTracker.track(Homeric.LOGIN_SWITCH_TO_MAGIC_LINK)
            } else {
                SuiteLoginTracker.track(Homeric.PASSPORT_VERIFY_CODE_PAGE_CLICK, params: [
                    "click": "change_method",
                    "target": "none",
                    "change_to": "message"
                ])
                SuiteLoginTracker.track(Homeric.LOGIN_SWITCH_TO_CODE)
            }
        case .pwd:
            SuiteLoginTracker.track(Homeric.LOGIN_SWITCH_TO_PWD)
        case .otp:
            SuiteLoginTracker.track(Homeric.PASSPORT_VERIFY_CODE_PAGE_CLICK, params: [
                "click": "change_method",
                "target": "none",
                "change_to": "otp_code"
            ])
        case .forgetVerifyCode, .mo, .fido:
            V3ViewModel.logger.error("unexpect track verifyType: \(verifyType)")
        }
    }

    func switchLoginWay() {
        verifyType = nextVerityType()
    }

    /// VerifyType 切换策略
    private func nextVerityType() -> VerifyType {
        switch verifyType {
        case .pwd:
            return .code
        case .code,.spareCode:
            if verifyInfo.enableChange.contains(.otp) {
                return .otp
            } else {
                return .pwd
            }
        case .otp:
            return .code
        case .forgetVerifyCode:
            break
        case .mo:
            break
        case .fido:
            break
        }
        
        return verifyType
    }

    // MARK: VerifyAPIProtocol

    func applyCode() -> Observable<Void> {
        return api
            .applyCode(
                sourceType: verifyState.pageInfo?.sourceType,
                contactType: nil,
                context: context
            )
            .post(context: context)
            .catchError { error -> Observable<()> in
                if let err = error as? V3LoginError,
                    case .badServerCode(let info) = err,
                    info.type == .applyCodeTooOften,
                    let exp = info.detail[V3.Const.expire] as? uint {
                    self.verifyState.verifyCodeState.expire.accept(exp)
                    return .just(())
                } else {
                    return .error(error)
                }
            }
    }

    func verify() -> Observable<Void> {
        if self.verifyType == .pwd {
            let sceneInfo = [
                MultiSceneMonitor.Const.scene.rawValue: MultiSceneMonitor.Scene.enterVerifyPWD.rawValue,
                MultiSceneMonitor.Const.type.rawValue: self.verifyType == .forgetVerifyCode ? "forget_pwd" : "register_or_login",
                MultiSceneMonitor.Const.result.rawValue: "success"
            ]
            SuiteLoginTracker.track(Homeric.LOGIN_CLICK_VERIFY_PWD)
            return api.verify(
                serverInfo: verifyInfo,
                flowType: verifyInfo.verifyPwd?.flowType,
                password: verifyState.verifyPwdState.password,
                rsaInfo: verifyInfo.verifyPwd?.rsaInfo,
                contactType: nil,
                sceneInfo: sceneInfo,
                context: context
            ).post(additionalInfo, context: context)
        } else if verifyType == .otp {
            let sceneInfo = [
                MultiSceneMonitor.Const.scene.rawValue: MultiSceneMonitor.Scene.enterVerifyOTP.rawValue,
                MultiSceneMonitor.Const.type.rawValue: self.verifyType == .forgetVerifyCode ? "forget_pwd" : "register_or_login",
                MultiSceneMonitor.Const.result.rawValue: "success"
            ]
            return api.verifyOtp(
                sourceType: verifyState.pageInfo?.sourceType,
                code: verifyState.verifyOtpState.code,
                sceneInfo: sceneInfo,
                context: context
            )
            .post(additionalInfo, context: context)
            .do(onNext: { (_) in
                SuiteLoginTracker.track(Homeric.PASSPORT_VERIFY_CODE_PAGE_CLICK, params: [
                    "click": "next",
                    "target": "none",
                    "verify_type": "otp_code",
                    "is_success": "true"
                ])
            }, onError: { _ in
                SuiteLoginTracker.track(Homeric.PASSPORT_VERIFY_CODE_PAGE_CLICK, params: [
                    "click": "next",
                    "target": "none",
                    "verify_type": "otp_code",
                    "is_success": "false"
                ])
            })
        } else {
            let sceneInfo = [
                MultiSceneMonitor.Const.scene.rawValue: MultiSceneMonitor.Scene.enterVerifyCode.rawValue,
                MultiSceneMonitor.Const.type.rawValue: self.verifyType == .forgetVerifyCode ? "forget_pwd" : "register_or_login",
                MultiSceneMonitor.Const.result.rawValue: "success"
            ]
            SuiteLoginTracker.track(Homeric.REGISTER_CLICK_VERIFY_CODE, params: [
                "source_type": verifyState.pageInfo?.sourceType ?? 0
            ])

            Self.logger.info("n_action_old_verify_code_req")

            return api
                .v3Verify(
                    sourceType: verifyState.pageInfo?.sourceType,
                          code: verifyState.verifyCodeState.code,
                   contactType: nil,
                     sceneInfo: sceneInfo,
                       context: context
                )
                .post(additionalInfo, context: self.context)
                .do(onNext: { (_) in
                    Self.logger.info("n_action_old_verify_code_req_succ")
                    SuiteLoginTracker.track(Homeric.PASSPORT_VERIFY_CODE_PAGE_CLICK, params: [
                        "click": "next",
                        "target": "none",
                        "verify_type": "message",
                        "is_success": "true"
                    ])
                    SuiteLoginTracker.track(Homeric.VERIFY_CODE_VERIFY_SUCCESS)
                }, onError: { error in
                    Self.logger.error("n_action_old_verify_code_req_fail", error: error)
                    SuiteLoginTracker.track(Homeric.PASSPORT_VERIFY_CODE_PAGE_CLICK, params: [
                        "click": "next",
                        "target": "none",
                        "verify_type": "message",
                        "is_success": "false"
                    ])
                    SuiteLoginTracker.track(Homeric.VERIFY_CODE_VERIFY_FAIL)
                })
        }
    }

    func recoverTypeResetPwd() -> Observable<Void> {
        return api.recoverType(
            sourceType: self.forgetVerifyCodePageInfo?.sourceType ?? BioAuthSourceType.resetPassword,
            context: context
        ).post(context: context)
    }

    func recoverTypeAccountRecover(
        from: RecoverAccountSourceType
    ) -> Observable<Void> {
        return api.recoverType(
            sourceType: BioAuthSourceType.accountRecoverBeforeLogin,
            context: context
        ).post(
            ["from", from.rawValue],
            context: context
        )
    }

    func postToMagicLink() -> Observable<Void> {
        return Observable.create { (observer) -> Disposable in
            guard let magicLinkInfo = self.verifyInfo.nextServerInfo(for: PassportStep.magicLink.rawValue) else {
                Self.logger.error("can not post to magic link without next info")
                observer.onError(EventBusError.invalidParams)
                return Disposables.create()
            }
            self.post(
                event: PassportStep.magicLink.rawValue,
                serverInfo: magicLinkInfo,
                additionalInfo: self.additionalInfo,
                success: {
                    observer.onNext(())
                    observer.onCompleted()
                }) { (error) in
                    observer.onError(error)
            }
            return Disposables.create()
        }
    }

    override func clickClose() {
        V3ViewModel.logger.info("send cancel")
        switchUserSub?.onNext(.cancel)
        switchUserSub?.onCompleted()
    }
}

extension V3LoginVerifyViewModel {

    var needSkipWhilePop: Bool {
        switch verifyType {
        case .pwd:
            return false
        case .code, .forgetVerifyCode, .otp, .spareCode, .mo, .fido:
            return true
        }
    }

    var pageName: String {
        switch verifyType {
        case .pwd:
            return Homeric.LOGIN_ENTER_VERIFY_PWD
        case .code, .forgetVerifyCode, .otp,.spareCode, .mo, .fido:
            return Homeric.PASSPORT_ENTER_VERIFY_CODE
        }
    }
}

extension V3LoginVerifyViewModel {
    static public func attributedString(_ subtitle: String, _ contact: String, paraStyle: NSParagraphStyle? = nil) -> NSAttributedString {
        let boldAttributed: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14.0, weight: .bold),
            .foregroundColor: UIColor.ud.textTitle
        ]

        let res = subtitle.replacingOccurrences(
            of: V3VerifyInfo.contactPlaceholder,
            with: contact
        )

        let resultAttributedString = NSMutableAttributedString(attributedString: defaultAttributedString(res, paraStyle: paraStyle))
        let rng = (res as NSString).range(of: contact)
        if rng.location != NSNotFound {
            resultAttributedString.addAttributes(boldAttributed, range: rng)
        }
        return resultAttributedString
    }

    static public func defaultAttributedString(_ string: String, paraStyle: NSParagraphStyle? = nil) -> NSAttributedString {

        var attributed: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14.0, weight: .regular),
            .foregroundColor: UIColor.ud.textCaption
        ]

        if let paraStyle = paraStyle {
            attributed[.paragraphStyle] = paraStyle
        }
        return NSAttributedString(string: string, attributes: attributed)
    }
}
