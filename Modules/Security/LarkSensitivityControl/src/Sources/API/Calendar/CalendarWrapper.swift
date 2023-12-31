//
//  CalendarWrapper.swift
//  LarkSensitivityControl
//
//  Created by yangyifan on 2023/3/7.
//

import EventKit

final class CalendarWrapper: NSObject, CalendarApi {
    /// EKEventStore requestAccess
    static func requestAccess(forToken token: Token,
                              eventStore: EKEventStore,
                              toEntityType entityType: EKEntityType,
                              completion: @escaping EKEventStoreRequestAccessCompletionHandler) throws {
        eventStore.requestAccess(to: entityType, completion: completion)
    }

    /// EKEventStore requestWriteOnlyAccessToEvents
    @available(iOS 17.0, *)
    static func requestWriteOnlyAccessToEvents(forToken token: Token,
                                               eventStore: EKEventStore,
                                               completion: @escaping EKEventStoreRequestAccessCompletionHandler) throws {
        #if swift(>=5.9)
        eventStore.requestWriteOnlyAccessToEvents(completion: completion)
        #endif
    }

    /// EKEventStore requestFullAccessToEvents
    @available(iOS, introduced: 17.0)
    static func requestFullAccessToEvents(forToken token: Token,
                                          eventStore: EKEventStore,
                                          completion: @escaping EKEventStoreRequestAccessCompletionHandler) throws {
        #if swift(>=5.9)
        eventStore.requestFullAccessToEvents(completion: completion)
        #endif
    }

    /// EKEventStore requestFullAccessToReminders
    @available(iOS, introduced: 17.0)
    static func requestFullAccessToReminders(forToken token: Token,
                                             eventStore: EKEventStore,
                                             completion: @escaping EKEventStoreRequestAccessCompletionHandler) throws {
        #if swift(>=5.9)
        eventStore.requestFullAccessToReminders(completion: completion)
        #endif
    }

    /// EKEventStore calendars
    static func calendars(forToken token: Token,
                          eventStore: EKEventStore,
                          forEntityType entityType: EKEntityType) throws -> [EKCalendar] {
        return eventStore.calendars(for: entityType)
    }

    /// lark calendar
    static func calendar(forToken token: Token,
                         eventStore: EKEventStore,
                         withIdentifier identifier: String) throws -> EKCalendar? {
        return eventStore.calendar(withIdentifier: identifier)
    }

    /// lark saveCalendar
    static func saveCalendar(forToken token: Token,
                             eventStore: EKEventStore,
                             calendar: EKCalendar,
                             commit: Bool) throws {
        return try eventStore.saveCalendar(calendar, commit: commit)
    }

    /// lark removeCalendar
    static func removeCalendar(forToken token: Token,
                               eventStore: EKEventStore,
                               calendar: EKCalendar,
                               commit: Bool) throws {
        return try eventStore.removeCalendar(calendar, commit: commit)
    }

    /// lark calendarItem
    static func calendarItem(forToken token: Token,
                             eventStore: EKEventStore,
                             withIdentifier identifier: String) throws -> EKCalendarItem? {
        return eventStore.calendarItem(withIdentifier: identifier)
    }

    /// lark calendarItems
    static func calendarItems(
        forToken token: Token,
        eventStore: EKEventStore,
        withExternalIdentifier externalIdentifier: String) throws -> [EKCalendarItem] {
        return eventStore.calendarItems(withExternalIdentifier: externalIdentifier)
    }

    /// EKEventStore events
    static func events(forToken token: Token,
                       eventStore: EKEventStore,
                       matchingPredicate predicate: NSPredicate) throws -> [EKEvent] {
        return eventStore.events(matching: predicate)
    }

    /// EKEventStore remove
    static func remove(forToken token: Token,
                       eventStore: EKEventStore,
                       event: EKEvent,
                       span: EKSpan,
                       commit: Bool) throws {
        try eventStore.remove(event, span: span, commit: commit)
    }

    /// EKEventStore saveWithCommit
    static func save(forToken token: Token,
                     eventStore: EKEventStore,
                     event: EKEvent,
                     span: EKSpan,
                     commit: Bool) throws {
        try eventStore.save(event, span: span, commit: commit)
    }

    /// EKEventStore save
    static func save(forToken token: Token,
                     eventStore: EKEventStore,
                     event: EKEvent,
                     span: EKSpan) throws {
        try eventStore.save(event, span: span)
    }

    /// EKSource calendars
    static func calendars(forToken token: Token,
                          source: EKSource,
                          entityType: EKEntityType) throws -> Set<EKCalendar> {
        return source.calendars(for: entityType)
    }

    /// EKEventStore event
    static func event(forToken token: Token, eventStore: EKEventStore, identifier: String) throws -> EKEvent? {
        return eventStore.event(withIdentifier: identifier)
    }
}
