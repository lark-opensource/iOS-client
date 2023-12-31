//
//  EventCardOldRSVPRepeatComponent.swift
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

final class EventCardOldRSVPRepeatComponent<C: Context>: ASComponent<EventCardRSVPRepeatComponentProps, EmptyState, UIView, C> {
    private let iconComponent: UIImageViewComponent<C> = {
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
        style.marginLeft = 9
        style.marginTop = -1
        style.display = .none
        return RichLabelComponent(props: titleProps, style: style)
    }()
    
    override init(props: EventCardRSVPRepeatComponentProps, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
        style.alignContent = .stretch
        style.flexDirection = .row
        style.marginTop = 12
        style.paddingLeft = 12
        style.paddingRight = 12
        setSubComponents([
            iconComponent,
            rruleComponent
        ])
    }

    override func willReceiveProps(_ old: EventCardRSVPRepeatComponentProps, _ new: EventCardRSVPRepeatComponentProps) -> Bool {
        var contentWidth: CGFloat = 0
        if let width = new.maxWidth {
            // 卡片Width - padding - iconMargin - iconSize
            contentWidth = width
            rruleComponent.props.preferMaxLayoutWidth = width - 24 - 8 - 16
        }
        
        rruleComponent.props.attributedText = getRichTimeString(time: new.text, isUpdate: new.showUpdatedFlag, width: contentWidth)
        rruleComponent.style.display = .flex
        return true
    }
    
    func getRichTimeString(time: String?, isUpdate: Bool, width: CGFloat) -> NSAttributedString {

        let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.ud.textTitle,
                                                         .font: UIFont.ud.body2]
        let fullTimeAttributeString: NSMutableAttributedString = NSMutableAttributedString(string: time ?? "", attributes: attributes)

        if isUpdate {
            let str = BundleI18n.Calendar.Calendar_Bot_UpdatedLabel
            let marginLeft = getTagMargin(str: fullTimeAttributeString.string, tagString: str, width: width)
            let updateTagString = AsyncRichLabelUtil.transTagViewToNSMutableString(tagString: str,
                                                                                   tagType: .update,
                                                                                   size: CGSize(width: str.getWidth(font: UIFont.ud.caption0) + 8, height: 18),
                                                                                   margin: UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 0),
                                                                                   font: UIFont.systemFont(ofSize: 12))
            fullTimeAttributeString.append(updateTagString)
        }

        return fullTimeAttributeString
    }
    
    private func getTagMargin(str: String, tagString: String, width: CGFloat) -> CGFloat {
        let strFont = UIFont.ud.body2
        let tagFont = UIFont.ud.caption0
        // 1: timeStr and tag String both exist in one line
        if str.getWidth(font: strFont) + tagString.getWidth(font: tagFont) + 8 + 4 <= width { return 4 } else {
            // 2:
            if str.getWidth(font: strFont) <= width { return 0 } else {
                return 4
            }
        }
    }
}
