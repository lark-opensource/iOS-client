//
//  LDAtComponent.swift
//  NewLarkDynamic
//
//  Created by Jiayun Huang on 2019/6/20.
//

import Foundation
import AsyncComponent
import LarkModel
import RichLabel
import LarkFeatureGating

final class AtComponentFactory: ComponentFactory {
    override var tag: RichTextElement.Tag {
        return .at
    }

    override func create<C: LDContext>(
        richtext: RichText,
        element: RichTextElement,
        elementId: String,
        children: [RichTextElement],
        style: LDStyle,
        context: C?,
        translateLocale: Locale? = nil) -> ComponentWithSubContext<C, C> {
        let props = AtComponentProps(context: context)
        props.content = element.property.at.atContent
        props.chatterID = element.property.at.userID
        props.tapableRangeList = [NSRange(location: 0, length: NSString(string: element.property.at.atContent).length)]

        let userID = element.property.at.userID
        props.chatterID = userID
        props.atUserIdRangeMap[userID] = props.tapableRangeList
        props.font = style.font
        style.underlineStyle = nil
        style.strikethroughStyle = nil
        props.key = context?.getCopyabelComponentKey()
        return AtComponent2<C>(props: props, style: style, context: context)
    }
}

final class AtComponentProps: LabelComponentProps {
    var chatterID: String = ""
    lazy var meForegroundColor: UIColor = UIColor.ud.primaryOnPrimaryFill.withContext(context: self.context)
    lazy var othersForegroundColor: UIColor = UIColor.ud.colorfulBlue.withContext(context: self.context)
    lazy var atAttributeColor: UIColor = UIColor.ud.colorfulBlue.withContext(context: self.context)
    internal var atUserIdRangeMap: [String: [NSRange]] = [:]
    override init(context: LDContext?) {
        super.init(context: context)
        lineBreakMode = .byTruncatingTail
    }
}

extension RichTextElement.AtProperty {
    var atContent: String {
        if self.content.starts(with: "@") {
            return self.content
        } else {
            return "@" + self.content
        }
    }
}

//为可控地进行灰度，使用新的组件换用LKSelectionLabel
class AtComponent2<C: LDContext>: LDComponent<AtComponentProps, LKSelectionLabel, C> {
    private var layoutEngine: LKTextLayoutEngine
    private var textParser: LKTextParser
    private var linkParser: LKLinkParserImpl

    override init(props: AtComponentProps, style: ASComponentStyle, context: C? = nil) {
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
        view.delegate = self

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
        var attrbuties = attributedBuilder(style: style, lineBreakMode: .byWordWrapping, context: context)
        if let atContent = props.content {
            let attributedText = NSMutableAttributedString(string: atContent, attributes: attrbuties)
            /// 在上面的公共初始化方法中，@标签的颜色被下面两个标记成了style中的文字颜色
            /// 同时下面根据是否是@自己，主动设置了固定的颜色，两种颜色在渲染时会出现冲突，偶现@文字颜色错误
            attrbuties.removeValue(forKey: .foregroundColor)
            attrbuties.removeValue(forKey: NSAttributedString.Key(kCTForegroundColorAttributeName as String))
            if context?.isMe(props.chatterID) == true {
                attributedText.addAttributes([
                    .foregroundColor: props.meForegroundColor,
                    LKAtAttributeName: props.atAttributeColor
                ], range: NSRange(location: 0, length: attributedText.length))
            } else {
                attributedText.addAttributes([
                    .foregroundColor: props.othersForegroundColor
                ], range: NSRange(location: 0, length: attributedText.length))
            }
            textParser.originAttrString = attributedText
        } else {
            textParser.originAttrString = nil
        }
        layoutEngine.outOfRangeText = NSAttributedString(string: messsageCardOutOfRangeText, attributes: attrbuties)
        labelRender(props, textParser: &textParser, linkParser: &linkParser, layoutEngine: &layoutEngine)
        return super.render()
    }
}

extension AtComponent2: LKLabelDelegate {
    func attributedLabel(_ label: LKLabel, didSelectText text: String, didSelectRange range: NSRange) -> Bool {
        for (userId, ranges) in props.atUserIdRangeMap where ranges.contains(range) && userId != "all" {
            self.context?.openProfile(chatterID: userId)
            return false
        }
        return true
    }
}
