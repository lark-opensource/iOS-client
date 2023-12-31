//
//  MergeForwardTimeCellComponent.swift
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

final class MergeForwardTimeCellComponent: ASComponent<MergeForwardTimeCellComponent.Props, EmptyState, UIView, MergeForwardContext> {
    final class Props: ASComponentProps {
        var timeString: String?
        var chatComponentTheme: ChatComponentTheme = ChatComponentTheme.getChatDefault()
    }

    override init(props: MergeForwardTimeCellComponent.Props,
                  style: ASComponentStyle,
                  context: MergeForwardContext? = nil) {
        super.init(props: props, style: style, context: context)
        self.style.justifyContent = .center
        self.style.paddingTop = 10
        self.style.paddingBottom = 10
    }

    private lazy var blurBackgroundView: BlurViewComponent<MergeForwardContext> = {
        let props = BlurViewProps()
        props.blurRadius = 25
        props.cornerRadius = 6
        let style = ASComponentStyle()
        style.alignSelf = .center
        return BlurViewComponent<MergeForwardContext>(props: props, style: style)
    }()

    lazy var label: UILabelComponent<MergeForwardContext> = {
        let props = UILabelComponentProps()
        props.font = UIFont.ud.body2
        props.textColor = UIColor.ud.N500
        props.textAlignment = .center
        let style = ASComponentStyle()
        style.alignSelf = .center
        style.backgroundColor = .clear
        let label = UILabelComponent<MergeForwardContext>(props: props, style: style)
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
        label.style.marginLeft = props.chatComponentTheme.isDefaultScene ? 0 : 8
        label.style.marginRight = props.chatComponentTheme.isDefaultScene ? 0 : 8
        label.style.marginTop = props.chatComponentTheme.isDefaultScene ? 0 : 4
        label.style.marginBottom = props.chatComponentTheme.isDefaultScene ? 0 : 4
        blurBackgroundView.props.fillColor = props.chatComponentTheme.systemMessageBlurColor
        blurBackgroundView.props.blurRadius = props.chatComponentTheme.isDefaultScene ? 0 : 25
    }
}
