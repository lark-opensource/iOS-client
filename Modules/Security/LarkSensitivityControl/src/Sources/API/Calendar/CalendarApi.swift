//
//  CalendarApi.swift
//  LarkSensitivityControl
//
//  Created by yangyifan on 2023/3/7.
//

import EventKit

public extension CalendarApi {
    /// 外部注册自定义api使用的key值
    static var tag: String {
        "calendar"
    }
}

/// calendar相关方法
public protocol CalendarApi: SensitiveApi {

    /// EKEventStore requestAccess
    static func requestAccess(forToken token: Token,
                              eventStore: EKEventStore,
                              toEntityType entityType: EKEntityType,
                              completion: @escaping EKEventStoreRequestAccessCompletionHandler) throws

    /// EKEventStore requestWriteOnlyAccessToEvents
    @available(iOS, introduced: 17.0)
    static func requestWriteOnlyAccessToEvents(forToken token: Token,
                                               eventStore: EKEventStore,
                                               completion: @escaping EKEventStoreRequestAccessCompletionHandler) throws

    /// EKEventStore requestFullAccessToEvents
    @available(iOS, introduced: 17.0)
    static func requestFullAccessToEvents(forToken token: Token,
                                          eventStore: EKEventStore,
                                          completion: @escaping EKEventStoreRequestAccessCompletionHandler) throws

    /// EKEventStore requestFullAccessToReminders
    @available(iOS, introduced: 17.0)
    static func requestFullAccessToReminders(forToken token: Token,
                                             eventStore: EKEventStore,
                                             completion: @escaping EKEventStoreRequestAccessCompletionHandler) throws

    /// EKEventStore calendars
    static func calendars(forToken token: Token,
                          eventStore: EKEventStore,
                          forEntityType entityType: EKEntityType) throws -> [EKCalendar]

    /// lark calendar
    static func calendar(forToken token: Token,
                         eventStore: EKEventStore,
                         withIdentifier identifier: String) throws -> EKCalendar?

    /// lark saveCalendar
    static func saveCalendar(forToken token: Token,
                             eventStore: EKEventStore,
                             calendar: EKCalendar,
                             commit: Bool) throws

    /// lark removeCalendar
    static func removeCalendar(forToken token: Token,
                               eventStore: EKEventStore,
                               calendar: EKCalendar,
                               commit: Bool) throws

    /// lark calendarItem
    static func calendarItem(forToken token: Token,
                             eventStore: EKEventStore,
                             withIdentifier identifier: String) throws -> EKCalendarItem?

    /// lark calendarItems
    static func calendarItems(
        forToken token: Token,
        eventStore: EKEventStore,
        withExternalIdentifier externalIdentifier: String) throws -> [EKCalendarItem]

    /// EKEventStore events
    static func events(forToken token: Token,
                       eventStore: EKEventStore,
                       matchingPredicate predicate: NSPredicate) throws -> [EKEvent]

    /// EKEventStore remove
    static func remove(forToken token: Token,
                       eventStore: EKEventStore,
                       event: EKEvent,
                       span: EKSpan,
                       commit: Bool) throws

    /// EKEventStore saveWithCommit
    static func save(forToken token: Token,
                     eventStore: EKEventStore,
                     event: EKEvent,
                     span: EKSpan,
                     commit: Bool) throws

    /// EKEventStore save
    static func save(forToken token: Token,
                     eventStore: EKEventStore,
                     event: EKEvent,
                     span: EKSpan) throws

    /// EKSource calendars
    static func calendars(forToken token: Token,
                          source: EKSource,
                          entityType: EKEntityType) throws -> Set<EKCalendar>

    /// EKEventStore event
    static func event(forToken token: Token, eventStore: EKEventStore, identifier: String) throws -> EKEvent?
}
