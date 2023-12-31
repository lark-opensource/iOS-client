//
//  VoteContentComponent.swift
//  LarkMessageCore
//
//  Created by KT on 2019/6/21.
//

import Foundation
import UIKit
import AsyncComponent
import EEFlexiable
import LarkMessageBase
import LarkModel
import UniverseDesignIcon
import UniverseDesignCardHeader

/// component 最小依赖
public protocol VoteContentComponentContext: ComponentContext { }

/// Component Key
struct VoteContentComponentConstant {
    static let voteContentKey = "VoteContentComponentConstant_VoteContentKey"
    static let voteButtonKey = "VoteContentComponentConstant_VoteButtonKey"
}

public final class VoteContentComponent<C: VoteContentComponentContext>: ASComponent<VoteContentComponent.Props, EmptyState, UIView, C> {

    private enum Cons {
        static var innerMargin: CGFloat { 12 }
        static var titleMargin: CGFloat {
            return 2
                + (typeFont.figmaHeight - typeFont.rowHeight) / 2
                + (titleFont.figmaHeight - titleFont.rowHeight) / 2
        }
        static var headerTopPadding: CGFloat { 12 }
        static var headerBottomPadding: CGFloat { 12 }
        static var footerTopMargin: CGFloat { 16 }
        static var typeFont: UIFont { UIFont.ud.caption1 }
        static var titleFont: UIFont { UIFont.ud.headline }
        static var contentFont: UIFont { UIFont.ud.body2 }
    }

    public final class Props: ASComponentProps {
        public var contentPreferMaxWidth: CGFloat = 0
        public var selectTypeLabelText: String?
        public var title: String?
        public var content: [ComponentWithContext<C>] = []
        public var footerText: String = ""
        public var hasBottomMargin: Bool = false
        public var buttonDisableTitle: String = ""
        public var buttonEnableTitle: String = ""
        public var submitEnable: Bool = false
        public var onViewClicked: (() -> Void)?
    }

    public override init(props: VoteContentComponent.Props, style: ASComponentStyle, context: C? = nil) {
        style.backgroundColor = .clear
        style.flexDirection = .column
        style.alignItems = .stretch
        style.backgroundColor = UIColor.ud.bgFloat
        props.key = VoteContentComponentConstant.voteContentKey
        super.init(props: props, style: style, context: context)

        setSubComponents([header, container, footer])
        header.setSubComponents([voteIconComponent, headerTextContainer])
        updateUI(props: props)
    }

    private lazy var voteIconComponent: UIImageViewComponent<C> = {
        let props = UIImageViewComponentProps()
        let iconSize = 16.auto()
        props.setImage = { $0.set(image: UDIcon.getIconByKey(.voteFilled,
                                                             iconColor: UDCardHeaderHue.indigo.textColor,
                                                             size: CGSize(width: iconSize, height: iconSize))) }
        let style = ASComponentStyle()
        style.width = CSSValue(cgfloat: iconSize)
        style.height = CSSValue(cgfloat: iconSize)
        style.marginRight = 8
        style.marginTop = 1.auto()
        style.flexShrink = 0
        return UIImageViewComponent<C>(props: props, style: style)
    }()

    lazy var headerTextContainer: ASLayoutComponent<C> = {
        let style = ASComponentStyle()
        style.flexDirection = .column
        return ASLayoutComponent(style: style, context: context, [titleLabel, selectTypeLabel])
    }()

    // header
    private lazy var header: UDCardHeaderComponent<C> = {
        let props = UDCardHeaderComponentProps()
        props.colorHue = UDCardHeaderHue.indigo
        let style = ASComponentStyle()
        style.flexDirection = .row
        style.paddingLeft = CSSValue(cgfloat: Cons.innerMargin)
        style.paddingRight = CSSValue(cgfloat: Cons.innerMargin)
        style.paddingTop = CSSValue(cgfloat: Cons.headerTopPadding)
        style.paddingBottom = CSSValue(cgfloat: Cons.headerBottomPadding)
        return UDCardHeaderComponent<C>(props: props, style: style)
    }()

    // 标题：单选、多选
    private lazy var selectTypeLabel: UILabelComponent<C> = {
        let props = UILabelComponentProps()
        props.font = Cons.typeFont
        props.textColor = UDCardHeaderHue.indigo.textColor
        props.numberOfLines = 1

        let style = ASComponentStyle()
        style.backgroundColor = .clear
        return UILabelComponent<C>(props: props, style: style)
    }()

    // Title
    private lazy var titleLabel: UILabelComponent<C> = {
        let props = UILabelComponentProps()
        props.font = Cons.titleFont
        props.textColor = UDCardHeaderHue.indigo.textColor
        props.numberOfLines = 0

        let style = ASComponentStyle()
        style.backgroundColor = .clear
        style.marginBottom = CSSValue(cgfloat: Cons.titleMargin)
        return UILabelComponent<C>(props: props, style: style)
    }()

    // Container
    lazy var container: ASLayoutComponent<C> = {
        let style = ASComponentStyle()
        style.marginTop = CSSValue(cgfloat: Cons.innerMargin)
        style.marginLeft = CSSValue(cgfloat: Cons.innerMargin)
        style.marginRight = CSSValue(cgfloat: Cons.innerMargin)
        style.flexDirection = .column
        return ASLayoutComponent(style: style, context: context, [])
    }()

    // Footer
    lazy var footer: ASLayoutComponent<C> = {
        let style = ASComponentStyle()
        style.marginTop = CSSValue(cgfloat: Cons.footerTopMargin)
        style.marginLeft = CSSValue(cgfloat: Cons.innerMargin)
        style.marginRight = CSSValue(cgfloat: Cons.innerMargin)
        style.flexDirection = .column
        return ASLayoutComponent(style: style, context: context, [submitButton, titleFooter])
    }()

    lazy var submitButton: VoteButtonComponent<C> = {
        let props = VoteButtonComponentProps()
        props.key = VoteContentComponentConstant.voteButtonKey
        let style = ASComponentStyle()
        return VoteButtonComponent(props: props, style: style)
    }()

    lazy var titleFooter: UILabelComponent<C> = {
        let props = UILabelComponentProps()
        props.font = UIFont.ud.caption1
        props.numberOfLines = 0
        props.textColor = UIColor.ud.textTitle

        let style = ASComponentStyle()
        style.backgroundColor = .clear
        return UILabelComponent<C>(props: props, style: style)
    }()

    public override func willReceiveProps(_ old: VoteContentComponent.Props,
                                          _ new: VoteContentComponent.Props) -> Bool {
        updateUI(props: new)
        return true
    }

    private func updateUI(props: VoteContentComponent.Props) {
        style.width = CSSValue(cgfloat: props.contentPreferMaxWidth)
        selectTypeLabel.props.text = props.selectTypeLabelText
        titleLabel.props.text = props.title
        container.setSubComponents(props.content)
        titleFooter.props.text = props.footerText

        titleFooter.style.display = props.footerText.isEmpty ? .none : .flex
        footer.style.marginBottom = props.hasBottomMargin ? CSSValue(cgfloat: Cons.innerMargin) : 0

        submitButton.style.display = props.footerText.isEmpty ? .flex : .none
        let buttonProps = submitButton.props
        buttonProps.text = props.submitEnable ? props.buttonEnableTitle : props.buttonDisableTitle
        buttonProps.enable = props.submitEnable
        buttonProps.onViewClicked = { [weak props] in
            props?.onViewClicked?()
        }
        submitButton.props = buttonProps
    }
}
