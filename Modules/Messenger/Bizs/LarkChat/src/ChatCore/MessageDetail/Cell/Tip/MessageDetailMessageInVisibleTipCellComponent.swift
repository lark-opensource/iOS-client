//
//  MessageDetailMessageInVisibleTipCellComponent.swift
//  LarkChat
//
//  Created by 赵家琛 on 2021/5/11.
//

import UIKit
import Foundation
import EEFlexiable
import AsyncComponent
import LarkMessageBase

final class MessageDetailMessageInVisibleTipCellComponent: ASComponent<MessageDetailMessageInVisibleTipCellComponent.Props, EmptyState, UIView, MessageDetailContext> {
    final class Props: ASComponentProps {
        var copyWriting: String = ""
    }

    lazy var labelComponent: RichLabelComponent<MessageDetailContext> = {
        let style = ASComponentStyle()
        style.backgroundColor = UIColor.clear
        style.marginLeft = 15
        style.marginRight = 15
        style.flexGrow = 1
        style.marginTop = 16
        style.marginBottom = 16
        return RichLabelComponent<MessageDetailContext>(props: RichLabelProps(), style: style)
    }()

    private lazy var content: UIViewComponent<MessageDetailContext> = {
        let style = ASComponentStyle()
        style.backgroundColor = UIColor.ud.N200
        style.flexGrow = 1
        style.marginTop = 1
        style.marginLeft = 0
        style.marginBottom = 0
        style.marginRight = 0
        return UIViewComponent<MessageDetailContext>(props: ASComponentProps(), style: style)
    }()

    override init(props: MessageDetailMessageInVisibleTipCellComponent.Props, style: ASComponentStyle, context: MessageDetailContext? = nil) {
        style.alignContent = .stretch
        style.backgroundColor = UIColor.ud.N300
        super.init(props: props, style: style, context: context)

        setSubComponents([content])
        content.setSubComponents([labelComponent])
        labelComponent.props.attributedText = formatRichText(text: props.copyWriting)
    }

    override func willReceiveProps(_ old: Props, _ new: Props) -> Bool {
        labelComponent.props.attributedText = formatRichText(text: new.copyWriting)
        return true
    }

    override func render() -> BaseVirtualNode {
        let maxCellWidth = context?.maxCellWidth ?? UIScreen.main.bounds.width
        style.width = CSSValue(cgfloat: maxCellWidth)

        let horizontalMargin = labelComponent.style.marginLeft.value + labelComponent.style.marginRight.value
        labelComponent.props.preferMaxLayoutWidth = maxCellWidth - CGFloat(horizontalMargin)
        return super.render()
    }

    private func formatRichText(text: String) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        return NSAttributedString(string: text,
                                  attributes: [.font: UIFont.systemFont(ofSize: 12),
                                               .foregroundColor: UIColor.ud.N500,
                                               .paragraphStyle: paragraphStyle])
    }
}
