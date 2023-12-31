//
//  EventCardRSVPAttendeesComponent.swift
//  Calendar
//
//  Created by pluto on 2023/2/2.
//

import UIKit
import UniverseDesignIcon
import Foundation
import CalendarFoundation
import AsyncComponent
import EEFlexiable
import RichLabel

final class EventCardRSVPAttendeesComponentProps: ASComponentProps {
    var text: NSAttributedString?
    var tapableRangeDic: [NSRange: String] = [:]
    var outOfRangeText: NSAttributedString?
    var didSelectChat: ((String) -> Void)?
    var maxWidth: CGFloat = 0
    var isAllUserInGroupReplyed: Bool = false
    var rsvpAllReplyedCountString: String?
    var eventTotalAttendeeCount: Int64 = 0
    var isAttendeeOverflow: Bool = false
}

final class EventCardRSVPAttendeesComponent<C: Context>: ASComponent<EventCardRSVPAttendeesComponentProps, EmptyState, UIView, C> {
    
    private let attendeeTopLineComponent: UIViewComponent<C> = {
        let style = ASComponentStyle()
        style.width = 100%
        style.height = 1
        style.backgroundColor = UIColor.ud.lineDividerDefault
        style.display = .flex
        return UIViewComponent<C>(props: ASComponentProps(), style: style)
    }()
    
    private let infoLabel: UILabelComponent<C> = {
        let titleProps = UILabelComponentProps()
        titleProps.font = UIFont.ud.body2
        titleProps.textColor = UIColor.ud.textTitle
        titleProps.numberOfLines = 0
        titleProps.attributedText = NSAttributedString(string: I18n.Calendar_Detail_AwaitingResponse,
                                                       attributes: [.foregroundColor: UIColor.ud.textTitle,
                                                                    .font: UIFont.ud.body2])
        let style = ASComponentStyle()
        style.width = 100%
        style.backgroundColor = UIColor.clear
        style.marginTop = 12        
        return UILabelComponent(props: titleProps, style: style)
    }()
    
    private let rsvpCountDetailLabel: UILabelComponent<C> = {
        let titleProps = UILabelComponentProps()
        titleProps.font = UIFont.ud.body2
        titleProps.textColor = UIColor.ud.textPlaceholder
        titleProps.numberOfLines = 0

        let style = ASComponentStyle()
        style.width = 100%
        style.backgroundColor = UIColor.clear
        style.marginTop = 4
        style.display = .none
        return UILabelComponent(props: titleProps, style: style)
    }()

    private lazy var titleLabel: RichLabelComponent<C> = {
        let titleProps = RichLabelProps()
        titleProps.font = UIFont.ud.body2
        titleProps.backgroundColor = UIColor.ud.bgBody
        titleProps.numberOfLines = 2
        titleProps.lineSpacing = 4
        let style = ASComponentStyle()
        style.backgroundColor = UIColor.clear
        style.marginTop = 4
        return RichLabelComponent(props: titleProps, style: style)
    }()

    override init(props: EventCardRSVPAttendeesComponentProps, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
        style.alignContent = .stretch
        style.alignItems = .flexStart
        style.flexDirection = .column
        style.marginTop = 12
        style.marginLeft = 12
        style.marginRight = 12
        setSubComponents([
            attendeeTopLineComponent,
            infoLabel,
            rsvpCountDetailLabel,
            titleLabel
            ])
    }

    override func willReceiveProps(_ old: EventCardRSVPAttendeesComponentProps, _ new: EventCardRSVPAttendeesComponentProps) -> Bool {
        titleLabel.props.delegate = self
        titleLabel.props.attributedText = new.text
        titleLabel.props.preferMaxLayoutWidth = new.maxWidth - 35.5 - 14
        let tapableRangeList = Array(new.tapableRangeDic.keys)
        if !tapableRangeList.isEmpty {
            titleLabel.props.tapableRangeList = tapableRangeList
        }

        titleLabel.props.outOfRangeText = new.outOfRangeText
        titleLabel.style.display = .flex
        /// 群内参与者全部回复
        let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.ud.textTitle,
                                     .font: UIFont.ud.body2]
        if new.isAllUserInGroupReplyed {

            infoLabel.props.attributedText = NSAttributedString(string: I18n.Calendar_Plural_FullDetailStringOfGuests(number: new.eventTotalAttendeeCount),
                                                                attributes: attributes)
            rsvpCountDetailLabel.props.attributedText = NSAttributedString(string: new.rsvpAllReplyedCountString ?? "",
                                                                           attributes: [.foregroundColor: UIColor.ud.textPlaceholder,
                                                                                        .font: UIFont.ud.body2])
            rsvpCountDetailLabel.style.display = .flex
            titleLabel.style.display = .none
        } else {
            infoLabel.props.attributedText = NSAttributedString(string: I18n.Calendar_Detail_AwaitingResponse,
                                                                attributes: attributes)
            rsvpCountDetailLabel.style.display = .none
            titleLabel.style.display = .flex
        }
        
        // attendee overflow
        if new.isAttendeeOverflow {
            infoLabel.style.display = .none
            titleLabel.style.display = .none
            rsvpCountDetailLabel.style.display = .none
        }
        
        return true
    }
}

extension EventCardRSVPAttendeesComponent: LKLabelDelegate {
    public func attributedLabel(_ label: LKLabel, didSelectText text: String, didSelectRange range: NSRange) -> Bool {
        if let chatId = props.tapableRangeDic[range] {
            self.props.didSelectChat?(chatId)
            return false
        }
        return true
    }
}
