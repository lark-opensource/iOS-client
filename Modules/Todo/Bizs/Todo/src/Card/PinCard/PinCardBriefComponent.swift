//
//  PinCardBriefComponent.swift
//  Todo
//
//  Created by 白言韬 on 2020/12/14.
//

import Foundation
import AsyncComponent
import EEFlexiable
import UniverseDesignColor
import UniverseDesignFont

// nolint: magic number
class PinCardBriefComponent<C: AsyncComponent.Context>: ASComponent<PinCardBriefComponent.Props, EmptyState, UIView, C> {

    class Props: ASComponentProps {
       var title: String = ""
       var setIcon: ((UIImageView) -> Void)?
       var content: [ComponentWithContext<C>] = []
       var contentPreferMaxWidth: CGFloat = 0
    }

    private let innerMargin: CSSValue = CSSValue(cgfloat: 12)

    override init(props: PinCardBriefComponent.Props, style: ASComponentStyle, context: C? = nil) {
        style.backgroundColor = .clear
        style.flexDirection = .row
        style.alignItems = .stretch
        style.cornerRadius = 10
        style.border = Border(
            BorderEdge(
                width: 1.0,
                color: UIColor.ud.lineBorderCard,
                style: .solid
            )
        )
        super.init(props: props, style: style, context: context)

        setSubComponents([icon, container])
        updateUI(props: props)
    }

    // header
    private lazy var icon: UIImageViewComponent<C> = {
        let props = UIImageViewComponentProps()
        let style = ASComponentStyle()
        style.width = 32.auto()
        style.height = 32.auto()
        style.marginTop = 12
        style.marginLeft = 8
        style.marginBottom = 12
        style.flexShrink = 0
        return UIImageViewComponent<C>(props: props, style: style)
    }()

    // Title
    private lazy var titleLabel: UILabelComponent<C> = {
        let props = UILabelComponentProps()
        props.font = UDFont.headline
        props.textColor = UIColor.ud.textTitle
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

   override func willReceiveProps(
        _ old: PinCardBriefComponent.Props,
        _ new: PinCardBriefComponent.Props
   ) -> Bool {
        updateUI(props: new)
        return true
    }

    private func updateUI(props: PinCardBriefComponent.Props) {
        style.width = CSSValue(cgfloat: props.contentPreferMaxWidth.auto())
        titleLabel.props.text = props.title
        icon.props.setImage = { [weak props] task in
            props?.setIcon?(task.view)
        }
        container.setSubComponents([titleLabel] + props.content)
    }
}
