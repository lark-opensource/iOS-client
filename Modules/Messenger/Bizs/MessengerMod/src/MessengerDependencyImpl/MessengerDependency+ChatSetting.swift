//
//  MessengerDependencyMockImpl+ChatSetting.swift
//  LarkMessenger
//
//  Created by kongkaikai on 2019/12/13.
//

import Foundation
import LarkChatSetting
import RxSwift
import LarkMessengerInterface
import Swinject
import EENavigator
import LarkContainer
#if CalendarMod
import Calendar
#endif
#if TodoMod
import TodoInterface
#endif

public final class ChatSettingDependencyImpl: ChatSettingDependency {
    private let resolver: UserResolver

    public init(resolver: UserResolver) {
        self.resolver = resolver
    }

    public func toNormalGroup(chatID: String) -> Observable<Void> {
        #if CalendarMod
        (try? resolver.resolve(assert: CalendarInterface.self))?.toNormalGroup(chatID: chatID) ?? .empty()
        #else
        .empty()
        #endif
    }

    public func getIsOrganizer(chatID: String) -> Observable<Bool> {
        #if CalendarMod
        (try? resolver.resolve(assert: CalendarInterface.self))?.getIsOrganizer(chatID: chatID) ?? .empty()
        #else
        .empty()
        #endif
    }

    public func pushEventDetail(chatId: String, pushParam: PushParam) {
        #if CalendarMod
        resolver.navigator.push(body: CalendarEeventDetailFromMeeting(chatId: chatId), pushParam: pushParam)
        #endif
    }

    public func presentEventDetail(chatId: String, presentParam: PresentParam) {
        #if CalendarMod
        resolver.navigator.present(body: CalendarEeventDetailFromMeeting(chatId: chatId), presentParam: presentParam)
        #endif
    }

    public func presentFreeBusyGroup(chatId: String, chatType: String, presentParam: PresentParam) {
        #if CalendarMod
        resolver.navigator.present(body: FreeBusyInGroupBody(chatId: chatId, chatType: chatType), presentParam: presentParam)
        #endif
    }

    public func getMeetingSummaryBadgeStatus(_ chatId: String, handler: @escaping (Result<Bool, Error>) -> Void) {
        #if CalendarMod
        (try? resolver.resolve(assert: CalendarInterface.self))?.getMeetingSummaryBadgeStatus(chatId, handler: handler)
        #endif
    }

    public func registerMeetingSummaryPush() -> Observable<(String, Int)> {
        #if CalendarMod
        (try? resolver.resolve(assert: CalendarInterface.self))?.registerMeetingSummaryPush() ?? .empty()
        #else
        .empty()
        #endif
    }

    public func getEventInfo(chatId: String) -> Observable<CalendarChatMeetingInfo?> {
        #if CalendarMod
        guard let interface = try? resolver.resolve(assert: CalendarInterface.self) else { return .empty() }
        return interface.getEventInfo(chatId: chatId)
            .map { info in
                info.flatMap {
                    if let meetingInfo = $0.meetingEventInfo {
                       return CalendarChatMeetingInfo(meetingInfo: MeetingInfo(startTime: meetingInfo.startTime,
                                                                     endTime: meetingInfo.endTime,
                                                                     alertName: meetingInfo.alertName), url: $0.url)
                    } else {
                        return CalendarChatMeetingInfo(meetingInfo: nil, url: $0.url)
                    }
                }
            }
        #else
        .empty()
        #endif
    }

    public func pushTodoListFromChat(withChat chatID: String, isFromThread: Bool, pushParam: PushParam) {
        #if TodoMod
        resolver.navigator.push(body: ChatTodoBody(chatId: chatID, isFromThread: isFromThread), pushParam: pushParam)
        #endif
    }
}
