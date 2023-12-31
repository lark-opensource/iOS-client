//
//  ShareHandler.swift
//  LarkOpenPlatform
//
//  Created by Meng on 2021/1/8.
//

import Foundation
import EENavigator
import LarkShareContainer
import LarkUIKit
import RxSwift
import LarkContainer
import LarkModel
import LarkSDKInterface
import LKCommonsLogging
import RoundedHUD
import LarkOPInterface
import RustPB
import NewLarkDynamic
import WidgetKit
import LarkSetting
import LarkOPInterface
import LarkNavigator
import LarkAccountInterface
import LarkFoundation
import OPFoundation
import SwiftyJSON

class OPShareHandler: UserTypedRouterHandler {
    @ScopedProvider private var client: OpenPlatformHttpClient?
    @ScopedProvider private var dependency: OpenPlatformDependency?

    static let logger = Logger.log(OPShareHandler.self, category: "OPShare")

    /// [appId: response]
    private var shareAppInfoCache: [String: GetShareAppInfoResponse] = [:]

    /// [originLink: shortLink]
    private var shortLinkCache: [String: String] = [:]
    
    private static var service: ECONetworkService {
        return Injected<ECONetworkService>().wrappedValue
    }

    func handle(_ body: OPShareBody, req: EENavigator.Request, res: Response) {
        OPMonitor(EPMClientOpenPlatformShareCode.share_entry_start)
            .addMap(body.monitorData)
            .flush()
        ShareTracker.clickShareEntry(appId: body.appId, from: body.from, opTracking: body.opTracking)
        Self.logger.info("shareHandler build ShareContainterBody")
        var title = BundleI18n.OpenPlatformShare.OpenPlatform_Share_ShareTtl
        switch body.shareType {
        case let .h5(h5Content):
            title = h5Content.title ?? BundleI18n.OpenPlatformShare.OpenPlatform_ShareWebApp_SharePageTtl
        default: break
        }
        
        let containerBody = LarkShareContainterBody(
            title: title,
            selectedShareTab: .viaChat,
            circleAvatar: false,
            contentProvider: { [weak self]tabType in
                guard let self = self else {
                    Self.logger.error("shareHandler deinit but call contentProvider")
                    return .just(.none)
                }
                return self.buildShareContent(body: body, tabType: tabType)
            },
            tabMaterials: buildTabMaterials(body),
            lifeCycleObserver: { [weak self](event, tabType) in
                self?.lifeCycleHandler(event: event, tabType: tabType, body: body)
            }
        )
        if let from = (req.context[ContextKeys.from] as? NavigatorFromWrapper)?.from {
            userResolver.navigator.present(
                body: containerBody,
                wrap: LkNavigationController.self,
                from: from,
                prepare: { $0.modalPresentationStyle = .formSheet }
            )
        } else {
            Self.logger.error("handler present opShare failed because no from parameter")
        }
        res.end(resource: EmptyResource())
    }
}

// MARK: - build content
extension OPShareHandler {
    private func buildShareContent(
        body: OPShareBody, tabType: ShareTabType
    ) -> Observable<TabContentMeterial> {
        Self.logger.info("shareHandler start build share content", additionalData: [
            "tabType": "\(tabType.rawValue)",
            "appId": "\(body.appId)",
            "skip": "\(tabType.skipContent)"
        ])
        /// 默认跳过的类型
        if tabType.skipContent {
            Self.logger.info("shareHandler build share content skip")
            return .just(.none)
        }
        if body.from != ShareFromType.shareH5API.rawValue {
            let shareInfo = buildShareInfo(body: body, tabType: tabType)
            let shortLinkInfo = buildShortLinkInfo(body: body, tabType: tabType)
            return Observable
                .of(shareInfo, shortLinkInfo)
                .merge()
                .catchError({ error in
                    Self.logger.error("shareHandler build merge info fail")
                    let errorMaterial = ErrorStatusMaterial(errorTipMsg: BundleI18n.OpenPlatformShare.AppDetail_Share_Share_Fail)
                    return .just(.error(errorMaterial))
                })
        } else {
            return buildShortLinkInfo(body: body, tabType: tabType)
                .catchError({ error in
                    Self.logger.error("shareHandler build merge info fail")
                    let errorMaterial = ErrorStatusMaterial(errorTipMsg: BundleI18n.OpenPlatformShare.AppDetail_Share_Share_Fail)
                    return .just(.error(errorMaterial))
                })
        }
    }

    private func buildShareInfo(
        body: OPShareBody, tabType: ShareTabType
    ) -> Observable<TabContentMeterial> {
        Self.logger.info("shareHandler will build share info", additionalData: [
            "tabType": "\(tabType.rawValue)",
            "appId": "\(body.appId)",
            "hasCacheInfo": "\(shareAppInfoCache[body.appId] != nil)"
        ])

        // 如果有缓存先走缓存
        if let infoRes = shareAppInfoCache[body.appId] {
            Self.logger.info("shareHandler build share info with cache, tabType:\(tabType.rawValue)")
            return .just(.preload(infoRes.commonInfo))
        }
        Self.logger.info("shareHandler build share info request api")
        
        let onError: (Error) -> Void = { error in
            Self.logger.error("shareHandler error: \(error)")
            OPMonitor(EPMClientOpenPlatformShareCode.share_get_app_info_failed)
                .addMap(body.monitorData)
                .setError(error)
                .flush()
        }
        let onSuccess: (GetShareAppInfoResponse) -> TabContentMeterial = { [weak self] res in
            OPMonitor(EPMClientOpenPlatformShareCode.share_get_app_info_success)
                .addMap(body.monitorData)
                .addCategoryValue("tabType", tabType.rawValue)
                .flush()
            Self.logger.info("shareHandler cache share info tabType:\(tabType.rawValue), appId:\(body.appId)")
            self?.shareAppInfoCache[body.appId] = res
            return .preload(res.commonInfo)
        }
        
        if OPNetworkUtil.basicUseECONetworkEnabled() {
            guard let url = OPNetworkUtil.getShareAppInfoURL() else {
                Self.logger.error("shareHandler get share app info url failed")
                return .just(.none)
            }
            var header: [String: String] = [APIHeaderKey.Content_Type.rawValue: "application/json"]
            if let userService = try? userResolver.resolve(assert: PassportUserService.self) {
                let sessionID: String? = userService.user.sessionKey
                header[APIHeaderKey.X_Session_ID.rawValue] = sessionID
            }
            let platform = Display.pad ? PlatformType.iPad : PlatformType.iphone
            let params: [String: Any] = [APIParamKey.lark_version.rawValue: Utils.appVersion,
                                         APIParamKey.cli_id.rawValue: body.appId,
                                         APIParamKey.platform.rawValue: platform.rawValue,
                                         APIParamKey.locale.rawValue: OpenPlatformAPI.curLanguage()]
            let networkContext = OpenECONetworkContext(trace: OPTraceService.default().generateTrace(), source: .other)
            return Observable.create { (ob) -> Disposable in
                let task = Self.service.post(url: url, header: header, params: params, context: networkContext) { [weak self] response, error in
                    if let error = error {
                        ob.onError(error)
                        return
                    }
                    guard let self = self else {
                        let selfErrorMsg = "shareHandler share app info failed because self is nil"
                        let nsError = NSError(domain: selfErrorMsg, code: -1, userInfo: nil)
                        ob.onError(nsError)
                        return
                    }
                    let logID = OPNetworkUtil.reportLog(Self.logger, response: response)
                    guard let response = response,
                          let result = response.result else {
                        let invalidMsg = "shareHandler share app info failed because response or result is nil"
                        let nsError = NSError(domain: invalidMsg, code: -1, userInfo: nil)
                        ob.onError(nsError)
                        return
                    }
                    let json = JSON(result)
                    let obj = GetShareAppInfoResponse(json: json, api: OpenPlatformAPI(path: .empty, resolver: self.userResolver))
                    obj.lobLogID = logID
                    ob.onNext(obj)
                    ob.onCompleted()
                }
                if let task = task {
                    Self.service.resume(task: task)
                } else {
                    let error = "shareHandler share app info url econetwork task failed"
                    Self.logger.error(error)
                    let nsError = NSError(domain: error, code: -1, userInfo: nil)
                    ob.onError(nsError)
                }
                return Disposables.create()
            }.map({ (res: GetShareAppInfoResponse) -> TabContentMeterial in
                return onSuccess(res)
            }).do(onError: { error in
                onError(error)
            })
        } else {
            let shareInfoAPI = OpenPlatformAPI.getShareAppInfoAPI(appId: body.appId, resolver: userResolver)
            guard let client = client else {
                Self.logger.error("shareHandler build client is nil")
                return .just(.none)
            }
            return client
                .request(api: shareInfoAPI)
                .map({ (res: GetShareAppInfoResponse) -> TabContentMeterial in
                    return onSuccess(res)
                }).do(onError: { error in
                    onError(error)
                })
        }
    }

    private func buildShortLinkInfo(
        body: OPShareBody, tabType: ShareTabType
    ) -> Observable<TabContentMeterial> {
        Self.logger.info("shareHandler will start build short link info", additionalData: [
            "appId": "\(body.appId)",
            "tabType": "\(tabType.rawValue)",
            "hasCacheShortLink": "\(shortLinkCache[body.originLink] != nil)"
        ])

        let copyCompletion = {
            OPMonitor(EPMClientOpenPlatformShareCode.share_link_copy)
                .addMap(body.monitorData)
                .flush()
            ShareTracker.shareFinish(
                appId: body.appId,
                from: body.from,
                opTracking: body.opTracking,
                status: .success,
                shareType: tabType
            )
        }
        let saveCompletion = { (success: Bool) in
            if success {
                OPMonitor(EPMClientOpenPlatformShareCode.share_qrcode_save_success)
                    .addMap(body.monitorData)
                    .flush()
            } else {
                OPMonitor(EPMClientOpenPlatformShareCode.share_qrcode_save_failed)
                    .addMap(body.monitorData)
                    .flush()
            }
            ShareTracker.shareFinish(
                appId: body.appId,
                from: body.from,
                opTracking: body.opTracking,
                status: success ? .success : .failure,
                shareType: tabType
            )
        }

        // 如果有缓存先走缓存
        if let shortLink = shortLinkCache[body.originLink] {
            Self.logger.info("shareHandler build short link info with cache，from:\(body.from)")
            let material = body.makeTabContentMaterial(
                tabType: tabType,
                shortLink: shortLink,
                copyCompletion: copyCompletion,
                saveCompletion: saveCompletion
            )
            return .just(material)
        }
        let url: URL! = URL(string:body.originLink)
        if (body.from == ShareFromType.shareH5API.rawValue) {
            return .just(body.makeTabContentMaterial(
                tabType: tabType,
                shortLink: body.originLink,
                copyCompletion: copyCompletion,
                saveCompletion: saveCompletion
            ))
        } else {
            Self.logger.info("shareHandler build short link info request api")
            
            let onError: (Error) -> Void = { error in
                Self.logger.error("shareHandler short link info error: \(error)")
                OPMonitor(EPMClientOpenPlatformShareCode.share_convert_short_link_failed)
                    .addMap(body.monitorData)
                    .setError(error)
                    .flush()
            }
            let onSuccess: (GenerateShortAppLinkResponse) -> TabContentMeterial = { res in
                Self.logger.info("shareHandler short link info success")
                OPMonitor(EPMClientOpenPlatformShareCode.share_convert_short_link_success)
                    .addMap(body.monitorData)
                    .addCategoryValue("tabType", tabType.rawValue)
                    .addCategoryValue("hasShortLink", !res.shortLink.isEmpty)
                    .flush()
                return body.makeTabContentMaterial(
                    tabType: tabType,
                    shortLink: res.shortLink,
                    copyCompletion: copyCompletion,
                    saveCompletion: saveCompletion
                )
            }
            
            if OPNetworkUtil.basicUseECONetworkEnabled() {
                guard let shortLinkURL = OPNetworkUtil.getAppLinkShortLinkV1URL() else {
                    Self.logger.error("shareHandler get short link info url failed")
                    return .just(.none)
                }
                var header: [String: String] = [APIHeaderKey.Content_Type.rawValue: "application/json"]
                var params: [String: Any] = [APIParamKey.link.rawValue: body.originLink,
                                             APIParamKey.businessTag.rawValue:"op_share",
                                             APIParamKey.expiration.rawValue:String(0)]
                let context = OpenECONetworkContext(trace: OPTraceService.default().generateTrace(), source: .other)
                return Observable.create { (ob) -> Disposable in
                    let task = Self.service.post(url: shortLinkURL, header: header, params: params, context: context) { [weak self] response, error in
                        if let error = error {
                            ob.onError(error)
                            return
                        }
                        guard let self = self else {
                            let selfErrorMsg = "shareHandler short link info failed because self is nil"
                            Self.logger.error(selfErrorMsg)
                            let nsError = NSError(domain: selfErrorMsg, code: -1, userInfo: nil)
                            ob.onError(nsError)
                            return
                        }
                        let logID = OPNetworkUtil.reportLog(Self.logger, response: response)
                        guard let response = response,
                              let result = response.result else {
                            let invalidMsg = "shareHandler short link info failed because response or result is nil"
                            Self.logger.error(invalidMsg)
                            let nsError = NSError(domain: invalidMsg, code: -1, userInfo: nil)
                            ob.onError(nsError)
                            return
                        }
                        let json = JSON(result)
                        let obj = GenerateShortAppLinkResponse(json: json, api: OpenPlatformAPI(path: .empty, resolver: self.userResolver))
                        obj.lobLogID = logID
                        ob.onNext(obj)
                        ob.onCompleted()
                    }
                    if let task = task {
                        Self.service.resume(task: task)
                    } else {
                        let error = "shareHandler short link info url econetwork task failed"
                        Self.logger.error(error)
                        let nsError = NSError(domain: error, code: -1, userInfo: nil)
                        ob.onError(nsError)
                    }
                    return Disposables.create()
                }.map({ (res: GenerateShortAppLinkResponse) -> TabContentMeterial in
                    onSuccess(res)
                }).do(onError: { error in
                    onError(error)
                })
            } else {
                let shortLinkAPI = OpenPlatformAPI.generateShortLinkAPI(
                    link: body.originLink, businessTag: "op_share", expiration: 0, resolver: userResolver
                )
                guard let client = client else {
                    Self.logger.error("shareHandler build client is nil")
                    return .just(.none)
                }
                return client
                    .request(api: shortLinkAPI)
                    .map({ (res: GenerateShortAppLinkResponse) -> TabContentMeterial in
                        onSuccess(res)
                    }).do(onError: { error in
                        onError(error)
                    })
            }
        }
    }
}

// MARK: - build tab materials
extension OPShareHandler {
    private func buildTabMaterials(_ body: OPShareBody) -> [TabMaterial] {
        Self.logger.info("shareHandler build tab materials")
        let linkTabName = ShareTabType.viaLink.tabName(for: body.shareType)
        let qrCodeTabName = ShareTabType.viaQRCode.tabName(for: body.shareType)
        return [
            .viaChat(buildChatTabMaterial(body: body)),
            .viaLink(ViaLinkTabMeterial(tabName: linkTabName)),
            .viaQRCode(ViaQRCodeTabMaterial(tabName: qrCodeTabName, canShareToExternal: true))
        ]
    }

    private func buildChatTabMaterial(body: OPShareBody) -> ViaChatTabMeterial {
        let clickShare = OPMonitor("openplatform_application_share_click")
            .addCategoryValue("application_id", body.appId)
            .addCategoryValue("scene_type", "none")
            .addCategoryValue("solution_id", "none")
            .addCategoryValue("op_tracking", body.opTracking)
            .addCategoryValue("subview", "card")
            .addCategoryValue("target", "none")
            .addCategoryValue("click", "confirm")
            .setPlatform([.tea, .slardar])
        let config = ViaChatChooseConfig(allowCreateGroup: true, multiSelect: true, ignoreSelf: false, ignoreBot: false, needSearchOuterTenant: false, includeOuterChat: false, selectType: .all, confirmTitle: BundleI18n.OpenPlatformShare.OpenPlatform_Share_ShareToTtl, confirmDesc: "", showInputView: true)
        var chatTabChoose = ShareViaChooseChatMaterial(
            config: config,
            selectHandler: {
                clickShare.addCategoryValue("type", "normal_string").flush()
                let richText: RustPB.Basic_V1_RichText?
                if $1.isNotEmpty && $1 != "" {
                    richText = RustPB.Basic_V1_RichText.text($1!)
                    Self.logger.info("shareHandler share text is not empty")
                } else {
                    richText = nil
                    Self.logger.info("shareHandler share text is empty")
                }
                return self.sendShareRichTextCard(with: $0, input:richText, body: body)
            }
        )
        chatTabChoose.selectHandlerWithShareInput = {
            clickShare.addCategoryValue("type", "rich_text").flush()
            let richText = $1?.richText
            return self.sendShareRichTextCard(with: $0, input:richText, body: body)
        }
        return ViaChatTabMeterial(
            tabName: ShareTabType.viaChat.tabName(for: body.shareType),
            material: chatTabChoose
        )
    }
}

// MARK: - requests
extension OPShareHandler {
    
    private func sendShareRichTextCard(
        with chatContexts: [ShareViaChooseChatMaterial.SelectContext],
        input: RustPB.Basic_V1_RichText?,
        body: OPShareBody
    ) -> Observable<Void> {
        Self.logger.info("shareHandler send share card", additionalData: [
            "appId": "\(body.appId)",
            "chatIds": "\(chatContexts.map({ $0.chatId }))",
        ])
        guard chatContexts != nil else {
            Self.logger.error("shareHandler send share card chatContexts is nil")
            return .just(())
        }
        guard let topView = Navigator.shared.mainSceneWindow else {
            Self.logger.error("shareHandler send share card mainSceneWindow is nil")
            return .just(())
        }
        let hud = RoundedHUD.showLoading(on: topView)
        let onNext: (() -> Void) = {
            OPMonitor(EPMClientOpenPlatformShareCode.share_card_success).addMap(body.monitorData).flush()
            ShareTracker.shareFinish(
                appId: body.appId,
                from: body.from,
                opTracking: body.opTracking,
                status: .success,
                shareType: .viaChat
            )
            let items: [[String: Any]] = chatContexts
                .map({ ["chatid": $0.chatId, "type": $0.itemType.rawValue] })
            let data: [String: Any] = ["items": items]
            Self.logger.info("shareHandler show success share toast")
            hud.showSuccess(with: BundleI18n.OpenPlatformShare.OpenPlatform_Share_ShareSuccessToast, on: topView)
            body.eventHandler?.shareCompletion?(data, false)
        }
        
        let onError: ((Error) -> Void) = {(error) in
            OPMonitor(EPMClientOpenPlatformShareCode.share_card_failed)
                .addMap(body.monitorData)
                .setError(error)
                .flush()
            ShareTracker.shareFinish(
                appId: body.appId,
                from: body.from,
                opTracking: body.opTracking,
                status: .failure,
                shareType: .viaChat
            )
            Self.logger.info("shareHandler will show fail share toast")
            Self.shareFailureToast(hud: hud, error: error)
            body.eventHandler?.shareCompletion?(nil, false)
        }
        guard let dependency: OpenPlatformDependency = self.dependency else {
            Self.logger.error("shareHandler dependency is nil")
            return .just(())
        }
        if body.from == ShareFromType.shareH5API.rawValue {
            
            return dependency.sendShareTextMessage(text: body.originLink, chatContexts: chatContexts, input: input).observeOn(MainScheduler.instance).do(onNext: {
                onNext()
            }, onError: { error in
                onError(error)
            })
            .catchErrorJustReturn(())
        } else {
            return dependency.sendShareAppRichTextCardMessage(
                type: body.shareAppCardType,
                chatContexts: chatContexts,
                input: input
            ).observeOn(MainScheduler.instance)
            .do(onNext: {
                onNext()
            }, onError: { error in
                onError(error)
            })
            .catchErrorJustReturn(())
        }
    }

    private static func shareFailureToast(hud: RoundedHUD, error: Error) {
        let failedDesc = BundleI18n.OpenPlatformShare.Lark_Legacy_ShareFailed
        guard let topView = Navigator.shared.mainSceneWindow else {
            Self.logger.error("shareHandler show fail share toast, mainSceneWindow is nil")
            return
        }
        Self.logger.info("shareHandler show fail share toast")
        if let error = error.underlyingError as? APIError {
            switch error.type {
            case .banned(let message):
                hud.showFailure(with: message, on: topView, error: error)
            default:
                hud.showFailure(with: failedDesc, on: topView, error: error)
            }
        } else {
            hud.showFailure(with: failedDesc, on: topView, error: error)
        }
    }
}


extension OPShareHandler {
    private func lifeCycleHandler(
        event: LifeCycleEvent, tabType: ShareTabType, body: OPShareBody
    ) -> Void {
        Self.logger.info("shareHandler on share event \(event.eventLogInfo), tabType:\(tabType)")
        switch event {
        case .initial:
            if case .viaChat = tabType {
                OPMonitor("openplatform_application_share_view")
                    .addCategoryValue("application_id", body.appId)
                    .addCategoryValue("scene_type", "none")
                    .addCategoryValue("solution_id", "none")
                    .addCategoryValue("op_tracking", body.opTracking)
                    .addCategoryValue("subview", "card")
                    .setPlatform(.tea)
                    .flush()
            }
            OPMonitor(EPMClientOpenPlatformShareCode.share_container_start)
                .addMap(body.monitorData)
                .flush()
        case .didDisappear:
            cleanCache(body: body) // 容器关闭，清理cache
            OPMonitor(EPMClientOpenPlatformShareCode.share_container_close)
                .addMap(body.monitorData)
                .flush()
        case .clickClose:
            ShareTracker.shareFinish(
                appId: body.appId,
                from: body.from,
                opTracking: body.opTracking,
                status: .cancel,
                shareType: tabType
            )
            body.eventHandler?.shareCompletion?(nil, true)
        case .shareSuccess:
            guard tabType == .viaQRCode || tabType == .viaLink else {
                Self.logger.info("shareHandler on share success, tabType:\(tabType)")
                return
            }
            var successMonitor: OPMonitorCodeBase
            if tabType == .viaLink {
                successMonitor = EPMClientOpenPlatformShareCode.share_link_success
            } else {
                successMonitor = EPMClientOpenPlatformShareCode.share_qrcode_success
            }
            OPMonitor(successMonitor)
                .addMap(body.monitorData)
                .setPlatform([.tea, .slardar])
                .flush()
        case .shareFailure:
            guard tabType == .viaQRCode || tabType == .viaLink else {
                Self.logger.error("shareHandler on share success, tabType:\(tabType)")
                return
            }
            var failMonitor: OPMonitorCodeBase
            if tabType == .viaLink {
                failMonitor = EPMClientOpenPlatformShareCode.share_link_failed
            } else {
                failMonitor = EPMClientOpenPlatformShareCode.share_qrcode_failed
            }
            OPMonitor(failMonitor)
                .addMap(body.monitorData)
                .setPlatform([.tea, .slardar])
                .flush()
        default:
            break
        }
    }

    private func cleanCache(body: OPShareBody) {
        /// 清理缓存
        shareAppInfoCache.removeValue(forKey: body.appId)
        shortLinkCache.removeValue(forKey: body.originLink)
    }
}
