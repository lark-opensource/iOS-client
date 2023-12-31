//
//  MessageCardPrewController.swift
//  LarkOpenPlatform
//
//  Created by 李论 on 2020/1/11.
//

import UIKit
import LarkUIKit
import RustPB
import SnapKit
import Kingfisher
import AsyncComponent
import NewLarkDynamic
import LarkMessageCore
import EEFlexiable
import LarkModel
import LarkCore
import LarkAvatar
import LKCommonsLogging
import LarkMessengerInterface
import EENavigator
import Swinject
import LarkForward
import LarkAccountInterface
import LarkFeatureGating
import LarkSDKInterface
import RxSwift
import EEMicroAppSDK
import UniverseDesignColor
import UniverseDesignInput
import UniverseDesignDialog
import LarkKeyboardKit
import LarkOPInterface
import LarkMessageCard
import LarkContainer
import LarkNavigator
import UniversalCard
import UniversalCardInterface

public typealias InternalSendMessageCardCallBack = ((_ errCode: SendMessageCardErrorCode,
                                                     _ errMsg: String?,
                                                     _ failedChatIDs: [String]?,
                                                     _ sendCardInfo: [EMASendCardInfo]?,
                                                     _ chatIds: [String],
                                                     _ sendTextInfo: [EMASendCardAditionalTextInfo]?) -> Void)

class MessageCardPrewController: BaseUIViewController, UITextViewDelegate {
    private let cardContent: Basic_V1_CardContent
    private let chatItems: [Chat]
    private let confirmSend: ((Bool, String) -> Void)
    private let container = UIView(frame: .zero)
    private var cardContentView: UIView?
    private var textField: UDBaseTextView
    private var previewComponent: MessageCardPreviewComponent<MessageCardPreviewContext>?
    /// 渲染引擎
    public var renderer: ASComponentRenderer?
    static let logger = Logger.log(MessageCardPrewController.self, category: "MessageCardPrewController")
    /// 标记是否需要输入留言
    private let inputMessage: Bool

    private var msgCardContainer: MessageCardContainer?

    private var cardLifeCycle :CardPreviewRenderLifeCycle?

    private let resolver: UserResolver

    deinit {
        MessageCardPrewController.logger.info("MessageCardPrewController deinit")
    }

    init(
        userResolver: UserResolver,
        cardContent: Basic_V1_CardContent,
        chatItems: [Chat],
        withMessage: Bool,
        confirmSend: @escaping ((Bool, String) -> Void)
    ) {
        self.resolver = userResolver
        self.cardContent = cardContent
        self.chatItems = chatItems
        self.confirmSend = confirmSend
        self.textField = Self.makeTextView()
        inputMessage = withMessage
        super.init(nibName: nil, bundle: nil)
        self.textField.delegate = self
    }
    
    static func makeTextView() -> UDBaseTextView {
        let textView = UDBaseTextView(frame: .zero)
        textView.font = UIFont.systemFont(ofSize: 16.0)
        textView.textColor = UIColor.ud.textTitle
        textView.backgroundColor = UIColor.ud.udtokenComponentOutlinedBg
        textView.layer.borderWidth = 0.5
        let borderColor = UIColor.ud.lineBorderComponent
        textView.layer.ud.setBorderColor(borderColor)
        textView.layer.cornerRadius = 4
        textView.layer.masksToBounds = true
        textView.placeholder = BundleI18n.LarkOpenPlatform.OpenPlatform_MessageCard_LeaveMesPlaceholder
        textView.placeholderTextColor = UIColor.ud.textPlaceholder
        var originInset = textView.textContainerInset
        originInset.left = 12
        originInset.right = 12
        originInset.top = 13
        originInset.bottom = 13
        textView.textContainerInset = originInset
        return textView
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private let cardContainer: UIView = UIScrollView()

    func makeSepLine() -> UIView {
        let line = UIView()
        line.backgroundColor = UIColor.ud.N300
        return line
    }

    func makeButton() -> UIButton {
        let btn = UIButton(type: .custom)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 17.0)
        return btn
    }
    
    private func viewWidth() -> CGFloat {
        let viewWidth: CGFloat = min(364.0, view.bdp_width)
        return viewWidth
    }
    internal func textViewDidChange(_ textView: UITextView) {
        updateHeight(textView)
    }
        
    private func updateHeight(_ textView: UITextView) {
        let containerSize = CGSize(width: textView.bounds.width,
                                   height: CGFloat.greatestFiniteMagnitude)
        let size = textView.sizeThatFits(containerSize)
        textView.snp.updateConstraints { make in
            let height = min(max(size.height, 48), 70)
            make.height.equalTo(height).priority(.required)
        }
    }
    
    private func setupTap() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        view.addGestureRecognizer(tap)
    }
    @objc func handleTap(_ sender: UITapGestureRecognizer? = nil) {
        textField.resignFirstResponder()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setupTap()
        let maskColor = UIColor.ud.bgMask
        view.backgroundColor = .clear
        UIView.animate(withDuration: 0.3, animations: {
            self.view.backgroundColor = maskColor
        }, completion: nil)

        view.addSubview(container)
        container.backgroundColor = UIColor.ud.bgBody
        container.layer.cornerRadius = 8
        container.layer.shadowColor = UIColor.ud.rgb("1f2329").withAlphaComponent(0.1).cgColor
        container.layer.shadowOffset = CGSize(width: 2, height: 8)
        let viewWidth = self.viewWidth()
        let padding = (16.0 / 364.0) * viewWidth
        let containerWidth = UDDialog.Layout.dialogWidth
        let containerHeight = (containerWidth / 332.0) * 434
        let containerSize = CGSize(width: containerWidth,
                                   height: containerHeight)
        container.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.equalTo(containerSize.width)
            make.height.equalTo(containerSize.height).priority(.low)
            make.height
                .lessThanOrEqualToSuperview()
                .multipliedBy(0.6)
                .priority(.required)
            make.top.greaterThanOrEqualTo(self.view.safeAreaLayoutGuide.snp.top)
        }

        let toLabel = UILabel()
        toLabel.numberOfLines = 0
        toLabel.font = UIFont.systemFont(ofSize: 17.0, weight: .bold)
        toLabel.textAlignment = .left
        toLabel.text = BundleI18n.LarkOpenPlatform.Lark_Legacy_ChatViewSendTo
        toLabel.textColor = UIColor.ud.textTitle
        container.addSubview(toLabel)
        let toLabelHeight = 17
        let toLabelMarginTop = 20
        toLabel.snp.makeConstraints { (make) in
            make.left.top.equalToSuperview().offset(toLabelMarginTop)
            make.height.equalTo(toLabelHeight)
        }

        let cardContainerMarginLeft = CGFloat(padding)
        let cardContainerMarginRight = CGFloat(padding)
        let cardContainerWidth = containerWidth - cardContainerMarginLeft - cardContainerMarginRight
        var cardContainerHeight = (cardContainerWidth / 300.0) * 266
        var cardContainerTopMargin: CGFloat

        if chatItems.count == 1 {
            let chat = chatItems.first!
            let toLabelSize = CGSize(width: 36, height: 36)

            let frame = CGRect(x: 0, y: 0, width: toLabelSize.width, height: toLabelSize.height)
            let avator = AvatarImageView(frame: frame)
            avator.set(avatarKey: chat.avatarKey)
            avator.backgroundColor = .blue
            container.addSubview(avator)
            let avatorMarginTop: CGFloat = 51.0
            let avatorMarginLeft: CGFloat = 20.0

            avator.snp.makeConstraints { (make) in
                make.top.equalToSuperview().offset(avatorMarginTop)
                make.left.equalTo(avatorMarginLeft)
                make.size.equalTo(CGSize(width: toLabelSize.width, height: toLabelSize.height))
            }
            avator.layer.cornerRadius = toLabelSize.width / 2.0
            avator.layer.masksToBounds = true

            let nameLabel = UILabel()
            nameLabel.font = UIFont.systemFont(ofSize: 15.0)
            nameLabel.textAlignment = .left
            nameLabel.lineBreakMode = .byTruncatingTail
            nameLabel.text = chat.name
            nameLabel.textColor = UIColor.ud.N900
            container.addSubview(nameLabel)
            let nameLabelMarginLeft = 70
            nameLabel.snp.makeConstraints { (make) in
                make.centerY.equalTo(avator)
                make.left.equalToSuperview().offset(nameLabelMarginLeft)
                make.right.equalToSuperview().offset(-cardContainerMarginRight)
            }

            cardContainerTopMargin = avatorMarginTop + toLabelSize.height
        } else {
            cardContainerTopMargin = addAvators(chatItems: chatItems, containerWidth: containerWidth)
            // 计算差值，需要更新 cardContainerHeight
            let diff = cardContainerTopMargin - 51.0 - 36.0
            if diff > 0.0 {
                cardContainerHeight -= diff
            }
        }

        let cardContainerSize = CGSize(width: cardContainerWidth,
                                   height: cardContainerHeight)
        container.addSubview(cardContainer)
        cardContainer.snp.makeConstraints { (make) in
            make.left.equalTo(cardContainerMarginLeft)
            make.right.equalTo(-cardContainerMarginRight)
            make.top.equalToSuperview().offset(cardContainerTopMargin + 14)
            make.height.equalTo(cardContainerSize.height).priority(.low)
            make.height.greaterThanOrEqualTo(min(30, cardContainerSize.height)).priority(.required)
        }
        cardContainer.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        cardContainer.layer.cornerRadius = 10
        cardContainer.layer.borderWidth = 1
        cardContainer.layer.masksToBounds = true
        cardContainer.setContentCompressionResistancePriority(.defaultLow,
                                                              for: .vertical)
        textField.setContentCompressionResistancePriority(.required,
                                                          for: .vertical)
        let cardSize = loadCardContent(cardContainerBounds: CGRect(origin: .zero, size: cardContainerSize))
        var heightReduce: CGFloat = 0.0
        if cardSize.height < cardContainerSize.height {
            ///卡片过小，现在需要整体缩短
            heightReduce = cardContainerSize.height - max(cardSize.height, 30)
            cardContainer.snp.updateConstraints { (make) in
                make.height.equalTo(cardContainerSize.height - heightReduce).priority(.low)
            }
        }
        
        if inputMessage {
            container.addSubview(self.textField)
            self.textField.snp.makeConstraints { make in
                make.top.equalTo(cardContainer.snp.bottom).offset(12)
                make.left.equalTo(cardContainerMarginLeft)
                make.right.equalTo(-cardContainerMarginRight)
                make.height.equalTo(48).priority(.required)
            }
            
            container.snp.remakeConstraints { make in
                make.width.equalTo(containerSize.width)
                let originHeight = containerSize.height - heightReduce
                make.height
                    .equalTo(self.textField.snp.height)
                    .offset(originHeight + 41.5)
                    .priority(.low)
                make.center.equalToSuperview().priority(.low)
                make.bottom
                    .lessThanOrEqualTo(view.lkKeyboardLayoutGuide.update(respectSafeArea: true).snp.top)
                    .offset(-20)
                    .priority(.required)
                make.top.greaterThanOrEqualTo(self.view.safeAreaLayoutGuide.snp.top).priority(.medium)
            }
        } else {
            container.snp.remakeConstraints { make in
                make.width.equalTo(containerSize.width)
                let originHeight = containerSize.height - heightReduce
                make.height.equalTo(originHeight + 20).priority(.low)
                make.height
                    .equalTo(cardContainer.snp.height)
                    .offset(heightReduce + 12)
                    .priority(.low)
                make.center.equalToSuperview()
            }
        }
        let hLine = makeSepLine()
        container.addSubview(hLine)
        hLine.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview().offset(-50)
            make.height.equalTo(1)
            if inputMessage {
                make.top.greaterThanOrEqualTo(textField.snp.bottom).offset(24)
            } else {
                make.top.greaterThanOrEqualTo(cardContainer.snp.bottom).offset(24)
            }
        }

        let vLine = makeSepLine()
        container.addSubview(vLine)
        vLine.snp.makeConstraints { (make) in
            make.top.equalTo(hLine.snp.bottom)
            make.bottom.centerX.equalToSuperview()
            make.width.equalTo(1)
        }

        let cancel = makeButton()
        container.addSubview(cancel)
        cancel.setTitleColor(UIColor.ud.textTitle, for: .normal)
        cancel.snp.makeConstraints { (make) in
            make.top.equalTo(hLine.snp.bottom)
            make.left.bottom.equalToSuperview()
            make.right.equalTo(vLine.snp.left)
        }
        cancel.setTitle(BundleI18n.LarkOpenPlatform.Lark_Legacy_PlusCancel, for: .normal)
        cancel.addTarget(self, action: #selector(self.cancel), for: .touchUpInside)

        let comfirm = makeButton()
        container.addSubview(comfirm)
        comfirm.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        comfirm.snp.makeConstraints { (make) in
            make.top.equalTo(hLine.snp.bottom)
            make.right.bottom.equalToSuperview()
            make.left.equalTo(vLine.snp.right)
        }
        comfirm.setTitle(BundleI18n.LarkOpenPlatform.Lark_Legacy_PlusSend, for: .normal)
        comfirm.addTarget(self, action: #selector(self.comfirm), for: .touchUpInside)
    }

    @objc
    public func cancel() {
        dismiss()
        self.confirmSend(false, "")
    }

    @objc
    public func comfirm() {
        dismiss()
        self.confirmSend(true, self.textField.text)
    }

    private func dismiss() {
        dismiss(animated: true, completion: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    func loadCardContent(cardContainerBounds: CGRect) -> CGSize {
        guard cardContentView == nil else { return .zero }
        if MessageCardRenderControl.lynxCardRenderEnable(content: self.cardContent) {
            var lynxView = UIView()
            let cardContentModel = LarkModel.CardContent.transform(cardContent: self.cardContent)
            cardLifeCycle = CardPreviewRenderLifeCycle(
                cardContent: cardContentModel,
                cardScene: .sendMessageCardPreview,
                renderBusinessType: .message
            )
            if let useUniversalCard = try? resolver.resolve(assert: MessageCardMigrateControl.self).useUniversalCard, useUniversalCard,
                let content = UniversalCardContent.transform(content: cardContentModel)  {
            cardLifeCycle?.didStartSetup()
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
                        sourceVC: self,
                        dependency: nil,
                        renderBizType: RenderBusinessType.message.rawValue,
                        bizContext: nil
                    ),
                    config: UniversalCardConfig(
                        width: (cardContainerBounds.width),
                        actionEnable: true,
                        actionDisableMessage: BundleI18n.LarkOpenPlatform.Lark_Legacy_forwardCardToast
                    )
                )
                let card = UniversalCard.create(resolver: resolver)
                cardLifeCycle?.didFinishSetup()
                card.render(
                    layout: UniversalCardLayoutConfig(preferWidth: (cardContainerBounds.width), maxHeight: nil),
                    source: source,
                    lifeCycle: cardLifeCycle
                )
                lynxView = card.getView()
            } else {
                let content: MessageCardContainer.CardContent = (origin: cardContentModel, translate: nil)
                let context = MessageCardContainer.Context(
                    trace: OPTraceService.default().generateTrace(),
                    dependency: nil,
                    bizContext: [:]
                )
                let config = MessageCardContainer.Config(
                    perferWidth: (cardContainerBounds.width),
                    isWideMode: false,
                    actionEnable: true,
                    isForward: false,
                    i18nText: I18nText()
                )
                let localeLanguage = BundleI18n.currentLanguage.rawValue.getLocaleLanguageForMsgCard()
                let translateInfo = TranslateInfo(localeLanguage: localeLanguage,
                                                  translateLanguage: "",
                                                  renderType: RenderType.renderOriginal)
                msgCardContainer = MessageCardContainer.create(
                    cardID: "preview" + UUID().uuidString,
                    version: "",
                    content: content,
                    localStatus: "",
                    config: config,
                    context: context,
                    lifeCycleClient: cardLifeCycle,
                    translateInfo: translateInfo
                )
                cardLifeCycle?.didFinishSetup()
                msgCardContainer?.render()
                lynxView = msgCardContainer?.view ?? UIView()
            }
            lynxView.isUserInteractionEnabled = false
            let size = CGSize(width: lynxView.frame.width, height: lynxView.frame.height)
            let box = UIView(frame: .zero)
            cardContainer.addSubview(box)
            box.snp.makeConstraints { make in make.edges.equalToSuperview() }
            box.addSubview(lynxView)
            lynxView.snp.makeConstraints { make in
                make.width.equalTo(size.width)
                make.height.equalTo(size.height)
                make.edges.equalToSuperview()
            }
            return size
        } else {
            let dynamicStyle = ASComponentStyle()
            dynamicStyle.flexShrink = 0
            dynamicStyle.overflow = .scroll
            dynamicStyle.width = CSSValue(cgfloat: cardContainerBounds.width)
            let _previewComponent = MessageCardPreviewComponent<MessageCardPreviewContext>(
                props: MessageCardPreviewComponent.Props(card: cardContent),
                style: dynamicStyle,
                context: MessageCardPreviewContext(cardContent: CardContent.transform(cardContent: cardContent))
            )
            let _renderer = ASComponentRenderer(_previewComponent)
            let _cardContentView = _previewComponent.create(cardContainerBounds)
            _cardContentView.isUserInteractionEnabled = false
            self.cardContainer.addSubview(_cardContentView)
            _renderer.bind(to: _cardContentView)
            _renderer.render(_cardContentView)

            self.previewComponent = _previewComponent
            self.cardContentView = _cardContentView
            self.renderer = _renderer
            let size = _renderer.size()

            let box = UIView(frame: .zero)
            cardContainer.addSubview(box)
            box.snp.makeConstraints { make in make.edges.equalToSuperview() }

            box.addSubview(_cardContentView)
            _cardContentView.snp.makeConstraints { make in
                make.width.equalTo(size.width)
                make.height.equalTo(size.height)
                make.edges.equalToSuperview()
            }

            return size
        }
    }

    private func addAvators(chatItems: [Chat], containerWidth: CGFloat) -> CGFloat {
        let avatorMarginTop: CGFloat = 51.0
        let avatorMarginLeft: CGFloat = (20.0 / 364.0) * viewWidth()
        let avatorWidth: CGFloat = (40.0 / 364.0) * viewWidth()
        // 每行5个
        let lineNum = 5
        let gapWidth = (containerWidth - avatorMarginLeft * 2.0 - CGFloat(lineNum) * avatorWidth) / CGFloat(lineNum - 1)
        let gapHeight = (10.0 / 364.0) * viewWidth()

        var count = 0
        var topMargin: CGFloat = 0.0
        for chatItem in chatItems {
            let row = count / lineNum
            let line = count % lineNum
            let left = avatorMarginLeft + CGFloat(line) * (avatorWidth + gapWidth)
            let top = avatorMarginTop + CGFloat(row) * (avatorWidth + gapHeight)
            addAvator(avatorKey: chatItem.avatarKey, width: avatorWidth, left: left, top: top)
            topMargin = top + avatorWidth
            count += 1
        }

        return topMargin
    }

    private func addAvator(avatorKey: String,
                           width: CGFloat,
                           left: CGFloat,
                           top: CGFloat) {
        let frame = CGRect(x: 0, y: 0, width: width, height: width)
        let avator = AvatarImageView(frame: frame)
        avator.backgroundColor = .blue
        avator.layer.cornerRadius = width / 2.0
        avator.layer.masksToBounds = true
        container.addSubview(avator)
        avator.set(avatarKey: avatorKey)

        avator.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(top)
            make.left.equalToSuperview().offset(left)
            make.size.equalTo(CGSize(width: width, height: width))
        }
    }
}

class GradientView: UIView {
    public override class var layerClass: AnyClass {
       return CAGradientLayer.classForCoder()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayer()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupLayer()
    }

    func setupLayer() {
        if let gradientLayer = layer as? CAGradientLayer {
            gradientLayer.colors = [UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.04).cgColor, UIColor.ud.primaryOnPrimaryFill.cgColor]
            gradientLayer.startPoint = CGPoint(x: 0, y: 0)
            gradientLayer.endPoint = CGPoint(x: 0, y: 1)
        } else {
            self.backgroundColor = .clear
        }
    }
}
//注入到转发组件的逻辑实体
final class SendMessageCardForwardAlertProvider: ForwardAlertProvider {
    let disposeBag = DisposeBag()
    var realContent: SendMessageCardForwardAlertContent {
        content as! SendMessageCardForwardAlertContent
    }
    public override class func canHandle(content: ForwardAlertContent) -> Bool {
        if content as? SendMessageCardForwardAlertContent != nil {
            return true
        }
        return false
    }
    public override var shouldCreateGroup: Bool {
        if realContent.body.model.selectType == .user {
            return false
        }
        return realContent.body.model.allowCreateGroup
    }
    public override var isSupportMultiSelectMode: Bool {
        realContent.body.model.multiSelect
    }
    public override func getTitle(by items: [ForwardItem]) -> String? {
        !realContent.body.model.confirmTitle.isEmpty ? realContent.body.model.confirmTitle : BundleI18n.LarkOpenPlatform.Lark_Legacy_ChatViewSendTo
    }
    public override var needSearchOuterTenant: Bool {
        realContent.body.model.externalChat
    }

    required init(userResolver: UserResolver, content: ForwardAlertContent) {
        super.init(userResolver: userResolver, content: content)
        var param = ForwardFilterParameters()
        param.includeThread = false
        param.includeOuterChat = (content as? SendMessageCardForwardAlertContent)?.body.model.externalChat ?? true
        self.filterParameters = param
    }
    
    override func getFilter() -> ForwardDataFilter? {
        let ignoreSelf = realContent.body.model.ignoreSelf
        let ignoreBot = realContent.body.model.ignoreBot
        let selectType = realContent.body.model.selectType
        let userId = AccountServiceAdapter.shared.currentChatterId
        return { (item) -> Bool in
            if item.type == .user {
                if selectType == .group {
                    return false
                } else {
                    return ignoreSelf ? item.id != userId : true
                }
            } else if item.type == .chat {
                return (selectType != .user)
            } else if item.type == .bot {
                if ignoreBot == true {
                    return false
                } else {
                    return selectType != .group
                }
            }
            return true
        }
    }
    
    override func getForwardItemsIncludeConfigsForEnabled() -> IncludeConfigs? {
        let ignoreSelf = realContent.body.model.ignoreSelf
        let ignoreBot = realContent.body.model.ignoreBot
        let selectType = realContent.body.model.selectType
        let includeOuterChat = realContent.body.model.externalChat
        var includeConfigs = IncludeConfigs()
        switch selectType {
        case .all:
            includeConfigs = [
                ForwardUserEnabledEntityConfig(tenant: includeOuterChat ? .all : .inner, selfType: ignoreSelf ? .other : .all),
                ForwardGroupChatEnabledEntityConfig(tenant: includeOuterChat == false ? .inner : .all)
            ]
            if !ignoreBot {
                includeConfigs.append(ForwardBotEnabledEntityConfig())
            }
        case .user:
            includeConfigs = [
                ForwardUserEnabledEntityConfig(tenant: includeOuterChat ? .all : .inner, selfType: ignoreSelf ? .other : .all)
            ]
            if !ignoreBot {
                includeConfigs.append(ForwardBotEnabledEntityConfig())
            }
        case .group:
            includeConfigs = [
                ForwardGroupChatEnabledEntityConfig(tenant: includeOuterChat == false ? .inner : .all)
            ]
        }
        return includeConfigs
    }
    
    /// 设置转发模块include参数，未设置的将会被过滤
    /// - Returns: include参数
    public override func getForwardItemsIncludeConfigs() -> IncludeConfigs? {
        let needShowExternalChat = realContent.body.model.externalChat
        let includeConfigs: IncludeConfigs = [
            ForwardUserEntityConfig(tenant: needShowExternalChat ? .all : .inner),
            ForwardGroupChatEntityConfig(tenant: needShowExternalChat ? .all : .inner),
            ForwardBotEntityConfig()
        ]
        return includeConfigs
    }

    //返回消息卡片的view，添加到alert上
    public override func getContentView(by items: [ForwardItem]) -> UIView? {
        let view = realContent.body.view
        return view
    }
    
    public override func isShowInputView(by items: [ForwardItem]) -> Bool {
        return realContent.body.model.withText
    }
    public override func sureAction(items: [ForwardItem], input: String?, from: UIViewController) -> Observable<[String]> {
        let (chatids, userids, _) = itemsToIds(items)
        let api = realContent.body.cardAPI
        let cardkey = realContent.body.cardkey
        //这个接口返回的items里的chatid是option，需要先调用checkAndCreateChats搞出非optional的chatids
        checkAndCreateChats(chatIds: chatids, userIds: userids).observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] (chats) in
            guard let self = self else {
                return
            }
            let ctids = chats.map { (ch) -> String in
                ch.id
            }
            //  发送消息卡片的接口
            api.sendCard(chatIDs: ctids, cardKey: cardkey) { [weak api] (scsp) in
                guard let sendCardRsp = scsp, let api = api else {
                    let info = MessageCardErr.sendCardError(-1000, nil).getCallBackResult()
                    let (errCode, errMsg, failedOpenIDs, sendCardInfos, sendTextInfos) = info
                    self.realContent.body.res(errCode, errMsg, failedOpenIDs, sendCardInfos, ctids, sendTextInfos)
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
                    if let text = input, !text.isEmpty {
                        MessageCardPrewController.logger.info("send text start")
                        api.sendText(chatIDMaps: sendCardRsp.chatIdToOpenChatIdMap(),
                                     message: text) { [weak self] (error, sendTextInfos) in
                            guard let self = self else {
                                return
                            }
                            if error == nil {
                                let info = MessageCardErr.ok.getCallBackResult(sendInfos: sendCardInfos, sendTextInfo: sendTextInfos)
                                let (errCode, errMsg, failedOpenIDs, sendCardInfos, sendTextInfos) = info
                                self.realContent.body.res(errCode, errMsg, failedOpenIDs, sendCardInfos, ctids, sendTextInfos)
                            } else {
                                let info = MessageCardErr
                                    .sendTextError(nil)
                                    .getCallBackResult(sendInfos: sendCardInfos, sendTextInfo: sendTextInfos)
                                let (errCode, errMsg, failedOpenIDs, sendCardInfos, sendTextInfos) = info
                                self.realContent.body.res(errCode, errMsg, failedOpenIDs, sendCardInfos, ctids, sendTextInfos)
                            }
                        }
                    } else {
                        let info = MessageCardErr.ok.getCallBackResult(sendInfos: sendCardInfos)
                        let (errCode, errMsg, failedOpenIDs, sendCardInfos, sendTextInfos) = info
                        self.realContent.body.res(errCode, errMsg, failedOpenIDs, sendCardInfos, ctids, sendTextInfos)
                    }
                    return
                } else {
                    let info = MessageCardErr.sendCardError(Int(sendCardRsp.status), failedOpenChatIDs).getCallBackResult(sendInfos: sendCardInfos)
                    let (errCode, errMsg, failedOpenIDs, sendCardInfos, sendTextInfos) = info
                    self.realContent.body.res(errCode, errMsg, failedOpenIDs, sendCardInfos, ctids, sendTextInfos)
                }
            }
        }, onError: { [weak self] (error) in
            guard let self = self else {
                return
            }
            let info = MessageCardErr.sendCardError(-1000, nil).getCallBackResult()
            let (errCode, errMsg, failedOpenIDs, sendCardInfos, sendTextInfos) = info
            self.realContent.body.res(errCode, errMsg, failedOpenIDs, sendCardInfos, [], sendTextInfos)
        }).disposed(by: self.disposeBag)
        return .just([])
    }

    public override func dismissAction (){
        let info = MessageCardErr.userCancelSend.getCallBackResult()
        let (errCode, errMsg, failedOpenIDs, sendCardInfos, sendTextInfos) = info
        self.realContent.body.res(errCode, errMsg, failedOpenIDs, sendCardInfos, [], sendTextInfos)
    }
}
//这个对象在上面的SendMessageCardForwardAlertProvider可以拿到
final class SendMessageCardForwardAlertContent: ForwardAlertContent {
    public let body: SendMessageCardForwardAlertBody
    
    public init( body: SendMessageCardForwardAlertBody) {
        self.body = body
    }
}
//传入数据全部放入body
final class SendMessageCardForwardAlertBody: PlainBody {
    public static let pattern = "//client/forward/sendMessageCardForwardAlert"
    public let cardkey: String
    let cardAPI: MessageCardAPI
    public let appid: String
    public let cardContent: [AnyHashable: Any]
    public let model: SendMessagecardChooseChatModel
    public let view: UIView
    public let res: InternalSendMessageCardCallBack
    init(
        cardkey: String,
        cardAPI: MessageCardAPI,
        appid: String,
        cardContent: [AnyHashable: Any],
        model: SendMessagecardChooseChatModel,
        view: UIView,
        res: @escaping InternalSendMessageCardCallBack
    ) {
        self.cardkey = cardkey
        self.cardAPI = cardAPI
        self.appid = appid
        self.cardContent = cardContent
        self.view = view
        self.model = model
        self.res = res
    }
}
//打开转发组件的路由
final class SendMessageCardForwardAlertHandler: UserTypedRouterHandler {
    @FeatureGating("im.chatterpicker.forward") var chatterpickerFG: Bool

    public func handle(_ body: SendMessageCardForwardAlertBody, req: EENavigator.Request, res: Response) throws {
        createForward(body: body, req: req, res: res)
    }

    func createForward(body: SendMessageCardForwardAlertBody, req: EENavigator.Request, res: Response) {
        let content = SendMessageCardForwardAlertContent(body: body)
        let factory = ForwardAlertFactory(userResolver: userResolver)
        guard let provider = factory.createWithContent(content: content) else { return }
        provider.permissions = [.checkBlock]
        let accountService = AccountServiceAdapter.shared
        let tenantId = accountService.currentTenant.tenantId
        let enableDocCustomIconFg = LarkFeatureGating.shared.getFeatureBoolValue(for: .docCustomAvatarEnable)
        if chatterpickerFG {
            let router = resolver.resolve(ForwardViewControllerRouterProtocol.self)!
            let vc = NewForwardViewController(provider: provider, router: router)
            let nvc = LkNavigationController(rootViewController: vc)
            res.end(resource: nvc)
            return
        }
        let userService = try? resolver.resolve(assert: PassportUserService.self)
        let viewModel = ForwardViewModel(feedSyncDispatchService: resolver.resolve(FeedSyncDispatchService.self)!,
                                         currentTenantId: tenantId,
                                         provider: provider,
                                         enableThreadMiniIconFg: false,
                                         enableDocCustomIconFg: enableDocCustomIconFg,
                                         serverNTPTimeService: resolver.resolve(ServerNTPTimeService.self)!,
                                         modelService: resolver.resolve(ModelService.self)!,
                                         userTypeObservable: userService?.state.map { $0.user.type } ?? .never())
        let router = resolver.resolve(ForwardViewControllerRouter.self)!
        let vc = ForwardViewController(viewModel: viewModel, router: router)
        let nvc = LkNavigationController(rootViewController: vc)
        res.end(resource: nvc)
    }
}

