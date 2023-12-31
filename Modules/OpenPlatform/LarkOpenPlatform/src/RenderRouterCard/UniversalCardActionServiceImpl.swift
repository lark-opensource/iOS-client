//
//  UniversalCardActionServiceImpl.swift
//  LarkOpenPlatform
//
//  Created by zhujingcheng on 10/19/23.
//

import Foundation
import RxSwift
import LarkContainer
import LKCommonsLogging
import EEMicroAppSDK
import UniversalCardInterface
import RenderRouterInterface
import UniverseDesignToast
import LarkSDKInterface
import LarkModel
import RustPB
import LarkAppLinkSDK
import LarkMessengerInterface

enum CardActionError: Error {
    case urlInvalid
    case urlUnSupport
    case frequencyLimit
    case openMicroAppWithoutCardID
    case openMicroAppWithoutTriggerCode
    case internalError(String)
    case actionNotAllow
    case lastActionNotFinished
    case actionIDNil
    case requestError(Error)
    case requestTimeout
}

enum CardActionErrorCode: Int {
    case networkError = 1
    case unKnownError = 2
    case customError = 100
}

final class UniversalCardActionServiceImpl {
    private struct Config {
        static let openLinkInterval: TimeInterval = 0.5
    }
    
    private let logger: Log
    
    private weak var dependency: UniversalCardActionDependency?
    private weak var monitor: UniversalCardActionServiceMonitor?
    
    private let userResolver: UserResolver?
    private var chatterAPI: ChatterAPI?
    private var microAppService: MicroAppService?
    private var opService: OpenPlatformService?
    
    private var lastOpenLinkTime: Date?
    private var urlAppendTriggerCode: (
        (String, String, @escaping (String) -> Void) -> Void
    )? { opService?.urlWithTriggerCode }
    private let disposeBag = DisposeBag()
    
    init(userResolver: UserResolver?, dependency: UniversalCardActionDependency?, monitor: UniversalCardActionServiceMonitor, logger: Log) {
        self.userResolver = userResolver
        self.dependency = dependency
        self.monitor = monitor
        self.logger = logger
        
        chatterAPI = try? userResolver?.resolve(assert: ChatterAPI.self)
        microAppService = try? userResolver?.resolve(assert: MicroAppService.self)
        opService = try? userResolver?.resolve(assert: OpenPlatformService.self)
    }
    
    func openUrl(
        context: UniversalCardActionContext,
        id: String?,
        urlStr: String?,
        from vc: UIViewController,
        callback: ((Error?) -> Void)?
    ) {
        logger.info("OpenUrl urlStr:\(urlStr?.safeURLString ?? "")", additionalData: ["traceID": context.trace.traceId])
        guard let urlStr = urlStr, let url = possibleURL(context: context, urlStr) else {
            logger.error("OpenUrl with invalid url", additionalData: ["traceID": context.trace.traceId])
            monitor?.createMonitor(code: EPMClientOpenPlatformCardCode.messagecard_url_open_unsupport,
                          trace: context.trace,
                          cardID: id,
                          startTime: nil,
                          componentTag: context.elementTag)
                .setError(CardActionError.urlInvalid)
                .flush()
            callback?(CardActionError.urlInvalid)
            return
        }
        guard !url.absoluteString.lowercased().hasPrefix("lark://msgcard/unsupported_action") else {
            showToast(context: context, type: .error, text: BundleI18n.LarkOpenPlatform.Lark_Legacy_MsgCardUnsupportedActionMobile)
            logger.info("OpenUrl with unsupported link", additionalData: ["traceID": context.trace.traceId])
            monitor?.createMonitor(code: EPMClientOpenPlatformCardCode.messagecard_url_open_unsupport,
                          trace: context.trace,
                          cardID: id, 
                          startTime: nil,
                          componentTag: context.elementTag)
                .setError(CardActionError.urlUnSupport)
                .flush()
            callback?(CardActionError.urlUnSupport)
            return
        }

        if let microAppService = microAppService, microAppService.canOpen(url: url.absoluteString) {
            // openMicroApp 需要有 CardID 作为入参
            guard let cardID = id else {
                openLink(context: context, url: url, from: vc, id: id, callback: callback)
                return
            }
            openMicroApp(context: context, id: cardID, url: url, from: vc,  callback: callback)
        } else {
            openLink(context: context, url: url, from: vc, id: id, callback: callback)
        }
    }
    
    func openProfile(
        context: UniversalCardActionContext,
        id: String,
        from: UIViewController
    ) {
        logger.info("openProfile with id: \(id)", additionalData: ["traceID": context.trace.traceId])
        guard let dependency = self.dependency else {
            self.logger.info("OpenProfile fail because dependency is nil", additionalData: ["traceID": context.trace.traceId])
            return
        }
        dependency.openProfile(chatterID: id, from: from)
    }
    
    func fetchUsers(
        context: UniversalCardActionContext,
        ids: [String],
        callback: @escaping (Error?, [String: UniversalCardPersonInfo]?) -> Void
    ) {
        logger.info("fetchUsers with ids: \(ids)", additionalData: ["traceID": context.trace.traceId])
        var personInfos: [String : UniversalCardPersonInfo] = [:]
        chatterAPI?.getChatters(ids: ids).subscribe(
            onNext: { chatters in
                chatters.forEach { (key: String, value: Chatter) in
                    personInfos[key] = UniversalCardPersonInfo(
                        name: value.name,
                        avatarKey: value.avatarKey
                    )
                }
                callback(nil, personInfos)
            },
            onError: { error in
                callback(error, nil)
            }
        ).disposed(by: disposeBag)
    }
    
    func showToast(
        context: UniversalCardActionContext,
        type: UDToastType,
        text: String,
        on view: UIView? = nil
    ) {
        logger.info("showToast with type: \(type), text: \(text)", additionalData: ["traceID": context.trace.traceId])
        DispatchQueue.main.async {
            guard let targetView = view ?? self.userResolver?.navigator.mainSceneWindow?.fromViewController?.view else {
                self.logger.error("showToast fail: currentVC or targetView is nil", additionalData: ["traceID": context.trace.traceId])
                return
            }
            let toastConfig = UDToastConfig(toastType: type, text: text, operation: nil)
            UDToast.showToast(with: toastConfig, on: targetView)
        }
        // 对于转发消息,点击后需要立刻埋点
        // TODO: 目前由于 lynx 侧没开埋点口, 但转发是在 lynx 处理的,所以通过 toast 埋点 后续整体优化埋点时统一处理.
        if text == BundleI18n.LarkOpenPlatform.Lark_Legacy_forwardCardToast {
            monitor?.trackUniversalCardClick(actionType: .interaction, elementTag: context.elementTag, cardID: nil, url: nil)
        }
    }
    
    func showImagePreview(
        context: UniversalCardActionContext,
        properties: [RustPB.Basic_V1_RichTextElement.ImageProperty],
        index: Int,
        from: UIViewController
    ) {
        logger.info("ShowImagePreview with index: \(index)", additionalData: ["traceID": context.trace.traceId])
        guard let dependency = dependency else {
            self.logger.info("ShowImagePreview fail because dependency is nil", additionalData: ["traceID": context.trace.traceId])
            return
        }
        dependency.showImagePreview(properties: properties, index: index, from: from)
    }
    
    func dealWithActionResponseLink(context: UniversalCardActionContext, res: Openplatform_V1_PutUniversalCardActionResponse, cardID: String?, callback:((Error?) -> Void)?) {
        guard res.hasURL else { return }
        logger.info("dealWithActionResponseLink", additionalData: ["traceID": context.trace.traceId])
        guard let url = possibleURL(context:context, res.url.hasIosURL ? res.url.iosURL : res.url.url) else {
            self.logger.error("dealWithActionResponseLink with invalid urlStr", additionalData: ["traceID": context.trace.traceId])
            monitor?.createMonitor(code: EPMClientOpenPlatformCardCode.messagecard_url_open_unsupport,
                          trace: context.trace,
                          cardID: cardID,
                          startTime: nil,
                          componentTag: context.elementTag)
                .setError(CardActionError.urlInvalid)
                .flush()
            callback?(CardActionError.urlInvalid)
            return
        }
        openLink(context: context, url: url, from: nil, id: cardID, callback: callback)
    }
    
    func openCodeBlockDetail(context: UniversalCardActionContext, property: Basic_V1_RichTextElement.CodeBlockV2Property, from: UIViewController) {
        logger.info("openCodeBlockDetail", additionalData: ["traceID": context.trace.traceId])
        let body = CodeDetailBody(property: property)
        userResolver?.navigator.present(body: body, from: from)
    }
}

extension UniversalCardActionServiceImpl {
    // 强制转换 URL String -> URL, 符合 RFC 协议
    fileprivate func possibleURL(context: UniversalCardActionContext, _ urlStr: String) -> URL? {
        do {
            return try URL.forceCreateURL(string: urlStr)
        } catch let error {
            logger.error("forceCreateURL fail with error:\(error)")
            return nil
        }
    }

    // 打开小程序
    fileprivate func openMicroApp(context: UniversalCardActionContext, id: String, url: URL, from: UIViewController, callback:((Error?) -> Void)?) {
        logger.info("openMicroApp url with type: \(context)")
        guard let urlAppendTriggerCode = urlAppendTriggerCode else {
            logger.error("openMicroApp url fail: urlAppendTriggerCode is nil")
            monitor?.createMonitor(code: EPMClientOpenPlatformCardCode.messagecard_url_open_without_triggercode,
                          trace: context.trace,
                          cardID: id,
                          startTime: nil,
                          componentTag: context.elementTag)
                .setError(CardActionError.openMicroAppWithoutTriggerCode)
                .flush()
            self.openLink(context: context, url: url, from: from, id: id, callback: callback)
            return
        }
        urlAppendTriggerCode(url.absoluteString, id) { [weak self] (urlWithCodeStr) in
            guard let self = self else {
                self?.logger.error("openMicroApp url fail self is nil")
                callback?(CardActionError.internalError("self is nil"))
                return
            }
            // 拼接后的字符串与处理前一样,则证明拼接失败(这个设计不好, 从老逻辑照搬, 待重构)
            if urlWithCodeStr == url.absoluteString {
                self.logger.error("openMicroApp url urlAppendTriggerCode fail")
                self.monitor?.createMonitor(code: EPMClientOpenPlatformCardCode.messagecard_url_open_without_triggercode,
                                   trace: context.trace,
                                   cardID: id,
                                   startTime: nil,
                                   componentTag: context.elementTag)
                    .setError(CardActionError.openMicroAppWithoutTriggerCode)
                    .flush()
            }
            self.openLink(context: context, url: url, from: from, id: id, callback: callback)
        }
    }

    // 打开链接
    fileprivate func openLink(context: UniversalCardActionContext, url: URL, from vc: UIViewController?, id: String?, callback:((Error?) -> Void)?){
        logger.info("openLink with url: \(String(describing: url.host)), context: \(context)", additionalData: ["url": url.safeURLString, "traceID": context.trace.traceId])
        guard let httpUrl = url.lf.toHttpUrl() else {
            logger.error("openLink open link with invalid url \(url.safeURLString)")
            monitor?.createMonitor(code: EPMClientOpenPlatformCardCode.messagecard_url_open_unsupport,
                          trace: context.trace,
                          cardID: id,
                          startTime: nil,
                          componentTag: context.elementTag)
                .setError(CardActionError.urlInvalid)
                .flush()
            callback?(CardActionError.urlInvalid)
            return
        }
        
        guard let targetVC = vc ?? userResolver?.navigator.mainSceneWindow?.fromViewController else {
            logger.error("openLink fail: currentVC or targetView is nil", additionalData: ["traceID": context.trace.traceId])
            monitor?.createMonitor(code: EPMClientOpenPlatformCardCode.messagecard_from_vc_error,
                          trace: context.trace,
                          cardID: id,
                          startTime: nil,
                          componentTag: context.elementTag)
                .setError(CardActionError.internalError("currentVC or targetView is nil"))
                .flush()
            return
        }

        if let lastOpenTime = lastOpenLinkTime, Date().timeIntervalSince(lastOpenTime) < Self.Config.openLinkInterval {
            logger.info("openLink interval limit", additionalData: ["url": url.safeURLString, "traceID": context.trace.traceId])
            monitor?.createMonitor(code: EPMClientOpenPlatformCardCode.messagecard_url_open_url_limt_interval,
                          trace: context.trace,
                          cardID: id,
                          startTime: nil,
                          componentTag: context.elementTag)
                .setError(CardActionError.internalError("interval limit"))
                .flush()
            callback?(CardActionError.frequencyLimit)
            return
        }

        var fromContext: [String: String] = [:]
        if let from = context.actionFrom { fromContext = createLinkFromContext(context: context, type: from) }
        logger.info("openLink success", additionalData: ["url": url.safeURLString, "traceID": context.trace.traceId])
        monitor?.createMonitor(code: EPMClientOpenPlatformCardCode.messagecard_open_url_success,
                      trace: context.trace,
                      cardID: id,
                      startTime: nil,
                      componentTag: context.elementTag)
            .flush()
        DispatchQueue.main.async {
            self.userResolver?.navigator.push(httpUrl, context: fromContext, from: targetVC)
        }
        lastOpenLinkTime = Date()
        callback?(nil)
        monitor?.trackUniversalCardClick(actionType: .openLink, elementTag: context.elementTag, cardID: id, url: url.absoluteString)
    }

    // Link 的 Context 生成逻辑
    // 此代码抄自 CardContext, 存在历史包袱请勿随意修改
    fileprivate func createLinkFromContext(context: UniversalCardActionContext, type: UniversalCardLinkFromType) -> [String: String] {
        guard let dependency = dependency else {
            logger.info("createLinkFromContext fail because dependency is nil", additionalData: ["traceID": context.trace.traceId])
            return [:]
        }
        var fromContext: [String: String] = [:]
        var scene: String = ""
        switch dependency.getCardLinkScene() {
            case .topic:
                switch type {
                case .cardLink:
                    scene = FromScene.topic_cardlink.rawValue
                case .innerLink:
                    scene = FromScene.topic_innerlink.rawValue
                case .footerLink:
                    scene = FromScene.app_flag_cardlink.rawValue
                @unknown default:
                    logger.error("createLinkFromContext fail scene topic get wrong sceneType")
                }
            case .single:
                switch type {
                case .cardLink:
                    scene = FromScene.single_cardlink.rawValue
                case .innerLink:
                    scene = FromScene.single_innerlink.rawValue
                case .footerLink:
                    scene = FromScene.app_flag_cardlink.rawValue
                @unknown default:
                    logger.error("createLinkFromContext fail scene single get wrong sceneType")
                }
            case .multi:
                switch type {
                case .cardLink:
                    scene = FromScene.multi_cardlink.rawValue
                case .innerLink:
                    scene = FromScene.multi_innerlink.rawValue
                case .footerLink:
                    scene = FromScene.app_flag_cardlink.rawValue
                @unknown default:
                    logger.error("createLinkFromContext fail scene multi get wrong sceneType")
                }
            case .none, .some:
                logger.error("createLinkFromContext fail get wrong sceneType")
        }
        fromContext[FromSceneKey.key] = scene
        fromContext["scene"] = "messenger"
        fromContext["location"] = "messenger_chat_shared_link_card"
        return fromContext
    }
}
