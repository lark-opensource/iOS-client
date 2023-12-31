//
//  LarkMagicServiceImpl.swift
//  LarkMagic
//
//  Created by mochangxing on 2020/11/8.
//

import Foundation
import UIKit
import ADFeelGood
import EENavigator
import LKCommonsLogging
import LarkContainer
import LarkAccountInterface
import ThreadSafeDataStructure
import LarkSecurityAudit
import LarkPrivacySetting

struct LarkMagicDelegateWrapper {
    weak var delegate: LarkMagicDelegate?
}

final class LarkMagicServiceImpl: LarkMagicService, UserResolverWrapper {
    var setupTask: LarkMagicSDKSetupTask? {
        didSet {
            setupTask?.didUpdateConfigHandler = { [weak self] in
                Self.logger.info("LarkMagicServiceImpl update config")
                self?.config = $0
            }
        }
    }

    static let logger = Logger.log(LarkMagicServiceImpl.self, category: "LarkMagic")
    static let scenarioKey = "scenario"
    static let secretIdKey = "secret_id"
    static let tenantIdKey = "tenant_id"

    private var scenarioID2VC: [String: ContainerProvider] = [:]
    private var scenarioID2Wrapper: [String: LarkMagicDelegateWrapper] = [:]

    private var scenarioIDs: SafeArray<String> = [] + .readWriteLock
    private let interceptorManager: LarkMagicInterceptorManager
    @ScopedProvider private var passportUserService: PassportUserService?

    var config: LarkMagicConfig?

    var isSDKInitialized: Bool = false // SDK是否初始化过
    let userResolver: UserResolver
    init(interceptorManager: LarkMagicInterceptorManager, userResolver: UserResolver) {
        self.interceptorManager = interceptorManager
        self.userResolver = userResolver
    }

    public var currentScenarioID: String? {
        return scenarioIDs.last
    }

    public func register(scenarioID: String,
                         interceptor: ScenarioInterceptor,
                         containerProvider: @escaping ContainerProvider) {
        guard Thread.isMainThread else {
            LarkMagicServiceImpl.logger.error("register must in main thread")
            return
        }
        register(scenarioID: scenarioID,
                 params: nil,
                 interceptor: interceptor,
                 containerProvider: containerProvider)
    }

    func register(scenarioID: String,
                  params: [String: String]?,
                  interceptor: ScenarioInterceptor,
                  containerProvider: @escaping ContainerProvider) {
        guard Thread.isMainThread else {
            LarkMagicServiceImpl.logger.error("register must in main thread")
            return
        }
        register(scenarioID: scenarioID,
                 params: params,
                 delegate: nil,
                 interceptor: interceptor,
                 containerProvider: containerProvider)
    }

    func register(scenarioID: String,
                  params: [String: String]?,
                  delegate: LarkMagicDelegate?,
                  interceptor: ScenarioInterceptor,
                  containerProvider: @escaping ContainerProvider) {
        guard scenarioID2VC[scenarioID] == nil else {
            LarkMagicServiceImpl.logger.error("scenarioID has exist",
                                              additionalData: ["scenarioID": scenarioID])
            return
        }
        scenarioIDs.append(scenarioID)
        scenarioID2VC[scenarioID] = containerProvider
        interceptorManager.registerInterceptor(scenarioID, interceptor)
        if let delegate = delegate {
            scenarioID2Wrapper[scenarioID] = LarkMagicDelegateWrapper(delegate: delegate)
        }
        LarkMagicServiceImpl.logger.info("register scenarioID",
                                          additionalData: ["scenario": scenarioID])
    }

    public func unregister(scenarioID: String) {
        scenarioID2VC.removeValue(forKey: scenarioID)
        if let index = scenarioIDs.firstIndex(where: { $0 == scenarioID }) {
            scenarioIDs.remove(at: index)
        }
        scenarioID2Wrapper.removeValue(forKey: scenarioID)
        interceptorManager.unregisterInterceptor(scenarioID)
        LarkMagicServiceImpl.logger.info("unregister scenarioID",
                                          additionalData: ["scenario": scenarioID])
    }

    func creatOpenModel(extraUserInfo: [AnyHashable: Any]) -> ADFeelGoodOpenModel {
        let model = ADFeelGoodOpenModel()
        model.extraUserInfo = extraUserInfo
        if let scenarioID = currentScenarioID {
            model.parentVC = scenarioID2VC[scenarioID]?()
        }
        model.needLoading = false
        model.darkModeType = .system
        if let darkModeType = extraUserInfo["feelgood_darkmode"] as? String {
            if darkModeType == "0" {
                model.darkModeType = .light
            } else if darkModeType == "1" {
                model.darkModeType = .dark
            }
        }
        if let timeout = config?.timeout {
            model.timeoutInterval = TimeInterval(Double(timeout) / 1000.0)
        }
        if #available(iOS 13.0, *),
           let windowScene = UIApplication.shared.windowApplicationScenes.first as? UIWindowScene {
            model.windowScene = windowScene
        }
        return model
    }

    func creatUserInfo(eventName: String, extraParams: [AnyHashable: Any]? = nil) -> [AnyHashable: Any] {
        var userInfo = [AnyHashable: Any]()
        if let scenarioID = currentScenarioID {
            userInfo[Self.scenarioKey] = scenarioID
        }
        if let extraParams = extraParams {
            extraParams.forEach { (key, value) in
                userInfo[key] = value
            }
        }
        // uid 临时加密方案，后续下线
        userInfo[Self.secretIdKey] = secreatString(str: userResolver.userID)
        userInfo[Self.tenantIdKey] = secreatString(str: passportUserService?.user.tenant.tenantID ?? "")
        return userInfo
    }

    func triggerEvent(eventName: String,
                      extraParams: [AnyHashable: Any]? = nil) {
        guard checkSDKAuthority() else { return }
        if !isSDKInitialized { // try to initialize sdk
            if let task = setupTask, let appkey = config?.feelgoodAppKey {
                task.initFeelGood(appKey: appkey)
                self.isSDKInitialized = true
            } else {
                LarkMagicServiceImpl.logger.error("magic service: \(String(describing: config)), \(String(describing: config?.feelgoodAppKey))")
                LarkMagicServiceImpl.logger.error("magic service init sdk failed",
                                                 additionalData: ["task": "\(setupTask == nil)",
                                                                  "appkey": "\(config?.feelgoodAppKey == nil)"])
                return
            }
        }
        guard config != nil, !eventName.isEmpty else {
            LarkMagicServiceImpl.logger.info("magic service no ready",
                                             additionalData: ["hasConfig": "\(config != nil)",
                                                              "eventNameIsEmpty": "\(eventName.isEmpty)"])
            return
        }
        let extraUserInfo = creatUserInfo(eventName: eventName, extraParams: extraParams)
        let lastScenarioID = extraUserInfo[Self.scenarioKey] as? String
        let openModel = creatOpenModel(extraUserInfo: extraUserInfo)
        LarkMagicServiceImpl.logger.info("triggerEvent",
                                         additionalData: ["eventName": eventName,
                                                          "extraUserInfo": "\(extraUserInfo)"])

        let start = LarkMagicTracker.timeCostStart()

        func reportCompletion(_ success: Bool,
                              _ dataDict: [AnyHashable: Any],
                              _ error: Error,
                              _ feelGoodInfo: ADFeelGoodInfo) {

            let cost = LarkMagicTracker.timeCostEnd(for: start)
            LarkMagicTracker.trackTriggerEvent(succeed: success,
                                               scenario: lastScenarioID,
                                               cost: cost,
                                               errorCode: success ? nil : error._code,
                                               errorMsg: success ? nil : error.localizedDescription)
            if let taskID = feelGoodInfo.taskID {
                LarkMagicTracker.trackWillOpen(taskID: taskID, scenario: lastScenarioID ?? "")
            }

            LarkMagicServiceImpl.logger.info("report completion",
                                             additionalData: ["taskID": feelGoodInfo.taskID ?? "",
                                                              "eventName": eventName])
        }

        let willOpen = { [weak self] (_ feelGoodInfo: ADFeelGoodInfo) -> Bool in
            guard let self = self else {
                return false
            }
            var canShow = false

            // 是否是同一个ScenarioID
            func isSameScenarioID() -> Bool {
                guard let last = lastScenarioID,
                      let current = self.currentScenarioID else {
                    return false
                }
                return last == current
            }

            if feelGoodInfo.isGlobalDialog {
                canShow = self.interceptorManager.canShow(scenarioID: "")
            } else if isSameScenarioID() {
                canShow = self.interceptorManager.canShow(scenarioID: lastScenarioID ?? "")
            }

            if canShow, let scenarioID = lastScenarioID,
               let delegate = self.scenarioID2Wrapper[scenarioID]?.delegate,
               let taskID = feelGoodInfo.taskID {
                delegate.taskWillOpen(taskID)
            }
            return canShow
        }

        let didOpen = { [weak self] (_ success: Bool, _ feelGoodInfo: ADFeelGoodInfo, _ error: Error) in
            let cost = LarkMagicTracker.timeCostEnd(for: start)
            LarkMagicTracker.trackDidOpen(succeed: success,
                                          taskId: feelGoodInfo.taskID ?? "",
                                          scenario: lastScenarioID ?? "",
                                          cost: cost,
                                          errorCode: success ? nil : error._code,
                                          errorMsg: success ? nil : error.localizedDescription)
            self?.didOpen(scenarioID: lastScenarioID ?? "", taskID: feelGoodInfo.taskID ?? "")
        }

        func didClose(_ submitSuccess: Bool, _ feelGoodInfo: ADFeelGoodInfo) {
            LarkMagicTracker.trackDidClosed(submitSuccess: submitSuccess, taskId: feelGoodInfo.taskID ?? "")

        }

        // 防止全局弹窗，导致键盘失去焦点
        let enableOpen = { [weak self] (_ feelGoodInfo: ADFeelGoodInfo) -> Bool in
            guard let self = self else {
                return false
            }
            if feelGoodInfo.isGlobalDialog {
                return self.interceptorManager.canShow(scenarioID: "")
            }
            return true
        }

        ADFeelGoodManager.sharedInstance().triggerEventAndOpen(withEvent: eventName,
                                                               openModel: openModel,
                                                               reportCompletion: reportCompletion,
                                                               enableOpen: enableOpen,
                                                               willOpen: willOpen,
                                                               didOpen: didOpen,
                                                               didClose: didClose)
    }

    func didOpen(scenarioID: String, taskID: String) {
        LarkMagicServiceImpl.logger.info("did ppen",
                                         additionalData: ["scenarioID": scenarioID,
                                                          "taskID": taskID])
        guard let delegate = scenarioID2Wrapper[scenarioID]?.delegate else {
            return
        }
        delegate.taskDidOpen(taskID)
    }

    func didClosed(scenarioID: String, taskID: String) {
        LarkMagicServiceImpl.logger.info("did closed",
                                         additionalData: ["scenarioID": scenarioID,
                                                          "taskID": taskID])
        guard let delegate = scenarioID2Wrapper[scenarioID]?.delegate else {
            return
        }
        delegate.taskDidClosed(taskID)
    }

    deinit {
        interceptorManager.removeAllInterceptors()
    }

    func checkSDKAuthority() -> Bool {
        let isAuth = LarkFeelgoodAuthority.checkSDKAuthority()
        Self.logger.info("[FeelGood]{check sdk authority}: \(isAuth)")
        return isAuth
    }
}
