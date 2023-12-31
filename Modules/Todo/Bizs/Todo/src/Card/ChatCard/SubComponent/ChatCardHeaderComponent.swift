//
//  ChatCardHeaderComponent.swift
//  Todo
//
//  Created by wangwanxin on 2023/6/16.
//

import Foundation
import AsyncComponent
import EEFlexiable
import UniverseDesignIcon
import UniverseDesignFont

// nolint: magic number
final class ChatCardHeaderComponentProps: ASComponentProps {
    var text: String?
    var preferMaxLayoutWidth: CGFloat?
}

final class ChatCardHeaderComponent<C: Context>: ASComponent<ChatCardHeaderComponentProps, EmptyState, UIView, C> {

    private lazy var iconComponent: UIImageViewComponent<C> = {
        let props = UIImageViewComponentProps()
        let style = ASComponentStyle()
        style.width = 16.auto()
        style.height = 16.auto()
        style.marginTop = 13.5.auto()
        style.flexShrink = 0
        return UIImageViewComponent(props: props, style: style)
    }()

    private lazy var labelComponent: UILabelComponent<C> = {
        let props = UILabelComponentProps()
        props.font = UDFont.headline
        props.textColor = UIColor.ud.textTitle
        props.numberOfLines = 2
        let style = ASComponentStyle()
        style.backgroundColor = .clear
        style.marginTop = 12.auto()
        style.marginLeft = 8.auto()
        return UILabelComponent(props: props, style: style)
    }()

    override init(props: ChatCardHeaderComponentProps, style: ASComponentStyle, context: C? = nil) {
        style.alignContent = .stretch
        style.flexDirection = .row
        super.init(props: props, style: style, context: context)
        setSubComponents([iconComponent, labelComponent])
    }

    override func willReceiveProps(
        _ old: ChatCardHeaderComponentProps,
        _ new: ChatCardHeaderComponentProps
    ) -> Bool {
        guard let text = new.text else { return true }
        let newIconProps = iconComponent.props
        newIconProps.setImage = { task in
            task.set(image: UDIcon.tabTodoFilled.ud.withTintColor(UIColor.ud.colorfulIndigo))
        }
        iconComponent.props = newIconProps

        let newLabelProps = labelComponent.props
        newLabelProps.text = text
        if let preferMaxLayoutWidth = new.preferMaxLayoutWidth {
            labelComponent.preferMaxLayoutWidth = preferMaxLayoutWidth - 16.0 - 8.0
        }
        labelComponent.props = newLabelProps
        return true
    }

}
