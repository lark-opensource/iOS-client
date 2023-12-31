//
//  PinEventRSVPViewModel.swift
//  LarkChat
//
//  Created by pluto on 2023/2/16.
//

import UIKit
import Foundation
import LarkModel
import LarkMessageBase
import AsyncComponent
import RustPB

public protocol PinEventRSVPViewModelContext: ViewModelContext {
    func eventTimeDescription(start: Int64,
                              end: Int64,
                              isAllDay: Bool) -> String
}

final class PinEventRSVPViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: PinEventRSVPViewModelContext>: MessageSubViewModel<M, D, C> {
    override var identifier: String {
        return "PinEventRSVP"
    }

    override var contentConfig: ContentConfig? {
        return ContentConfig(hasMargin: false, backgroundStyle: .white, maskToBounds: true, supportMutiSelect: true)
    }

    var content: GeneralCalendarEventRSVPContent {
        return (message.content as? GeneralCalendarEventRSVPContent) ?? .init(pb: .init())
    }

    var contentWidth: CGFloat {
        return min(metaModelDependency.getContentPreferMaxWidth(message), 370)
    }

    var title: String {
        return content.title.isEmpty ? BundleI18n.LarkChat.Lark_View_ServerNoTitle : content.title
    }

    var icon: UIImage {
        return Resources.pinCalenderTip
    }

    var displayContent: [ComponentWithContext<C>] {
        let props = UILabelComponentProps()
        props.text = context.eventTimeDescription(start: content.startTime, end: content.endTime, isAllDay: content.isAllDay)
        props.font = UIFont.systemFont(ofSize: 14)
        props.numberOfLines = 1
        props.textColor = UIColor.ud.N500
        let style = ASComponentStyle()
        style.backgroundColor = UIColor.clear
        return [UILabelComponent<C>(props: props, style: style)]
    }
}

extension PageContext: PinEventRSVPViewModelContext {
}
