//
//  EventCardSimpleCellComponent.swift
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
import UniverseDesignColor

final class EventCardSimpleCellComponentProps: ASComponentProps {
    var text: String?
    var showUpdatedFlag: Bool?
    var numberOfLines: Int?
    var marginTop: CGFloat?
    var onTap: (() -> Void)?
}

class EventCardSimpleCellComponent<C: Context>: ASComponent<EventCardSimpleCellComponentProps, EmptyState, UIView, C> {
    var iconComponent: UIImageViewComponent<C> = UIImageViewComponent(
        props: UIImageViewComponentProps(),
        style: ASComponentStyle()
    )

    let titleLabel: UILabelComponent<C> = {
        let titleProps = UILabelComponentProps()
        titleProps.numberOfLines = 4
        titleProps.font = UIFont.ud.body2
        let style = ASComponentStyle()
        style.flexShrink = 1
        style.marginLeft = 8
        style.backgroundColor = UIColor.clear
        return UILabelComponent(props: titleProps, style: style)
    }()

    let updatedFlagComponent: CalendarTagComponent<C> = {
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

    override init(props: EventCardSimpleCellComponentProps, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
        style.alignContent = .stretch
        style.alignItems = .flexStart
        style.flexDirection = .row
        style.marginTop = 16
        style.paddingLeft = 12.5
        style.paddingRight = 12.5
        setSubComponents([
            iconComponent,
            titleLabel
        ])
    }

    override func willReceiveProps(_ old: EventCardSimpleCellComponentProps, _ new: EventCardSimpleCellComponentProps) -> Bool {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6
        paragraphStyle.lineBreakMode = .byTruncatingTail
        let attributes = [NSAttributedString.Key.foregroundColor: UIColor.ud.textTitle,
                          NSAttributedString.Key.font: UIFont.body3,
                          NSAttributedString.Key.paragraphStyle: paragraphStyle]

        if let showUpdatedFlag = new.showUpdatedFlag, showUpdatedFlag {
            updatedFlagComponent.style.display = .flex
        } else {
            updatedFlagComponent.style.display = .none
        }

        guard let text = new.text else { return true }
        let attributedText = NSAttributedString(string: text, attributes: attributes)
        titleLabel.props.attributedText = attributedText
        
        if let lines = new.numberOfLines {
            titleLabel.props.numberOfLines = lines
        }
        
        if let marginTop = new.marginTop {
            style.marginTop = marginTop.css
        }
        return true
    }
}

final class EventCardLocationComponent<C: Context>: EventCardSimpleCellComponent<C> {
    override var iconComponent: UIImageViewComponent<C> {
        get {
            let props = UIImageViewComponentProps()
            props.setImage = { $0.set(image: UDIcon.getIconByKeyNoLimitSize(.localOutlined).renderColor(with: .n2)) }
            let style = ASComponentStyle()
            style.width = 16.auto()
            style.height = 16.auto()
            style.flexShrink = 0
            return UIImageViewComponent(props: props, style: style)
        }
        set {
            _ = newValue
            assertionFailureLog()
        }
    }

    override init(props: EventCardSimpleCellComponentProps, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
        setSubComponents([
            iconComponent,
            titleLabel,
            updatedFlagComponent
            ])
    }
}

final class EventCardRoomsComponent<C: Context>: EventCardSimpleCellComponent<C> {
    override var iconComponent: UIImageViewComponent<C> {
        get {
            let props = UIImageViewComponentProps()
            props.setImage = { $0.set(image: UDIcon.getIconByKeyNoLimitSize(.roomOutlined).renderColor(with: .n2)) }
            let style = ASComponentStyle()
            style.width = 16.auto()
            style.height = 16.auto()
            style.flexShrink = 0
            return UIImageViewComponent(props: props, style: style)
        }
        set {
            _ = newValue
            assertionFailureLog()
        }
    }

    override init(props: EventCardSimpleCellComponentProps, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
        setSubComponents([
            iconComponent,
            titleLabel,
            updatedFlagComponent
            ])
    }
}

final class EventCardRepeatComponent<C: Context>: EventCardSimpleCellComponent<C> {
    override var iconComponent: UIImageViewComponent<C> {
        get {
            let props = UIImageViewComponentProps()
            props.setImage = { task in
                let image = UDIcon.getIconByKeyNoLimitSize(.repeatOutlined).renderColor(with: .n2)
                task.set(image: image)
            }
            let style = ASComponentStyle()
            style.width = 16.auto()
            style.height = 16.auto()
            style.flexShrink = 0
            return UIImageViewComponent(props: props, style: style)
        }
        set {
            _ = newValue
            assertionFailureLog()
        }
    }

    override init(props: EventCardSimpleCellComponentProps, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
        setSubComponents([
            iconComponent,
            titleLabel,
            updatedFlagComponent
        ])
    }
}

final class EventCardMeetingNotesComponent<C: Context>: EventCardSimpleCellComponent<C> {
    override var iconComponent: UIImageViewComponent<C> {
        get {
            let props = UIImageViewComponentProps()
            props.setImage = { task in
                let color: DarkMode.IconColor = FG.rsvpStyleOpt ? .n3 : .n2
                let image = UDIcon.fileLinkWordOutlined.renderColor(with: color)
                task.set(image: image)
            }
            let style = ASComponentStyle()
            style.width = 16.auto()
            style.height = 16.auto()
            style.marginRight = 4
            style.flexShrink = 0
            return UIImageViewComponent(props: props, style: style)
        }
        set {
            _ = newValue
            assertionFailureLog()
        }
    }

    lazy var docIcon: UIImageViewComponent<C> = {
        let props = UIImageViewComponentProps()
        props.setImage = { task in
            let image = UDIcon.fileLinkWordOutlined.ud.withTintColor(UDColor.textLinkNormal)
            task.set(image: image)
        }
        let style = ASComponentStyle()
        style.width = 16.auto()
        style.height = 16.auto()
        style.flexShrink = 0
        style.marginLeft = 4
        return UIImageViewComponent(props: props, style: style)
    }()

    override init(props: EventCardSimpleCellComponentProps, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
        titleLabel.style.marginLeft = 4
        if FG.rsvpStyleOpt {
            style.marginTop = 8
            style.paddingLeft = 13
            style.paddingRight = 12
        }
        setSubComponents([
            iconComponent,
            docIcon,
            titleLabel
        ])
    }

    override func willReceiveProps(_ old: EventCardSimpleCellComponentProps, _ new: EventCardSimpleCellComponentProps) -> Bool {
        let labelProps: UILabelComponentProps = titleLabel.props
        labelProps.textColor = UDColor.textLinkNormal
        labelProps.onTap = new.onTap
        labelProps.text = new.text
        labelProps.numberOfLines = 1
        titleLabel.props = labelProps
        return true
    }
}
