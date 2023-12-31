//
//  V4LoginVerifyViewModel.swift
//  LarkAccount
//
//  Created by au on 2021/6/3.
//

import Foundation
import RxSwift
import RxCocoa
import Homeric
import LarkPerf
import LarkAccountInterface
import LarkContainer
import ECOProbeMeta

class V4LoginVerifyViewModel: V3ViewModel, VerifyViewModelProtocol, VerifyProtocol, WebauthNServiceProtocol {

    @Provider var loginService: V3LoginService
    let api: VerifyAPIProtocol

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
        verifyInfo.enableChange.verifyTypeCount() > 1
    }
    
    var retrieveLinkTitle: String {
        return verifyState.retrieveLinkTitle
    }

    var state: VerifyStateProtocol {
        return verifyState
    }

    let verifyState: LoginVerifyState

    let verifyTokenCompletionWrapper: VerifyTokenCompletionWrapper?

    var webAuthNService: PassportWebAuthService?

    var enableClientLoginMethodMemory: Bool

    var recordVerifyType: VerifyType? {
        get {
            return verifyState.recordVerifyType
        }
        set {
            verifyState.recordVerifyType = newValue
        }
    }
    
    var needSkipWhilePopStub: Bool = false
    //返回的时候是否回到 feed 页面;
    //https://meego.bytedance.net/larksuite/issue/detail/2768937?#detail
    let backToFeed: Bool

    init(
        step: String,
        api: VerifyAPIProtocol,
        backToFeed: Bool,
        verifyInfo: VerifyInfoProtocol & ServerInfo,
        verifyTokenCompletionWrapper: VerifyTokenCompletionWrapper?,
        context: UniContextProtocol
    ) {
        self.api = api
        self.backToFeed = backToFeed
        self.verifyTokenCompletionWrapper = verifyTokenCompletionWrapper
        self.enableClientLoginMethodMemory = verifyInfo.enableClientLoginMethodMemory ?? false
//        let enableResetPwd = verifyInfo.enableChange.contains(.forgetVerifyCode) && verifyInfo.forgetVerifyCode != nil
        let verifyPwdState = VerifyPwdState(enableResetPwd: true)
        let verifyCodeState = VerifyCodeState(verifyCodeTip: verifyInfo.verifyCode?.subTitle)
        let verifyForgetCodeState = VerifyCodeState(verifyCodeTip: verifyInfo.forgetVerifyCode?.subTitle)
        let verifyOtpState = VerifyCodeState(verifyCodeTip: verifyInfo.verifyOtp?.subTitle, hasApplyCode: true)
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
        monitorVerifyEventEnter(type: verifyType)
    }

    func trackSwitchLoginWay() {
        // 当要切换到下一个验证方式时，先把前一个验证方式 cancel，再 start 下一个
        monitorVerifyEventCancel(type: verifyType)
        monitorVerifyEventEnter(type: nextVerityType())

        // fido切换到其他验证方式时埋点
        if verifyType == .fido {
            let params = SuiteLoginTracker.makeCommonViewParams(flowType: verifyInfo.flowType ?? "", data: ["target": "none",
                                                                                                            "click": "switch"])
            SuiteLoginTracker.track(Homeric.PASSPORT_FIDO_VERIFY_CLICK, params: params)
        }

        switch nextVerityType() {
        case .pwd:
            PassportMonitor.flush(EPMClientPassportMonitorCode.passport_monitor_step_view_run,
                                  categoryValueMap: [ProbeConst.stepName: self.step,
                                                     ProbeConst.stageName: "onCreateView",
                                                     ProbeConst.tagName: "input_pwd"],
                                  context: context)
            let params = SuiteLoginTracker.makeCommonClickParams(flowType: verifyInfo.verifyCode?.flowType ?? "",
                                                                 click: "change_to_pwd",
                                                                 target: TrackConst.passportPwdVerifyView,
                                                                 data:["enable_client_login_method_memory": enableClientLoginMethodMemory,
                                                                       "last_login_type": self.verifyState.recordVerifyType?.rawValue ?? ""])
            SuiteLoginTracker.track(Homeric.PASSPORT_VERIFY_CODE_CLICK, params: params)
        case .code:
            PassportMonitor.flush(EPMClientPassportMonitorCode.passport_monitor_step_view_run,
                                  categoryValueMap: [ProbeConst.stepName: self.step,
                                                     ProbeConst.stageName: "onCreateView",
                                                     ProbeConst.tagName: "verify_code"],
                                  context: context)
            let params = SuiteLoginTracker.makeCommonClickParams(flowType: verifyInfo.verifyPwd?.flowType ?? "",
                                                                 click: "change_to_verify_code",
                                                                 target: TrackConst.passportVerifyCodeView,
                                                                 data:["enable_client_login_method_memory": enableClientLoginMethodMemory,
                                                                       "last_login_type": self.verifyState.recordVerifyType?.rawValue ?? ""])
            SuiteLoginTracker.track(Homeric.PASSPORT_PWD_VERIFY_CLICK, params: params)
        default:
            return
        }

    }

    func switchLoginWay() {
        verifyType = nextVerityType()
    }

    func hasVerifyType(verifyType: VerifyType) -> Bool {
        switch verifyType {
        case .code:
            if verifyInfo.verifyCode == nil {
                return false
            }
        case .forgetVerifyCode:
            if verifyInfo.forgetVerifyCode == nil {
                return false
            }
        case .pwd:
            if verifyInfo.verifyPwd == nil {
                return false
            }
        case .otp:
            if verifyInfo.verifyOtp == nil {
                return false
            }
        case .spareCode:
            if verifyInfo.verifyCodeSpare == nil {
                return false
            }
        case .mo:
            if verifyInfo.verifyMo == nil {
                return false
            }
        case .fido:
            if verifyInfo.verifyFido == nil {
                return false
            }
        }
        return true

    }

    func updateRecordVerifyType() {
        if let cp = context.credential.cp,
           let recordVerifyTypeRawValue = PassportStore.shared.getRecordVerifyMethod(credentialKey: cp),
           let recordVerifyType = VerifyType(rawValue: recordVerifyTypeRawValue) {
            if hasVerifyType(verifyType: recordVerifyType) && enableClientLoginMethodMemory {
                verifyState.verifyType = recordVerifyType
                verifyState.recordVerifyType = recordVerifyType
            }
        }
    }


    /// VerifyType 切换策略
    private func nextVerityType() -> VerifyType {
        if let currentPageInfo = self.verifyState.pageInfo {
            if currentPageInfo.codeButton != nil {
                return .code
            } else if currentPageInfo.otpButton != nil {
                return .otp
            } else if currentPageInfo.spareCodeButton != nil {
                return .spareCode
            } else if currentPageInfo.fidoButton != nil {
                return .fido
            } else if currentPageInfo.passwordButton != nil {
                return .pwd
            } else if currentPageInfo.moButton != nil {
                return .mo
            }
        }
        return verifyType
    }
        
    func cancelVerify() {
        // 校验安全密码时重置密码流程中取消验证
        if context.from == .checkSecurityPassword {
            Self.logger.info("Cancel verify for checking security password")
            loginService.securityResult?(
                SecurityResultCode.userCancelOrFailed,
                SecurityError.userCancel.rawValue,
                nil
            )
            loginService.securityResult = nil
        }
    }

    // MARK: VerifyAPIProtocol

    func applyCode() -> Observable<Void> {

        Self.logger.info("n_action_verify_code_apply", method: .local)
        
        // 由于服务端设计原因，use_package_domain 在外层 step info
        // 而 flow_type 在内层的结构中，这里分开传参
        let flowType: String?
        let startCode: OPMonitorCodeProtocol
        let resultCode: OPMonitorCodeProtocol
        let durationKey: String
        if self.verifyType == .spareCode {
            flowType = verifyInfo.verifyCodeSpare?.flowType
            startCode = PassportMonitorMetaStep.startBackupCodeApply
            resultCode = PassportMonitorMetaStep.backupCodeApplyResult
            durationKey = "verifyBackupCodeFlow"
        } else {
            flowType = verifyInfo.verifyCode?.flowType
            startCode = PassportMonitorMetaStep.startCodeApply
            resultCode = PassportMonitorMetaStep.codeApplyResult
            durationKey = "verifyCodeFlow"
        }

        PassportMonitor.flush(startCode,
                              eventName: ProbeConst.monitorEventName,
                              categoryValueMap: [ProbeConst.flowType: flowType],
                              context: context)
        ProbeDurationHelper.startDuration(durationKey)
        
        return api
            .applyCode(
                serverInfo: verifyInfo,
                flowType: flowType,
                contactType: nil,
                context: context
            )
            .post(context: context)
            .catchError { error -> Observable<()> in
                if let err = error as? V3LoginError, case .badServerCode(let info) = err {
                    
                    if info.type == .applyCodeTooOften, let exp = info.detail[V3.Const.expire] as? uint {
                        
                        self.verifyState.verifyCodeState.expire.accept(exp)
                        return .just(())
                    } else if info.type == .needTuringVerify {
                        // 命中风控，倒计时清零
                        self.verifyState.verifyCodeState.expire.accept(0)
                    }
                }
                
                return .error(error)
            }
            .do(onNext: { [weak self] _ in
                guard let self = self else { return }
                PassportMonitor.flush(EPMClientPassportMonitorLoginCode.login_auth_code_apply_request_succ, context: self.context)
                let duration = ProbeDurationHelper.stopDuration(durationKey)
                PassportMonitor.monitor(resultCode,
                                        eventName: ProbeConst.monitorEventName,
                                        categoryValueMap: [ProbeConst.duration: duration],
                                        context: self.context)
                .setResultTypeSuccess()
                .flush()
            }, onError: { [weak self] error in
                guard let self = self else { return }
                let duration = ProbeDurationHelper.stopDuration(durationKey)
                PassportMonitor.monitor(resultCode,
                                        eventName: ProbeConst.monitorEventName,
                                        categoryValueMap: [ProbeConst.duration: duration],
                                        context: self.context)
                .setResultTypeFail()
                .setPassportErrorParams(error: error)
                .flush()
            })
    }

    func verify() -> Observable<Void> {
        if self.verifyType == .pwd {
            monitorVerifyEventStart(type: .pwd)
            Self.logger.info("n_action_verify_pwd_next")
            let sceneInfo = [
                MultiSceneMonitor.Const.scene.rawValue: MultiSceneMonitor.Scene.enterVerifyPWD.rawValue,
                MultiSceneMonitor.Const.type.rawValue: self.verifyType == .forgetVerifyCode ? "forget_pwd" : "register_or_login",
                MultiSceneMonitor.Const.result.rawValue: "success"
            ]
            SuiteLoginTracker.track(Homeric.LOGIN_CLICK_VERIFY_PWD)
            return api
                .verify(
                    serverInfo: verifyInfo,
                    flowType: verifyInfo.verifyPwd?.flowType,
                    password: verifyState.verifyPwdState.password,
                    rsaInfo: verifyInfo.verifyPwd?.rsaInfo,
                    contactType: nil,
                    sceneInfo: sceneInfo,
                    context: context
                )
                .post(additionalInfo, context: context).do {[weak self] (_) in
                    self?.needSkipWhilePopStub = true
                }
                .do(onNext: { [weak self] _ in
                    guard let self = self else { return }
                    let params = SuiteLoginTracker.makeCommonClickParams(flowType: self.verifyState.pageInfo?.flowType ?? "", click: "next", target: "", data: ["verify_result": "success",
                         "enable_client_login_method_memory": self.enableClientLoginMethodMemory,
                        "last_login_type": self.verifyState.recordVerifyType?.rawValue])
                    SuiteLoginTracker.track(Homeric.PASSPORT_PWD_VERIFY_CLICK, params: params)
                    //记录当前登录方式
                    if let cp = self.context.credential.cp, self.enableClientLoginMethodMemory == true {
                        PassportStore.shared.recordVerifyMethod(credentialKey: cp, verifyType: self.verifyType.rawValue)
                    }
                    self.monitorVerifyEventResult(type: .pwd, isSucceeded: true)

                }, onError: { [weak self] error in
                    guard let self = self else { return }
                    let params = SuiteLoginTracker.makeCommonClickParams(flowType: self.verifyState.pageInfo?.flowType ?? "", click: "next", target: "", data: ["verify_result": "failed",
                         "enable_client_login_method_memory": self.enableClientLoginMethodMemory,
                         "last_login_type": self.verifyState.recordVerifyType?.rawValue])
                    SuiteLoginTracker.track(Homeric.PASSPORT_PWD_VERIFY_CLICK, params: params)

                    if let loginError = error as? V3LoginError {
                        loginError.loggerInfo
                    }
                    self.monitorVerifyEventResult(type: .pwd, isSucceeded: false, error: error)
                })
        } else if verifyType == .otp {
            monitorVerifyEventStart(type: .otp)
            let usePackageDomain = verifyInfo.usePackageDomain ?? false
            let sceneInfo = [
                MultiSceneMonitor.Const.scene.rawValue: MultiSceneMonitor.Scene.enterVerifyOTP.rawValue,
                MultiSceneMonitor.Const.type.rawValue: self.verifyType == .forgetVerifyCode ? "forget_pwd" : "register_or_login",
                MultiSceneMonitor.Const.result.rawValue: "success"
            ]
            return api.v4VerifyOtp(
                serverInfo: verifyInfo,
                flowType: verifyInfo.verifyOtp?.flowType,
                code: verifyState.verifyOtpState.code,
                context: context
            )
            .post(additionalInfo, context: context)
            .do(onNext: {[weak self] (_) in
                guard let self = self else { return }
                self.needSkipWhilePopStub = true
                SuiteLoginTracker.track(Homeric.PASSPORT_VERIFY_CODE_PAGE_CLICK, params: [
                    "click": "next",
                    "target": "none",
                    "verify_type": "otp_code",
                    "is_success": "true"
                ])
                //记录当前登录方式
                if let cp = self.context.credential.cp, self.enableClientLoginMethodMemory == true {
                    PassportStore.shared.recordVerifyMethod(credentialKey: cp, verifyType: self.verifyType.rawValue)
                }
                self.monitorVerifyEventResult(type: .otp, isSucceeded: true)
            }, onError: { error in
                SuiteLoginTracker.track(Homeric.PASSPORT_VERIFY_CODE_PAGE_CLICK, params: [
                    "click": "next",
                    "target": "none",
                    "verify_type": "otp_code",
                    "is_success": "false"
                ])
                self.monitorVerifyEventResult(type: .otp, isSucceeded: false, error: error)
            })
        } else if verifyType == .mo {
            monitorVerifyEventStart(type: .mo)
            Self.logger.info("n_action_verify_mo_verify")
            let flowType: String?
            flowType = verifyInfo.verifyMo?.flowType
            return api.verifyMo(
                serverInfo: verifyInfo,
                flowType: flowType ?? "",
                context: context)
            .post(additionalInfo, context: context)
            .do(onNext: {[weak self] (_) in
                guard let self = self else { return }
                self.needSkipWhilePopStub = true
                Self.logger.info("n_action_verify_mo_verify_succ")
                SuiteLoginTracker.track(Homeric.PASSPORT_INDENTITY_VERIFY_PHONE_MSG_SEND_CLICK, params: [
                    "flow_type": self.verifyInfo.verifyMo?.flowType,
                    "target": "none",
                    "click": "msg_sent",
                    "verify_result": "success"
                ])
                //记录当前登录方式
                if let cp = self.context.credential.cp, self.enableClientLoginMethodMemory == true {
                    PassportStore.shared.recordVerifyMethod(credentialKey: cp, verifyType: self.verifyType.rawValue)
                }
                self.monitorVerifyEventResult(type: .mo, isSucceeded: true)
            }, onError: { error in
                Self.logger.info("n_action_verify_mo_verify_fail")
                SuiteLoginTracker.track(Homeric.PASSPORT_INDENTITY_VERIFY_PHONE_MSG_SEND_CLICK, params: [
                    "flow_type": self.verifyInfo.verifyMo?.flowType,
                    "target": "none",
                    "click": "msg_sent",
                    "verify_result": "failed"
                ])
                self.monitorVerifyEventResult(type: .mo, isSucceeded: false, error: error)
            })
        } else {
            // 验证码
            monitorVerifyEventStart(type: self.verifyType)
            Self.logger.info("n_action_verify_code_verify", method: .local)
            let params = SuiteLoginTracker.makeCommonClickParams(flowType: verifyInfo.flowType ?? "",
                                                                 click: "next",
                                                                 target: "none",
                                                                 data:[
                                                                        "enable_client_login_method_memory": enableClientLoginMethodMemory,
                                                                        "last_login_type": self.verifyState.recordVerifyType?.rawValue])
            SuiteLoginTracker.track(Homeric.PASSPORT_VERIFY_CODE_CLICK, params: params)
            
            let flowType: String?
            let code: String
            if self.verifyType == .spareCode {
                flowType = verifyInfo.verifyCodeSpare?.flowType
                code = verifyState.verifySpareCodeState.code
            } else {
                flowType = verifyInfo.verifyCode?.flowType
                code = verifyState.verifyCodeState.code
            }
            
            let sceneInfo = [
                MultiSceneMonitor.Const.scene.rawValue: MultiSceneMonitor.Scene.enterVerifyCode.rawValue,
                MultiSceneMonitor.Const.type.rawValue: self.verifyType == .forgetVerifyCode ? "forget_pwd" : "register_or_login",
                MultiSceneMonitor.Const.result.rawValue: "success"
            ]
            SuiteLoginTracker.track(Homeric.REGISTER_CLICK_VERIFY_CODE, params: [
                "source_type": verifyState.pageInfo?.sourceType ?? 0
            ])
            if verifyTokenCompletionWrapper != nil {
                additionalInfo = verifyTokenCompletionWrapper
            }
            return api
                .verify(
                    serverInfo: verifyInfo,
                    flowType: flowType,
                    code: code,
                    contactType: nil,
                    sceneInfo: sceneInfo,
                    context: context
                )
                .post(additionalInfo, context: self.context)
                .do(onNext: { [weak self] (_) in
                    guard let self = self else { return }
                    self.needSkipWhilePopStub = true
                    SuiteLoginTracker.track(Homeric.PASSPORT_VERIFY_CODE_PAGE_CLICK, params: [
                        "click": "next",
                        "target": "none",
                        "verify_type": "message",
                        "is_success": "true"
                    ])
                    SuiteLoginTracker.track(Homeric.VERIFY_CODE_VERIFY_SUCCESS)
                    //记录当前登录方式
                    if let cp = self.context.credential.cp, self.enableClientLoginMethodMemory == true {
                        PassportStore.shared.recordVerifyMethod(credentialKey: cp, verifyType: self.verifyType.rawValue)
                    }
                    self.monitorVerifyEventResult(type: self.verifyType, isSucceeded: true)
                }, onError: { error in
                    SuiteLoginTracker.track(Homeric.PASSPORT_VERIFY_CODE_PAGE_CLICK, params: [
                        "click": "next",
                        "target": "none",
                        "verify_type": "message",
                        "is_success": "false"
                    ])
                    SuiteLoginTracker.track(Homeric.VERIFY_CODE_VERIFY_FAIL)
                    self.monitorVerifyEventResult(type: self.verifyType, isSucceeded: false, error: error)
                })
        }
    }
    
    func retrieveAction() -> Observable<Void> {
        
        guard let retrieveBtnInfo = self.verifyState.pageInfo?.retrieveButton,
              let stepInfo = retrieveBtnInfo.next?.stepInfo,
              let actionValue = stepInfo[CommonConst.action],
              let actionType = actionValue as? Int
              else {
            Self.logger.error("no retrieveBtn info skip action")
            return Observable.create {(observer) -> Disposable in
                return Disposables.create()
            }
        }
        if self.verifyState.verifyType == .pwd {
            let params = SuiteLoginTracker.makeCommonClickParams(flowType: self.verifyState.pageInfo?.flowType ?? "",
                                                                 click: TrackConst.passportClickTrackResetPwd,
                                                                 target: "none",
                                                                 data:["enable_client_login_method_memory": self.enableClientLoginMethodMemory,
                                                                       "last_login_type": self.verifyState.recordVerifyType?.rawValue])
            SuiteLoginTracker.track(Homeric.PASSPORT_PWD_VERIFY_CLICK, params: params)
        } else {
            let params = SuiteLoginTracker.makeCommonClickParams(flowType: self.verifyState.pageInfo?.flowType ?? "",
                                                                 click: "find_account",
                                                                 target: "none",
                                                                 data: ["enable_client_login_method_memory": enableClientLoginMethodMemory,
                                                                        "last_login_type": self.verifyState.recordVerifyType?.rawValue])
            SuiteLoginTracker.track(Homeric.PASSPORT_VERIFY_CODE_CLICK, params: params)
        }



        switch self.verifyType {
        case .pwd: Self.logger.info("n_action_reset_pwd_click")
        case .code: Self.logger.info("n_action_account_retrieve_click")
        case .otp: Self.logger.info("n_action_reset_otp_click")
        default: break
        }

        Self.logger.info("n_action_account_retrieve_req", additionalData: ["action": actionType])
        return api.retrieveGuideWay(
            serverInfo: self.verifyInfo,
            flowType: self.verifyState.pageInfo?.flowType,
            action: actionType,
            context: context
        ).do(onNext: { step in
            Self.logger.info("n_action_account_retrieve_req_succ", additionalData: ["action": actionType])
        }, onError: { error in
            Self.logger.error("n_action_account_retrieve_req_fail", additionalData: ["action": actionType], error: error)
        }).post([CommonConst.closeAllStartPointKey: true], context: context)
    }

    func monitorBackOrClose() {
        monitorVerifyEventCancel(type: verifyType)
    }
    
}

extension V4LoginVerifyViewModel {

    var needSkipWhilePop: Bool {
        return needSkipWhilePopStub
    }

    var pageName: String? {
        switch verifyType {
        case .pwd:
            return Homeric.LOGIN_ENTER_VERIFY_PWD
        case .code, .forgetVerifyCode, .otp,.spareCode:
            return Homeric.PASSPORT_ENTER_VERIFY_CODE
        case .mo, .fido:
            return nil
        }
    }
}

extension V4LoginVerifyViewModel {
    private func monitorVerifyEventEnter(type: VerifyType) {
        let flowType = getFlowTypeFromVerifyType(type)
        switch type {
        case .code:
            PassportMonitor.flush(PassportMonitorMetaStep.codeVerifyEnter,
                                  eventName: ProbeConst.monitorEventName,
                                  categoryValueMap: [ProbeConst.flowType: flowType],
                                  context: context)
        case .pwd:
            PassportMonitor.flush(PassportMonitorMetaStep.passwordVerifyEnter,
                                  eventName: ProbeConst.monitorEventName,
                                  categoryValueMap: [ProbeConst.flowType: flowType],
                                  context: context)
        case .forgetVerifyCode:
            return
        case .otp:
            PassportMonitor.flush(PassportMonitorMetaStep.otpVerifyEnter,
                                  eventName: ProbeConst.monitorEventName,
                                  categoryValueMap: [ProbeConst.flowType: flowType],
                                  context: context)
        case .spareCode:
            PassportMonitor.flush(PassportMonitorMetaStep.backupCodeVerifyEnter,
                                  eventName: ProbeConst.monitorEventName,
                                  categoryValueMap: [ProbeConst.flowType: flowType],
                                  context: context)
        case .mo:
            PassportMonitor.flush(PassportMonitorMetaStep.moVerifyEnter,
                                  eventName: ProbeConst.monitorEventName,
                                  categoryValueMap: [ProbeConst.flowType: flowType],
                                  context: context)
        case .fido:
            PassportMonitor.flush(PassportMonitorMetaStep.fidoVerifyEnter,
                                  eventName: ProbeConst.monitorEventName,
                                  categoryValueMap: [ProbeConst.flowType: flowType],
                                  context: context)
        }
    }

    private func monitorVerifyEventStart(type: VerifyType) {
        let flowType = getFlowTypeFromVerifyType(type)
        ProbeDurationHelper.startDuration(flowType)
        switch type {
        case .code:
            PassportMonitor.flush(PassportMonitorMetaStep.startCodeVerify,
                                  eventName: ProbeConst.monitorEventName,
                                  categoryValueMap: [ProbeConst.flowType: flowType],
                                  context: context)
        case .pwd:
            PassportMonitor.flush(PassportMonitorMetaStep.startPasswordVerify,
                                  eventName: ProbeConst.monitorEventName,
                                  categoryValueMap: [ProbeConst.flowType: flowType],
                                  context: context)
        case .forgetVerifyCode:
            return
        case .otp:
            PassportMonitor.flush(PassportMonitorMetaStep.startOtpVerify,
                                  eventName: ProbeConst.monitorEventName,
                                  categoryValueMap: [ProbeConst.flowType: flowType],
                                  context: context)
        case .spareCode:
            PassportMonitor.flush(PassportMonitorMetaStep.startBackupCodeVerify,
                                  eventName: ProbeConst.monitorEventName,
                                  categoryValueMap: [ProbeConst.flowType: flowType],
                                  context: context)
        case .mo:
            PassportMonitor.flush(PassportMonitorMetaStep.startMoVerify,
                                  eventName: ProbeConst.monitorEventName,
                                  categoryValueMap: [ProbeConst.flowType: flowType],
                                  context: context)
        case .fido:
            PassportMonitor.flush(PassportMonitorMetaStep.startFidoVerify,
                                  eventName: ProbeConst.monitorEventName,
                                  categoryValueMap: [ProbeConst.flowType: flowType],
                                  context: context)
        }
    }

    private func monitorVerifyEventCancel(type: VerifyType) {
        let flowType = getFlowTypeFromVerifyType(type)
        switch type {
        case .code:
            PassportMonitor.flush(PassportMonitorMetaStep.codeVerifyCancel,
                                  eventName: ProbeConst.monitorEventName,
                                  categoryValueMap: [ProbeConst.flowType: flowType],
                                  context: context)
        case .pwd:
            PassportMonitor.flush(PassportMonitorMetaStep.passwordVerifyCancel,
                                  eventName: ProbeConst.monitorEventName,
                                  categoryValueMap: [ProbeConst.flowType: flowType],
                                  context: context)
        case .forgetVerifyCode:
            return
        case .otp:
            PassportMonitor.flush(PassportMonitorMetaStep.otpVerifyCancel,
                                  eventName: ProbeConst.monitorEventName,
                                  categoryValueMap: [ProbeConst.flowType: flowType],
                                  context: context)
        case .spareCode:
            PassportMonitor.flush(PassportMonitorMetaStep.backupCodeVerifyCancel,
                                  eventName: ProbeConst.monitorEventName,
                                  categoryValueMap: [ProbeConst.flowType: flowType],
                                  context: context)
        case .mo:
            PassportMonitor.flush(PassportMonitorMetaStep.moVerifyCancel,
                                  eventName: ProbeConst.monitorEventName,
                                  categoryValueMap: [ProbeConst.flowType: flowType],
                                  context: context)
        case .fido:
            PassportMonitor.flush(PassportMonitorMetaStep.fidoVerifyCancel,
                                  eventName: ProbeConst.monitorEventName,
                                  categoryValueMap: [ProbeConst.flowType: flowType],
                                  context: context)
        }
    }

    private func monitorVerifyEventResult(type: VerifyType, isSucceeded: Bool, error: Error? = nil) {
        let errorMsg: String
        if let e = error, !e.localizedDescription.isEmpty {
            errorMsg = e.localizedDescription
        } else {
            errorMsg = "verify result error in \(type)"
        }

        let errorCode: String
        let bizCode: String
        if let loginError = error as? V3LoginError,
           case .badServerCode(let info) = loginError {
            errorCode = "\(info.type.rawValue)"
            bizCode = String(info.bizCode ?? -9999)
        } else {
            errorCode = ProbeConst.commonInternalErrorCode
            bizCode = "-9999"
        }
        let flowType = getFlowTypeFromVerifyType(type)
        let duration = ProbeDurationHelper.stopDuration(flowType)
        let map: [String: Any] = [ProbeConst.flowType: flowType, ProbeConst.duration: duration, ProbeConst.bizCode: bizCode]

        switch type {
        case .code:
            let monitor = PassportMonitor.monitor(PassportMonitorMetaStep.codeVerifyResult,
                                                  eventName: ProbeConst.monitorEventName,
                                                  categoryValueMap: map,
                                                  context: context)
            if isSucceeded {
                monitor.setResultTypeSuccess().flush()
            } else {
                monitor.setResultTypeFail().setErrorMessage(errorMsg).setErrorCode(errorCode).flush()
            }
        case .pwd:
            let monitor = PassportMonitor.monitor(PassportMonitorMetaStep.passwordVerifyResult,
                                                  eventName: ProbeConst.monitorEventName,
                                                  categoryValueMap: map,
                                                  context: context)
            if isSucceeded {
                monitor.setResultTypeSuccess().flush()
            } else {
                monitor.setResultTypeFail().setErrorMessage(errorMsg).setErrorCode(errorCode).flush()
            }
        case .forgetVerifyCode:
            return
        case .otp:
            let monitor = PassportMonitor.monitor(PassportMonitorMetaStep.otpVerifyResult,
                                                  eventName: ProbeConst.monitorEventName,
                                                  categoryValueMap: map,
                                                  context: context)
            if isSucceeded {
                monitor.setResultTypeSuccess().flush()
            } else {
                monitor.setResultTypeFail().setErrorMessage(errorMsg).setErrorCode(errorCode).flush()
            }
        case .spareCode:
            let monitor = PassportMonitor.monitor(PassportMonitorMetaStep.backupCodeVerifyResult,
                                                  eventName: ProbeConst.monitorEventName,
                                                  categoryValueMap: map,
                                                  context: context)
            if isSucceeded {
                monitor.setResultTypeSuccess().flush()
            } else {
                monitor.setResultTypeFail().setErrorMessage(errorMsg).setErrorCode(errorCode).flush()
            }
        case .mo:
            let monitor = PassportMonitor.monitor(PassportMonitorMetaStep.moVerifyResult,
                                                  eventName: ProbeConst.monitorEventName,
                                                  categoryValueMap: map,
                                                  context: context)
            if isSucceeded {
                monitor.setResultTypeSuccess().flush()
            } else {
                monitor.setResultTypeFail().setErrorMessage(errorMsg).setErrorCode(errorCode).flush()
            }
        case .fido:
            let monitor = PassportMonitor.monitor(PassportMonitorMetaStep.fidoVerifyResult,
                                                  eventName: ProbeConst.monitorEventName,
                                                  categoryValueMap: map,
                                                  context: context)
            if isSucceeded {
                monitor.setResultTypeSuccess().flush()
            } else {
                monitor.setResultTypeFail().setErrorMessage(errorMsg).setErrorCode(errorCode).flush()
            }
        }
    }

    private func getFlowTypeFromVerifyType(_ verifyType: VerifyType) -> String {
        let flowType: String
        switch verifyType {
        case .code:
            flowType = verifyInfo.verifyCode?.flowType ?? ""
        case .pwd:
            flowType = verifyInfo.verifyPwd?.flowType ?? ""
        case .forgetVerifyCode:
            flowType = verifyInfo.forgetVerifyCode?.flowType ?? ""
        case .otp:
            flowType = verifyInfo.verifyOtp?.flowType ?? ""
        case .spareCode:
            flowType = verifyInfo.verifyCodeSpare?.flowType ?? ""
        case .mo:
            flowType = verifyInfo.verifyMo?.flowType ?? ""
        case .fido:
            flowType = verifyInfo.verifyFido?.flowType ?? ""
        }
        return flowType
    }
}

extension V4LoginVerifyViewModel {
    static public func attributedString(_ subtitle: String, _ contact: String, paraStyle: NSParagraphStyle? = nil) -> NSAttributedString {
        let boldAttributed: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14.0, weight: .bold),
            .foregroundColor: UIColor.ud.N900
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
            .foregroundColor: UIColor.ud.N600
        ]

        if let paraStyle = paraStyle {
            attributed[.paragraphStyle] = paraStyle
        }
        return NSAttributedString(string: string, attributes: attributed)
    }
}

