//
//  ChatCardDueTimeComponent.swift
//  Todo
//
//  Created by 白言韬 on 2021/5/23.
//

import Foundation
import AsyncComponent
import EEFlexiable
import UniverseDesignIcon

// nolint: magic number
class ChatCardTimeComponentProps: ASComponentProps {
    var style: ChatCard.TimeComponentStyle = .normal
    var timeInfo: V3ListTimeInfo = V3ListTimeInfo(
        text: "",
        color: UIColor.ud.colorfulBlue,
        reminderIcon: nil,
        repeatRuleIcon: nil,
        textWidth: 0
    )
}

class ChatCardTimeComponent<C: Context>: ASComponent<ChatCardTimeComponentProps, EmptyState, UIView, C> {

    private lazy var iconComponent: UIImageViewComponent<C> = {
        let props = UIImageViewComponentProps()
        let style = ASComponentStyle()
        style.flexShrink = 0
        style.marginRight = 8
        return UIImageViewComponent(props: props, style: style)
    }()

    private lazy var labelComponent: UILabelComponent<C> = {
        let props = UILabelComponentProps()
        props.textColor = UIColor.ud.N900
        props.textAlignment = .left

        let style = ASComponentStyle()
        style.backgroundColor = .clear
        return UILabelComponent(props: props, style: style)
    }()

    private lazy var reminderComponent: UIImageViewComponent<C> = {
        let props = UIImageViewComponentProps()
        let style = ASComponentStyle()
        style.flexShrink = 0
        style.marginLeft = 8
        return UIImageViewComponent(props: props, style: style)
    }()

    private lazy var repeatComponent: UIImageViewComponent<C> = {
        let props = UIImageViewComponentProps()
        let style = ASComponentStyle()
        style.flexShrink = 0
        style.marginLeft = 8
        return UIImageViewComponent(props: props, style: style)
    }()

    override init(props: ChatCardTimeComponentProps, style: ASComponentStyle, context: C? = nil) {
        style.alignContent = .stretch
        style.flexDirection = .row
        super.init(props: props, style: style, context: context)
        setSubComponents([iconComponent, labelComponent, reminderComponent, repeatComponent])
    }

    override func willReceiveProps(
        _ old: ChatCardTimeComponentProps,
        _ new: ChatCardTimeComponentProps
    ) -> Bool {
        let color = new.timeInfo.color
        // icon
        if new.style.isDisplayIcon {
            iconComponent.style.width = new.style.squareIconWidth.auto()
            iconComponent.style.height = new.style.squareIconWidth.auto()
            iconComponent.style.marginTop = new.style.iconMarginTop.auto()
            iconComponent.props.setImage = { task in
                task.set(image: UDIcon.calendarDateOutlined.ud.withTintColor(UIColor.ud.iconN2))
            }
            iconComponent.style.display = .flex
        } else {
            iconComponent.style.display = .none
        }

        // text
        labelComponent.props.text = new.timeInfo.text
        labelComponent.props.textColor = color
        labelComponent.props.font = new.style.font
        labelComponent.props.numberOfLines = new.style.numberOfLines
        labelComponent.style.marginTop = new.style.textMarginTop.auto()
        labelComponent.style.height = new.style.textHeight.auto()

        // remider
        if let reminder = new.timeInfo.reminderIcon {
            reminderComponent.style.width = new.style.squareIconWidth.auto()
            reminderComponent.style.height = new.style.squareIconWidth.auto()
            reminderComponent.style.marginTop = new.style.iconMarginTop.auto()
            reminderComponent.props.setImage = { task in
                let resizedImage = reminder.ud.resized(to: CGSize(width: new.style.squareIconWidth, height: new.style.squareIconWidth))
                task.set(image: resizedImage.ud.withTintColor(color))
            }
            reminderComponent.style.display = .flex
        } else {
            reminderComponent.style.display = .none
        }

        // repeat
        if let repeatRule = new.timeInfo.repeatRuleIcon {
            repeatComponent.style.width = new.style.squareIconWidth.auto()
            repeatComponent.style.height = new.style.squareIconWidth.auto()
            repeatComponent.style.marginTop = new.style.iconMarginTop.auto()
            repeatComponent.props.setImage = { task in
                let resizedImage = repeatRule.ud.resized(to: CGSize(width: new.style.squareIconWidth, height: new.style.squareIconWidth))
                task.set(image: resizedImage.ud.withTintColor(color))
            }
            repeatComponent.style.display = .flex
        } else {
            repeatComponent.style.display = .none
        }

        return true
    }

}
