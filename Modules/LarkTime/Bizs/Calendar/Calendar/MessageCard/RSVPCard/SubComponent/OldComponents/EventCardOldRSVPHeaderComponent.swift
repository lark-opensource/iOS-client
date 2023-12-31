//
//  EventCardOldRSVPHeaderComponent.swift
//  Calendar
//
//  Created by pluto on 2023/1/31.
//


import UIKit
import Foundation
import CalendarFoundation
import AsyncComponent
import EEFlexiable
import LarkTag
import UniverseDesignCardHeader
import UniverseDesignIcon
import UniverseDesignColor
import RichLabel

final class EventCardOldRSVPHeaderComponent<C: Context>: ASComponent<EventCardRSVPHeaderComponentProps, EmptyState, UIView, C> {
    private let iconComponent: UIImageViewComponent<C> = {
        let props = UIImageViewComponentProps()
        props.setImage = { task in
            let image = UDIcon.getIconByKeyNoLimitSize(.calendarFilled).ud.withTintColor(UIColor.ud.udtokenMessageCardTextGreen)
            task.set(image: image)
        }
        let style = ASComponentStyle()
        style.width = 16.auto()
        style.height = 16.auto()
        style.marginTop = 14
        style.marginLeft = 12
        style.flexShrink = 0
        return UIImageViewComponent(props: props, style: style)
    }()

    private lazy var contentWapperComponent: ASLayoutComponent<C> = {
        let style = ASComponentStyle()
        style.justifyContent = .flexStart
        style.flexDirection = .row
        style.alignItems = .flexStart
        return ASLayoutComponent<C>(style: style, [
            iconComponent,
            labelsComponent
        ])
    }()

    private let summaryLabel: UILabelComponent<C> = {
        let props = UILabelComponentProps()
        props.font = UIFont.ud.headline
        props.textColor = UIColor.ud.udtokenMessageCardTextGreen
        props.lineBreakMode = .byTruncatingTail
        props.textAlignment = .left
        props.numberOfLines = 4

        let style = ASComponentStyle()
        style.alignContent = .center
        style.alignItems = .center
        style.minHeight = 22
        style.width = 100%
        style.backgroundColor = .clear
        style.flexShrink = 1
        return UILabelComponent(props: props, style: style)
    }()
    
    private var subTitleLabel: UILabelComponent<C> = {
        let titleProps = UILabelComponentProps()
        titleProps.numberOfLines = 2
        titleProps.text = I18n.Calendar_Bot_EventInfoUpdated
        titleProps.textColor = UIColor.ud.udtokenMessageCardTextGreen
        let style = ASComponentStyle()
        style.backgroundColor = UIColor.clear
        style.minHeight = 22
        style.marginTop = 4
        return UILabelComponent(props: titleProps, style: style)
    }()

    private lazy var externalTag: CalendarTagComponent<C> = {
        let props = CalendarTagComponentProps()
        props.height = 18
        props.tagString = BundleI18n.Calendar.Calendar_Detail_External

        let style = ASComponentStyle()
        style.flexShrink = 0
        style.marginTop = 2
        style.marginLeft = 4
        style.maxWidth = 78
        style.display = .none
        return CalendarTagComponent(props: props, style: style)
    }()

    private lazy var optionalTag: CalendarTagComponent<C> = {
        let props = CalendarTagComponentProps()
        props.height = 18
        props.tagString = BundleI18n.Calendar.Calendar_Detail_Optional
        let style = ASComponentStyle()
        style.marginLeft = 8
        style.marginTop = 2
        style.flexShrink = 0
        return CalendarTagComponent(props: props, style: style)
    }()

    private lazy var summaryComponent: ASLayoutComponent<C> = {
        let style = ASComponentStyle()
        style.justifyContent = .flexStart
        style.alignContent = .stretch
        style.flexDirection = .row
        style.alignItems = .flexStart
        return ASLayoutComponent<C>(style: style, [
            summaryLabel,
            optionalTag,
            externalTag
        ])
    }()
    
    private lazy var labelsComponent: ASLayoutComponent<C> = {
        let style = ASComponentStyle()
        style.flexDirection = .column
        style.justifyContent = .flexStart
        style.alignContent = .stretch
        style.marginTop = 11
        style.marginBottom = 9
        style.marginRight = 12
        style.marginLeft = 8
        return ASLayoutComponent<C>(style: style, [
            summaryComponent,
            subTitleLabel
        ])
    }()

    private let greyBackground: CalendarCardHeaderComponent<C> = {
        let style = ASComponentStyle()
        style.height = 100%
        style.width = 100%
        style.position = .absolute
        let props = CalendarCardHeaderComponentProps()
        props.colorHue = .neural
        return CalendarCardHeaderComponent<C>(props: props, style: style)
    }()
    
    private let greenBackground: CalendarCardHeaderComponent<C> = {
        let style = ASComponentStyle()
        style.height = 100%
        style.width = 100%
        style.position = .absolute
        style.display = .none
        let props = CalendarCardHeaderComponentProps()
        props.colorHue = .green
        return CalendarCardHeaderComponent<C>(props: props, style: style)
    }()
    
    private let tenativeStripBackground: CalendarHeaderBgComponent<C> = {
        let style = ASComponentStyle()
        style.height = 100%
        style.width = 100%
        style.position = .absolute
        style.display = .none
        return CalendarHeaderBgComponent<C>(props: CalendarHeaderBgComponentProps(), style: style)
    }()

    override func willReceiveProps(_ old: EventCardRSVPHeaderComponentProps, _ new: EventCardRSVPHeaderComponentProps) -> Bool {
        setUpProps(props: new)
        return true
    }

    func setUpProps(props: EventCardRSVPHeaderComponentProps) {
        
        let needChangeLayout = (props.isInValid || props.status == .decline) && props.cardStatus != .updated
        let elementColor =  needChangeLayout ? UIColor.ud.udtokenMessageCardTextNeutral : UIColor.ud.udtokenMessageCardTextGreen
        let tagTextColor = needChangeLayout ?  UIColor.ud.udtokenMessageCardTextNeutral : UIColor.ud.G600
        let tagBgColor = needChangeLayout ? UDColor.calendarRSVPCardTagBgColor : UIColor.ud.udtokenTagBgGreen
        
        iconComponent.props.setImage = { task in
            let image = UDIcon.getIconByKeyNoLimitSize(.calendarFilled).ud.withTintColor(elementColor)
            task.set(image: image)
        }
        
        summaryLabel.props.text = props.headerTitle
        summaryLabel.props.textColor = elementColor
        subTitleLabel.props.textColor = elementColor
        
        optionalTag.props.textColor = tagTextColor
        optionalTag.props.backgroundColor = tagBgColor
        externalTag.props.textColor = tagTextColor
        externalTag.props.backgroundColor = tagBgColor

        optionalTag.style.display = props.isShowOptional ? .flex : .none
        subTitleLabel.style.display = (props.cardStatus == .updated) ? .flex : .none
        if props.isShowExternal {
            externalTag.style.display = .flex
            externalTag.props.tagString = I18n.Calendar_Detail_External
        }

        greyBackground.style.display =  needChangeLayout ? .flex : .none
        tenativeStripBackground.style.display = (!props.isInValid && props.status == .tentative && props.cardStatus != .updated) ? .flex : .none
        greenBackground.style.display = (greyBackground.style.display == .flex || tenativeStripBackground.style.display == .flex) ? .none : .flex
    }

    override init(props: EventCardRSVPHeaderComponentProps, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)

        style.alignItems = .stretch
        style.flexDirection = .column
        style.width = 100%
        style.alignSelf = .stretch
        setSubComponents([
            greenBackground,
            tenativeStripBackground,
            greyBackground,
            contentWapperComponent
        ])
    }
}

