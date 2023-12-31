//
//  MessengerMockDependency+AI.swift
//  LarkMessenger
//
//  Created by ZhangHongyun on 2020/11/3.
//

import Foundation
import LarkAI
import Swinject
import EENavigator
import LarkNavigation
import LarkMessengerInterface
import LarkUIKit
import LarkFoundation
import LarkContainer
import LarkTab
import RxSwift
#if CalendarMod
import Calendar
#endif
#if CCMMod
import SpaceInterface
import SKDrive
#endif

public final class AIDependencyImpl: AIDependency {
    public var userResolver: UserResolver

    public init(resolver: UserResolver) {
        self.userResolver = resolver
    }

    public func smartActionPushToCalendar(chatId: String,
                                          startDate: Date?,
                                          endDate: Date?,
                                          useCount: Int,
                                          isMeeting: Bool = false,
                                          isAtAll: Bool = false,
                                          atList: [String]?,
                                          timeGrain: String?,
                                          pushParam: PushParam) {
        #if CalendarMod
        let isAllDay: Bool = (timeGrain == "day")
        var attendees: [CalendarCreateEventBody.Attendee] = []
        if isAtAll && isMeeting {
            attendees.append(CalendarCreateEventBody.Attendee.meetingGroup(chatId: chatId, memberCount: useCount))
        } else if isAtAll {
            attendees.append(CalendarCreateEventBody.Attendee.group(chatId: chatId, memberCount: useCount))
        } else if isMeeting {
            guard let atList = atList else { return }
            attendees.append(CalendarCreateEventBody.Attendee.partialMeetingGroupMembers(chatId: chatId, memberChatterIds: atList))
        } else {
            guard let atList = atList else { return }
            attendees.append(CalendarCreateEventBody.Attendee.partialGroupMembers(chatId: chatId, memberChatterIds: atList))
        }
        let body = CalendarCreateEventBody(summary: nil,
                                           startDate: startDate ?? Date().nextHalfHour,
                                           endDate: endDate,
                                           isAllDay: isAllDay,
                                           attendees: attendees,
                                           perferredScene: .freebusy)
        // PM临时决定改为present，故做一下参数pushParam到presentParam的转换，后续修改接口参数
        let displayStyle: UIModalPresentationStyle = Display.pad ? .formSheet : .fullScreen
        let presentParam = PresentParam(from: pushParam.from, prepare: { $0.modalPresentationStyle = displayStyle })
        userResolver.navigator.present(body: body, presentParam: presentParam)
        #endif
    }

    public func upload(localPath: String,
                fileName: String,
                mountNodePoint: String,
                mountPoint: String) -> Observable<(String, String, Bool)> {
        #if CCMMod
        guard let docCommonUploadProtocol = try? userResolver.resolve(assert: DocCommonUploadProtocol.self) else { return .empty() }
        return docCommonUploadProtocol
            .upload(localPath: localPath, fileName: fileName, mountNodePoint: mountNodePoint, mountPoint: mountPoint)
            .flatMap { (rustKey, progress, fileToken, status) -> Observable<(String, String, Bool)> in
                var complete = false
                if progress >= 1.0 && status == .success {
                    complete = true
                }
                return .just((rustKey, fileToken, complete))
            }
        #else
        .empty()
        #endif
    }
}
