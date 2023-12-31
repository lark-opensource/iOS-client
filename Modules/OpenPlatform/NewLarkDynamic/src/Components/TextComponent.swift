//
//  TextComponent.swift
//  NewLarkDynamic
//
//  Created by qihongye on 2019/6/25.
//

import Foundation
import LarkModel
import AsyncComponent
import RichLabel
import EEAtomic

class TextComponentFactory: ComponentFactory {
    override var tag: RichTextElement.Tag {
        return .text
    }

    override func create<C: LDContext>(
        richtext: RichText,
        element: RichTextElement,
        elementId: String,
        children: [RichTextElement],
        style: LDStyle,
        context: C?,
        translateLocale: Locale? = nil) -> ComponentWithSubContext<C, C> {
        let props = RichLabelProps()
        props.font = style.font
        props.lineSpacing = 3
        props.numberOfLines = max(0, Int(element.property.text.numberOfLines))
        let isButtonText = context?.isButtonText(elementId: elementId) ?? false
        var isLoading = false
        var customTextColor: UIColor?
        if let buttonContext = context?.buttonContext(subTextElementId: elementId) {
            if (buttonContext.isLoading() ?? false) ||
                (buttonContext.isDisable() ?? false) {
                isLoading = true
                customTextColor = style.getDisableTextColor() ?? style.getColor()?.withAlphaComponent(0.32)
            }
        }
        /// 开放平台 非 Office 场景，暂时逃逸
        // swiftlint:disable ban_linebreak_byChar
        let breakMode: NSLineBreakMode = isButtonText ? .byCharWrapping : .byWordWrapping
        // swiftlint:enable ban_linebreak_byChar
        let attrbuties = attributedBuilder(style: style,
                                           lineBreakMode: breakMode,
                                           context: context,
                                           textColorCustom: customTextColor)
        props.attributedText = NSAttributedString(string: element.property.text.content, attributes: attrbuties)
        props.outOfRangeText = NSAttributedString(string: messsageCardOutOfRangeText, attributes: attrbuties)
        #if DEBUG
        cardlog.info("TextComponent \(props.attributedText) \(isLoading) style \(style.styleValues) text \(element.property.text.content)")
        #endif
        props.key = context?.getCopyabelComponentKey()
        return TextComponent<C>(props: props, style: style, context: context)
    }
}

// 拷贝自 RichLabelComponent，换组件名与tag对齐，换用LKSelectionLabel
public final class TextComponent<C: LDContext>: ASComponent<RichLabelProps, EmptyState, LKSelectionLabel, C> {
    /// layoutEngine
    private var layoutEngine: AtomicObject<LKTextLayoutEngineImpl>
    private var writeLayoutEngine: LKTextLayoutEngine
    /// textParser
    private var textParser: AtomicObject<LKTextParserImpl>
    private var writeTextParser: LKTextParser
    /// linkParser
    private var linkParser: AtomicObject<LKLinkParserImpl>
    private var writeLinkParser: LKLinkParserImpl

    public override var isSelfSizing: Bool {
        return true
    }

    public override var isComplex: Bool {
        return true
    }

    public override init(props: RichLabelProps, style: ASComponentStyle, context: C? = nil) {
        // layoutEngine init
        self.layoutEngine = AtomicObject(LKTextLayoutEngineImpl())
        self.writeLayoutEngine = LKTextLayoutEngineImpl()
        // textParser init
        self.textParser = AtomicObject(LKTextParserImpl())
        self.writeTextParser = LKTextParserImpl()
        // linkParser init
        self.linkParser = AtomicObject(LKLinkParserImpl(linkAttributes: props.linkAttributes))
        self.writeLinkParser = LKLinkParserImpl(linkAttributes: props.linkAttributes)
        super.init(props: props, style: style, context: context)
    }

    public override func sizeToFit(_ size: CGSize) -> CGSize {
        let size = self.writeLayoutEngine.layout(size: size)
        // swiftlint:disable:next force_cast
        self.layoutEngine.value = writeLayoutEngine.clone() as! LKTextLayoutEngineImpl
        return size
    }

    public override func update(view: LKSelectionLabel) {
        super.update(view: view)
        view.delegate = props.delegate
        view.debugOptions = props.debugOptions
        view.activeLinkAttributes = props.activeLinkAttributes
        view.linkAttributes = props.linkAttributes
        view.textCheckingDetecotor = props.textCheckingDetecotor
        view.autoDetectLinks = props.autoDetectLinks
        view.numberOfLines = props.numberOfLines
        view.tag = props.tag
        view.isFuzzyPointAt = props.isFuzzyPointAt
        view.textParser = textParser.value
        view.linkParser = linkParser.value
        view.setForceLayout(layoutEngine.value)

        //与原组件相比新增
        view.selectionDelegate = context?.selectionLabelDelegate
        view.options = [
            .cursorColor(UIColor.ud.colorfulBlue),
            .selectionColor(UIColor.ud.colorfulBlue.withAlphaComponent(0.16)),
            .cursorTouchHitTestInsets(UIEdgeInsets(top: -14, left: -25, bottom: -14, right: -25))
        ]
        //与原组件相比新增
    }

    public override func render() -> BaseVirtualNode {
        richLabelRender(props, textParser: &writeTextParser, linkParser: &writeLinkParser, layout: &writeLayoutEngine)
        self.textParser.value = writeTextParser.clone() as? LKTextParserImpl ?? LKTextParserImpl()
        self.linkParser.value = writeLinkParser.clone() as? LKLinkParserImpl ?? LKLinkParserImpl(linkAttributes: [:])
        self.layoutEngine.value = writeLayoutEngine.clone() as? LKTextLayoutEngineImpl ?? LKTextLayoutEngineImpl()
        return super.render()
    }
}


