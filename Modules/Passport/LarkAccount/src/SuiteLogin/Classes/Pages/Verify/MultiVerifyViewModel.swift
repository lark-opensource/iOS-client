//
//  MultiVerifyViewModel.swift
//  LarkAccount
//
//  Created by zhaoKejie on 2023/7/26.
//

import Foundation
import RxSwift
import RxRelay
import Homeric
import SnapKit
import LarkPerf
import LarkContainer
import LKCommonsLogging
import LarkReleaseConfig

class MultiVerifyViewModel: V3ViewModel {

    let verifyBaseStepInfo: MultiVerifyBaseStepInfo

    let disposeBag = DisposeBag()

    private(set) var currentVerifyProvider: VerifyProvider

    private(set) var currentVerifyType: MultiVerifyType

    private var supportVerifyProviders: [MultiVerifyType: VerifyProvider] = [:]

    /// 用于切换'通知源'到不同验证方式
    var switchPublish: BehaviorSubject<Observable<VerifyStatus>>

    //返回的时候是否回到 feed 页面
    let backToFeed: Bool

    let enableClientLoginMethodMemory: Bool

    func getNeedSkipWhilePop() -> Bool {
        currentVerifyProvider.needSkipWhilePop
    }

    func getCurrentVerifyView() -> UIView {
        currentVerifyProvider.getVerifyContentView()
    }

    func getTitle() -> String {
        currentVerifyProvider.getVerifyPageInfo().title
    }

    func getSubtitle() -> String {
        currentVerifyProvider.getVerifyPageInfo().subtitle
    }

    func getSwitchButtonInfo() -> V4ButtonInfo? {
        currentVerifyProvider.getVerifyPageInfo().switchButton
    }

    func getNextButtonInfo() -> V4ButtonInfo? {
        currentVerifyProvider.getVerifyPageInfo().nextButton
    }

    func getRetrieveRichText() -> NSAttributedString? {
        currentVerifyProvider.getRetrieveText()
    }

    func getVerifyMethodsTable() -> VerifyMethodTable? {
        verifyBaseStepInfo.verifyAuthnMethods
    }

    func isCurrentVerify(type: ActionIconType) -> Bool {
        if let verifyType = MultiVerifyType(actionType: type) {
           return verifyType == currentVerifyType
        }
        return false
    }

    func trySwitchToNext(actionType: ActionIconType) {
       Self.logger.info("n_action_multi_verify_handle_switch")
       if let nextVerifyType = MultiVerifyType(actionType: actionType),
          let nextVerifyProvider = supportVerifyProviders[nextVerifyType] {
           self.monitorVerifyEventCancel()
           self.trackerViewClick(event: "change_to_\(nextVerifyType.rawValue)", target: TrackConst.passportVerifyListView)
           self.currentVerifyType = nextVerifyType
           self.currentVerifyProvider = nextVerifyProvider
           switchPublish.onNext(currentVerifyProvider.verifyStatus)
           monitorVerifyEventEnter()
           trackerViewEnter()
       }
    }

    func handleNextAction() {
        Self.logger.info("n_action_multi_verify_handle_next")
        if let nextStep = getNextButtonInfo()?.next,
           let stepName = nextStep.stepName,
           let stepInfo = nextStep.stepInfo {
            post(event: stepName, stepInfo: stepInfo) {
                // 日志
            } error: {[weak self] error in
                self?.currentVerifyProvider.verifyStatus.onNext(.fail(error))
            }

        } else {
            currentVerifyProvider.doVerify({})
        }
    }

    func handleRetrieveAction() {
        Self.logger.info("n_action_multi_verify_handle_retrieve")
        if let retrieveAction = getRetrieveClickName() {
            trackerViewClick(event: retrieveAction)
        }
        self.currentVerifyProvider.doRetrieve({})
    }

    func bindCurrentVerifyStatus() -> Observable<VerifyStatus> {
        switchPublish
            .switchLatest()
            .do {[weak self] verifyStatus in
                guard let self = self else { return }
                switch verifyStatus {
                case .start:
                    self.monitorVerifyEventStart()
                    Self.logger.info("n_action_multi_verify_status_start")
                case .fail(let error):
                    self.monitorVerifyEventResult(isSucceeded: false, error: error)
                    self.trackerViewClick(event: "next", additional: ["verify_result": "failed"])
                    Self.logger.error("n_action_multi_verify_status_fail", error: error)
                case .succ:
                    self.monitorVerifyEventResult(isSucceeded: true)
                    self.trackerViewClick(event: "next", additional: ["verify_result": "success"])
                    Self.logger.info("n_action_multi_verify_status_succ")

                    // 记录当前登录方式
                    if let cp = self.context.credential.cp, self.enableClientLoginMethodMemory {
                        PassportStore.shared.recordVerifyMethod(credentialKey: cp, verifyType: self.currentVerifyType.rawValue)
                    }
                case .commonError(let error):
                    Self.logger.error("n_action_multi_verify_status_common_error", error: error)
                default:
                    return
                }
            }
    }

    static func createAllVerifyProviders(verifyBaseInfo: MultiVerifyBaseStepInfo, context: UniContextProtocol) -> [MultiVerifyType: VerifyProvider] {
        // 需要把目前支持的验证方式列出

        var providers: [MultiVerifyType: VerifyProvider] = [:]
        // 手机验证码
        if var verifyMobileInfo = verifyBaseInfo.verifyMobileCodeInfo {
            verifyMobileInfo.usePackageDomain = verifyBaseInfo.usePackageDomain
            let verifyMobileCodeProvider = VerifyCodeProvider(pageInfo: verifyMobileInfo, context: context)
            providers[.mobileCode] = verifyMobileCodeProvider
        }
        // 邮箱验证
        if var verifyEmailInfo = verifyBaseInfo.verffyEmailCodeInfo {
            verifyEmailInfo.usePackageDomain = verifyBaseInfo.usePackageDomain
            let verifyEmailCodeProvider = VerifyCodeProvider(pageInfo: verifyEmailInfo, context: context)
            providers[.emailCode] = verifyEmailCodeProvider
        }
        // 备用验证方式
        if var verifySpareCodeInfo = verifyBaseInfo.verifyCodeSpareInfo {
            verifySpareCodeInfo.usePackageDomain = verifyBaseInfo.usePackageDomain
            let verifySpareCodeProvider = VerifyCodeProvider(pageInfo: verifySpareCodeInfo, context: context)
            providers[.spareCode] = verifySpareCodeProvider
        }
        // 密码验证
        if var verifyMobileInfo = verifyBaseInfo.verifyPwdInfo {
            verifyMobileInfo.usePackageDomain = verifyBaseInfo.usePackageDomain
            let verifyPwdProvider = VerifyPwdProvider(pageInfo: verifyMobileInfo, context: context)
            providers[.pwd] = verifyPwdProvider
        }
        // OTP验证
        if var verifyOtpInfo = verifyBaseInfo.verifyOtpInfo {
            verifyOtpInfo.usePackageDomain = verifyBaseInfo.usePackageDomain
            let verifyOtpProvider = VerifyOTPProvider(pageInfo: verifyOtpInfo, context: context)
            providers[.otp] = verifyOtpProvider
        }
        // FIDO验证
        if var verifyFIDOInfo = verifyBaseInfo.verifyFidoInfo {
            verifyFIDOInfo.usePackageDomain = verifyBaseInfo.usePackageDomain
            let verifyFIDOProvider = VerifyFIDOProvider(pageInfo: verifyFIDOInfo, context: context)
            providers[.fido] = verifyFIDOProvider
        }
        // Google验证
        if var verifyGoogleInfo = verifyBaseInfo.verifyGoogleInfo {
            verifyGoogleInfo.usePackageDomain = verifyBaseInfo.usePackageDomain
            let verifyGoogleProvider = VerifyIDPProvider(pageInfo: verifyGoogleInfo, context: context)
            providers[.google] = verifyGoogleProvider
        }
        // apple验证
        if var verifyAppleInfo = verifyBaseInfo.verifyAppleInfo {
            verifyAppleInfo.usePackageDomain = verifyBaseInfo.usePackageDomain
            let verifyAppleProvider = VerifyIDPProvider(pageInfo: verifyAppleInfo, context: context)
            providers[.apple] = verifyAppleProvider
        }
        // b-idp验证
        if var verifyBIDPInfo = verifyBaseInfo.verifyBIDPInfo {
            verifyBIDPInfo.usePackageDomain = verifyBaseInfo.usePackageDomain
            let verifyBIDPProvider = VerifyIDPProvider(pageInfo: verifyBIDPInfo, context: context)
            providers[.bIDP] = verifyBIDPProvider
        }
        // 上行短信验证
        if var verifyMoInfo = verifyBaseInfo.verifyMoInfo {
            verifyMoInfo.usePackageDomain = verifyBaseInfo.usePackageDomain
            let verifyMoProvider = verifyMoProvider(pageInfo: verifyMoInfo, context: context)
            providers[.mo] = verifyMoProvider
        }
        
        return providers
    }

    init(step: String, verifyInfo: MultiVerifyBaseStepInfo, context: UniContextProtocol) throws {

        // 初始化数据
        verifyBaseStepInfo = verifyInfo
        backToFeed = verifyInfo.backToFeed ?? false
        // 创建所有支持的验证
        supportVerifyProviders = MultiVerifyViewModel.createAllVerifyProviders(verifyBaseInfo: verifyInfo, context: context)
        // 初始化默认验证类型

        // 使用服务端下发的默认验证方式
        guard let verifyProvider = supportVerifyProviders[verifyInfo.defaultType] else {
            let error = V3LoginError.badResponse(I18N.Lark_Passport_BadServerData)
            Self.logger.error("n_action_default_verify_provider_error", error: error)
            throw error
        }
        currentVerifyType = verifyInfo.defaultType
        currentVerifyProvider = verifyProvider

        // 如果有客户端记录的验证方式优先用客户端记录的
        enableClientLoginMethodMemory = verifyBaseStepInfo.enableClientLoginMethodMemory ?? false
        if enableClientLoginMethodMemory,
           let cp = context.credential.cp,
           let recordVerifyTypeRawValue = PassportStore.shared.getRecordVerifyMethod(credentialKey: cp),
           let recordVerifyType = MultiVerifyType(rawValue: recordVerifyTypeRawValue),
           let recordVerifyProvider = supportVerifyProviders[recordVerifyType] {
            currentVerifyType = recordVerifyType
            currentVerifyProvider = recordVerifyProvider
        }

        self.switchPublish = BehaviorSubject<Observable<VerifyStatus>>(value: currentVerifyProvider.verifyStatus)
        super.init(step: step, stepInfo: verifyInfo, context: context)
        monitorVerifyEventEnter()
        trackerViewEnter()

    }

}

// 监控埋点相关
extension MultiVerifyViewModel {

// - MARK: 业务埋点
    func trackerViewEnter(additional: [String: Any] = [:]) {
        let flowType = self.currentVerifyProvider.getVerifyPageInfo().flowType ?? ""
        let switchButtonEnable = getSwitchButtonInfo() != nil
        var data = additional
        data["verify_type"] = currentVerifyType.rawValue
        data["is_switch_button_enable"] = switchButtonEnable
        let params = SuiteLoginTracker.makeCommonViewParams(flowType: flowType, data: data)
        SuiteLoginTracker.track(Homeric.PASSPORT_VERIFY_LIST_VIEW, params: params)
    }

    func trackerViewClick(event: String, target: String = "none", additional: [String: Any] = [:]) {
        let flowType = self.currentVerifyProvider.getVerifyPageInfo().flowType ?? ""
        let switchButtonEnable = getSwitchButtonInfo() != nil
        var data = additional
        data["verify_type"] = currentVerifyType.rawValue
        data["is_switch_button_enable"] = switchButtonEnable
        let params = SuiteLoginTracker.makeCommonClickParams(flowType: flowType,
                                                             click: event,
                                                             target: "none",
                                                             data: data)
        SuiteLoginTracker.track(Homeric.PASSPORT_VERIFY_LIST_CLICK, params: params)
    }

    func getRetrieveClickName() -> String? {
        switch currentVerifyType {
        case .mobileCode, .emailCode:
            return "find_account"
        case .pwd:
            return "reset_pwd"
        case .otp:
            return "reset_otp"
        default:
            return nil
        }
    }

// - MARK: 监控埋点
    var enterMontiorEventKey: PassportMonitorMetaStep? {
        switch currentVerifyType {
        case .mobileCode, .emailCode:
            return .codeVerifyEnter
        case .pwd:
            return .passwordVerifyEnter
        case .otp:
            return .otpVerifyEnter
        case .spareCode:
            return .backupCodeVerifyEnter
        case .fido:
            return .fidoVerifyEnter
        case .mo:
            return .moVerifyEnter
        case .apple:
            return .appleVerifyEnter
        case .google:
            return .googleVerifyEnter
        case .bIDP:
            return .bidpVerifyEnter
        case .unknow:
            return nil
        }
    }

    var startMontiorEventKey: PassportMonitorMetaStep? {
        switch currentVerifyType {
        case .mobileCode, .emailCode:
            return .startCodeVerify
        case .pwd:
            return .startPasswordVerify
        case .otp:
            return .startOtpVerify
        case .spareCode:
            return .startBackupCodeVerify
        case .fido:
            return .startFidoVerify
        case .mo:
            return .startMoVerify
        case .apple:
            return .startAppleVerify
        case .google:
            return .startGoogleVerify
        case .bIDP:
            return .startBidpVerify
        case .unknow:
            return nil
        }
    }

    var cancelMontiorEventKey: PassportMonitorMetaStep? {
        switch currentVerifyType {
        case .mobileCode, .emailCode:
            return .codeVerifyCancel
        case .pwd:
            return .passwordVerifyCancel
        case .otp:
            return .otpVerifyCancel
        case .spareCode:
            return .backupCodeVerifyCancel
        case .fido:
            return .fidoVerifyCancel
        case .mo:
            return .moVerifyCancel
        case .apple:
            return .appleVerifyCancel
        case .google:
            return .googleVerifyCancel
        case .bIDP:
            return .bidpVerifyCancel
        case .unknow:
            return nil
        }
    }

    var resultMontiorEventKey: PassportMonitorMetaStep? {
        switch currentVerifyType {
        case .mobileCode, .emailCode:
            return .codeVerifyResult
        case .pwd:
            return .passwordVerifyResult
        case .otp:
            return .otpVerifyResult
        case .spareCode:
            return .backupCodeVerifyResult
        case .fido:
            return .fidoVerifyResult
        case .mo:
            return .moVerifyResult
        case .apple:
            return .appleVerifyResult
        case .google:
            return .googleVerifyResult
        case .bIDP:
            return .bidpVerifyResult
        case .unknow:
            return nil
        }
    }

    func monitorVerifyEventCancel() {
        let flowType = self.currentVerifyProvider.getVerifyPageInfo().flowType ?? ""
        if let eventKey = cancelMontiorEventKey {
            PassportMonitor.flush(eventKey,
                                  eventName: ProbeConst.monitorEventName,
                                  categoryValueMap: [ProbeConst.flowType: flowType],
                                  context: context)
        }
    }

    func monitorVerifyEventEnter() {
        // 监控埋点
        let flowType = self.currentVerifyProvider.getVerifyPageInfo().flowType ?? ""
        if let eventKey = enterMontiorEventKey {
            PassportMonitor.flush(eventKey,
                                  eventName: ProbeConst.monitorEventName,
                                  categoryValueMap: [ProbeConst.flowType: flowType],
                                  context: context)
        }
    }

    func monitorVerifyEventStart() {
        let flowType = self.currentVerifyProvider.getVerifyPageInfo().flowType ?? ""
        ProbeDurationHelper.startDuration(flowType)
        if let eventKey = startMontiorEventKey {
            PassportMonitor.flush(eventKey,
                                  eventName: ProbeConst.monitorEventName,
                                  categoryValueMap: [ProbeConst.flowType: flowType],
                                  context: context)
        }
    }

    func monitorVerifyEventResult(isSucceeded: Bool, error: Error? = nil) {
        let errorMsg: String
        if let e = error, !e.localizedDescription.isEmpty {
            errorMsg = e.localizedDescription
        } else {
            errorMsg = "verify result error in \(currentVerifyType)"
        }
        let flowType = self.currentVerifyProvider.getVerifyPageInfo().flowType ?? ""
        let duration = ProbeDurationHelper.stopDuration(flowType)
        let map: [String: Any] = [ProbeConst.flowType: flowType, ProbeConst.duration: duration]

        if let montiorKey = resultMontiorEventKey {
            let monitor = PassportMonitor.monitor(montiorKey,
                                                  eventName: ProbeConst.monitorEventName,
                                                  categoryValueMap: map,
                                                  context: context)
            if isSucceeded {
                monitor.setResultTypeSuccess().flush()
            } else {
                monitor.setResultTypeFail()
                if let error = error {
                    _ = monitor.setPassportErrorParams(error: error)
                }
                monitor.setErrorMessage(errorMsg).flush()
            }
        }
    }
}

enum VerifyStatus {
    case showTips(String)
    case start
    case succ
    case fail(Error)
    case commonError(Error)
}

enum MultiVerifyType: String, Codable {
    case mobileCode = "verify_code_mobile"
    case emailCode = "verify_code_email"
    case pwd = "verify_pwd"
    case otp = "verify_otp"
    case spareCode = "verify_code_spare"
    case mo = "verify_mo"
    case fido = "verify_fido"
    case bIDP = "verify_b_idp"
    case apple = "verify_apple"
    case google = "verify_google"
    case unknow = "unknow"

    // 通过actionType转换为验证方式
    init?(actionType: ActionIconType) {
        switch actionType {
        case .verifyMobile:
            self = .mobileCode
        case .verifyEmail:
            self = .emailCode
        case .verifyOTP:
            self = .otp
        case .verifyPwd:
            self = .pwd
        case .verifySpareCode:
            self = .spareCode
        case .verifyAppleID:
            self = .apple
        case .verifyGoogle:
            self = .google
        case .verifyMo:
            self = .mo
        case .verifyFIDO:
            self = .fido
        case .verifyBIdp:
            self = .bIDP

        default:
            return nil
        }

    }
}
