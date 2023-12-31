//
//  SystemCellComponent.swift
//  LarkThread
//
//  Created by liuwanlin on 2019/2/15.
//

import UIKit
import Foundation
import EEFlexiable
import AsyncComponent
import RichLabel
import FigmaKit
import LarkMessageBase

public class BlurViewProps: ASComponentProps {
    public var blurRadius: CGFloat = 0
    public var fillColor: UIColor = .clear
    public var cornerRadius: CGFloat = 0
}

// 系统的 UIVisualEffectView 不能添加 subview，暂时去掉，等 FigmaKit.BackgroundBlurView 重新上线再加回来
// Author: wanghaidong
open class BlurViewComponent<C: Context>: ASComponent<BlurViewProps, EmptyState, UIView, C> {

    public override func update(view: UIView) {
        // view.blurRadius = props.blurRadius
        view.backgroundColor = props.fillColor
        view.layer.cornerRadius = props.cornerRadius
        view.clipsToBounds = props.cornerRadius != 0
    }
}

public protocol SystemCellComponentContext: ViewModelContext {
    var maxCellWidth: CGFloat { get }
}

open class SystemCellComponent<C: SystemCellComponentContext>: ASComponent<SystemCellComponent.Props, EmptyState, UIView, C> {
    public final class Props: ASComponentProps {
        public var labelAttrText = NSAttributedString(string: "")
        public var textLinks: [LKTextLink] = []
        // 是否可交互
        public var isUserInteractionEnabled: Bool = true
        public var chatComponentTheme: ChatComponentTheme = ChatComponentTheme.getChatDefault()
    }

    private lazy var blurBackgroundView: BlurViewComponent<C> = {
        let props = BlurViewProps()
        props.blurRadius = 25
        props.cornerRadius = 6
        let style = ASComponentStyle()
        style.alignSelf = .center
        return BlurViewComponent<C>(props: props, style: style)
    }()

    lazy var labelComponent: RichLabelComponent<C> = {
        let labelProps = RichLabelProps()
        let style = ASComponentStyle()
        style.marginLeft = 8
        style.marginRight = 8
        style.marginTop = 4
        style.marginBottom = 4
        style.backgroundColor = UIColor.clear
        style.alignSelf = .center
        return RichLabelComponent<C>(props: labelProps, style: style)
    }()

    public override init(props: Props, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
        style.paddingBottom = 12
        style.paddingTop = 12
        style.paddingLeft = 15
        style.paddingRight = 15
        style.justifyContent = .center
        setSubComponents([blurBackgroundView])
        blurBackgroundView.setSubComponents([labelComponent])
        setupProps(props)
    }

    public override func willReceiveProps(_ old: SystemCellComponent<C>.Props, _ new: SystemCellComponent<C>.Props) -> Bool {
        setupProps(new)
        return true
    }

    public override func render() -> BaseVirtualNode {
        let maxCellWidth = (context?.maxCellWidth ?? UIScreen.main.bounds.width)
        style.width = CSSValue(cgfloat: maxCellWidth)
        let horizontalMargin = labelComponent.style.marginLeft.value + labelComponent.style.marginRight.value
        labelComponent.props.preferMaxLayoutWidth = maxCellWidth - 30 - CGFloat(horizontalMargin)
        return super.render()
    }

    private func setupProps(_ props: Props) {
        blurBackgroundView.props.fillColor = props.chatComponentTheme.systemMessageBlurColor
        blurBackgroundView.props.blurRadius = props.chatComponentTheme.isDefaultScene ? 0 : 25
        labelComponent.style.marginLeft = props.chatComponentTheme.isDefaultScene ? 0 : 8
        labelComponent.style.marginRight = props.chatComponentTheme.isDefaultScene ? 0 : 8
        labelComponent.style.marginTop = props.chatComponentTheme.isDefaultScene ? 0 : 4
        labelComponent.style.marginBottom = props.chatComponentTheme.isDefaultScene ? 0 : 4

        labelComponent.props.backgroundColor = UIColor.clear
        labelComponent.props.textLinkList = props.textLinks
        labelComponent.props.numberOfLines = 0
        labelComponent.props.linkAttributes = [.foregroundColor: UIColor.ud.textLinkNormal]
        labelComponent.props.attributedText = props.labelAttrText
    }

    public override func update(view: UIView) {
        super.update(view: view)
        view.isUserInteractionEnabled = props.isUserInteractionEnabled
    }
}
