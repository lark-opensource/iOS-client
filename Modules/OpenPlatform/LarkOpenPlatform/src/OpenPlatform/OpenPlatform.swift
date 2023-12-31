//
//  OpenPlatform.swift
//  LarkOpenPlatform
//
//  Created by 武嘉晟 on 2019/9/24.
//

import EENavigator
import LKCommonsLogging
import LarkAccountInterface
import LarkAppStateSDK
import LarkFeatureGating
import LarkModel
import LarkSDKInterface
import RxSwift
import Swinject
import LarkMessengerInterface
import LarkOPInterface
import LKTracing
import SwiftyJSON
import LarkNavigator
import LarkAppLinkSDK
import WebBrowser
import AsyncComponent
import NewLarkDynamic
import EEFlexiable
import LarkUIKit
import EEMicroAppSDK
import OPSDK
import LarkTab
import LarkMicroApp
import UniverseDesignDialog
import UIKit
import LarkSetting
import LarkMessageCard
import RustPB
import UniversalCard
import UniversalCardInterface
import LarkContainer
import LarkOpenAPIModel

final class OpenPlatform: OpenPlatformService {
    private let resolver: UserResolver
    private let cardConnector: MessageCardConnector
    private var disposeBag = DisposeBag()
    private static let logger = Logger.log(OpenPlatform.self, category: "OpenPlatform")
    private var cardContent: LarkModel.CardContent?
    /// OpenPlatform 错误domain
    static let errorDomain = "com.bytedance.ee.lark.op"
    static let errorUndefinedCode = -9999
    static let getTriggerContextBizTypeKey = "bizType"
    static let getTriggerContextChatTypeKey = "chatType"
    static let getTriggerContextChatIDKey = "chatID"
    static let getTriggerContextBizTypeMessageAction = "messageAction"
    static let getTriggerContextBizTypeChatAction = "chatAction"
    
    deinit {
        Self.logger.info("OpenPlatform deinit")
    }

    private func delayRelease() {
    }
    
    private var domain: String {
        guard let applinkDomain = DomainSettingManager.shared.currentSetting["applink"]?.first else {
            // 理论上不会出现这个情况，这里是纯语法上的兜底写法，留下日志即可 https://bytedance.feishu.cn/docx/doxcnDtWgIn1eKcstzoRv21xXAg
            Self.logger.error("invalid applink domain settings")
            assertionFailure("invalid applink domain settings")
            return ""
        }
        Self.logger.info("share applink domain is \(applinkDomain)")
        return applinkDomain
    }
    
    private lazy var getUserInfoEXHandler: GetUserInfoEXHandler = {
        let ret = GetUserInfoEXHandler(resolver: resolver)
        return ret
    }()

    private lazy var cardAPI: MessageCardAPI = {
        let ret = MessageCardAPI(resolver: resolver)
        return ret
    }()

    private var keyBoardData: KeyBoardItemsData?
    private var renderer: ASComponentRenderer?
    
    private let chatService: ChatService
    
    private var useUniversalCard: Bool {
        do {
            return try resolver.resolve(assert: MessageCardMigrateControl.self).useUniversalCard
        } catch let error {
            Self.logger.error("OpenPlatform get useUniversalCard fail because userResolver resolve with", error: error)
            return false
        }
    }
    
    @FeatureGating("openplatform.basic.addmenu_init_update.enable")
    private var addMenuInitUpdateEnabled: Bool

    init(resolver: UserResolver) throws {
        self.resolver = resolver
        self.chatService = try resolver.resolve(assert: ChatService.self)
        self.cardConnector = MessageCardConnector(resolver: resolver)
        keyBoardData = KeyBoardItemsData(resolver: resolver)
    }

    /// 开放平台初始化，请务必确保在【登录成功】和【切换账户后】执行，不要随意调整时机
    public func setup() {
        /// 调用应用机制初始化方法
        AppStateSDK.shared.setupSDKWith(resolver: resolver)
        try? resolver.resolve(assert: OpenPlatformAliver.self).setup()
        
        // 开放应用引擎登录(OpenPlatform.setup 会在【登录成功】和【切换账户后】执行)
        OpenAppEngine.shared.login(resolver: resolver)
        
        #if NativeApp
        OPApplicationService.current.registerContainerService(
            for: .thirdNativeApp,
            service: OPNativeAppContainerService()
        )
        try? resolver.resolve(assert: NativeAppManagerInternalProtocol.self).setupContainer()
        #endif
    }

    public func getTriggerCode(callback: @escaping (String) -> Void) {
        let cc = cardConnector
        return cc.getTriggerCode(callback: callback)
    }
    
    public func fetchApplicationAvatarList(appVersion: String, accessToken: String) -> Observable<(Int?, JSON)> {
        guard let client = try? resolver.resolve(assert: OpenPlatformHttpClient.self) else {
            Self.logger.error("OpenPlatform: OpenPlatformHttpClient impl is nil")
            return .empty()
        }
        return client.request(api: OpenPlatformAPI(path: .getAvatarList, resolver: resolver)
            .setMethod(.post)
            .useSession()
            .appendParam(key: .larkVersion, value: appVersion)
            .appendCookie()
            .useLocale()
            .setScope(.personalizedAvatar))
        .map{ ($0.code, $0.json) }
    }

    public func urlWithTriggerCode(_ sourceUrl: String,
                                   _ cardMsgID: String, _ callback: @escaping (String) -> Void) {
        let cc = cardConnector
        getTriggerCode { (tcode) in
            guard let tUrl = cc.appendCodeToMiniProgramUrl(sourceUrl, tcode) else {
                callback(sourceUrl)
                return
            }
            cc.bindTriggerCode(tcode, cardMsgID)
            callback(tUrl)
            return
        }
    }

    /// 添加TriggerCode到url
    public func urlAppendTriggerCode(_ sourceUrl: String, _ triggerCode: String, appendOnlyForMiniProgram: Bool = true) -> String? {
        let cc = cardConnector
        if appendOnlyForMiniProgram, let tUrl = cc.appendCodeToMiniProgramUrl(sourceUrl, triggerCode) {
            return tUrl
        }
        if !appendOnlyForMiniProgram, let tUrl = cc.appendCodeToTargetUrl(sourceUrl, triggerCode) {
            return tUrl
        }
        return nil
    }

    public func getUserInfoEx(onSuccess: @escaping ([String: Any]) -> Void, onFail: @escaping (Error) -> Void) {
        getUserInfoEXHandler.getUserInfoEx(onSuccess: onSuccess, onFail: onFail)
    }

    public func getOpenPlatformDeviceID() -> String {
        if let service = try? resolver.resolve(assert: DeviceService.self) {
            let salt = "littleapp"
            return (service.deviceId + salt).sha256()
        }
        return ""
    }

    public func getKeyBoardApps(chat: Chat, chatViewController: UIViewController?) -> Observable<[KeyBoardItemProtocol]>? {
        return Observable.create {[weak self, weak chatViewController] observer -> Disposable in
            ///监听数据刷新的通知
            if let keyboardData = self?.keyBoardData, let bag = self?.disposeBag {
                ///因为这里还有一个type参数，需要根据type获取到对应的数据
                // 修复每次进入会话点击加号面板后网络请求累积的问题
                keyboardData.itemsUpdateSub = PublishSubject<KeyBoardItemUpdateEvent>()
                keyboardData.itemsUpdateSub.subscribe({ [weak self] event in
                    // 打开加号面板时，读取缓存展示UI。在后台更新数据，但不更新UI
                    switch event {
                    case .completed:
                        Self.logger.info("keyboardData itemsUpdateSub completed")
                    case .error(let error):
                        Self.logger.error("keyboardData itemsUpdateSub error: \(error)")
                    case .next(let updateEvent):
                        Self.logger.info("keyboardData itemsUpdateSub updateEvent: \(updateEvent)")
                        var shouldUpdateData = true
                        switch updateEvent {
                        case .loadFromInit:
                            shouldUpdateData = self?.addMenuInitUpdateEnabled == true
                        case .reloadFromCache,
                             .reloadWhenImage,
                             .reloadWhenOtherUpdate:
                            shouldUpdateData = true
                        }
                        // 判断是否只使用缓存数据，而后续不用刷新数据
                        var onlyUseCache = false
                        if updateEvent == .reloadFromCache || updateEvent == .reloadWhenImage {
                            onlyUseCache = true
                        }
                        if self?.addMenuInitUpdateEnabled == true && updateEvent == .loadFromInit {
                            onlyUseCache = true
                        }
                        var hasReloadImage = false
                        // 如果之前已经加载过图片，刷新加号面板上展示数据时，会引起重新加载图片
                        // 为避免循环调用，这时不再需要重新触发刷新加号面板上展示数据的流程
                        if updateEvent == .reloadWhenImage {
                            hasReloadImage = true
                        }
                        if shouldUpdateData {
                            self?.keyBoardData?.getDynamicItems(chat: chat,
                                                                chatViewController: chatViewController,
                                                                onlyUseCache: onlyUseCache,
                                                                hasReloadImage: hasReloadImage
                                                                ) { result in
                                observer.onNext(result)
                            }
                        }
                    @unknown default:
                        assertionFailure("unknow type")
                    }
                }).disposed(by: bag)
            }
            if let keyboardData = self?.keyBoardData {
                ///因为这里还有一个type参数，需要根据type获取到对应的数据
                keyboardData.getDynamicItems(chat: chat,
                                             chatViewController: chatViewController) { (result) in
                    observer.onNext(result)
                }
            }
            return Disposables.create()
        }
    }

    public func getTriggerContext(withTriggerCode triggerCode: String, block: (([String: Any]?) -> Void)?) {
        // 针对加号菜单场景
        if let chatCtx = MessageCardSession.shared().getChatActionContext(triggerCode: triggerCode) {
            var callbackInfo = [OpenPlatform.getTriggerContextChatIDKey: chatCtx.chat.id,
                                OpenPlatform.getTriggerContextBizTypeKey: OpenPlatform.getTriggerContextBizTypeChatAction]
            if chatCtx.chat.type == .group {
                callbackInfo[OpenPlatform.getTriggerContextChatTypeKey] = "1"
            } else if chatCtx.chat.type == .p2P {
                callbackInfo[OpenPlatform.getTriggerContextChatTypeKey] = "0"
            }
            block?(callbackInfo)
            return
        }
        // 针对Message Action场景
        if let messageCtx = MessageCardSession.shared().getMessageActionContext(triggerCode: triggerCode) {
            let callbackInfo = [OpenPlatform.getTriggerContextChatIDKey: messageCtx.chatId,
                                OpenPlatform.getTriggerContextBizTypeKey: OpenPlatform.getTriggerContextBizTypeMessageAction]
            block?(callbackInfo)
            return
        }
        block?(MessageCardErr.noPermissionByNoOpenRecord.getCallBackDic())
    }
    
    public func getTriggerMessageIds(triggerCode: String) -> [String]? {
        guard let messageContext = MessageCardSession.shared().getMessageActionContext(triggerCode: triggerCode) else {
            return nil
        }
        return messageContext.messageIds
    }

    public func sendMessageCard(appID: String,
                                fromWindow: UIWindow?,
                                scene: String,
                                triggerCode: String?,
                                chatIDs: [String]?,
                                cardContent: [AnyHashable: Any],
                                withMessage: Bool,
                                block: SendMessageCardCallBack?) {
        OpenPlatform.logger.info("start send message card \(String(describing: triggerCode))")
        keyBoardData?.reportSendCardCallEvent(appid: appID, scene: scene)
        let wrapBlock: ((SendMessageCardErrorCode, String?, [String]?, [EMASendCardInfo]?, [EMASendCardAditionalTextInfo]?)) -> Void = { (info) in
            let (errCode, errMsg, failedOpenIDs, sendCardInfos, sendTextInfos) = info
            OpenPlatform.logger.info("start send message card wrapBlock")
            block?(errCode, errMsg, failedOpenIDs, sendCardInfos, sendTextInfos)
        }
        guard let cardJsonData = try? JSONSerialization.data(withJSONObject: cardContent,
                                                             options: .prettyPrinted),
            let cardJson = String(data: cardJsonData, encoding: .utf8) else {
                wrapBlock(MessageCardErr.cardContentToJsonError.getCallBackResult())
                return
        }
        if let cts = chatIDs,
           cts.isEmpty == false {
            OpenPlatform.logger.info("start send message card getChatItems \(appID)")
            getChatItems(chatIDs: cts) { (success, chatItems) in
                if success {
                    OpenPlatform.logger.info("start send message card getChatItems previewAndSendMessageCard \(appID)")
                    self.previewAndSendMessageCard(appID: appID,
                                                   fromWindow: fromWindow,
                                                   scene: scene,
                                                   chatIDs: cts,
                                                   chatItems: chatItems,
                                                   cardJson: cardJson,
                                                   withMessage: withMessage,
                                                   callback: wrapBlock)
                } else {
                    wrapBlock(MessageCardErr.getChatItemsFailed.getCallBackResult())
                }
            }
        } else if let tc = triggerCode {
            guard let ctx = MessageCardSession.shared().getChatActionContext(triggerCode: tc) else {
                wrapBlock(MessageCardErr.noPermissionByNoOpenRecord.getCallBackResult())
                return
            }
            OpenPlatform.logger.info("start send message card previewAndSendMessageCard \(appID)")
            previewAndSendMessageCard(appID: appID,
                                      fromWindow: fromWindow,
                                      scene: scene,
                                      chatIDs: [ctx.chat.id],
                                      chatItems: [ctx.chat],
                                      cardJson: cardJson,
                                      withMessage: withMessage,
                                      callback: wrapBlock)
        } else {
            wrapBlock(MessageCardErr.chatIDsEmpty.getCallBackResult())
        }
        return
    }
    public func chooseChatAndSendMsgCard(
        appid: String,
        cardContent: [AnyHashable: Any],
        model: SendMessagecardChooseChatModel,
        withMessage: Bool,
        res: @escaping SendMessageCardCallBack
) {
        guard let cardJsonData = try? JSONSerialization.data(withJSONObject: cardContent, options: .prettyPrinted),
              let cardJson = String(data: cardJsonData, encoding: .utf8) else {
            let (errCode, errMsg, failedOpenIDs, sendCardInfos, sendTextInfos) = MessageCardErr.cardContentToJsonError.getCallBackResult()
            res(errCode, errMsg, failedOpenIDs, sendCardInfos, sendTextInfos)
            return
        }
        //和yuanzeyao@bytedance.com讨论，按照yuanzeyao@bytedance.com的建议chatId传入""(说chat里面有一个兜底的策略，默认显示用户真实姓名)，但是这个API绝对不合理，需要消息卡片owner重构
        cardAPI.resuqstCardPB(jsonStr: cardJson, appId: appid, chatId: "") { [weak self, weak cardAPI] response in
            guard let self = self else { return }
            //code from lilun.ios
            DispatchQueue.main.async {
                guard let rsp = response else {
                    let info = MessageCardErr.jsonToPBError(-2000).getCallBackResult()
                    let (errCode, errMsg, failedOpenIDs, sendCardInfos, sendTextInfos) = info
                    res(errCode, errMsg, failedOpenIDs, sendCardInfos, sendTextInfos)
                    OpenPlatform.logger.error("resuqstCardPB failed no response")
                    return
                }
                guard rsp.status == 0 else {
                    let info = MessageCardErr.jsonToPBError(Int(rsp.status)).getCallBackResult()
                    let (errCode, errMsg, failedOpenIDs, sendCardInfos, sendTextInfos) = info
                    res(errCode, errMsg, failedOpenIDs, sendCardInfos, sendTextInfos)
                    OpenPlatform.logger.error("resuqstCardPB failed status:\(rsp.status)")
                    return
                }
                
                if MessageCardRenderControl.lynxCardRenderEnable(content: rsp.cardContent) {
                    var cardView = UIView()
                    let cardContentModel = LarkModel.CardContent.transform(cardContent: rsp.cardContent)
                    self.cardContent = cardContentModel
                    if self.useUniversalCard, let content = UniversalCardContent.transform(content: cardContentModel)  {
                        let data = UniversalCardData(
                            cardID: "preview" + UUID().uuidString,
                            version: "",
                            bizID: "-1",
                            bizType: -1,
                            cardContent: content,
                            translateContent: nil,
                            actionStatus: UniversalCardData.ActionStatus(),
                            localExtra: [:],
                            appInfo: cardContentModel.appInfo
                        )
                        let source = (
                            data: data,
                            context: UniversalCardContext(
                                key: UUID().uuidString,
                                trace: OPTraceService.default().generateTrace(),
                                sourceData: data,
                                sourceVC: nil,
                                dependency: nil,
                                renderBizType: RenderBusinessType.message.rawValue,
                                bizContext: nil
                            ),
                            config: UniversalCardConfig(
                                width: (UDDialog.Layout.dialogWidth - 40),
                                actionEnable: true,
                                actionDisableMessage: BundleI18n.LarkOpenPlatform.Lark_Legacy_forwardCardToast
                            )
                        )
                        let card = UniversalCard.create(resolver: self.resolver)
                        card.render(
                            layout: UniversalCardLayoutConfig(preferWidth: (UDDialog.Layout.dialogWidth - 40), maxHeight: nil),
                            source: source,
                            lifeCycle: nil
                        )
                        cardView = card.getView()
                    } else {
                        let content: MessageCardContainer.CardContent = (origin: cardContentModel, translate: nil)
                        let context = MessageCardContainer.Context(
                            trace: OPTraceService.default().generateTrace(),
                            dependency: nil,
                            bizContext: [:]
                        )
                        let config = MessageCardContainer.Config(
                            perferWidth: (UDDialog.Layout.dialogWidth - 40),
                            isWideMode: false,
                            actionEnable: true,
                            isForward: false,
                            i18nText: I18nText()
                        )
                        let localeLanguage =
                        BundleI18n.currentLanguage.rawValue.getLocaleLanguageForMsgCard()
                        let translateInfo = TranslateInfo(localeLanguage: localeLanguage,
                                                          translateLanguage: "",
                                                          renderType: RenderType.renderOriginal)

                        let msgCardContainer = MessageCardContainer.create(
                            cardID: "",
                            version: "",
                            content: content,
                            localStatus: "",
                            config: config,
                            context: context,
                            lifeCycleClient: nil,
                            translateInfo: translateInfo
                        )
                        msgCardContainer.render()
                        cardView = msgCardContainer.view ?? UIView()
                    }
                    cardView.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
                    cardView.layer.cornerRadius = 10
                    cardView.layer.borderWidth = 1
                    cardView.layer.masksToBounds = true
                    cardView.isUserInteractionEnabled = false
                    let size = cardView.frame.size
                    let scroll = UIScrollView(frame: CGRect(origin: .zero,
                                                            size: CGSize(width: size.width, height: min(300, size.height))))
                    scroll.addSubview(cardView)
                    cardView.snp.makeConstraints { (make) in
                        make.width.equalTo(size.width)
                        make.height.equalTo(size.height)
                        make.edges.equalToSuperview()
                    }
                    let container = UIView(frame: scroll.bounds)
                    container.addSubview(scroll)
                    container.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
                    container.layer.cornerRadius = 10
                    container.layer.borderWidth = 1
                    container.layer.masksToBounds = true
                    scroll.snp.makeConstraints { (make) in
                        make.width.equalTo(size.width)
                        make.height.equalTo(min(300, size.height))
                        make.edges.equalToSuperview()
                    }
                    scroll.contentSize = size
                    let body = SendMessageCardForwardAlertBody(cardkey: rsp.cardKey, cardAPI: self.cardAPI, appid: appid, cardContent: cardContent, model: model, view: container) { (errCode, errMsg, failedChatIDs, sendCardInfos, _, sendTextInfos) in
                        res(errCode, errMsg, failedChatIDs, sendCardInfos, sendTextInfos)
                    }

                    if let fromVC = self.resolver.navigator.mainSceneWindow?.fromViewController {
                        self.resolver.navigator.present(body: body, naviParams: nil, context: [:], wrap: nil, from: fromVC, prepare: { $0.modalPresentationStyle = .overFullScreen }, animated: true, completion: nil)
                    } else {
                        OpenPlatform.logger.error("chooseChatAndSendMsgCard  can not show vc because no fromViewController")
                    }
                } else {
                    //TODO:【李论.ios】这里需要研究如何处理，老逻辑在MessageCardPrewController中，目前组装消息卡片的代码耦合在其中，无法抽离，需要owner统一重构处理，包括卡片需要提前算出frame，需要考虑卡片支持自动布局
                    let defaultFrame = UIScreen.main.bounds
                    var w:CGFloat
                    var cardContainerBounds:CGRect
                    //消息卡片预览页面给卡片提供了一个固定的宽度，这里使用与其相匹配的值，40是两侧的边距
                    //代码位置/LarkForward/src/Forward/ForwardFactory/ForwardAlertViewCreater.swift line：21
                    w = UDDialog.Layout.dialogWidth - 40
                    cardContainerBounds =  CGRect.init(x: 0,
                                                        y: 0,
                                                        width: w,
                                                        height: defaultFrame.height)
                    let cardContent1 = rsp.cardContent
                    let dynamicStyle = ASComponentStyle()
                    dynamicStyle.flexShrink = 0
                    dynamicStyle.overflow = .scroll
                    dynamicStyle.width = CSSValue(cgfloat: w)
                    let _previewComponent = MessageCardPreviewComponent<MessageCardPreviewContext>(
                        props: MessageCardPreviewComponent.Props(card: cardContent1),
                        style: dynamicStyle,
                        context: MessageCardPreviewContext(cardContent: CardContent.transform(cardContent: cardContent1))
                    )
                    let _renderer = ASComponentRenderer(_previewComponent)
                    let _cardContentView = _previewComponent.create(cardContainerBounds)
                    _cardContentView.isUserInteractionEnabled = false
                    _renderer.bind(to: _cardContentView)
                    _renderer.render(_cardContentView)
                    self.renderer = _renderer
                    let cardSize = _renderer.size()
                    
                    func makeOriginCard(cardSize: CGSize, _cardContentView: UIView) -> UIView {
                        let card = UIView(frame: CGRect.init(origin: .zero, size: cardSize))
                        card.addSubview(_cardContentView)
                        _cardContentView.snp.makeConstraints { (make) in
                            make.width.equalTo(cardSize.width)
                            make.height.equalTo(cardSize.height)
                            make.edges.equalToSuperview()
                        }
                        _cardContentView.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
                        _cardContentView.layer.cornerRadius = 10
                        _cardContentView.layer.borderWidth = 1
                        _cardContentView.layer.masksToBounds = true
                        return card
                    }
                    
                    func makeScrollCard(cardSize: CGSize, _cardContentView: UIView) -> UIView {
                        let scroll = UIScrollView(frame: CGRect(origin: .zero,
                                                                size: CGSize(width: cardSize.width, height: min(300, cardSize.height))))
                        scroll.addSubview(_cardContentView)
                        _cardContentView.snp.makeConstraints { (make) in
                            make.width.equalTo(cardSize.width)
                            make.height.equalTo(cardSize.height)
                            make.edges.equalToSuperview()
                        }
                        let container = UIView(frame: scroll.bounds)
                        container.addSubview(scroll)
                        container.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
                        container.layer.cornerRadius = 10
                        container.layer.borderWidth = 1
                        container.layer.masksToBounds = true
                        scroll.snp.makeConstraints { (make) in
                            make.width.equalTo(cardSize.width)
                            make.height.equalTo(min(300, cardSize.height))
                            make.edges.equalToSuperview()
                        }
                        scroll.contentSize = cardSize
                        return container
                    }
                    let container = makeScrollCard(cardSize: cardSize, _cardContentView: _cardContentView)
                    let body = SendMessageCardForwardAlertBody(cardkey: rsp.cardKey, cardAPI: self.cardAPI, appid: appid, cardContent: cardContent, model: model, view: container) {[weak self] (errCode, errMsg, failedChatIDs, sendCardInfos, _, sendTextInfos) in
                        self?.renderer = nil
                        res(errCode, errMsg, failedChatIDs, sendCardInfos, sendTextInfos)
                    }
                    if let fromVC = Navigator.shared.mainSceneWindow?.fromViewController {
                        self.resolver.navigator.present(body: body, naviParams: nil, context: [:], wrap: nil, from: fromVC, prepare: { $0.modalPresentationStyle = .overFullScreen }, animated: true, completion: nil)
                    } else {
                        OpenPlatform.logger.error("chooseChatAndSendMsgCard  can not show vc because no fromViewController")
                    }
                }
            }
        }
        //选人，有了chatid后使用cardAPI.resuqstCardPB获取到卡片的pb，rsp.status == 0的时候取出rsp.cardContent，然后做各种奇奇怪怪的转view
        //所以这里要先调用转发页面的路由
    }
    
    public func fetchCardContent() -> LarkModel.CardContent? {
        return self.cardContent
    }
        
    private func makeOriginCard(cardSize: CGSize, _cardContentView: UIView) -> UIView {
        let card = UIView(frame: CGRect.init(origin: .zero, size: cardSize))
        card.addSubview(_cardContentView)
        _cardContentView.snp.makeConstraints { (make) in
            make.width.equalTo(cardSize.width)
            make.height.equalTo(cardSize.height)
            make.edges.equalToSuperview()
        }
        _cardContentView.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        _cardContentView.layer.cornerRadius = 10
        _cardContentView.layer.borderWidth = 1
        _cardContentView.layer.masksToBounds = true
        return card
    }
    /// 执行Message Action
    public func takeMessageActionV2(chatId: String, messageIds: [String], isMultiSelect: Bool, targetVC: UIViewController) {
        let messageActionInfoDic: [String: Any] = ["chatId": chatId,
                                                   "messageIds": messageIds,
                                                   "isMultiSelect": isMultiSelect]
        guard let messageActionData = try? JSONSerialization.data(withJSONObject: messageActionInfoDic, options: .prettyPrinted) else {
            OpenPlatform.logger.error("messageActionInfoDic can't serialize to json")
            return
        }
        guard let messageActionString = String(data: messageActionData, encoding: .utf8) else {
            OpenPlatform.logger.error("messageActionString can't serialize to json string")
            return
        }
        guard let messageActionParameter = messageActionString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            OpenPlatform.logger.error("messageActionString can't percentEncoding to json parameter")
            return
        }
        let messageApplink = applinkForMessageActionIndex(messageActionParameter: messageActionParameter)
        if let messageActionUrl = messageApplink.possibleURL() {
            if let fromVC = Navigator.shared.mainSceneWindow?.fromViewController {
                self.resolver.navigator.push(messageActionUrl, from: fromVC)
            } else {
                OpenPlatform.logger.error("takeMessageActionV2  can not show vc because no fromViewController")
            }
            OpenPlatform.logger.info("open takeMessageActionV2 url \(messageActionUrl)")
        }
    }
    /// 打开导索页面的applink
    private func applinkForMessageActionIndex(messageActionParameter: String) -> String {
        var applinkComponents = URLComponents()
        applinkComponents.scheme = "https"
        applinkComponents.host = AppLinkBody.domains?.first ?? ""
        applinkComponents.path = "/client/message_action_list/open"
        applinkComponents.queryItems = [
            /// 打开message action导索页面会话的chatId
            URLQueryItem(name: "message_action_info", value: messageActionParameter),
            /// 打开message action导索页面的参数
            URLQueryItem(name: "list", value: "message_action")
        ]
        return applinkComponents.url?.absoluteString ?? ""
    }
    public func getBlockActionDetail(appID: String,
                              triggerCode: String?,
                              extraInfo: [String: Any]?,
                              complete: @escaping ((Error?, OpenAPIErrnoProtocol?, [String: Any]) -> Void)) {
        GetMessageDetailHandler.shared.getBlockActionDetail(resolver: resolver,
                                                            appID: appID,
                                                            triggerCode: triggerCode,
                                                            extraInfo: nil,
                                                            complete: complete)
    }
    
    func canOpenDocs(url: String) -> Bool {
        guard let dependency = try? resolver.resolve(assert: OpenPlatformDependency.self) else {
            OpenPlatform.logger.error("OpenPlatformDependency is nil")
            return false
        }
        return dependency.canOpenDocs(url: url)
    }
}

// MARK: private func
extension OpenPlatform {
    private func previewAndSendMessageCard(appID: String,
                                           fromWindow: UIWindow?,
                                           scene: String,
                                           chatIDs: [String],
                                           chatItems: [Chat],
                                           cardJson: String,
                                           withMessage: Bool,
                                           callback: @escaping (((SendMessageCardErrorCode,
                                                                  String?,
                                                                  [String]?,
                                                                  [EMASendCardInfo]?,
                                                                  [EMASendCardAditionalTextInfo]?)) -> Void)) {
        /// 之前的对齐太难看了，受不了改了改
        OpenPlatform.logger.info("start send message card previewAndSendMessageCard \(appID)")
        let userResolver = self.resolver
        cardAPI.resuqstCardPB(
            jsonStr: cardJson,
            appId: appID,
            chatId: chatIDs.first!) { response in
            OpenPlatform.logger.info("start send message card previewAndSendMessageCard resp \(appID)")
                DispatchQueue.main.async {
                    guard let rsp = response else {
                        callback(MessageCardErr.jsonToPBError(-2000).getCallBackResult())
                        OpenPlatform.logger.error("resuqstCardPB failed no response")
                        return
                    }
                    guard rsp.status == 0 else {
                        callback(MessageCardErr.jsonToPBError(Int(rsp.status)).getCallBackResult())
                        OpenPlatform.logger.error("resuqstCardPB failed status:\(rsp.status)")
                        return
                    }
                    let cardContentModel = LarkModel.CardContent.transform(cardContent: rsp.cardContent)
                    self.cardContent = cardContentModel
                    let previewVC = MessageCardPrewController(
                        userResolver: userResolver,
                        cardContent: rsp.cardContent,
                        chatItems: chatItems,
                        withMessage: withMessage
                    ) { (comfirm, message) in
                        if comfirm {
                            self.cardAPI.sendCard(
                                chatIDs: chatIDs,
                                cardKey: rsp.cardKey
                            ) { [weak self](scsp) in
                                guard let self = self else {
                                    return
                                }
                                guard let sendCardRsp = scsp else {
                                    callback(MessageCardErr.sendCardError(-1000, nil).getCallBackResult())
                                    self.keyBoardData?.reportSendCardSendEvent(appid: appID, scene: scene, result: false)
                                    return
                                }
                                var failedOpenChatIDs: [String] = []
                                var sendCardInfos: [EMASendCardInfo] = []
                                for (_, sendInfo) in sendCardRsp.sendCardInfos {
                                    if sendInfo.status != 0 {
                                        failedOpenChatIDs.append(sendInfo.openChatID)
                                    } else {
                                        let tempCardSendInfo = EMASendCardInfo()
                                        tempCardSendInfo.status = Int(sendInfo.status)
                                        tempCardSendInfo.openChatId = sendInfo.openChatID
                                        tempCardSendInfo.openMessageId = sendInfo.openMessageID
                                        sendCardInfos.append(tempCardSendInfo)
                                    }
                                }
                                if failedOpenChatIDs.isEmpty {
                                    /// 失败的发送openChatId为空, 那么开始发送文本
                                    self.keyBoardData?.reportSendCardSendEvent(appid: appID, scene: scene, result: true)
                                    if !message.isEmpty {
                                        OpenPlatform.logger.info("send text start")
                                        self.cardAPI.sendText(chatIDMaps: sendCardRsp.chatIdToOpenChatIdMap(),
                                                              message: message) { (error, sendTextInfos) in
                                            if let sendTextError = error {
                                                OpenPlatform.logger.error("send text after send card error", tag: "", additionalData: nil, error: sendTextError)
                                                callback(MessageCardErr.sendTextError(nil).getCallBackResult(sendInfos: sendCardInfos, sendTextInfo: sendTextInfos))
                                            } else {
                                                OpenPlatform.logger.info("send text after send card success")
                                                callback(MessageCardErr.ok.getCallBackResult(sendInfos: sendCardInfos))
                                            }
                                        }
                                    } else {
                                        OpenPlatform.logger.info("send text after send card success")
                                        callback(MessageCardErr.ok.getCallBackResult(sendInfos: sendCardInfos))
                                    }
                                    return
                                } else {
                                    callback(MessageCardErr.sendCardError(Int(sendCardRsp.status), failedOpenChatIDs).getCallBackResult(sendInfos: sendCardInfos))
                                    self.keyBoardData?.reportSendCardSendEvent(appid: appID, scene: scene, result: false)
                                }
                            }
                            self.keyBoardData?.reportSendCardPreviewClickEvent(appid: appID, scene: scene, action: true)
                        } else {
                            callback(MessageCardErr.userCancelSend.getCallBackResult())
                            self.keyBoardData?.reportSendCardPreviewClickEvent(appid: appID, scene: scene, action: false)
                        }
                    }
                    previewVC.modalPresentationStyle = .overFullScreen
                    OpenPlatform.logger.error("start send message card present preview \(appID)")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        if let from = fromWindow {
                            self.resolver.navigator.present(previewVC, from: from)
                        } else if let from = Navigator.shared.mainSceneWindow?.fromViewController {
                            self.resolver.navigator.present(previewVC, from: from)
                        } else {
                            OpenPlatform.logger.error("resuqstCardPB can not show vc because no fromViewController")
                        }
                    }
                }
        }
    }

    private func getChatItems(chatIDs: [String], callback: @escaping (Bool, [Chat]) -> Void) {
        guard let chatAPI = try? resolver.resolve(assert: ChatAPI.self) else {
            callback(false, [])
            return
        }
        chatAPI.fetchChats(by: chatIDs, forceRemote: false)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (chatsMap) in
                var chatItems: [Chat] = []
                for chatID in chatIDs {
                    if let chatItem = chatsMap[chatID] {
                        chatItems.append(chatItem)
                    } else {
                        callback(false, [])
                        return
                    }
                }
                callback(true, chatItems)
            }, onError: { _ in
                callback(false, [])
            }).disposed(by: self.disposeBag)
    }

    /// 打开bot
    public func openBot(botId: String) {
        self.chatService.createP2PChat(userId: botId, isCrypto: false, chatSource: nil)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (chat) in
                let body = ChatControllerByChatBody(chat: chat)
                if let fromVC = Navigator.shared.mainSceneWindow?.fromViewController {
                    self.resolver.navigator.push(body: body, from: fromVC)
                } else {
                    OpenPlatform.logger.error("openBot \(botId) can not show vc because no fromViewController")
                }
                /// 需要延时释放一下
                self.delayRelease()
            }).disposed(by: disposeBag)
    }

    /// 打开会话
    public func gotoChat(userID: String, fromVC: UIViewController? = nil, completion: ((_ isSuccess: Bool) -> Void)?) {
        self.chatService.createP2PChat(
                userId: userID,
                isCrypto: false,
                chatSource: nil
            )
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (chat) in
                let body = ChatControllerByChatBody(chat: chat)
                let context: [String: Any] = [
                    FeedSelection.contextKey: FeedSelection(feedId: chat.id, selectionType: .skipSame)
                ]
                var from: NavigatorFrom
                if let f = fromVC {
                    from = f
                } else if let f = Navigator.shared.mainSceneWindow?.fromViewController {
                    from = f
                } else {
                    completion?(false)
                    return
                }
                self.resolver.navigator.showAfterSwitchIfNeeded(
                    tab: Tab.feed.url,
                    body: body,
                    context: context,
                    wrap: LkNavigationController.self,
                    from: from
                )
                completion?(true)
            }).disposed(by: disposeBag)
    }
    
    public func buildAppShareLink(with appId: String, opTracking: String) -> String {
        return "https://\(domain)/client/app_share/open?appId=\(appId)&op_tracking=\(opTracking)"
    }
    
}
