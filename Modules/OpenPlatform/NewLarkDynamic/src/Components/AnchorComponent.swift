//
//  LDAnchorComponent.swift
//  NewLarkDynamic
//
//  Created by Jiayun Huang on 2019/6/20.
//

import Foundation
import AsyncComponent
import RichLabel
import LarkModel

final class AnchorComponentFactory: ComponentFactory {
    override var tag: RichTextElement.Tag {
        return .a
    }

    override func create<C: LDContext>(
        richtext: RichText,
        element: RichTextElement,
        elementId: String,
        children: [RichTextElement],
        style: LDStyle,
        context: C?,
        translateLocale: Locale? = nil) -> ComponentWithSubContext<C, C> {
        let props = AnchorComponentProps(context: context)
        let anchorProperty = element.property.anchor
        let contentLength = NSString(string: anchorProperty.content).length

        if anchorProperty.hasIosHref, let url = anchorProperty.iosHref.possibleURL() {
            props.rangeLinkMap = [NSRange(location: 0, length: contentLength): url]
        } else if anchorProperty.hasHref, let url = anchorProperty.href.possibleURL() {
            props.rangeLinkMap = [NSRange(location: 0, length: contentLength): url]
        }

        let textColor = (style.getColor() ?? UIColor.ud.colorfulBlue).withContext(context: context)
        style.color = textColor
        style.underlineColor = (style.getUnderlineColor() ?? textColor).withContext(context: context)
        style.strikethroughColor = (style.getStrikethroughColor() ?? textColor).withContext(context: context)
        /// 开放平台 非 Office 场景，暂时逃逸
        // swiftlint:disable ban_linebreak_byChar
        let attrbuties = attributedBuilder(style: style, lineBreakMode: .byCharWrapping, context: context)
        // swiftlint:enable ban_linebreak_byChar
        props.attributedText = NSAttributedString(string: anchorProperty.content, attributes: attrbuties)
        props.outOfRangeText = NSAttributedString(string: messsageCardOutOfRangeText, attributes: attrbuties)
        props.textColor = textColor
        props.content = anchorProperty.content
        props.font = style.font
        props.key = context?.getCopyabelComponentKey()
        return AnchorComponent2<C>(props: props, style: style, context: context)
    }
}

final class AnchorComponentProps: LabelComponentProps {
    var isUserInteractionEnabled: Bool = false
    
    override init(context: LDContext?) {
        super.init(context: context)
        /// 开放平台 非 Office 场景，暂时逃逸
        // swiftlint:disable ban_linebreak_byChar
        lineBreakMode = .byCharWrapping
        // swiftlint:enable ban_linebreak_byChar
    }
}

//为可控地进行灰度，使用新的组件换用LKSelectionLabel
class AnchorComponent2<C: LDContext>: LDComponent<AnchorComponentProps, LKSelectionLabel, C> {
    private var layoutEngine: LKTextLayoutEngine
    private var textParser: LKTextParser
    private var linkParser: LKLinkParserImpl

    override init(props: AnchorComponentProps, style: ASComponentStyle, context: C? = nil) {
        self.layoutEngine = LKTextLayoutEngineImpl()
        self.textParser = LKTextParserImpl()
        self.linkParser = LKLinkParserImpl(linkAttributes: props.linkAttributes)
        super.init(props: props, style: style, context: context)
    }
    override func update(view: LKSelectionLabel) {
        super.update(view: view)
        view.font = props.font
        view.textColor = props.textColor.withContext(context: self.context).currentColor()
        view.backgroundColor = props.backgroudColor.withContext(context: self.context).currentColor()
        view.lineSpacing = props.lineSpacing
        view.numberOfLines = props.numberOfLines
        view.lineBreakMode = props.lineBreakMode
        view.isUserInteractionEnabled = props.isUserInteractionEnabled
        view.linkAttributes = props.linkAttributes
        view.activeLinkAttributes = props.activeLinkAttributes
        view.textParser = textParser
        view.linkParser = linkParser
        view.delegate = self
        view.setForceLayout(layoutEngine)

        //与原组件相比新增
        view.selectionDelegate = context?.selectionLabelDelegate
        view.options = [
            .cursorColor(UIColor.ud.colorfulBlue),
            .selectionColor(UIColor.ud.colorfulBlue.withAlphaComponent(0.16)),
            .cursorTouchHitTestInsets(UIEdgeInsets(top: -14, left: -25, bottom: -14, right: -25))
        ]
        //与原组件相比新增
    }
    public override var isSelfSizing: Bool {
        return true
    }

    public override func sizeToFit(_ size: CGSize) -> CGSize {
        return self.layoutEngine.layout(size: size)
    }

    public override func render() -> BaseVirtualNode {
        textParser.originAttrString = props.attributedText
        labelRender(props, textParser: &textParser, linkParser: &linkParser, layoutEngine: &layoutEngine)
        return super.render()
    }
}

extension AnchorComponent2: LKLabelDelegate {
    public func attributedLabel(_ label: LKLabel, didSelectLink url: URL) {
        guard let context = context as? LDContext else {
            cardlog.error("context is not LDContext: \(context.self)")
            return
        }
        let start = Date()
        context.openLink(url, from: .innerLink()){ [weak context] error in
            context?.reportAction(
                start: start,
                trace: context?.trace.subTrace(),
                actionID: nil,
                actionType: .url,
                error: error
            )
        }
    }
}
