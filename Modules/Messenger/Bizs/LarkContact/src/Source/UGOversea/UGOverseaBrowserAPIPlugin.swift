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
import LKCommonsTracker

private let joinByCodeAPI = "biz.ug.oversea.join.code"
private let createTeamAPI = "biz.ug.oversea.create.tenant"
private let createPersonalAPI = "biz.ug.oversea.create.personal"
private let closeNaviAPI = "biz.navigation.close"
private let checkHealthAPI = "biz.ug.oversea.check.health"
private let utilLogAPI = "biz.util.log"
private let utilTeaTrackerAPI = "biz.util.base.event.track"

final class UGOverseaBrowserAPIPlugin: OpenBasePlugin {

    @Provider var deviceService: DeviceService //Global
    @Provider var accountServiceUG: AccountServiceUG //Global
    private var loggerTool = UGOverseaBrowserTool()

    required init(resolver: UserResolver) {
        super.init(resolver: resolver)

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

        registerAsyncHandler(for: checkHealthAPI) { [weak self] (_, context, callback) in
            guard let self = self else { return }

            let api = checkHealthAPI
            let stepInfoName = "backup"

            self.loggerTool.log("js call api: \(api)")

            guard let param = context.additionalInfo["params"] as? [String: Any],
                  let health = param["isHealth"] as? Bool else {
                self.loggerTool.log("js call api: \(api) error, get health value fail")
                return
            }

            if !health {
                self.loggerTool.log("js call api: \(api) page bad health")

                //在health = false时，先关闭容器
                guard let browser = context.additionalInfo["controller"] as? WebBrowser else {
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                    callback(.failure(error: error))
                    return
                }
                browser.closeWith(animated: false)
                //slardar监控
                let scene: String = param["stepName"] as? String ?? "none"
                self.accountServiceUG.fallbackProbe(by: "checkHealth", in: scene)
                //进入backup流程
                handleNextRegistStep(api: checkHealthAPI, stepInfoName: stepInfoName, context: context, callback: callback)
            } else {
                self.loggerTool.log("js call api: \(api) page good health")
                guard let browser = context.additionalInfo["controller"] as? WebBrowser else {
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                    self.loggerTool.error("checkHealth: controller is nil")
                    callback(.failure(error: error))
                    return
                }
                guard let item = browser.resolve(UGOverseaWebBrowserLoadItem.self) else {
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                    self.loggerTool.error("checkHealth: loadItem is nil")
                    callback(.failure(error: error))
                    return
                }
                item.handleFinishLoad(succ: true)
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

        registerAsyncHandler(for: utilTeaTrackerAPI, paramsType: UGTeaTrackerParams.self, resultType: OpenAPIBaseResult.self) { [weak self] (params, _, callback) in
            self?.loggerTool.log("js call api: \(utilTeaTrackerAPI)")
            Tracker.post(TeaEvent(params.eventName, params: params.eventParams ?? [:]))

            callback(.success(data: nil))
        }

        registerAsyncHandler(for: joinByCodeAPI) { [weak self] (_, context, callback) in
            guard let self = self else { return }

            let api = joinByCodeAPI
            let stepInfoName = "callback_join_simple"
            let codeKey = "codeValue"

            self.loggerTool.log("js call api: \(api)")

            guard let stepInfo = context.additionalInfo["stepInfo"] as? [String: Any],
                  let nextStep = stepInfo[stepInfoName] as? [String: Any] else {
                self.loggerTool.log("js call api: \(api) error, step info decode fail")
                let result = UGOverseaDispatchNextResult(code: "1")
                callback(.success(data: result))
                return
            }

            guard let param = context.additionalInfo["params"] as? [String: Any],
                  let tenantCode = param[codeKey] as? String else {
                self.loggerTool.log("js call api: \(api) error, get code fail")
                return
            }

            self.accountServiceUG.joinByCode(code: tenantCode, stepInfo: nextStep) {
                let result = UGOverseaDispatchNextResult(code: "0")
                callback(.success(data: result))
            } failure: { [weak self] error in
                let result = UGOverseaDispatchNextResult(code: "1")
                callback(.success(data: result))
                self?.loggerTool.log("js call api: \(api) error: \(error)")
            }
        }

        registerAsyncHandler(for: createTeamAPI) { (_, context, callback) in
            handleNextRegistStep(api: createTeamAPI, stepInfoName: "callback_create", context: context, callback: callback)
        }

        registerAsyncHandler(for: createPersonalAPI) { (_, context, callback) in
            handleNextRegistStep(api: createTeamAPI, stepInfoName: "callback_create_simple", context: context, callback: callback)
        }

        func handleNextRegistStep(api: String,
                                  stepInfoName: String,
                                  context: OpenAPIContext,
                                  callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
            loggerTool.log("js call api: \(api)")
            guard let stepInfo = context.additionalInfo["stepInfo"] as? [String: Any],
                  let nextStep = stepInfo[stepInfoName] as? [String: Any] else {
                loggerTool.log("js call api: \(api) error, step info decode fail")
                let result = UGOverseaDispatchNextResult(code: "1")
                callback(.success(data: result))
                return
            }
            self.accountServiceUG.dispatchNext(stepInfo: nextStep) {
                let result = UGOverseaDispatchNextResult(code: "0")
                callback(.success(data: result))
            } failure: { [weak self] error in
                let result = UGOverseaDispatchNextResult(code: "1")
                callback(.success(data: result))
                self?.loggerTool.log("js call api: \(api) error: \(error)")
            }
        }
    }
}

private final class UGOverseaDispatchNextResult: OpenAPIBaseResult {

    public let code: String

    public init(code: String) {
        self.code = code
        super.init()
    }

    public override func toJSONDict() -> [AnyHashable: Any] {
        return ["code": code]
    }
}
