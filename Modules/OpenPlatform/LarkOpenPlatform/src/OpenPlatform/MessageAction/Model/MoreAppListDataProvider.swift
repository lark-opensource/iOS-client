//
//  MoreAppListDataProvider.swift
//  LarkOpenPlatform
//
//  Created by houjihu on 2021/5/8.
//

import Kingfisher
import LKCommonsLogging
import Swinject
import RxSwift
import RustPB
import LarkRustClient
import SwiftyJSON
import LarkExtensions
import LKCommonsTracker
import LarkAccountInterface
import LarkLocalizations
import LarkModel
import EENavigator
import LarkEnv
import LarkAppLinkSDK
import LarkCache
import LarkOPInterface
import LarkMessageBase
import LarkFoundation
import LarkContainer
import LarkSetting
import LarkStorage
import ECOInfra
import OPFoundation

/// log object for MoreAppListDataProvider
private let logger = Logger.oplog(MoreAppListDataProvider.self,
                                  category: MessageActionPlusMenuDefines.messageActionLogCategory)

/// 更多应用列表数据提供者
/// Message Action & 加号菜单 数据源：
/// 1. 外露常用应用列表：
/// 1）针对加号菜单，需要在进入群时根据有无缓存和缓存过期时间按需来提前请求数据，并刷新缓存；
/// 再打开加号面板时只使用缓存数据，避免加号菜单应用闪现问题；
/// 在进入更多应用列表页时后台强制请求一遍数据，并刷新缓存
/// 2）针对消息快捷操作，不需要提前请求，在进入更多应用列表页时即时请求即可，不需要做缓存
/// 2. 更多应用列表：在进入更多应用列表页时即时请求即可，不需要做缓存
/// 3. 用户排序应用列表后，通知后端并通知外面的加号菜单更新显示
/// 4. 接收push消息，强制请求一遍数据来刷新外露常用应用列表
class MoreAppListDataProvider {
    private let bizKey = "MoreAppListData"
    var locale: String
    var scene: BizScene
    private let disposeBag = DisposeBag()

    var allItemListModel: MoreAppAllItemListModel?
    var externalItemListModel: MoreAppExternalItemListModel?

    /// 上次发起请求的时间戳
    private var lastRequestTimestamp: Int64 = 0
    /// 上次更新的时间戳
    private var lastUpdateInterval: Int64 {
        /// 如果没有更新时间戳就以上次请求的时间戳为准
        return max(Int64(externalItemListModel?.localUpdateTS ?? 0), lastRequestTimestamp)
    }
    private var minUpdateInterval: Int64 {
        var minUpdateInterval: Int64 = 24 * 3600
        // 加号菜单只有在进入会话时用cacheExpireTime（1d）判断缓存过期时间，其他场景（点击加号按钮和essage Action）都强制拉数据。
        if let time = externalItemListModel?.cacheExpireTime {
            minUpdateInterval = Int64(time)
        }
        return minUpdateInterval
    }
    private var httpClient: OpenPlatformHttpClient {
        Injected<OpenPlatformHttpClient>().wrappedValue
    }
    private let store: KVStore
    private let resolver: UserResolver

    /// push observer
    var pushObserver: AnyObject?
    
    private static var service: ECONetworkService {
        return Injected<ECONetworkService>().wrappedValue
    }

    /// 初始化方法
    /// - Parameters:
    ///   - locale: 当前国际化标识
    ///   - scene: 业务场景
    init(resolver: UserResolver, locale: String, scene: BizScene) {
        self.resolver = resolver
        self.locale = locale
        self.scene = scene
        store = KVStores.in(space: .global, domain: Domain.biz.microApp).udkv()
        let cacheDataKey = getCacheKey()
        self.externalItemListModel = loadExternalModelFromCache(key: cacheDataKey)
        self.externalItemListModel?.cacheKey = cacheDataKey
        logger.info("MoreAppListDataProvider init with scene \(scene)")
    }
}

/// local cache logic
extension MoreAppListDataProvider {
    /// online/staging等App环境
    private func getCurrentEnvType() -> String {
        return EnvManager.env.description
    }

    /// 缓存数据的key，分用户+语言+App环境+场景等维度
    private func getCacheKey() -> String {
        let userKey: String = resolver.userID
        return userKey
            + "_" + locale
            + "_" + "\(getCurrentEnvType())_"
            + "\(scene)_"
            + "message_action_more_app_list_cache"
    }

    /// App Version Cache Key
    private func appVersionCacheKey() -> String {
        return "\(self.bizKey).\(self.scene).\(#function)"
    }

    /// 是否是App升级或者第一次安装
    private func isAppNewInstalled() -> Bool {
        guard let appVersionData: Data = OPRequestCache().object(forKey: appVersionCacheKey()),
              let recordAppVersion = String(data: appVersionData, encoding: .utf8),
              recordAppVersion == Utils.appVersion else {
            if let currentAppVersionData = Utils.appVersion.data(using: .utf8) {
                OPRequestCache().set(object: currentAppVersionData,
                                     forKey: appVersionCacheKey())
            }
            return true
        }
        return false
    }

    /// 列表请求间隔控制
    private func shouldUpdateThisTime() -> Bool {
        let now = Date().timeIntervalSince1970
        logger.info("check update lastUpdateInterval:\(lastUpdateInterval) minUpdateInterval:\(minUpdateInterval)")
        return (
            Double(lastUpdateInterval + minUpdateInterval) < now
                || lastUpdateInterval < 1
                || isAppNewInstalled()
        )
    }

    ///从本地缓存加载+号面板的小程序入口信息
    private func loadExternalModelFromCache(key: String?) -> MoreAppExternalItemListModel? {
        let cacheLanguage: String? = store.value(forKey: "\(getCacheKey())_language")
        guard let cacheLanguage = cacheLanguage, cacheLanguage == LanguageManager.currentLanguage.localeIdentifier else {
            logger.info("MoreAppListDataProvider loadModelFromCache return nil, language not cache")
            return nil
        }
        if let data: Data = OPRequestCache().object(forKey: getCacheKey()),
            let model = try? JSONDecoder().decode(MoreAppExternalItemListModel.self, from: data) {
            return model
        }
        logger.info("MoreAppListDataProvider loadModelFromCache return nil")
        return nil
    }

    /// 保存缓存
    private func saveExternalModelToCache() {
        if let data = try? JSONEncoder().encode(externalItemListModel) {
            OPRequestCache().set(object: data, forKey: getCacheKey())
            let cacheLanguage = LanguageManager.currentLanguage.localeIdentifier
            store.set(cacheLanguage, forKey: "\(getCacheKey())_language")
            logger.info("MoreAppListDataProvider set cache")
            return
        }
        logger.warn("MoreAppListDataProvider set cache can not encode model")
    }

    /// check cache is for current user
    private func checkAndUpdateCacheModel() {
        let currentUserCacheKey = getCacheKey()
        if externalItemListModel?.cacheKey != currentUserCacheKey {
            externalItemListModel = loadExternalModelFromCache(key: currentUserCacheKey)
            externalItemListModel?.cacheKey = currentUserCacheKey
            logger.info("update cache old key \(externalItemListModel?.cacheKey ?? "empty") to \(currentUserCacheKey)")
        }
    }
}

/// network request for external item list
extension MoreAppListDataProvider {
    /// 尝试更新缓存
    func updateRemoteExternalItemListIfNeed(
        forceUpdate: Bool = false,
        shouldUpdateBlock: ((Bool) -> Void)? = nil,
        updateCallback: ((Error?, MoreAppExternalItemListModel?) -> Void)? = nil
    ) {
        logger.info("MoreAppListDataProvider updateRemoteItemListIfNeed \(forceUpdate)")
        var shouldUpdate = false
        if (externalItemListModel == nil) || forceUpdate {
            shouldUpdate = true
            /// 记录请求的时间戳，主要是考虑第一次model为空以及请求失败的时候无法记录更新时间戳的场景
            lastRequestTimestamp = Int64(Date().timeIntervalSince1970)
            logger.info("MoreAppListDataProvider updateRemoteData")
            updateRemoteExternalData(updateCallback: updateCallback)
        }
        shouldUpdateBlock?(shouldUpdate)
    }

    /// 重新刷新缓存
    func updateLocalExternalItemList(updateCallback: ((MoreAppExternalItemListModel?) -> Void)) {
        logger.info("MoreAppListDataProvider updateLocalExternalItemList")
        let cacheDataKey = getCacheKey()
        externalItemListModel = loadExternalModelFromCache(key: cacheDataKey)
        externalItemListModel?.cacheKey = cacheDataKey
        updateCallback(externalItemListModel)
    }

    /// 获取请求更多应用列表的接口
    private func getExternalAppListRequestAPI() -> OpenPlatformAPI {
        switch self.scene {
        case .addMenu:
            return OpenPlatformAPI.getPlusMenuExternalItemsAPI(resolver: resolver)
        case .msgAction:
            return OpenPlatformAPI.getMsgActionExternalItemsAPI(resolver: resolver)
        }
    }
    
    private func getExternalAppListReqComponents() -> OPNetworkUtil.ECONetworkReqComponents? {
        var url: String? = nil
        if scene == .addMenu {
            url = OPNetworkUtil.getPlusMenuExternalItemsURL()
        } else if scene == .msgAction {
            url = OPNetworkUtil.getMsgActionExternalItemsURL()
        }
        guard let reqURL = url else {
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
        let params: [String: Any] = [APIParamKey.larkVersion.rawValue: Utils.appVersion,
                                     APIParamKey.locale.rawValue: OpenPlatformAPI.curLanguage()]
        let context = OpenECONetworkContext(trace: OPTraceService.default().generateTrace(), source: .other)
        return OPNetworkUtil.ECONetworkReqComponents(url: reqURL, header: header, params: params, context: context)
    }

    /// 更新远端的列表数据
    private func updateRemoteExternalData(updateCallback: ((Error?, MoreAppExternalItemListModel?) -> Void)? = nil) {
        logger.info("MoreAppListDataProvider updateRemoteData")
        let errorDomain = "OpenPlatformAPI.RequestRemote.\(scene)"
        var monitorSuccessCode: OPMonitorCodeBase
        var monitorFailCode: OPMonitorCodeBase
        switch self.scene {
        case .addMenu:
            monitorSuccessCode = EPMClientOpenPlatformMessageactionPlusmenuAppPlusMenuCode.external_apps_request_data_success
            monitorFailCode = EPMClientOpenPlatformMessageactionPlusmenuAppPlusMenuCode.external_apps_request_data_fail
        case .msgAction:
            monitorSuccessCode = EPMClientOpenPlatformMessageactionPlusmenuAppMsgActionCode.external_apps_request_data_success
            monitorFailCode = EPMClientOpenPlatformMessageactionPlusmenuAppMsgActionCode.external_apps_request_data_fail
        }
        let monitorSuccess = OPMonitor(monitorSuccessCode).setResultTypeSuccess().timing()
        let monitorFail = OPMonitor(monitorFailCode).setResultTypeFail()
        
        let onSelfError: (String?) -> Void = { logID in
            let errorMessage = "MoreAppListDataProvider's self missed, request exit"
            logger.error(errorMessage)
            monitorFail.addCategoryValue(MessageActionPlusMenuDefines.monitorKeyRequestID, logID ?? "")
                .setErrorMessage(errorMessage)
                .flush()
        }
        let onError: (Error) -> Void = { [weak self] error in
            logger.error("request guideIndex list failed with backEnd-Error: \(error.localizedDescription)")
            let logID = (error as NSError).userInfo[OpenPlatformHttpClient.lobLogIDKey] as? String
            DispatchQueue.main.async {
                self?.onRequestExternalDataFail(err: error, logID: logID, updateCallback: updateCallback)
            }
            monitorFail.addCategoryValue(MessageActionPlusMenuDefines.monitorKeyRequestID, logID)
                .setError(error)
                .flush()
        }
        let onSuccess: (APIResponse) -> Void = { [weak self] result in
            logger.info("MoreAppListDataProvider success \(result.code ?? -1)")
            let logID = result.lobLogID
            guard let self = self else {
                onSelfError(logID)
                return
            }
            if let resultCode = result.code, resultCode == 0 {
                if let dataModel = result.buildDataModel(type: MoreAppExternalItemListModel.self) {
                    logger.info("fetch data complete, parse to model success, refresh page")
                    DispatchQueue.main.async {
                        self.onRequestExternalDataSuccess(dataModel: dataModel, logID: result.lobLogID, updateCallback: updateCallback)
                    }
                    monitorSuccess.addCategoryValue(MessageActionPlusMenuDefines.monitorKeyRequestID, logID)
                        .timing()
                        .flush()
                } else {
                    let buildDataModelFailCode = -1
                    let buildDataModelFailMessage = "fetch data complete, parse to model failed, show failed page"
                    let error = NSError(domain: errorDomain,
                                        code: buildDataModelFailCode,
                                        userInfo: [NSLocalizedDescriptionKey: buildDataModelFailMessage])
                    logger.error("\(buildDataModelFailMessage)", error: error)
                    DispatchQueue.main.async {
                        self.onRequestExternalDataFail(updateCallback: updateCallback)
                    }
                    monitorFail.addCategoryValue(MessageActionPlusMenuDefines.monitorKeyRequestID, logID)
                        .setError(error)
                        .flush()
                }
            } else {
                let errCode = result.json["code"].intValue
                let errMsg = result.json["msg"].stringValue
                logger.error("request guideIndex list failed with errCode: \(errCode), errMsg: \(errMsg)")
                let error = NSError(domain: errorDomain,
                                    code: errCode,
                                    userInfo: [NSLocalizedDescriptionKey: errMsg])
                DispatchQueue.main.async {
                    self.onRequestExternalDataFail(err: error, logID: result.lobLogID, updateCallback: updateCallback)
                }
                monitorFail.addCategoryValue(MessageActionPlusMenuDefines.monitorKeyRequestID, logID)
                    .setError(error)
                    .flush()
            }
        }
        
        if OPNetworkUtil.basicUseECONetworkEnabled() {
            guard let (url, header, params, context) = getExternalAppListReqComponents() else {
                logger.error("MoreAppListDataProvider get external app list req components failed")
                return
            }
            let completionHandler: (ECOInfra.ECONetworkResponse<[String: Any]>?, ECOInfra.ECONetworkError?) -> Void = { [weak self] response, error in
                if let error = error {
                    onError(error)
                    return
                }
                guard let self = self else {
                    let error = "MoreAppListDataProvider external app list failed because self is nil"
                    let nsError = NSError(domain: error, code: -1, userInfo: nil)
                    onError(nsError)
                    return
                }
                guard let response = response,
                      let result = response.result else {
                    let error = "MoreAppListDataProvider external app list failed because response or result is nil"
                    let nsError = NSError(domain: error, code: -1, userInfo: nil)
                    onError(nsError)
                    return
                }
                let json = JSON(result)
                let obj = APIResponse(json: json, api: OpenPlatformAPI(path: .empty, resolver: self.resolver))
                let logID = OPNetworkUtil.reportLog(logger, response: response)
                obj.lobLogID = logID
                onSuccess(obj)
            }
            let task = Self.service.post(url: url, header: header, params: params, context: context, requestCompletionHandler: completionHandler)
            if let task = task {
                Self.service.resume(task: task)
            } else {
                logger.error("MoreAppListDataProvider external app list url econetwork task failed")
            }
            return
        }
        
        let requestAPI = getExternalAppListRequestAPI()
        httpClient.request(api: requestAPI).observeOn(ConcurrentDispatchQueueScheduler(queue: .global()))
            .subscribe(onNext: { (result) in
                onSuccess(result)
            }, onError: { (error) in
                onError(error)
            }).disposed(by: self.disposeBag)
    }

    /// 更新远端的列表数据 成功毁掉回调
    private func onRequestExternalDataSuccess(
        dataModel: MoreAppExternalItemListModel,
        logID: String?,
        updateCallback: ((Error?, MoreAppExternalItemListModel?) -> Void)? = nil
    ) {
        logger.info("MoreAppListDataProvider onRequestSuccess")
        // 缓存外露常用应用列表
        updateExternalItemListModel(dataModel)
        updateCallback?(nil, externalItemListModel)
    }

    /// 更新外露常用应用列表及其缓存
    private func updateExternalItemListModel(_ dataModel: MoreAppExternalItemListModel) {
        externalItemListModel = dataModel
        externalItemListModel?.localUpdateTS = Int64(Date().timeIntervalSince1970)
        externalItemListModel?.cacheKey = getCacheKey()
        saveExternalModelToCache()
    }

    /// 更新远端的列表数据 成功失败回调
    private func onRequestExternalDataFail(
        err: Error? = nil,
        logID: String? = nil,
        updateCallback: ((Error?, MoreAppExternalItemListModel?) -> Void)? = nil
    ) {
        logger.error("MoreAppListDataProvider onRequestFail",
                     tag: "MoreAppListDataProvider",
                     additionalData: nil,
                     error: err)
        updateCallback?(err, nil)
    }

    /// +号面板需要展示的数据
    public func keyBoardDisplayApps(type: Chat.TypeEnum, dataUpdateBlock: @escaping (() -> Void)) -> [KeyboardApp] {
        checkAndUpdateCacheModel()
        var result: [KeyboardApp] = []
        var sourceList: [MoreAppItemModel]? = []
        // 加号菜单支持外化开关控制，不再全部展示所有应用：
        // 1. 当开关打开时只展示部分推荐应用
        // 2. 当开关关闭时不展示推荐应用
        if let externalItemList = externalItemListModel?.externalItemList {
            // 显示加号菜单时，过滤掉只能在PC端展示的应用
            for item in externalItemList {
                if item.mobileAvailable == true {
                    sourceList?.append(item)
                }
            }
        } else {
            sourceList = nil
        }
        for item in sourceList ?? [] {
            result.append(KeyboardApp(appModel: item, dataUpdateBlock: dataUpdateBlock))
        }
        return result
    }
}

/// network request for all item list
extension MoreAppListDataProvider {
    /// 尝试更新缓存
    func updateRemoteAllItemList(
        updateCallback: ((Error?, MoreAppAllItemListModel?) -> Void)? = nil
    ) {
        logger.info("MoreAppListDataProvider updateRemoteAllItemList")
        updateRemoteAllData(updateCallback: updateCallback)
    }

    /// 更新远端的列表数据
    private func updateRemoteAllData(updateCallback: ((Error?, MoreAppAllItemListModel?) -> Void)?) {
        logger.info("MoreAppListDataProvider updateRemoteData")
        let errorDomain = "OpenPlatformAPI.RequestRemote.\(scene)"
        var monitorSuccessCodeExternal: OPMonitorCodeBase
        var monitorFailCodeExternal: OPMonitorCodeBase
        switch self.scene {
        case .addMenu:
            monitorSuccessCodeExternal = EPMClientOpenPlatformMessageactionPlusmenuAppPlusMenuCode.external_apps_request_data_success
            monitorFailCodeExternal = EPMClientOpenPlatformMessageactionPlusmenuAppPlusMenuCode.external_apps_request_data_fail
        case .msgAction:
            monitorSuccessCodeExternal = EPMClientOpenPlatformMessageactionPlusmenuAppMsgActionCode.external_apps_request_data_success
            monitorFailCodeExternal = EPMClientOpenPlatformMessageactionPlusmenuAppMsgActionCode.external_apps_request_data_fail
        }
        let monitorSuccessExternal = OPMonitor(monitorSuccessCodeExternal).setResultTypeSuccess().timing()
        let monitorFailExternal = OPMonitor(monitorFailCodeExternal).setResultTypeFail()
        var monitorSuccessCodeMore: OPMonitorCodeBase
        var monitorFailCodeMore: OPMonitorCodeBase
        switch self.scene {
        case .addMenu:
            monitorSuccessCodeMore = EPMClientOpenPlatformMessageactionPlusmenuAppPlusMenuCode.more_apps_request_data_success
            monitorFailCodeMore = EPMClientOpenPlatformMessageactionPlusmenuAppPlusMenuCode.more_apps_request_data_fail
        case .msgAction:
            monitorSuccessCodeMore = EPMClientOpenPlatformMessageactionPlusmenuAppMsgActionCode.more_apps_request_data_success
            monitorFailCodeMore = EPMClientOpenPlatformMessageactionPlusmenuAppMsgActionCode.more_apps_request_data_fail
        }
        let monitorSuccessMore = OPMonitor(monitorSuccessCodeMore).setResultTypeSuccess().timing()
        let monitorFailMore = OPMonitor(monitorFailCodeMore).setResultTypeFail()
        
        var externalRequest: Observable<APIResponse>
        var moreRequest: Observable<APIResponse>
        if OPNetworkUtil.basicUseECONetworkEnabled() {
            externalRequest = getAppListRequest(external: true)
            moreRequest = getAppListRequest(external: false)
        } else {
            externalRequest = httpClient.request(api: getExternalAppListRequestAPI())
            moreRequest = httpClient.request(api: getAvailableAppListRequestAPI())
        }
        Observable
            .zip(externalRequest, moreRequest)
            .observeOn(ConcurrentDispatchQueueScheduler(queue: .global()))
            .subscribe(onNext: { [weak self] (externalResult, availableResult) in
                logger.info("MoreAppListDataProvider result code: externalResult \(externalResult.code ?? -1), moreResult \(availableResult.code ?? -1)")
                guard let `self` = self else {
                    let errorMessage = "MoreAppListDataProvider's self missed, request exit"
                    logger.error(errorMessage)
                    return
                }
                let logIDExternal = externalResult.lobLogID
                let logIDMore = availableResult.lobLogID
                if let externalResultCode = externalResult.code, externalResultCode == 0,
                   let availableResultCode = availableResult.code, availableResultCode == 0 {
                    if let externalDataModel = externalResult.buildDataModel(type: MoreAppExternalItemListModel.self),
                       let availableDataModel = availableResult.buildDataModel(type: MoreAppAvailableItemListModel.self) {
                        logger.info("fetch data complete, parse to model success, refresh page")
                        DispatchQueue.main.async {
                            let allDataModel = MoreAppAllItemListModel(externalItemListModel: externalDataModel, availableItemListModel: availableDataModel)
                            self.onRequestAllDataSuccess(dataModel: allDataModel, updateCallback: updateCallback)
                        }
                        monitorSuccessExternal
                            .addCategoryValue(MessageActionPlusMenuDefines.monitorKeyRequestID, logIDExternal)
                            .timing()
                            .flush()
                        monitorSuccessMore
                            .addCategoryValue(MessageActionPlusMenuDefines.monitorKeyRequestID, logIDMore)
                            .timing()
                            .flush()
                    } else {
                        let buildDataModelFailCode = -1
                        let buildDataModelFailMessage = "fetch data complete, parse to model failed, show failed page"
                        let error = NSError(domain: errorDomain,
                                            code: buildDataModelFailCode,
                                            userInfo: [NSLocalizedDescriptionKey: buildDataModelFailMessage])
                        logger.error("\(buildDataModelFailMessage)", error: error)
                        DispatchQueue.main.async {
                            self.onRequestAllDataFail(updateCallback: updateCallback)
                        }
                        monitorFailExternal
                            .addCategoryValue(MessageActionPlusMenuDefines.monitorKeyRequestID, logIDExternal)
                            .setError(error)
                            .flush()
                        monitorFailMore
                            .addCategoryValue(MessageActionPlusMenuDefines.monitorKeyRequestID, logIDMore)
                            .setError(error)
                            .flush()
                    }
                } else {
                    var errCode = externalResult.json["code"].intValue
                    var errMsg = externalResult.json["msg"].stringValue
                    if errCode == 0 {
                        errCode = availableResult.json["code"].intValue
                        errMsg = availableResult.json["msg"].stringValue
                    }
                    logger.error("request all list failed with errCode: \(errCode), errMsg: \(errMsg)")
                    let error = NSError(domain: errorDomain,
                                        code: errCode,
                                        userInfo: [NSLocalizedDescriptionKey: errMsg])
                    DispatchQueue.main.async {
                        self.onRequestAllDataFail(err: error, logID: externalResult.lobLogID, updateCallback: updateCallback)
                    }
                    monitorFailExternal
                        .addCategoryValue(MessageActionPlusMenuDefines.monitorKeyRequestID, logIDExternal)
                        .setError(error)
                        .flush()
                    monitorFailMore
                        .addCategoryValue(MessageActionPlusMenuDefines.monitorKeyRequestID, logIDMore)
                        .setError(error)
                        .flush()
                }
            }, onError: { (error) in
                logger.error("request all list failed with Backend error: \(error.localizedDescription)")
                let logID = (error as NSError).userInfo[OpenPlatformHttpClient.lobLogIDKey] as? String
                DispatchQueue.main.async {
                    self.onRequestAllDataFail(err: error, logID: logID, updateCallback: updateCallback)
                }
                monitorFailExternal
                    .addCategoryValue(MessageActionPlusMenuDefines.monitorKeyRequestID, logID)
                    .setError(error)
                    .flush()
                monitorFailMore
                    .addCategoryValue(MessageActionPlusMenuDefines.monitorKeyRequestID, logID)
                    .setError(error)
                    .flush()
            }).disposed(by: self.disposeBag)
    }
    
    private func getAppListRequest<R>(external: Bool) -> Observable<R> where R: APIResponse {
        var components: OPNetworkUtil.ECONetworkReqComponents? = external ? getExternalAppListReqComponents() : getAvailableAppListReqComponents()
        return Observable<R>.create { (ob) -> Disposable in
            if let components = components {
                let task = Self.service.post(url: components.url, header: components.header, params: components.params, context: components.context) { [weak self] response, error in
                    if let error = error {
                        ob.onError(error)
                        return
                    }
                    guard let self = self else {
                        let selfErrorMsg = "externalAppListRequest failed because self is nil"
                        let nsError = NSError(domain: selfErrorMsg, code: -1, userInfo: nil)
                        ob.onError(nsError)
                        return
                    }
                    guard let response = response,
                          let result = response.result else {
                        let invalidMsg = "shareHandler share app info failed because response or result is nil"
                        let nsError = NSError(domain: invalidMsg, code: -1, userInfo: nil)
                        ob.onError(nsError)
                        return
                    }
                    let json = JSON(result)
                    let obj = R(json: json, api: OpenPlatformAPI(path: .empty, resolver: self.resolver))
                    let logID = OPNetworkUtil.reportLog(logger, response: response)
                    obj.lobLogID = logID
                    ob.onNext(obj)
                    ob.onCompleted()
                }
                if let task = task {
                    Self.service.resume(task: task)
                } else {
                    let error = "externalAppListRequest url econetwork task failed"
                    logger.error(error)
                    let nsError = NSError(domain: error, code: -1, userInfo: nil)
                    ob.onError(nsError)
                }
            } else {
                ob.onError(RxError.unknown)
            }
            return Disposables.create {}
        }
    }

    /// 更新远端的列表数据 成功毁掉回调
    private func onRequestAllDataSuccess(dataModel: MoreAppAllItemListModel, updateCallback: ((Error?, MoreAppAllItemListModel?) -> Void)?) {
        logger.info("MoreAppListDataProvider onRequestSuccess")
        allItemListModel = dataModel
        // 缓存外露常用应用列表
        updateExternalItemListModel(dataModel.externalItemListModel)
        updateCallback?(nil, allItemListModel)
    }

    /// 更新远端的列表数据 成功失败回调
    private func onRequestAllDataFail(err: Error? = nil, logID: String? = nil, updateCallback: ((Error?, MoreAppAllItemListModel?) -> Void)?) {
        logger.error("MoreAppListDataProvider onRequestFail",
                     tag: "MoreAppListDataProvider",
                     additionalData: nil,
                     error: err)
        updateCallback?(err, nil)
    }

    /// 获取请求更多应用列表的接口
    private func getAvailableAppListRequestAPI() -> OpenPlatformAPI {
        switch self.scene {
        case .addMenu:
            return OpenPlatformAPI.getPlusMenuListV1API(resolver: resolver)
        case .msgAction:
            return OpenPlatformAPI.getMsgActionListV1API(resolver: resolver)
        }
    }
    
    private func getAvailableAppListReqComponents() -> OPNetworkUtil.ECONetworkReqComponents? {
        var url: String? = nil
        if scene == .addMenu {
            url = OPNetworkUtil.getPlusMenuListV1URL()
        } else if scene == .msgAction {
            url = OPNetworkUtil.getMsgActionListV1URL()
        }
        guard let reqURL = url else {
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
        let params: [String: Any] = [APIParamKey.larkVersion.rawValue: Utils.appVersion,
                                     APIParamKey.locale.rawValue: OpenPlatformAPI.curLanguage()]
        let context = OpenECONetworkContext(trace: OPTraceService.default().generateTrace(), source: .other)
        return OPNetworkUtil.ECONetworkReqComponents(url: reqURL, header: header, params: params, context: context)
    }
}

/// 更新用户常用配置
extension MoreAppListDataProvider {
    /// 更新用户常用配置
    func updateLocalExternalItemListToRemote(
        bizScene: BizScene,
        appIDs: [String],
        responseCallback: ((_ isSuccess: Bool, _ error: Error?) -> Void)?
    ) {
        logger.info("MoreAppListDataProvider updateRemoteData")
        var scene = ""
        switch bizScene {
        case .addMenu:
            scene = "plus_menu"
        case .msgAction:
            scene = "msg_action"
        }
        let errorDomain = "OpenPlatformAPI.RequestRemote.\(scene)"
        var monitorSuccessCode: OPMonitorCodeBase
        var monitorFailCode: OPMonitorCodeBase
        switch self.scene {
        case .addMenu:
            monitorSuccessCode = EPMClientOpenPlatformMessageactionPlusmenuAppPlusMenuCode.update_config_success
            monitorFailCode = EPMClientOpenPlatformMessageactionPlusmenuAppPlusMenuCode.update_config_fail
        case .msgAction:
            monitorSuccessCode = EPMClientOpenPlatformMessageactionPlusmenuAppMsgActionCode.update_config_success
            monitorFailCode = EPMClientOpenPlatformMessageactionPlusmenuAppMsgActionCode.update_config_fail
        }
        let monitorSuccess = OPMonitor(monitorSuccessCode).setResultTypeSuccess().timing()
        let monitorFail = OPMonitor(monitorFailCode).setResultTypeFail()
        
        let onError: (Error) -> Void = { error in
            logger.error("updateLocalExternalItemListToRemote failed with backEnd-Error: \(error.localizedDescription)")
            let logID = (error as NSError).userInfo[OpenPlatformHttpClient.lobLogIDKey] as? String
            DispatchQueue.main.async {
                responseCallback?(false, error)
            }
            monitorFail.addCategoryValue(MessageActionPlusMenuDefines.monitorKeyRequestID, logID)
                .setError(error)
                .flush()
        }
        let onSuccess: (APIResponse) -> Void = { result in
            logger.info("MoreAppListDataProvider success \(result.code ?? -1)")
            let logID = result.lobLogID
            if let resultCode = result.code, resultCode == 0 {
                logger.info("fetch data complete, parse to model success, refresh page")
                DispatchQueue.main.async {
                    responseCallback?(true, nil)
                }
                monitorSuccess.addCategoryValue(MessageActionPlusMenuDefines.monitorKeyRequestID, logID)
                    .timing()
                    .flush()
            } else {
                let errCode = result.json["code"].intValue
                let errMsg = result.json["msg"].stringValue
                logger.error("updateLocalExternalItemListToRemote failed with errCode: \(errCode), errMsg: \(errMsg)")
                let error = NSError(domain: errorDomain,
                                    code: errCode,
                                    userInfo: [NSLocalizedDescriptionKey: errMsg])
                DispatchQueue.main.async {
                    responseCallback?(false, error)
                }
                monitorFail.addCategoryValue(MessageActionPlusMenuDefines.monitorKeyRequestID, logID)
                    .setError(error)
                    .flush()
            }
        }
        
        if OPNetworkUtil.basicUseECONetworkEnabled() {
            guard let url = OPNetworkUtil.getUpdateUserCommonAppsURL() else {
                logger.error("updateLocalExternalItemListToRemote get update user common apps url failed")
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
                                         APIParamKey.scene.rawValue: scene,
                                         APIParamKey.common_app_ids.rawValue: appIDs,
                                         APIParamKey.locale.rawValue:  OpenPlatformAPI.curLanguage()]
            let context = OpenECONetworkContext(trace: OPTraceService.default().generateTrace(), source: .other)
            let completionHandler: (ECOInfra.ECONetworkResponse<[String: Any]>?, ECOInfra.ECONetworkError?) -> Void = { response, error in
                if let error = error {
                    onError(error)
                    return
                }
                guard let response = response,
                      let result = response.result else {
                    let error = "updateLocalExternalItemListToRemote update user common apps failed because response or result is nil"
                    let nsError = NSError(domain: error, code: -1, userInfo: nil)
                    onError(nsError)
                    return
                }
                let json = JSON(result)
                let obj = APIResponse(json: json, api: OpenPlatformAPI(path: .empty, resolver: self.resolver))
                let logID = OPNetworkUtil.reportLog(logger, response: response)
                obj.lobLogID = logID
                onSuccess(obj)
            }
            let task = Self.service.post(url: url, header: header, params: params, context: context, requestCompletionHandler: completionHandler)
            if let task = task {
                Self.service.resume(task: task)
            } else {
                logger.error("updateLocalExternalItemListToRemote update user common apps url econetwork task failed")
            }
            return
        }
        
        let requestAPI = OpenPlatformAPI.updateUserCommonItemsAPI(bizScene: scene, appIDs: appIDs, resolver: resolver)
        httpClient.request(api: requestAPI).observeOn(ConcurrentDispatchQueueScheduler(queue: .global()))
            .subscribe(onNext: { result in
                onSuccess(result)
            }, onError: { (error) in
                onError(error)
            }).disposed(by: self.disposeBag)
    }
}

/// 监听push更新事件
extension MoreAppListDataProvider {
    /// 注册gadget push，提取data push的数据，然后更新加号菜单应用数据
    func observeGadgetPush(updateCallback: ((Error?, MoreAppExternalItemListModel?) -> Void)? = nil) {
        logger.info("MoreAppListDataProvider observeGadgetPush")
        removeObserveGadgetPush()
        let AppCenterNotificationGadgetPush = "gadget.common.push"
        pushObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name(rawValue: AppCenterNotificationGadgetPush),
            object: nil,
            queue: OperationQueue.main,
            using: { [weak self] (notification) in
                guard let self = self else {
                    logger.info("MoreAppListDataProvider received push message, but self released")
                    return
                }
                /// 数据处理
                logger.info("MoreAppListDataProvider received push message")
                if let message = notification.userInfo?["message"]
                    as? RustPB.Openplatform_V1_CommonGadgetPushRequest {
                    logger.info("MoreAppListDataProvider received push message biz \(message.biz)")
                    if message.biz == "app_explore_user_common_apps" {
                        self.handleMsgActionPushData(message: message, updateCallback: updateCallback)
                    }
                }
            }
        )
    }

    /// 处理data push
    func handleMsgActionPushData(message: RustPB.Openplatform_V1_CommonGadgetPushRequest, updateCallback: ((Error?, MoreAppExternalItemListModel?) -> Void)? = nil) {
        logger.info("MoreAppListDataProvider handleMsgActionPushData")
        let pushJson = JSON(parseJSON: message.data)
        let scene = pushJson.dictionaryValue["scene"]?.string
        if let scene = scene {
            if scene == "plus_menu" {
                if self.scene == .addMenu {
                    // 针对加号场景，提前更新数据、缓存到磁盘并在下次打开加号菜单时展示，但不立即刷新加号菜单和导索页
                    updateRemoteExternalItemListIfNeed(forceUpdate: true, updateCallback: updateCallback)
                    OPMonitor(EPMClientOpenPlatformMessageactionPlusmenuAppPlusMenuCode.receive_push).flush()
                }
            } else if scene == "msg_action" {
                // 针对message action场景，不需要提前加载
            }
        }
    }

    func removeObserveGadgetPush() {
        if let _pushObserver = pushObserver {
            logger.info("MoreAppListDataProvider removeObserveGadgetPush \(_pushObserver)")
            NotificationCenter.default.removeObserver(_pushObserver)
            pushObserver = nil
        }
    }
}

extension MoreAppListDataProvider {
    /// onboarding显示状态
    var cacheKeyForBoarding: String {
        return "\(scene)" + "_message_action_cache_onboarding"
    }
    /// 是否显示过onboarding
    var hasShownBoardingStatus: Bool {
        let result: Bool? = store.value(forKey: cacheKeyForBoarding)
        logger.info("hasShownBoardingStatus status: \(result)")
        return result ?? false
    }
    /// 保存显示过onboarding的状态
    func saveHasShownBoardingStatus() {
        logger.info("saveHasShownBoardingStatus")
        store.set(true, forKey: cacheKeyForBoarding)
    }
}
