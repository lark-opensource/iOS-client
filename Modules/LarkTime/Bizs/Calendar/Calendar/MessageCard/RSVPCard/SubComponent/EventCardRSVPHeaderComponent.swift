//
//  EventCardRSVPHeaderComponent.swift
//  Calendar
//
//  Created by pluto on 2023/1/31.
//


import UIKit
import Foundation
import CalendarFoundation
import AsyncComponent
import EEFlexiable
import LarkTag
import UniverseDesignCardHeader
import UniverseDesignIcon
import UniverseDesignColor
import RichLabel
import LarkModel

final class EventCardRSVPHeaderComponentProps: ASComponentProps {
    var cardStatus: EventRSVPCardInfo.EventRSVPCardStatus = .normal
    var headerTitle: String?
    var isShowExternal: Bool = false
    var isShowOptional: Bool = false
    var isInValid: Bool = false
    var relationTag: String?
    var status: CalendarEventAttendee.Status = .needsAction
    var maxWidth: CGFloat?
}

final class EventCardRSVPHeaderComponent<C: Context>: ASComponent<EventCardRSVPHeaderComponentProps, EmptyState, UIView, C> {
    private let iconDisableComponent: UIImageViewComponent<C> = {
        let props = UIImageViewComponentProps()
        props.setImage = { task in
            let image = UDIcon.getIconByKey(.calendarDisableColorful, size: CGSize(width: 18, height: 18))
            task.set(image: image)
        }
        let style = ASComponentStyle()
        style.width = 18
        style.height = 18
        style.flexShrink = 0
        style.display = .none
        return UIImageViewComponent(props: props, style: style)
    }()
    
    private let iconComponent: UIImageViewComponent<C> = {
        let props = UIImageViewComponentProps()
        props.setImage = { task in
            let image = UDIcon.getIconByKey(.calendarColorful, size: CGSize(width: 18, height: 18))
            task.set(image: image)
        }
        let style = ASComponentStyle()
        style.width = 18.auto()
        style.height = 18.auto()
        style.position = .absolute
        style.flexShrink = 0
        return UIImageViewComponent(props: props, style: style)
    }()
    
    private lazy var iconWapperComponent: ASLayoutComponent<C> = {
        let style = ASComponentStyle()
        style.marginTop = 2
        style.width = 16
        style.height = 16
        style.flexShrink = 0
        return ASLayoutComponent<C>(style: style, [
            iconDisableComponent,
            iconComponent
        ])
    }()

    private let summaryLabel: RichLabelComponent<C> = {
        let props = RichLabelProps()
        props.numberOfLines = 6
        props.lineSpacing = 4
        let style = ASComponentStyle()
        style.backgroundColor = UIColor.clear
        return RichLabelComponent(props: props, style: style)
    }()
    
    private var subTitleLabel: UILabelComponent<C> = {
        let titleProps = UILabelComponentProps()
        titleProps.numberOfLines = 2
        titleProps.text = I18n.Calendar_Bot_EventInfoUpdated
        let style = ASComponentStyle()
        style.backgroundColor = UIColor.clear
        style.marginTop = 4
        return UILabelComponent(props: titleProps, style: style)
    }()
    
    private lazy var labelsComponent: ASLayoutComponent<C> = {
        let style = ASComponentStyle()
        style.flexDirection = .column
        style.justifyContent = .flexStart
        style.alignContent = .stretch
        style.marginLeft = 8
        return ASLayoutComponent<C>(style: style, [
            summaryLabel,
            subTitleLabel
        ])
    }()
    
    override init(props: EventCardRSVPHeaderComponentProps, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
        style.alignContent = .stretch
        style.flexDirection = .row
        style.marginTop = 12
        style.paddingLeft = 12
        style.paddingRight = 12
        setSubComponents([
            iconWapperComponent,
            labelsComponent
        ])
    }
    
    override func willReceiveProps(_ old: EventCardRSVPHeaderComponentProps, _ new: EventCardRSVPHeaderComponentProps) -> Bool {
        setUpProps(props: new)
        return true
    }

    func setUpProps(props: EventCardRSVPHeaderComponentProps) {
        let needDisable: Bool = (props.isInValid || props.status == .decline) && props.cardStatus != .updated
        
        var contentWidth: CGFloat = 0
        if let width = props.maxWidth {
            // 卡片Width - padding - iconMargin - iconSize - offset
            contentWidth = width - 25 - 8 - 16 - 4
            summaryLabel.props.preferMaxLayoutWidth = contentWidth
        }
        
        iconComponent.style.display = needDisable ? .none : .flex
        iconDisableComponent.style.display = needDisable ? .flex : .none
        subTitleLabel.props.textColor = needDisable ? UIColor.ud.textPlaceholder : UIColor.ud.textCaption
        subTitleLabel.style.display = (props.cardStatus == .updated) ? .flex : .none
        
        let font = UIFont.ud.headline(.fixed)
        let fontFigmaHeight = font.figmaHeight
        let baselineOffset = (fontFigmaHeight - font.lineHeight) / 2.0 / 2.0
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = fontFigmaHeight
        paragraphStyle.maximumLineHeight = fontFigmaHeight
        
        let disableAttributes: [NSAttributedString.Key : Any] = [.font: UIFont.ud.headline,
                                                                 .foregroundColor: UIColor.ud.textPlaceholder,
                                                                 .baselineOffset: baselineOffset,
                                                                 .paragraphStyle: paragraphStyle]
        
        let enableAttributes: [NSAttributedString.Key : Any] = [.font: UIFont.ud.headline,
                                                                 .foregroundColor: UIColor.ud.textTitle,
                                                                 .baselineOffset: baselineOffset,
                                                                 .paragraphStyle: paragraphStyle]

        var tagDataSource: [CalendarEventCardTag] = []
        
        if props.isShowOptional && !props.isInValid {
            let optionalStr = I18n.Calendar_Detail_Optional
            tagDataSource.append(CalendarEventCardTag(title: optionalStr, type: .optional, size: CGSize(width: optionalStr.getWidth(font: UIFont.ud.caption0) + 8, height: 18), font: UIFont.ud.caption0))
        }
        
        if props.isShowExternal {
            let externalStr = I18n.Calendar_Detail_External
            tagDataSource.append(CalendarEventCardTag(title: externalStr, type: .externel, size: CGSize(width: externalStr.getWidth(font: UIFont.ud.caption0) + 8, height: 18), font: UIFont.ud.caption0))
        }
        
        
        let trimedAttrbuteStr = AsyncRichLabelUtil.getRichTextWithTrailingTags(titleStr: props.headerTitle ?? "",titleFont: font, titleAttributes: enableAttributes, tagDataSource: tagDataSource, maxWidth: contentWidth, fistTagLeftMargin: 8, numberOfLines: 6, topMargin: -3)
        
        let trimedDisabledAttrbuteStr = AsyncRichLabelUtil.getRichTextWithTrailingTags(titleStr: props.headerTitle ?? "",titleFont: font, titleAttributes: disableAttributes, tagDataSource: tagDataSource, maxWidth: contentWidth, fistTagLeftMargin: 8, numberOfLines: 6, topMargin: -3)
        
        summaryLabel.props.attributedText = needDisable ? trimedDisabledAttrbuteStr : trimedAttrbuteStr
    }
}

