//
//  EventCardRSVPDescComponent.swift
//  Calendar
//
//  Created by pluto on 2023/6/27.
//

import UIKit
import UniverseDesignIcon
import Foundation
import CalendarFoundation
import AsyncComponent
import EEFlexiable
import RichLabel

final class EventCardRSVPDescComponent<C: Context>: ASComponent<EventCardDescComponentProps, EmptyState, UIView, C> {
    private let iconComponent: UIImageViewComponent<C> = {
        let props = UIImageViewComponentProps()
        props.setImage = { $0.set(image: UDIcon.getIconByKeyNoLimitSize(.slideOutlined).renderColor(with: .n3)) }
        let style = ASComponentStyle()
        style.width = 16.auto()
        style.height = 16.auto()
        style.flexShrink = 0
        style.marginTop = 2
        return UIImageViewComponent(props: props, style: style)
    }()

    private lazy var titleLabel: RichLabelComponent<C> = {
        let titleProps = RichLabelProps()
        titleProps.font = UIFont.ud.body2
        titleProps.backgroundColor = UIColor.ud.bgBody
        titleProps.numberOfLines = 3
        titleProps.lineSpacing = 4
        titleProps.linkAttributes = [
            NSAttributedString.Key(rawValue: kCTForegroundColorAttributeName as String): UIColor.ud.primaryContentDefault.cgColor
        ]
        titleProps.activeLinkAttributes = [
            LKBackgroundColorAttributeName: UIColor(white: 0, alpha: 0.1)
        ]
        titleProps.outOfRangeText = NSAttributedString(string: "...", attributes: [.foregroundColor : UIColor.ud.textTitle, .font: UIFont.ud.body2])
        
        let style = ASComponentStyle()
        style.backgroundColor = UIColor.clear
        style.marginLeft = 8
        style.marginTop = 0
        style.marginRight = 0
        style.minHeight = 20
        return RichLabelComponent(props: titleProps, style: style)
    }()

    override init(props: EventCardDescComponentProps, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
        style.alignContent = .stretch
        style.alignItems = .flexStart
        style.flexDirection = .row
        style.marginTop = 8
        style.paddingLeft = 13
        style.paddingRight = 12
        setSubComponents([
            iconComponent,
            titleLabel
            ])
    }

    override func willReceiveProps(_ old: EventCardDescComponentProps, _ new: EventCardDescComponentProps) -> Bool {
        titleLabel.props.delegate = self
        titleLabel.props.preferMaxLayoutWidth = new.maxWidth - 35.5 - 14
        if let dict = props.tapableRangeDic {
            titleLabel.props.rangeLinkMap = dict
        }
        
        titleLabel.props.attributedText = new.text
        return true
    }
}

extension EventCardRSVPDescComponent: LKLabelDelegate {
    func attributedLabel(_ label: LKLabel, didSelectLink url: URL) {
        self.props.didSelectUrl?(url)
    }
}
