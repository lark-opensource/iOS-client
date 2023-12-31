//
//  PinAppointmentViewModel.swift
//  LarkChat
//
//  Created by tuwenbo on 2023/4/10.
//

import Foundation
import LarkModel
import LarkMessageBase
import AsyncComponent
import RustPB

extension PageContext: PinAppointmentViewModelContext { }

public protocol PinAppointmentViewModelContext: ViewModelContext {
    func eventTimeDescription(start: Int64,
                              end: Int64,
                              isAllDay: Bool) -> String
}

final class PinAppointmentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: PinAppointmentViewModelContext>: MessageSubViewModel<M, D, C> {

    override var identifier: String {
        return "PinAppointment"
    }

    override var contentConfig: ContentConfig? {
        return ContentConfig(hasMargin: false, backgroundStyle: .white, maskToBounds: true, supportMutiSelect: true)
    }

    var content: SchedulerAppointmentCardContent {
        return (message.content as? SchedulerAppointmentCardContent) ?? .init(pb: .init())
    }

    var contentWidth: CGFloat {
        return min(metaModelDependency.getContentPreferMaxWidth(message), 370)
    }

    var title: String {
        if content.status == .statusActive {
            if content.action == .actionReschedule {
                return BundleI18n.Calendar.Calendar_Scheduling_HostRescheduledByInvitee(invitee: content.guestName, host: content.hostName)
            } else if content.action == .actionCancel {
                return BundleI18n.Calendar.Calendar_Scheduling_HostCanceledByInvitee(invitee: content.altOperatorName, host: content.hostName)
            } else {
                return BundleI18n.Calendar.Calendar_Scheduling_WhoDidEvent_Bot(host: content.hostName, invitee: content.guestName)
            }
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
