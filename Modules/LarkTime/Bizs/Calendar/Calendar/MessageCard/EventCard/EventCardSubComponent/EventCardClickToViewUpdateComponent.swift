//
//  EventCardClickToViewUpdateComponent.swift
//  CalendarInChat
//
//  Created by 王仕杰 on 2021/2/1.
//

import UniverseDesignIcon
import Foundation
import AsyncComponent
import EEFlexiable
import UIKit

final class EventCardClickToViewUpdateComponentProps: ASComponentProps {
    var hintText: String?
}

final class EventCardClickToViewUpdateComponent<C: Context>: ASComponent<EventCardClickToViewUpdateComponentProps, EmptyState, UIView, C> {

    private let hintLabel: UILabelComponent<C> = {
        let pros = UILabelComponentProps()
        pros.font = UIFont.ud.body2
        pros.textColor = UIColor.ud.primaryContentPressed
        pros.textAlignment = .center
        pros.numberOfLines = 1
        pros.text = I18n.Calendar_Bot_ViewUpdatedEventDetails_New

        let style = ASComponentStyle()
        style.height = 16
        style.paddingLeft = 10
        style.backgroundColor = .clear

        return UILabelComponent(props: pros, style: style)
    }()

    private let hintIcon: UIImageViewComponent<C> = {
        let props = UIImageViewComponentProps()
        props.setImage = { $0.set(image: UDIcon.getIconByKeyNoLimitSize(.disorderListOutlined).ud.withTintColor(UIColor.ud.primaryContentPressed)) }
        let style = ASComponentStyle()
        style.width = 16.auto()
        style.height = 16.auto()
        style.flexShrink = 0
        return UIImageViewComponent(props: props, style: style)
    }()

    override init(props: EventCardClickToViewUpdateComponentProps, style: ASComponentStyle, context: C? = nil) {
        style.justifyContent = .flexStart
        style.alignItems = .flexEnd
        style.flexDirection = .row
        style.paddingLeft = 12
        style.marginBottom = -2
        style.width = 100%
        style.height = 30
        style.alignSelf = .flexEnd

        super.init(props: props, style: style, context: context)

        setSubComponents([hintIcon, hintLabel])
    }
    
    override func willReceiveProps(_ old: EventCardClickToViewUpdateComponentProps, _ new: EventCardClickToViewUpdateComponentProps) -> Bool {
        hintLabel.props.text = new.hintText
        return true
    }

}
