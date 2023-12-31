//
//  SchedulerAppointmentHeaderComponent.swift
//  Calendar
//
//  Created by tuwenbo on 2023/3/30.
//

import Foundation
import AsyncComponent
import EEFlexiable
import UniverseDesignCardHeader
import RichLabel

final class SchedulerAppointmentHeaderComponent<C: Context>: ASComponent<SchedulerAppointmentHeaderComponent.Props, EmptyState, UIView, C> {

    final class Props: ASComponentProps {
        var isActive: Bool = true
        var title: String?
        var subtitle: String?
        var isExternal: Bool = false

        var subtitleClickableName: String?
        var clickableUserID: String?
        var subtitleNameOnClick: ((String?) -> Void)?

        var textColor: UIColor {
            isActive ? UIColor.ud.udtokenMessageCardTextOrange : UIColor.ud.udtokenMessageCardTextNeutral
        }

        var backgroundColor: UDCardHeaderHue {
            isActive ? .orange : .neural
        }
    }

    private lazy var titleLabel: UILabelComponent<C> = {
        let props = UILabelComponentProps()
        props.font = UIFont.ud.headline(.fixed)
        props.textColor = UIColor.ud.udtokenMessageCardTextOrange
        props.lineBreakMode = .byTruncatingTail
        props.textAlignment = .left
        props.numberOfLines = 4

        let style = ASComponentStyle()
        style.alignContent = .stretch
        style.alignItems = .stretch
        style.backgroundColor = .clear
        style.minHeight = 22
        style.width = 100%
        style.flexShrink = 1
        return UILabelComponent(props: props, style: style)
    }()

    private lazy var textTag: CalendarTagComponent<C> = {
        let props = CalendarTagComponentProps()
        props.height = 20
        props.tagString = BundleI18n.Calendar.Calendar_Detail_External
        let style = ASComponentStyle()
        style.flexShrink = 0
        style.maxWidth = 78
        return CalendarTagComponent(props: props, style: style)
    }()

    private lazy var titleLayout: ASLayoutComponent<C> = {
        let style = ASComponentStyle()
        style.justifyContent = .flexStart
        style.flexDirection = .row
        style.alignItems = .flexStart
        return ASLayoutComponent<C>(style: style, [titleLabel, textTag])
    }()

    private lazy var subTitleLabel: RichLabelComponent<C> = {
        let props = RichLabelProps()
        props.numberOfLines = 2
        props.lineSpacing = 4

        let style = ASComponentStyle()
        style.backgroundColor = UIColor.clear
        style.marginTop = 2
        return RichLabelComponent(props: props, style: style)
    }()

    private lazy var contentWapperComponent: ASLayoutComponent<C> = {
        let style = ASComponentStyle()
        style.justifyContent = .flexStart
        style.flexDirection = .column
        style.alignContent = .center
        style.alignItems = .stretch
        style.padding = 12
        return ASLayoutComponent<C>(style: style, [
            titleLayout,
            subTitleLabel
        ])
    }()

    private let backgroundComponent: CalendarCardHeaderComponent<C> = {
        let style = ASComponentStyle()
        style.height = 100%
        style.width = 100%
        style.position = .absolute
        let props = CalendarCardHeaderComponentProps()
        props.colorHue = .neural
        return CalendarCardHeaderComponent<C>(props: props, style: style)
    }()

    override init(props: Props, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
        style.alignItems = .stretch
        style.flexDirection = .column
        style.width = 100%
        style.alignSelf = .stretch
        setSubComponents([
            backgroundComponent,
            contentWapperComponent
        ])
    }

    override func willReceiveProps(_ old: Props, _ new: Props) -> Bool {
        backgroundComponent.props.colorHue = new.backgroundColor
        titleLabel.props.text = new.title
        titleLabel.props.textColor = new.textColor
        textTag.props.textColor = new.isActive ? UIColor.ud.O600 : UIColor.ud.udtokenMessageCardTextNeutral
        textTag.props.backgroundColor = new.isActive ? UIColor.ud.udtokenTagBgOrange : UIColor.ud.staticBlack20
        textTag.style.display = new.isExternal ? .flex : .none
        if let subtitle = new.subtitle, !subtitle.isEmpty {
            subTitleLabel.style.display = .flex
            subTitleLabel.props.delegate = self
            subTitleLabel.props.attributedText = subtitleAttrText(text: subtitle, color: new.textColor)
            subTitleLabel.props.outOfRangeText = subtitleAttrText(text: "\u{2026}", color: new.textColor)  // ...
            if let atName = new.subtitleClickableName, !atName.isEmpty {
                let range = NSString(string: subtitle).range(of: atName)
                subTitleLabel.props.tapableRangeList = [range]
            }
        } else {
            subTitleLabel.style.display = .none
        }
        return true
    }

    private func subtitleAttrText(text: String, color: UIColor) -> NSAttributedString {
        let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.ud.body2(.fixed),
                                                    .foregroundColor: color]
        return NSAttributedString(string: text, attributes: attrs)
    }
}

extension SchedulerAppointmentHeaderComponent: LKLabelDelegate {
    public func attributedLabel(_ label: LKLabel,
                                didSelectText text: String,
                                didSelectRange range: NSRange) -> Bool {
        self.props.subtitleNameOnClick?(self.props.clickableUserID)
        return false
    }
}
