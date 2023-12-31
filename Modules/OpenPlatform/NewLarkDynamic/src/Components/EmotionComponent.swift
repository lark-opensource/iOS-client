//
//  EmotionComponent.swift
//  NewLarkDynamic
//
//  Created by Songwen Ding on 2019/8/12.
//

import Foundation
import AsyncComponent
import LarkModel
import RichLabel
import LarkEmotion

final class EmotionComponentFactory: ComponentFactory {
    override var tag: RichTextElement.Tag {
        return .emotion
    }

    override func create<C: LDContext>(
        richtext: RichText,
        element: RichTextElement,
        elementId: String,
        children: [RichTextElement],
        style: LDStyle,
        context: C?,
        translateLocale: Locale? = nil) -> ComponentWithSubContext<C, C> {
        let props = EmotionComponentProps(context: context)
        props.emojiKey = element.property.emotion.key
        props.font = style.font
        style.underlineStyle = nil
        style.strikethroughStyle = nil
        props.key = context?.getCopyabelComponentKey()
        return EmotionComponent2<C>(props: props, style: style, context: context)
    }
}

final class EmotionComponentProps: LabelComponentProps {
    var emojiKey: String = ""
    override init(context: LDContext?) {
        super.init(context: context)
        lineBreakMode = .byTruncatingTail
    }
}
class EmotionComponent2<C: LDContext>: LDComponent<EmotionComponentProps, LKSelectionLabel, C> {
    private var layoutEngine: LKTextLayoutEngine
    private var textParser: LKTextParser
    private var linkParser: LKLinkParserImpl

    override init(props: EmotionComponentProps, style: ASComponentStyle, context: C? = nil) {
        self.layoutEngine = LKTextLayoutEngineImpl()
        self.textParser = LKTextParserImpl()
        self.linkParser = LKLinkParserImpl(linkAttributes: props.linkAttributes)
        super.init(props: props, style: style, context: context)
    }

    override func update(view: LKSelectionLabel) {
        super.update(view: view)

        view.textParser = textParser
        view.linkParser = linkParser
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

    override var isSelfSizing: Bool {
        return true
    }

    override func sizeToFit(_ size: CGSize) -> CGSize {
        return self.layoutEngine.layout(size: size)
    }

    override func render() -> BaseVirtualNode {
        var emojiKey = props.emojiKey
        emojiKey = emojiKey.lf.trimCharacters(in: ["["], postion: .lead)
        emojiKey = emojiKey.lf.trimCharacters(in: ["]"], postion: .tail)
        // 资源统一从EmotionResouce获取
        if let icon = loadEmotion(emojiKey) {
            let emoji = LKEmoji(icon: icon, font: props.font)
            let attributedString = NSMutableAttributedString(
                string: LKLabelAttachmentPlaceHolderStr,
                attributes: [LKEmojiAttributeName: emoji]
            )
            textParser.originAttrString = attributedString
        } else {
            textParser.originAttrString = nil
        }
        layoutEngine.outOfRangeText = props.outOfRangeText
        labelRender(props, textParser: &textParser, linkParser: &linkParser, layoutEngine: &layoutEngine)
        return super.render()
    }
}
