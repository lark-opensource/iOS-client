//
//  MessageDetailPlaceholderTipCellComponent.swift
//  LarkChat
//
//  Created by 赵家琛 on 2020/11/16.
//
import UIKit
import Foundation
import EEFlexiable
import AsyncComponent
import LarkMessageBase

final class MessageDetailPlaceholderTipCellComponent: ASComponent<MessageDetailPlaceholderTipCellComponent.Props, EmptyState, UIView, MessageDetailContext> {
    final class Props: ASComponentProps {
        var copyWriting: String = ""
    }

    lazy var labelComponent: RichLabelComponent<MessageDetailContext> = {
        let style = ASComponentStyle()
        style.backgroundColor = UIColor.clear
        style.marginLeft = 15
        style.marginRight = 15
        style.flexGrow = 1
        style.marginTop = 12
        return RichLabelComponent<MessageDetailContext>(props: RichLabelProps(), style: style)
    }()

    override init(props: MessageDetailPlaceholderTipCellComponent.Props, style: ASComponentStyle, context: MessageDetailContext? = nil) {
        style.paddingBottom = 8
        style.paddingTop = 8
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

        let horizontalMargin = labelComponent.style.marginLeft.value + labelComponent.style.marginRight.value
        labelComponent.props.preferMaxLayoutWidth = maxCellWidth - CGFloat(horizontalMargin)
        return super.render()
    }

    private func formatRichText(text: String) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        return NSAttributedString(string: text,
                                  attributes: [.font: UIFont.systemFont(ofSize: 14),
                                               .foregroundColor: UIColor.ud.N500,
                                               .paragraphStyle: paragraphStyle])
    }
}
