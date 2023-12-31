//
//  EventCardAttendeesComponent.swift
//  Calendar
//
//  Created by heng zhu on 2019/6/23.
//

import UIKit
import UniverseDesignIcon
import Foundation
import CalendarFoundation
import AsyncComponent
import EEFlexiable
import RichLabel

final class EventCardAttendeesComponentProps: ASComponentProps {
    var text: NSAttributedString?
    var tapableRangeDic: [NSRange: String] = [:]
    var outOfRangeText: NSAttributedString?
    var didSelectChat: ((String) -> Void)?
    var maxWidth: CGFloat = 0
    var isWebinar: Bool = false
}

final class EventCardAttendeesComponent<C: Context>: ASComponent<EventCardAttendeesComponentProps, EmptyState, UIView, C> {
    private let iconComponent: UIImageViewComponent<C> = {
        let props = UIImageViewComponentProps()
        props.setImage = { task in
            let image = UDIcon.getIconByKeyNoLimitSize(.groupOutlined).renderColor(with: .n2)
            task.set(image: image)
        }
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
        titleProps.numberOfLines = 2
        titleProps.lineSpacing = 4
        let style = ASComponentStyle()
        style.backgroundColor = UIColor.clear
        style.marginLeft = 9
        style.marginTop = -2
        style.marginRight = 12.5
        return RichLabelComponent(props: titleProps, style: style)
    }()

    override init(props: EventCardAttendeesComponentProps, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
        style.alignContent = .stretch
        style.alignItems = .flexStart
        style.flexDirection = .row
        style.marginTop = 14
        style.marginLeft = 12.5
        setSubComponents([
            iconComponent,
            titleLabel
            ])
    }

    override func willReceiveProps(_ old: EventCardAttendeesComponentProps, _ new: EventCardAttendeesComponentProps) -> Bool {
        titleLabel.props.delegate = self
        titleLabel.props.attributedText = new.text
        titleLabel.props.preferMaxLayoutWidth = new.maxWidth - 12.5 - 12.5 - 16.auto() - 9
        let tapableRangeList = Array(new.tapableRangeDic.keys)
        if !tapableRangeList.isEmpty {
            titleLabel.props.tapableRangeList = tapableRangeList
        }

        titleLabel.props.outOfRangeText = new.outOfRangeText

        if new.isWebinar {
            iconComponent.props.setImage = { task in
                let image = UDIcon.getIconByKeyNoLimitSize(.webinarOutlined).renderColor(with: .n2)
                task.set(image: image)
            }
        }
        return true
    }
}

extension EventCardAttendeesComponent: LKLabelDelegate {
    public func attributedLabel(_ label: LKLabel, didSelectText text: String, didSelectRange range: NSRange) -> Bool {

        if let chatId = props.tapableRangeDic[range] {
            self.props.didSelectChat?(chatId)
            return false
        }
        return true
    }
}
