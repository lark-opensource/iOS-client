//
//  ChatTopMsgTipCellComponent.swift
//  LarkChat
//
//  Created by zhaojiachen on 2021/11/4.
//

import UIKit
import Foundation
import AsyncComponent
import LarkMessageBase
import LarkMessageCore
import EEFlexiable

final class ChatTopMsgTipCellComponent: ASComponent<ChatTopMsgTipCellComponent.Props, EmptyState, UIView, ChatContext> {
    final class Props: ASComponentProps {
        var tip: String = ""
        var chatComponentTheme: ChatComponentTheme = ChatComponentTheme.getChatDefault()
    }

    lazy var labelComponent: RichLabelComponent<ChatContext> = {
        let style = ASComponentStyle()
        style.backgroundColor = UIColor.clear
        style.alignSelf = .center
        return RichLabelComponent<ChatContext>(props: RichLabelProps(), style: style)
    }()

    private lazy var blurBackgroundView: BlurViewComponent<ChatContext> = {
        let props = BlurViewProps()
        props.blurRadius = 25
        props.cornerRadius = 6
        let style = ASComponentStyle()
        style.alignSelf = .center
        return BlurViewComponent<ChatContext>(props: props, style: style)
    }()

    override init(props: ChatTopMsgTipCellComponent.Props, style: ASComponentStyle, context: ChatContext? = nil) {
        style.backgroundColor = UIColor.clear
        super.init(props: props, style: style, context: context)
        self.style.width = CSSValue(cgfloat: context?.maxCellWidth ?? UIScreen.main.bounds.width)
        self.style.justifyContent = .center
        setSubComponents([blurBackgroundView])
        blurBackgroundView.setSubComponents([labelComponent])
        labelComponent.props.attributedText = formatRichText(text: props.tip, color: props.chatComponentTheme.systemTextColor)
    }

    override func willReceiveProps(_ old: Props, _ new: Props) -> Bool {
        labelComponent.props.attributedText = formatRichText(text: new.tip, color: new.chatComponentTheme.systemTextColor)
        labelComponent.style.marginLeft = new.chatComponentTheme.isDefaultScene ? 0 : 8
        labelComponent.style.marginRight = new.chatComponentTheme.isDefaultScene ? 0 : 8
        labelComponent.style.marginTop = new.chatComponentTheme.isDefaultScene ? 0 : 4
        labelComponent.style.marginBottom = new.chatComponentTheme.isDefaultScene ? 0 : 4

        blurBackgroundView.props.fillColor = new.chatComponentTheme.systemMessageBlurColor
        blurBackgroundView.props.blurRadius = new.chatComponentTheme.isDefaultScene ? 0 : 25
        return true
    }

    override func render() -> BaseVirtualNode {
        let maxCellWidth = context?.maxCellWidth ?? UIScreen.main.bounds.width
        style.width = CSSValue(cgfloat: maxCellWidth)

        let horizontalMargin = labelComponent.style.marginLeft.value + labelComponent.style.marginRight.value
        labelComponent.props.preferMaxLayoutWidth = maxCellWidth - CGFloat(horizontalMargin)
        return super.render()
    }

    private func formatRichText(text: String, color: UIColor) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        return NSAttributedString(string: text,
                                  attributes: [.font: UIFont.ud.body2,
                                               .foregroundColor: color,
                                               .paragraphStyle: paragraphStyle])
    }
}
