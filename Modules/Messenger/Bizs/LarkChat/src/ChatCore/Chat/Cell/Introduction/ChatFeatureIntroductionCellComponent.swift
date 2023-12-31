//
//  ChatFeatureIntroductionCellComponent.swift
//  LarkChat
//
//  Created by 赵家琛 on 2020/11/3.
//

import UIKit
import Foundation
import AsyncComponent
import EEFlexiable
import LarkMessageBase

final class ChatFeatureIntroductionCellComponent: ASComponent<ChatFeatureIntroductionCellComponent.Props, EmptyState, UIView, ChatContext> {
    final class Props: ASComponentProps {
        var copyWriting: String = ""
        var hasHeader: Bool = false
    }

    lazy var labelComponent: RichLabelComponent<ChatContext> = {
        let style = ASComponentStyle()
        style.backgroundColor = UIColor.clear
        style.marginLeft = 15
        style.marginRight = 15
        style.flexGrow = 1
        return RichLabelComponent<ChatContext>(props: RichLabelProps(), style: style)
    }()

    override init(props: ChatFeatureIntroductionCellComponent.Props, style: ASComponentStyle, context: ChatContext? = nil) {
        style.paddingBottom = 12
        style.paddingTop = 12
        style.alignContent = .stretch
        super.init(props: props, style: style, context: context)

        setSubComponents([labelComponent])
        labelComponent.props.attributedText = formatRichText(text: props.copyWriting)
    }

    override func willReceiveProps(_ old: Props, _ new: Props) -> Bool {
        labelComponent.props.attributedText = formatRichText(text: new.copyWriting)
        return true
    }

    override func render() -> BaseVirtualNode {
        let maxCellWidth = context?.maxCellWidth ?? UIScreen.main.bounds.width
        style.width = CSSValue(cgfloat: maxCellWidth)
        if props.hasHeader {
            labelComponent.style.marginTop = 12
        } else {
            labelComponent.style.marginTop = 0
        }

        let horizontalMargin = labelComponent.style.marginLeft.value + labelComponent.style.marginRight.value
        labelComponent.props.preferMaxLayoutWidth = maxCellWidth - CGFloat(horizontalMargin)
        return super.render()
    }

    private func formatRichText(text: String) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        return NSAttributedString(string: text,
                                  attributes: [.font: UIFont.ud.body2,
                                               .foregroundColor: UIColor.ud.textPlaceholder,
                                               .paragraphStyle: paragraphStyle])
    }
}
