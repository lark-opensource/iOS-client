//
//  EventDetailNavigationBarViewModel+Edit.swift
//  Calendar
//
//  Created by Rico on 2021/4/13.
//

import Foundation
import EventKit
import RxRelay
import RxSwift
import RustPB

extension EventDetailNavigationBarViewModel {

    func handleEditAction() {

        EventDetail.logInfo("edit action")
        guard editStyle != .none else { return }
        if event.disableEncrypt {
            rxToast.accept(.tips(I18n.Calendar_NoKeyNoOperate_Toast))
            return
        }

        if editStyle == .disabled {
            if let event = model.event,
               event.calendarEventDisplayInfo.deleteBtnDisplayType == .shownExternalAccountExpired {
                rxToast.accept(.tips(I18n.Calendar_Sync_SyncExpiredShort))
            } else {
                rxToast.accept(.tips(I18n.Calendar_Edit_CantEditNeedUpdateToast()))
            }
            return
        }

        if let schemaLink = model.event?.dt.schemaLink(key: .edit) {
            rxRoute.accept(.url(url: schemaLink))
            return
        }

        let editInput: EventEditInput
        switch model {
        case let .local(ekEvent): editInput = .editFromLocal(ekEvent: ekEvent)
        case let .pb(event, instance):
            if model.isWebinar {
                var newEvent = event
                // webinar 日程的 webinarInfo 只在 server event 里面存在，详情页在请求 server 的时候缓存了，这里直接使用
                newEvent.webinarInfo = context.state.webinarContext?.webinarInfo ?? event.webinarInfo
                editInput = .editWebinar(pbEvent: newEvent, pbInstance: instance)
            } else {
                editInput = .editFrom(pbEvent: event, pbInstance: instance)
            }
        case .meetingRoomLimit:
            assertionFailure("会议室无权限日程不能走到这个逻辑")
            editInput = .editFromLocal(ekEvent: EKEvent())
        }

        let coordinator = EventEditCoordinator(
            userResolver: self.userResolver,
            editInput: editInput,
            dependency: EventEditCoordinator.DependencyImpl(userResolver: userResolver),
            legoInfo: editInput.isWebinarScene ? .webinar() : .normal()
        )

        coordinator.delegate = self
        coordinator.actionSource = .detail
        rxRoute.accept(.edit(coordinator: coordinator))
        EventDetail.logInfo("event edit accept coordinator")
        monitor.track(.start(.edit))

        CalendarTracerV2.EventDetail.traceClick {
            $0
                .click("edit_event")
                .target(.cal_event_full_create_view)
            $0.event_type = model.isWebinar ? "webinar" : "normal"
            $0.mergeEventCommonParams(commonParam: CommonParamData(instance: self.model.instance, event: self.model.event))
        }
    }

}
