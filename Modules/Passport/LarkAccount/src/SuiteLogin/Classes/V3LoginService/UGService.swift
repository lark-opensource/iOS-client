//
//  UGService.swift
//  LarkAccount
//
//  Created by bytedance on 2022/2/18.
//

import Foundation
import LKCommonsLogging
import LarkContainer
import LarkAccountInterface
import LarkUIKit
import RxSwift
import LarkReleaseConfig
import LarkLocalizations
import ECOProbeMeta

class UGService: AccountServiceUG {

    @Provider var loginApi: LoginAPI

    @Provider var deviceService: InternalDeviceServiceProtocol

    static let logger = Logger.log(UGService.self, category: "SuiteLogin.UGService")
    static let onlineLogger = Logger.plog(UGService.self, category: "SuiteLogin.UGService")

    private let disposeBag = DisposeBag()

    func getABTestValueForUGRegist(onResult: @escaping (Bool) -> Void) {
        //飞书包且不是 ipad 才开启 ug 的注册
        guard Display.phone && ReleaseConfig.isFeishu else {
            onResult(false)
            return
        }

        loginApi.checkABTestForUG(context: UniContextCreator.create(.ug)).subscribe(onNext: { resp in
            if let responseInfo = resp.dataInfo {
                onResult(responseInfo.enable)
            } else {
                onResult(false)
            }
        }, onError: { _ in
            onResult(false)
        }).disposed(by: disposeBag)
    }

    func getTCCValueForGlobalRegist(onResult: @escaping (Bool) -> Void) {

        // 飞书的ipad和端内登录不走UG/Global流程，也就是显示立即注册按钮
        if ReleaseConfig.isFeishu && (UserManager.shared.foregroundUser != nil || !Display.phone) { // user:current
            onResult(false)
            return
        } else {
            //TCC接口中的开关判断是否走UG/Global流程
            PassportStore.shared.enableRegisterEntryObservable.subscribe { event in
                if let isEnable = event.element {
                    //这里的enableRegister指的是是否开启原生注册流程，用于替代之前UG的abTest，所以语义刚好相反
                    onResult(!isEnable)
                } else {
                    onResult(false)
                }
            }.disposed(by: disposeBag)
        }

    }

    func registPassportEventBus(stepName: String,
                                callback: @escaping (_ stepInfo: [String: Any]) -> Void) {

        Self.logger.info("n_action_ug_regist", body: stepName)
        ExternalEventBus.shared.register(
            step: stepName,
            handler: ExternalEventBusHandler(handleWork: { (args) in
                Self.onlineLogger.info("n_action_ug_regist", body: "handle event \(stepName)", method: .timeline)
                callback(args.stepInfo ?? [:])
                args.successHandler()
        }))
    }

    func dispatchNext(stepInfo: [String: Any], success: @escaping () -> Void, failure: @escaping (_ error: Error) -> Void) {
        do {
            let rawData = try JSONSerialization.data(withJSONObject: stepInfo, options: .init())
            let stepData = try JSONDecoder().decode(V4StepData.self, from: rawData)

            guard let stepName = stepData.stepName else {
                Self.onlineLogger.error("n_action_ug_stepInfo_no_stepName", method: .timeline)
                return
            }
            LoginPassportEventBus.shared.post(
                event: stepName,
                context: V3RawLoginContext(stepInfo: stepData.stepInfo, context: UniContextCreator.create(.ug)),
                success: {
                    Self.onlineLogger.info("n_action_ug_post_step_succ", body: stepName, method: .timeline)
                    success()
                },
                error: { error in
                    Self.onlineLogger.error("n_action_ug_post_step_fail", body: stepName, method: .timeline)
                    failure(error)
                }
            )
        } catch {
            Self.onlineLogger.error("n_action_ug_decode_error", error: error, method: .timeline)
        }
    }

    func joinByCode(code: String, stepInfo: [String: Any], success: @escaping () -> Void, failure: @escaping (_ error: Error) -> Void) {

        var dispatchStepInfo = stepInfo

        guard var nextStepInfo = stepInfo[CommonConst.stepInfo] as? [String: Any] else {
            Self.onlineLogger.error("n_action_ug_join_stepinfo_wrong", method: .timeline)
            failure(V3LoginError.badResponse("data error"))
            return
        }

        nextStepInfo[CommonConst.tenantCode] = code
        dispatchStepInfo[CommonConst.stepInfo] = nextStepInfo
        dispatchNext(stepInfo: dispatchStepInfo, success: success, failure: failure)
    }

    func log(_ msg: String) {
        Self.onlineLogger.info("n_action_ug", body: msg, method: .timeline)
    }

    func getLang() -> [String: String] {
        let current = LanguageManager.currentLanguage.rawValue
        Self.logger.info("n_action_ugService_get_lang", additionalData: ["lang": current])
        return ["lang": current]
    }

    func fallbackProbe(by reason: String, in scene: String) {
        let enableOffline = enableLarkGlobalOffline()
        let categoryValueMap = ["fallback_reason": reason, "fallback_scene": scene, "enable_offline": enableOffline] as [String : Any]
        PassportMonitor.flush(EPMClientPassportMonitorUnspecifiedCode.env_global_register_fallback, categoryValueMap: categoryValueMap, context: UniContext(.ug))
    }

    func enterGlobalRegistEnterProbe() {
        let enableOffline = enableLarkGlobalOffline()
        let categoryValueMap = ["enable_offline": enableOffline]
        PassportMonitor.flush(EPMClientPassportMonitorUnspecifiedCode.env_global_register_enter,categoryValueMap: categoryValueMap , context: UniContext(.ug))
    }

    func globalRegistTimeoutNum() -> Int {
        PassportStore.shared.globalRegistrationTimeout
    }

    func enableLarkGlobalOffline() -> Bool {
        return PassportGray.shared.getGrayValue(key: .enableLarkGlobalOffline)
    }

    func passportOfflineConfig() -> PassportOfflineConfig {
        let passportOfflineConfig = PassportStore.shared.passportOfflineConfig
        return passportOfflineConfig
    }

    func subscribePassportOfflineConfig(handler: @escaping (PassportOfflineConfig) -> Void) {
        PassportStore.shared.passportOfflineConfigObservable.subscribe { passportOfflineConfig in
            handler(passportOfflineConfig)
        }.disposed(by: disposeBag)
    }

    func finishGlobalRegistProbe(enableOffline: Bool, duration: Int) {
        PassportMonitor.flush(PassportMonitorMetaCommon.finishLarkGlobalRegist,
                              eventName: ProbeConst.monitorEventName,
                              categoryValueMap: ["duration": duration, "enable_offline": enableOffline],
                              context: UniContext(.ug))
    }
}
