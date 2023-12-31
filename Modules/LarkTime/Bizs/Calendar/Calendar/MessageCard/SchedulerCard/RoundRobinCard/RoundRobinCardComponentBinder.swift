//
//  RoundRobinCardComponentBinder.swift
//  Calendar
//
//  Created by tuwenbo on 2023/3/28.
//

import Foundation
import LarkMessageBase
import LarkModel
import RxSwift
import AsyncComponent
import EEFlexiable

final class RoundRobinCardComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: RoundRobinCardViewModelContext>: ComponentBinder<C> {

    private lazy var _component: RoundRobinCardComponent<C> = RoundRobinCardComponent(props: .init(), style: .init())

    override var component: ComponentWithContext<C> { _component }

    private let style = ASComponentStyle()
    private let props = RoundRobinCardComponent<C>.Props()
    private var borderGetter: (() -> Border)?
    private var cornerRadiusGetter: (() -> CGFloat)?

    required init(key: String? = nil, context: C? = nil, borderGetter: (() -> Border)? = nil, cornerRadiusGetter: (() -> CGFloat)? = nil) {
        self.borderGetter = borderGetter
        self.cornerRadiusGetter = cornerRadiusGetter
        super.init(key: key, context: context)
    }

    override func update<VM>(with vm: VM, key: String? = nil) where VM : ViewModel {
        guard let vm = vm as? RoundRobinCardViewModel<M, D, C> else {
            assertionFailure()
            return
        }

        _component.style.width = CSSValue(cgfloat: vm.contentWidth)
        let content = vm.content
        props.time = vm.formatTime(startTime: content.startTime, endTime: content.endTime)
        props.isActive = content.status == .statusActive
        props.isForward = content.isForwardMsg
        props.amIHost = vm.amIHost(hostID: content.hostID)
        props.amICreator = vm.amICreator(creatorID: content.creatorID)
        switch (content.status, content.expiredReason) {
        case (.statusActive, _):
            props.title = I18n.Calendar_Scheduling_NewEvent_Bot
            props.subtitle = I18n.Calendar_Scheduling_WhoDidEvent_Bot(host: content.hostName, invitee: content.guestName)
            props.subtitleClickableName = content.hostName
            props.clickableUserID = content.hostID
            props.subtitleNameOnClick = vm.onSubtitleNameClick
            props.hostID = content.hostID
            props.hostName = content.hostName
            props.inviteeName = content.guestName
            props.inviteeEmail = content.guestEmail
            props.hostOnClick = vm.onHostNameClick
            props.inviteeEmailOnClick = vm.onInviteeEmailClick
            props.changeHostAction = vm.onChangeHost
            props.rescheduleAction = vm.onReschedule
            props.cancelAction = vm.onCancelScheduler
        case (.statusExpired, .expiredReasonReschedule):
            // 针对取消和重新预约的卡片失效类型，采用guestName代替operatorName
            props.title = I18n.Calendar_Scheduling_EventNoAvailable_Bot
            props.subtitle = I18n.Calendar_Scheduling_NameReschedule_Bot(name: content.guestName)
        case (.statusExpired, .expiredReasonCancel):
            // 针对取消和重新预约的卡片失效类型，采用guestName代替operatorName
            props.title = I18n.Calendar_Scheduling_EventNoAvailable_Bot
            props.subtitle = I18n.Calendar_Scheduling_NameCancel_Bot(name: content.guestName)
        case (.statusExpired, .expiredReasonChangeHost):
            let atName = "@\(content.operatorName)"
            props.title = I18n.Calendar_Scheduling_EventNoAvailable_Bot
            props.subtitle = I18n.Calendar_Scheduling_NameChangeHost_Bot(name: atName)
            props.subtitleClickableName = atName
            props.clickableUserID = content.operatorID
            props.subtitleNameOnClick = vm.onSubtitleNameClick
        @unknown default:
            props.title = I18n.Calendar_Scheduling_EventNoAvailable_Bot
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

        _component = RoundRobinCardComponent(props: props, style: style, context: context)
    }

}
