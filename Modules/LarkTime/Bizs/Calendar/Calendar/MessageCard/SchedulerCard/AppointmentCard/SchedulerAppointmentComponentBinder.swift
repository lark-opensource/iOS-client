//
//  SchedulerAppointmentComponentBinder.swift
//  Calendar
//
//  Created by tuwenbo on 2023/3/29.
//

import Foundation
import LarkMessageBase
import LarkModel
import RxSwift
import AsyncComponent
import EEFlexiable

final class SchedulerAppointmentComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: SchedulerAppointmentViewModelContext>: ComponentBinder<C> {

    private lazy var _component: SchedulerAppointmentComponent<C> = SchedulerAppointmentComponent(props: .init(), style: .init())

    override var component: ComponentWithContext<C> { _component }

    private let style = ASComponentStyle()
    private let props = SchedulerAppointmentComponent<C>.Props()
    private var borderGetter: (() -> Border)?
    private var cornerRadiusGetter: (() -> CGFloat)?

    required init(key: String? = nil, context: C? = nil, borderGetter: (() -> Border)? = nil, cornerRadiusGetter: (() -> CGFloat)? = nil) {
        self.borderGetter = borderGetter
        self.cornerRadiusGetter = cornerRadiusGetter
        super.init(key: key, context: context)
    }

    override func update<VM>(with vm: VM, key: String? = nil) where VM : ViewModel {
        guard let vm = vm as? SchedulerAppointmentViewModel<M, D, C> else {
            assertionFailure()
            return
        }

        _component.style.width = CSSValue(cgfloat: vm.contentWidth)

        let content = vm.content
        props.isActive = content.status == .statusActive
        props.time = vm.formatTime(startTime: content.startTime, endTime: content.endTime)
        props.isExternal = content.isExternal

        if content.status == .statusActive {
            props.title = content.schedulerName.isEmpty ? I18n.Calendar_Common_NoTitle : content.schedulerName
            props.inviteeEmail = content.guestEmail
            props.inviteeEmailOnClick = vm.onInviteeEmailClick
            props.subtitleClickableName = content.hostName
            props.clickableUserID = content.hostID
            props.subtitleNameOnClick = vm.openChatter
            props.message = content.message
            props.detailLink = content.eventLink
            props.viewDetailAction = vm.viewDetailAction
            props.actionButtonVisible = !content.isForwardMsg && props.isActive
            switch content.action {
            case .actionCreate, .actionChangeHost:
                props.subtitle = content.isForwardMsg ?
                I18n.Calendar_Scheduling_WhoDidEvent_Bot(host: content.hostName, invitee: content.guestName) :
                I18n.Calendar_ScheduleMobile_Title(name: content.guestName)
                props.messageTitle = I18n.Calendar_ScheduleBot_Message
            case .actionReschedule:
                props.subtitle = content.isForwardMsg ?
                I18n.Calendar_Scheduling_HostRescheduledByInvitee(invitee: content.guestName, host: content.hostName) :
                I18n.Calendar_ScheduleMobile_NameReschedule(name: content.guestName)
                props.messageTitle = I18n.Calendar_ScheduleBot_ChangeReason
            case .actionCancel:
                // 虽然状态是 active，但是 actionCancel 的样式和 expired 一样，所以展示时当 expired 处理
                props.isActive = false
                props.actionButtonVisible = false
                if content.cancelReason == .cancelReasonChangeHost {
                    props.subtitle = I18n.Calendar_Scheduling_NameChangeHost_Bot(name: content.altOperatorName)
                } else {
                    props.subtitle = content.isForwardMsg ?
                    I18n.Calendar_Scheduling_HostCanceledByInvitee(invitee: content.altOperatorName, host: content.hostName) :
                    I18n.Calendar_ScheduleMobile_NameCancel(name: content.altOperatorName)
                }
                props.messageTitle = I18n.Calendar_ScheduleBot_CancellationReason
            @unknown default:
                break
            }
        } else if content.status == .statusExpired {
            props.title = I18n.Calendar_Scheduling_EventNoAvailable_Bot
            switch content.expiredReason {
            case .expiredReasonReschedule:
                props.subtitle = content.isForwardMsg ?
                I18n.Calendar_Scheduling_HostRescheduledByInvitee(invitee: content.guestName, host: content.hostName) :
                I18n.Calendar_Scheduling_NameReschedule_Bot(name: content.guestName)
                props.subtitleClickableName = content.hostName
                props.clickableUserID = content.hostID
                props.subtitleNameOnClick = vm.openChatter
            case .expiredReasonCancel:
                props.subtitle = content.isForwardMsg ?
                I18n.Calendar_Scheduling_HostCanceledByInvitee(invitee: content.altOperatorName, host: content.hostName) :
                I18n.Calendar_Scheduling_NameCancel_Bot(name: content.altOperatorName)
                props.subtitleClickableName = content.hostName
                props.clickableUserID = content.hostID
                props.subtitleNameOnClick = vm.openChatter
            case .expiredReasonChangeHost:
                props.subtitle = I18n.Calendar_Scheduling_NameChangeHost_Bot(name: content.operatorName)
            @unknown default:
                break
            }
        }
        _component.props = props
    }

    override func buildComponent(key: String? = nil, context: C? = nil) {
        if let border = borderGetter?() {
            style.border = border
        }

        if let cornerRadius = cornerRadiusGetter?() {
            style.cornerRadius = cornerRadius
        }

        _component = SchedulerAppointmentComponent(props: props, style: style, context: context)
    }

}

