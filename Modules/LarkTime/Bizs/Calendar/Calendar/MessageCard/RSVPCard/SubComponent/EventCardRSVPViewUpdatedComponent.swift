//
//  EventCardRSVPViewUpdatedComponent.swift
//  Calendar
//
//  Created by pluto on 2023/5/31.
//

import UniverseDesignIcon
import Foundation
import AsyncComponent
import EEFlexiable
import UIKit

final class EventCardRSVPViewUpdatedComponent<C: Context>: ASComponent<EventCardClickToViewUpdateComponentProps, EmptyState, UIView, C> {
    
    private let divideTopLineComponent: UIViewComponent<C> = {
        let style = ASComponentStyle()
        style.width = 100%
        style.height = 0.5
        style.marginTop = 12
        style.backgroundColor = UIColor.ud.lineDividerDefault
        
        return UIViewComponent<C>(props: ASComponentProps(), style: style)
    }()

    private let hintLabel: UILabelComponent<C> = {
        let pros = UILabelComponentProps()
        pros.font = UIFont.ud.body2
        pros.textColor = UIColor.ud.textLinkNormal
        pros.textAlignment = .center
        pros.numberOfLines = 1
        pros.text = I18n.Calendar_Bot_ViewUpdatedEventDetails_New

        let style = ASComponentStyle()
        style.height = 22
        style.paddingLeft = 10
        style.backgroundColor = .clear

        return UILabelComponent(props: pros, style: style)
    }()

    private let hintIcon: UIImageViewComponent<C> = {
        let props = UIImageViewComponentProps()
        props.setImage = { $0.set(image: UDIcon.getIconByKeyNoLimitSize(.disorderListOutlined).ud.withTintColor(UIColor.ud.primaryPri600)) }
        let style = ASComponentStyle()
        style.width = 16.auto()
        style.height = 16.auto()
        style.marginTop = 3
        return UIImageViewComponent(props: props, style: style)
    }()
    
    private lazy var updateActionPanel: ASLayoutComponent = {
        let style = ASComponentStyle()
        style.flexDirection = .row
        style.flexGrow = 0
        style.flexShrink = 0
        style.marginTop = 13
        return ASLayoutComponent(style: style, [hintIcon, hintLabel])
    }()

    override init(props: EventCardClickToViewUpdateComponentProps, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
        style.alignContent = .stretch
        style.justifyContent = .flexEnd
        style.flexDirection = .column
        style.paddingLeft = 14
        style.paddingRight = 12
        style.width = 100%
        
        let warpperStyle = ASComponentStyle()
        warpperStyle.flexDirection = .column
        warpperStyle.width = 100%

        let warpperComponent = ASLayoutComponent(style: warpperStyle, [updateActionPanel])
        
        setSubComponents([divideTopLineComponent,
                          warpperComponent])
    }
    
    override func willReceiveProps(_ old: EventCardClickToViewUpdateComponentProps, _ new: EventCardClickToViewUpdateComponentProps) -> Bool {
        hintLabel.props.text = new.hintText
        return true
    }

}
