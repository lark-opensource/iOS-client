//
//  V3LoginViewModel.swift
//  SuiteLogin
//
//  Created by quyiming on 2020/3/12.
//

import Foundation
import Homeric
import RxSwift
import LarkReleaseConfig
import LarkPerf
import LarkFoundation
import LarkContainer
import LarkUIKit
import ECOProbeMeta
import LarkSetting

class V3LoginViewModel: V3InputCredentialBaseViewModel {

    @Provider var tokenManager: PassportTokenManager

    override func doType(
        serverInfo: ServerInfo,
        contact: String,
        method: SuiteLoginMethod,
        regionCode: String,
        name: String) -> Observable<Void> {
        return doLoginType(
            serverInfo: serverInfo,
            contact: contact,
            method: method,
            regionCode: regionCode,
            sceneInfo: [
                MultiSceneMonitor.Const.scene.rawValue: MultiSceneMonitor.Scene.enterContact.rawValue,
                MultiSceneMonitor.Const.type.rawValue: "login",
                MultiSceneMonitor.Const.result.rawValue: "success"
            ],
            context: context.trace.newProcessSpan()
        )
    }

    func doLoginType(
        serverInfo: ServerInfo,
        contact: String,
        method: SuiteLoginMethod,
        regionCode: String,
        sceneInfo: [String: String]?,
        context: UniContextProtocol
    ) -> Observable<()> {
        // duplicate with LOGIN_CLICK_NEXT
        SuiteLoginTracker.track(Homeric.LOGIN_ACCOUNT_NEXT)
        logger.info("n_action_login", body: "method: \(method), regionCode: \(regionCode), action: \(ugRegistEnable.value)", method: .local)
        let credentialType = method.toCredentialType()
        let action = ugRegistEnable.value ? 1 : 0
        return api
            .loginType(serverInfo: serverInfo, contact: contact, credentialType: credentialType, action: action, sceneInfo: sceneInfo, forceLocal: false, context: context)
            .flatMap({ [weak self] step -> Observable<Void> in
                // ChangeGeo：https://bytedance.feishu.cn/docx/Vi9FdXgF3o3JZQxay0qc9ZTQnw7
                guard let self = self,
                      let nextStep = PassportStep(rawValue: step.stepData.nextStep), nextStep == .changeGeo else {
                    return Observable<V3.Step>.just(step).post(context: context)
                }
                
                guard V3NormalConfig.enableChangeGeo,
                      let changeGeoStepInfo = PassportStep.changeGeo.pageInfo(with: step.stepData.stepInfo) as? ChangeGeoStepInfo else {
                    return self.api.loginType(serverInfo: serverInfo, contact: contact, credentialType: credentialType, action: action, sceneInfo: sceneInfo, forceLocal: true, context: context)
                        .post(context: context)
                }
                
                self.logger.info("n_change_geo_update_domain", body: "domain: \(changeGeoStepInfo.targetDomain)")
                let changeGeoContext = UniContextCreator.create(.login, flowDomain: .custom(domain: changeGeoStepInfo.targetDomain))
                return self.api.loginType(serverInfo: serverInfo, contact: contact, credentialType: credentialType, action: action, sceneInfo: sceneInfo, forceLocal: true, context: changeGeoContext)
                    .post(context: changeGeoContext)
            })
    }


    override public init(
        step: String,
        process: Process,
        config: V3InputCredentialConfig,
        inputInfo: V3InputInfo? = nil,
        simplifyLogin: Bool = false,
        context: UniContextProtocol
    ) {
        super.init(
            step: step,
            process: process,
            config: config,
            inputInfo: inputInfo,
            simplifyLogin: simplifyLogin,
            context: context
        )
        // 这里Setting开关关闭时为2，可以控制这段逻辑不执行
        if supportLoginMethods.count == 1 {
            self.method.accept(supportLoginMethods[0])
        }
    }
}

extension V3LoginViewModel: V3InputCredentailViewModelProtocol {

    var needOnekeyLogin: Bool {
        return ReleaseConfig.isFeishu && !fromUserCenter
    }

    var needQRLogin: Bool {
        let enableQRLogin = getDisplayViewSetting(for: "login_enable_qr_code_entry") ?? true
        return enableQRLogin && Display.pad
    }

    var title: String { I18N.Lark_Login_V3_LoginTitle() }

    var subtitle: String { I18N.Lark_Login_V3_LoginTip() }

    var processTip: NSAttributedString {
        let attributedString = NSMutableAttributedString.tip(str: I18N.Lark_Passport_Newlogin_HomePageSwitchSignUpButton, color: UIColor.ud.N500)
        let suffixLink = NSAttributedString.link(
            str: I18N.Lark_Login_V3_notregtoreg,
            url: Link.registerURL,
            font: UIFont.systemFont(ofSize: 14.0)
        )
        attributedString.append(suffixLink)
        return attributedString
    }

    var canChangeMethod: Bool {
        // 这里Setting开关关闭时为2，可以控制这段逻辑不执行
        if supportLoginMethods.count == 1 {
            return false
        }
        return true
    }

    var switchButtonText: String {
        switch method.value {
        case .phoneNumber:
            return I18N.Lark_Login_V3_UseEmailLogin
        case .email:
            return I18N.Lark_Login_V3_UsePhoneLogin
        }
    }

    var pageName: String { Homeric.LOGIN_ENTER_ACCOUNT_INPUT }

    var needPolicyCheckbox: Bool { shouldShowAgreementAlertForCurrentEnv() }

    var needProcessTipLabel: Bool { !ugRegistEnable.value }

    //是否需要b端idp登录按钮
    var needBIdpView: Bool {
        let needBIdpViewFromSetting: Bool = getDisplayViewSetting(for: "login_enable_bidp_button") ?? true
        return (bottomActions != .none) && needBIdpViewFromSetting
    }
    //是否需要c端idp登录按钮
    var needCIdpView: Bool {
        let needCIdpViewFromSetting: Bool = getDisplayViewSetting(for: "login_enable_cidp_button") ?? true
        return (!resultSupportChannel.isEmpty) && needCIdpViewFromSetting
    }
    //该客户端下支持的登录方式
    var supportLoginMethods: [SuiteLoginMethod] {
        let loginMethodType: Int = getDisplayViewSetting(for: "login_switch_credential_tab") ?? 0
        // 兼容前端的Int枚举:  0:all,1:phone,2:email
        switch loginMethodType {
        case 1:
            return [.phoneNumber]
        case 2:
            return [.email]
        case 0:
            return [.email, .phoneNumber]
        default:
            return [.email, .phoneNumber]
        }
    }
    var needBottomView: Bool {
        needCIdpView || needBIdpView
    }

    var enableDirectOpenIDPPage: Bool {
        return getDisplayViewSetting(for: "login_sso_button_direct_open_idp") ?? false
    }

    var needJoinMeetingView: Bool { PassportSwitch.shared.value(.joinMeeting) }

    var needSubtitle: Bool { false }

    var bottomActions: BottomAction {
        var bottomActions: BottomAction = .none
        if PassportSwitch.shared.value(.toBIdPLogin) {
            bottomActions.insert(.enterpriseLogin)
        }
        if PassportSwitch.shared.value(.joinTeam), config.enableLoginJoinType {
            bottomActions.insert(.joinTeam)
        }
        return bottomActions
    }

    var needLocaleButton: Bool {
        return ( context.from == .login || context.from == .register )
    }

    var needRegisterView: Bool {
        return getDisplayViewSetting(for: "login_enable_create_entry") ?? true
    }

    func cleanTokenIfNeeded() {
        tokenManager.cleanToken()
    }

    func revertEnvIfNeeded() {
        service.revertEnvIfNeeded()
    }

    var keepLoginText: NSAttributedString {
        let font: UIFont = UIFont.systemFont(ofSize: 14.0)
        let res: String = I18N.Lark_Login_PeriodOfValidity
        let attributedString = NSAttributedString.tip(str: res, color: UIColor.ud.N500, font: font, aligment: .left)
        return attributedString
    }

    var needKeepLoginTip: Bool {
        return PassportSwitch.shared.value(.keepLoginOption)
    }

    func handleSwitchAction() -> Observable<Void> {
        guard needQRLogin else { return .just(()) }
        return api.qrLoginInit().post([CommonConst.ugRegistEnable: ugRegistEnable.value], vcHandler: nil, context: context)
    }

    //获取LarkSetting中是否展示相关点位
    func getDisplayViewSetting<T>(for key: String) -> T? {
        return try? SettingManager.shared.setting(with: UserSettingKey.make(userKeyLiteral: "passport_view_display_enable"))[key] as? T
    }
}

extension V3LoginViewModel: V3InputCrendentialTrackProtocol {

    func trackClickNext() {
        let params = SuiteLoginTracker.makeCommonClickParams(flowType: self.stepInfo.flowType ?? "", click: TrackConst.passportClickTrackNext, target: TrackConst.passportVerifyCodeView)
        SuiteLoginTracker.track(Homeric.PASSPORT_LOGIN_CLICK, params: params)
    }

    func trackSwitchMethod() {
        var click = ""
        var target = ""
        switch method.value {
        case .phoneNumber:
            click = TrackConst.passportClickTrackPhoneLogin
            target = TrackConst.passportLoginView
        case .email:
            click = TrackConst.passportClickTrackMailLogin
            target = TrackConst.passportLoginView
        }
        let params = SuiteLoginTracker.makeCommonClickParams(flowType: self.stepInfo.flowType ?? "", click: click, target: target)
        SuiteLoginTracker.track(Homeric.PASSPORT_LOGIN_CLICK, params: params)
    }

    func trackSwitchRegionCode() {
        SuiteLoginTracker.track(Homeric.LOGIN_SWITCH_COUNTRY_REGION, params: [TrackConst.countryRegion: credentialRegionCode.value])
    }

    func trackClickServiceTerm(_ URL: URL) {
        SuiteLoginTracker.track(Homeric.LOGIN_CLICK_SERVICE_TERM)
    }

    func trackClickPrivacy(_ URL: URL) {
        SuiteLoginTracker.track(Homeric.LOGIN_CLICK_PRIVACY_POLICY)
    }

    func trackClickJionTeam() {
        SuiteLoginTracker.track(Homeric.JOINTEAM_BUTTON_LOGIN_CLICK)
    }

    func trackSwitchCountryCode() {}

    func trackClickIDPLogin(_ type: IDPLoginType) {
        var target = ""
        switch type {
        case .sso:
            target = TrackConst.passportSSO
        case .google:
            target = TrackConst.passportGoogle
        case .appleID:
            target = TrackConst.passportApple
        case .unknown:
            break
        }
        let params = SuiteLoginTracker.makeCommonClickParams(flowType: self.stepInfo.flowType ?? "", click: TrackConst.passportClickTrackMoreLoginType, target: target)
        SuiteLoginTracker.track(Homeric.PASSPORT_LOGIN_CLICK, params: params)
    }

    func trackClickToRegister() {
        let params = SuiteLoginTracker.makeCommonClickParams(flowType: self.stepInfo.flowType ?? "", click: TrackConst.passportClickTrackCreateTenant, target: TrackConst.passportTeamInfoSettingView)
        SuiteLoginTracker.track(Homeric.PASSPORT_LOGIN_CLICK, params: params)
    }

    func trackClickLocaleButton() {}

    func trackViewShow() {
        let params = SuiteLoginTracker.makeCommonViewParams(flowType: self.stepInfo.flowType ?? "")
        SuiteLoginTracker.track(Homeric.PASSPORT_LOGIN_VIEW, params: params)
    }
}
