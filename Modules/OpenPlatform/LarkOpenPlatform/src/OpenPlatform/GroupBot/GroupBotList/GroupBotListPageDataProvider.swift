//
//  GroupBotListPageDataProvider.swift
//  LarkOpenPlatform
//
//  Created by houjihu on 2021/3/23.
//

import LKCommonsLogging
import RxSwift
import Swinject
import LarkAccountInterface
import ECOProbe
import LarkContainer
import LarkFoundation
import OPFoundation
import SwiftyJSON

/// 「群机器人」页面数据提供者
class GroupBotListPageDataProvider {
    static let logger = Logger.oplog(GroupBotListPageDataProvider.self, category: GroupBotDefines.groupBotLogCategory)
    private let resolver: UserResolver
    var locale: String
    var model: GroupBotListPageDataModel?
    let chatID: String
    private var updateCallback: ((Error?, GroupBotListPageDataModel?) -> Void)?
    private let disposeBag = DisposeBag()
    private static var service: ECONetworkService {
        return Injected<ECONetworkService>().wrappedValue
    }

    /// 初始化方法
    /// - Parameters:
    ///   - resolver: Resolver
    ///   - locale: 当前国际化标识
    ///   - chatID: chat id
    init(resolver: UserResolver, locale: String, chatID: String) {
        self.resolver = resolver
        self.locale = locale
        self.chatID = chatID
    }

    /// 更新数据
    func updateRemoteItems(updateCallback: ((Error?, GroupBotListPageDataModel?) -> Void)? = nil) {
        Self.logger.info("updateRemoteItems")
        self.updateCallback = updateCallback
        updateRemoteData()
    }

    /// 更新列表数据
    private func updateRemoteData() {
        Self.logger.info("updateRemoteData")
        
        let monitorCodeSuccess = EPMClientOpenPlatformGroupBotCode.pull_groupbot_list_success
        let monitorCodeFail = EPMClientOpenPlatformGroupBotCode.pull_groupbot_list_fail
        let monitorSuccess = OPMonitor(monitorCodeSuccess)
            .setResultTypeSuccess()
            .timing()
            .addCategoryValue(GroupBotDefines.keyChatID, chatID)
        let monitorFail = OPMonitor(monitorCodeFail)
            .setResultTypeFail()
            .addCategoryValue(GroupBotDefines.keyChatID, chatID)
        let onSelfError: () -> Void = { 
            let errorMessage = "self missed, request exit"
            Self.logger.error(errorMessage)
        }
        let onError: (Error) -> Void = { [weak self] error in
            Self.logger.error("request group bot list failed with backEnd-Error: \(error.localizedDescription)")
            let logID = (error as NSError).userInfo[OpenPlatformHttpClient.lobLogIDKey] as? String
            monitorFail.addCategoryValue(GroupBotDefines.keyRequestID, logID)
                .setError(error)
                .flush()
            DispatchQueue.main.async {
                self?.onRequestFail(err: error)
            }
        }
        let onSuccess: (APIResponse) -> Void = { [weak self] result in
            Self.logger.info("success \(result.code ?? -1)")
            guard let self = self else {
                onSelfError()
                return
            }
            let errorDomain = "GroupBotRequest"
            let logID = result.lobLogID
            if let resultCode = result.code, resultCode == 0 {
                if let dataModel = result.buildDataModel(type: GroupBotListPageDataModel.self) {
                    Self.logger.info("fetch group bot list data complete, parse to model success, refresh page")
                    monitorSuccess
                        .addCategoryValue(GroupBotDefines.keyRequestID, logID)
                        .timing()
                        .flush()
                    DispatchQueue.main.async {
                        self.onRequestSuccess(dataModel: dataModel)
                    }
                } else {
                    let buildDataModelFailCode = -1
                    let buildDataModelFailMessage = "fetch group bot list data complete, parse to model failed, show failed page"
                    let error = NSError(domain: errorDomain,
                                        code: buildDataModelFailCode,
                                        userInfo: [NSLocalizedDescriptionKey: buildDataModelFailMessage])
                    Self.logger.error("\(buildDataModelFailMessage)", error: error)
                    monitorFail
                        .addCategoryValue(GroupBotDefines.keyRequestID, logID)
                        .setError(error)
                        .flush()
                    DispatchQueue.main.async {
                        self.onRequestFail(err: error)
                    }
                }
            } else {
                let errCode = result.json["code"].intValue
                let errMsg = result.json["msg"].stringValue
                Self.logger.error("request group bot failed with errCode: \(errCode), errMsg: \(errMsg)")
                let error = NSError(domain: errorDomain,
                                    code: errCode,
                                    userInfo: [NSLocalizedDescriptionKey: errMsg])
                monitorFail
                    .addCategoryValue(GroupBotDefines.keyRequestID, logID)
                    .setError(error)
                    .flush()
                DispatchQueue.main.async {
                    self.onRequestFail(err: error)
                }
            }
        }
        
        if OPNetworkUtil.basicUseECONetworkEnabled() {
            guard let url = OPNetworkUtil.getGroupBotListPageDataURL() else {
                Self.logger.error("get group bot list url failed")
                return
            }
            var header: [String: String] = [APIHeaderKey.Content_Type.rawValue: "application/json"]
            if let userService = try? resolver.resolve(assert: PassportUserService.self) {
                let sessionID: String? = userService.user.sessionKey
                header[APIHeaderKey.X_Session_ID.rawValue] = sessionID
                // 对照原网络接口参数实现, 若session:nil, 则不为Header添加Cookie:value键值对
                if let value = sessionID {
                    header[APIHeaderKey.Cookie.rawValue] = "\(APICookieKey.session.rawValue)=\(value)"
                }
            }
            let params: [String: Any] = [APIParamKey.larkVersion.rawValue: Utils.appVersion,
                                         APIParamKey.chat_id.rawValue: chatID,
                                         APIParamKey.locale.rawValue:OpenPlatformAPI.curLanguage()]
            let context = OpenECONetworkContext(trace: OPTraceService.default().generateTrace(), source: .other)
            let completionHandler: (ECOInfra.ECONetworkResponse<[String: Any]>?, ECOInfra.ECONetworkError?) -> Void = { [weak self] response, error in
                if let error = error {
                    onError(error)
                    return
                }
                guard let self = self else {
                    let error = "group bot list failed because self is nil"
                    let nsError = NSError(domain: error, code: -1, userInfo: nil)
                    onError(nsError)
                    return
                }
                guard let response = response,
                      let result = response.result else {
                    let error = "group bot list failed because response or result is nil"
                    let nsError = NSError(domain: error, code: -1, userInfo: nil)
                    onError(nsError)
                    return
                }
                let json = JSON(result)
                let obj = APIResponse(json: json, api: OpenPlatformAPI(path: .empty, resolver: self.resolver))
                let logID = OPNetworkUtil.reportLog(Self.logger, response: response)
                obj.lobLogID = logID
                onSuccess(obj)
            }
            let task = Self.service.post(url: url, header: header, params: params, context: context, requestCompletionHandler: completionHandler)
            if let task = task {
                Self.service.resume(task: task)
            } else {
                Self.logger.error("group bot list url econetwork task failed")
            }
            return
        }
        
        guard let client = try? resolver.resolve(assert: OpenPlatformHttpClient.self) else {
            Self.logger.error("resolve OpenPlatformHttpClient failed,fetch data exit")
            return
        }
        let requestAPI = OpenPlatformAPI.getGroupBotListPageDataAPI(chatID: chatID, resolver: resolver)
        client.request(api: requestAPI).observeOn(ConcurrentDispatchQueueScheduler(queue: .global()))
            .subscribe(onNext: { result in
                onSuccess(result)
            }, onError: { error in
                onError(error)
            }).disposed(by: self.disposeBag)
    }

    /// 成功回调
    private func onRequestSuccess(dataModel: GroupBotListPageDataModel) {
        Self.logger.info("onRequestSuccess bots:\(dataModel.bots?.count ?? 0)")
        model = dataModel
        self.updateCallback?(nil, model)
        self.updateCallback = nil
    }

    /// 失败回调
    private func onRequestFail(err: Error? = nil) {
        Self.logger.error("onRequestFail with error: \(String(describing: err))")
        self.updateCallback?(err, nil)
        self.updateCallback = nil
    }
}
