//
//  EventCardRSVPRepeatComponent.swift
//  Calendar
//
//  Created by pluto on 2023/2/15.
//

import UIKit
import UniverseDesignIcon
import Foundation
import CalendarFoundation
import AsyncComponent
import EEFlexiable
import RichLabel

final class EventCardRSVPRepeatComponentProps: ASComponentProps {
    var text: String?
    var showUpdatedFlag: Bool = false
    var maxWidth: CGFloat?
}

final class EventCardRSVPRepeatComponent<C: Context>: ASComponent<EventCardRSVPRepeatComponentProps, EmptyState, UIView, C> {
    private let iconComponent: UIImageViewComponent<C> = {
        let props = UIImageViewComponentProps()
        props.setImage = { task in
            let image = UDIcon.getIconByKeyNoLimitSize(.repeatOutlined).renderColor(with: .n3)
            task.set(image: image)
        }
        let style = ASComponentStyle()
        style.width = 16.auto()
        style.height = 16.auto()
        style.marginTop = 2
        style.flexShrink = 0
        return UIImageViewComponent(props: props, style: style)
    }()
    
    private lazy var rruleComponent: RichLabelComponent<C> = {
        let titleProps = RichLabelProps()
        titleProps.font = UIFont.ud.body2
        titleProps.backgroundColor = UIColor.ud.bgBody
        titleProps.numberOfLines = 3
        titleProps.lineSpacing = 4
        let style = ASComponentStyle()
        style.backgroundColor = UIColor.clear
        style.alignContent = .stretch
        style.marginLeft = 8
        //        style.minHeight = 22
        style.display = .none
        return RichLabelComponent(props: titleProps, style: style)
    }()
    
    override init(props: EventCardRSVPRepeatComponentProps, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
        style.alignContent = .stretch
        style.flexDirection = .row
        style.marginTop = 8
        style.paddingLeft = 13
        style.paddingRight = 12
        setSubComponents([
            iconComponent,
            rruleComponent
        ])
    }
    
    override func willReceiveProps(_ old: EventCardRSVPRepeatComponentProps, _ new: EventCardRSVPRepeatComponentProps) -> Bool {
        var contentWidth: CGFloat = 0
        if let width = new.maxWidth {
            // 卡片Width - padding - iconMargin - iconSize - offset
            contentWidth = width - 25 - 15 - 16 - 4
            rruleComponent.props.preferMaxLayoutWidth = contentWidth
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
        
        let timeAttrbuteStr = AsyncRichLabelUtil.getRichTextWithTrailingTags(titleStr: new.text ?? "",titleFont: font, titleAttributes: attributes, tagDataSource: tagDataSource, maxWidth: contentWidth, fistTagLeftMargin: 4, numberOfLines: 3)
        
        
        rruleComponent.props.attributedText = timeAttrbuteStr
        rruleComponent.style.display = .flex
        return true
    }
    
}
