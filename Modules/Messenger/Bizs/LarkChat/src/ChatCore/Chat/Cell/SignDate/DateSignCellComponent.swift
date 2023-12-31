//
//  DateSignCellComponent.swift
//  LarkNewChat
//
//  Created by qihongye on 2019/5/8.
//

import UIKit
import Foundation
import AsyncComponent
import EEFlexiable
import LarkMessageBase
import LarkMessageCore
import UniverseDesignColor

final class DateSignCellComponent: ASComponent<DateSignCellComponent.Props, EmptyState, UIView, ChatContext> {
    final class Props: ASComponentProps {
        var dateText: String = ""
        var styleColor: UIColor = UIColor.ud.primaryContentPressed
        var chatComponentTheme: ChatComponentTheme = ChatComponentTheme.getChatDefault()
    }

    private lazy var timeLabelContainer: BlurViewComponent<ChatContext> = {
        let props = BlurViewProps()
        props.blurRadius = 25
        props.cornerRadius = 6
        let style = ASComponentStyle()
        style.alignSelf = .center
        return BlurViewComponent<ChatContext>(props: props, style: style)
    }()

    private lazy var newMsgLabelContainer: BlurViewComponent<ChatContext> = {
        let props = BlurViewProps()
        props.blurRadius = 25
        props.cornerRadius = 6
        let style = ASComponentStyle()
        style.alignSelf = .center
        return BlurViewComponent<ChatContext>(props: props, style: style)
    }()

    lazy var timeLabel: UILabelComponent<ChatContext> = {
        let props = UILabelComponentProps()
        props.font = UIFont.ud.body2
        props.textAlignment = .center
        props.textColor = UIColor.ud.N900
        props.text = self.props.dateText
        let style = ASComponentStyle()
        style.backgroundColor = .clear

        return UILabelComponent<ChatContext>(props: props, style: style)
    }()

    lazy var newMsgLabel: UILabelComponent<ChatContext> = {
        let props = UILabelComponentProps()
        props.textColor = self.props.styleColor
        props.font = UIFont.ud.body2
        props.textAlignment = .center
        props.text = BundleI18n.LarkChat.Lark_Legacy_NewMessageSign

        let style = ASComponentStyle()
        style.backgroundColor = .clear

        return UILabelComponent<ChatContext>(props: props, style: style)
    }()

    lazy var top: ASLayoutComponent<ChatContext> = {
        let style = ASComponentStyle()
        style.alignContent = .stretch
        style.width = 100%
        style.paddingLeft = 15
        style.paddingRight = 15
        style.paddingBottom = 6
        style.justifyContent = .spaceBetween

        return ASLayoutComponent<ChatContext>(style: style, [timeLabelContainer, newMsgLabelContainer])
    }()

    lazy var bottomLine: UIViewComponent<ChatContext> = {
        let style = ASComponentStyle()
        style.width = 100%
        style.height = CSSValue(cgfloat: 1)
        style.backgroundColor = props.styleColor
        return UIViewComponent<ChatContext>(props: .empty, style: style)
    }()

    override init(props: Props, style: ASComponentStyle, context: ChatContext? = nil) {
        super.init(props: props, style: style, context: context)
        self.style.paddingTop = 20
        self.style.flexDirection = .column
    }

    override func willReceiveProps(_ old: DateSignCellComponent.Props, _ new: DateSignCellComponent.Props) -> Bool {
        timeLabelContainer.props.fillColor = new.chatComponentTheme.systemMessageBlurColor
        newMsgLabelContainer.props.fillColor = new.chatComponentTheme.systemMessageBlurColor
        timeLabel.props.text = new.dateText
        timeLabel.style.marginLeft = new.chatComponentTheme.isDefaultScene ? 0 : 8
        timeLabel.style.marginRight = new.chatComponentTheme.isDefaultScene ? 0 : 8
        timeLabel.style.marginTop = new.chatComponentTheme.isDefaultScene ? 0 : 4
        timeLabel.style.marginBottom = new.chatComponentTheme.isDefaultScene ? 0 : 4

        newMsgLabel.style.marginLeft = new.chatComponentTheme.isDefaultScene ? 0 : 8
        newMsgLabel.style.marginRight = new.chatComponentTheme.isDefaultScene ? 0 : 8
        newMsgLabel.style.marginTop = new.chatComponentTheme.isDefaultScene ? 0 : 4
        newMsgLabel.style.marginBottom = new.chatComponentTheme.isDefaultScene ? 0 : 4

        bottomLine.style.backgroundColor = new.styleColor
        return true
    }

    override func render() -> BaseVirtualNode {
        self.style.width = CSSValue(cgfloat: context?.maxCellWidth ?? UIScreen.main.bounds.width)
        setSubComponents([top, bottomLine])
        newMsgLabelContainer.setSubComponents([newMsgLabel])
        timeLabelContainer.setSubComponents([timeLabel])
        return super.render()
    }
}
