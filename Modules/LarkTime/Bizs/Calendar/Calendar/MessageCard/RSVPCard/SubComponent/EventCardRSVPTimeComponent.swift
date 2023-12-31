//
//  EventCardRSVPTimeComponent.swift
//  Calendar
//
//  Created by pluto on 2023/2/9.
//

import UIKit
import UniverseDesignIcon
import Foundation
import CalendarFoundation
import AsyncComponent
import EEFlexiable
import RichLabel

final class EventCardRSVPTimeComponentProps: ASComponentProps {
    var conflictText: String?
    var timeString: String?
    var showUpdatedFlag: Bool = false
    var maxWidth: CGFloat?
}

final class EventCardRSVPTimeComponent<C: Context>: ASComponent<EventCardRSVPTimeComponentProps, EmptyState, UIView, C> {
    private let iconComponent: UIImageViewComponent<C> = {
        let props = UIImageViewComponentProps()
        props.setImage = { task in
            let image = UDIcon.getIconByKeyNoLimitSize(.timeOutlined).renderColor(with: .n3)
            task.set(image: image)
        }
        let style = ASComponentStyle()
        style.width = 16.auto()
        style.height = 16.auto()
        style.marginTop = 2
        style.flexShrink = 0
        return UIImageViewComponent(props: props, style: style)
    }()
    
    private lazy var timeComponent: RichLabelComponent<C> = {
        let titleProps = RichLabelProps()
        titleProps.font = UIFont.ud.body2
        titleProps.backgroundColor = UIColor.ud.bgBody
        titleProps.numberOfLines = 4
        titleProps.lineSpacing = 4
        titleProps.preferMaxLayoutWidth = 370
//        titleProps.outOfRangeText = NSAttributedString(string: "...", attributes: [.foregroundColor : UIColor.ud.textTitle, .font: UIFont.ud.body2])
        let style = ASComponentStyle()
        style.backgroundColor = UIColor.clear
        style.marginLeft = 8
        style.display = .none
        return RichLabelComponent(props: titleProps, style: style)
    }()
    
    override init(props: EventCardRSVPTimeComponentProps, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
        style.alignContent = .stretch
        style.flexDirection = .row
        style.marginTop = 8
        style.paddingLeft = 13
        style.paddingRight = 12
        setSubComponents([
            iconComponent,
            timeComponent
        ])
    }
    
    override func willReceiveProps(_ old: EventCardRSVPTimeComponentProps, _ new: EventCardRSVPTimeComponentProps) -> Bool {
        var contentWidth: CGFloat = 0
        if let width = new.maxWidth {
            // 卡片Width - padding - iconMargin - iconSize - offset
            contentWidth = width - 25 - 8 - 16 - 4
            timeComponent.props.preferMaxLayoutWidth = contentWidth
        }
        let font = UIFont.ud.body2(.fixed)
        let fontFigmaHeight = font.figmaHeight
        let baselineOffset = (fontFigmaHeight - font.lineHeight) / 2.0 / 2.0
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = fontFigmaHeight
        paragraphStyle.maximumLineHeight = fontFigmaHeight
        
        let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.ud.textTitle,
                                                         .font: font,
                                                         .baselineOffset: baselineOffset,
                                                         .paragraphStyle: paragraphStyle]
        var tagDataSource: [CalendarEventCardTag] = []
        
        if let str = new.conflictText, str.isEmpty != true {
            tagDataSource.append(CalendarEventCardTag(title: str, type: .conflict, size: CGSize(width: str.getWidth(font: UIFont.ud.caption0) + 9, height: 18), font: UIFont.ud.caption0))
        }
        
        if new.showUpdatedFlag {
            let updateStr = BundleI18n.Calendar.Calendar_Bot_UpdatedLabel
            tagDataSource.append(CalendarEventCardTag(title: updateStr, type: .update, size: CGSize(width: updateStr.getWidth(font: UIFont.ud.caption0) + 8, height: 18), font: UIFont.ud.caption0))
        }
        
        let timeAttrbuteStr = AsyncRichLabelUtil.getRichTextWithTrailingTags(titleStr: new.timeString ?? "",titleFont: font, titleAttributes: attributes, tagDataSource: tagDataSource, maxWidth: contentWidth, fistTagLeftMargin: 4, numberOfLines: 4)
        
        
        timeComponent.props.attributedText = timeAttrbuteStr
        timeComponent.style.display = .flex
        return true
    }
}
