//
//  EventCardTimeComponent.swift
//  Calendar
//
//  Created by heng zhu on 2019/6/19.
//

import UIKit
import UniverseDesignIcon
import Foundation
import CalendarFoundation
import AsyncComponent
import EEFlexiable

final class EventCardTimeComponentProps: ASComponentProps {
    var conflictText: String?
    var timeString: String?
    var showUpdatedFlag: Bool?
}

final class EventCardTimeComponent<C: Context>: ASComponent<EventCardTimeComponentProps, EmptyState, UIView, C> {
    private let iconComponent: UIImageViewComponent<C> = {
        let props = UIImageViewComponentProps()
        props.setImage = { task in
            let image = UDIcon.getIconByKeyNoLimitSize(.timeOutlined).renderColor(with: .n2)
            task.set(image: image)
        }
        let style = ASComponentStyle()
        style.width = 16.auto()
        style.height = 16.auto()
        style.flexShrink = 0
        return UIImageViewComponent(props: props, style: style)
    }()

    private let titleLabel: UILabelComponent<C> = {
        let titleProps = UILabelComponentProps()
        titleProps.font = UIFont.ud.body2
        titleProps.textColor = UIColor.ud.textTitle
        titleProps.numberOfLines = 4
        let style = ASComponentStyle()
        style.width = 100%
        style.backgroundColor = UIColor.clear
        return UILabelComponent(props: titleProps, style: style)
    }()

    private lazy var conflictComponent: CalendarTagComponent<C> = {
        let props = CalendarTagComponentProps()
        props.tagString = BundleI18n.Calendar.Calendar_Bot_ConflictTip
        props.tagStyle = .red
        props.height = 20
        let style = ASComponentStyle()
        style.marginTop = 6.5
        return CalendarTagComponent(props: props, style: style)
    }()

    private lazy var updatedFlagComponent: CalendarTagComponent<C> = {
        let props = CalendarTagComponentProps()
        props.tagString = BundleI18n.Calendar.Calendar_Bot_UpdatedLabel
        props.textColor = UIColor.ud.Y600
        props.backgroundColor = UIColor.ud.Y100
        props.height = 20
        let style = ASComponentStyle()
        style.marginLeft = 8
        style.flexShrink = 0
        return CalendarTagComponent(props: props, style: style)
    }()

    private lazy var timeComponent: ASLayoutComponent<C> = {
        let style = ASComponentStyle()
        style.flexDirection = .column
        style.alignContent = .stretch
        style.alignItems = .flexStart
        style.flexShrink = 1
        style.marginTop = -2
        style.marginLeft = 8
        return ASLayoutComponent<C>(style: style, [
            titleLabel,
            conflictComponent
        ])
    }()

    override init(props: EventCardTimeComponentProps, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
        style.alignContent = .stretch
        style.flexDirection = .row
        style.marginTop = 16
        style.paddingLeft = 12.5
        style.paddingRight = 12.5
        setSubComponents([
            iconComponent,
            timeComponent,
            updatedFlagComponent
        ])
    }

    override func willReceiveProps(_ old: EventCardTimeComponentProps, _ new: EventCardTimeComponentProps) -> Bool {

        titleLabel.props.attributedText = NSAttributedString(string: new.timeString ?? "", attributes: [.foregroundColor: UIColor.ud.textTitle,
                                                                                                        .font: UIFont.ud.body2])
        if let tagText = new.conflictText {
            let props = conflictComponent.props
            props.tagString = tagText
            conflictComponent.props = props
            conflictComponent.style.display = .flex
        } else {
            conflictComponent.style.display = .none
        }
        
        if let showUpdatedFlag = new.showUpdatedFlag, showUpdatedFlag {
            updatedFlagComponent.style.display = .flex
        } else {
            updatedFlagComponent.style.display = .none
        }

        return true
    }
}
