//
//  ChatTimeCellComponent.swift
//  LarkNewChat
//
//  Created by qihongye on 2019/4/21.
//

import UIKit
import FigmaKit
import Foundation
import AsyncComponent
import EEFlexiable
import LarkMessageBase
import LarkMessageCore

final class ChatTimeCellComponent: ASComponent<ChatTimeCellComponent.Props, EmptyState, UIView, ChatContext> {
    final class Props: ASComponentProps {
        var timeString: String?
        var chatComponentTheme: ChatComponentTheme = ChatComponentTheme.getChatDefault()
    }

    override init(props: ChatTimeCellComponent.Props,
                  style: ASComponentStyle,
                  context: ChatContext? = nil) {
        super.init(props: props, style: style, context: context)
        self.style.justifyContent = .center
        self.style.paddingTop = 12
        self.style.paddingBottom = 12
    }

    private lazy var blurBackgroundView: BlurViewComponent<ChatContext> = {
        let props = BlurViewProps()
        props.blurRadius = 25
        props.cornerRadius = 6
        let style = ASComponentStyle()
        style.alignSelf = .center
        return BlurViewComponent<ChatContext>(props: props, style: style)
    }()

    lazy var label: UILabelComponent<ChatContext> = {
        let props = UILabelComponentProps()
        props.font = UIFont.ud.body2
        props.textAlignment = .center
        let style = ASComponentStyle()
        style.marginLeft = 8
        style.marginRight = 8
        style.marginTop = 4
        style.marginBottom = 4
        style.alignSelf = .center
        style.backgroundColor = .clear
        let label = UILabelComponent<ChatContext>(props: props, style: style)
        return label
    }()

    override func render() -> BaseVirtualNode {
        label.props.text = props.timeString
        self.style.width = CSSValue(cgfloat: context?.maxCellWidth ?? UIScreen.main.bounds.width)
        setSubComponents([blurBackgroundView])
        blurBackgroundView.setSubComponents([label])
        return super.render()
    }

    override func willReceiveProps(_ old: Props, _ new: Props) -> Bool {
        setupProps(new)
        return true
    }

    private func setupProps(_ props: Props) {
        label.props.textColor = props.chatComponentTheme.systemTextColor
        label.style.marginLeft = props.chatComponentTheme.isDefaultScene ? 0 : 8
        label.style.marginRight = props.chatComponentTheme.isDefaultScene ? 0 : 8
        label.style.marginTop = props.chatComponentTheme.isDefaultScene ? 0 : 4
        label.style.marginBottom = props.chatComponentTheme.isDefaultScene ? 0 : 4
        blurBackgroundView.props.fillColor = props.chatComponentTheme.systemMessageBlurColor
        blurBackgroundView.props.blurRadius = props.chatComponentTheme.isDefaultScene ? 0 : 25
    }
}
