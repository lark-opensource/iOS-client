//
//  LarkDynamicCore.swift
//  NewLarkDynamic
//
//  Created by qihongye on 2019/6/18.
//

import Foundation
import AsyncComponent
import LarkModel
import EEFlexiable
import LKCommonsLogging
import LarkZoomable
import LarkFeatureGating
import UniverseDesignCardHeader
import RustPB
import ECOProbe
import LarkSetting
//import LarkOpenPlatform


let larkDynamicModule = "NewLarkDynamic"
private let logger = Logger.log(LDContext.self, category: "LarkNewDynamic.LDComponent")
typealias ElementTag = RustPB.Basic_V1_RichTextElement.Tag
public final class LarkDynamicCore<C: LDContext> {
    let flexParser = FlexStyleParser([
        PositionParser(),
        DisplayParser(),
        FlexDirectionParser(),
        FlexWrapParser(),
        JustifyContentParser(),
        OverflowParser(),
        CSSValueParser(),
        FloatValueParser(),
        AlignValueParser()
    ])
    lazy var componentsFactory: ComponentsFactory<C> = {
        let factory = ComponentsFactory<C>(flexParser: flexParser, context: context, translateLocale: props.translateLocale)
        empowerment(componentsFactory: factory)
        return factory
    }()

    var richTextPreProcessor: RichTextPreProcessor

    private var components: [ComponentWithContext<C>]!
    private(set) var richtext: RichText
    private(set) var props: LDRootComponentProps
    let context: C?
    /// 传入context，字体预处理
    public init(props: LDRootComponentProps, context: C? = nil) {
        let startTime = Date()
        self.richtext = props.richtext
        self.props = props
        self.context = context
        richTextPreProcessor = RichTextPreProcessor(context: context)
        empowerment(richTextPreProcessor: self.richTextPreProcessor, context: context)
        var tempRichText = self.richTextPreProcessor.process(richText: richtext, translateLocale: props.translateLocale)
        self.richtext = RichTextFontPreProcessor(context: context!,
                                                 richText: tempRichText,
                                                 flexParser: flexParser).richTextAfterZoom()
        let (components, unknownTags, unknownElements) = buildComponents(patchNoWideStyle(richtext: self.richtext))
        self.components = components
        reportResult(
            start: startTime,
            renderType: .cardInit,
            unknownTags: unknownTags,
            unknownElements: unknownElements,
            elementsCount: self.richtext.elements.count,
            appInfo: props.cardContent.appInfo
        )
        logger.info("LarkDynamicCore initialization completed")
    }
    /// 传入context，字体预处理
    public func getComponents() -> [ComponentWithContext<C>] {
        return components
    }

    /// 消息卡片刷新机制：通过传入新的RichTextg来更新components
    public func update(_ richtext: RichText, translateLocale: Locale?) {
        self.componentsFactory.translateLocale = translateLocale
        let startTime = Date()
        context?.updateWideCardContext()
        var tempRichText = richTextPreProcessor.process(richText: richtext, translateLocale: translateLocale)
        self.richtext = RichTextFontPreProcessor(context: context,
                                                 richText: tempRichText,
                                                 flexParser: flexParser).richTextAfterZoom()
        let (components, unknownTags, unknownElements) = buildComponents(patchNoWideStyle(richtext: self.richtext))
        self.components = components
        reportResult(
            start: startTime,
            renderType: .cardUpdate,
            unknownTags: unknownTags,
            unknownElements: unknownElements,
            elementsCount: self.richtext.elements.count, 
            appInfo: props.cardContent.appInfo
        )
        logger.info("richtext & components update completed")
    }

    private func buildComponents(_ richtext: RichText) -> ([ComponentWithContext<C>], [ElementTag], [String]) {
        var unknownTags: [ElementTag] = []
        var unknownElements: [String] = []
        let components = richtext.elementIds
            .compactMap({
                buildComponentTree(
                    elementID: $0,
                    richtext: richtext,
                    unknownElements: &unknownElements,
                    unknownTags: &unknownTags
                )})
        return (components, unknownTags, unknownElements)
    }

    private func buildComponentTree(
        elementID: String,
        richtext: RichText,
        unknownElements: inout [String],
        unknownTags: inout [ElementTag]
    ) -> ComponentWithContext<C>? {
        
        guard let element = richtext.elements[elementID] else {
            logger.warn("\(elementID) element is empty")
            unknownElements.append(elementID)
            return nil
        }
        // 通过componet的create方法判断是否需要递归生成该component
        let (component, needRecucive) = componentsFactory.create(elementID: elementID,
                                                                 element,
                                                                 richtext: richtext,
                                                                 unknownTags: &unknownTags)
        if needRecucive {
            component.children += element.childIds.compactMap({
                buildComponentTree(
                    elementID: $0,
                    richtext: richtext,
                    unknownElements: &unknownElements,
                    unknownTags: &unknownTags
                )})
        }
        return component
    }
    /// patch with no wide style
    private func patchNoWideStyle(richtext: RichText) -> RichText {
        return RichTextNonWideStylePreProcessor(context: context as? LDContext,
                                                richText: richtext).richTextApplyWideStyle()
    }
    
    private func reportResult(
        start: Date,
        renderType: MonitorField.RenderTypeValue,
        unknownTags: [ElementTag],
        unknownElements: [String],
        elementsCount: Int,
        appInfo: Basic_V1_CardAppInfo?
    ) {
        var duration = Date().timeIntervalSince(start)
        if (unknownTags.count == 0 && unknownElements.count == 0 && elementsCount != 0) {
            OPMonitor(EPMClientOpenPlatformCardCode.messagecard_loading_success)
                .addCategoryValue(MonitorField.MessageID, context?.messageID)
                .addCategoryValue(MonitorField.Version, "v1")
                .addCategoryValue(MonitorField.RenderType, renderType.rawValue)
                .addCategoryValue(MonitorField.ElementsCount, elementsCount)
                .addCategoryValue(MonitorField.BotID, appInfo?.botID)
                .addCategoryValue(MonitorField.AppID, appInfo?.appID)
                .tracing(context?.trace)
                .setDuration(duration)
                .setResultTypeSuccess()
                .flush()
        } else {
            OPMonitor(EPMClientOpenPlatformCardv2LoadingCode.messagecardv2_process_fail)
                .addCategoryValue(MonitorField.MessageID, context?.messageID)
                .tracing(context?.trace)
                .addCategoryValue(MonitorField.UnknownTags, unknownTags.map{ $0.rawValue })
                .addCategoryValue(MonitorField.UnknownElements, unknownElements)
                .addCategoryValue(MonitorField.Version, "v1")
                .addCategoryValue(MonitorField.RenderType, renderType.rawValue)
                .addCategoryValue(MonitorField.ElementsCount, elementsCount)
                .addCategoryValue(MonitorField.BotID, appInfo?.botID)
                .addCategoryValue(MonitorField.AppID, appInfo?.appID)
                .setDuration(duration)
                .setResultTypeFail()
                .flush()
        }
    }
}

public class LDComponent<P: ASComponentProps, V: UIView, C: LDContext>: ASComponent<P, EmptyState, V, C> {
    ///公共方法，如果是转发的消息，并且处理成功，那么Action之后就不需要处理了
    public func processForwardCardMessage(actionID: String, params: [String: String]? = nil) -> Bool {
        guard let ctx = context else {
            return false
        }
        let result = ctx.forwardMessageAction(actionID: actionID, params: params)
        defer {
            if result {
                logger.info("click forward message card")
            }
        }
        return result
    }

    public override func update(view: V) {
        super.update(view: view)
        if let style = self.style as? LDStyle,
           let _ = self.style.backgroundColor {
            view.backgroundColor = style.getBackgroundColor()?.currentColor()
        }
    }
}

public final class LDRootView: UIView {
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public final class LDRootComponentProps: ASComponentProps {
    public var richtext: RichText
    public var cardContent: CardContent
    public var translateLocale: Locale?

    public init(richtext: RichText, cardContent: CardContent, translateLocale: Locale? = nil) {
        self.richtext = richtext
        self.cardContent = cardContent
        self.translateLocale = translateLocale
    }
}

func richTextLogDetail(richtext: RichText, description: String) {
    if detailLog.enableColorLog() {
        var richTextResult = ""
        richTextResult.append("\(description)\n")
        detailLog.info(description)
        for (elementId, element) in richtext.elements {
            let style = "element style \(elementId) \(element.style) \(element.styleKeys) \(element.wideStyle) \(element.tag) \(element.childIds)"
            richTextResult.append("\(style)\n")
        }
        detailLog.info("\(richTextResult)")
    }
}

final public class LDRootComponent<C: LDContext>: LDComponent<LDRootComponentProps, LDRootView, C> {
    let core: LarkDynamicCore<C>
    let logger = Logger.log(LDRootComponent.self, category: larkDynamicModule)

    public override init(props: LDRootComponentProps, style: ASComponentStyle, context: C? = nil) {
        richTextLogDetail(richtext: props.richtext, description: "LDRootInit")
        self.core = LarkDynamicCore(props: props, context: context)
        style.flexDirection = .column
        logger.info("LDRootComponent initialization completed")
        super.init(props: props, style: style, context: context)
    }

    // 卡片数据更新
    public override func willReceiveProps(_ old: LDRootComponentProps, _ new: LDRootComponentProps) -> Bool {
        core.update(new.richtext, translateLocale: new.translateLocale)
        richTextLogDetail(richtext: props.richtext, description: "LDRootIUpdate")
        return true
    }

    // 卡片渲染：依赖RichLabel模块中的LKTextRenderEngine实现渲染
    public override func render() -> BaseVirtualNode {
        setSubComponents(core.getComponents())
        return super.render()
    }

    public override func update(view: LDRootView) {
        super.update(view: view)
        view.backgroundColor = UIColor.ud.bgFloat.withContext(context: self.context).currentColor()
        style.backgroundColor = UIColor.ud.bgFloat.withContext(context: self.context)
    }
}

final public class LDHeaderComponent<C: LDContext>: ASComponent<LDHeaderComponent.Props, EmptyState, LDHeaderView, C> {

    private lazy var labelProps = makeLabelProps(fontSize: 16, weight: .medium, numberOfLines: 4)

    private lazy var subTitleProps = makeLabelProps(fontSize: 14, weight: .light, numberOfLines: 1)

    private lazy var label: UILabelComponent<C> = {
        let style = ASComponentStyle()
        style.backgroundColor = .clear
        style.marginTop = 10
        style.marginBottom = 10
        style.marginLeft = 12
        style.marginRight = 12
        return UILabelComponent(props: self.labelProps, style: style)
    }()
    
    private lazy var subTitle: UILabelComponent<C> = {
        let style = ASComponentStyle()
        style.backgroundColor = .clear
        style.marginBottom = 10
        style.marginLeft = 12
        style.marginRight = 12
        return UILabelComponent(props: self.subTitleProps, style: style)
    }()

    
    //较原head组件替换文本组件为TextComponent
    private lazy var labelSurpportCopy: TextComponent<C> = {
        let style = ASComponentStyle()
        style.backgroundColor = .clear
        style.marginTop = 10
        style.marginBottom = 10
        style.marginLeft = 12
        style.marginRight = 12
        var props = makeLabelProps_surpportCopy(text: self.props.text,
                                                textColor: getTextColor(self.props),
                                                fontSize: 16,
                                                weight: .bold,
                                                numberOfLines: 4)
        return TextComponent(props:props , style: style)
    }()
    
    //较原head组件替换文本组件为TextComponent
    private lazy var subTitleSurpportCopy: TextComponent<C> = {
        let style = ASComponentStyle()
        style.backgroundColor = .clear
        style.marginBottom = 10
        style.marginLeft = 12
        style.marginRight = 12
        var props = makeLabelProps_surpportCopy(text: self.props.subTitle ?? "",
                                                textColor: getTextColor(self.props),
                                                fontSize: 14,
                                                weight: .light,
                                                numberOfLines: 1)
        return TextComponent(props:props , style: style)
    }()

    lazy var labelAvatar: ComponentWithContext<C> = {
        return labelSurpportCopy
    }()
    
    lazy var subTitileAvatar: ComponentWithContext<C> = {
        return subTitleSurpportCopy
    }()
    
    private lazy var icon:LDImageComponent<C> = {
        let props = LDImageComponentProps()
        props.contentMode = .scaleAspectFill
        let style = ASComponentStyle()
        style.marginTop = 12
        style.marginLeft = 12
        style.width = 16
        style.height = 16
        return LDImageComponent(props: props, style: style)
    }()

    private let logger = Logger.log(LDHeaderComponent.self, category: larkDynamicModule)

    //标题最外层用div包裹一下，解决render时head下多个组件时不显示的问题
    private lazy var headContent = DivComponent<C>(props: DivComponentProps(), style: ASComponentStyle())

    private lazy var titileContent: DivComponent<C> = {
        var style = ASComponentStyle()
        style.flexDirection = .column
        return DivComponent<C>(props: DivComponentProps(), style: style)
    }()

    public override init(props: Props, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
        guard LarkFeatureGating.shared.getFeatureBoolValue(for: FeatureGating.messageCardHeaderUseNew) else {
            setSubComponents([labelAvatar])
            return
        }
        setSubComponents([headContent])
        setupComponent(props: props)
        logger.info("LDHeaderComponent initialization completed")
    }

    public final class Props: ASComponentProps {
        public var text: String = ""
        public var textColor: UIColor? = UIColor.ud.N900
        public var backgroundColors: [UIColor] = []
        public var theme: String = ""
        public var iconProperty: RichTextElement.ImageProperty?
        public var subTitle:String?
    }
    
    public override func update(view: LDHeaderView) {
        super.update(view: view)
        if let bgColor = props.theme.themeHeaderBGColor() {
//            detailLog.info("Header Update \(props.text) for theme \(props.theme) as color \(bgColor.hex8)")
            view.colorHue = UDCardHeaderHue(color: bgColor)
            view.setLineLayerBG(hidden: true)
        } else {
//            detailLog.info("Header Update \(props.text) for colors \(props.backgroundColors.first?.hex8) as color \(props.backgroundColors.last?.hex8)")
            view.setBackground(colors: props.backgroundColors)
        }
    }

    public override func willReceiveProps(
        _ old: LDHeaderComponent<C>.Props,
        _ new: LDHeaderComponent<C>.Props
    ) -> Bool {
        self.props.backgroundColors = new.backgroundColors
        labelProps.text = new.text
        let themeColor = new.theme.themeTextColor()
        labelProps.textColor = (themeColor ?? (new.textColor ?? UIColor.ud.N900)).withContext(context: self.context)
//        detailLog.info("Header Update \(new.text) for theme \(new.theme) as color \(new.theme.themeHeaderBGColor()?.hex8)")
        label.props = labelProps
        labelSurpportCopy.props = makeLabelProps_surpportCopy(text: new.text,
                                                              textColor: getTextColor(new),
                                                              fontSize: 16,
                                                              weight: .bold,
                                                              numberOfLines: 4)
        setupComponent(props: new)
        return true
    }
    
    //根据props添加icon和subtitle
    func setupComponent(props: LDHeaderComponent<C>.Props) {
        guard LarkFeatureGating.shared.getFeatureBoolValue(for: FeatureGating.messageCardHeaderUseNew) else {
            return
        }
        headContent.children.removeAll()
        titileContent.children.removeAll()
        if let iconProperty = props.iconProperty {
            icon.props.imageProperty = iconProperty
            label.style.marginLeft = 8
            subTitle.style.marginLeft = 8
            labelSurpportCopy.style.marginLeft = 8
            subTitleSurpportCopy.style.marginLeft = 8
            headContent.setSubComponents([icon,titileContent])
        } else {
            label.style.marginLeft = 12
            subTitle.style.marginLeft = 12
            labelSurpportCopy.style.marginLeft = 12
            subTitleSurpportCopy.style.marginLeft = 12
            headContent.setSubComponents([titileContent])
        }

        if let subTitleText = props.subTitle {
            subTitleProps.textColor = labelProps.textColor
            subTitleProps.text = subTitleText
            subTitle.props = subTitleProps
            label.style.marginBottom = 2
            labelSurpportCopy.style.marginBottom = 2
            subTitleSurpportCopy.props = makeLabelProps_surpportCopy(text: subTitleText,
                                                                     textColor: getTextColor(props),
                                                                     fontSize: 14,
                                                                     weight: .light,
                                                                     numberOfLines: 1)
            titileContent.setSubComponents([labelAvatar,subTitileAvatar])
        } else {
            label.style.marginBottom = 10
            labelSurpportCopy.style.marginBottom = 10
            titileContent.setSubComponents([labelAvatar])
        }
    }

    private func makeLabelProps(fontSize: CGFloat, weight: UIFont.Weight, numberOfLines: Int) -> UILabelComponentProps {
        let props = UILabelComponentProps()
        let fontSize = context?.zoomFontSize(originSize: fontSize) ?? fontSize
        props.font = UIFont.systemFont(ofSize: fontSize, weight: weight)
        props.text = self.props.text
        let textColor = self.props.theme.themeTextColor() ?? (self.props.textColor ?? UIColor.ud.N900)
        props.textColor = textColor.withContext(context: self.context)
        props.numberOfLines = numberOfLines
        props.textAlignment = .left
        props.lineBreakMode = .byTruncatingTail
        return props
    }
    
    //较原head组件替换文本组件为TextComponent，修改props为RichLabelProps
    private func makeLabelProps_surpportCopy(text: String, textColor: UIColor ,fontSize: CGFloat, weight: UIFont.Weight, numberOfLines: Int) -> RichLabelProps {
        let props = RichLabelProps()
        let fontSize = context?.zoomFontSize(originSize: fontSize) ?? fontSize
        props.font = UIFont.systemFont(ofSize: fontSize, weight: weight)
        props.numberOfLines = numberOfLines
        props.lineSpacing = 3
        var attrbuties: [NSAttributedString.Key: Any] = [
            .foregroundColor: textColor,
            .font: UIFont.systemFont(ofSize: fontSize, weight: weight),
            .paragraphStyle: {
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineBreakMode = .byWordWrapping
                paragraphStyle.alignment = .left
                return paragraphStyle
            }()
        ]
        props.key = context?.getCopyabelComponentKey()
        props.attributedText = NSAttributedString(string: text, attributes: attrbuties)
        props.outOfRangeText = NSAttributedString(string: messsageCardOutOfRangeText, attributes: attrbuties)
        return props
    }
    
    //获取标题文本颜色
    private func getTextColor(_ props: LDHeaderComponent<C>.Props) -> UIColor {
        return props.theme.themeTextColor() ?? (props.textColor ?? UIColor.ud.N900)
    }
}

public final class LDHeaderView: UDCardHeader {
    private lazy var gradientLayer: CAGradientLayer = {
        let gradient = CAGradientLayer()
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 0)
        gradient.isHidden = true
        layer.insertSublayer(gradient, at: 0)
        return gradient
    }()
    
    public func setLineLayerBG(hidden: Bool) {
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.0)
        CATransaction.setDisableActions(true)
        gradientLayer.isHidden = hidden
        CATransaction.commit()
    }

    public func setBackground(colors: [UIColor]) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        CATransaction.setAnimationDuration(0.0)
        gradientLayer.isHidden = colors.count < 2
        switch colors.count {
        case 1:
            backgroundColor = colors.first
        case 2...:
            backgroundColor = nil
            gradientLayer.colors = colors.map { $0.currentColor().cgColor }
//            gradientLayer.ud.setColors(colors, bindTo: UIApplication.shared.keyWindow)
            gradientLayer.locations = colors.enumerated().map { (offset: Int, _: UIColor) -> NSNumber in
                return NSNumber(value: Float(offset) / Float(colors.count - 1))
            }
        default:
            backgroundColor = nil
        }
        CATransaction.commit()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        CATransaction.setAnimationDuration(0.0)
        gradientLayer.frame = bounds
        CATransaction.commit()
    }
}
