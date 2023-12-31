//
//  DynamicContentViewModel.swift
//  NewLarkDynamic
//
//  Created by qihongye on 2019/6/23.
//

import Foundation
import EENavigator
import EEAtomic
import RxSwift
import AsyncComponent
import EEFlexiable
import NewLarkDynamic
import LarkModel
import LarkMessageCore
import LarkMessageBase
import struct LarkSDKInterface.PushCardMessageActionResult
import RustPB
import LKCommonsLogging
import LarkFeatureGating
import LarkMessengerInterface
import UniverseDesignIcon
import EEMicroAppSDK
import LarkSetting

private let logger = Logger.log(LDContext.self, category: "LarkNewDynamic.DynamicContentViewModel")
private struct Styles {
    static let PinContentMaxHeight: CGFloat = 240.0
    static let PinBottomGradientHeight: CGFloat = 30.0
    static let ContainerCornerRadius: CGFloat = 8.0
    static let ContainerMargin: CGFloat = 12.0
    static let HorizontalMargin: CGFloat = 12.0
    static let VerticalMargin: CGFloat = 8.0
}

protocol DynamicContentViewModelContext: ViewModelContext, ColorConfigContext {
    /// 场景
    var scene: ContextScene { get }

    var pushCardMessageActionObserver: Observable<PushCardMessageActionResult> { get }

    func getContentMaxHeight(_ message: Message) -> CGFloat

    /// 创建每个卡片需要的Context
    func createDynamicContext(_ message: Message, chat: @escaping () -> Chat, metaModelDependency: CellMetaModelDependency) -> CardContext?

    func isMe(_ chatterID: String) -> Bool
    /// 获取cell的最大宽度，根据最大宽度决定是否使用宽版卡片还是窄版卡片
    func getCellMaxWidth() -> CGFloat?
    /// 获取卡片展示的最期望的宽度
    func preferMaxWidth(_ message: Message, _ contentPreferMaxWidth: CGFloat) -> CGFloat
    /// 最大的卡片宽度限制
    func maxCardWidthLimit(_ message: Message, _ contentPreferMaxWidth: CGFloat) -> CGFloat
}

final class DynamicContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: DynamicContentViewModelContext>: MessageSubViewModel<M, D, C> {
    public override var identifier: String {
        return "dynamic"
    }

    var content: CardContent {
        // swiftlint:disable:next force_cast
        return message.content as! CardContent
    }

    public var richtext: RustPB.Basic_V1_RichText {
        return darkmodeRichText ?? content.richText
    }

    @SafeLazy
    public var showMoreBackgroundColors: [UIColor]

    public var hasCornerRadius: Bool {
        return self.context.scene != .newChat
    }

    public var isShowMore: Bool = false {
        didSet {
            if isShowMore != oldValue {
                binder.update(with: self)
                update(component: binder.component)
            }
        }
    }

    public var isAutoFold: Bool = false
    #if BETA || ALPHA || DEBUG
    fileprivate var messageCardDebugIsOn: Bool {
        return EMADebugUtil.sharedInstance()?.debugConfig(forID: kEMADebugConfigMessageCardDebugTool)?.boolValue ?? false
    }
    #endif

    public var maxHeight: CGFloat? {
        if context.scene == .pin { return Styles.PinContentMaxHeight }
        if !isAutoFold { return nil }
        let maxHeight = context.getContentMaxHeight(message)
        guard maxHeight > 0 else { return nil }
        return maxHeight
    }

    public override func shouldUpdate(_ new: Message) -> Bool {
        // @qhy 服务器原因，updateTime没有更新
        return true
        //return message.updateTime != new.updateTime
    }

    private let threadReplyBubbleOptimize = FeatureGatingManager.shared.featureGatingValue(with: "im.message.thread_reply_bubble_optimize")
    public override var contentConfig: ContentConfig? {
        // 当翻译开关打开, 且需要显示翻译的 component 时才隐藏边框
        var hasBorder = true
        var backgroundStyle: ContentConfig.BackgroundStyle? = .white
        if isCanTranslateCard {
            hasBorder = !(message.isTranslated() && context.scene != .pin)
            backgroundStyle = context.isMe(message.fromId) ? .white : .gray
        }
        // 话题回复不固定气泡的最大宽度，会导致话题回复区域渲染超出气泡
        if (context.scene == .newChat || context.scene == .mergeForwardDetail), (message.showInThreadModeStyle && !message.displayInThreadMode), threadReplyBubbleOptimize {
            var config = ContentConfig(
                hasMargin: false,
                backgroundStyle: backgroundStyle,
                maskToBounds: true,
                supportMutiSelect: !message.isEphemeral,
                hasBorder: hasBorder
            )
            config.isCard = true
            return config
        }
        var config = ContentConfig(
            hasMargin: false,
            backgroundStyle: backgroundStyle,
            maskToBounds: true,
            supportMutiSelect: !message.isEphemeral,
            contentMaxWidth: context.maxCardWidthLimit(message, metaModelDependency.getContentPreferMaxWidth(message)),
            hasBorder: hasBorder
        )
        config.isCard = true
        return config
    }

    public var preferMaxWidth: CGFloat {
        return context.preferMaxWidth(message, metaModelDependency.getContentPreferMaxWidth(message))
    }

    fileprivate var isCanTranslateCard = false
    private var darkmodeRichText: RustPB.Basic_V1_RichText?
    private func updateDarkModeStyle() {
        guard let cardContent = message.content as? CardContent else {
            logger.error("init DynamicMaskViewComponent with wrong content")
            return
        }
        let version = cardContent.version
        let style = MessageCardStyleManager.shared.messageCardStyle()
        let darkprocess = RichTextDarkModePreProcessor(cardVersion: Int(version),
                                                       cardStyle: style,
                                                       styleCache: MessageCardStyleManager.shared)
        self.darkmodeRichText = darkprocess.richTextApplyDarkMode(originRichText: cardContent.richText)
    }
    public override init(metaModel: M, metaModelDependency: D, context: C, binder: ComponentBinder<C>) {
        let isFromMe = context.isMe(metaModel.message.fromId)
        _showMoreBackgroundColors = SafeLazy {
            let topColor = context.getColor(for: .Message_Mask_GradientTop, type: isFromMe ? .mine : .other)
            let bottomColor = context.getColor(for: .Message_Mask_GradientBottom, type: isFromMe ? .mine : .other)
            return [topColor, bottomColor]
        }
        isCanTranslateCard = TranslateControl.isTranslatableMessageCardType(metaModel.message)
        super.init(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context, binder: binder)
        updateDarkModeStyle()
    }

    // NOTE: 为什么这里要override？
    // 因为经这里会导致隐式的upcast，导致crash，这里面通过as告诉编译器生成的代码不要做upcast绕过此问题
    public override func syncToBinder() {
        self.binder.update(with: self as DynamicContentViewModel<M, D, C>)
    }

    public func showMore() {
        isAutoFold = false
        isShowMore = false
    }

    public func shouldShowMore() {
        if isAutoFold {
            isShowMore = true
        }
    }
}

protocol DynamicMaskViewDelegate: AnyObject {
    func outofMaxHeightCallback()
}

final class DynamicMaskView: UIView {
    weak var delegate: DynamicMaskViewDelegate?
    var maxHeight: CGFloat?

    public override func layoutSubviews() {
        let isOutofBounds = checkOutofBounds()
        if isOutofBounds {
            delegate?.outofMaxHeightCallback()
            layer.masksToBounds = true
        }
        return super.layoutSubviews()
    }

    private func checkOutofBounds() -> Bool {
        guard let height = maxHeight, height > 0 else {
            return false
        }
        for v in subviews {
            if let rootView = v as? LDRootView,
                rootView.convert(rootView.bounds, to: self).maxY > height {
                return true
            }
        }
        return false
    }
}

final class DynamicMaskViewComponent<C: DynamicContentViewModelContext>: ASComponent<DynamicMaskViewComponent.Props, EmptyState, DynamicMaskView, C> {
    final class Props: ASComponentProps {
        public var message: Message {
            didSet {
                updateDarkModeStyle()
            }
        }
        public var displayRule: RustPB.Basic_V1_DisplayRule {
            return message.displayRule
        }
        public var chat: () -> Chat
        public var contentPadding: CGFloat
        public var headerTitle: String
        public var headerTitleColor: UIColor
        public var headerBackgroundColors: [UIColor]
        public var theme: String
        public var iconProperty: RichTextElement.ImageProperty?
        public var subTitle:String?
        public var maxHeight: CGFloat?
        public var isShowMore: Bool = false
        public var showMoreBackgroundColors: [UIColor] = []
        public var showMoreHandler: (() -> Void)?
        public var shouldShowMore: (() -> Void)?
        public var hasCornerRadius: Bool = true
        public var isUserInteractionEnabled: Bool = true
        public var metaModelDependency: CellMetaModelDependency

        var richtext: RustPB.Basic_V1_RichText {
            return darkmodeRichText ?? (message.content as? CardContent)?.richText ?? RustPB.Basic_V1_RichText()
        }
        private var darkmodeRichText: RustPB.Basic_V1_RichText?
        /// 翻译后的 richText
        /// 为避免新增的翻译业务对原逻辑造成影响, 5.18 仅新增翻译业务,不修改原逻辑
        /// 预计 5.20 版本以前会对翻译及非翻译代码做优化, majiaxin.jx
        var translatedContent: CardContent? {
            return message.translateContent as? CardContent
        }
        var translatedRichText: RustPB.Basic_V1_RichText? {
            return translatedDarkmodeRichText ?? translatedContent?.richText
        }
        private var translatedDarkmodeRichText: RustPB.Basic_V1_RichText?
        
        private func updateDarkModeStyle() {
            guard let content = message.content as? CardContent else {
                logger.error("meesage content is not CardContent")
                return
            }
            self.darkmodeRichText = RichTextDarkModePreProcessor(
                cardVersion: Int(content.version),
                cardStyle:  MessageCardStyleManager.shared.messageCardStyle(),
                styleCache: MessageCardStyleManager.shared
            ).richTextApplyDarkMode(originRichText: content.richText)
            
            /// 为避免新增的翻译业务对原逻辑造成影响, 5.18 仅新增翻译业务,不修改原逻辑
            /// 预计 5.20 版本以前会对翻译及非翻译代码做优化, majiaxin.jx
            guard TranslateControl.isTranslatableMessageCardType(message),
                  let translateContent = translatedContent else {
                return
            }
            self.translatedDarkmodeRichText = RichTextDarkModePreProcessor(
                cardVersion: Int(translateContent.version),
                cardStyle:  MessageCardStyleManager.shared.messageCardStyle(),
                styleCache: MessageCardStyleManager.shared
            ).richTextApplyDarkMode(originRichText: translateContent.richText)
        }
        
        public init(message: Message,
                    chat: @escaping () -> Chat,
                    contentPadding: CGFloat,
                    metaModelDependency: CellMetaModelDependency,
                    headerTitle: String,
                    headerTitleColor: UIColor,
                    headerBackgroundColors: [UIColor],
                    headerTheme: String = "",
                    iconProperty: RichTextElement.ImageProperty? = nil,
                    subTitle:String? = nil) {
            self.message = message
            self.contentPadding = contentPadding
            self.metaModelDependency = metaModelDependency
            self.headerTitle = headerTitle
            self.headerTitleColor = headerTitleColor
            self.headerBackgroundColors = headerBackgroundColors
            self.iconProperty = iconProperty
            self.subTitle = subTitle
            self.chat = chat
            self.theme = headerTheme
            super.init()
            updateDarkModeStyle()
        }
    }

    let ldHeaderProps = LDHeaderComponent<CardContext>.Props()

    
    @FeatureGatingValue(key: "messagecard.support.translate.moreaction")
    var messageCardEnableTranslateMore: Bool
    
    // 以下三个成员变量,最好而言是作为常量而非成员变量存在,否者容易在使用同一个 style 时互相影响,但因为会影响到老代码,所以暂时不在这个版本修改
    // 预计 5.20 对整个类做小重构 majiaxin.jx
    private var ldHeaderStyle: ASComponentStyle = {
        let style = ASComponentStyle()
        style.height = 0
        style.top = 0
        style.flexShrink = 0
        style.overflow = .scroll
        return style
    }()
    
    private var contentStyle: ASComponentStyle = {
        let style = ASComponentStyle()
        style.flexShrink = 0
        style.overflow = .scroll
        return style
    }()
    
    private var splitLineStyle: ASComponentStyle = {
        let style = ASComponentStyle()
        let marginH = CSSValue(cgfloat: Styles.HorizontalMargin)
        let marginV = CSSValue(cgfloat: Styles.VerticalMargin)
        style.marginLeft = marginH
        style.marginRight = marginH
        style.marginTop = marginV
        style.marginBottom = marginV
        return style
    }()
    
    private var cardContext: CardContext?
    
    private var messageCardTranslateActionHandler: MessageCardTranslateActionHandler?
    
    private var ldHeaderComponent: LDHeaderComponent<CardContext>?

    private var dynamicComponent: LDRootComponent<CardContext>?
    /**
     为避免新增的翻译业务对原逻辑造成影响, 5.18 仅新增翻译业务,不修改原逻辑
     预计 5.20 版本以前会对翻译及非翻译代码做优化, majiaxin.jx
     */
    /// 翻译的 Header 组件
    private var translatedHeaderComponent: LDHeaderComponent<CardContext>?
    /// 翻译的 Content 组件
    private var translatedContentComponent: LDRootComponent<CardContext>?
    /// 卡片 Components 集合
    private var cardComponents: ComponentWithSubContext<C, CardContext>?
    /// 翻译 分割线
    private lazy var translateSplitLineComponent: TranslateSplitLineComponent<CardContext> = {
        return TranslateSplitLineComponent(
            props: TranslateSplitLineComponent<CardContext>.Props(text: BundleI18n.LarkOpenPlatform.OpenPlatform_MessageCard_Translation),
            style: splitLineStyle
        )
    }()
    
    private lazy var showMoreComponent: ShowMoreMaskViewComponent<C> = {
        let style = ASComponentStyle()
        style.display = .none
        style.position = .absolute
        style.left = 1
        style.right = 1
        style.bottom = 0
        style.height = 60
        style.cornerRadius = 9
        return ShowMoreMaskViewComponent(
            props: ShowMoreMaskViewComponent<C>.Props(),
            style: style,
            context: context
        )
    }()
    
    private lazy var pinMaskComponent: MessageCardPinMaskComponent<C> = {
        let style = ASComponentStyle()
        style.display = .flex
        style.position = .absolute
        style.left = 0
        style.right = 0
        style.bottom = -1
        style.height = CSSValue(cgfloat: Styles.PinBottomGradientHeight)
        return MessageCardPinMaskComponent(
            props: MessageCardPinMaskComponent<C>.Props(),
            style: style,
            context: context
        )
    }()

    /// 翻译反馈style
    private lazy var translateRightButtonStyle: ASComponentStyle = {
        let style = ASComponentStyle()
        style.marginBottom = CSSValue(cgfloat: Styles.VerticalMargin)
        style.marginLeft = CSSValue(cgfloat: Styles.ContainerMargin)
        style.marginTop = CSSValue(cgfloat: Styles.VerticalMargin)
        return style
    }()

    private lazy var translateFeedBackButton: RightButtonComponent<CardContext> = {
        return  RightButtonFactory.create(name:BundleI18n.LarkOpenPlatform.OpenPlatform_MessageCard_TranslationFeedbackRateButton,
                                          action: { [weak self] in
            self?.translateFeedBackTapHandler()
        }, style: translateRightButtonStyle)
    }()

    /// 翻译 action props
    private lazy var translateActionProps: TranslateActionComponent<CardContext>.Props = {
        let props = TranslateActionComponent<CardContext>.Props()
        props.translateFeedBackTapHandler = { [weak self] in
            self?.messageCardTranslateActionHandler?.translateFeedBackTapHandler()
        }
        props.translateMoreActionTapHandler = { [weak self] view in
            self?.messageCardTranslateActionHandler?.translateMoreTapHandler(view)
        }
        return props
    }()
    /// 翻译 action style
    private lazy var translateActionStyle: ASComponentStyle = {
        let style = ASComponentStyle()
        style.justifyContent = .spaceBetween
        style.marginBottom = CSSValue(cgfloat: Styles.VerticalMargin)
        style.marginLeft = CSSValue(cgfloat: Styles.ContainerMargin)
        style.marginRight = CSSValue(cgfloat: Styles.ContainerMargin)
        style.marginTop = CSSValue(cgfloat: Styles.VerticalMargin)
        return style
    }()
    
    /// 翻译 action component
    private lazy var translateActionComponent: TranslateActionComponent<CardContext> = {
        return TranslateActionComponent<CardContext>(props: translateActionProps, style: translateActionStyle)
    }()
    
    #if BETA || ALPHA || DEBUG
    private lazy var debugButton: RightButtonComponent<CardContext> = {
        return  self.GetDebugButton()
    }()
    fileprivate var messageCardDebugIsOn: Bool {
        return EMADebugUtil.sharedInstance()?.debugConfig(forID: kEMADebugConfigMessageCardDebugTool)?.boolValue ?? false
    }
    #endif
    fileprivate var isCanTranslateCard = false

    public override init(props: Props, style: ASComponentStyle, context: C? = nil) {
        //消息更新，message可能会更换
        //这里可以确保拿到的是PageContext
        if let context = context as? PageContext {
            messageCardTranslateActionHandler = MessageCardTranslateActionHandler(context: context, chat: props.chat, message: props.message)
        }
       
        /**
         为避免新增的翻译业务对原逻辑造成影响, 5.18 仅新增翻译业务,不修改原逻辑
         预计 5.20 版本以前会对翻译及非翻译代码做优化, majiaxin.jx
         */
        isCanTranslateCard = TranslateControl.isTranslatableMessageCardType(props.message)

        if isCanTranslateCard {
            cardContext = context?.createDynamicContext(props.message, chat: props.chat, metaModelDependency: props.metaModelDependency)
            style.flexWrap = .noWrap
            style.flexDirection = .column
            style.alignItems = .stretch
            style.overflow = .scroll
            let cardComponents = CardContext.provider(
                context: context,
                buildSubContext: { [weak cardContext] (context) -> CardContext? in
                    return cardContext
                }, children: []
            )
            self.cardComponents = cardComponents
            super.init(props: props, style: style, context: context)
            setupCardComponents(props: props, context: cardContext)
            var subComponents = [cardComponents, showMoreComponent]
            if context?.scene == .pin { subComponents.append(pinMaskComponent) }
            setSubComponents(subComponents)
            return
        }
        let ldContext = context?.createDynamicContext(props.message, chat: props.chat, metaModelDependency: props.metaModelDependency)
        let content = (props.message.content as! CardContent)
        let originProps = LDRootComponentProps(richtext: props.richtext,
                                               cardContent: content)
        
        let dynamicComponent = LDRootComponent<CardContext>(
            props: originProps,
            style: contentStyle,
            context: ldContext
        )
        style.flexWrap = .noWrap
        style.flexDirection = .column
        style.alignItems = .stretch
        style.overflow = .scroll
        ldHeaderProps.theme = props.theme
        let ldHeaderComponent = LDHeaderComponent<CardContext>(props: ldHeaderProps, style: ldHeaderStyle, context: ldContext)
        self.dynamicComponent = dynamicComponent
        self.ldHeaderComponent = ldHeaderComponent
        super.init(props: props, style: style, context: context)
        var components = [ldHeaderComponent, dynamicComponent]
        #if BETA || ALPHA || DEBUG
        if messageCardDebugIsOn {
            components.append(debugButton)
        }
        #endif
        var subComponents = [
            CardContext.provider(context: context, buildSubContext: { [weak ldContext] (context) -> CardContext? in
                return ldContext
            }, children: components),
            showMoreComponent
        ]
        if context?.scene == .pin {
            subComponents.append(pinMaskComponent)
        }
        setSubComponents(subComponents)
        setUpCopySummerize(ldContext, message: props.message)
    }
    
    // 获取摘要填在cardContent新增summerize属性里，给消息卡片全局复制使用
    func setUpCopySummerize(_ ldcontext: LDContext?, message: Message) {
        guard let ldcontext = ldcontext,
        var cardContent = message.content as? CardContent else {
            return
        }
        cardContent.summary = CardModelSummerizeFactory().getCopySummerize(message: message, context: ldcontext)
        message.content = cardContent
    }
    
    public override func create(_ rect: CGRect) -> DynamicMaskView {
        let view = DynamicMaskView()
        view.maxHeight = props.maxHeight
        view.delegate = self
        view.frame = rect
        view.isAccessibilityElement = true
        view.accessibilityIdentifier = "DynamicMaskView"
        view.isUserInteractionEnabled = props.isUserInteractionEnabled
        return view
    }

    public override func update(view: DynamicMaskView) {
        view.maxHeight = props.maxHeight
        view.delegate = self
        super.update(view: view)
    }

    public override func willReceiveProps(_ old: Props, _ new: Props) -> Bool {
        //消息更新，message可能会更换
        if let context = context as? PageContext,
           let messageCardTranslateActionHandler = messageCardTranslateActionHandler {
            messageCardTranslateActionHandler.update(context: context, chat: new.chat, message: new.message)
        } else {
            logger.error("messageCardTranslateActionHandler update failed",additionalData: [
                "MessageID": new.message.id,
                "traceId": cardContext?.trace.traceId ?? ""
            ])
        }
        /**
         为避免新增的翻译业务对原逻辑造成影响, 5.18 仅新增翻译业务,不修改原逻辑
         预计 5.20 版本以前会对翻译及非翻译代码做优化, majiaxin.jx
         */
        if isCanTranslateCard {
            setupCardComponents(props: new, context: cardContext)
            return true
        }
        
        dynamicComponent?.context?.setupCardEnv(message: new.message)
        let props = LDRootComponentProps(richtext: props.richtext,
                                               cardContent: new.message.content as! CardContent)
        
        showMoreComponent.style.display = new.isShowMore ? .flex : .none
        /// 背景色
        showMoreComponent.props.backgroundColors = new.showMoreBackgroundColors
        showMoreComponent.props.showMoreHandler = { [weak new] in
            new?.showMoreHandler?()
        }
        
        let hasHeader = !new.headerTitle.isEmpty
        ldHeaderComponent?.style.height = hasHeader ? YGValueAuto : 0
        ldHeaderProps.text = new.headerTitle
        ldHeaderProps.backgroundColors = new.headerBackgroundColors
        ldHeaderProps.theme = new.theme
        ldHeaderProps.textColor = new.theme.themeHeaderBGColor() ?? new.headerTitleColor
        ldHeaderProps.iconProperty = new.iconProperty
        ldHeaderProps.subTitle = new.subTitle
        ldHeaderComponent?.props = ldHeaderProps
        
        let padding = CSSValue(cgfloat: new.contentPadding)
        dynamicComponent?.style.paddingTop = hasHeader ? 0 : padding
        dynamicComponent?.style.paddingLeft = padding
        dynamicComponent?.style.paddingRight = padding
        dynamicComponent?.style.paddingBottom = padding
        dynamicComponent?.context?.updateMessage(message: new.message)
        dynamicComponent?.props = props
        setUpCopySummerize(dynamicComponent?.context,message: new.message)
        return true
    }

    public override func render() -> BaseVirtualNode {
        if props.isShowMore, let maxHeight = props.maxHeight {
            style.maxHeight = CSSValue(cgfloat: maxHeight)
        } else if context?.scene == .pin, let maxHeight = props.maxHeight {
            style.maxHeight = CSSValue(cgfloat: maxHeight)
        } else {
            style.maxHeight = CSSValueUndefined
        }
        return super.render()
    }

    func translateFeedBackTapHandler() {
        if let translateFeedBackService = (self.context as? ChatContext)?.resolver.resolve(TranslateFeedbackService.self),
           let targetVC = (self.context as? ChatContext)?.pageAPI {
            translateFeedBackService.showTranslateFeedbackView(message: props.message, fromVC: targetVC)
            return
        }
        logger.error("resolve TranslateFeedbackService failed or get TargetVC faild")
    }
}

extension Message {
    fileprivate func isTranslated() -> Bool {
        return translateContent != nil &&
        (displayRule == .onlyTranslation || displayRule == .withOriginal)
    }
}

extension DynamicMaskViewComponent {
    enum CardContentCotnainerType {
        case origin
        case translate
    }
    
    fileprivate static func needOriginComponent(props: Props, context: CardContext?) -> Bool {
        // pin 或 非翻译态 或 翻译态+原文态均需要添加原文
        return context?.scene == .pin || !props.message.isTranslated() || props.displayRule == .withOriginal
    }
    
    fileprivate static func needTranbslatedStyle(props: Props, context: CardContext?) -> Bool {
        return props.message.isTranslated() && context?.scene != .pin
    }
    
    fileprivate static func getSplitLineMarginTop(props: Props) -> CSSValue {
        return CSSValue(cgfloat: props.displayRule == .onlyTranslation ?
            Styles.ContainerMargin : Styles.VerticalMargin
        )
    }
    
    fileprivate static func getCardContentStyle(
        props: Props, type: CardContentCotnainerType, context: CardContext?
    ) -> ASComponentStyle {
        let isTranslate = needTranbslatedStyle(props: props, context: context)
        let borderWidth = isTranslate ? (1 / UIScreen.main.scale) : 0
        let style = ASComponentStyle()
        let margin = CSSValue(cgfloat: Styles.ContainerMargin)
        style.marginTop = (isTranslate && type == .origin) ? margin : 0
        style.marginBottom = 0
        style.marginRight = isTranslate ? margin : 0
        style.marginLeft = isTranslate ? margin : 0
        style.flexWrap = .noWrap
        style.flexDirection = .column
        style.alignItems = .stretch
        style.overflow = .scroll
        style.border = Border(BorderEdge(
            width: borderWidth,
            color: UIColor.ud.lineBorderCard,
            style: .solid)
        )
        style.cornerRadius = isTranslate ? Styles.ContainerCornerRadius : 0
        return style
    }
    
    fileprivate func setupHeaderComponent(
        _ component: LDHeaderComponent<CardContext>?,
        withContent content: CardContent, context context: CardContext?
    ) -> LDHeaderComponent<CardContext> {
        var props = LDHeaderComponent<CardContext>.Props()
        props.text = content.header.getTitle() ?? ""
        props.backgroundColors = content.header.backgroundColors
        props.theme = content.header.theme
        props.textColor = content.header.theme.themeHeaderBGColor() ?? content.header.color
        props.iconProperty = content.header.hasIcon ? content.header.icon : nil
        props.subTitle = content.header.hasSubtitle ? content.header.subtitle : nil
        let headerComponent = component ?? LDHeaderComponent<CardContext>(
            props: props, style: ldHeaderStyle.clone(), context: context
        )
        headerComponent.style.height = !content.header.isEmptyTitle() ? YGValueAuto : 0
        headerComponent.props = props
        return headerComponent
    }
    
    fileprivate func setupContentComponent(
        _ component: LDRootComponent<CardContext>?,
        withMessage message: Message,
        richText richText: RichText,
        content content: CardContent,
        context context: CardContext?,
        translateLocale translateLocale: Locale? = nil
    ) -> LDRootComponent<CardContext> {
        let props = LDRootComponentProps(richtext: richText, cardContent: content, translateLocale: translateLocale)
        let contentComponent = component ?? LDRootComponent<CardContext>(
            props: props, style: contentStyle.clone(), context: context
        )
        let padding = CSSValue(cgfloat: Styles.ContainerMargin)
        contentComponent.style.paddingTop = (content.header.isEmptyTitle()) ? padding : 0
        contentComponent.style.paddingLeft = padding
        contentComponent.style.paddingRight = padding
        contentComponent.style.paddingBottom = padding
        contentComponent.context?.setupCardEnv(message: message)
        contentComponent.context?.updateMessage(message: message)
        contentComponent.props = props
        return contentComponent
    }
    
    fileprivate func setupCardComponents(props: Props, context: CardContext?) {
        let displayRule = props.displayRule
        // 移除所有子视图, 重新生成
        cardComponents?.children.removeAll()
        // 添加原文相关 component
        if Self.needOriginComponent(props: props, context: context),
           let content = props.message.content as? CardContent {
            let headerComponent = setupHeaderComponent(
                ldHeaderComponent,
                withContent: content, context: context
            )
            ldHeaderComponent = headerComponent
            @FeatureGating("messagecard.richtext.useprops")
            var usePropsRichText: Bool
            let richText = usePropsRichText ? props.richtext : content.richText

            let contentComponent = setupContentComponent(
                dynamicComponent,
                withMessage: props.message, richText: richText, content: content, context: context
            )
            dynamicComponent = contentComponent
            
            let cardContainer = UIViewComponent<CardContext>(
                props: .empty, style: Self.getCardContentStyle(props: props, type: .origin, context: context)
            )
            cardContainer.setSubComponents([headerComponent, contentComponent])
            cardComponents?.children.append(cardContainer)
        }
        // 添加译文相关 component, pin 不展示为译文态
        if Self.needTranbslatedStyle(props: props, context: context),
           let translatedContent = props.translatedContent,
           let richText = props.translatedRichText {
            let headerComponent = setupHeaderComponent(
                translatedHeaderComponent,
                withContent: translatedContent, context: context
            )
            translatedHeaderComponent = headerComponent
            let contentComponent = setupContentComponent(
                translatedContentComponent,
                withMessage: props.message,
                richText: richText,
                content: translatedContent,
                context: context,
                translateLocale: Locale(identifier: props.message.translateLanguage)
            )
            translatedContentComponent = contentComponent
            let cardContainer = UIViewComponent<CardContext>(
                props: .empty, style: Self.getCardContentStyle(props: props, type: .translate, context: context)
            )
            cardContainer.setSubComponents([headerComponent, contentComponent])
            // 仅显示
            translateSplitLineComponent.style.marginTop = Self.getSplitLineMarginTop(props: props)
            cardComponents?.children.append(translateSplitLineComponent)
            cardComponents?.children.append(cardContainer)
            if messageCardEnableTranslateMore {
                cardComponents?.children.append(translateActionComponent)
            } else {
                cardComponents?.children.append(translateFeedBackButton)
            }
        }
        //可翻译的卡片更新摘要
        setUpCopySummerize(context, message: props.message)
        #if BETA || ALPHA || DEBUG
        if messageCardDebugIsOn {
            self.cardComponents?.children.append(debugButton)
        }
        #endif
    }
}

extension DynamicMaskViewComponent: DynamicMaskViewDelegate {
    func outofMaxHeightCallback() {
        self.props.shouldShowMore?()
    }
}

extension CardContent.CardHeader {
    public var color: UIColor {
        if let cssColor = StyleHelpers.parseColor(colorKey: "color",
                                                  style: style) {
            return cssColor
        }
        return UIColor.ud.N900
    }

    public var backgroundColors: [UIColor] {
        var colors = [UIColor]()
        if let startColor = StyleHelpers.parseColor(
            colorKey: "startColor",
            style: style) {
            colors.append(startColor)
        }
        if let endColor = StyleHelpers.parseColor(
            colorKey: "endColor",
            style: style) {
            colors.append(endColor)
        }
        return colors
    }
}

final class DynamicContentViewModelBinder<M: CellMetaModel, D: CellMetaModelDependency, C: DynamicContentViewModelContext>: ComponentBinder<C> {
    private var props: DynamicMaskViewComponent<C>.Props
    private var _component: DynamicMaskViewComponent<C>?
    private let message: Message

    public override var component: ComponentWithContext<C> {
        guard let _component else { fatalError("should nevier go here")}
        return _component
    }

    public init(message: Message, chat: @escaping () -> Chat, metaModelDependency: D, key: String? = nil, context: C? = nil) {
        self.message = message
        let headerTheme = (message.content as? CardContent)?.header.theme ?? ""
        props = DynamicMaskViewComponent<C>.Props(message: message,
                                                  chat: chat,
                                                  contentPadding: 0,
                                                  metaModelDependency: metaModelDependency,
                                                  headerTitle: "",
                                                  headerTitleColor: UIColor.ud.N900,
                                                  headerBackgroundColors: [],
                                                  headerTheme: headerTheme)
        if context?.scene == .pin {
            props.isUserInteractionEnabled = false
            props.maxHeight = Styles.PinContentMaxHeight
        }
        super.init(key: key, context: context)
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        let style = ASComponentStyle()
        if context?.scene == .threadDetail
            || context?.scene == .threadChat
            || context?.scene == .messageDetail
            || context?.scene == .replyInThread
            || context?.scene == .threadPostForwardDetail
            || context?.scene == .pin {
            style.border = Border(BorderEdge(width: 1, color: cardBorderColor(), style: .solid))
            style.cornerRadius = 10
        }
        _component = DynamicMaskViewComponent<C>(
            props: props,
            style: style,
            context: context
        )
    }

    public override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? DynamicContentViewModel<M, D, C> else {
            assertionFailure()
            return
        }
        _component?.style.width = CSSValue(cgfloat: vm.preferMaxWidth)
        props.contentPadding = vm.content.type == .vchat ? 0 : 12
        props.message = vm.message
        props.chat = vm.metaModel.getChat
        props.metaModelDependency = vm.metaModelDependency
        props.maxHeight = vm.maxHeight
        props.isShowMore = vm.isShowMore
        props.showMoreBackgroundColors = vm.showMoreBackgroundColors
        props.hasCornerRadius = vm.hasCornerRadius
        props.showMoreHandler = { [weak vm] in
            vm?.showMore()
        }
        props.shouldShowMore = { [weak vm] in
            vm?.shouldShowMore()
        }
        props.headerTitle = vm.content.header.getTitle() ?? ""
        props.headerTitleColor = vm.content.header.color
        props.headerBackgroundColors = vm.content.header.backgroundColors
        props.theme = vm.content.header.theme
        props.iconProperty = vm.content.header.hasIcon ? vm.content.header.icon : nil
        props.subTitle = vm.content.header.hasSubtitle ? vm.content.header.subtitle : nil
        _component?.props = props
    }
}

final class MessageDetailDynamicContentViewModelBinder<M: CellMetaModel, D: CellMetaModelDependency, C: DynamicContentViewModelContext>: ComponentBinder<C> {
    private var props: DynamicMaskViewComponent<C>.Props
    private var _component: DynamicMaskViewComponent<C>?
    private let message: Message
    public override var component: ComponentWithContext<C> {
        guard let _component else { fatalError("should nevier go here")}
        return _component
    }
    public init(message: Message, chat: @escaping () -> Chat, metaModelDependency: D, key: String? = nil, context: C? = nil) {
        self.message = message
        props = DynamicMaskViewComponent<C>.Props(message: message,
                                                  chat: chat,
                                                  contentPadding: 0,
                                                  metaModelDependency: metaModelDependency,
                                                  headerTitle: "",
                                                  headerTitleColor: UIColor.ud.N900,
                                                  headerBackgroundColors: [])
        super.init(key: key, context: context)
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        let style = ASComponentStyle()
        if context?.scene == .threadDetail
            || context?.scene == .threadChat
            || context?.scene == .messageDetail {
            style.border = Border(BorderEdge(width: 1, color: cardBorderColor(), style: .solid))
            style.cornerRadius = 10
        }
        _component = DynamicMaskViewComponent<C>(
            props: props,
            style: style,
            context: context
        )
    }

    public override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? DynamicContentViewModel<M, D, C> else {
            assertionFailure()
            return
        }
        _component?.style.width = CSSValue(cgfloat: vm.preferMaxWidth)
        props.contentPadding = vm.content.type == .vchat ? 0 : 12
        props.message = vm.message
        props.chat = vm.metaModel.getChat
        props.metaModelDependency = vm.metaModelDependency
        props.maxHeight = vm.maxHeight
        props.isShowMore = vm.isShowMore
        props.showMoreBackgroundColors = vm.showMoreBackgroundColors
        props.hasCornerRadius = vm.hasCornerRadius
        props.showMoreHandler = { [weak vm] in
            vm?.showMore()
        }
        props.shouldShowMore = { [weak vm] in
            vm?.shouldShowMore()
        }
        props.headerTitle = vm.content.header.getTitle() ?? ""
        props.headerTitleColor = vm.content.header.color
        props.headerBackgroundColors = vm.content.header.backgroundColors
        props.iconProperty = vm.content.header.hasIcon ? vm.content.header.icon : nil
        props.subTitle = vm.content.header.hasSubtitle ? vm.content.header.subtitle : nil
        props.theme = vm.content.header.theme
        _component?.props = props
    }
}
#if BETA || ALPHA || DEBUG

extension DynamicMaskViewComponent {

    fileprivate func debugHandler(newContent:CardContent) {
        if self.messageCardDebugIsOn {
            self.context?.reloadRows(by: [props.message.id], doUpdate: { message -> Message? in
                message.content = newContent
                return message
            })
        }
    }

    fileprivate func GetDebugButton() ->RightButtonComponent<CardContext> {
        return  RightButtonFactory.create(name:"DEBUG",action: { [weak self] in
            guard let component = self else {
                logger.error("get DynamicMaskViewComponent failed")
                return
            }
            if component.messageCardDebugIsOn {
                if let targetVC = component.context?.targetVC,
                   let content = component.props.message.content as? CardContent {
                    var vc = UINavigationController(rootViewController: MessageCardDebugEditController(content: content,
                                                                                                       handler: { [weak component] (newContent) in
                                                                                                                        component?.debugHandler(newContent:newContent)
                                                                                                                },
                                                                                                       message:  component.props.message))
                    Navigator.shared.present(vc, from: targetVC)
                } else {
                    logger.error("debugButton handle failed")
                }
            }
        }, style: translateRightButtonStyle)
    }
}
#endif

