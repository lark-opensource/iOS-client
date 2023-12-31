//
//  EventCardRSVPReactionInfoComponent.swift
//  Calendar
//
//  Created by pluto on 2023/6/3.
//

import UIKit
import UniverseDesignIcon
import Foundation
import CalendarFoundation
import AsyncComponent
import EEFlexiable
import RichLabel

final class EventCardRSVPReactionInfoComponentProps: ASComponentProps {
    var infoText: String?
    var needTopLine: Bool = false
}

final class EventCardRSVPReactionInfoComponent<C: Context>: ASComponent<EventCardRSVPReactionInfoComponentProps, EmptyState, UIView, C> {
    private let topLineComponent: UIViewComponent<C> = {
        let style = ASComponentStyle()
        style.width = 100%
        style.height = 1
        style.backgroundColor = UIColor.ud.lineDividerDefault
        style.display = .none
        return UIViewComponent<C>(props: ASComponentProps(), style: style)
    }()
    
    private let infoLabel: UILabelComponent<C> = {
        let titleProps = UILabelComponentProps()
        titleProps.font = UIFont.ud.caption1
        titleProps.textColor = UIColor.ud.textTitle
        titleProps.numberOfLines = 1
        let style = ASComponentStyle()
        style.width = 100%
        style.backgroundColor = UIColor.clear
        style.marginTop = 8
        return UILabelComponent(props: titleProps, style: style)
    }()
    
    override init(props: EventCardRSVPReactionInfoComponentProps, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
        style.flexDirection = .column
        style.marginTop = 12
        style.paddingLeft = 13
        style.paddingRight = 12
        setSubComponents([
            topLineComponent,
            infoLabel
        ])
    }
    
    override func willReceiveProps(_ old: EventCardRSVPReactionInfoComponentProps, _ new: EventCardRSVPReactionInfoComponentProps) -> Bool {
        let font = UIFont.ud.caption1(.fixed)
        let fontFigmaHeight = font.figmaHeight
        let baselineOffset = (fontFigmaHeight - font.lineHeight) / 2.0 / 2.0
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = fontFigmaHeight
        paragraphStyle.maximumLineHeight = fontFigmaHeight
        infoLabel.props.attributedText = NSAttributedString(string: new.infoText ?? "",
                                                            attributes: [.foregroundColor: UIColor.ud.textTitle,
                                                                         .font: UIFont.ud.caption1,
                                                                         .baselineOffset: baselineOffset,
                                                                         .paragraphStyle: paragraphStyle])
        topLineComponent.style.display = new.needTopLine ? .flex : .none
        style.marginTop = new.needTopLine ? 12 : 0
        return true
    }
    
    
}
