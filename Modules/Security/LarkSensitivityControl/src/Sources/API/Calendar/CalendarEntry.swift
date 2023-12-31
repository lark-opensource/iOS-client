//
//  CalendarEntry.swift
//  LarkSensitivityControl
//
//  Created by huanzhengjie on 2022/8/24.
//

import EventKit

/// Calendar
final public class CalendarEntry: NSObject, CalendarApi {

    private static func getService() -> CalendarApi.Type {
        if let service = LSC.getService(forTag: tag) as? CalendarApi.Type {
            return service
        }
        return CalendarWrapper.self
    }

    /// EKEventStore requestAccess
    public static func requestAccess(
        forToken token: Token,
        eventStore: EKEventStore,
        toEntityType entityType: EKEntityType,
        completion: @escaping EKEventStoreRequestAccessCompletionHandler) throws {
        let context = Context([AtomicInfo.Calendar.requestAccess.rawValue])
        try Assistant.checkToken(token, context: context)
        try getService().requestAccess(forToken: token, eventStore: eventStore,
                                       toEntityType: entityType, completion: completion)
    }

    /// EKEventStore requestWriteOnlyAccessToEvents
    @available(iOS 17.0, *)
    public static func requestWriteOnlyAccessToEvents(forToken token: Token,
                                                      eventStore: EKEventStore,
                                                      completion: @escaping EKEventStoreRequestAccessCompletionHandler) throws {
        let context = Context([AtomicInfo.Calendar.requestWriteOnlyAccessToEvents.rawValue])
        try Assistant.checkToken(token, context: context)
        try getService().requestWriteOnlyAccessToEvents(forToken: token, eventStore: eventStore, completion: completion)
    }

    /// EKEventStore requestFullAccessToEvents
    @available(iOS, introduced: 17.0)
    public static func requestFullAccessToEvents(forToken token: Token,
                                                 eventStore: EKEventStore,
                                                 completion: @escaping EKEventStoreRequestAccessCompletionHandler) throws {
        let context = Context([AtomicInfo.Calendar.requestFullAccessToEvents.rawValue])
        try Assistant.checkToken(token, context: context)
        try getService().requestFullAccessToEvents(forToken: token, eventStore: eventStore, completion: completion)
    }

    /// EKEventStore requestFullAccessToReminders
    @available(iOS, introduced: 17.0)
    public static func requestFullAccessToReminders(forToken token: Token,
                                                    eventStore: EKEventStore,
                                                    completion: @escaping EKEventStoreRequestAccessCompletionHandler) throws {
        let context = Context([AtomicInfo.Calendar.requestFullAccessToReminders.rawValue])
        try Assistant.checkToken(token, context: context)
        try getService().requestFullAccessToReminders(forToken: token, eventStore: eventStore, completion: completion)
    }

    /// EKEventStore calendars
    public static func calendars(forToken token: Token,
                                 eventStore: EKEventStore,
                                 forEntityType entityType: EKEntityType) throws -> [EKCalendar] {
        let context = Context([AtomicInfo.Calendar.calendars.rawValue])
        try Assistant.checkToken(token, context: context)
        return try getService().calendars(forToken: token, eventStore: eventStore,
                                          forEntityType: entityType)
    }

    /// lark calendar
    public static func calendar(forToken token: Token,
                                eventStore: EKEventStore,
                                withIdentifier identifier: String) throws -> EKCalendar? {
        let context = Context([AtomicInfo.Calendar.calendar.rawValue])
        try Assistant.checkToken(token, context: context)
        return try getService().calendar(forToken: token, eventStore: eventStore, withIdentifier: identifier)
    }

    /// lark saveCalendar
    public static func saveCalendar(forToken token: Token,
                                    eventStore: EKEventStore,
                                    calendar: EKCalendar,
                                    commit: Bool) throws {
        let context = Context([AtomicInfo.Calendar.saveCalendar.rawValue])
        try Assistant.checkToken(token, context: context)
        return try getService().saveCalendar(forToken: token, eventStore: eventStore, calendar: calendar, commit: commit)
    }

    /// lark removeCalendar
    public static func removeCalendar(forToken token: Token,
                                      eventStore: EKEventStore,
                                      calendar: EKCalendar,
                                      commit: Bool) throws {
        let context = Context([AtomicInfo.Calendar.removeCalendar.rawValue])
        try Assistant.checkToken(token, context: context)
        return try getService().removeCalendar(forToken: token, eventStore: eventStore, calendar: calendar, commit: commit)
    }

    /// lark calendarItem
    public static func calendarItem(forToken token: Token,
                                    eventStore: EKEventStore,
                                    withIdentifier identifier: String) throws -> EKCalendarItem? {
        let context = Context([AtomicInfo.Calendar.calendarItem.rawValue])
        try Assistant.checkToken(token, context: context)
        return try getService().calendarItem(forToken: token, eventStore: eventStore, withIdentifier: identifier)
    }

    /// lark calendarItems
    public static func calendarItems(
        forToken token: Token,
        eventStore: EKEventStore,
        withExternalIdentifier externalIdentifier: String) throws -> [EKCalendarItem] {
        let context = Context([AtomicInfo.Calendar.calendarItems.rawValue])
        try Assistant.checkToken(token, context: context)
        return try getService().calendarItems(forToken: token, eventStore: eventStore, withExternalIdentifier: externalIdentifier)
    }

    /// EKEventStore events
    public static func events(forToken token: Token,
                              eventStore: EKEventStore,
                              matchingPredicate predicate: NSPredicate) throws -> [EKEvent] {
        let context = Context([AtomicInfo.Calendar.events.rawValue])
        try Assistant.checkToken(token, context: context)
        return try getService().events(forToken: token, eventStore: eventStore,
                                       matchingPredicate: predicate)
    }

    /// EKEventStore remove
    public static func remove(forToken token: Token,
                              eventStore: EKEventStore,
                              event: EKEvent,
                              span: EKSpan,
                              commit: Bool) throws {
        let context = Context([AtomicInfo.Calendar.remove.rawValue])
        try Assistant.checkToken(token, context: context)
        try getService().remove(forToken: token, eventStore: eventStore, event: event, span: span, commit: commit)
    }

    /// EKEventStore saveWithCommit
    public static func save(forToken token: Token,
                            eventStore: EKEventStore,
                            event: EKEvent,
                            span: EKSpan,
                            commit: Bool) throws {
        let context = Context([AtomicInfo.Calendar.saveWithCommit.rawValue])
        try Assistant.checkToken(token, context: context)
        try getService().save(forToken: token, eventStore: eventStore, event: event, span: span, commit: commit)
    }

    /// EKEventStore save
    public static func save(forToken token: Token,
                            eventStore: EKEventStore,
                            event: EKEvent,
                            span: EKSpan) throws {
        let context = Context([AtomicInfo.Calendar.save.rawValue])
        try Assistant.checkToken(token, context: context)
        try getService().save(forToken: token, eventStore: eventStore, event: event, span: span)
    }

    /// EKSource calendars
    public static func calendars(forToken token: Token,
                                 source: EKSource,
                                 entityType: EKEntityType) throws -> Set<EKCalendar> {
        let context = Context([AtomicInfo.Calendar.calendarsWithSource.rawValue])
        try Assistant.checkToken(token, context: context)
        return try getService().calendars(forToken: token, source: source, entityType: entityType)
    }

    /// EKEventStore event
    public static func event(forToken token: Token,
                             eventStore: EKEventStore,
                             identifier: String) throws -> EKEvent? {
        let context = Context([AtomicInfo.Calendar.event.rawValue])
        try Assistant.checkToken(token, context: context)
        return try getService().event(forToken: token, eventStore: eventStore, identifier: identifier)
    }
}
