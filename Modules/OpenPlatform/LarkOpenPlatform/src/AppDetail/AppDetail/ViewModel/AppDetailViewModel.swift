//
//  AppDetailViewModel.swift
//  LarkAppCenter
//
//  Created by yuanping on 2019/4/17.
//

import EENavigator
import LKCommonsLogging
import LarkExtensions
import LarkOPInterface
import LarkRustClient
import LarkSetting
import RxSwift
import SwiftyJSON
import Swinject
import LarkUIKit
import EEMicroAppSDK
import WebBrowser
import RoundedHUD
import LarkAlertController
import ECOInfra
import LarkFeatureGating
import Foundation
import LarkContainer
import UniverseDesignToast
import ECOProbe
import LarkLocalizations
import LarkFoundation
import LarkAccountInterface

/// 群机器人额外信息key-机器人类型
let groupBotExtraInfoKeyBotType = "bot_type"

/// 反馈入口类型   https://bytedance.feishu.cn/docx/doxcnH6X7SKozq4VsWhWmgqHHJm
enum ProfileFeedbackType {
    // 不展示入口
    case none
    // 展示小程序入口（参数是小程序的applink
    case miniApp(String)
}

enum AppType: Int {
    case gadget = 1
    case h5 = 2
    case bot = 8
}

enum ReceiveMessageType: Int {
    case noShow = -1           //未获取到数据，不展示
    case receiveMessage = 0    //正常接收消息
    case muted = 1             //被降噪
}

/// 应用详情(Profile)页面的数据模型
class AppDetailViewModel {

    static let logger = Logger.log(AppDetailViewModel.self, category: "AppDetailViewModel")
    
    static let defaultErrCode: Int = -1

    /// 应用类型对应的Int值，具体含义参考AppDetailInfo数据结构
    let h5 = 2
    let gadget = 1
    let bot = 8

    struct Const {
        let resolver: UserResolver
        let NormalCellH: CGFloat = 55 // 普通cell高度
        let MultCellH: CGFloat = 75 // 多行信息的时候cell高度
        let SplitLineH: CGFloat = 8 // 特殊的分割线高度
        let UnreviewH: CGFloat = 70 // 没有评分的高度
        let ReviewedH: CGFloat = 78 // 已经评分的高度
        lazy var Report: String = {
            guard let dependency = AppDetailUtils(resolver: resolver).internalDependency else {
                AppDetailViewModel.logger.error("const.report AppDetailInternalDependency is nil")
                return ""
            }
            let reportDomain = dependency.host(for: .suiteReport)
            let reportUrl = "https://\(reportDomain)/report/"
            return reportUrl
        }()
    }

    private let disposeBag = DisposeBag()
    var const: Const
    private let appId: String
    private let botId: String
    private let fileCacheManager: LarkOPFileCacheManager?
    private var appReviewManager: AppReviewService
    
    private var httpClient: OpenPlatformHttpClient
    private static var service: ECONetworkService {
        return Injected<ECONetworkService>().wrappedValue
    }
    
    var dataSourceType: [AppDetailCellType] = [AppDetailCellType]()
    var dataSourceHeight: [CGFloat] = [CGFloat]()
    var isSingleAppName: Bool = true // 是否是单行标题
    var isSingleDesc: Bool = true // 是否是单行副标题
    /// 应用详情页对应的appinfo数据结构
    var appDetailInfo: AppDetailInfo?
    var superViewSize: (() -> CGSize)!
    let appDetialInfoUpdate = PublishSubject<Bool>()
    let client: RustService
    let resolver: UserResolver
    let params: [String: String]
    // FG
    let reportEnabled: Bool // 举报入口FG控制

    /// Profile页打开场景
    public let scene: AppDetailOpenScene?
    /// 群ID，目前服务于群机器人业务
    public let chatID: String?

    /// 针对添加机器人到群聊场景，权限设置开关默认关闭
    static let checkMenderDefaultValue = false
    var checkMenderForGroupBotToAddScene: Bool = AppDetailViewModel.checkMenderDefaultValue
    private let trace: OPTrace = OPTraceService.default().generateTrace()

    /// 开放平台反馈配置：检查是否要显示小程序版本的反馈，提供小程序 applink
    private var opFeedbackConfig: FeedbackConfig? = {
        return FeedbackConfig(config: ECOConfig.service().getDictionaryValue(for: FeedbackConfig.ConfigName) ?? [:])
    }()

    init(appId: String = "",
         botId: String = "",
         params: [String: String] = [:],
         scene: AppDetailOpenScene? = nil,
         chatID: String? = nil,
         resolver: UserResolver) throws {
        self.resolver = resolver
        self.const = AppDetailViewModel.Const(resolver: resolver, Report: nil)
        self.appId = appId
        self.botId = botId
        self.params = params
        self.scene = scene
        self.chatID = chatID
        self.client = try resolver.resolve(assert: RustService.self)
        self.httpClient = try resolver.resolve(assert: OpenPlatformHttpClient.self)
        self.appReviewManager = try resolver.resolve(assert: AppReviewService.self)
        let userId = resolver.userID
        self.fileCacheManager = AppDetailUtils(resolver: resolver).internalDependency?.buildFileCache(for: userId)
        reportEnabled = resolver.fg.dynamicFeatureGatingValue(with: "feishu.report")
    }

    func fetchAppInfo() {
        guard !(appId.isEmpty && botId.isEmpty) else { return }
        /// 针对从群机器人列表页或添加机器人列表页进入机器人Profile的场景，为避免使用缓存时导致权限相关功能闪现，不再使用缓存
        let shouldRequestExtraInfo = self.shouldRequestGroupBotExtraInfo
        if !shouldRequestExtraInfo {
            fetchAppInfoFromLocal()
            if appDetailInfo != nil {
                appDetialInfoUpdate.onNext(false)
            }
        }
        fetchAppInfoFromRemote()
    }

    func curCellHeight(index: Int) -> CGFloat {
        guard index >= 0, index < dataSourceHeight.count, dataSourceHeight.count == dataSourceType.count else { return 0 }
        return dataSourceHeight[index]
    }

    func curCellType(index: Int) -> AppDetailCellType? {
        guard index >= 0, index < dataSourceHeight.count, dataSourceHeight.count == dataSourceType.count else { return nil }
        return dataSourceType[index]
    }

    func cellCount() -> Int {
        guard dataSourceHeight.count == dataSourceType.count else { return 0 }
        return dataSourceHeight.count
    }

    private func fetchAppInfoFromLocal() {
        let fileName = self.appId.isEmpty ? self.botId : self.appId
        guard !fileName.isEmpty else { return }
        let cacheLanguage = fileCacheManager?.readFromFile(fileName: "\(fileName)_language")
        guard let cacheLanguage = cacheLanguage, cacheLanguage == LanguageManager.currentLanguage.localeIdentifier else {return}
        let result = fileCacheManager?.readFromFile(fileName: fileName)
        guard let jsonStr = result, !jsonStr.isEmpty else { return }
        let json = JSON(parseJSON: jsonStr)
        appDetailInfo = AppDetailInfo(json: json)
        computeCellCount()
    }

    /// 如果botType == 1，则请求webhook接口来查看或更新权限信息；否则请求应用机器人相关接口
    var isWebhook: Bool {
        return params[groupBotExtraInfoKeyBotType] == "1"
    }

    /// 是否需要请求额外信息，当前只有确保机器人在群内，且在群机器人列表页或添加机器人列表页需要请求
    var shouldRequestGroupBotExtraInfo: Bool {
        if let scene = scene, scene == .groupBotToRemove {
            return true
        }
        return false
    }

    /// 是否允许当前用户去删除或编辑机器人
    var hasPermissionToEdit: Bool {
        if appDetailInfo?.extraInfo?.noPermission == false {
            return true
        }
        return false
    }

    func requestAppReviewInfo(fromLocal: Bool) {
        Self.logger.info("start request app review info fromLocal: \(fromLocal)")
        guard let appDetailInfo = appDetailInfo, !appDetailInfo.appId.isEmpty else {
            Self.logger.error("appId is empty")
            return
        }
        let appId = appDetailInfo.appId
        guard appReviewManager.isAppReviewEnable(appId: appId) else {
            Self.logger.error("appReviewManager is disable")
            return
        }
        if fromLocal {
            updateAppReviewInfo(appReviewInfo: appReviewManager.getAppReview(appId: appId))
            return
        }
        let trace = OPTraceService.default().generateTrace()
        appReviewManager.syncAppReview(appId: appId, trace: trace) { [weak self] appReviewInfo, error in
            executeOnMainQueueAsync {
            guard let self = self else { return }
            if let error = error {
                Self.logger.error("request app review error: \(error.localizedDescription)")
                return
            }
            self.updateAppReviewInfo(appReviewInfo: appReviewInfo)
            }
        }
    }

    private func updateAppReviewInfo(appReviewInfo: AppReviewInfo?) {
        self.appDetailInfo?.appReviewInfo = appReviewInfo
        self.computeCellCount()
        self.appDetialInfoUpdate.onNext(false)
    }
    
    private func fetchBotInfoAPI(isWebhook: Bool, botID: String, chatID: String? = nil) -> OpenPlatformAPI {
        if isWebhook {
            return OpenPlatformAPI.fetchWebhookBotInfoAPI(botID: botID, resolver: resolver)
        } else {
            return OpenPlatformAPI.fetchAppBotInfoAPI(botID: botID, chatID: chatID ?? "", resolver: resolver)
        }
    }

    private func fetchAppInfoFromRemote() {
        guard !(appId.isEmpty && botId.isEmpty) else {
            appDetialInfoUpdate.onNext(true)
            return
        }

        var request = GetAppDetailRequest()
        request.appID = appId
        request.botID = botId

        let request1 = client.sendAsyncRequest(request) { (response) -> GetAppDetailResponse in
            return response
        }
        let isWebhook = self.isWebhook
        let shouldRequestExtraInfo = self.shouldRequestGroupBotExtraInfo
        let request2 = requestBotInfoAPI(isWebhook: isWebhook, botID: botId, chatID: chatID).map { apiResponse in
            apiResponse.json
        }
        
        let onNext: ((GetAppDetailResponse, JSON?) -> Void) = { [weak self] (appDetailResponse, extraInfoJSON) in
            guard let `self` = self else { return }
            var success = false
            /// request1
            var json = JSON(parseJSON: appDetailResponse.jsonResp)
            let errorCode = json["code"].intValue
            var appDetailSuccess = (errorCode == 0)

            /// request2
            var extraInfo: AbstractBotExtraInfo?
            var extraSuccess = false
            if shouldRequestExtraInfo {
                if let extraInfoJSON = extraInfoJSON {
                    let (info, infoError) = self.decodeJSONOfGroupBotInfo(isWebhook: isWebhook, json: extraInfoJSON)
                    if let info2 = info {
                        extraInfo = info2
                        extraSuccess = true
                    }
                }
                success = appDetailSuccess && extraSuccess
            } else {
                success = appDetailSuccess
            }

            if success { // 成功
                /// 调用computeCellCount会使用UIView.frame，触发主线程检查
                executeOnMainQueueAsync {
                    AppDetailInfo.encodeExtraInfo(json: &json, isWebHook: isWebhook, extraInfo: extraInfo)
                    var appDetailInfo = AppDetailInfo(json: json, shouldDecodeGroupBotExtraInfo: shouldRequestExtraInfo)
                    self.appDetailInfo = appDetailInfo
                    // 先用本地数据
                    if !appDetailInfo.appId.isEmpty, self.appReviewManager.isAppReviewEnable(appId: appDetailInfo.appId) {
                        self.appDetailInfo?.appReviewInfo = self.appReviewManager.getAppReview(appId: appDetailInfo.appId)
                    }
                    self.computeCellCount()
                    self.appDetialInfoUpdate.onNext(false)
                    let fileName = self.appId.isEmpty ? self.botId : self.appId
                    if !fileName.isEmpty {
                        if let result = json.rawString() {
                            self.fileCacheManager?.writeToFile(fileName: fileName, data: result)
                            self.fileCacheManager?.writeToFile(fileName: "\(fileName)_language", data: LanguageManager.currentLanguage.localeIdentifier)
                        }
                    }
                    self.requestAppReviewInfo(fromLocal: false)
                }
                return
            }
            AppDetailViewModel.logger.error("fetchAppInfoFromRemote errorCode: \(errorCode)")
            self.appDetialInfoUpdate.onNext(true)
        }
        let onError: ((Error) -> Void) = { [weak self] (error) in
            AppDetailViewModel.logger.debug("fetchAppInfoFromRemote error: \(error)")
            self?.appDetialInfoUpdate.onNext(true)
        }
        if shouldRequestExtraInfo {
            Observable.zip(request1, request2).subscribe(
                onNext: onNext,
                onError: onError
            )
            .disposed(by: disposeBag)
        } else {
            request1.subscribe(
                onNext: { (appDetailResponse) in
                    onNext(appDetailResponse, nil)
                },
                onError: onError
            )
            .disposed(by: disposeBag)
        }
    }
    
    private func requestBotInfoAPI<R>(isWebhook: Bool, botID: String, chatID: String? = nil) -> Observable<R> where R: APIResponse {
        if OPNetworkUtil.basicUseECONetworkEnabled() {
            var components: OPNetworkUtil.ECONetworkReqComponents? = fetchBotInfoReqComponents(isWebhook: isWebhook, botID: botID, chatID: chatID)
            return Observable<R>.create { (ob) -> Disposable in
                if let components = components {
                    let task = Self.service.post(url: components.url, header: components.header, params: components.params, context: components.context) { [weak self] response, error in
                        if let error = error {
                            ob.onError(error)
                            return
                        }
                        guard let self = self else {
                            let selfErrorMsg = "requestBotInfoAPI failed because self is nil"
                            let nsError = NSError(domain: selfErrorMsg, code: -1, userInfo: nil)
                            ob.onError(nsError)
                            return
                        }
                        let logID = OPNetworkUtil.reportLog(Self.logger, response: response)
                        guard let response = response,
                              let result = response.result else {
                            let invalidMsg = "requestBotInfoAPI failed because response or result is nil"
                            let nsError = NSError(domain: invalidMsg, code: -1, userInfo: nil)
                            ob.onError(nsError)
                            return
                        }
                        let json = JSON(result)
                        let obj = R(json: json, api: OpenPlatformAPI(path: .empty, resolver: self.resolver))
                        obj.lobLogID = logID
                        ob.onNext(obj)
                        ob.onCompleted()
                    }
                    if let task = task {
                        Self.service.resume(task: task)
                    } else {
                        let error = "requestBotInfoAPI url econetwork task failed"
                        Self.logger.error(error)
                        let nsError = NSError(domain: error, code: -1, userInfo: nil)
                        ob.onError(nsError)
                    }
                } else {
                    ob.onError(RxError.unknown)
                }
                return Disposables.create {}
            }
        }
        let api = fetchBotInfoAPI(isWebhook: isWebhook, botID: botId, chatID: chatID)
        return httpClient.request(api: api)
    }
    
    private func fetchBotInfoReqComponents(isWebhook: Bool, botID: String, chatID: String? = nil) -> OPNetworkUtil.ECONetworkReqComponents? {
        var url: String? = nil
        if isWebhook {
            url = OPNetworkUtil.getWebhookBotInfoURL()
        } else {
            url = OPNetworkUtil.getAppBotInfoURL()
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
        var params: [String: Any] = [APIParamKey.larkVersion.rawValue: Utils.appVersion,
                                     APIParamKey.bot_id.rawValue: botID,
                                     APIParamKey.i18n.rawValue: OpenPlatformAPI.curLanguage(),
                                     APIParamKey.locale.rawValue: OpenPlatformAPI.curLanguage()]
        if !isWebhook {
            params[APIParamKey.chat_id.rawValue] = chatID
        }
        let context = OpenECONetworkContext(trace: OPTraceService.default().generateTrace(), source: .other)
        return OPNetworkUtil.ECONetworkReqComponents(url: reqURL, header: header, params: params, context: context)
    }

    func hasAppReviewed() -> Bool {
        guard let appInfo = appDetailInfo, let appReviewInfo = appInfo.appReviewInfo else { return false }
        return appReviewInfo.isReviewed
    }
    
    private func decodeJSONOfGroupBotInfo(isWebhook: Bool, json: JSON) -> (AbstractBotExtraInfo?, Error?) {
        if json["code"].int == 0 {  // 请求成功
            Self.logger.info("requestGroupBotInfo request data via network successed")
            var dataJSON: JSON
            if isWebhook {
                dataJSON = json["data"]
            } else {
                dataJSON = json
            }
            if let data = try? dataJSON.rawData() {
                let decoder = JSONDecoder()
                var info: AbstractBotExtraInfo?
                var decodeMsg: String?
                if isWebhook {
                    if let extraInfo = try? decoder.decode(WebhookBotExtraInfo.self, from: data) {
                        info = extraInfo
                    } else {
                        decodeMsg = "decode error for WebhookBotExtraInfo with json(\(json))"
                    }
                } else {
                    if let extraInfo = try? decoder.decode(AppBotExtraInfo.self, from: data) {
                        info = extraInfo
                    } else {
                        decodeMsg = "decode error for AppBotExtraInfo with json(\(json))"
                    }
                }
                if let info = info {
                    return (info, nil)
                }
                Self.logger.error("requestGroupBotInfo decode error(\(decodeMsg))")
            }
        }

        let errorMessage = "requestGroupBotInfo request data failed with json: \(String(describing: json))"
        Self.logger.error(errorMessage)
        let error = NSError(domain: "requestGroupBotInfo",
                            code: AppDetailViewModel.defaultErrCode,
                            userInfo: [NSLocalizedDescriptionKey: errorMessage])
        return (nil, error)
    }

    func isSingleDirection() -> Bool {
        guard let appInfo = appDetailInfo else { return true }
        let size = superViewSize()
        return widthForText(text: appInfo.getLocalDirection(),
                            font: UIFont.systemFont(ofSize: 14.0), height: 20) <= size.width - 168
    }

    func isSingleDeveloperInfo() -> Bool {
        guard let appInfo = appDetailInfo else { return true }
        if !appInfo.isISV() {
            return true
        }
        let size = superViewSize()
        return widthForText(text: appInfo.getLocalDeveloperInfo(),
                            font: UIFont.systemFont(ofSize: 14.0), height: 20) <= size.width - 168 - (appInfo.isISV() ? 18 : 0)
    }

    private func widthForText(text: String, font: UIFont?, height: CGFloat) -> CGFloat {
        if let curFont = font {
            return (text as NSString).boundingRect(with: CGSize(width: CGFloat(MAXFLOAT), height: height),
                                                   options: .usesLineFragmentOrigin,
                                                   attributes: [.font: curFont],
                                                   context: nil).width
        }
        return (text as NSString).boundingRect(with: CGSize(width: CGFloat(MAXFLOAT), height: height),
                                               options: .usesLineFragmentOrigin,
                                               attributes: nil,
                                               context: nil).width
    }
    
    func hasAppType(appType: AppType) -> Bool {
        Self.logger.info("AppDetailViewModel check appType:\(appType), cache appType:\(appDetailInfo?.appType)")
        guard let appInfo = appDetailInfo, let type = appInfo.appType else {
            return false
        }
        return (type & appType.rawValue) != 0
    }

    func openFeedback(from: UIViewController?) {
        guard let info = appDetailInfo, let vc = from else {
            Self.logger.error("open feedback cancel")
            return
        }
        let type = feedbackType()
        switch type {
        case .none:
            return
        case .miniApp(let applink):
            if applink.isEmpty {
                self.dealFailedFeedback(errorType: .BuildURLFailed)
                return
            }
            guard let applinkComponents = NSURLComponents(string: applink),
              let launchQuery = buildMicroappFeedbackLaunchQuery() else {
                Self.logger.error("build launch query failed, fallback to original feedback")
                self.dealFailedFeedback(errorType: .BuildQueryFailed)
                return
            }

            var queryItems = applinkComponents.queryItems ?? []
            queryItems.append(launchQuery)
            applinkComponents.queryItems = queryItems
            if let url  = applinkComponents.url {
                OPMonitor(EPMClientOpenPlatformAppFeedbackCode.open_app_feedback_microapp_success)
                    .setResultTypeSuccess()
                    .flush()
                self.resolver.navigator.push(url, from: vc) { _, res in
                    if let error = res.error {
                        Self.logger.error("push new feedback failed \(error)")
                    }
                }
            } else {
                Self.logger.error("build applink failed! fallback to original feedback")
                self.dealFailedFeedback(errorType: .BuildURLFailed)
            }
        }
    }
    
    private func dealFailedFeedback(errorType: AppFeedbackFailedType) {
        OPMonitor(EPMClientOpenPlatformAppFeedbackCode.open_app_feedback_microapp_fail)
            .setResultTypeFail()
            .addCategoryValue("error_type", errorType.rawValue)
            .flush()
        let errorInfo = LarkOpenPlatform.BundleI18n.LarkOpenPlatform.OpenPlatform_Feedback_FeedbackFailedToast
        let config = UDToastConfig(toastType: .error, text: errorInfo, operation: nil)
        guard let mainSceneWindow = Navigator.shared.mainSceneWindow else {
            return
        }
        UDToast.showToast(with: config, on: mainSceneWindow)
    }


    private func buildMicroappFeedbackLaunchQuery() -> URLQueryItem? {
        guard let appInfo = appDetailInfo else { return nil }

        let params: [String: AnyHashable] = ["app_id": appInfo.appId,
                                             "app_name": appInfo.getLocalTitle(),
                                             "app_version": appInfo.version,
                                             "app_type": "bot",
                                             "page_path": ""]

        do {
            let data = try JSONSerialization.data(withJSONObject: params)
            return URLQueryItem(name: "bdp_launch_query", value: String(data: data, encoding: .utf8))
        } catch {
            Self.logger.error("json serialization failed \(error)")
            return nil
        }
    }

    func openDeveloperChat(from: UIViewController) {
        guard let appInfo = appDetailInfo, !appInfo.developerId.isEmpty, !appInfo.isISV() else { return }
        openChat(from: from, userId: appInfo.developerId)
    }

    func openInviterChat(from: UIViewController) {
        guard let appInfo = appDetailInfo, let botInviterID = appInfo.botInviterID, !botInviterID.isEmpty else { return }
        openChat(from: from, userId: botInviterID)
    }

    private func openChat(from: UIViewController, userId: String) {
        let info = AppDetailChatInfo(userId: userId, from: from, disposeBag: disposeBag)
        AppDetailUtils(resolver: resolver).internalDependency?.toChat(info, completion: nil)
    }

    func openLarkApp() {
        guard let appInfo = appDetailInfo else {
            Self.logger.error("LarkAppCenter openLarkApp but appInfo is nil")
            return
        }
        if let h5Applink = appInfo.h5Applink, !h5Applink.isEmpty {
            Self.logger.info("AppDetailViewModel h5Applink:\(h5Applink)")
            if hasAppType(appType: .h5) {
                if let url = URL(string: h5Applink) {
                    if let fromVC = Navigator.shared.mainSceneWindow?.fromViewController {
                        Self.logger.info("LarkAppCenter openLarkApp with applink")
                        AppDetailUtils(resolver: resolver).internalDependency?.showDetailOrPush(url, from: fromVC)
                    } else {
                        Self.logger.error("LarkAppCenter openLarkApp can not push vc because no fromViewController")
                    }
                } else {
                    Self.logger.error("LarkAppCenter openLarkApp parse url fail")
                }
                return
            } else {
                Self.logger.warn("LarkAppCenter openLarkApp but not h5 app")
            }
        } else {
            Self.logger.warn("LarkAppCenter openLarkApp with empty h5applink")
        }
        Self.logger.info("AppDetailViewModel appUrl:\(appInfo.appUrl)")
        if appInfo.appUrl.hasPrefix("http") || appInfo.appUrl.hasPrefix("https") {
            //  新容器
            guard let url = URL(string: appInfo.appUrl) else { return }
            /*
            let body = WebBody(url: url, appID: appInfo.appId)
 */
            //  这里的iconKey不符合主端规范，无法消费，传入nil，责任是 appDetailInfo 数据源后端
            let body = WebBody(url: url, webAppInfo: WebAppInfo(id: appInfo.appId, name: appInfo.title, iconKey: nil))
            if let fromVC = Navigator.shared.mainSceneWindow?.fromViewController {
                self.resolver.navigator.push(body: body, from: fromVC)
            } else {
                Self.logger.error("LarkAppCenter openLarkApp can not push vc because no fromViewController")
            }
        } else {
            guard let miniUrl = URL(string: appInfo.appUrl) else { return }
            if let fromVC = Navigator.shared.mainSceneWindow?.fromViewController {
                self.resolver.navigator.push(miniUrl, context: ["from": "chat_bot_profile"], from: fromVC, animated: true, completion: nil)
            } else {
                Self.logger.error("LarkAppCenter openLarkApp can not push vc because no fromViewController")
            }
        }
    }

    func openMessageBot(from: UIViewController) {
        guard appDetailInfo != nil else { return }
        guard !botId.isEmpty else { return }
        let info = AppDetailChatInfo(userId: botId, from: from, disposeBag: disposeBag)
        AppDetailUtils(resolver: resolver).internalDependency?.toChat(info, completion: nil)
    }

    func openApplyForUse() {
        let applyBody = ApplyForUseBody(appId: appDetailInfo?.appId ?? appId,
                                        botId: appDetailInfo?.botId ?? botId,
                                        appName: appDetailInfo?.title ?? "")
        if let fromVC = Navigator.shared.mainSceneWindow?.fromViewController {
            self.resolver.navigator.push(body: applyBody, from: fromVC)
        } else {
            Self.logger.error("LarkAppCenter openApplyForUse can not push vc because no fromViewController")
        }
    }

    // 举报
    func openReport() {
        let reportId = appDetailInfo?.appId ?? appId
        let params = JSON(["app_id": reportId]).rawString()
        guard !reportId.isEmpty, let paramsStr = params else {
            Self.logger.error("LarkAppCenter openReport reportid is empty or params json failed")
            return
        }
        guard let url = URL(string: const.Report) else {
            Self.logger.error("LarkAppCenter openReport url init string failed")
            return
        }
        let reportUrl = url.lf.addQueryDictionary(["type": "app",
                                                   "params": paramsStr])
        guard let reportStr = reportUrl?.lf.toHttpUrl() else {
            Self.logger.error("LarkAppCenter openReport url with query to http url failed")
            return
        }
        if let fromVC = Navigator.shared.mainSceneWindow?.fromViewController {
            self.resolver.navigator.push(reportStr, from: fromVC)
        } else {
            Self.logger.error("LarkAppCenter openReport can not push vc because no fromViewController")
        }
    }
    /// 打开帮助文档
    func openHelpDoc() {
        guard let doc = appDetailInfo?.getHelpDocInfo(), let docUrl = URL(string: doc) else {
            Self.logger.error("help doc url is empty, open doc failed")
            return
        }
        if let fromVC = Navigator.shared.mainSceneWindow?.fromViewController {
            self.resolver.navigator.push(docUrl, from: fromVC)
        } else {
            Self.logger.error("LarkAppCenter openHelpDoc can not push vc because no fromViewController")
        }
    }
    /// 打开应用分享模块
    func openAppShare(from: UIViewController) {
        guard let appId = appDetailInfo?.appId, !appId.isEmpty else {
            AppDetailViewModel.logger.error("appId missing, can't open share")
            return
        }
        Self.logger.info("open share with \(appId)")
        AppDetailUtils(resolver: resolver).internalDependency?.shareApp(with: appId, entry: .profile, from: from)
    }
    /// 打开评分小程序
    func openAppReview(from: UIViewController) {
        Self.logger.info("start open appReview gadget")
        guard let appInfo = appDetailInfo else {
            Self.logger.error("can't open appReview because appInfo is nil")
            return
        }
        guard !appInfo.appId.isEmpty else {
            Self.logger.error("can't open appReview because appInfo is nil")
            return
        }
        let params = AppLinkParams(appId: appInfo.appId,
                                   appIcon: appInfo.avatarKey,
                                   appName: appInfo.getLocalTitle(),
                                   appType: .bot,
                                   appVersion: nil,
                                   origSeneType: nil,
                                   pagePath: "",
                                   fromType: .container,
                                   trace: trace.traceId)
        guard let applink = appReviewManager.getAppReviewLink(appLinkParams: params) else {
            Self.logger.error("get app review link error: applink is nil")
            return
        }
        OPMonitor("openplatform_bot_profile_click")
            .addCategoryValue("application_id", appInfo.appId)
            .addCategoryValue("click", "my_score")
            .addCategoryValue("target", "openplatform_application_new_score_view")
            .setPlatform(.tea)
            .flush()
        AppDetailUtils(resolver: resolver).internalDependency?.showDetailOrPush(applink, from: from)
    }

    /// 添加机器人到群聊
    func addBotToGroupAndGotoChat(fromVC: UIViewController, completion: (() -> Void)?) {
        guard let chatID = chatID else {
            AppDetailViewModel.logger.error("chatID missing, can't add bot to group")
            completion?()
            return
        }
        let window = fromVC.view.window
        let monitorSuccess = OPMonitor(name: GroupBotMonitorParamKey.keyEvent, code: EPMClientOpenPlatformGroupBotCode.add_groupbot_success)
            .setResultTypeSuccess()
            .timing()
            .addCategoryValue(GroupBotMonitorParamKey.keyScene, "profile")
            .addCategoryValue(GroupBotMonitorParamKey.keyChatID, chatID)
            .addCategoryValue(GroupBotMonitorParamKey.keyBotID, botId)
        let monitorFail = OPMonitor(name: GroupBotMonitorParamKey.keyEvent, code: EPMClientOpenPlatformGroupBotCode.add_groupbot_fail)
            .setResultTypeFail()
            .addCategoryValue(GroupBotMonitorParamKey.keyScene, "profile")
            .addCategoryValue(GroupBotMonitorParamKey.keyChatID, chatID)
            .addCategoryValue(GroupBotMonitorParamKey.keyBotID, botId)
        let onSelfError: () -> Void = {
            AppSettingViewModel.log.error("addBotToGroupAndGotoChat failed because self is nil")
        }
        let onError: (Error) -> Void = { error in
            completion?()
            Self.logger.error("addBotToGroupAndGotoChat failed with error(\(error)")
            if let window = window {
                RoundedHUD.showFailure(with: BundleI18n.GroupBot.Lark_GroupBot_AddBotFailed, on: window)
            } else {
                Self.logger.error("addBotToGroupAndGotoChat failed not show toast because window is nil")
            }
        }
        let onSuccess: (APIResponse) -> Void = { [weak self] result in
            completion?()
            guard let self = self else {
                onSelfError()
                return
            }
            if result.code == 0 {
                Self.logger.info("addBotToGroupAndGotoChat success")
                monitorSuccess.flush()
                self.gotoChat(chatID: chatID, from: fromVC)
            } else {
                Self.logger.error("addBotToGroupAndGotoChat failed with code\(result.code ?? -1)")
                monitorFail.flush()
                let toast = result.json["msg"].string ?? BundleI18n.GroupBot.Lark_GroupBot_AddBotFailed
                if let window = window {
                    RoundedHUD.showFailure(with: toast, on: window)
                } else {
                    Self.logger.error("addBotToGroupAndGotoChat failed not show toast because window is nil")
                }
            }
        }
        if OPNetworkUtil.basicUseECONetworkEnabled() {
            guard let url = OPNetworkUtil.getAddBotToGroupURL() else {
                Self.logger.error("addBotToGroupAndGotoChat url failed")
                completion?()
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
                                         APIParamKey.bot_id.rawValue: botId,
                                         APIParamKey.i18n.rawValue: OpenPlatformAPI.curLanguage(),
                                         APIParamKey.locale.rawValue: OpenPlatformAPI.curLanguage(),
                                         APIParamKey.check_mender.rawValue: checkMenderForGroupBotToAddScene]
            let context = OpenECONetworkContext(trace: trace, source: .other)
            let completionHandler: (ECOInfra.ECONetworkResponse<[String: Any]>?, ECOInfra.ECONetworkError?) -> Void = { [weak self] response, error in
                if let error = error {
                    onError(error)
                    return
                }
                guard let self = self else {
                    let error = "addBotToGroupAndGotoChat failed because self is nil"
                    let nsError = NSError(domain: error, code: -1, userInfo: nil)
                    onError(nsError)
                    return
                }
                let logID = OPNetworkUtil.reportLog(Self.logger, response: response)
                guard let response = response,
                      let result = response.result else {
                    let error = "addBotToGroupAndGotoChat failed because response or result is nil"
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
                Self.logger.error("addBotToGroupAndGotoChat url econetwork task failed")
                completion?()
            }
            return
        }
        
        let requestAPI = OpenPlatformAPI.addBotToGroup(botID: botId, chatID: chatID, source: .profile, checkMender: checkMenderForGroupBotToAddScene, resolver: resolver)
        httpClient.request(api: requestAPI)
            .subscribe(onNext: { result in
                onSuccess(result)
            }, onError: { error in
                onError(error)
            }).disposed(by: self.disposeBag)
    }

    /// 将机器人从群聊移除
    func removeBotFromGroupAndGotoChat(fromVC: UIViewController, start:(() -> Void)?, completion: (() -> Void)?) {
        guard let chatID = chatID else {
            AppDetailViewModel.logger.error("chatID missing, can't add bot to group")
            completion?()
            return
        }

        let alert = LarkAlertController()
        alert.setContent(text: BundleI18n.GroupBot.Lark_GroupBot_Remove_Content, alignment: .center)
        alert.addCancelButton()
        let window = fromVC.view.window
        alert.addPrimaryButton(text: BundleI18n.LarkOpenPlatform.OpenPlatform_AppCenter_Confirm, dismissCompletion: { [weak self] in
            guard let `self` = self else {
                return
            }
            start?()
            
            let monitorSuccess = OPMonitor(name: GroupBotMonitorParamKey.keyEvent, code: EPMClientOpenPlatformGroupBotCode.delete_groupbot_success)
                .setResultTypeSuccess()
                .timing()
                .addCategoryValue(GroupBotMonitorParamKey.keyScene, "profile")
                .addCategoryValue(GroupBotMonitorParamKey.keyChatID, chatID)
                .addCategoryValue(GroupBotMonitorParamKey.keyBotID, self.botId)
            let monitorFail = OPMonitor(name: GroupBotMonitorParamKey.keyEvent, code: EPMClientOpenPlatformGroupBotCode.delete_groupbot_fail)
                .setResultTypeFail()
                .addCategoryValue(GroupBotMonitorParamKey.keyScene, "profile")
                .addCategoryValue(GroupBotMonitorParamKey.keyChatID, chatID)
                .addCategoryValue(GroupBotMonitorParamKey.keyBotID, self.botId)
            let onError: (Error) -> Void = { error in
                completion?()
                monitorFail.addCategoryValue(GroupBotMonitorParamKey.errorCode, -100).addCategoryValue(GroupBotMonitorParamKey.errorMsg, error.localizedDescription).flush()
                Self.logger.error("removeBotFromGroupAndGotoChat failed with error(\(error)")
                if let window = window {
                    RoundedHUD.showFailure(with: BundleI18n.GroupBot.Lark_GroupBot_DeleteBotFailed, on: window)
                } else {
                    Self.logger.error("removeBotFromGroupAndGotoChat failed not show toast because window is nil")
                }
            }
            let onSuccess: (APIResponse) -> Void = { [weak self] result in
                completion?()
                guard let `self` = self else {
                    Self.logger.error("deleteBotToGroupAndGotoChat failed because self is nil")
                    return
                }
                if result.code == 0 {
                    Self.logger.info("deleteBotToGroupAndGotoChat success")
                    monitorSuccess.flush()
                    self.gotoChat(chatID: chatID, from: fromVC)
                } else {
                    monitorFail.addCategoryValue(GroupBotMonitorParamKey.errorCode, result.code).addCategoryValue(GroupBotMonitorParamKey.errorMsg, result.json["msg"].string).flush()
                    Self.logger.error("deleteBotToGroupAndGotoChat failed with code \(result.code ?? -1)")
                    let toast = result.json["msg"].string ?? BundleI18n.GroupBot.Lark_GroupBot_AddBotFailed
                    if let window = window {
                        RoundedHUD.showFailure(with: toast, on: window)
                    } else {
                        Self.logger.error("deleteBotToGroupAndGotoChat failed not show toast because window is nil")
                    }
                }
            }
            
            if OPNetworkUtil.basicUseECONetworkEnabled() {
                guard let url = OPNetworkUtil.getDelBotFromGroupURL() else {
                    Self.logger.error("removeBotFromGroupAndGotoChat url failed")
                    completion?()
                    return
                }
                var header: [String: String] = [APIHeaderKey.Content_Type.rawValue: "application/json"]
                if let userService = try? self.resolver.resolve(assert: PassportUserService.self) {
                    let sessionID: String? = userService.user.sessionKey
                    header[APIHeaderKey.X_Session_ID.rawValue] = sessionID
                    // 对照原网络接口参数实现, 若session:nil, 则不为Header添加Cookie:value键值对
                    if let value = sessionID {
                        header[APIHeaderKey.Cookie.rawValue] = "\(APICookieKey.session.rawValue)=\(value)"
                    }
                }
                let params: [String: Any] = [APIParamKey.larkVersion.rawValue: Utils.appVersion,
                                             APIParamKey.chat_id.rawValue: chatID,
                                             APIParamKey.bot_id.rawValue: self.botId,
                                             APIParamKey.i18n.rawValue: OpenPlatformAPI.curLanguage(),
                                             APIParamKey.locale.rawValue: OpenPlatformAPI.curLanguage()]
                let context = OpenECONetworkContext(trace: trace, source: .other)
                let completionHandler: (ECOInfra.ECONetworkResponse<[String: Any]>?, ECOInfra.ECONetworkError?) -> Void = { [weak self] response, error in
                    if let error = error {
                        onError(error)
                        return
                    }
                    guard let self = self else {
                        let error = "removeBotFromGroupAndGotoChat failed because self is nil"
                        let nsError = NSError(domain: error, code: -1, userInfo: nil)
                        onError(nsError)
                        return
                    }
                    let logID = OPNetworkUtil.reportLog(Self.logger, response: response)
                    guard let response = response,
                          let result = response.result else {
                        let error = "removeBotFromGroupAndGotoChat failed because response or result is nil"
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
                    Self.logger.error("removeBotFromGroupAndGotoChat url econetwork task failed")
                    completion?()
                }
                return
            }
            
            let requestAPI = OpenPlatformAPI.deleteBotFromGroupAPI(botID: self.botId, chatID: chatID, resolver: self.resolver)
            self.httpClient.request(api: requestAPI)
                .subscribe(onNext: { result in
                    onSuccess(result)
                }, onError: {error in
                    onError(error)
                }).disposed(by: self.disposeBag)
        })
        self.resolver.navigator.present(alert, from: fromVC)
    }

    /// 跳转到会话
    func gotoChat(chatID: String, from: UIViewController) {
        AppDetailUtils(resolver: resolver).internalDependency?.toChat(chatID, from: from)
    }
}

// MARK: compute cell count
extension AppDetailViewModel {
    private func computeCellCount() {
        guard let appInfo = appDetailInfo else { return }
        let size = superViewSize()
        dataSourceType.removeAll()
        dataSourceHeight.removeAll()
        // 128: label距离左边加上距离右边距离之和为定值128
        isSingleAppName = !(widthForText(text: appInfo.getLocalTitle(),
                                         font: UIFont.systemFont(ofSize: 24.0, weight: .semibold),
                                         height: 36) >= size.width - 128)
        isSingleDesc =  !(widthForText(text: appInfo.getLocalDescription(),
                                       font: UIFont.systemFont(ofSize: 14.0),
                                       height: 20) > size.width - 128)
        // 如果标题多行，那么副标题都只显示单行
        if !isSingleAppName {
            isSingleDesc = true
        }

        guard let status = appInfo.curAppStatus() else {
            if !appInfo.getLocalDeveloperInfo().isEmpty {
                dataSourceType.append(.Developer)
                dataSourceHeight.append(!isSingleDeveloperInfo() ? const.MultCellH : const.NormalCellH)
            }
            return
        }

        Self.logger.info("compute cell count with status \(status)")

        if status == .usable {
            if showInstruction()  {
                dataSourceType.append(.Instruction)
                var instructH: CGFloat = !isSingleDirection() ? const.MultCellH : const.NormalCellH
                dataSourceHeight.append(instructH)
            }
        }
        if status != .appNeedPayUse {
            if showDeveloper() {
                dataSourceType.append(.Developer)
                var developerH: CGFloat = !isSingleDeveloperInfo() ? const.MultCellH : const.NormalCellH
                dataSourceHeight.append(developerH)
            }
            if showInvitedBy() {
                dataSourceType.append(.InvitedBy)
                dataSourceHeight.append(const.NormalCellH)
            }
        }
        if status == .usable {
            if showHelpDoc() {
                dataSourceType.append(.HelpDoc)
                dataSourceHeight.append(const.NormalCellH)
            }
            if showAuthorziationSetting() {
                dataSourceType.append(.AuthorizationSetting)
                // 需要在计算authorziationSetting cell高度之前，设置containerWidth，以此宽度为基准来计算cell高度
                let text = BundleI18n.GroupBot.Lark_GroupBot_CustomAppPermissionCheckbox
                var cellHeight = AppDetailCell.settingCellFitHeight(cellWidth: superViewSize().width, text: text)
                dataSourceHeight.append(cellHeight)
            }
        }
        if showScopeInfo() {
            dataSourceType.append(.ScopeInfo)
            dataSourceHeight.append(const.NormalCellH)
        }
        if case .none = feedbackType() {} else {
            dataSourceType.append(.FeedBack)
            dataSourceHeight.append(const.NormalCellH)
        }
        if status == .usable && showReceiveMessage() {
            dataSourceType.append(.ReceiveMessageSetting)
            let text = BundleI18n.GroupBot.Lark_BotMsg_ReceiveMsgHoverText
            var cellHeight = AppDetailCell.settingCellFitHeight(cellWidth: superViewSize().width, text: text)
            dataSourceHeight.append(cellHeight)
        }
        if status == .offline || status == .appDeleted {
            if showHistoryMessage() {
                dataSourceType.append(.HistoryMessage)
                dataSourceHeight.append(const.NormalCellH)
            }
        }
        if showAppReview() {
            dataSourceType.append(.AppReview)
            dataSourceHeight.append(hasAppReviewed() ? const.ReviewedH : const.UnreviewH)
        }
    }
}

// MARK: show ability
extension AppDetailViewModel {
    // 是否显示Developer
    private func showDeveloper() -> Bool {
        if showInvitedBy() {
            // 产品需求：如果显示邀请人，则不显示开发者 (https://bytedance.feishu.cn/docs/doccnB5gwkkKrGDVZDBM2WH4tag?login_redirect_times=1)
            return false
        }
        guard let appInfo = appDetailInfo else { return false }
        return !appInfo.getLocalDeveloperInfo().isEmpty
    }
    
    private func showScopeInfo() -> Bool {
        let inviterName = self.appDetailInfo?.botInviterDisplayName
        return !self.isWebhook && inviterName == nil
    }
    /// 是否显示权限设置
    /// - 群主、机器人的添加者在访问机器人资料卡时，可勾选/取消勾选是否“仅允许群主和添加者从群聊中移除机器人”，默认态不勾选此配置
    /// - 如果群主和添加者勾选了禁止删除权限，其他群成员有以下限制：
    ///     - 无法在机器人资料卡上删除机器人，可见相关引导提示
    func showAuthorziationSetting() -> Bool {
        // 针对未添加到群的场景，客户端直接展示权限开关
        if showAddBotToGroup() {
            return true
        }
        // 判断当前用户身份不是群主、机器人的添加者时，不展示开关
        if let showCheckMender = appDetailInfo?.extraInfo?.showCheckMender {
            return showCheckMender
        }
        return false
    }
    /// 权限设置开关状态
    func statusOfAuthorziationSetting() -> Bool {
        // 针对未添加到群的场景，客户端直接展示权限开关，默认为false
        if showAddBotToGroup() {
            return Self.checkMenderDefaultValue
        }
        if let checkMender = appDetailInfo?.extraInfo?.checkMender {
            return checkMender
        }
        return false
    }
    
    /// 是否接受消息开关状态
    func ReceiveMessageSetting() -> Bool {
        return appDetailInfo?.receiveMessageSetting == .receiveMessage
    }

    // 是否显示评分
    private func showAppReview() -> Bool {
        guard let appInfo = appDetailInfo else { return false }
        guard !appInfo.appId.isEmpty, appReviewManager.isAppReviewEnable(appId: appInfo.appId) else { return false }
        return true
    }

    // 是否显示Instruction
    private func showInstruction() -> Bool {
        guard let appInfo = appDetailInfo else { return false }
        return !appInfo.getLocalDirection().isEmpty
    }
    
    private func showReceiveMessage() -> Bool {
        Self.logger.info("AppDateilViewModel judge show receive message,scene:\(self.scene), receiveMessageSetting:\(self.appDetailInfo?.receiveMessageSetting)")
        return (self.scene == nil) && ((self.appDetailInfo?.receiveMessageSetting ?? .noShow).rawValue >= ReceiveMessageType.receiveMessage.rawValue) && self.resolver.fg.staticFeatureGatingValue(with: "messager.bot.p2p_chat_mute")
    }

    // 是否显示邀请人
    private func showInvitedBy() -> Bool {
        guard let appDetailInfo = appDetailInfo,
            let botInviterName = appDetailInfo.getLocalBotInviterName() else {
                return false
        }

        if !botInviterName.isEmpty {
            return true
        }
        return false
    }

    // 获取feedback类型
    private func feedbackType() -> ProfileFeedbackType {
        guard let appInfo = appDetailInfo, !appInfo.appId.isEmpty else {
            return .none
        }
        guard let feedbackConfig = opFeedbackConfig,
                (feedbackConfig.applyToAll || feedbackConfig.appIdWhiteList.contains(appInfo.appId)) else {
            return .none
        }
        return .miniApp(feedbackConfig.baseAppLink)
    }

    // 是否显示SendMessage
    func showSendMessage() -> Bool {
        guard let appInfo = appDetailInfo, let status = appInfo.curAppStatus() else { return false }
        if hasAppType(appType: .bot) && appInfo.curChatType() != .InChatBot && !(appInfo.isOnCall ?? false) && status == .usable {
            return true
        }
        return false
    }

    // 是否显示HistoryMessage
    private func showHistoryMessage() -> Bool {
        guard let appInfo = appDetailInfo else { return false }
        return appInfo.curChatType() == .HistoryMessage
    }

    // 是否显示OpenApp
    func showOpenApp() -> Bool {
        guard let appInfo = appDetailInfo, let status = appInfo.curAppStatus() else { return false }
        if (showH5() || showApp()) && !(appInfo.isOnCall ?? false) && status == .usable {
            return true
        }
        return false
    }

    /// 是否显示将机器人「添加到群聊」
    /// @zhangxin.alan: 删除入口应该机器人在群里就展示（大前提：不考虑群主权限配置），添加入口是受可用性控制的
    func showAddBotToGroup() -> Bool {
        guard let chatID = chatID, let scene = scene else { return false }
        if scene == .groupBotToAdd {
            return true
        }
        return false
    }

    /// 是否显示将机器人「从群聊中移除」
    /// @zhangxin.alan: 删除入口应该机器人在群里就展示（大前提：不考虑群主权限配置），添加入口是受可用性控制的
    func showRemoveBotFromGroup() -> Bool {
        guard let chatID = chatID, let scene = scene else { return false }
        if scene == .groupBotToRemove {
            if hasPermissionToEdit {
                return true
            }
        }
        return false
    }

    /// 是否展示帮助文档
    private func showHelpDoc() -> Bool {
        guard let appInfo = appDetailInfo else { return false }
        let isShowDoc = !appInfo.getHelpDocInfo().isEmpty
        if let appSceneType = appDetailInfo?.getAppType() {
            let params = ["show_help": isShowDoc, "application_type": appSceneType.rawValue] as [String: Any]
            AppDetailUtils(resolver: resolver).internalDependency?.post(eventName: "op_profile_show", params: params)
        }
        return isShowDoc
    }

    /// 是否展示分享
    func showShare() -> Bool {
        guard let appInfo = appDetailInfo else { return false }
        return !appInfo.appId.isEmpty
    }

    // 判断是否需要展示打开应用，判断条件是两个，1:类型正确 2：有用于打开的URL
    func showH5() -> Bool {
        guard let appInfo = appDetailInfo else { return false }
        var hasUrl = !appInfo.appUrl.isEmpty
        if let h5Applink = appInfo.h5Applink, !h5Applink.isEmpty {
            hasUrl = true
        }
        return hasAppType(appType: .h5) && hasUrl
    }
    func showApp() -> Bool {
        guard let appInfo = appDetailInfo else { return false }
        return hasAppType(appType: .gadget) && !appInfo.appUrl.isEmpty
    }

    // 是否显示举报入口：套件机器人没有appId，不显示入口
    func showReport() -> Bool {
        let reportId = appDetailInfo?.appId ?? appId
        /// 原来最后面判断的是非海外环境，现在替换为 isFeishuBrand
        return !reportId.isEmpty && reportEnabled && (AppDetailUtils(resolver: resolver).internalDependency?.isFeishuBrand) ?? false
    }
}

struct FeedbackConfig {
    static let ConfigName = "op_feedback_config"

    let baseAppLink: String
    let applyToAll: Bool
    let appIdWhiteList: [String]

    struct ConfigKey {
        static let applink = "feedback_applink"
        static let applyAll = "open_to_all"
        static let appWhiteList = "app_white_list"
    }

    init?(config: [String: Any]) {
        guard let applink = config[ConfigKey.applink] as? String, applink != "" else {
            return nil
        }

        self.baseAppLink = applink

        if let applyAll = config[ConfigKey.applyAll] as? NSString {
            self.applyToAll = applyAll.integerValue != 0
        } else if let applyAll = config[ConfigKey.applyAll] as? NSNumber {
            self.applyToAll = applyAll.boolValue
        } else {
            self.applyToAll = false
        }

        if let appWhiteList = config[ConfigKey.appWhiteList] as? [String] {
            appIdWhiteList = appWhiteList.filter({$0 != ""})
        } else {
            self.appIdWhiteList = []
        }
    }
}
