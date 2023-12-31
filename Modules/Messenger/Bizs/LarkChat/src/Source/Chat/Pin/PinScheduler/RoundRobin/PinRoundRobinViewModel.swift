//
//  PinRoundRobinViewModel.swift
//  LarkChat
//
//  Created by tuwenbo on 2023/4/5.
//

import Foundation
import LarkModel
import LarkMessageBase
import AsyncComponent
import RustPB
extension PageContext: PinRoundRobinViewModelContext { }

public protocol PinRoundRobinViewModelContext: ViewModelContext {
    func eventTimeDescription(start: Int64,
                              end: Int64,
                              isAllDay: Bool) -> String
}

final class PinRoundRobinViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: PinRoundRobinViewModelContext>: MessageSubViewModel<M, D, C> {

    override var identifier: String {
        return "PinRoundRobin"
    }

    override var contentConfig: ContentConfig? {
        return ContentConfig(hasMargin: false, backgroundStyle: .white, maskToBounds: true, supportMutiSelect: true)
    }

    var content: RoundRobinCardContent {
        return (message.content as? RoundRobinCardContent) ?? .init(pb: .init())
    }

    var contentWidth: CGFloat {
        return min(metaModelDependency.getContentPreferMaxWidth(message), 370)
    }

    var title: String {
        if content.status == .statusActive {
            return BundleI18n.Calendar.Calendar_Scheduling_WhoDidEvent_Bot(host: content.hostName, invitee: content.guestName)
        } else {
            return BundleI18n.Calendar.Calendar_Scheduling_EventNoAvailable_Bot
        }
    }

    var icon: UIImage {
        return Resources.pinCalenderTip
    }

    var displayContent: [ComponentWithContext<C>] {
        let props = UILabelComponentProps()
        props.text = context.eventTimeDescription(start: content.startTime, end: content.endTime, isAllDay: false)
        props.font = UIFont.systemFont(ofSize: 14)
        props.numberOfLines = 1
        props.textColor = UIColor.ud.N500
        let style = ASComponentStyle()
        style.backgroundColor = UIColor.clear
        return [UILabelComponent<C>(props: props, style: style)]
    }

}
