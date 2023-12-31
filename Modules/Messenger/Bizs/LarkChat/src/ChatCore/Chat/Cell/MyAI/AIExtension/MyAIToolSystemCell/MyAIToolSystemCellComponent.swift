//
//  MyAIToolSystemCellComponent.swift
//  LarkAI
//
//  Created by ByteDance on 2023/6/1.
//

import UIKit
import Foundation
import EEFlexiable
import AsyncComponent
import RichLabel
import LarkMessageBase
import LarkMessageCore
import UniverseDesignIcon
import LKCommonsLogging
import LarkMessengerInterface

public protocol MyAIToolSystemCellContext: ViewModelContext {
    var maxCellWidth: CGFloat { get }
    func getChatThemeScene() -> ChatThemeScene
    var myAIPageService: MyAIPageService? { get }
}

extension PageContext: MyAIToolSystemCellContext {}

open class MyAIToolSystemCellComponent<C: MyAIToolSystemCellContext>: ASComponent<MyAIToolSystemCellComponent.Props, EmptyState, UIView, C> {
    public final class Props: ASComponentProps {
        public var styleColor: UIColor = UIColor.ud.textPlaceholder
        public var centerText: String?
        public var textFont: UIFont = UIFont.ud.body2
        public var textColor: UIColor = UIColor.ud.textPlaceholder
        public var backgroundColor: UIColor = UIColor.clear
        public var chatComponentTheme: ChatComponentTheme = ChatComponentTheme.getChatDefault()
        public var displayTopic: Bool = true
    }

    private let logger = Logger.log(MyAIToolSystemCellComponent.self, category: "MyAITool")
    var leftLineProps = GradientComponent<C>.Props()
    let leftGradientStyle = ASComponentStyle()
    let rightGradientStyle = ASComponentStyle()

    lazy var leftLine: ASLayoutComponent<C> = {
        leftLineProps.colors = [props.styleColor.withAlphaComponent(0.0), props.styleColor.withAlphaComponent(0.5)]
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
        rightLineProps.colors = [props.styleColor.withAlphaComponent(0.5), props.styleColor.withAlphaComponent(0.0)]
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

    lazy var blurBackgroundView: BlurViewComponent<C> = {
        let props = BlurViewProps()
        props.blurRadius = 25
        props.cornerRadius = 6
        let style = ASComponentStyle()
        style.alignSelf = .center
        style.flexGrow = 0
        style.flexShrink = 0
        style.maxWidth = 70%
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
        labelStyle.marginTop = 4
        labelStyle.marginBottom = 4
        labelStyle.backgroundColor = .clear
        return UILabelComponent<C>(props: labelProps, style: labelStyle)
    }()

    lazy var containView: UIViewComponent<C> = {
        let style = ASComponentStyle()
        style.backgroundColor = .clear
        style.alignContent = .stretch
        style.justifyContent = .center
        return UIViewComponent<C>(props: .empty, style: style)
    }()

    public override init(props: MyAIToolSystemCellComponent.Props, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
        self.style.paddingTop = 12
        self.style.paddingBottom = 6
        self.style.backgroundColor = props.backgroundColor
        self.style.flexDirection = .column
        self.style.alignContent = .center
        self.style.justifyContent = .flexStart
        containView.setSubComponents([leftLine, blurBackgroundView, rightLine])
        blurBackgroundView.setSubComponents([label])
        setSubComponents(props.displayTopic ? [
            containView
        ] : [])
    }

    public override func willReceiveProps(_ old: MyAIToolSystemCellComponent.Props, _ new: MyAIToolSystemCellComponent.Props) -> Bool {
        setSubComponents(new.displayTopic ? [
            containView
        ] : [])
        setupNewTopic(props: new)
        return true
    }

    private func setupNewTopic(props: MyAIToolSystemCellComponent.Props) {
        style.backgroundColor = props.backgroundColor
        blurBackgroundView.props.fillColor = props.chatComponentTheme.systemMessageBlurColor
        blurBackgroundView.props.blurRadius = props.chatComponentTheme.isDefaultScene ? 0 : 25
        label.style.marginLeft = props.chatComponentTheme.isDefaultScene ? 0 : 8
        label.style.marginRight = props.chatComponentTheme.isDefaultScene ? 0 : 8
        label.style.marginTop = props.chatComponentTheme.isDefaultScene ? 0 : 4
        label.style.marginBottom = props.chatComponentTheme.isDefaultScene ? 0 : 4
        leftGradientStyle.marginRight = props.chatComponentTheme.isDefaultScene ? 10 : 8
        rightGradientStyle.marginLeft = props.chatComponentTheme.isDefaultScene ? 10 : 8

        label.props.text = props.centerText
        label.props.font = props.textFont
        label.props.textColor = props.textColor
    }

    public override func render() -> BaseVirtualNode {
        style.width = CSSValue(cgfloat: context?.maxCellWidth ?? UIScreen.main.bounds.width)
        return super.render()
    }
}
