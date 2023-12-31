//
//  EventCardReplyCellComponent.swift
//  CalendarInChat
//
//  Created by heng zhu on 2019/7/30.
//

import UIKit
import Foundation
import CalendarFoundation
import AsyncComponent
import EEFlexiable

final class EventCardReplyCellComponentProps: ASComponentProps {
    var name: String?
    var text: String?
}

final class EventCardReplyCellComponent<C: Context>: ASComponent<EventCardReplyCellComponentProps, EmptyState, UIView, C> {
    private let replyTopLineComponent: UIViewComponent<C> = {
        let style = ASComponentStyle()
        style.width = 100%
        style.height = 1
        style.marginTop = 16
        style.backgroundColor = UIColor.ud.lineDividerDefault
        return UIViewComponent<C>(props: ASComponentProps(), style: style)
    }()

    private let titleLabel: UILabelComponent<C> = {
        let titleProps = UILabelComponentProps()
        titleProps.font = UIFont.body3
        titleProps.textColor = UIColor.ud.textTitle
        titleProps.textAlignment = .center
        titleProps.numberOfLines = 2
        let style = ASComponentStyle()
        style.marginTop = 14
        style.flexGrow = 0
        style.flexShrink = 0
        style.backgroundColor = UIColor.clear
        return UILabelComponent(props: titleProps, style: style)
    }()

    override init(props: EventCardReplyCellComponentProps, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
        style.alignContent = .stretch
        style.justifyContent = .flexEnd
        style.flexDirection = .column
        style.marginTop = 0
        style.paddingRight = 12
        style.paddingLeft = 12

        let warpperStyle = ASComponentStyle()
        warpperStyle.flexDirection = .column
        warpperStyle.width = 100%

        let warpperComponent = ASLayoutComponent(style: warpperStyle, [titleLabel])

        setSubComponents([
            replyTopLineComponent,
            warpperComponent
        ])
    }

    override func willReceiveProps(_ old: EventCardReplyCellComponentProps, _ new: EventCardReplyCellComponentProps) -> Bool {
        titleLabel.props.text = new.text
        return true
    }
}
