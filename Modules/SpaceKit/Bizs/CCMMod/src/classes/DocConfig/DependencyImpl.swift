//
//  DependencyImpl.swift
//  LarkWeb
//
//  Created by liuwanlin on 2018/7/7.
//
//  swiftlint:disable file_length type_body_length

import Foundation
import RxSwift
import RxCocoa
import LarkRustClient
import LarkContainer
import LarkModel
import Swinject
import EENavigator
import LarkUIKit
import Kingfisher
import LKCommonsLogging
import RoundedHUD
import Reachability
import SpaceKit
import LarkAccountInterface
import LarkFeatureGating
import LarkAppConfig
import LarkSetting

#if MessengerMod
import LarkMessengerInterface
import LarkSDKInterface
import LarkSendMessage
import LarkSearch
import LarkQRCode
import LarkTab
#endif

#if ByteViewMod
import ByteViewInterface
#endif

import LarkLeanMode
import SKCommon
import SpaceInterface
import CookieManager
import LarkWaterMark
import RustPB
import LarkKAFeatureSwitch
import SKInfra

public final class DocsDependencyImpl: DocsDependency {
    let resolver: Resolver

    init(resolver: Resolver) {
        self.resolver = resolver
        #if MessengerMod
        self.docAPI = resolver.resolve(DocAPI.self)!
        #endif
    }

    public func open(url: URL) -> UIViewController? {
        return Navigator.shared.response(for: url).resource as? UIViewController
    }

    #if MessengerMod
    public let docAPI: DocAPI
    #endif
}

class DocsFactoryDependencyImpl: DocsFactoryDependency {

    private let reach = Reachability()!

    static let logger = Logger.log(DocsFactoryDependencyImpl.self, category: "doc.factory.dependency.impl")

    let resolver: Resolver

    let disposeBag = DisposeBag()

    init(resolver: Resolver) {
        self.resolver = resolver
    }

    var isLogin: Bool? {
        let passportService = try? resolver.resolve(assert: PassportService.self)
        let hasForegroundUser = passportService?.foregroundUser != nil
        return hasForegroundUser
    }

    var token: String {
        return AccountServiceAdapter.shared.currentAccessToken
    }
    var userID: String {
        return AccountServiceAdapter.shared.currentChatterId
    }
    var tenantID: String {
        return AccountServiceAdapter.shared.currentTenant.tenantId
    }
    var deviceID: String {
        return resolver.resolve(DeviceService.self)!.deviceId
    }

    var userDomain: String {
        var prefix = AccountServiceAdapter.shared.foregroundUser?.tenant.tenantDomain ?? ""
        if prefix.isEmpty {
            // 获取 tenantCode 失败（小C用户），用 www 兜底
            prefix = "www"
        }
        return "\(prefix).\(docsMainDomain)"
    }

    var docsApiDomain: String {
        return domain(of: .docsApi)
    }

    var docsHomeDomain: String {
        return domain(of: .docsHome)
    }

    var internalApiDomain: String {
        return domain(of: .internalApi)
    }

    var docsHelpDomain: String {
        return domain(of: .helpDocument)
    }

    var docsLongConDomain: [String] {
        var domains: [String] = domainArray(of: .docsFrontier)
        let defaultDomain = ["ccm-frontier.feishu.cn"]
        let isDefault = domains == defaultDomain
        if domains.isEmpty || isDefault {
            DocsFactoryDependencyImpl.logger.error("【LongConDomain】DocsFrontier.count = 0, isDefault=\(isDefault)")
            domains = domainArray(of: .docsLong)
        }
        return domains
    }

    var docsMainDomain: String {
        return domain(of: .docsMainDomain)
    }

    var suiteMainDomain: String {
        return domain(of: .suiteMainDomain)
    }
    var docsFeResourceUrl: String {
        return domain(of: .docsFeResourceUrl)
    }

    var docsDriveDomain: String {
        return domain(of: .docsDrive)
    }

    var tnsReportDomain: [String] {
        return domainArray(of: .tnsReport)
    }
    
    var tnsLarkReportDomain: [String] {
        return domainArray(of: .tnsLarkReport)
    }
    
    var helpCenterDomain: String {
        return domain(of: .helpCenter)
    }
    
    var suiteReportDomain: String {
        return domain(of: .suiteReport)
    }
    
    var mpAppLinkDomain: String {
        return domain(of: .mpApplink)
    }

    #if MessengerMod
    var userAppConfig: UserAppConfig {
        return resolver.resolve(UserAppConfig.self)!
    }

    var docAPI: DocAPI {
        return resolver.resolve(DocAPI.self)!
    }

    var feedAPI: FeedAPI {
        return resolver.resolve(FeedAPI.self)!
    }
    
    var groupGuideAddTabProvider: GroupGuideAddTabProvider? {
        return resolver.resolve(GroupGuideAddTabProvider.self)
    }
    #endif

    var docsDependency: DocsDependency {
        return resolver.resolve(DocsDependency.self)!
    }

    var rustService: RustService {
        return resolver.resolve(RustService.self)!
    }

    var globalWatermarkOn: Observable<Bool> {
        resolver.resolve(WaterMarkService.self)!.globalWaterMarkIsShow
    }
    
    var docsMgApi: [String: [String: String]] {
        let apiArray = domainArray(of: "docs_mg_api")
        
        //解析数据例子
        //"feishu|jp|internal-api-space-jp.feishu.cn",
        //"larksuite|sg|internal-api-space-sg.larksuite.com",
        
        var apiMap = [String: [String: String]]()
        for apiString in apiArray {
            let splitArr = apiString.components(separatedBy: "|")
            if splitArr.count > 2 {
                
                if var brand = apiMap[splitArr[0]] {
                    brand[splitArr[1]] = splitArr[2]
                    apiMap[splitArr[0]] = brand
                } else {
                    let newBrand = [splitArr[1]: splitArr[2]]
                    apiMap[splitArr[0]] = newBrand
                }
            }
        }
        
        return apiMap
    }
    
    var docsMgFrontier: [String: [String: [String]]] {
        let apiArray = domainArray(of: "docs_mg_frontier")
        
        //解析数据例子
        //"feishu|jp|ccm16-frontier-jp.feishu.cn",
        //"larksuite|sg|ccm16-frontier-sg.larksuite.com,ccm-frontier-sg.larksuite.com",
        
        var apiMap = [String: [String: [String]]]()
        for apiString in apiArray {
            let splitArr = apiString.components(separatedBy: "|")
            if splitArr.count > 2 {
                
                let barndKey = splitArr[0]
                let unitKey = splitArr[1]
                //长链域名可能存在多个，通过“,”分割
                let frontierStr = splitArr[2]
                let frontierArr = frontierStr.components(separatedBy: ",")
                
                if var brand = apiMap[barndKey] {
                    brand[unitKey] = frontierArr
                    apiMap[barndKey] = brand
                } else {
                    let newBrand = [unitKey: frontierArr]
                    apiMap[barndKey] = newBrand
                }
            }
        }
        
        return apiMap
    }
    var docsMgGeoRegex: String {
        return domain(of: "docs_mg_geo_regex")
    }
    var docsMgBrandRegex: String {
        return domain(of: "docs_mg_brand_regex")
    }

    private func domain(of alias: DomainKey) -> String {
        guard let domain = DomainSettingManager.shared.currentSetting[alias]?.first else {
            DocsFactoryDependencyImpl.logger.error("Docs get AppConfiguration domain setting failed,alias: \(alias)")
            return ""
        }
        return domain
    }

    private func domainArray(of alias: DomainKey) -> [String] {
        guard let domainArray = DomainSettingManager.shared.currentSetting[alias] else {
            DocsFactoryDependencyImpl.logger.error("Docs get AppConfiguration domainArray failed,alias: \(alias)")
            return []
        }
        return domainArray
    }

    /// 更新RN长链域名
    func updateLongDomain(trigerBlock: @escaping ([String]) -> Void) {
        let settingsPushObservable = DomainSettingManager.shared.domainObservable
        settingsPushObservable
            .observeOn(MainScheduler.instance)
            .subscribe(
                onNext: {
                    guard let longArray = DomainSettingManager.shared.currentSetting[.docsFrontier], !longArray.isEmpty else {
                        return
                    }
                    DocsFactoryDependencyImpl.logger.info("【LongConDomain】，longArrayUpdate: \(longArray)")
                    trigerBlock(longArray)
                })
            .disposed(by: disposeBag)
    }

    /// 设置Lark 传入，最终注入给RN appInfo的appkey
    func setupAppKey(trigerBlock: @escaping (String) -> Void) {
        guard let appKey = FeatureSwitch.share.config(for: .docFrontierAppKey).first, !appKey.isEmpty else {
            return
        }
        trigerBlock(appKey)
    }
    /// 注册精简模式下，定时清除本地数据的通知
    func registerLeanModeCleanPushNotification(trigerBlock: @escaping (Int64) -> Void) {
        guard let leanModeService = resolver.resolve(LeanModeService.self) else { return }
        leanModeService.dataClean.subscribe(onNext: { cleanData in
            if cleanData.cleanLevel.rawValue >= PushCleanDataResponse.CleanLevel.high.rawValue {
                trigerBlock(cleanData.dataTimeLimit)
            }
        }).disposed(by: disposeBag)
    }
    func openURL(_ url: URL?, from controller: UIViewController) {
        guard let url = url else {
            return
        }
        Navigator.shared.push(url, from: controller)
    }

    func showUserProfile(_ userId: String, fileName: String?, from controller: UIViewController, params: [String: Any]) {
        #if MessengerMod
        let body: PersonCardBody = {
            var source: RustPB.Basic_V1_ContactSource = .docs
            if let raw = params["type"] as? Int, raw == ShareDocsType.minutes.rawValue {
                source = .minutes
            }
            if let file = fileName {
                return PersonCardBody(chatterId: userId,
                                      sourceName: file,
                                      source: source)
            } else {
                return PersonCardBody(chatterId: userId, source: source)
            }
        }()
        if UIDevice.current.userInterfaceIdiom == .pad {
            Navigator.shared.present(body: body,
                                     wrap: LkNavigationController.self,
                                     from: controller,
                                     prepare: { (vc) in
                                        vc.modalPresentationStyle = .formSheet
            }, animated: true, completion: nil)
        } else {
            Navigator.shared.push(body: body, from: controller)
        }
        #endif
    }

    func showEnterpriseTopic(query: String,
                             addrId: String,
                             triggerView: UIView,
                             triggerPoint: CGPoint,
                             clientArgs: String,
                             clickHandle: ((String) -> Void)?,
                             tapApplinkHandle: ((URL) -> Void)?,
                             targetVC: UIViewController) {
#if MessengerMod
        guard let eewService = resolver.resolve(EnterpriseEntityWordService.self) else {
            return
        }
        eewService.showEnterpriseTopic(abbrId: addrId,
                                       query: query,
                                       chatId: nil,
                                       sense: .docs,
                                       targetVC: targetVC,
                                       completion: nil,
                                       clientArgs: clientArgs,
                                       passThroughAction: clickHandle,
                                       didTapApplink: tapApplinkHandle)
#endif
    }

    func dismissEnterpriseTopic() {
#if MessengerMod
        guard let eewService = resolver.resolve(EnterpriseEntityWordService.self) else {
            return
        }
        eewService.dismissEnterpriseTopic(animated: true)
#endif
    }

    func didEndEdit(_ docUrl: String, thumbNailUrl: String, chatId: String, changed: Bool, from: UIViewController, syncThumbBlock: ((PublishSubject<Any>) -> Void)?) {
        DocTrackUtil.trackChatAnnouncementNotify(edited: changed)
        guard let url = URL(string: thumbNailUrl) else { return }

        let hud = RoundedHUD.showLoading(with: BundleI18n.CCMMod.Lark_Legacy_Sending, on: from.view, disableUserInteraction: true)

        let publisObserver = PublishSubject<Any>()
        publisObserver.subscribe { (observer) in
            guard let completion = observer as? PublishSubject<Any> else { return }
            self.uploadImage(url: url, chatId: chatId, hud: hud, from: from, observer: completion)
        } onError: { (error) in
            if let docsSyncError = error as? DocThumbnailSyncer.DocThumbnailSyncerError, docsSyncError == .announcementLLegal {
                hud.showFailure(with: BundleI18n.CCMMod.Lark_Group_AnnouncementEditingIllegal(), on: from.view)
            } else {
                hud.showFailure(with: BundleI18n.CCMMod.Lark_Legacy_SendChatAnnouncementFailed, on: from.view)
            }
        }.disposed(by: disposeBag)

        syncThumbBlock?(publisObserver)
    }
    /// 发送群公告消息
    private func sendMessage(imageKey: String, imageSize: CGSize, chatId: String) {
        #if MessengerMod
        let messageSendAPI = self.resolver.resolve(SendMessageAPI.self)!
        let threadSendAPI = self.resolver.resolve(SendThreadAPI.self)!
        let chatAPI = self.resolver.resolve(ChatAPI.self)!
        guard let chat = chatAPI.getLocalChat(by: chatId) else { return }
        let title = BundleI18n.CCMMod.Lark_Legacy_GroupAnnouncement
        let content = RustPB.Basic_V1_RichText.image(imageKey, imageSize)
        if chat.chatMode == .threadV2 {
            threadSendAPI.sendPost(
                context: nil,
                to: .threadChat,
                title: title,
                content: content,
                chatId: chatId,
                isGroupAnnouncement: true,
                preprocessingHandler: nil)
        } else {
            messageSendAPI.sendPost(
                context: nil,
                title: title,
                content: content,
                parentMessage: nil,
                chatId: chatId,
                threadId: nil,
                isGroupAnnouncement: true,
                preprocessingHandler: nil,
                stateHandler: nil)
        }
        #endif
    }
    /// upload image
    private func uploadImage(url: URL, chatId: String, hud: RoundedHUD, from: UIViewController, observer: PublishSubject<Any>?) {
        let cookieService = LarkCookieManager.shared

        #if MessengerMod
        let imageAPI = self.resolver.resolve(ImageAPI.self)!
        #endif

        let modifier: AnyModifier = AnyModifier { request in
            return cookieService.processRequest(request)
        }
        ImageDownloader.default.downloadImage(with: url, options: [.requestModifier(modifier)], completionHandler: { [weak self] (result) in
            guard let `self` = self else { return }
            switch result {
            case .success(let imageResult):
                if let data = imageResult.image.pngData() {
//                    var imageCompressedSizeKb: Int64 = 0
//                    if self.reach.connection == .wifi {
//                        imageCompressedSizeKb = 500
//                    } else if self.reach.connection == .cellular {
//                        imageCompressedSizeKb = 300
//                    }
                    #if MessengerMod
                    imageAPI.uploadSecureImage(data: data, type: .post, imageCompressedSizeKb: 0)
                        .observeOn(MainScheduler.instance)
                        .subscribe(onNext: { (key) in
                            self.sendMessage(imageKey: key, imageSize: imageResult.image.size, chatId: chatId)
                            let body = ChatControllerByIdBody(chatId: chatId)
                            let rootVC = from.view.window?.rootViewController
                            Navigator.shared.push(body: body, from: from, completion: { _, _ in
                                guard let controller = UIViewController.docs.topMost(of: rootVC) else {
                                    assertionFailure("找不到topMost VC")
                                    return
                                }
                                hud.remove()
                                RoundedHUD.showSuccess(with: BundleI18n.CCMMod.Lark_Legacy_SentSuccessfully, on: controller.view)
                            })
                            observer?.onCompleted()
                        }, onError: { (error) in
                            hud.showFailure(
                                with: BundleI18n.CCMMod.Lark_Legacy_SendChatAnnouncementFailed,
                                on: from.view,
                                error: error
                            )
                            observer?.onCompleted()
                            DocsFactoryDependencyImpl.logger.error("upload chat annoucement thumb image failed", error: error)
                        }).disposed(by: self.disposeBag)
                    #endif
                } else {
                    DocsFactoryDependencyImpl.logger.error("download chat annoucement thumb image failed")
                    hud.showFailure(with: BundleI18n.CCMMod.Lark_Legacy_SendChatAnnouncementFailed, on: from.view)
                    observer?.onCompleted()
                }
            case .failure(let error):
                DocsFactoryDependencyImpl.logger.error("download chat annoucement thumb image failed", error: error)
                hud.showFailure(
                    with: BundleI18n.CCMMod.Lark_Legacy_SendChatAnnouncementFailed,
                    on: from.view
                )
                observer?.onCompleted()
            @unknown default:
                break
            }
        })
    }

    func shareImage(_ image: UIImage, from controller: UIViewController) {
        #if MessengerMod
        Navigator.shared.present(
            body: ShareImageBody(name: "", image: image),
            from: controller,
            prepare: { $0.modalPresentationStyle = .fullScreen })
        #endif
    }

    func sendDebugFile(path: String, fileName: String, vc: UIViewController) {
        #if MessengerMod
        let allowCreateGroup = false
        let multiSelect = false
        let ignoreSelf = false
        let ignoreBot = true
        let confirmDesc = ""
        let block: (([String: Any]?, Bool) -> Void) = { (dict, _) in
            guard let dict = dict else { return }
            let items = dict["items"] as? [[String: Any]]
            let chadId = items?.first?["chatid"] as? String
            if let chadId = chadId {
                let messageSendAPI = self.resolver.resolve(SendMessageAPI.self)
                messageSendAPI?.sendFile(context: nil,
                                             path: path,
                                             name: fileName,
                                             parentMessage: nil,
                                             removeOriginalFileAfterFinish: false,
                                             chatId: chadId,
                                             threadId: nil,
                                             stateHandler: nil)
            }
        }
        let body = ChatChooseBody(allowCreateGroup: allowCreateGroup,
                                  multiSelect: multiSelect,
                                  ignoreSelf: ignoreSelf,
                                  ignoreBot: ignoreBot,
                                  selectType: 0,
                                  confirmTitle: "",
                                  confirmDesc: confirmDesc,
                                  showInputView: false,
                                  callback: block)
        Navigator.shared.present(body: body, from: vc, prepare: { $0.modalPresentationStyle = .fullScreen })
        #endif
    }

    func scanQR(_ code: String, from: UIViewController) {
        #if MessengerMod
        let status: (HandleStatus, (() -> Void)?) -> Void = { (status, callback) in
            switch status {
            case .preFinish:
                break
            case .fail(errorInfo: let errorInfo):
                if let errorInfo = errorInfo {
                    RoundedHUD.showFailure(with: errorInfo, on: from.view.window ?? from.view)
                }
            }
            callback?()
        }
        resolver.resolve(QRCodeAnalysisService.self)!.handle(code: code, status: status, from: .pressImage, fromVC: from)
        #endif
    }

    func markFeedCardShortcutHandle(for feedId: String,
                                    isAdd: Bool,
                                    type: RustPB.Basic_V1_Channel.TypeEnum,
                                    success: ((_ tips: String) -> Void)?,
                                    failure: ((_ error: Error) -> Void)?) {
        let isShortcut = !isAdd
        markFeedCardShortcut(feedId: feedId, isShortcut: isShortcut, type: type, onSuccess: success, onFailed: failure)
    }

    public func isFeedCardShortcut(feedId: String) -> Bool {
        #if MessengerMod
        let feedSyncModule = resolver.resolve(FeedSyncDispatchServiceForDoc.self)!
        let isShortcut = feedSyncModule.isFeedCardShortcut(feedId: feedId)
        return isShortcut
        #else
        return false
        #endif
    }

    func fetchLarkFeatureGating(with key: String, isStatic: Bool, defaultValue: Bool) -> Bool? {
        // Will cause a crash before DocsSDK is initialized
        if isStatic {
            return LarkFeatureGating.shared.getStaticBoolValue(for: key, defaultValue: defaultValue)
        } else {
            return LarkFeatureGating.shared.getFeatureBoolValue(for: key, defaultValue: defaultValue)
        }
    }

    func checkVCIsRunning() -> Bool {
        #if ByteViewMod
        return (try? resolver.resolve(assert: MeetingService.self))?.currentMeeting?.isActive == true
        #else
        return false
        #endif
    }

    func checkIsSearchMainContainerViewController(responder: UIResponder) -> Bool {
        #if MessengerMod
        return (responder is SearchRootViewController)
        #else
        return false
        #endif
    }
    
    func createGroupGuideBottomView(docToken: String, docType: String, templateId: String, chatId: String, fromVC: UIViewController?) -> UIView {
#if MessengerMod
        guard let provider = groupGuideAddTabProvider else {
            DocsFactoryDependencyImpl.logger.error("Docs get groupGuide provider failed")
            return UIView()
        }
        return provider.createView(docToken: docToken, docType: docType, templateId: templateId, chatId: chatId, fromVC: fromVC)
#else
        return UIView()
#endif
    }
}

/// Groub Announcement 新流程 API
extension DocsFactoryDependencyImpl {

    func showPublishAlert(params: AnnouncementPublishAlertParams) {

        #if MessengerMod
        DocTrackUtil.trackChatAnnouncementNotify(edited: params.changed)
        guard let url = URL(string: params.thumbnailUrl) else { return }
        guard let groupAnnouncementService = self.resolver.resolve(GroupAnnouncementService.self) else {
            return
        }
        // 生成获取群公告信息
        let getInfoHandler: (@escaping GetGroupAnnouncementInfoClosure) -> Void = { [weak self] getInfoClosure in
            guard let self = self else { return }
            func _uploadThumbnailToMessageServer() {
                self.uploadThumbnailToMessageServer(url: url, chatId: params.chatId) { result in
                    switch result {
                    case let .success(imageKey, imageSize):
                        let richText = RustPB.Basic_V1_RichText.image(imageKey, imageSize)
                        getInfoClosure(.success(chatId: params.chatId, richText: richText, title: BundleI18n.CCMMod.Lark_Legacy_GroupAnnouncement))
                    case let .fail(error):
                        getInfoClosure(.fail(error, BundleI18n.CCMMod.Lark_Legacy_SendChatAnnouncementFailed))
                    }
                }
            }

            /// 没有改动就不用重新生成缩略图
            if !params.changed {
                _uploadThumbnailToMessageServer()
                return
            }
            /// 有改动就需要重新生成缩略图
            DocThumbnailSyncer.syncDocThumbnail(objToken: params.objToken) { error in
                if let er = error {
                    if let docsSyncError = error as? DocThumbnailSyncer.DocThumbnailSyncerError, docsSyncError == .announcementLLegal {
                        getInfoClosure(.fail(nil, BundleI18n.CCMMod.Lark_Group_AnnouncementEditingIllegal()))
                    } else {
                        getInfoClosure(.fail(nil, BundleI18n.CCMMod.Lark_Legacy_SendChatAnnouncementFailed))
                    }
                } else {
                    _uploadThumbnailToMessageServer()
                }
            }
        }

        // 调用 Message 的弹窗接口。
        let uiConfig = SendAlertSheetUIConfig(fromController: params.fromVc, actionView: params.targetView)
        groupAnnouncementService.showSendAlertSheetIfNeed(chatId: params.chatId,
                                                          uiConfig: uiConfig,
                                                          extra: [:],
                                                          getInfoHandler: getInfoHandler,
                                                          completion: nil)
        #endif
    }

    enum UploadThumbnailResult {
        case success(imageKey: String, imageSize: CGSize)
        case fail(error: Error?)
    }

    private func uploadThumbnailToMessageServer(url: URL, chatId: String, completion: @escaping (UploadThumbnailResult) -> Void) {
        #if MessengerMod
        guard let imageAPI = self.resolver.resolve(ImageAPI.self) else {
            DocsFactoryDependencyImpl.logger.error("imageAPI not register")
            return
        }
        let cookieService = LarkCookieManager.shared
        let modifier: AnyModifier = AnyModifier { request in
            return cookieService.processRequest(request)
        }
        ImageDownloader.default.downloadImage(with: url, options: [.requestModifier(modifier)], completionHandler: { [weak self] (result) in
            guard let `self` = self else { return }
            switch result {
            case .success(let imageResult):
                if let data = imageResult.image.pngData() {
                    imageAPI.uploadSecureImage(data: data, type: .post, imageCompressedSizeKb: 0)
                        .observeOn(MainScheduler.instance)
                        .subscribe(onNext: { (key) in
                            completion(.success(imageKey: key, imageSize: imageResult.image.size))
                        }, onError: { (error) in
                            completion(.fail(error: error))
                            DocsFactoryDependencyImpl.logger.error("upload chat annoucement thumb image failed", error: error)
                        }).disposed(by: self.disposeBag)

                } else {
                    DocsFactoryDependencyImpl.logger.error("download chat annoucement thumb image failed")
                    completion(.fail(error: nil))
                }
            case .failure(let error):
                DocsFactoryDependencyImpl.logger.error("download chat annoucement thumb image failed", error: error)
                completion(.fail(error: error))
            @unknown default:
                break
            }
        })
        #endif
    }
}

#if MessengerMod
public final class AskOwnerDependencyImpl: AskOwnerDependency {
    public func openAskOwnerView(body: AskOwnerBody, from: UIViewController?) {
        guard let from = from else { return }
        Navigator.shared.present(body: body, from: from, animated: false)
    }
}
#endif

#if MessengerMod
public final class DocPermissionDependencyImpl: DocPermissionDependency {

    let resolver: Resolver
    var docPermissionImpl: DocPermissionProtocol

    init(resolver: Resolver) {
        self.resolver = resolver
        self.docPermissionImpl = resolver.resolve(DocPermissionProtocol.self)!
    }

    public func deleteCollaborators(type: Int, token: String, ownerID: String, ownerType: Int, permType: Int, complete: @escaping (Swift.Result<Void, Error>) -> Void) {
        docPermissionImpl.deleteCollaborators(type: type, token: token, ownerID: ownerID, ownerType: ownerType, permType: permType, complete: complete)
    }
}
#endif
