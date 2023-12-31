//
//  MessageBriefComponent.swift
//  LarkMessageCore
//
//  Created by zc09v on 2019/9/24.
//

import UIKit
import Foundation
import AsyncComponent
import EEFlexiable

public final class MessageBriefComponent<C: AsyncComponent.Context>: ASComponent<MessageBriefComponent.Props, EmptyState, UIView, C> {

    public final class Props: ASComponentProps {
        public var title: String = ""
        public var setIcon: ((UIImageView) -> Void)?
        public var content: [ComponentWithContext<C>] = []
        public var contentPreferMaxWidth: CGFloat = 0
    }

    private let innerMargin: CSSValue = CSSValue(cgfloat: 12)

    public override init(props: MessageBriefComponent.Props, style: ASComponentStyle, context: C? = nil) {
        style.backgroundColor = .clear
        style.flexDirection = .row
        style.alignItems = .stretch
        style.cornerRadius = 10
        style.border = Border(BorderEdge(width: 1, color: UIColor.ud.N300, style: .solid))
        super.init(props: props, style: style, context: context)

        setSubComponents([icon, container])
        updateUI(props: props)
    }

    // header
    private lazy var icon: UIImageViewComponent<C> = {
        let props = UIImageViewComponentProps()
        let style = ASComponentStyle()
        style.width = 32.auto()
        style.height = style.width
        style.marginLeft = 8
        style.flexShrink = 0
        style.alignSelf = .center
        return UIImageViewComponent<C>(props: props, style: style)
    }()

    // Title
    private lazy var titleLabel: UILabelComponent<C> = {
        let props = UILabelComponentProps()
        props.font = UIFont.ud.headline
        props.textColor = UIColor.ud.N900
        props.numberOfLines = 1

        let style = ASComponentStyle()
        style.backgroundColor = .clear
        style.marginBottom = 4
        return UILabelComponent<C>(props: props, style: style)
    }()

    // Container
    lazy var container: ASLayoutComponent<C> = {
        let style = ASComponentStyle()
        style.marginTop = 6
        style.marginLeft = 8
        style.marginRight = 16
        style.marginBottom = 6
        style.flexDirection = .column
        style.alignSelf = .center
        return ASLayoutComponent(style: style, context: context, [])
    }()

    public override func willReceiveProps(_ old: MessageBriefComponent.Props,
                                          _ new: MessageBriefComponent.Props) -> Bool {
        updateUI(props: new)
        return true
    }

    private func updateUI(props: MessageBriefComponent.Props) {
        style.width = CSSValue(cgfloat: props.contentPreferMaxWidth)
        titleLabel.props.text = props.title
        icon.props.setImage = { [weak props] task in
            props?.setIcon?(task.view)
        }
        container.setSubComponents([titleLabel] + props.content)
    }
}
