//
//  AIMockLineSystemCellComponent.swift
//  LarkChat
//
//  Created by Zigeng on 2023/11/30.
//

import UIKit
import Foundation
import EEFlexiable
import AsyncComponent
import LarkMessageCore
import LarkMessageBase
import EEAtomic

final public class AIMockLineSystemCellComponentProps: ASComponentProps {
    private var _styleColor = Atomic<UIColor>(UIColor.ud.textPlaceholder)
    public var styleColor: UIColor {
        get { return _styleColor.wrappedValue ?? UIColor.ud.textPlaceholder }
        set { _styleColor.wrappedValue = newValue }
    }
    private var _centerText = Atomic<String?>("")
    public var centerText: String? {
        get { return _centerText.wrappedValue ?? "" }
        set { _centerText.wrappedValue = newValue }
    }
    private var _textFont = Atomic<UIFont>(UIFont.ud.body2)
    public var textFont: UIFont {
        get { return _textFont.wrappedValue ?? UIFont.ud.body2 }
        set { _textFont.wrappedValue = newValue }
    }
    private var _textColor = Atomic<UIColor>(UIColor.ud.textPlaceholder)
    public var textColor: UIColor {
        get { return _textColor.wrappedValue ?? UIColor.ud.textPlaceholder }
        set { _textColor.wrappedValue = newValue }
    }
    private var _backgroundColor = Atomic<UIColor>(UIColor.clear)
    public var backgroundColor: UIColor {
        get { return _backgroundColor.wrappedValue ?? UIColor.clear }
        set { _backgroundColor.wrappedValue = newValue }
    }
    public var chatComponentTheme: ChatComponentTheme = ChatComponentTheme.getChatDefault()
}

final public class AIMockLineSystemCellComponent<C: PageContext>: ASComponent<AIMockLineSystemCellComponentProps, EmptyState, UIView, C> {
    var leftLineProps = GradientComponent<C>.Props()
    let leftGradientStyle = ASComponentStyle()
    let rightGradientStyle = ASComponentStyle()

    lazy var leftLine: ASLayoutComponent<C> = {
        leftLineProps.colors = [props.styleColor.withAlphaComponent(0), props.styleColor.withAlphaComponent(0.5)]
        leftLineProps.locations = [0.0, 1.0]
        leftLineProps.direction = .horizontal
        leftGradientStyle.marginLeft = 15
        leftGradientStyle.marginRight = 10
        leftGradientStyle.width = 100%
        leftGradientStyle.height = CSSValue(cgfloat: 2 / UIScreen.main.scale)
        leftGradientStyle.backgroundColor = UIColor.clear

        let leftLayoutStyle = ASComponentStyle()
        leftLayoutStyle.flexGrow = 1
        leftLayoutStyle.alignSelf = .center

        return ASLayoutComponent<C>(style: leftLayoutStyle, [
            GradientComponent<C>(props: leftLineProps, style: leftGradientStyle)
        ])
    }()

    var rightLineProps = GradientComponent<C>.Props()

    lazy var rightLine: ASLayoutComponent<C> = {
        rightLineProps.colors = [props.styleColor.withAlphaComponent(0.5), props.styleColor.withAlphaComponent(0)]
        rightLineProps.locations = [0.0, 1.0]
        rightLineProps.direction = .horizontal
        rightGradientStyle.marginLeft = 10
        rightGradientStyle.marginRight = 15
        rightGradientStyle.width = 100%
        rightGradientStyle.height = CSSValue(cgfloat: 2 / UIScreen.main.scale)
        rightGradientStyle.backgroundColor = UIColor.clear

        let rightLayoutStyle = ASComponentStyle()
        rightLayoutStyle.flexGrow = 1
        rightLayoutStyle.alignSelf = .center

        return ASLayoutComponent<C>(style: rightLayoutStyle, [
            GradientComponent<C>(props: rightLineProps, style: rightGradientStyle)
        ])
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

    lazy var label: UILabelComponent<C> = {
        let labelProps = UILabelComponentProps()
        labelProps.text = props.centerText
        labelProps.font = props.textFont
        labelProps.textColor = props.textColor
        labelProps.numberOfLines = 1
        let labelStyle = ASComponentStyle()
        labelStyle.flexGrow = 0
        labelStyle.flexShrink = 0
        labelStyle.marginLeft = 8
        labelStyle.marginRight = 8
        labelStyle.marginTop = 1
        labelStyle.marginBottom = 1
        labelStyle.backgroundColor = .clear
        return UILabelComponent<C>(props: labelProps, style: labelStyle)
    }()

    public override init(props: AIMockLineSystemCellComponentProps, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
        self.style.paddingTop = 12
        self.style.paddingBottom = 12
        self.style.backgroundColor = props.backgroundColor
        self.style.alignContent = .stretch
        self.style.justifyContent = .center

        setSubComponents([
            leftLine,
            blurBackgroundView,
            rightLine
        ])
        blurBackgroundView.setSubComponents([label])
    }

    public override func willReceiveProps(_ old: AIMockLineSystemCellComponentProps, _ new: AIMockLineSystemCellComponentProps) -> Bool {
        style.backgroundColor = new.backgroundColor
        blurBackgroundView.props.fillColor = new.chatComponentTheme.systemMessageBlurColor
        blurBackgroundView.props.blurRadius = new.chatComponentTheme.isDefaultScene ? 0 : 25
        label.style.marginLeft = new.chatComponentTheme.isDefaultScene ? 0 : 8
        label.style.marginRight = new.chatComponentTheme.isDefaultScene ? 0 : 8
        label.style.marginTop = new.chatComponentTheme.isDefaultScene ? 0 : 4
        label.style.marginBottom = new.chatComponentTheme.isDefaultScene ? 0 : 4
        leftGradientStyle.marginRight = new.chatComponentTheme.isDefaultScene ? 10 : 8
        rightGradientStyle.marginLeft = new.chatComponentTheme.isDefaultScene ? 10 : 8

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
