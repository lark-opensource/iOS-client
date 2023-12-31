//
//  ChatSettingDependency.swift
//  LarkChatSetting
//
//  Created by kongkaikai on 2019/12/13.
//

import Foundation
import RxSwift
import LarkMessengerInterface
import LarkModel
import ServerPB
import RustPB

public typealias ChatSettingDependency = ChatSettingCalendarDependency & ChatSettingTodoDependency

public protocol ChatSettingCalendarDependency {
    func toNormalGroup(chatID: String) -> Observable<Void>
    func getIsOrganizer(chatID: String) -> Observable<Bool>
    func pushEventDetail(chatId: String, pushParam: PushParam)
    func presentEventDetail(chatId: String, presentParam: PresentParam)
    func presentFreeBusyGroup(chatId: String, chatType: String, presentParam: PresentParam)
    func getMeetingSummaryBadgeStatus(_ chatId: String, handler: @escaping (Result<Bool, Error>) -> Void)
    func registerMeetingSummaryPush() -> Observable<(String, Int)>
    func getEventInfo(chatId: String) -> Observable<CalendarChatMeetingInfo?>
}

public protocol ChatSettingTodoDependency {
    func pushTodoListFromChat(withChat chatID: String, isFromThread: Bool, pushParam: PushParam)
}
