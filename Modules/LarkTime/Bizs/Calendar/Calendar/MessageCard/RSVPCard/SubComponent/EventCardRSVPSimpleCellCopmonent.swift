//
//  EventCardRSVPSimpleCellCopmonent.swift
//  Calendar
//
//  Created by pluto on 2023/5/31.
//

import UIKit
import UniverseDesignIcon
import Foundation
import CalendarFoundation
import AsyncComponent
import EEFlexiable

final class EventCardRSVPSimpleCellCopmonentProps: ASComponentProps {
    var text: String?
    var showUpdatedFlag: Bool = false
    var maxWidth: CGFloat?
    var numberOfLines: Int = 0
}

class EventCardRSVPSimpleCellCopmonent<C: Context>: ASComponent<EventCardRSVPSimpleCellCopmonentProps, EmptyState, UIView, C> {
    var iconComponent: UIImageViewComponent<C> = UIImageViewComponent(
        props: UIImageViewComponentProps(),
        style: ASComponentStyle()
    )

    lazy var titleComponent: RichLabelComponent<C> = {
        let titleProps = RichLabelProps()
        titleProps.backgroundColor = UIColor.ud.bgBody
        titleProps.numberOfLines = 2
        titleProps.lineSpacing = 4
        titleProps.outOfRangeText = NSAttributedString(string: "...", attributes: [.foregroundColor : UIColor.ud.textTitle, .font: UIFont.ud.body2])
        let style = ASComponentStyle()
        style.backgroundColor = UIColor.clear
        style.alignContent = .stretch
        style.marginLeft = 8
        style.display = .none
        return RichLabelComponent(props: titleProps, style: style)
    }()

    override init(props: EventCardRSVPSimpleCellCopmonentProps, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
        style.alignContent = .stretch
        style.flexDirection = .row
        style.marginTop = 8
        style.paddingLeft = 13
        style.paddingRight = 12
        setSubComponents([
            iconComponent,
            titleComponent
        ])
    }

    override func willReceiveProps(_ old: EventCardRSVPSimpleCellCopmonentProps, _ new: EventCardRSVPSimpleCellCopmonentProps) -> Bool {
        titleComponent.props.numberOfLines = new.numberOfLines
        
        var contentWidth: CGFloat = 0
        if let width = new.maxWidth {
            // 卡片Width - padding - iconMargin - iconSize - offset
            contentWidth = width - 24 - 15 - 16 - 4
            titleComponent.props.preferMaxLayoutWidth = contentWidth
        }
        
        let font = UIFont.ud.body2(.fixed)
        let fontFigmaHeight = font.figmaHeight
        let baselineOffset = (fontFigmaHeight - font.lineHeight) / 2.0 / 2.0
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = fontFigmaHeight
        paragraphStyle.maximumLineHeight = fontFigmaHeight
        
        let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.ud.textTitle,
                                                         .font: UIFont.ud.body2,
                                                         .baselineOffset: baselineOffset,
                                                         .paragraphStyle: paragraphStyle]
        var tagDataSource: [CalendarEventCardTag] = []
        
        if new.showUpdatedFlag {
            let updateStr = BundleI18n.Calendar.Calendar_Bot_UpdatedLabel
            tagDataSource.append(CalendarEventCardTag(title: updateStr, type: .update, size: CGSize(width: updateStr.getWidth(font: UIFont.ud.caption0) + 8, height: 18), font: UIFont.ud.caption0))
        }
        
        let trimedAttrbuteStr = AsyncRichLabelUtil.getRichTextWithTrailingTags(titleStr: new.text ?? "",titleFont: font, titleAttributes: attributes, tagDataSource: tagDataSource, maxWidth: contentWidth, fistTagLeftMargin: 4, numberOfLines: 2, topMargin: -4)
    
        titleComponent.props.attributedText = trimedAttrbuteStr
        titleComponent.style.display = .flex
        return true
    }
}

final class EventCardRSVPLocationComponent<C: Context>: EventCardRSVPSimpleCellCopmonent<C> {
    override var iconComponent: UIImageViewComponent<C> {
        get {
            let props = UIImageViewComponentProps()
            props.setImage = { $0.set(image: UDIcon.getIconByKeyNoLimitSize(.localOutlined).renderColor(with: .n3)) }
            let style = ASComponentStyle()
            style.width = 16.auto()
            style.height = 16.auto()
            style.flexShrink = 0
            style.marginTop = 2
            return UIImageViewComponent(props: props, style: style)
        }
        set {
            _ = newValue
            assertionFailureLog()
        }
    }

    override init(props: EventCardRSVPSimpleCellCopmonentProps, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
        setSubComponents([
            iconComponent,
            titleComponent
            ])
    }
}

final class EventCardRSVPRoomsComponent<C: Context>: EventCardRSVPSimpleCellCopmonent<C> {
    override var iconComponent: UIImageViewComponent<C> {
        get {
            let props = UIImageViewComponentProps()
            props.setImage = { $0.set(image: UDIcon.getIconByKeyNoLimitSize(.roomOutlined).renderColor(with: .n3)) }
            let style = ASComponentStyle()
            style.width = 16.auto()
            style.height = 16.auto()
            style.flexShrink = 0
            style.marginTop = 2
            return UIImageViewComponent(props: props, style: style)
        }
        set {
            _ = newValue
            assertionFailureLog()
        }
    }

    override init(props: EventCardRSVPSimpleCellCopmonentProps, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
        setSubComponents([
            iconComponent,
            titleComponent
            ])
    }
}
