//
//  UGBrowserAPIPlugin.swift
//  LarkContact
//
//  Created by aslan on 2022/2/22.
//

import Foundation
import LarkOpenPluginManager
import Reachability
import LarkOpenAPIModel
import CoreTelephony
import LarkAccountInterface
import LarkContainer
import WebBrowser
import EENavigator
import LarkUIKit
import LarkTab
import RxSwift
import LarkRustClient
import ServerPB

private let getNetworkTypeAPI = "device.connection.getNetworkType"
private let getDeviceIdAPI = "biz.account.getDeviceId"
private let utilLogAPI = "biz.util.log"
private let joinTeamAPI = "biz.ug.joinTeam"
private let createTeamAPI = "biz.ug.createTeam"
private let closeNaviAPI = "biz.navigation.close"
private let closeRegisterAPI = "biz.ug.register.close"
private let closeSMBGuideAPI = "biz.ug.guide.toast.close"
private let authorizeIndustryOnboardingAPI = "biz.ug.register.industry.authorize.finish"
private let industryOnboardingPrivacyLinkAPI = "biz.ug.register.industry.authorize.jump"

final class UGBrowserAPIPlugin: OpenBasePlugin {

    @Provider var deviceService: DeviceService //Global
    @Provider var accountServiceUG: AccountServiceUG //Global
    private var loggerTool = UGBrowserTool()

    required init(resolver: UserResolver) {
        super.init(resolver: resolver)

        registerAsyncHandler(for: closeSMBGuideAPI) { [weak self] (_, context, callback) in
            self?.loggerTool.log("js call api: \(closeSMBGuideAPI)")
            guard let browser = context.additionalInfo["controller"] as? WebBrowser else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                self?.loggerTool.error("controller is nil")
                callback(.failure(error: error))
                return
            }
            browser.parent?.dismiss(animated: true, completion: {
                guard let param = context.additionalInfo["params"] as? [String: Any],
                      let url = param["applink"] as? String,
                      let URL = URL(string: url),
                      let window = Navigator.shared.mainSceneWindow else { //Global
                          self?.loggerTool.error("url parse fail")
                          return
                      }
                Navigator.shared.present(URL, from: window) //Global
                // 执行后续任务
                OnboardingTaskManager.getSharedInstance().executeNextTask()
            })
            callback(.success(data: nil))
        }

        registerAsyncHandler(for: closeRegisterAPI) { [weak self] (_, context, callback) in
            self?.loggerTool.log("js call api: \(closeRegisterAPI)")
            guard let browser = context.additionalInfo["controller"] as? WebBrowser else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                self?.loggerTool.error("controller is nil")
                callback(.failure(error: error))
                return
            }
            Navigator.shared.switchTab(Tab.feed.url, from: browser) //Global
            // 执行后续任务
            OnboardingTaskManager.getSharedInstance().executeNextTask()
            callback(.success(data: nil))
        }

        registerAsyncHandler(for: getNetworkTypeAPI) { [weak self] (_, _, callback) in
            self?.loggerTool.log("js call api: \(getNetworkTypeAPI)")
            let status = Self.networkStatus()
            self?.loggerTool.log("js call api: \(getNetworkTypeAPI), result: \(status)")
            let data = UGNetworkTypeResult(status: status)
            callback(.success(data: data))
        }

        registerAsyncHandler(for: getDeviceIdAPI) { [weak self] _, _, callback in
            self?.loggerTool.log("js call api: \(getDeviceIdAPI)")
            if let deviceId = self?.deviceService.deviceId {
                let deviceInfo = UGDeviceInfoResult(deviceId: deviceId)
                callback(.success(data: deviceInfo))
                self?.loggerTool.log("js call api: \(getDeviceIdAPI), result: has deviceId")
            } else {
                callback(.failure(error: OpenAPIError(code: OpenAPICommonErrorCode.internalError)))
                self?.loggerTool.log("js call api: \(getDeviceIdAPI), result: no deviceId")
            }
        }

        registerAsyncHandler(for: utilLogAPI, paramsType: UGLogParams.self, resultType: OpenAPIBaseResult.self) { [weak self] (params, _, callback) in
            params.logMessage
            self?.loggerTool.log("js call api: \(utilLogAPI)")
            switch params.level {
            case "info":
                self?.loggerTool.log(params.logMessage)
            case "error":
                self?.loggerTool.error(params.logMessage)
            case "warn":
                self?.loggerTool.warn(params.logMessage)
            default:
                self?.loggerTool.log(params.logMessage)
            }

            callback(.success(data: nil))
        }

        registerAsyncHandler(for: closeNaviAPI) { [weak self] (_, context, callback) in
            self?.loggerTool.log("js call api: \(closeNaviAPI)")
            guard let browser = context.additionalInfo["controller"] as? WebBrowser else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                self?.loggerTool.error("controller is nil")
                callback(.failure(error: error))
                return
            }
            browser.navigationController?.popViewController(animated: true)
            callback(.success(data: nil))
        }

        registerAsyncHandler(for: joinTeamAPI) { (_, context, callback) in
            handleNextRegistStep(api: joinTeamAPI, stepInfoName: "callback_join", context: context, callback: callback)
        }

        registerAsyncHandler(for: createTeamAPI) { (_, context, callback) in
            handleNextRegistStep(api: createTeamAPI, stepInfoName: "callback_create", context: context, callback: callback)
        }

        registerAsyncHandler(for: authorizeIndustryOnboardingAPI) { (_, context, callback) in
            ContactLogger.shared.info(module: ContactLogger.Module.onboarding,
                                       event: "industry - jsb: ",
                                       parameters: "\(authorizeIndustryOnboardingAPI)")
            guard let param = context.additionalInfo["params"] as? [String: Any],
                  let authorizedString = param["is_authorized"] as? String else {
                ContactLogger.shared.error(module: ContactLogger.Module.onboarding,
                                           event: "industry onboarding finish error: ",
                                           parameters: "\(context.additionalInfo)")
                let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                callback(.failure(error: error))
                return
            }
            let isAuthorized = authorizedString == "1"
            let name = Notification.Name("ug.onboarding.industry.finish")
            NotificationCenter.default.post(name: name, object: nil, userInfo: ["isAuthorized": isAuthorized])
            callback(.success(data: nil))
        }

        registerAsyncHandler(for: industryOnboardingPrivacyLinkAPI) { (_, context, callback) in
            ContactLogger.shared.info(module: ContactLogger.Module.onboarding,
                                       event: "industry - jsb: ",
                                       parameters: "\(industryOnboardingPrivacyLinkAPI)")
            guard let param = context.additionalInfo["params"] as? [String: Any],
                  let urlString = param["url"] as? String,
                  let url = URL(string: urlString.trimmingCharacters(in: .whitespacesAndNewlines)) else {
                ContactLogger.shared.error(module: ContactLogger.Module.onboarding,
                                           event: "industry - onboarding open link error: ",
                                           parameters: "\(context.additionalInfo)")
                let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                callback(.failure(error: error))
                return
            }
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
            callback(.success(data: nil))
        }

        func handleNextRegistStep(api: String,
                                  stepInfoName: String,
                                  context: OpenAPIContext,
                                  callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
            loggerTool.log("js call api: \(api)")
            guard let stepInfo = context.additionalInfo["stepInfo"] as? [String: Any],
            let nextStep = stepInfo[stepInfoName] as? [String: Any] else {
                loggerTool.log("js call api: \(api) error, step info decode fail")
                let result = UGDispatchNextResult(code: "1")
                callback(.success(data: result))
                return
            }
            self.accountServiceUG.dispatchNext(stepInfo: nextStep) {
                let result = UGDispatchNextResult(code: "0")
                callback(.success(data: result))
            } failure: { [weak self] error in
                let result = UGDispatchNextResult(code: "1")
                callback(.success(data: result))
                self?.loggerTool.log("js call api: \(api) error: \(error)")
            }
        }
    }

    static func networkStatus() -> String {
        guard let reach = Reachability() else { return "unkown" }
        if reach.connection == .wifi {
            return "wifi"
        } else if reach.connection == .cellular {
            switch CTTelephonyNetworkInfo.lu.shared.lu.currentSpecificStatus {
            case .📶2G:
                return "2G"
            case .📶3G:
                return "3G"
            case .📶4G:
                return "4G"
            case .📶5G:
                return "5G"
            default:
                return "unknown"
            }
        }
        return "none"
    }
}

private final class UGDispatchNextResult: OpenAPIBaseResult {

    public let code: String

    public init(code: String) {
        self.code = code
        super.init()
    }

    public override func toJSONDict() -> [AnyHashable: Any] {
        return ["code": code]
    }
}

private final class UGNetworkTypeResult: OpenAPIBaseResult {

    public let status: String

    public init(status: String) {
        self.status = status
        super.init()
    }

    public override func toJSONDict() -> [AnyHashable: Any] {
        return ["result": status, "networkType": status]
    }
}

private final class UGDeviceInfoResult: OpenAPIBaseResult {

    public let deviceId: String

    public init(deviceId: String) {
        self.deviceId = deviceId
        super.init()
    }

    public override func toJSONDict() -> [AnyHashable: Any] {
        return ["deviceId": deviceId]
    }
}

public final class UGLogParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "logMessage")
    public var logMessage: String

    @OpenAPIOptionalParam(jsonKey: "level")
    public var level: String?

    // declare your properties here
    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        // add your checkable properties here
        return [_logMessage, _level]
    }
}

public final class UGTeaTrackerParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "eventName")
    public var eventName: String

    @OpenAPIOptionalParam(jsonKey: "eventParams")
    public var eventParams: [String: Any]?

    // declare your properties here
    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        // add your checkable properties here
        return [_eventName, _eventParams]
    }
}
