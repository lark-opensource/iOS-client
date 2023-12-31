//
//  MessageCardConnector.swift
//  LarkOpenPlatform
//
//  Created by 李论 on 2019/9/26.
//

import LarkAppStateSDK
import Swinject
import RxSwift
import RustPB
import LarkRustClient
import SwiftyJSON
import LarkExtensions
import LKCommonsTracker
import LarkAccountInterface
import EEMicroAppSDK
import LKCommonsLogging
import LarkContainer
import NewLarkDynamic

class MessageCardConnector {
    private let resolver: UserResolver
    private let keyExtra = "bdp_launch_query"
    private let keyUUID = "__trigger_id__"
    private let disposeBag = DisposeBag()
    
    private static var service: ECONetworkService {
        return Injected<ECONetworkService>().wrappedValue
    }

    fileprivate static let logger = Logger.log(MessageCardConnector.self, category: "MessageCardConnector")

    init(resolver: UserResolver) {
        self.resolver = resolver
    }

    func getTriggerCode(callback: @escaping (String) -> Void) {
        let completion = { (response: String?) in
            let result = response ?? UUID().uuidString
            callback("c-" + result)
        }

        if let client = try? resolver.resolve(assert: RustService.self) {
            let req = GetUuidRequest()
            client.sendAsyncRequest(req).observeOn(MainScheduler.instance)
                .subscribe(
                    onNext: { (response: GetUuidResponse) in
                        completion(response.uuid)
                    },
                    onError: { _ in
                        completion(nil)
                    }
            ).disposed(by: disposeBag)
            return
        }

        completion(nil)
    }

    func bindTriggerCode(_ triggerCode: String, _ cardMsgID: String) {
        if OPNetworkUtil.cardUseECONetworkEnabled() {
            reportBindTriggerCodeService(triggerCode, msgID: cardMsgID)
            return
        }
        reportBindTriggerCode(triggerCode, cardMsgID)
    }
    
    private func reportBindTriggerCode(_ triggerCode: String, _ cardMsgID: String) {
        let userID = resolver.userID
        let start = Date()
        if let client = try? resolver.resolve(assert: OpenPlatformHttpClient.self) {
            let api = OpenPlatformAPI.bindTriggerCodeSettingAPI(resolver: resolver)
                .appendParam(key: APIParamKey.user_id, value: userID)
                .appendParam(key: APIParamKey.message_id, value: cardMsgID)
                .appendParam(key: APIParamKey.trigger_code, value: triggerCode)
            client.request(api: api)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { (apiResponse: APIResponse) in
                    if let code = apiResponse.code, code == 0 {
                        self.reportBindEvent(true, nil, start)
                    } else {
                        let errMsg = apiResponse.msg ?? "code is not 0:\(String(describing: apiResponse.code))"
                        self.reportBindEvent(false, errMsg, start)
                    }
                    OPMonitor(MessageCardMonitorCode.messagecard_trigger_code_success)
                        .setDuration(Date().timeIntervalSince(start))
                        .flush()
                }, onError: { (error) in
                    self.reportBindEvent(false, error.localizedDescription, start)
                    var errorInfo: BusinessErrorInfo?
                    if case let .businessFailure( info) = error as? RCError {
                        errorInfo = info
                    }
                    OPMonitor(MessageCardMonitorCode.messagecard_trigger_code_fail)
                        .setErrorCode(String(errorInfo?.errorCode ?? 0))
                        .setErrorMessage(errorInfo?.debugMessage ?? error.localizedDescription)
                        .addCategoryValue(MonitorField.TTLogId, errorInfo?.ttLogId)
                        .flush()
                }, onCompleted: nil, onDisposed: nil)
                .disposed(by: client.disposeBag)
        }
    }
    
    private func reportBindTriggerCodeService(_ code: String, msgID: String) {
        guard let url = OPNetworkUtil.getCardBindTriggerCodeURL() else {
            OPLogger.error("card bind trigger code url failed")
            return
        }
        let start = Date()
        var header: [String: String] = [APIHeaderKey.Content_Type.rawValue: "application/json"]
        if let userService = try? resolver.resolve(assert: PassportUserService.self),
        let sessionID = userService.user.sessionKey {
            header[APIHeaderKey.X_Session_ID.rawValue] = sessionID
        }
        let params: [String: String] = [APIParamKey.user_id.rawValue: resolver.userID,
                                        APIParamKey.message_id.rawValue: msgID,
                                        APIParamKey.trigger_code.rawValue: code]
        let context = OpenECONetworkContext(trace: OPTraceService.default().generateTrace(), source: .other)
        let completionHandler: (ECOInfra.ECONetworkResponse<[String: Any]>?, ECOInfra.ECONetworkError?) -> Void = { [weak self] response, error in
            guard let self = self else {
                OPLogger.error("card bind trigger code failed because self is nil")
                return
            }
            if let error = error as? NSError {
                OPLogger.error("card bind trigger code failed error: \(error)")
                self.reportBindEvent(false, error.localizedDescription, start)
                OPMonitor(MessageCardMonitorCode.messagecard_trigger_code_fail)
                    .setErrorCode("\(error.code)")
                    .setErrorMessage(error.localizedDescription)
                    .flush()
                return
            }
            guard let response = response,
                  let result = response.result else {
                let error = "card bind trigger code failed because response or result is nil"
                let nsError = NSError(domain: error, code: -1, userInfo: nil)
                OPLogger.error(error)
                self.reportBindEvent(false, nsError.localizedDescription, start)
                OPMonitor(MessageCardMonitorCode.messagecard_trigger_code_fail)
                    .setErrorCode("\(nsError.code)")
                    .setErrorMessage(nsError.localizedDescription)
                    .flush()
                return
            }
            OPNetworkUtil.reportLog(OPLogger, response: response)
            let json = JSON(result)
            if let code = json["code"].int, code == 0 {
                self.reportBindEvent(true, nil, start)
            } else {
                let errMsg = json["message"].string ?? "code is not 0:\(String(describing: json["code"].int ?? -1))"
                self.reportBindEvent(false, errMsg, start)
            }
            OPMonitor(MessageCardMonitorCode.messagecard_trigger_code_success)
                .setDuration(Date().timeIntervalSince(start))
                .flush()
        }
        let task = Self.service.post(url: url, header: header, params: params, context: context, requestCompletionHandler: completionHandler)
        if let task = task {
            Self.service.resume(task: task)
        } else {
            OPLogger.error("card bind trigger code url econetwork task failed")
        }
    }

    func appendCodeToMiniProgramUrl(_ targetUrl: String, _ triggerCode: String) -> String? {
        //  目前仅小程序需要添加参数
        guard let url = toMiniProgramUrl(url: targetUrl) else {
            return nil
        }
        let uuidJson: JSON = [keyUUID: triggerCode]
        guard var extraValue = uuidJson.rawString() else {
            MessageCardConnector.logger.error("appendCodeToMiniProgramUrl: uuidJson.rawString() is nil")
            return targetUrl
        }
        if let extraJson = url.queryParameters[keyExtra] {
            var js = JSON(parseJSON: extraJson)
            do {
                try js.merge(with: uuidJson)
            } catch {
                MessageCardConnector.logger.error("JSON merge with uuidJson: \(uuidJson) error \(error)")
                return targetUrl
            }
            extraValue = js.rawString(options: .sortedKeys) ?? extraValue
        }
        return targetUrl.urlStringAddParameter(parameters: [keyExtra: extraValue])
    }
    func appendCodeToTargetUrl(_ targetUrl: String, _ triggerCode: String) -> String? {
        guard let url = targetUrl.possibleURL() else {
            return nil
        }
        let uuidJson: JSON = [keyUUID: triggerCode]
        guard var extraValue = uuidJson.rawString() else {
            MessageCardConnector.logger.error("appendCodeToTargetUrl: uuidJson.rawString()is nil")
            return targetUrl
        }
        if let extraJson = url.queryParameters[keyExtra] {
            var js = JSON(parseJSON: extraJson)
            do {
                try js.merge(with: uuidJson)
            } catch {
                MessageCardConnector.logger.error("JSON merge with uuidJson: \(uuidJson) error")
                return targetUrl
            }
            extraValue = js.rawString() ?? extraValue
        }
        return targetUrl.urlStringAddParameter(parameters: [keyExtra: extraValue])
    }

    private func toMiniProgramUrl(url: String) -> URL? {
        guard let microAppService: MicroAppService = try? resolver.resolve(assert: MicroAppService.self) else {
            return nil
        }
        if microAppService.canOpen(url: url) {
            return url.possibleURL()
        }
        //  兼容头条圈
        /*  暂时不考虑兼容http跳转方式
        if let Url = possibleURL(urlStr: url),
            let convertUrl = MicroAppRouteConfigManager.convertHttpToSSLocal(Url) {
            return convertUrl
        }
        */
        return nil
    }

    private func reportBindEvent(_ isSuccess: Bool, _ errMsg: String?, _ start: Date) {
        var category = ["state": isSuccess ? "success" : "fail"]
        if errMsg != nil {
            category["errorMsg"] = errMsg
        }
        let metric = ["duration": Date().timeIntervalSince(start)]
        Tracker.post(SlardarEvent(name: "messagecard_trigger_code", metric: metric, category: category, extra: [:]))
    }
}

typealias GetUuidRequest = RustPB.Openplatform_V1_GetUuidRequest
typealias GetUuidResponse = RustPB.Openplatform_V1_GetUuidResponse
