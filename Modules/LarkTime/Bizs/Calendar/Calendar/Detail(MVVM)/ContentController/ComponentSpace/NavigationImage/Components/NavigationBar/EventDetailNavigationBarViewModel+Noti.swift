//
//  EventDetailNavigationBarViewModel+Noti.swift
//  Calendar
//
//  Created by pluto on 2022/12/28.
//

import Foundation

extension EventDetailNavigationBarViewModel {
    func addingMeetingCollaboratorRequest(data: CalendarNotiGroupApplySavedData, reason: String) {
        CalendarTracerV2.ApplyJoinGroup.traceClick {
            $0.click("confirm")
            $0.mergeEventCommonParams(commonParam: CommonParamData(event: self.event))
        }
        calendarApi?.AddMeetingCollaboratorRequest(uniqueKey: data.key,
                                                  operatorCalendarID: data.calendarID,
                                                   originalTime: data.originalTime,
                                                  addChatID: data.addChatIDs,
                                                  addCalendarID: data.addChatCalendarIDs,
                                                  addMeetingChatChatter: data.addMeetingChatChatter,
                                                  addMeetingMinuteCollaborator: data.addMeetingMinuteCollaborator,
                                                  addChatterApplyReason: reason)
        .subscribe(onNext: { [weak self] res in
            guard let self = self else { return }
            EventEdit.logger.info("AddMeetingCollaboratorRequest success.with \(res.status)")

            switch res.status {
            case .bothFailed, .addMeetingChatCollFailed:
                self.rxToast.accept(.failure(I18n.Calendar_G_OopsWrongRetry))
            case .addMeetingMinuteCollFailed:
                self.rxToast.accept(.failure(I18n.Calendar_G_AuthorizeFailCheckPermit_Toast))
            @unknown default: break
            }
        }, onError: { error in
            EventEdit.logger.error("AddMeetingCollaboratorRequest failed with \(error)")
        }).disposed(by: self.disposeBag)
    }
}
