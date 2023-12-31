//
//  EventEditViewModel+Delete.swift
//  Calendar
//
//  Created by 张威 on 2020/4/1.
//

/// 日程删除

extension EventEditViewModel {

    func getEntitiesForDeleting() -> (event: CalendarEventEntity, instance: CalendarEventInstanceEntity)? {
        switch input {
        case .editFromLocal(let ekEvent):
            let eventEntity = CalendarEventEntityFromLocal(event: ekEvent)
            let instanceEntity = CalendarEventInstanceEntityFromLocal(event: ekEvent)
            return (eventEntity, instanceEntity)
        case .editFrom(let pbEvent, let pbInstance), .editWebinar(let pbEvent, let pbInstance):
            let eventEntity = PBCalendarEventEntity(pb: pbEvent)
            let instanceEntity = CalendarEventInstanceEntityFromPB(withInstance: pbInstance)
            return (eventEntity, instanceEntity)
        default:
            assertionFailure()
            return nil
        }
    }

    func getModelForDeleting() -> EventDeleteProtocol? {
        guard let entities = getEntitiesForDeleting() else {
            assertionFailure()
            return nil
        }

        let isMeetingLiving = permissionModel?.rxModel?.value.isVideoMeetingLiving ?? false

        return EventDeleteModel.eventDeleteModel(
            event: entities.event,
            instance: entities.instance,
            isException: entities.event.isException(),
            isMeeting: entities.event.type == .meeting,
            isMeetingLiving: isMeetingLiving,
            span: self.span
        )
    }

    func deleteZoomMeeting(meetingID: Int64) {
        calendarApi?.deleteZoomMeetingRequest(meetingID: meetingID)
            .subscribe(onNext: { [weak self] (response) in
                guard let `self` = self else { return }
                switch response.respState {
                case .success:
                    self.logger.info("delete ZoomMeeting success")
                case .fail:
                    self.logger.info("delete ZoomMeeting failed")
                @unknown default:
                    break
                }
            }, onError: {[weak self] error in
                guard let `self` = self else { return }
                self.logger.error("delete ZoomMeeting request failed with: \(error)")
            }).disposed(by: disposeBag)
    }

}
