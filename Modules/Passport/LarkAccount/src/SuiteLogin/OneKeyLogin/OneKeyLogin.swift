//
//  OneKeyLogin.swift
//  SuiteLogin
//
//  Created by Miaoqi Wang on 2020/6/11.
//

import Foundation
import BDUGAccountOnekeyLogin
import LarkReleaseConfig
import LKCommonsLogging
import RxSwift
import LarkAccountInterface
import RoundedHUD
import EENavigator
import UniverseDesignToast
import TTReachability
import ECOProbeMeta
import Reachability

extension Notification.Name {
    static let oneKeyLoginFirstPrefetched = NSNotification.Name("OneKeyLogin.oneKeyLoginFirstPrefetched")
}

/// OneKeyLogin https://doc.bytedance.net/docs/177/266/4433/
struct OneKeyLogin {
    static let logger = Logger.plog(OneKeyLogin.self, category: "SuiteLogin.OneKeyLogin")

    public static let isOneKeyLoginBeforeGuideKey = "Passport.OneKeyLogin.isOneKeyLoginBeforeGuide"
    private(set) static var isOneKeyLoginBeforeGuide: Bool = true

    private static var oneKeyService: BDUGAccountOnekeyLogin { getBDOneKeyLogin() }

    private static var isSetup: Bool = false
    private(set) static var oneKeyLoginFirstPrefetched = false
    // avoid prefetching when logged in
    private static var isLoggedIn = false
    // avoid multiple fetching work run simultaneously (联通多个取号同时进行会崩溃)
    private static var isGettingNumber = false

    private static var needPrefetch: V3OneKeyLoginConfig.NeedPrefetch = .default

    // prefetch number
    private static var prefetchedNumber: (number: String, service: OneKeyLoginService)?
    private static var networkListenDisposable: Disposable?

    private static func registerService(_ service: BDUGAccountOnekeyLogin, config: OneKeyLoginConfig) {
        // isTestChannel is always false, will be removed
        logger.info("n_action_one_key_login: OneKeyLogin register service: \(config.service) appId: \(config.appId.md5()) appKey: \(config.appKey.md5())")
        service.registerOneKeyLoginService(
            config.service.rawValue,
            appId: config.appId,
            appKey: config.appKey
        )
    }

    static var currentService: OneKeyLoginService? {
        logger.info("n_action_one_key_login currentService: \(oneKeyService.service)")
        return OneKeyLoginService(rawValue: oneKeyService.service)
    }

    static func updateIsOneKeyLoginBeforeGuide(_ value: Bool) {
        Self.isOneKeyLoginBeforeGuide = value
        UserDefaults.standard.set(Self.isOneKeyLoginBeforeGuide, forKey: Self.isOneKeyLoginBeforeGuideKey)
    }

    private static func getBDOneKeyLogin() -> BDUGAccountOnekeyLogin {
        /// about settings https://bytedance.feishu.cn/docs/doccnulVzeeOyymio2UugQQm7Oc

        let setup = isSetup
        if !setup {
            logger.info("setup", method: .local)
            OneKeyLoginTrackService.bind()
        }
        let service = BDUGAccountOnekeyLogin.sharedInstance()
        if !setup {
            if let configs = PassportConf.shared.oneKeyLoginConfig {
                if configs.count != OneKeyLoginService.allCases.count {
                    logger.errorWithAssertion("n_action_one_key_login: information of three carriers is incomplete (telecom, unicom, mobile)")
                }
                configs.forEach { (cfg) in
                    registerService(service, config: cfg)
                }
            } else {
                OneKeyLoginService.allCases.forEach { (ser) in
                    registerService(service, config: ser.config())
                }
            }
            isSetup = true
        }
        return service
    }

    private static func startNetworkListen() {
        if networkListenDisposable == nil {
            logger.info("n_action_one_key_login: start listen network change")
            networkListenDisposable = NotificationCenter.default.rx.notification(.reachabilityChanged)
                .observeOn(MainScheduler.instance)
                .skip(1)    // skip init
                .subscribe(onNext: { notification in
                    guard let reach = notification.object as? Reachability else {
                        logger.error("n_action_one_key_login: reach notification error")
                        return
                    }
                    if reach.connection != .none {
                        logger.info("n_action_one_key_login: network change has data flow; from reachability")
                        prefetch()
                    } else {
                        logger.info("n_action_one_key_login: network change no data flow")
                        prefetchedNumber = nil
                    }
                })
        }
    }

    private static func removeNetworkListen() {
        logger.info("stop listen network change", method: .local)
        networkListenDisposable?.dispose()
        networkListenDisposable = nil
    }

    private static func prefetch(complete: @escaping (Error?) -> Void = { _ in }) {
        let internelComplete = { (error: Error?) in
            if error == nil, oneKeyLoginFirstPrefetched == false {
                SuiteLoginUtil.runOnMain {
                    logger.info("n_action_one_key_login: internelComplete finished")
                    oneKeyLoginFirstPrefetched = true
                    NotificationCenter.default.post(name: .oneKeyLoginFirstPrefetched, object: self.prefetchedNumber)
                }
            }
            logger.error("n_action_one_key_login: internelComplete error \(String(describing: error?.localizedDescription))", method: .local)
            complete(error)
        }
        
        guard ReleaseConfig.isFeishu, !isLoggedIn else {
            logger.info("n_action_one_key_login: skip prefetch: \(ReleaseConfig.isFeishu), \(isLoggedIn)", method: .local)
            internelComplete(nil)
            return
        }
        
        guard let service = currentService else {
            logger.error("n_action_one_key_login: skip prefetch: service is nil")
            internelComplete(nil)
            return
        }

        if needPrefetch.value(for: service) {
            logger.info("n_action_one_key_login: prefetch \(service)")
            getPhoneNumber(success: { (_, _) in
                internelComplete(nil)
            }, failure: { error in
                internelComplete(error)
            })
        } else {
            logger.info("n_action_one_key_login: no need prefetch \(service)")
            internelComplete(nil)
        }
    }
}

// MARK: - interface
extension OneKeyLogin {

    static func needPrefetch(for service: OneKeyLoginService) -> Bool {
        return needPrefetch.value(for: service)
    }

    static func updateSetting(oneKeyLoginConfig: V3OneKeyLoginConfig) {
        guard ReleaseConfig.isFeishu else {
            logger.info("not feishu stop updateSetting")
            return
        }
        if let settings = oneKeyLoginConfig.sdkConfig {
            logger.info("settings count \(settings.count)", method: .local)
            oneKeyService.updateSDKSettings(settings)
            // 电信需要在更新 settings 后补注册一次
            registerService(BDUGAccountOnekeyLogin.sharedInstance(), config: OneKeyLoginService.telecom.config())
        }

        if let config = oneKeyLoginConfig.needPrefetch {
            needPrefetch = config
        }
        
        logger.info("OneKeyLogin from update settings", method: .local)
        prefetch()
    }

    static func getPhoneNumber(trackInfo: [String: Any]? = nil, success: @escaping (String, OneKeyLoginService) -> Void, failure: @escaping (Error) -> Void) {
        guard ReleaseConfig.isFeishu else {
            logger.info("n_action_one_key_login: getPhoneNumber failed: not feishu")
            return
        }
        guard !isGettingNumber else {
            logger.info("n_action_one_key_login: getPhoneNumber skip: have previous getting")
            return
        }

        PassportMonitor.flush(PassportMonitorMetaLogin.startOnekeyLoginNumberPrefetch,
                                eventName: ProbeConst.monitorEventName,
                                context: UniContextCreator.create(.login))
        ProbeDurationHelper.startDuration(ProbeDurationHelper.onekeyLoginNumberPrefetchFlow)

        logger.info("n_action_one_key_login: get security phone \(String(describing: currentService?.carrierName))")
        isGettingNumber = true
        oneKeyService.getOneKeyLoginPhoneNumber(withExtraTrackInfo: trackInfo) { (phoneNumber, service, error) in
            SuiteLoginUtil.runOnMain {
                isGettingNumber = false
                if let err = error {
                    self.prefetchedNumber = nil
                    logger.error("n_action_one_key_login: get phone number from \(service ?? "") failed, error: \(error?.localizedDescription ?? "no desc")", error: err)
                    let duration = ProbeDurationHelper.stopDuration(ProbeDurationHelper.onekeyLoginNumberPrefetchFlow)
                    PassportMonitor.monitor(PassportMonitorMetaLogin.onekeyLoginNumberPrefetchResult,
                                            eventName: ProbeConst.monitorEventName,
                                            categoryValueMap: [ProbeConst.duration: duration],
                                            context: UniContext(.login))
                    .setResultTypeFail()
                    .setPassportErrorParams(error: err)
                    .flush()
                    failure(err)
                } else {
                    logger.info("n_action_one_key_login: get phone number from \(String(describing: service)) number: \(String(describing: phoneNumber)) succeed")
                    let resultNumber = phoneNumber ?? ""
                    let oneKeyService = OneKeyLoginService(rawValue: service ?? "") ?? .mobile
                    self.prefetchedNumber = (resultNumber, oneKeyService)
                    let duration = ProbeDurationHelper.stopDuration(ProbeDurationHelper.onekeyLoginNumberPrefetchFlow)
                    PassportMonitor.monitor(PassportMonitorMetaLogin.onekeyLoginNumberPrefetchResult,
                                            eventName: ProbeConst.monitorEventName,
                                            categoryValueMap: [ProbeConst.duration: duration],
                                            context: UniContext(.login))
                    .setResultTypeSuccess()
                    .flush()
                    success(resultNumber, oneKeyService)
                }
            }
        }
    }

    static func getLoginToken(trackInfo: [String: Any]? = nil, success: @escaping (String) -> Void, failure: @escaping (Error) -> Void) {
        guard ReleaseConfig.isFeishu else {
            logger.warn("getLoginToken failed: not feishu")
            return
        }

        PassportMonitor.flush(PassportMonitorMetaLogin.startOneKeyLoginRequestToken,
                              eventName: ProbeConst.monitorEventName,
                              categoryValueMap: nil,
                              context: UniContextCreator.create(.login))
        ProbeDurationHelper.startDuration(ProbeDurationHelper.loginOneKeyTokenFlow)
        PassportMonitor.flush(EPMClientPassportMonitorLoginCode.onekey_sdk_get_token_request_start, context: UniContextCreator.create(.login))

        oneKeyService.getOneKeyAuthInfo(withExtraTrackInfo: trackInfo) { (info, service, error) in
            SuiteLoginUtil.runOnMain {
                let duration = ProbeDurationHelper.stopDuration(ProbeDurationHelper.loginOneKeyTokenFlow)
                if let err = error {
                    logger.error("n_action_one_key_login: get token from \(service ?? "") failed", error: err)
                    PassportMonitor.monitor(PassportMonitorMetaLogin.oneKeyLoginRequestTokenResult,
                                            eventName: ProbeConst.monitorEventName,
                                            categoryValueMap: [ProbeConst.duration: duration,
                                                               ProbeConst.carrier: "\(service ?? "")"],
                                            context: UniContextCreator.create(.login))
                    .setResultTypeFail()
                    .setPassportErrorParams(error: err)
                    .flush()
                    failure(err)
                } else {
                    PassportMonitor.monitor(PassportMonitorMetaLogin.oneKeyLoginRequestTokenResult,
                                            eventName: ProbeConst.monitorEventName,
                                            categoryValueMap: [ProbeConst.duration: duration],
                                            context: UniContextCreator.create(.login)).setResultTypeSuccess().flush()
                    PassportMonitor.flush(EPMClientPassportMonitorLoginCode.onekey_sdk_get_token_request_succ, context: UniContextCreator.create(.login))

                    logger.info("n_action_one_key_login: get token from \(String(describing: service)) success \(String(describing: info?.token.md5()))")
                    #if DEBUG
                    print("n_action_one_key_login: get token: \(String(describing: info?.token))")
                    #endif
                    success(info?.token ?? "")
                }
            }
        }
    }
}

// MARK: - interface for life cycle
extension OneKeyLogin {
    static func fastLoginResult(_ result: FastLoginResult) {
        switch result {
        case .success:
            isLoggedIn = true
        case .failure:
            isLoggedIn = false
            startNetworkListen()
        }
    }

    static func loginSucceed() {
        isLoggedIn = true
        removeNetworkListen()
    }

    static func logoutSucceed() {
        isLoggedIn = false
        startNetworkListen()
        logger.info("OneKeyLogin from logout")
        prefetch()
    }
}

// MARK: - create vc
extension OneKeyLogin {

    /// One Click Login VC return a boolean to tell whether need more time (loading)
    /// - Parameters:
    ///   - otherLoginAction: additional action when click other login
    ///   - result: result vc
    @discardableResult
    static func oneKeyLoginVC(
        type: OneKeyLoginType,
        loginService: V3LoginService,
        otherLoginAction: (() -> Void)?,
        result: @escaping (OneKeyLoginViewController?) -> Void,
        context: UniContextProtocol
    ) -> Bool {

        if !oneKeyLoginFirstPrefetched {
            logger.warn("n_action_one_key_login: request oneKeyLogin VC when first prefetch is not ready")
        }

        guard ReleaseConfig.isFeishu else {
            logger.info("n_action_one_key_login: use normal login: not feishu")
            result(nil)
            return false
        }

        guard let service = currentService else {
            logger.error("n_action_one_key_login: vc error; use normal login: no carrier service found")
            result(nil)
            return false
        }

        func makeVC(
            number: String,
            context: UniContextProtocol
        ) -> OneKeyLoginViewController {
            let vm = OneKeyLoginViewModel(
                type: type,
                number: number,
                oneKeyService: service,
                service: loginService,
                otherLoginAction: otherLoginAction,
                context: context
            )
            return OneKeyLoginViewController(vm: vm)
        }

        if needPrefetch.value(for: service) {
            if let number = prefetchedNumber {
                logger.info("n_action_one_key_login: use prefetched number")
                result(makeVC(number: number.number, context: context))
            } else {
                logger.error("n_action_one_key_login: error: use prefetch but no prefetch number")
                result(nil)
            }
            return false
        } else {
            getPhoneNumber(success: { (number, _) in
                result(makeVC(number: number, context: context))
            }) { (error) in
                logger.error("n_action_one_key_login: error: not use prefetch and fetch error", error: error)
                result(nil)
            }
            return true
        }
    }
}

enum OneKeyLoginSDKErrorCode: Int {
    case unknown = -1
    case unsupportService = -2
    case unregisterService = -3
    case timeout = -4
}

extension V3OneKeyLoginConfig.NeedPrefetch {
    func value(for service: OneKeyLoginService) -> Bool {
        switch service {
        case .mobile: return mobile ?? Self.defaultMobile
        case .unicom: return unicom ?? Self.defaultUnicom
        case .telecom: return telecom ?? Self.defaultTelecom
        }
    }
}
