//
//  AddBotPageDataProvider.swift
//  LarkOpenPlatform
//
//  Created by houjihu on 2021/3/10.
//

import LKCommonsLogging
import RxSwift
import Swinject
import LarkAccountInterface
import ECOProbe
import LarkFeatureGating
import LarkContainer
import ECOInfra
import SwiftyJSON
import OPFoundation
import LarkFoundation

/// 「添加机器人」数据提供者
class AddBotPageDataProvider {
    static let logger = Logger.oplog(AddBotPageDataProvider.self, category: GroupBotDefines.groupBotLogCategory)
    private let resolver: UserResolver
    var locale: String
    var model: AddBotPageDataModel?
    let chatID: String
    private var updateCallback: ((Error?, AddBotPageDataModel?) -> Void)?
    private let disposeBag = DisposeBag()
    private var curQuery: String?
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
    func updateRemoteItems(isSearching: Bool = false, query: String = "", updateCallback: ((Error?, AddBotPageDataModel?) -> Void)? = nil) {
        Self.logger.info("updateRemoteItems")
        self.updateCallback = updateCallback
        self.curQuery = query
        updateRemoteData(isSearching: isSearching, query: query)
    }

    private func getRequestAPI(chatID: String, isSearching: Bool = false, query: String = "") -> OpenPlatformAPI {
        if !isSearching {
            return OpenPlatformAPI.getAddBotPageDataAPI(chatID: chatID, resolver: resolver)
        }
        return OpenPlatformAPI.searchBotData(chatID: chatID, query: query, resolver: resolver)
    }
    
    private func getBotAddOrSearchReqComponents(chatID: String, isSearching: Bool = false, query: String = "") -> OPNetworkUtil.ECONetworkReqComponents? {
        var url: String? = nil
        if !isSearching {
            url = OPNetworkUtil.getAddBotPageDataURL()
        } else {
            url = OPNetworkUtil.getSearchBotDataURL()
        }
        guard let url = url else {
            Self.logger.error("get add bot page or search bot data url failed")
            return nil
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
        var params: [String: Any] = [APIParamKey.larkVersion.rawValue: Utils.appVersion,
                                     APIParamKey.chat_id.rawValue: chatID,
                                     APIParamKey.locale.rawValue: OpenPlatformAPI.curLanguage()]
        if isSearching {
            params[APIParamKey.query.rawValue] = query
        }
        let context = OpenECONetworkContext(trace: OPTraceService.default().generateTrace(), source: .other)
        return OPNetworkUtil.ECONetworkReqComponents(url: url, header: header, params: params, context: context)
    }

    /// 更新列表数据
    private func updateRemoteData(isSearching: Bool = false, query: String = "") {
        Self.logger.info("updateRemoteData")
        // monitor...
        let monitorCodeSuccess = isSearching ? EPMClientOpenPlatformGroupBotCode.search_groupbot_success : EPMClientOpenPlatformGroupBotCode.pull_groupbot_candidate_success
        let monitorCodeFail = isSearching ? EPMClientOpenPlatformGroupBotCode.search_groupbot_fail : EPMClientOpenPlatformGroupBotCode.pull_groupbot_candidate_fail
        let monitorSuccess = OPMonitor(name: GroupBotDefines.keyEvent, code: monitorCodeSuccess)
            .setResultTypeSuccess()
            .timing()
            .addCategoryValue(GroupBotDefines.keyChatID, chatID)
            .addCategoryValue(GroupBotDefines.keyQuery, query)
        let monitorFail = OPMonitor(name: GroupBotDefines.keyEvent, code: monitorCodeFail)
            .setResultTypeFail()
            .addCategoryValue(GroupBotDefines.keyChatID, chatID)
            .addCategoryValue(GroupBotDefines.keyQuery, query)
        let onSelfError: () -> Void = { 
            let errorMessage = "self missed, request exit"
            Self.logger.error(errorMessage)
        }
        let onError: (Error) -> Void = { [weak self] error in
            Self.logger.error("request data failed with backEnd-Error: \(error.localizedDescription)")
            let logID = (error as NSError).userInfo[OpenPlatformHttpClient.lobLogIDKey] as? String
            monitorFail
                .addCategoryValue(GroupBotDefines.keyRequestID, logID)
                .setError(error)
                .flush()
            DispatchQueue.main.async {
                self?.onRequestFail(err: error, query: query)
            }
        }
        let onSuccess: (APIResponse) -> Void = { [weak self] result in
            Self.logger.info("success \(result.code ?? -1)")
            guard let self = self else {
                onSelfError()
                return
            }
            let logID = result.lobLogID
            let errorDomain = "GroupBotRequest"
            if let resultCode = result.code, resultCode == 0 {
                if let dataModel = result.buildDataModel(type: AddBotPageDataModel.self) {
                    Self.logger.info("fetch data complete, parse to model success, refresh page")
                    monitorSuccess
                        .addCategoryValue(GroupBotDefines.keyRequestID, logID)
                        .timing()
                        .flush()
                    DispatchQueue.main.async {
                        self.onRequestSuccess(dataModel: dataModel, query: query)
                    }
                } else {
                    let buildDataModelFailCode = -1
                    let buildDataModelFailMessage = "fetch data complete, parse to model failed, show failed page"
                    let error = NSError(domain: errorDomain,
                                        code: buildDataModelFailCode,
                                        userInfo: [NSLocalizedDescriptionKey: buildDataModelFailMessage])
                    Self.logger.error("\(buildDataModelFailMessage)", error: error)
                    monitorFail
                        .addCategoryValue(GroupBotDefines.keyRequestID, logID)
                        .setError(error)
                        .flush()
                    DispatchQueue.main.async {
                        self.onRequestFail(err: error, query: query)
                    }
                }
            } else {
                let errCode = result.json["code"].intValue
                let errMsg = result.json["msg"].stringValue
                Self.logger.error("request data failed with errCode: \(errCode), errMsg: \(errMsg)")
                let error = NSError(domain: errorDomain,
                                    code: errCode,
                                    userInfo: [NSLocalizedDescriptionKey: errMsg])
                monitorFail
                    .addCategoryValue(GroupBotDefines.keyRequestID, logID)
                    .setError(error)
                    .flush()
                DispatchQueue.main.async {
                    self.onRequestFail(err: error, query: query)
                }
            }
        }
        
        if OPNetworkUtil.basicUseECONetworkEnabled() {
            guard let (url, header, params, context) = getBotAddOrSearchReqComponents(chatID: chatID, isSearching: isSearching, query: query) else {
                Self.logger.error("update remote data isSearching:\(isSearching) req components failed")
                return
            }
            let completionHandler: (ECOInfra.ECONetworkResponse<[String: Any]>?, ECOInfra.ECONetworkError?) -> Void = { [weak self] response, error in
                if let error = error {
                    onError(error)
                    return
                }
                guard let self = self else {
                    let error = "update remote data isSearching:\(isSearching) failed because self is nil"
                    let nsError = NSError(domain: error, code: -1, userInfo: nil)
                    onError(nsError)
                    return
                }
                let logID = OPNetworkUtil.reportLog(Self.logger, response: response)
                guard let response = response,
                      let result = response.result else {
                    let error = "update remote data isSearching:\(isSearching) failed because response or result is nil"
                    let nsError = NSError(domain: error, code: -1, userInfo: nil)
                    onError(nsError)
                    return
                }
                let json = JSON(result)
                let obj = APIResponse(json: json, api: OpenPlatformAPI(path: .empty, resolver: self.resolver))
                obj.lobLogID = logID
                onSuccess(obj)
            }
            DispatchQueue.global().async {
                let task = Self.service.post(url: url, header: header, params: params, context: context, requestCompletionHandler: completionHandler)
                if let task = task {
                    Self.service.resume(task: task)
                } else {
                    Self.logger.error("update remote data isSearching:\(isSearching) url econetwork task failed")
                }
            }
            return
        }
        
        guard let client = try? resolver.resolve(assert: OpenPlatformHttpClient.self) else {
            Self.logger.error("resolve OpenPlatformHttpClient failed,fetch data exit")
            return
        }
        let requestAPI = getRequestAPI(chatID: chatID, isSearching: isSearching, query: query)
        client.request(api: requestAPI).observeOn(ConcurrentDispatchQueueScheduler(queue: .global()))
            .subscribe(onNext: { result in
                onSuccess(result)
            }, onError: { error in
                onError(error)
            }).disposed(by: self.disposeBag)
    }

    /// 成功回调
    private func onRequestSuccess(dataModel: AddBotPageDataModel, query: String) {
        Self.logger.info("onRequestSuccess bots:\(dataModel.bots?.count ?? 0) recommendBots:\(dataModel.recommendBots?.count ?? 0)")
        if needDiscardRequest(query: query) {
            return
        }
        model = dataModel
        self.updateCallback?(nil, model)
        self.updateCallback = nil
        self.curQuery = nil
    }

    /// 失败回调
    private func onRequestFail(err: Error? = nil, query: String) {
        Self.logger.error("onRequestFail with error: \(String(describing: err))")
        if needDiscardRequest(query: query) {
            return
        }
        self.updateCallback?(err, nil)
        self.updateCallback = nil
        self.curQuery = nil
    }
    
    private func needDiscardRequest(query: String) -> Bool {
        if let curQueryStr = curQuery, curQueryStr != query {
            Self.logger.info("needDiscardRequest query \(query), curQuery \(curQueryStr)")
            return true
        }
        return false
    }

    // MARK: addBotToGroup
    func addBotToGroup(botModel: AbstractBotModel, chatID: String, completion:@escaping ((GroupBotManageLegacyResult) -> Void)) {
        Self.logger.info("addBotToGroup")
        guard let botModel = botModel as? GroupBotModel else {
            Self.logger.error("botModel is not GroupBotModel, fetch data exit")
            return
        }
        let botID = botModel.botID ?? ""
        // monitor...
        let monitorCodeSuccess = EPMClientOpenPlatformGroupBotCode.add_groupbot_success
        let monitorCodeFail = EPMClientOpenPlatformGroupBotCode.add_groupbot_fail
        let scene = "addBot"
        let monitorSuccess = OPMonitor(name: GroupBotDefines.keyEvent, code: monitorCodeSuccess)
            .setResultTypeSuccess()
            .timing()
            .addCategoryValue(GroupBotDefines.keyScene, scene)
            .addCategoryValue(GroupBotDefines.keyChatID, chatID)
            .addCategoryValue(GroupBotDefines.keyBotID, botID)
        let monitorFail = OPMonitor(name: GroupBotDefines.keyEvent, code: monitorCodeFail)
            .setResultTypeFail()
            .addCategoryValue(GroupBotDefines.keyScene, scene)
            .addCategoryValue(GroupBotDefines.keyChatID, chatID)
            .addCategoryValue(GroupBotDefines.keyBotID, botID)
        let onError: (Error) -> Void = { error in
            let msg = "request data failed with backEnd-Error: \(error.localizedDescription)"
            Self.logger.error(msg)
            let logID = (error as NSError).userInfo[OpenPlatformHttpClient.lobLogIDKey] as? String
            monitorFail.addCategoryValue(GroupBotDefines.keyRequestID, logID)
                .setError(error)
                .flush()
            DispatchQueue.main.async {
                completion(GroupBotManageLegacyResult(errorMessageToShow: nil, code: GroupBotManageLegacyResult.defaultErrorCode))
            }
        }
        let onSuccess: (APIResponse) -> Void = { result in
            let logID = result.lobLogID
            do {
                let data = try result.json.rawData()
                // 解析数据
                if let dataModel = result.buildCustomDataModel(type: GroupBotManageLegacyResult.self, data: data) {
                    // 添加成功
                    if dataModel.success {
                        Self.logger.info("fetch data complete, parse to model success, refresh page")
                        monitorSuccess
                            .addCategoryValue(GroupBotDefines.keyRequestID, logID)
                            .timing()
                            .flush()
                    } else {
                        // 添加失败
                        let errorMessage = dataModel.errorMessageToShow ?? ""
                        Self.logger.error("fetch data complete, parse to model success, but result failed: \(errorMessage)")
                        monitorFail
                            .addCategoryValue(GroupBotDefines.keyRequestID, logID)
                            .setErrorMessage(errorMessage)
                            .flush()
                    }
                    DispatchQueue.main.async {
                        let responseResult = dataModel
                        completion(responseResult)
                    }
                } else {
                    // 解析数据失败
                    let errorMessage = "fetch data complete, parse to model failed, show failed page"
                    Self.logger.error(errorMessage)
                    monitorFail
                        .addCategoryValue(GroupBotDefines.keyRequestID, logID)
                        .setErrorMessage(errorMessage)
                        .flush()
                    DispatchQueue.main.async {
                        completion(GroupBotManageLegacyResult(errorMessageToShow: nil, code: GroupBotManageLegacyResult.defaultErrorCode))
                    }
                }
            } catch {
                // try json -> rawData 失败
                let errorMessage = "fetch data failed with error(\(error))"
                Self.logger.error(errorMessage)
                monitorFail
                    .addCategoryValue(GroupBotDefines.keyRequestID, logID)
                    .setError(error)
                    .flush()
                DispatchQueue.main.async {
                    completion(GroupBotManageLegacyResult(errorMessageToShow: nil, code: GroupBotManageLegacyResult.defaultErrorCode))
                }
            }
        }
        if OPNetworkUtil.basicUseECONetworkEnabled() {
            guard let url = OPNetworkUtil.getAddBotToGroupURL() else {
                Self.logger.error("get add bot to group url failed")
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
                                         APIParamKey.bot_id.rawValue: botID,
                                         APIParamKey.i18n.rawValue: OpenPlatformAPI.curLanguage(),
                                         APIParamKey.locale.rawValue: OpenPlatformAPI.curLanguage()]
            let context = OpenECONetworkContext(trace: OPTraceService.default().generateTrace(), source: .other)
            let completionHandler: (ECOInfra.ECONetworkResponse<[String: Any]>?, ECOInfra.ECONetworkError?) -> Void = { response, error in
                if let error = error {
                    onError(error)
                    return
                }
                let logID = OPNetworkUtil.reportLog(Self.logger, response: response)
                guard let response = response,
                      let result = response.result else {
                    let error = "add bot to group failed because response or result is nil"
                    let nsError = NSError(domain: error, code: -1, userInfo: nil)
                    onError(nsError)
                    return
                }
                let json = JSON(result)
                let obj = APIResponse(json: json, api: OpenPlatformAPI(path: .empty, resolver: self.resolver))
                obj.lobLogID = logID
                onSuccess(obj)
            }
            let task = Self.service.post(url: url, header: header, params: params, context: context, requestCompletionHandler: completionHandler)
            if let task = task {
                Self.service.resume(task: task)
            } else {
                Self.logger.error("add bot to group url econetwork task failed")
            }
            return
        }
        
        guard let client = try? resolver.resolve(assert: OpenPlatformHttpClient.self) else {
            Self.logger.error("resolve OpenPlatformHttpClient failed, fetch data exit")
            return
        }
        let requestAPI = OpenPlatformAPI.addBotToGroup(botID: botID, chatID: chatID, resolver: resolver)
        client.request(api: requestAPI).observeOn(ConcurrentDispatchQueueScheduler(queue: .global()))
            .subscribe(onNext: { result in
                onSuccess(result)
            }, onError: { error in
                // 网络错误
                onError(error)
            }).disposed(by: self.disposeBag)
    }
}
