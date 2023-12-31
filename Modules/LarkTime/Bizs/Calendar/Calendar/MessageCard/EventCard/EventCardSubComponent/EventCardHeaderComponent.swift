//
//  EventCardHeaderComponent.swift
//  Calendar
//
//  Created by heng zhu on 2019/6/19.
//

import UIKit
import Foundation
import CalendarFoundation
import AsyncComponent
import EEFlexiable
import LarkTag
import UniverseDesignCardHeader
import UniverseDesignIcon
import RichLabel

final class EventCardHeaderProps: ASComponentProps {
    var summary: String?
    var inviteAttributeString: NSAttributedString?
    var inviterOnTapped: (() -> Void)?
    var inviterRange: NSRange?
    var isShowExternal: Bool = false
    var isShowOptional: Bool = false
    var isValid: Bool = true
    var target: Any?
    var inviteMessageSelector: Selector?
    var relationTag: String?
    var sendUserName: String = ""
    var messageType: Int?
    var maxWidth: CGFloat?
    var senderUserId: String?
    var isWebinar: Bool = false
}

final class CalendarCardHeaderComponentProps: ASComponentProps {
    var colorHue: UDCardHeaderHue?
}

final class CalendarCardHeaderComponent<C: Context>: ASComponent<CalendarCardHeaderComponentProps, EmptyState, UDCardHeader, C> {
    public override func update(view: UDCardHeader) {
        super.update(view: view)
        if let hue = props.colorHue {
            view.colorHue = hue
        }
    }

    override func create(_ rect: CGRect) -> UDCardHeader {
        return UDCardHeader(colorHue: .orange)
    }

    public override var isComplex: Bool {
        return true
    }
}

final class EventCardHeaderComponent<C: Context>: ASComponent<EventCardHeaderProps, EmptyState, UIView, C> {
    private let iconComponent: UIImageViewComponent<C> = {
        let props = UIImageViewComponentProps()
        props.setImage = { task in
            let image = UDIcon.getIconByKeyNoLimitSize(.calendarFilled).ud.withTintColor(UIColor.ud.udtokenMessageCardTextOrange)
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

    private lazy var summaryComponent: ASLayoutComponent<C> = {
        let style = ASComponentStyle()
        style.justifyContent = .flexStart
        style.flexDirection = .row
        style.alignItems = .flexStart
        return ASLayoutComponent<C>(style: style, [
            summaryLabel,
            externalTag,
            optionalTag
        ])
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
        props.textColor = UIColor.ud.udtokenMessageCardTextOrange
        props.numberOfLines = 0
        props.lineBreakMode = .byTruncatingTail
        props.textAlignment = .left
        props.numberOfLines = 2

        let style = ASComponentStyle()
        style.alignContent = .stretch
        style.alignItems = .stretch
        style.minHeight = 22
        style.width = 100%
        style.backgroundColor = .clear
        style.flexShrink = 1
        return UILabelComponent(props: props, style: style)
    }()

    private lazy var externalTag: CalendarTagComponent<C> = {
        let props = CalendarTagComponentProps()
        props.height = 20
        props.tagString = BundleI18n.Calendar.Calendar_Detail_External

        let style = ASComponentStyle()
        style.flexShrink = 0
        style.maxWidth = 78
        style.marginLeft = 5
        return CalendarTagComponent(props: props, style: style)
    }()

    private lazy var optionalTag: CalendarTagComponent<C> = {
        let props = CalendarTagComponentProps()
        props.height = 20
        props.tagString = BundleI18n.Calendar.Calendar_Detail_Optional
        let style = ASComponentStyle()
        style.marginLeft = 6
        style.flexShrink = 0
        return CalendarTagComponent(props: props, style: style)
    }()

    private lazy var subTitleLabel: RichLabelComponent<C> = {
        let titleProps = RichLabelProps()
        titleProps.numberOfLines = 2
        titleProps.lineSpacing = 4
        let style = ASComponentStyle()
        style.backgroundColor = UIColor.clear
        style.marginTop = 2
        return RichLabelComponent(props: titleProps, style: style)
    }()

    private lazy var labelsComponent: ASLayoutComponent<C> = {
        let style = ASComponentStyle()
        style.flexDirection = .column
        style.justifyContent = .flexStart
        style.alignContent = .stretch
        style.marginTop = 12
        style.marginBottom = 12
        style.marginRight = 12
        style.marginLeft = 8
        return ASLayoutComponent<C>(style: style, [
            summaryComponent,
            subTitleLabel
        ])
    }()

    private let orangeBackground: CalendarCardHeaderComponent<C> = {
        let style = ASComponentStyle()
        style.height = 100%
        style.width = 100%
        style.position = .absolute
        let props = CalendarCardHeaderComponentProps()
        props.colorHue = .orange

        return CalendarCardHeaderComponent<C>(props: props, style: style)
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

    override func willReceiveProps(_ old: EventCardHeaderProps, _ new: EventCardHeaderProps) -> Bool {
        setUpProps(props: new)
        return true
    }

    func setUpProps(props: EventCardHeaderProps) {
        summaryLabel.props.text = props.summary
        let elementColor = props.isValid ? UIColor.ud.udtokenMessageCardTextOrange : UIColor.ud.udtokenMessageCardTextNeutral

        summaryLabel.props.textColor = elementColor
        iconComponent.props.setImage = { task in
            let image = UDIcon.getIconByKeyNoLimitSize(.calendarFilled).ud.withTintColor(elementColor)
            task.set(image: image)
        }

        let tagTextColor = props.isValid ? UIColor.ud.O600 : UIColor.ud.udtokenMessageCardTextNeutral
        let tagBgColor = props.isValid ? UIColor.ud.udtokenTagBgOrange : UIColor.ud.staticBlack20
        optionalTag.props.textColor = tagTextColor
        optionalTag.props.backgroundColor = tagBgColor
        externalTag.props.textColor = tagTextColor
        externalTag.props.backgroundColor = tagBgColor
        subTitleLabel.props.delegate = self
        subTitleLabel.props.attributedText = self.layoutSubTitleLabel(props: props, fistTagLeftMargin: 4, numberOfLines: 2)
        subTitleLabel.props.outOfRangeText = subtitleAttrText(text: "\u{2026}", isValid: props.isValid)  // ...
        if let range = props.inviterRange {
            subTitleLabel.props.tapableRangeList = [range]
        }
        subTitleLabel.style.display = props.inviteAttributeString?.string.isEmpty ?? true ? .none : .flex
        optionalTag.style.display = props.isShowOptional ? .flex : .none
        externalTag.style.display = !props.relationTag.isEmpty ? .flex : .none
        externalTag.props.tagString = props.relationTag
        orangeBackground.style.display = props.isValid ? .flex : .none
        greyBackground.style.display = props.isValid ? .none : .flex
    }

    override init(props: EventCardHeaderProps, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)

        style.alignItems = .stretch
        style.flexDirection = .column
        style.width = 100%
        style.alignSelf = .stretch
        setSubComponents([
            orangeBackground,
            greyBackground,
            contentWapperComponent
        ])
    }

    private func subtitleAttrText(text: String, isValid: Bool) -> NSAttributedString {
        let titleColor = isValid ? UIColor.ud.udtokenMessageCardTextOrange : UIColor.ud.udtokenMessageCardTextNeutral
        let attribues: [NSAttributedString.Key: Any] = [.font: UIFont.ud.body2,
                                                        .foregroundColor: titleColor]
        return NSAttributedString(string: text, attributes: attribues)
    }
}

extension EventCardHeaderComponent: LKLabelDelegate {
    public func attributedLabel(_ label: LKLabel, didSelectText text: String, didSelectRange range: NSRange) -> Bool {
        self.props.inviterOnTapped?()
        return false
    }
}

extension EventCardHeaderComponent {
    
    /// 处理不同场景的尾随字符串
    func layoutSubTitleLabel(props: EventCardHeaderProps, fistTagLeftMargin: CGFloat, numberOfLines: Int) -> NSAttributedString? {
        
        guard let inviteAttributeString = props.inviteAttributeString, !inviteAttributeString.string.isEmpty else {
            return props.inviteAttributeString
        }
        
        // 卡片长度
        var contentWidth: CGFloat = 0
        if let width = props.maxWidth {
            // 卡片Width - padding - iconMargin - iconSize - offset
            contentWidth = width - 25 - 8 - 16 - 4
        }
        
        if contentWidth < 0 {
            return inviteAttributeString
        }
        
        let attributes = inviteAttributeString.attributes(at: 0, effectiveRange: nil)
        
        guard let font = attributes[.font] as? UIFont else {
            return inviteAttributeString
        }
        // 如果当前字符串不够长，直接返回
        if inviteAttributeString.string.getWidth(font: font) <= contentWidth * CGFloat(numberOfLines) {
            return inviteAttributeString
        }
        
        if let messageType = props.messageType {
            let hasSender = props.senderUserId?.isEmpty ?? false
            let senderUserName = hasSender ? props.sendUserName : ("@" + props.sendUserName)
            let cardType = CardType(rawValue: messageType ) ?? .unknown
            switch cardType {
            case .eventDelete:
                return AsyncRichLabelUtil.getSubtitleTrimText(senderUserActionTag: I18n.Lark_CalendarCard_NameDeletedEvent_Text(name: ""), senderUserName: senderUserName, attributes: attributes, font: font, contentWidth: contentWidth, fistTagLeftMargin: fistTagLeftMargin, numberOfLines: numberOfLines)
            case .replyAccept, .replyDecline, .replyTentative, .eventInvite:
                if props.isWebinar {
                    return AsyncRichLabelUtil.getSubtitleTrimText(senderUserActionTag: I18n.Calendar_G_NameInviteYouToWebinar(name: ""), senderUserName: senderUserName, attributes: attributes, font: font, contentWidth: contentWidth, fistTagLeftMargin: fistTagLeftMargin, numberOfLines: numberOfLines)
                } else {
                    return AsyncRichLabelUtil.getSubtitleTrimText(senderUserActionTag: I18n.Lark_CalendarCard_NameInviteJoinEvent_Text(name: ""), senderUserName: senderUserName, attributes: attributes, font: font, contentWidth: contentWidth, fistTagLeftMargin: fistTagLeftMargin, numberOfLines: numberOfLines)
                }
            case .eventReschedule, .eventUpdateLocation, .eventUpdateDescription:
                return AsyncRichLabelUtil.getSubtitleTrimText(senderUserActionTag: I18n.Lark_CalendarCard_NameUpdatedEvent_Text(name: ""), senderUserName: senderUserName, attributes: attributes, font: font, contentWidth: contentWidth, fistTagLeftMargin: fistTagLeftMargin, numberOfLines: numberOfLines)
            default:
                break
            }
        }
        return inviteAttributeString
    }
}
