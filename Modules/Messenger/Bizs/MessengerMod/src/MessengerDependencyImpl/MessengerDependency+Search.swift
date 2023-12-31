//
//  MessengerMockDependency+Search.swift
//  LarkMessenger
//
//  Created by CharlieSu on 12/3/19.
//

import UIKit
import Foundation
import RxSwift
import EENavigator
import Swinject
import LarkMessengerInterface
import LarkSearch
import LarkUIKit
import LarkContainer
import LarkSearchFilter
#if CalendarMod
import Calendar
#endif
#if MailMod
import LarkMailInterface
import MailSDK
import LarkMail
#endif
#if CCMMod
import SKSpace
import SpaceInterface
import CCMMod
#endif

final class SearchDependencyImpl: SearchDependency {
    private let resolver: UserResolver

    init(resolver: UserResolver) {
        self.resolver = resolver
    }

    // 重构后
    func getEmailSearchViewController(searchNavBar: SearchNaviBar) -> SearchContentContainer {
        #if MailMod
        guard let mailSearchViewController = try? resolver.resolve(type: LarkMailInterface.self)
                .getSearchController(query: searchNavBar.searchbar.searchTextField.text, searchNavBar: searchNavBar) as? MailSearchViewController else {
            return DemoUIViewController()
        }
        return mailSearchViewController
        #else
        DemoUIViewController()
        #endif
    }

    func isConversationModeEnable() -> Bool {
        #if MailMod
        guard let enableConversationMode = try? resolver.resolve(type: LarkMailInterface.self).isConversationModeEnable() else {
            return false
        }
        return enableConversationMode
        #else
        return false
        #endif
    }

    func hasEmailService() -> Bool {
        #if MailMod
        guard let hasMailService = try? resolver.resolve(type: LarkMailInterface.self).hasLarkSearchService() else {
            return false
        }
        return hasMailService
        #else
        return false
        #endif
    }
    func eventChildViewController(searchNavBar: SearchNaviBar) -> SearchContentContainer {
        #if CalendarMod
        guard let calendarSearchViewController = try? resolver.resolve(type: CalendarInterface.self)
            .getSearchController(query: searchNavBar.searchbar.searchTextField.text, searchNavBar: searchNavBar) as? CalendarSearchViewController else {
            return DemoUIViewController()
        }
        return calendarSearchViewController
        #else
        DemoUIViewController()
        #endif
    }

    func getAllCalendarsForSearchBiz(isNeedSelectedState: Bool) -> Observable<[MainSearchCalendarItem]> {
        #if CalendarMod
        guard let calendarService = try? resolver.resolve(type: CalendarInterface.self) else { return .empty() }
        return calendarService.getAllCalendarsForSearchBiz().map { subscribeCalendarsItems in
            guard !subscribeCalendarsItems.isEmpty else { return [] }
            return subscribeCalendarsItems.map { calendar in
                return MainSearchCalendarItem(id: calendar.serverId,
                                              title: calendar.summary,
                                              color: calendar.color,
                                              isOwner: calendar.isOwnerAccessRole,
                                              isSelected: isNeedSelectedState ? calendar.isVisible : false)
            }
        }
        #else
        return .empty()
        #endif
    }

    func pushCalendarEventDetail(eventKey: String, calendarId: String,
                                 originalTime: Int64, startTime: Int64, endTime: Int64,
                                 from: UIViewController) {
        #if CalendarMod
        let body = CalendarEventDetailWithTimeBody(eventKey: eventKey,
                                                   calendarId: calendarId,
                                                   originalTime: originalTime,
                                                   startTime: startTime,
                                                   endTime: endTime)
        resolver.navigator.push(body: body, from: from)
        #endif
    }

    func showDetailCalendarEventDetail(eventKey: String, calendarId: String,
                                       originalTime: Int64, startTime: Int64, endTime: Int64,
                                       from: UIViewController) {
        #if CalendarMod
        let body = CalendarEventDetailWithTimeBody(eventKey: eventKey,
                                                   calendarId: calendarId,
                                                   originalTime: originalTime,
                                                   startTime: startTime,
                                                   endTime: endTime)
        if Display.pad {
            resolver.navigator.present(body: body, from: from, prepare: { $0.modalPresentationStyle = .formSheet })
            return
        }
        resolver.navigator.showDetail(body: body, from: from)
        #endif
    }

    func pushCalendarEventSubSearch(query: String, pushParam: PushParam) {
        #if CalendarMod
        resolver.navigator.push(body: CalendarEventSubSearch(query: query), pushParam: pushParam)
        #endif
    }

    func isSupportURLType(url: URL) -> (Bool, type: String, token: String) {
        #if CCMMod
        return (try? resolver.resolve(assert: DocSDKAPI.self))?.isSupportURLType(url: url) ?? (false, "", "")
        #else
        (false, "", "")
        #endif
    }
}

final class DemoUIViewController: UIViewController, SearchContentContainer {
    func listView() -> UIView { UIView() }
    func queryChange(text: String) { }
}

#if CalendarMod
extension CalendarSearchViewController: SearchContentContainer {
    public func queryChange(text: String) { search() }
    public func listView() -> UIView { view }
}

#endif

#if MailMod
extension MailSearchViewController: SearchContentContainer {
    public func queryChange(text: String) { searchTextChanged(text) }
    public func listView() -> UIView { view }
}
#endif
