//
//  CardContext.swift
//  LarkMessageCore
//
//  Created by qihongye on 2019/6/24.
//

import Foundation
import NewLarkDynamic
import LarkModel
import LarkMessageBase
import LarkMessengerInterface
import LKCommonsLogging
import LarkContainer
import EENavigator
import LarkNavigator
import ByteWebImage
import RxSwift
import RustPB
import LarkAlertController
import LarkUIKit
import LarkActionSheet
import SelectMenu
import LarkDatePickerView
import LarkSDKInterface
import LarkAppLinkSDK
import LarkFeatureGating
import LarkOPInterface
import LarkMessageCore
import UniverseDesignPopover
import UniverseDesignActionPanel
import UIKit
import UniverseDesignToast
import ECOProbe
import EEMicroAppSDK
import LarkFlag
import RichLabel
import LarkSetting
import LarkMessageCard

private let logger = Logger.log(DynamicContentViewModelContext.self, category: "MessageCard.ChatContext")
private let MaxPinContentHeight: CGFloat = 240.0

struct LDComponentContextCardAction: PushMessage {
    let cardType: LarkModel.CardContent.TypeEnum
    let actionID: String
    let params: [String: String]?
}

public struct CardContentI18n: NewLarkDynamic.LDComponentI18n {
    /// 「未知标签」国际化文案（用于消息卡片未知类型的组件）
    public var unknownTag: String {
        BundleI18n.LarkOpenPlatform.Lark_Legacy_UnknownMessageTypeTip()
    }
    /// 「取消」国际化文案
    public var cancelText: String {
        BundleI18n.LarkOpenPlatform.Lark_Legacy_Cancel
    }
    /// 「确认」国际化文案
    public var sureText: String {
        BundleI18n.LarkOpenPlatform.Lark_Legacy_Sure
    }
    /// 「点击无效」国际化文案
    public var unsupportedActionMobile: String {
        BundleI18n.LarkOpenPlatform.Lark_Legacy_MsgCardUnsupportedActionMobile
    }
    /// 「请在电脑上操作」 国际化文案
    public var applicationPhoneCallSendCardError: String {
        BundleI18n.LarkOpenPlatform.Lark_Legacy_ApplicationPhoneCallSendCardErrorToast
    }
    /// 公有initial方法
    public init() {}
}

// MARK: Dependency
public protocol CardContextDependency {
    /// 消息卡片 - 点击 - url添加token - 进入其他地方
    func urlWithTriggerCode(_ sourceUrl: String, _ cardMsgID: String, _ callback: @escaping (String) -> Void)
    func isRinging() -> Bool
    func hasCurrentModule() -> Bool
    func inRingingCannotJoinMeetingText() -> String
    func isInCallText() -> String
    func videoDenied() -> Bool
    func showCameraAlert()
    func audioDenied() -> Bool
    func showMicrophoneAlert()
    func setupMeegoEnv(message: LarkModel.Message)
}

final class CardContext: LDContext {
    static let logger = Logger.log(CardContext.self, category: "Module.IM.CardContext")
    public let trace: OPTrace = OPTraceService.default().generateTrace()
    static private let openLinkInterval: TimeInterval = 0.5
    let pageContext: PageContext
    private let _i18n: CardContentI18n
    private let extra: LarkModel.CardContent.ExtraType
    private var message: LarkModel.Message
    private let chat: () -> LarkModel.Chat
    private let disposebag = DisposeBag()
    private let toastManagerService: ToastManagerService
    private var urlAppendTriggerCode: ((String, String, @escaping (String) -> Void) -> Void)?
    private var lastOpenLinkTime: Date?
    private var dependency: CardContextDependency { return pageContext.resolver.resolve(CardContextDependency.self)! }
    @InjectedLazy private var microAppService: MicroAppService
    /// 传入消息被渲染的场景，主要是获取是否是合并转发的场景
    let scene: ContextScene
    public var locale: Locale {
        BundleI18n.currentLanguage
    }

    public var messageID: String {
        return message.id
    }

    public var cardType: LarkModel.CardContent.TypeEnum

    public var i18n: LDComponentI18n {
        return _i18n
    }

    public var actionFinished: Bool = true

    /// 转发的卡片标记，message.parentSourceId不为空表示是单条被转发的消息
    /// 如果是合并转发的场景中，所有的消息将是被转发的消息
    public var isForwardCardMessage: Bool {
        return !message.parentSourceId.isEmpty || self.scene == .mergeForwardDetail
    }
    /// 返回卡片的版本
    public var cardVersion: Int {
        if let cardcontent = message.content as? CardContent {
            return Int(cardcontent.version)
        }
        return 0
    }
    //获取是否24小时制
    public var is24HourTime:Bool = false

    public var selectionLabelDelegate: LKSelectionLabelDelegate?
    /// 返回卡片渲染的最大宽度
    public var cardAvailableMaxWidth: CGFloat
    /// 是否展示宽版卡片
    public var wideCardMode: Bool
    /// 主动更新宽版卡片上下文
    public var wideCardContextUpdate: (() -> (Bool, CGFloat))
    /// 记录按钮的标题的elementId
    private var buttonTextElementMap: [String: ElementContext] = [:]
    private lazy var buttonTextLock: NSLock = NSLock()
    
    private var appIDCache = Set<String>()
    ///
    public lazy var actionObsever: ActionObserver = {
        let observer = getActionService().getCardActionObserver(key: message.id)
        observer.actionStatusChange = { [weak self] in
            guard let self = self else {
                return
            }
//            self.pageContext.reloadRow(by: self.messageID)
            self.pageContext.reloadRows(by: [self.messageID]) { message in
                return message
            }
        }
        return observer
    }()
    ///获取时间配置服务
    @InjectedLazy private var timeFormatSettingService: TimeFormatSettingService
    
    public let disposeBag = DisposeBag()
    
    /// 记录按钮标题的element ID
    public func recordButtonText(elementId: String, parentElement: ElementContext) {
        buttonTextLock.lock()
        buttonTextElementMap[elementId] = parentElement
        buttonTextLock.unlock()
    }
    /// 判断是不是按钮上面的标题
    public func isButtonText(elementId: String) -> Bool {
        buttonTextLock.lock()
        defer {
            buttonTextLock.unlock()
        }
        return buttonTextElementMap.keys.contains(elementId)
    }
    /// 判断按钮上面的标题所在的元素的上下文
    public func buttonContext(subTextElementId: String) -> ElementContext {
        return buttonTextElementMap[subTextElementId] ?? ElementContext(parentElement: RichTextElement())
    }
    var transitioningDelegate: UDPopoverTransition?
    /// popover箭头颜色
    let popoverArrowColor: UIColor = .white
    /// popover箭头方向
    let popoverPermittedArrowDirections: UIPopoverArrowDirection = [.up, .down]

    //消息卡片支持复制生成key参数
    fileprivate var msgCardCopyableBaseKeyNum = 0

    deinit {
        cardlog.info(
            "CardContext deinit pageContext \(pageContext) \(ObjectIdentifier(pageContext)), message \(message.id) \(scene) \(wideCardMode)",
            additionalData: [
                "MessageID": self.messageID,
                "TraceID": trace.traceId ?? ""
            ])
    }
    
    init?(pageContext: PageContext,
                 toastManagerService: ToastManagerService,
                 message: LarkModel.Message,
                 chat: @escaping () -> LarkModel.Chat,
                 i18n: CardContentI18n,
                 scene: ContextScene,
                 cardAvailableMaxWidth: CGFloat,
                 wideCardMode: Bool,
                 wideCardContextUpdate: @escaping (() -> (Bool, CGFloat))) {
        guard let content = message.content as? LarkModel.CardContent else {
            return nil
        }
        self.toastManagerService = toastManagerService
        self.pageContext = pageContext
        self.message = message
        self.cardType = content.type
        self.extra = content.extra
        self._i18n = i18n
        self.chat = chat
        self.scene = scene
        self.cardAvailableMaxWidth = cardAvailableMaxWidth
        self.wideCardMode = wideCardMode
        self.wideCardContextUpdate = wideCardContextUpdate
        self.urlAppendTriggerCode = dependency.urlWithTriggerCode
        self.is24HourTime = timeFormatSettingService.is24HourTime
        self.selectionLabelDelegate = pageContext.pageAPI?.getSelectionLabelDelegate()
        cardlog.info("CardContext init pageContext \(pageContext) \(ObjectIdentifier(pageContext)), message \(message.id) \(scene) \(wideCardMode) actionObsever \(ObjectIdentifier(actionObsever))")
    }

    public func setupCardEnv(message: LarkModel.Message) {
        setupMeegoEnvIfNeed(message: message)
        preLoadMicroAppIfNeed(message: message)
    }
    
    private func preLoadMicroAppIfNeed(message: LarkModel.Message) {
        if let content = message.content as? CardContent,
           content.extraInfo.gadgetConfig.isPreload,
           content.extraInfo.gadgetConfig.cliIds.count > 0 {
            var cliIds =  content.extraInfo.gadgetConfig.cliIds
            let cliIdsSet = Set(cliIds)
            guard cliIdsSet != appIDCache else {
                return
            }
            appIDCache = cliIdsSet
            handleGadgetCardExposed(appIds: cliIds)
        }
    }
    
    fileprivate func handleGadgetCardExposed(appIds: [String]) {
        // todo 小程序预加载接口，需要要异步延迟加载
        CardContext.logger.info("preload microApp messageID: \(message.id)  app_ids: \(appIds)")
        // 按理应该感知具体的scene是哪个，但这里还在数据处理阶段，而真实的scene是跟点击区域有关的，因此在这里只能把潜在的scene都传过去
        //1007    从单人聊天会话中小程序消息卡片打开    移动端&PC端
        //1008    从多人聊天会话中小程序消息卡片打开    移动端&PC端
        //1009    从单人聊天会话里消息中链接或者按钮打开    移动端&PC端
        //1010    从多人聊天会话里消息中链接或者按钮打开    移动端&PC端
        //1511    消息卡片末尾应用标识链接打开小程序    移动端&PC端
        //https://open.feishu.cn/document/uYjL24iN/uQzMzUjL0MzM14CNzMTN
         NotificationCenter.default.post(name: NSNotification.Name(rawValue: "kGadgetPreRunNotificationName"),
                                         object: nil,
                                         userInfo: ["appid": appIds.last,"scenes":[1007,1009,1008,1010,1511]])

    }

    public func getCopyabelComponentKey() -> String {
        msgCardCopyableBaseKeyNum += 1
        return MessageCardSurpportCopyKey.msgCardCopyableBaseKey + String(msgCardCopyableBaseKeyNum)
    }

    private func setupMeegoEnvIfNeed(message: LarkModel.Message) {
        guard let content = message.content as? LarkModel.CardContent else {
            CardContext.logger.error("Unexpected message.content type\(message.content.self)")
            return
        }
        guard content.extraInfo.hasMeegoConfig && content.extraInfo.meegoConfig.hasIsPreload && content.extraInfo.meegoConfig.isPreload else {
            CardContext.logger
                .info("meegoConfig is nil or isPreload is false")
            return
        }
        CardContext.logger.info("Card: \(message.id) setupMeegoEnv")
        self.dependency.setupMeegoEnv(message: message)
    }
    
    public func getActionService() -> ActionService {
        guard let service = pageContext.pageContainer.resolve(ActionService.self) else {
            OPMonitor(EPMClientOpenPlatformCardCode.messagecard_action_service_fail)
                .setErrorMessage("ActionService resolve fail")
                .setResultTypeFail()
                .flush()
            CardContext.logger.error("ActionService resolve fail, check DynamicContentFactory: func registerServices")
            assertionFailure("ActionService resolve fail")
            let service = ActionServiceImpl()
            pageContext.pageContainer.register(ActionService.self) { return service }
            return service
        }
        return service
    }

    public func isMe(_ chatterID: String) -> Bool {
        return pageContext.isMe(chatterID)
    }

    public func chatType() -> ChatType {
        return chat().type
    }
    
    public func updateMessage(message: LarkModel.Message) {
        self.message = message
    }

    public func setImageProperty(
        _ imageProperty: RustPB.Basic_V1_RichTextElement.ImageProperty,
        imageView: UIImageView,
        completion: NewLarkDynamic.Completion?) {
        let key = ImageItemSet.transform(imageProperty: imageProperty).generatePostMessageKey(forceOrigin: false)
        detailLog.info("debugImagePreview setImageOrigin propertyKey \(imageProperty.originKey) imageKey \(key) for \(imageView)")
        imageView.bt.setLarkImage(with: .default(key: key), completion: {[weak self] result in
            switch result {
            case .success(let imageResult):
                let image = imageResult.image
                completion?(nil, image)
                detailLog.info("debugImagePreview setImage success propertyKey \(imageProperty.originKey) imageKey \(key)")
                CardContext.logger.info("setImageProperty success")
            case .failure(let error):
                completion?(error, nil)
                OPMonitor(MessageCardMonitorCode.messagecard_image_load_property_error)
                    .addCategoryValue(MonitorField.MessageID, self?.messageID)
                    .tracing(self?.trace)
                    .setError(error)
                    .flush()
                CardContext.logger.error("setImageProperty error \(key)", tag: "", additionalData: nil, error: error)
            }
        })
    }

    public func setImageOrigin(
        _ originImageParams: OriginalImageParams,
        placeholderImg: UIImage? = nil,
        imageView: UIImageView,
        _ completion: NewLarkDynamic.Completion?) {
        detailLog.info("debugImagePreview originImageParams imageKey \(originImageParams.key) url \(originImageParams.url) for \(imageView)")
        imageView.bt.setLarkImage(with: .default(key: originImageParams.url),
                                  placeholder: placeholderImg,
                                  completion: { [weak self] result in
            switch result {
            case .success(let imageResult):
                completion?(nil, imageResult.image)
                CardContext.logger.info("setImageOrigin success")
                detailLog.info("debugImagePreview originImageParams success propertyKey \(originImageParams.key)")
            case .failure(let error):
                completion?(error, nil)
                OPMonitor(MessageCardMonitorCode.messagecard_image_load_origin_error)
                    .addCategoryValue(MonitorField.MessageID, self?.messageID)
                    .tracing(self?.trace)
                    .setError(error)
                    .flush()
                CardContext.logger.error("setImageOrigin error", tag: "", additionalData: nil, error: error)
            }
        })
    }

    public func imagePreview(
        imageView: UIImageView,
        imageKey: String) {
        guard let content = message.content as? LarkModel.CardContent else {
            return
        }
        detailLog.info("debugImagePreview imagePreview imageKey \(imageKey) for \(imageView)")
        CardContext.logger.info("imagePreview click")
        var previewRichText = content.richText
        let result = LKDisplayAsset.createAsset(
            message: message,
            richText: previewRichText,
            imageKey: imageKey,
            isMeSend: isMe
        )
        guard !result.assets.isEmpty, let index = result.selectIndex else { return }
        CardContext.logger.info("imagePreview preview body")
        result.assets[index].visibleThumbnail = imageView
        let chat = self.chat()
        let body = PreviewImagesBody(assets: result.assets.map { $0.transform() },
                                     pageIndex: index,
                                     scene: .normal(assetPositionMap: result.assetPositionMap, chatId: chat.id),
                                     shouldDetectFile: chat.shouldDetectFile,
                                     canSaveImage: !chat.enableRestricted(.download),
                                     canShareImage: !chat.enableRestricted(.forward),
                                     canEditImage: !chat.enableRestricted(.download) || !chat.enableRestricted(.forward),
                                     showSaveToCloud: !chat.enableRestricted(.download),
                                     canTranslate: false,
                                     translateEntityContext: (message.id, .message))
        if let targetVC = self.pageContext.pageAPI {
            Navigator.shared.present(body: body, from: targetVC)
        }
    }

    public func openLink(_ url: URL, from: OpenLinkFromType, complete: ((LDCardError.ActionError?) -> Void)? = nil){
        CardContext.logger.info("openLink from: \(from), url:\(url.host)")
        reportAction("openLink", from.reason() ?? "open_link", url: url.absoluteString)
        guard !url.absoluteString.lowercased().hasPrefix("lark://msgcard/unsupported_action") else {
            toastManagerService.showToast(
                key: "",
                type: .tips,
                info: _i18n.unsupportedActionMobile
            )
            CardContext.logger.info("openLink unsupport host: \(String(describing: url.host)), from: \(from)")
            complete?(.openLinkUrlUnsupport)
            return
        }
        // 判断是否是小程序链接,小程序链接需要最佳 trigger code
        if microAppService.canOpen(url: url.absoluteString) {
            guard let urlAppendTriggerCode = urlAppendTriggerCode else {
                CardContext.logger.info("openLink urlNoTriggerCode \(String(describing: url.host)) \(from)")
                complete?(openLinkImpl(url: url, from: from) ?? .openLinkwithoutTriggercodeFunc)
                return
            }
            urlAppendTriggerCode(url.absoluteString, self.messageID) { [weak self] (urlWithCodeStr) in
                guard let self = self else {
                    CardContext.logger.info("openLink from: \(from), url:\(url.host) fail, card context is nil")
                    complete?(.openLinkFail("Card Context is nil"))
                    return
                }
                var openLinkError = self.openLinkImpl(url: url, from: from)
                // 拼接后的字符串与处理前一样,则证明拼接失败(这个设计不好, 内部待重构)
                let triggerCodeError = urlWithCodeStr == url.absoluteString ?
                    LDCardError.ActionError.openLinkWithoutTriggercode :
                    nil
                // 优先判断 OpenLink 是否正常,如果正常则判断 TriggerCode 是否正常
                complete?(openLinkError ?? triggerCodeError)
            }
        } else {
            complete?(openLinkImpl(url: url, from: from))
        }
    }

    private func openLinkImpl(
        url: URL,
        from: OpenLinkFromType
    ) -> LDCardError.ActionError? {
        CardContext.logger.info("openLinkImpl from \(from) \(String(describing: url.host))")
        guard let httpUrl = url.lf.toHttpUrl() else {
            CardContext.logger.error("messagecard open url not valid \(url.safeURLString)")
            return .openLinkUrlInvalid
        }
        var fromContext = [String: String]()
        let chatInfo = chat()
        switch from {
        case .cardLink:
            if chatInfo.chatMode == .threadV2 {
                // 主端这块目前是一个未解的遗留问题，对于 ThreadDetail场景 返回的 type 仍然是 group，这里通过 chatMode 来纠正一下，后续主端修正该问题后可移除该判断逻辑
                // https://review.byted.org/c/lark/LarkMessenger/+/1662748/2/Libs/LarkMessageCore/src/Cells/MessageCell/MessageContent/post/TextPostContentViewModel.swift#536
                fromContext = [FromSceneKey.key: FromScene.topic_cardlink.rawValue]
            } else {
                switch chatInfo.type {
                case .p2P:
                    fromContext = [FromSceneKey.key: FromScene.single_cardlink.rawValue]
                case .group, .topicGroup:
                    fromContext = [FromSceneKey.key: FromScene.multi_cardlink.rawValue]
                @unknown default:
                    assert(false, "new value")
                }
            }
            fromContext["scene"] = "messenger"
            fromContext["location"] = "messenger_chat_shared_link_card"
        case .innerLink:
            if chatInfo.chatMode == .threadV2 {
                // 主端这块目前是一个未解的遗留问题，对于 ThreadDetail场景 返回的 type 仍然是 group，这里通过 chatMode 来纠正一下，后续主端修正该问题后可移除该判断逻辑
                // https://review.byted.org/c/lark/LarkMessenger/+/1662748/2/Libs/LarkMessageCore/src/Cells/MessageCell/MessageContent/post/TextPostContentViewModel.swift#536
                fromContext = [FromSceneKey.key: FromScene.topic_innerlink.rawValue]
            } else {
                switch chatInfo.type {
                case .p2P:
                    fromContext = [FromSceneKey.key: FromScene.single_innerlink.rawValue]
                case .group, .topicGroup:
                    fromContext = [FromSceneKey.key: FromScene.multi_innerlink.rawValue]
                @unknown default:
                    assert(false, "new value")
                }
            }
        case .footerLink:
            fromContext = [FromSceneKey.key: FromScene.app_flag_cardlink.rawValue]
        case .newcardOpenLink:
            fromContext = [FromSceneKey.key: FromScene.single_innerlink.rawValue]
        @unknown default:
            assert(false, "new value")
        }
        
        guard let targetVC = self.pageContext.pageAPI else {
            CardContext.logger.info("openLinkImpl from \(from) \(url.host.logValue) unsupport because pageAPI is nil")
            return .openLinkFail("PageAPI is nil")
        }
        // 限流，距离上次打开时间小于指定间隔时间则不打开
        var error: LDCardError.ActionError?
        if let lastOpenTime = lastOpenLinkTime,
           Date().timeIntervalSince(lastOpenTime) < CardContext.openLinkInterval {
            CardContext.logger.info("openLinkImpl from \(from) \(url.host.logValue) interval limit")
            error = .openLinkLimitInterval
        } else {
            CardContext.logger.info("openLinkImpl push \(from) \(httpUrl.host.logValue) context \(fromContext)")
            Navigator.shared.push(httpUrl, context: fromContext, from: targetVC)
            lastOpenLinkTime = Date()
        }
        return error
    }

    private func possibleURL(_ urlStr: String) -> URL? {
        do {
            return try URL.forceCreateURL(string: urlStr)
        } catch let error {
            CardContext.logger.error("conver string: \(urlStr.safeURL()) to url fail with error: \(error)")
            return nil
        }
    }

    public func openProfile(chatterID: String) {
        CardContext.logger.info("openProfile call")
        if let targetVC = self.pageContext.pageAPI {
            let body = PersonCardBody(
                chatterId: chatterID,
                chatId: chat().id,
                source: .chat
            )
            Navigator.shared.presentOrPush(
                body: body,
                wrap: LkNavigationController.self,
                from: targetVC,
                prepareForPresent: { vc in
                    vc.modalPresentationStyle = .formSheet
                })
        }
    }

    public func presentController(vc: UIViewController, wrap: UINavigationController.Type?) {
        CardContext.logger.info("presentController")
        if let targetVC = self.pageContext.pageAPI {
            Navigator.shared.present(vc, wrap: wrap, from: targetVC, prepare: { controller in
                #if canImport(CryptoKit)
                if #available(iOS 13.0, *) {
                    if controller.modalPresentationStyle == .automatic {
                        controller.modalPresentationStyle = .fullScreen
                    }
                }
                #endif
            })
        }
    }

    /// 为popover外接矩形增加padding
    private func sourceRectWithPadding(for originSourceRect: CGRect) -> CGRect {
        return originSourceRect.inset(by: UIEdgeInsets(edges: -4))
    }

    public func selectChatter(sender: UIControl, chatterIDs: [String], complete: @escaping (String) -> Void) {
        CardContext.logger.info("selectChatter call")
        reportAction("selectChatter")
        let body = SearchChatterPickerBody(chatID: chat().id, chatterIDs: chatterIDs, selectChatterCallback: { (chatters) in
            complete(chatters.first?.id ?? "")
        })
        if let targetVC = self.pageContext.pageAPI {
            Navigator.shared.present(body: body,
                                     wrap: LkNavigationController.self,
                                     from: targetVC,
                                     prepare: {
                                        $0.modalPresentationStyle = .formSheet
                                     })
        }
    }

    public func selectOverflowOption(sender: UIView, options: [OverFlowOption], complete: @escaping (OverFlowOption) -> Void) {
        CardContext.logger.info("selectOverflowOption call")
        reportAction("selectOverflow")
        let config = UDActionSheetUIConfig(popSource: UDActionSheetSource(sourceView: sender, sourceRect: sourceRectWithPadding(for: sender.bounds)))
        let actionSheet = UDActionSheet(config: config)
        options.forEach { option in
            actionSheet.addItem(UDActionSheetItem(title: option.text, action: {
                complete(option)
            }))
        }
        actionSheet.setCancelItem(text: BundleI18n.LarkOpenPlatform.Lark_Legacy_MsgCardCancel)
        presentController(vc: actionSheet, wrap: nil)
    }

    public func selectMenuOption(sender: UIControl, options: [SelectMenuOption], initialValue: String?, complete: @escaping (SelectMenuOption) -> Void) {
        CardContext.logger.info("selectMenuOption call")
        switch options.count {
        case 1...7:
            let selectMenuController = SelectMenuCompactController(items: options.map {
                SelectMenuViewModel.Item(name: $0.text, value: $0.value, icon: nil)
            }, selectedValues: [initialValue ?? ""])
            selectMenuController.selectConfirm = { selectedItems in
                complete((text: selectedItems.first?.name ?? "", value: selectedItems.first?.value ?? ""))
            }
            let transitioningDelegate = UDPopoverTransition(
                sourceView: sender,
                sourceRect: sourceRectWithPadding(for: sender.bounds),
                permittedArrowDirections: popoverPermittedArrowDirections
            )
            transitioningDelegate.presentStypeInCompact = .overFullScreen
            self.transitioningDelegate = transitioningDelegate
            selectMenuController.modalPresentationStyle = .custom
            selectMenuController.transitioningDelegate = transitioningDelegate
            presentController(vc: selectMenuController, wrap: nil)
        case 8...:
            let selectMenuController = SelectMenuController(items: options.map {
                SelectMenuViewModel.Item(name: $0.text, value: $0.value, icon: nil)
            }, selectedValues: [initialValue ?? ""])
            selectMenuController.selectConfirm = { selectedItems in
                complete((text: selectedItems.first?.name ?? "", value: selectedItems.first?.value ?? ""))
            }
            presentController(vc: selectMenuController, wrap: nil)
        default:
            break
        }
    }

    public func selectDate(sender: UIView, initialDate: String?, dateOption: DateOption, complete: @escaping (Date) -> Void) {
        CardContext.logger.info("selectDate call")
        let dataPickerController = DatePickerController(initialDate: initialDate, pickType: dateOption)
        dataPickerController.cancel = { [weak dataPickerController] in
            dataPickerController?.dismiss(animated: true, completion: nil)
        }
        dataPickerController.confirm = { [weak dataPickerController] type, date in            dataPickerController?.dismiss(animated: true, completion: {
                guard let date = dataPickerController?.currentDate else {
                    return
                }
                complete(date)
            })
        }
        let transitioningDelegate = UDPopoverTransition(
            sourceView: sender,
            sourceRect: sourceRectWithPadding(for: sender.bounds),
            permittedArrowDirections: popoverPermittedArrowDirections
        )
        transitioningDelegate.presentStypeInCompact = .overFullScreen
        self.transitioningDelegate = transitioningDelegate
        dataPickerController.modalPresentationStyle = .custom
        dataPickerController.transitioningDelegate = transitioningDelegate
        presentController(vc: dataPickerController, wrap: nil)
    }

    public func sendAction(actionID: String, params: [String: String]?) {
        let actionTrace = trace.subTrace()
        let actionStart = Date()
        CardContext.logger.info(
            "will send action",
            additionalData: ["messageID": messageID, "actionID": actionID, "traceID": actionTrace.traceId]
        )
        
        guard allowToAction(cardType: cardType) else {
            CardContext.logger.info(
                "action not allow",
                additionalData: ["messageID": messageID, "actionID": actionID, "traceID": actionTrace.traceId]
            )
            reportAction(start: actionStart, trace: actionTrace, actionID: actionID, actionType: nil, error: .actionNotAllow)
            return
        }
        
        guard self.actionFinished else {
            CardContext.logger.info(
                "last action not finished, skip send action",
                additionalData: ["messageID": messageID, "actionID": actionID, "traceID": actionTrace.traceId]
            )
            reportAction(start: actionStart, trace: actionTrace, actionID: actionID, actionType: nil, error: .actionProcessing)
            return
        }
        
        self.actionFinished = false
        var request = RustPB.Im_V1_PutActionRequest()
        request.actionID = actionID
        request.messageID = self.messageID
        request.isEphemeral = self.message.isEphemeral
        if let params = params {
            request.params = params
        }
        let actionType = self.action(actionID: actionID)?.method == .openURL ? MonitorField.ActionTypeValue.url : MonitorField.ActionTypeValue.request
        let action = LDComponentContextCardAction(cardType: cardType, actionID: actionID, params: params)
        PushNotificationCenter().post(action)
        CardContext.logger.info(
            "did send action",
            additionalData: ["messageID": messageID, "actionID": actionID, "traceID": actionTrace.traceId]
        )
        
        let reportOpenlink: (LDCardError.ActionError?) -> Void = {[weak self] error in
            CardContext.logger.info(
                "open link finish with error \(error)",
                additionalData: [
                    "messageID": self?.messageID ?? "",
                    "actionID": actionID,
                    "traceID": actionTrace.traceId
                ])
            self?.reportAction(
                start: actionStart,
                trace: actionTrace,
                actionID: nil,
                actionType: .url,
                error: error
            )
        }
        
        let observable: Observable<RustPB.Im_V1_PutActionResponse>? = pageContext
                                                                .resolver
                                                                .resolve(SDKRustService.self)?
                                                                .sendAsyncRequest(request)
        observable?.subscribe(onNext: { [weak self] res in
            if res.method == .openURL {
                self?.actionFinished = true
                self?.openUrlAction(action: res.openURL, complete: reportOpenlink)
                CardContext.logger.warn("open wrong url")
            } else {
                self?.reportAction("sendAction", "interaction")
                self?.reportAction(
                    start: actionStart,
                    trace: actionTrace,
                    actionID: actionID,
                    actionType: .request,
                    error: nil
                )
            }
            CardContext.logger.info(
                "recived send action callback",
                additionalData: ["messageID": self?.messageID ?? "", "actionID": actionID, "method": res.method.rawValue.description]
            )
        }, onError: { [weak self] error in
            guard let `self` = self else { return }
            self.actionFinished = true
            CardContext.logger.error(
                "recived send action callback",
                additionalData: ["messageID": self.messageID, "actionID": actionID],
                error: error
            )
            if let action = self.action(actionID: actionID),
               action.method == .openURL {
                self.openUrlAction(action: action.openURL, complete: reportOpenlink)
            } else {
                self.reportAction(
                    start: actionStart,
                    trace: actionTrace,
                    actionID: actionID,
                    actionType: .request,
                    error: .responseFail(error)
                )
            }
        }).disposed(by: self.disposebag)
    }

    /// 打开url action
    private func openUrlAction(action: RustPB.Basic_V1_CardAction.Url, complete: ((LDCardError.ActionError?) -> Void)? = nil) {
        CardContext.logger.info("perform openUrlAction action ")
        if action.hasIosURL, let url = possibleURL(action.iosURL) {
            CardContext.logger.info("sendAction openLink iosUrl")
            DispatchQueue.main.async {
                self.openLink(url, from: .innerLink(reason: "open_link_resp_action"), complete: complete)
            }
            return
        }
        if action.hasURL, let url = possibleURL(action.url) {
            CardContext.logger.info("sendAction openLink url")
            DispatchQueue.main.async {
                self.openLink(url, from: .innerLink(reason: "open_link_resp_action"), complete: complete)
            }
            return
        }
        CardContext.logger.error("openLink with invalid url \(action.url.safeURLString)")
        complete?(.openLinkUrlInvalid)
        reportAction("sendAction", "interaction")
    }

    private func allowToAction(cardType: LarkModel.CardContent.TypeEnum) -> Bool {
        if isMe(message.fromId), extra == .senderCannotClick {
            toastManagerService.showToast(
                key: "",
                type: .tips,
                info: _i18n.unsupportedActionMobile
            )
            return false
        }
        return triggerInterceptAction()
    }

    private func triggerInterceptAction() -> Bool {
        switch cardType {
        case .vchat:
            // 正在通话
            if dependency.hasCurrentModule() {
                let text = (dependency.isRinging() == true) ? dependency.inRingingCannotJoinMeetingText() : dependency.isInCallText()
                toastManagerService.showToast(key: nil, type: .tips, info: text)
                return false
            }

            if dependency.videoDenied() {
                dependency.showCameraAlert()
                return false
            }

            if dependency.audioDenied() {
                dependency.showMicrophoneAlert()
                return false
            }
        @unknown default:
            break
        }
        return true
    }

    /// 如果是转发的卡片，那么会走这个方法，返回true表示响应成功，弹出提示
    public func forwardMessageAction(actionID: String, params: [String: String]?) -> Bool {
        /// 如果是转发的卡片 且 是非URL跳转的操作，才不允许交互
        if isForwardCardMessage && !isOpenURLAction(actionID: actionID) {
            toastManagerService.showToast(
                key: "",
                type: .tips,
                info: BundleI18n.LarkOpenPlatform.Lark_Legacy_forwardCardToast
            )

            CardContext.logger.info("handle forward card message action")
            return true
        }
        return false
    }

    /// 通过ActionID判断是不是跳转的action（也就是打开一个url，不需要发送信息给后端的action）
    public func isOpenURLAction(actionID: String) -> Bool {
        if let actions = (message.content as? CardContent)?.actions,
            let action = actions[actionID], action.method == .openURL {
            return true
        }
        return false
    }
    
    /// DarkMode
    public func messageCardStyle() -> [String: Any]? {
        return MessageCardStyleManager.shared.messageCardStyle()
    }
    /// 获取对应的Action
    public func action(actionID: String) -> LarkModel.CardContent.CardAction? {
        if let actions = (message.content as? CardContent)?.actions,
           let action = actions[actionID] {
            return action
        }
        return nil
    }
    /// 上报卡片点击
    private func reportAction(_ eventSource: String = "", _ reason: String? = nil, url: String? = nil) {
        /// https://bytedance.feishu.cn/sheets/shtcn7SfFfKGMVduuDvFajBLwDf?sheet=KFuJbb
        CardContext.logger.info("reportAction eventSource \(eventSource)")
        let teaEventName = "openplatform_im_message_card_click"
        let event = OPMonitor(teaEventName)
                .addMetricValue("click", "message_card")
                .addMetricValue("msg_id", messageID)
                .addMetricValue("target", "none")
                .addMetricValue("eventSource", eventSource)
                .setPlatform(.tea)
        if let actionType = reason {
            switch actionType {
            case "open_link_resp_action", "open_link":
                event.addCategoryValue("action_type", "open_link")
            default:
                event.addCategoryValue("action_type", "interaction")
            }
        }
        if let url = url {
            url.setUrlMonitorCategoryValue(monitor: event)
        }
        event.flush()
    }
}

///
extension PageContext: DynamicContentViewModelContext {
    public var pushCardMessageActionObserver: Observable<PushCardMessageActionResult> {
        return resolver.userPushCenter.observable(for: PushCardMessageActionResult.self)
    }

    public func getContentMaxHeight(_ message: Message) -> CGFloat {
        let scene = dataSourceAPI?.scene ?? .newChat
        switch scene {
        case .messageDetail:
            // 详情页不折叠
            return -1
        case .pin:
            return MaxPinContentHeight
        default:
            guard let height = dataSourceAPI?.hostSize.height else {
                return -1
            }
            return (height - 85 - 44) * 0.9
        }
    }

    func createDynamicContext(_ message: Message, chat: @escaping () -> Chat, metaModelDependency: CellMetaModelDependency) -> CardContext? {
        let preferWidth = metaModelDependency.getContentPreferMaxWidth(message)
        return CardContext(
            pageContext: self,
            toastManagerService: self.pageContainer.resolve(ToastManagerService.self)!,
            message: message,
            chat: chat,
            i18n: CardContentI18n(),
            scene: self.scene,
            cardAvailableMaxWidth: maxCardWidthLimit(message, preferWidth),
            wideCardMode: shouldDisplayWideCard(message,
                                                cellMaxWidth: getCellMaxWidth(),
                                                contentPreferWidth: preferWidth
            ), wideCardContextUpdate: {[weak self] in
                guard let self = self else {
                    return (false, preferWidth)
                }
                let preferWidthNew = metaModelDependency.getContentPreferMaxWidth(message)
                let wideCardMode = shouldDisplayWideCard(message,
                                                         cellMaxWidth: self.getCellMaxWidth(),
                                                         contentPreferWidth: preferWidthNew)
                return (wideCardMode, preferWidthNew)
            }
        )
    }
    public func getCellMaxWidth() -> CGFloat? {
        guard let width = dataSourceAPI?.hostSize.width else {
            return nil
        }
        return width
    }
    public func preferMaxWidth(_ message: Message, _ contentPreferMaxWidth: CGFloat) -> CGFloat {
        if shouldDisplayWideCard(message, cellMaxWidth: getCellMaxWidth(), contentPreferWidth: contentPreferMaxWidth) {
            return min(message.cardMaxLimitWidth(), contentPreferMaxWidth)
        }
        if widthAdaptContainerEnabled() &&
            MessageCardRenderControl.lynxCardRenderEnable(message: message) &&
            contentPreferMaxWidth > 0.1 {
            return contentPreferMaxWidth
        }
        return min(narrowCardMaxLimitWidth, contentPreferMaxWidth)
    }
    public func maxCardWidthLimit(_ message: Message, _ contentPreferMaxWidth: CGFloat) -> CGFloat {
        if shouldDisplayWideCard(message, cellMaxWidth: getCellMaxWidth(), contentPreferWidth: contentPreferMaxWidth) {
            var maxWidth = message.cardMaxLimitWidth()
            let widthMode = (message.content as? CardContent)?.widthMode
            switch widthMode {
                case "fill": maxWidth = contentPreferMaxWidth
                case "compact": maxWidth = wideCardCompactMaxLimitWidth
                case "default": maxWidth = wideCardMaxLimitWidth
                case .none, .some(_): maxWidth = message.cardMaxLimitWidth()
            }
            return MessageCardRenderControl.lynxCardRenderEnable(message: message) ?  maxWidth : message.cardMaxLimitWidth()
        }
        if widthAdaptContainerEnabled() &&
            MessageCardRenderControl.lynxCardRenderEnable(message: message) &&
            contentPreferMaxWidth > 0.1 {
            return contentPreferMaxWidth
        }
        return narrowCardMaxLimitWidth
    }
    
    private func widthAdaptContainerEnabled() -> Bool {
        @FeatureGatingValue(key: "openplatform.card.width_adapt_container.enable")
        var widthAdaptContainerEnabled: Bool
        return widthAdaptContainerEnabled
    }
}

// 临时修改，解决编译问题，需要@qihognye确认
extension CellConfigProxy {
    var hostSize: CGSize { hostUIConfig.size }
}

extension String {

    func setUrlMonitorCategoryValue(monitor: OPMonitor) {
        @RawSetting(key: UserSettingKey.make(userKeyLiteral: "msg_card_common_config"))
        var msgCardCommonConfig: [String: Any]?

        guard let trackDomains = msgCardCommonConfig?["trackDomains"] as? [String] else {
            return
        }
        if let urlComponent = URLComponents(string: self),
           let host = urlComponent.host {
            for  trackDomain in trackDomains {
                if host.contains(trackDomain) {
                    monitor.addCategoryValue("url_domain", host)
                    let subPaths = urlComponent.path.split(separator: "/")
                    if !subPaths.isEmpty {
                        let pathHashValues = subPaths.map{ String($0).getUrlHashValue() }
                        monitor.addCategoryValue("url_path", pathHashValues)
                    }
                    if let queryItems = urlComponent.queryItems,
                       !queryItems.isEmpty {
                        let queryItemsHashValue = queryItems.map{$0.name + "=" + ($0.value?.getUrlHashValue() ?? "")}
                        let queryItemsHashValueStr = queryItemsHashValue.joined(separator: "&")
                        monitor.addCategoryValue("url_query", queryItemsHashValueStr)
                    }
                    return
                }
            }
        }
    }

    func getUrlHashValue() -> String {
        return ( "08a441" + (self + "42b91e").md5()).sha1()
    }

}
