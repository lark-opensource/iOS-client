//
//  EventCardOldRSVPTimeComponent.swift
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

final class EventCardOldRSVPTimeComponent<C: Context>: ASComponent<EventCardRSVPTimeComponentProps, EmptyState, UIView, C> {
    private let iconComponent: UIImageViewComponent<C> = {
        let props = UIImageViewComponentProps()
        props.setImage = { task in
            let image = UDIcon.getIconByKeyNoLimitSize(.timeOutlined).renderColor(with: .n2)
            task.set(image: image)
        }
        let style = ASComponentStyle()
        style.width = 16.auto()
        style.height = 16.auto()
        style.flexShrink = 0
        return UIImageViewComponent(props: props, style: style)
    }()
    
    private lazy var timeComponent: RichLabelComponent<C> = {
        let titleProps = RichLabelProps()
        titleProps.font = UIFont.ud.body2
        titleProps.backgroundColor = UIColor.ud.bgBody
        titleProps.numberOfLines = 3
        titleProps.lineSpacing = 4
        titleProps.preferMaxLayoutWidth = 370
        let style = ASComponentStyle()
        style.backgroundColor = UIColor.clear
        style.marginLeft = 8
        style.marginTop = -1
        style.display = .none
        return RichLabelComponent(props: titleProps, style: style)
    }()

    override init(props: EventCardRSVPTimeComponentProps, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
        style.alignContent = .stretch
        style.flexDirection = .row
        style.marginTop = 12
        style.paddingLeft = 12
        style.paddingRight = 12
        setSubComponents([
            iconComponent,
            timeComponent
        ])
    }

    override func willReceiveProps(_ old: EventCardRSVPTimeComponentProps, _ new: EventCardRSVPTimeComponentProps) -> Bool {
        var contentWidth: CGFloat = 0
        if let width = new.maxWidth {
            // 卡片Width - padding - iconMargin - iconSize
            contentWidth = width - 24 - 8 - 16
            timeComponent.props.preferMaxLayoutWidth = width - 24 - 8 - 16
        }
        
        timeComponent.props.attributedText = getRichTimeString(time: new.timeString, isUpdate: new.showUpdatedFlag, conflictStr: new.conflictText, width: contentWidth)
        timeComponent.style.display = .flex
        return true
    }
    
    func getRichTimeString(time: String?, isUpdate: Bool, conflictStr: String?, width: CGFloat) -> NSAttributedString {
        let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.ud.textTitle,
                                                         .font: UIFont.ud.body2]
        let fullTimeAttributeString: NSMutableAttributedString = NSMutableAttributedString(string: time ?? "", attributes: attributes)
        var conflictWidth: CGFloat = 0
        if let str = conflictStr, str.isEmpty != true {
            let marginLeft = getTagMargin(str: fullTimeAttributeString.string, tagString: str, width: width, conflictWidth: 0)
            conflictWidth = str.getWidth(font: UIFont.ud.caption0) + 9
            let conflictTagString = AsyncRichLabelUtil.transTagViewToNSMutableString(tagString: str,
                                                                                     tagType: .conflict,
                                                                                     size: CGSize(width: conflictWidth, height: 18),
                                                                                     margin: UIEdgeInsets(top: 0, left: marginLeft, bottom: 0, right: 0),
                                                                                     font: UIFont.ud.caption0)
           
            fullTimeAttributeString.append(conflictTagString)
        }

        if isUpdate {
            let str = BundleI18n.Calendar.Calendar_Bot_UpdatedLabel
            let marginLeft = getTagMargin(str: fullTimeAttributeString.string, tagString: str, width: width, conflictWidth: conflictWidth)
            let updateTagString = AsyncRichLabelUtil.transTagViewToNSMutableString(tagString: str,
                                                                                   tagType: .update,
                                                                                   size: CGSize(width: str.getWidth(font: UIFont.ud.caption0) + 8, height: 18),
                                                                                   margin: UIEdgeInsets(top: 0, left: marginLeft, bottom: 0, right: 0),
                                                                                   font: UIFont.ud.caption0)
            fullTimeAttributeString.append(updateTagString)
        }

        return fullTimeAttributeString
    }
    
    private func getTagMargin(str: String, tagString: String, width: CGFloat, conflictWidth: CGFloat) -> CGFloat {
        let strFont = UIFont.ud.body2
        let tagFont = UIFont.ud.caption0
        // 1: timeStr and tag String both exist in one line
        if str.getWidth(font: strFont) + conflictWidth + tagString.getWidth(font: tagFont) + 8 + 4 <= width { return 4 } else {
            // 2: timestring can not reach the full line width
            if str.getWidth(font: strFont) + conflictWidth <= width { return 0 } else {
                // no conflictWidth just4
                if conflictWidth == 0 { return 4 } else {
                    // has conflictWidth come to SecondLine calculate
                    if str.getWidth(font: strFont) + conflictWidth + tagString.getWidth(font: tagFont) + 8 + 4 <= 2*width { return 4 } else {
                        // not out for third line
                        if str.getWidth(font: strFont) + conflictWidth <= 2*width { return 0 } else {
                            // come to third line
                            return 4
                        }
                    }
                }
            }
        }
    }
}
