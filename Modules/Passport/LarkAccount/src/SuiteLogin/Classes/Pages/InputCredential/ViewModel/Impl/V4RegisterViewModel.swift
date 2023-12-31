//
//  V4RegisterViewModel.swift
//  LarkAccount
//
//  Created by au on 2021/6/10.
//

import Foundation
import Homeric
import RxSwift
import RxCocoa
import LarkPerf
import LarkReleaseConfig
import LarkContainer
import LarkEnv
import LarkAccountInterface
import LarkUIKit
import LarkLocalizations
import Homeric

class V4RegisterViewModel: V3InputCredentialBaseViewModel {

    @Provider var tokenManager: PassportTokenManager
    @Provider var envManager: SwitchEnvironmentManager // user:checked (global-resolve)

    public var regionCodeValid: BehaviorRelay<Bool>
    private lazy var mobileCodeProvider: MobileCodeProvider = {
        return MobileCodeProvider(
            mobileCodeLocale: LanguageManager.currentLanguage,
            topCountryList: [],
            allowCountryList: allowRegionList,
            blockCountryList: blockRegionList
        )
    }()

    /// 服务端下发的 step_info 数据
    let personalInfo: V4PersonalInfo
    let userCenterInfo: V4UserOperationCenterInfo?

    init(step: String,
         process: Process,
         config: V3InputCredentialConfig,
         personalInfo: V4PersonalInfo,
         userCenterInfo: V4UserOperationCenterInfo? = nil,
         inputInfo: V3InputInfo? = nil,
         simplifyLogin: Bool = false,
         context: UniContextProtocol) {
        self.personalInfo = personalInfo
        self.userCenterInfo = userCenterInfo
        self.regionCodeValid = BehaviorRelay(value: false)
        super.init(step: step, process: process, config: config, inputInfo: inputInfo, simplifyLogin: simplifyLogin, context: context)
        if let item = personalInfo.credentialInputList.first {
            // 创建 CP 输入时的默认方式，以服务端返回的类型为准
            self.method.accept(item.credentialType.method)
        }

        self.credentialRegionCode
            .map { [weak self] code -> Bool in
                guard let self = self else { return false }

                let isValid = self.mobileCodeProvider.searchCountry(searchCode: code) != nil
                if !isValid {
                    self.trackInvalidRegionCode(code: code)
                }
                return isValid
            }
            .bind(to: regionCodeValid)
    }

    private func trackInvalidRegionCode(code: String) {
        var phonePrefix = code
        if code.starts(with: "+") {
            phonePrefix = code.substring(from: 1)
        }
        SuiteLoginTracker.track(Homeric.TNS_PASSPORT_NON_SCAN_OR_INVITECODE_CROSS_BORDER_ALERT_VIEW,
                                params: [
                                    TrackConst.phonePrefix : phonePrefix,
                                    TrackConst.templateID : TrackConst.none,
                                    TrackConst.trackingCode : TrackConst.none,
                                    TrackConst.passportAppID : TrackConst.none,
                                    TrackConst.flowType : stepInfo.flowType ?? TrackConst.none
                                ])
    }

    override func doType(
        serverInfo: ServerInfo,
        contact: String,
        method: SuiteLoginMethod,
        regionCode: String,
        name: String) -> Observable<Void> {
        return doTenantInformationType(contact: contact, method: method, regionCode: regionCode, name: name, sceneInfo: nil, context: context)
    }

    func doTenantInformationType(
        contact: String,
        method: SuiteLoginMethod,
        regionCode: String,
        name: String,
        sceneInfo: [String: String]?,
        context: UniContextProtocol
    ) -> Observable<Void> {
        logger.info("tenant information with method: \(method), regionCode: \(regionCode)")
        let credentialType = method.toCredentialType()
        let credentialInfo = V4CredentialInfo(credential: contact, credentialType: credentialType)
        PassportMonitor.flush(PassportMonitorMetaStep.startPersonalInfoCommit,
                              eventName: ProbeConst.monitorEventName,
                              categoryValueMap: [ProbeConst.flowType: self.flowType],
                              context: self.context)
        let startTime = Date()
        return api.tenantInformation(serverInfo: personalInfo, credentialInfo: credentialInfo, name: name, sceneInfo: sceneInfo, context: context)
                .do { _ in
                    PassportMonitor.monitor(PassportMonitorMetaStep.personalInfoCommitResult,
                                                  eventName: ProbeConst.monitorEventName,
                                                  categoryValueMap: [ProbeConst.flowType: self.flowType,
                                                                     ProbeConst.duration: Int(Date().timeIntervalSince(startTime) * 1000)],
                                                  context: self.context)
                    .setResultTypeSuccess()
                    .flush()
                } onError: { error in
                    PassportMonitor.monitor(PassportMonitorMetaStep.personalInfoCommitResult,
                                                  eventName: ProbeConst.monitorEventName,
                                                  categoryValueMap: [ProbeConst.flowType: self.flowType],
                                                  context: self.context)
                    .setResultTypeFail()
                    .setPassportErrorParams(error: error)
                    .flush()
                }
                .post(credentialInfo, context: context)



    }

}

extension V4RegisterViewModel: V4RegisterInputCredentialViewModelProtocol {

    var flowType: String { personalInfo.flowType ?? "" }

    var title: String { personalInfo.title ?? I18N.Lark_Login_V3_RegisterTitle() }

    var subtitle: String {
        if simplifyLogin {
            return ""
        } else {
            return personalInfo.subtitle ?? I18N.Lark_Login_V3_RegisterDesc()
        }
    }

    var namePlaceholder: String { personalInfo.nameInput.placeholder ?? "" }

    var nextButtonTitle: String {
        if let text = personalInfo.nextButton?.text {
            return text
        } else {
            return I18N.Lark_Login_V3_NextStep
        }
    }

    var processTip: NSAttributedString { return NSAttributedString(string: "") }

    var canChangeMethod: Bool {

        // 当服务端有 unit 返回时，Lark 环境可以切换方式
        // MultiGeo updated
        if let brand = personalInfo.tenantBrand, !brand.isEmpty {
            return brand == TenantBrand.lark.rawValue
        }

        switch method.value {
        case .email:
            return config.enableMobileReg
        case .phoneNumber:
            return config.enableEmailReg
        }
    }

    var needQRLogin: Bool { false }

    var switchButtonText: String {
        switch method.value {
        case .phoneNumber:
            return I18N.Lark_Login_V3_UseMailRegister
        case .email:
            return I18N.Lark_Login_V3_UsePhoneRegister
        }
    }

    var pageName: String { Homeric.REGISTER_ENTER_ACCOUNT_INPUT }

    var needPolicyCheckbox: Bool { shouldShowAgreementAlertForCurrentEnv() }

    var needProcessTipLabel: Bool { false }

    var needBottomView: Bool {
        if simplifyLogin {
            return false
        }
        return bottomActions != .none || !resultSupportChannel.isEmpty
    }

    var needJoinMeetingView: Bool { PassportSwitch.shared.value(.joinMeeting) && !simplifyLogin }

    var needSubtitle: Bool { true }

    var needOneKeyLogin: Bool { !simplifyLogin }

    var bottomActions: BottomAction {
        var bottomActions: BottomAction = .none
        if PassportSwitch.shared.value(.toBIdPLogin) {
            bottomActions.insert(.enterpriseLogin)
        }
        if PassportSwitch.shared.value(.joinTeam), config.enableRegisterJoinType {
            bottomActions.insert(.joinTeam)
        }
        return bottomActions
    }

    var needLocaleButton: Bool { false }

    var credentialInputList: [V4CredentialInputInfo] { personalInfo.credentialInputList }

    func cleanTokenIfNeeded() {
        tokenManager.cleanToken()
    }

    func revertEnvIfNeeded() {}

    var keepLoginText: NSAttributedString { NSAttributedString(string: "") }

    var needKeepLoginTip: Bool { false }

    // 如果服务端返回 unit 信息，代表此时是端内加入团队流程，数据的显示根据 unit 的归属为准

    var topCountryList: [String] {
        // MultiGeo updated
        guard let brand = personalInfo.tenantBrand, !brand.isEmpty else {
            return service.topCountryList
        }
        let configEnv: String = brand == TenantBrand.lark.rawValue ? V3ConfigEnv.lark : V3ConfigEnv.feishu
        return service.configInfo.config().topCountryList(for: configEnv)
    }

    var blackCountryList: [String] {
        // MultiGeo updated
        guard let brand = personalInfo.tenantBrand, !brand.isEmpty else {
            return service.blackCountryList
        }
        let configEnv: String = brand == TenantBrand.lark.rawValue ? V3ConfigEnv.lark : V3ConfigEnv.feishu
        return service.configInfo.config().blackCountryList(for: configEnv)
    }
    
    var allowRegionList: [String] {
        return personalInfo.allowRegionList ?? []
    }
    
    var blockRegionList: [String] {
        return personalInfo.blockRegionList ?? blackCountryList
    }

    var joinTeamInFeishu: Bool {
        // MultiGeo updated
        guard let brand = personalInfo.tenantBrand, !brand.isEmpty else {
            return false
        }
        let result = brand == TenantBrand.feishu.rawValue
        return result
    }

    var tenantUnitDomain: String? {
        return personalInfo.tenantUnitDomain
    }

    func handleSwitchAction() -> Observable<Void> {
        .just(())
    }

    var tenantBrand: TenantBrand? {
        if let rawBrand = personalInfo.tenantBrand {
            return TenantBrand(rawValue: rawBrand)
        }
        
        return nil
    }
}

extension V4RegisterViewModel: V3InputCrendentialTrackProtocol {

    func trackClickNext() {
        SuiteLoginTracker.track(Homeric.REGISTER_CLICK_NEXT)
        let current = method.value == .phoneNumber ? "phone_and_name" : "mail_and_name"
        let params = SuiteLoginTracker.makeCommonClickParams(flowType: flowType, click: "next", target: TrackConst.passportVerifyCodeView, data: ["user_info_type": current])
        SuiteLoginTracker.track(Homeric.PASSPORT_USER_INFO_SETTING_CLICK, params: params)
    }

    func trackSwitchMethod() {}

    func trackSwitchRegionCode() {
        SuiteLoginTracker.track(Homeric.REGISTER_SWITCH_COUNTRY_REGION, params: [TrackConst.countryRegion: credentialRegionCode.value])
    }

    func trackClickServiceTerm(_ URL: URL) {
        SuiteLoginTracker.track(Homeric.REGISTER_CLICK_SERVICE_TERM)
    }

    func trackClickPrivacy(_ URL: URL) {
        SuiteLoginTracker.track(Homeric.REGISTER_CLICK_PRIVACY_POLICY)
    }

    func trackClickJionTeam() {
        SuiteLoginTracker.track(Homeric.JOINTEAM_BUTTON_REGISTER_CLICK)
    }

    func trackSwitchCountryCode() {}

    func trackPrivacyCheckboxCheck() {
        SuiteLoginTracker.track(Homeric.POLICY_LINK_CHECKBOX_CHECK)
    }

    func trackClickBack() {}

    func trackClickLocaleButton() {}

    func trackViewShow() {
        let params = SuiteLoginTracker.makeCommonViewParams(flowType: flowType)
        SuiteLoginTracker.track(Homeric.PASSPORT_USER_INFO_SETTING_VIEW, params: params)
    }
}
