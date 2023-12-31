//
//  PreviewSignCellComponent.swift
//  LarkMessageCore
//
//  Created by ByteDance on 2022/10/9.
//

import UIKit
import Foundation
import EEFlexiable
import AsyncComponent

final public class PreviewSignCellComponentProps: ASComponentProps {
    public var styleColor: UIColor = UIColor.ud.textPlaceholder
    public var centerText: String?
    public var textFont: UIFont = UIFont.ud.caption1
    public var textColor: UIColor = UIColor.ud.textPlaceholder
    public var backgroundColor: UIColor = UIColor.clear
    public var chatComponentTheme: ChatComponentTheme = ChatComponentTheme.getChatDefault()
}

final class PreviewSignCellComponent<C: PreviewSignCellContext>: ASComponent<PreviewSignCellComponentProps, EmptyState, UIView, C> {

    lazy var label: UILabelComponent<C> = {
        let labelProps = UILabelComponentProps()
        labelProps.text = props.centerText
        labelProps.font = props.textFont
        labelProps.textColor = props.textColor
        labelProps.lineBreakMode = .byWordWrapping
        labelProps.numberOfLines = 1
        let labelStyle = ASComponentStyle()
        labelStyle.flexGrow = 0
        labelStyle.flexShrink = 0
        labelStyle.backgroundColor = .clear
        labelStyle.marginLeft = 8
        labelStyle.marginRight = 8
        labelStyle.marginTop = 4
        labelStyle.marginBottom = 4
        return UILabelComponent<C>(props: labelProps, style: labelStyle)
    }()

    private lazy var blurBackgroundView: BlurViewComponent<C> = {
        let props = BlurViewProps()
        props.blurRadius = 25
        props.cornerRadius = 6
        let style = ASComponentStyle()
        style.alignSelf = .center
        style.flexGrow = 0
        style.flexShrink = 0
        return BlurViewComponent<C>(props: props, style: style)
    }()

    public override init(props: PreviewSignCellComponentProps, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
        self.style.paddingTop = 12
        self.style.paddingBottom = 12
        self.style.backgroundColor = props.backgroundColor
        self.style.alignContent = .stretch
        self.style.justifyContent = .center

        setSubComponents([
            blurBackgroundView
        ])
        blurBackgroundView.setSubComponents([
            label
        ])
    }

    public override func willReceiveProps(_ old: PreviewSignCellComponentProps, _ new: PreviewSignCellComponentProps) -> Bool {
        style.backgroundColor = new.backgroundColor
        blurBackgroundView.props.fillColor = new.chatComponentTheme.systemMessageBlurColor
        blurBackgroundView.props.blurRadius = new.chatComponentTheme.isDefaultScene ? 0 : 25
        label.style.marginLeft = new.chatComponentTheme.isDefaultScene ? 0 : 8
        label.style.marginRight = new.chatComponentTheme.isDefaultScene ? 0 : 8
        label.style.marginTop = new.chatComponentTheme.isDefaultScene ? 0 : 4
        label.style.marginBottom = new.chatComponentTheme.isDefaultScene ? 0 : 4

        label.props.text = new.centerText
        label.props.font = new.textFont
        label.props.textColor = new.textColor
        return true
    }

    public override func render() -> BaseVirtualNode {
        style.width = CSSValue(cgfloat: context?.maxCellWidth ?? UIScreen.main.bounds.width)
        return super.render()
    }
}
