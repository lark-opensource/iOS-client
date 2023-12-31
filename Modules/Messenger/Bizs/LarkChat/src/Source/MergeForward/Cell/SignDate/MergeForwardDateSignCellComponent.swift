//
//  MergeForwardDateSignCellComponent.swift
//  LarkChat
//
//  Created by 李勇 on 2019/11/13.
//

import UIKit
import Foundation
import AsyncComponent
import EEFlexiable
import LarkMessageBase
import LarkMessageCore

final class MergeForwardDateSignCellComponent: ASComponent<MergeForwardDateSignCellComponent.Props, EmptyState, UIView, MergeForwardContext> {
    final class Props: ASComponentProps {
        var dateText: String = ""
        var styleColor: UIColor = UIColor.ud.B600
        var chatComponentTheme: ChatComponentTheme = ChatComponentTheme.getChatDefault()
    }

    private lazy var timeLabelContainer: BlurViewComponent<MergeForwardContext> = {
        let props = BlurViewProps()
        props.blurRadius = 25
        props.cornerRadius = 6
        let style = ASComponentStyle()
        style.alignSelf = .center
        style.flexGrow = 1
        return BlurViewComponent<MergeForwardContext>(props: props, style: style)
    }()

    private lazy var newMsgLabelContainer: BlurViewComponent<MergeForwardContext> = {
        let props = BlurViewProps()
        props.blurRadius = 25
        props.cornerRadius = 6
        let style = ASComponentStyle()
        style.alignSelf = .center
        style.flexGrow = 1
        return BlurViewComponent<MergeForwardContext>(props: props, style: style)
    }()

    lazy var timeLabel: UILabelComponent<MergeForwardContext> = {
        let props = UILabelComponentProps()
        props.font = UIFont.ud.body2
        props.textAlignment = .left
        props.textColor = UIColor.ud.N900
        props.text = self.props.dateText
        let style = ASComponentStyle()
        style.backgroundColor = .clear
        style.flexGrow = 1

        return UILabelComponent<MergeForwardContext>(props: props, style: style)
    }()

    lazy var newMsgLabel: UILabelComponent<MergeForwardContext> = {
        let props = UILabelComponentProps()
        props.textColor = self.props.styleColor
        props.font = UIFont.ud.body2
        props.textAlignment = .right
        props.text = BundleI18n.LarkChat.Lark_Legacy_NewMessageSign

        let style = ASComponentStyle()
        style.flexGrow = 1
        style.backgroundColor = .clear

        return UILabelComponent<MergeForwardContext>(props: props, style: style)
    }()

    lazy var top: ASLayoutComponent<MergeForwardContext> = {
        let style = ASComponentStyle()
        style.alignContent = .stretch
        style.width = 100%
        style.paddingLeft = 15
        style.paddingRight = 15
        style.paddingBottom = 6

        return ASLayoutComponent<MergeForwardContext>(style: style, [timeLabelContainer, newMsgLabelContainer])
    }()

    lazy var bottomLine: UIViewComponent<MergeForwardContext> = {
        let style = ASComponentStyle()
        style.width = 100%
        style.height = CSSValue(cgfloat: 1 / UIScreen.main.scale)
        style.backgroundColor = props.styleColor
        return UIViewComponent<MergeForwardContext>(props: .empty, style: style)
    }()

    override init(props: Props, style: ASComponentStyle, context: MergeForwardContext? = nil) {
        super.init(props: props, style: style, context: context)
        self.style.paddingTop = 20
        self.style.flexDirection = .column
    }

    override func willReceiveProps(_ old: Props, _ new: Props) -> Bool {
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
        return super.render()
    }
}
