//
//  EventCardDescComponent.swift
//  Calendar
//
//  Created by heng zhu on 2019/6/25.
//

import UIKit
import UniverseDesignIcon
import Foundation
import CalendarFoundation
import AsyncComponent
import EEFlexiable
import RichLabel

final class EventCardDescComponentProps: ASComponentProps {
    var text: NSAttributedString?
    var tapableRangeDic: [NSRange: URL]?
    var didSelectUrl: ((URL) -> Void)?
    var maxWidth: CGFloat = 0
}

final class EventCardDescComponent<C: Context>: ASComponent<EventCardDescComponentProps, EmptyState, UIView, C> {
    private let iconComponent: UIImageViewComponent<C> = {
        let props = UIImageViewComponentProps()
        props.setImage = { $0.set(image: UDIcon.getIconByKeyNoLimitSize(.slideOutlined).renderColor(with: .n2)) }
        let style = ASComponentStyle()
        style.width = 16.auto()
        style.height = 16.auto()
        style.flexShrink = 0
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
        style.marginLeft = 9
        style.marginTop = -2
        style.marginRight = 12.5
        return RichLabelComponent(props: titleProps, style: style)
    }()

    override init(props: EventCardDescComponentProps, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
        style.alignContent = .stretch
        style.alignItems = .flexStart
        style.flexDirection = .row
        style.marginTop = 12
        style.marginLeft = 12.5
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

extension EventCardDescComponent: LKLabelDelegate {
    func attributedLabel(_ label: LKLabel, didSelectLink url: URL) {
        self.props.didSelectUrl?(url)
    }
}
