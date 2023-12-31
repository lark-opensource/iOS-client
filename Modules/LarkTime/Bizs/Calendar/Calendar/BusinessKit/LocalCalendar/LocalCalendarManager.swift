//
//  LocalCalendarManager.swift
//  Calendar
//
//  Created by jiayi zou on 2018/9/7.
//  Copyright © 2018 EE. All rights reserved.
//

import Foundation
import CalendarFoundation
import EventKit
import EventKitUI
import RustPB
import RxSwift
import RxCocoa
import ThreadSafeDataStructure
import LarkContainer
import RunloopTools
import LarkSensitivityControl

public protocol LocalCalSidebarModel {
    var title: String { get }
    var sourceTitle: String { get }
    var color: UIColor { get }
    var selected: Bool { get }
    var calIdentifier: String { get }
    var calSourceIdentifier: String { get }
}

private struct LocalCalSidebarModelImpl: LocalCalSidebarModel {
    var title: String

    var sourceTitle: String

    var color: UIColor

    var selected: Bool

    var calIdentifier: String

    var calSourceIdentifier: String
}

struct LocalCalSideBarSourceModel: Hashable {
    var title: String
    var id: String
}

public final class LocalCalendarManager {
    //类似数据库入口，需保持全局唯一性
    //绝对不允许对外暴露
    private static func getEventStore() -> EKEventStore {
        return EKEventStore()
    }
    private static var serverHost: SafeAtomic<String> = "caldav.feishu.cn" + .readWriteLock

    /// preload EKEventView Only Once
    private static var firstInit = true
    private static let disposeBag = DisposeBag()
    static let localCalVisibiltyPublish = PublishSubject<[LocalCalendarSettingControllerItem]>()

    static func registerObservers() {
        // LocalCalendarManager.eventStore 有性能问题，延时监听避免影响冷启动
        DispatchQueue.global().asyncAfter(deadline: .now() + 3) {
            NotificationCenter.default.addObserver(self, selector: #selector(LocalCalendarManager.receiveNotification), name: .EKEventStoreChanged, object: LocalCalendarManager.eventStore.value)

            LocalCalendarManager.localCalVisibiltyPublish.debounce(.milliseconds(1000), scheduler: MainScheduler.instance).subscribe({ (event) in
                guard let items = event.element else {
                    assertionFailureLog("Visibilty items error")
                    return
                }
                LocalCalendarManager.updateCalSource(with: items)
            }).disposed(by: LocalCalendarManager.disposeBag)
        }
    }

    private static var eventStore: SafeAtomic<EKEventStore> = LocalCalendarManager.getEventStore() + .readWriteLock

    private static var allEKCalendars: SafeAtomic<[EKCalendar]> = [EKCalendar]() + .readWriteLock

    public enum LocalCalendarAuthorizationStatus {
        case authorized
        case pending
        case unauthorized
    }

    private static var authStatus = LocalCalendarAuthorizationStatus.unauthorized

    // MARK: 授权相关
    public static func isLocalCalendarAccessable() -> LocalCalendarAuthorizationStatus {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .authorized:
            authStatus = .authorized
        case .notDetermined:
            authStatus = .pending
        case .denied:
            authStatus = .unauthorized
        case .restricted:
            authStatus = .unauthorized
        #if swift(>=5.9)
        case .fullAccess:
            authStatus = .authorized
        case .writeOnly:
            authStatus = .unauthorized
        #endif
        @unknown default:
            assertionFailureLog()
        }
        operationLog(message: "authStatus: \(authStatus)")
        return authStatus
    }

    static func requireLocalCalendarAuthorization(for token: SensitivityControlToken, _ handler: @escaping (Bool) -> Void) {
        do {
            if #available(iOS 17.0, *) {
                operationLog(message: "call requestFullAccessToEvents")
                try CalendarEntry.requestFullAccessToEvents(forToken: token.LSCToken,
                                                            eventStore: LocalCalendarManager.eventStore.value,
                                                            completion: requestAccessCompletionHandler)
            } else {
                operationLog(message: "call requestAccess")
                try CalendarEntry.requestAccess(forToken: token.LSCToken,
                                                eventStore: LocalCalendarManager.eventStore.value,
                                                toEntityType: .event,
                                                completion: requestAccessCompletionHandler)
            }
        } catch {
            handler(false)
            SensitivityControlToken.logFailure("Cannot Get Calendar Authorization cause sensitivity control for \(token), error: \(error)")
        }
        
        func requestAccessCompletionHandler(result: Bool, e: Error?) {
            if let e = e {
                    assertionFailureLog("Cannot Get Calendar Authorization \(e)")
                } else if result {
                    LocalCalendarManager.authStatus = .authorized
                    operationLog(message: "require local calendar authorization success")

                    //after authorization, we need a new eventStore
                    LocalCalendarManager.eventStore.value = LocalCalendarManager.getEventStore()
                    // 授权成功后需要注册下日程更新的监听
                    LocalCalendarManager.registerObservers()
                    LocalCalendarManager.reloadCalendars()
                    handler(true)
                } else {
                    LocalCalendarManager.authStatus = .unauthorized
                    operationLog(message: "require local calendar authorization failed")
                    handler(false)
                }
        }

    }

    // MARK: 日历相关
    static func getAllLocalCalendars() -> Observable<[CalendarModel]> {
        return Observable.create({ (observable) -> Disposable in
            DispatchQueue.global().async {
                if LocalCalendarManager.isLocalCalendarAccessable() == .authorized {
                    let cals = LocalCalendarManager.getAllEKCalendars()
                    let calBGColors = cals.map { (calendar) -> CGColor in
                        calendar.cgColor ?? UIColor.ud.backgroundColor.cgColor
                    }
                    LocalCalHelper.preloadColors(colors: calBGColors)
                    let result = cals.map { (localCalendar) -> CalendarModel in
                        let calModel = CalendarFromLocal(localCalendar: localCalendar)
                        return calModel
                    }
                    observable.onNext(result)
                } else {
                    observable.onNext([CalendarModel]())
                }
                observable.onCompleted()
            }
            return Disposables.create()
        })
    }

    public static var eventStoreCalendars: [EKCalendar] = tryGetLocalCalendarsByStore(for: .preloadLocalCalendarOnSetup) ?? []

    private static func getAllEKCalendars() -> [EKCalendar] {
        if LocalCalendarManager.allEKCalendars.value.isEmpty {
            LocalCalendarManager.allEKCalendars.value = eventStoreCalendars
        }
        return LocalCalendarManager.allEKCalendars.value.filter { (calendar) -> Bool in
            guard let source = calendar.source else {
                return false
            }
            return LocalCalendarManager.isPublicSource(source, serverHost: serverHost.value)
        }
    }
    
    // 刷新本地日历
    public static func reloadCalendars() {
        eventStoreCalendars = tryGetLocalCalendarsByStore(for: .updateLocalCalendarsAfterAuth) ?? []
    }

    static func saveEvent(for token: SensitivityControlToken, event: CalendarEventEntity, span: Span) throws {
        guard let localSpan = span.toEKSpan(), let localEvent = event.getEKEvent() else {
            assertionFailureLog()
            return
        }
        try saveEvent(for: token, event: localEvent, span: localSpan)
    }

    static func saveEvent(for token: SensitivityControlToken, event: EKEvent, span: EKSpan?) throws {
        do {
            let originalLocalEvent = event
            let title = event.title
            let startDate = event.startDate
            let endDate = event.endDate
            let alarms = event.alarms
            let structuredLocation = event.structuredLocation
            let recurrenceRules = event.recurrenceRules
            let notes = event.notes
            if span == .thisEvent {
                event.removeRecurrence()
            }
            try CalendarEntry.save(forToken: token.LSCToken,
                                   eventStore: LocalCalendarManager.eventStore.value,
                                   event: event,
                                   span: span ?? .thisEvent,
                                   commit: true)
            DispatchQueue.global().async {
                originalLocalEvent.rollback()
                let titleChanged = title != originalLocalEvent.title
                let timeChanged = startDate != originalLocalEvent.startDate || endDate == originalLocalEvent.endDate
                let alertsChanged = alarms != originalLocalEvent.alarms
                let siteChanged = structuredLocation != originalLocalEvent.structuredLocation
                let repeatChanged = recurrenceRules != originalLocalEvent.recurrenceRules
                let descriptionChanged = notes != originalLocalEvent.notes
                CalendarTracer.shareInstance.editEvent(isTimeChanged: timeChanged,
                                                       isTitleChanged: titleChanged,
                                                       isAlarmsChanged: alertsChanged,
                                                       isSiteChanged: siteChanged,
                                                       isRepeatChanged: repeatChanged,
                                                       isDescChanged: descriptionChanged)
            }
        } catch {
            SensitivityControlToken.logFailure("save local event failed, may because sensitivity control for :\(token),  error: \(error)")
            assertionFailureLog("save local event failed, message = \(event.debugDescription), span = \(String(describing: span?.rawValue)), error = \(error)")
            throw(error)
        }
    }

    static func deleteEvent(for token: SensitivityControlToken, event: CalendarEventEntity, span: Span) throws {
        guard let localSpan = span.toEKSpan(), let localEvent = event.getEKEvent() else {
            assertionFailureLog()
            return
        }
        try deleteEvent(for: token, event: localEvent, span: localSpan)
    }

    static func deleteEvent(for token: SensitivityControlToken, event: EKEvent, span: EKSpan) throws {
        if span == .thisEvent {
            event.removeRecurrence()
        }
        try CalendarEntry.remove(forToken: token.LSCToken,
                             eventStore: LocalCalendarManager.eventStore.value,
                             event: event,
                             span: span,
                             commit: true)
        CalendarTracer.shareInstance.deleteEvent()
    }

    private static func isPublicSource(_ source: EKSource, serverHost: String) -> Bool {
        let sourceType = source.sourceType
        return (sourceType == .local ||
            sourceType == .exchange ||
            sourceType == .calDAV ||
            sourceType == .mobileMe ||
            sourceType == .subscribed)
    }

    // MARK: 日程实例相关
    private static func filterLocalEvents(localEvents: [EKEvent], filter: (EKEvent) -> Bool, timeZone: String?) -> [Local.Instance] {
        let calendar = TimeZoneUtil.getCalendar(timeZoneId: timeZone)
        return localEvents.compactMap({ (localEvent) -> Local.Instance? in
            if !filter(localEvent) {
                return nil
            }
            return localEvent
        })
    }

    static func firstTimeInit(for token: SensitivityControlToken) {
        // 初始化，读取本地日程前后七天日程
        guard !blockedLoad else {
            hasBlockedLoad = true
            operationLog(message: "Block calendar loading in the background!")
            return
        }
        hasBlockedLoad = false
        
        guard let localEvents = tryGetEventsByPredicate(for: token,
                                                       startTime: Date().addingTimeInterval(-7 * 24 * 60 * 60),
                                                       endTime: Date().addingTimeInterval(7 * 24 * 60 * 60),
                                                       eventStore: LocalCalendarManager.eventStore.value,
                                                       calendars: LocalCalendarManager.getAllEKCalendars()) else {
            return
        }
        if !localEvents.isEmpty && LocalCalendarManager.firstInit {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(2), execute: {
                if let targetEvent = localEvents.first(where: { (event) -> Bool in
                    event.getSelfAttendee() != nil
                }) {
                    LocalCalendarManager.firstInit = false
                    let eventVC = EKEventViewController()
                    eventVC.event = targetEvent
                    _ = eventVC.view
                }
            })
        }
    }

    private static func getLocalEventInstanceBetween(for token: SensitivityControlToken, starttime: Date, endtime: Date, filterHidden: Bool, timeZone: String?) -> [Local.Instance] {
        guard !blockedLoad else {
            hasBlockedLoad = true
            operationLog(message: "Block calendar loading in the background!")
            return []
        }
        hasBlockedLoad = false

        // 读取本地日程指定时间日程
        let localEvents: [EKEvent] = tryGetEventsByPredicate(for: token,
                                                             startTime: starttime,
                                                             endTime: endtime,
                                                             eventStore: LocalCalendarManager.eventStore.value,
                                                             calendars: LocalCalendarManager.getAllEKCalendars()) ?? []

        let shouldShowDeclinedEvent = SettingService.shared().getSetting().showRejectSchedule
        let filter: (EKEvent) -> Bool = { (event) -> Bool in
            //日历可见
            guard let calendar = event.calendar else {
                return false
            }
            if !LocalCalendarManager.isVisible(localCal: calendar) && filterHidden {
                return false
            }
            //无attendee则必为可见日程
            guard let selfAttendee = event.getSelfAttendee() else {
                return true
            }
            return !((selfAttendee.participantStatus.toCalendarEvnetAttendeeStatus() == .decline) && !shouldShowDeclinedEvent)
        }
        let result = LocalCalendarManager.filterLocalEvents(localEvents: localEvents, filter: filter, timeZone: timeZone)
        return result
    }

    private static func tryGetEventsByPredicate(for token: SensitivityControlToken,
                                                startTime: Date,
                                                endTime: Date,
                                                eventStore: EKEventStore,
                                                calendars: [EKCalendar]?) -> [EKEvent]? {

        do {
            let predicate = eventStore.predicateForEvents(withStart: startTime, end: endTime, calendars: calendars)
            return try CalendarEntry.events(forToken: token.LSCToken, eventStore: eventStore, matchingPredicate: predicate)
        } catch {
            SensitivityControlToken.logFailure("Failed to get events by predicate, because SensitivityControl for \(token), error: \(error)")
            return nil
        }
    }

    static func getLocalEventInstances(for token: SensitivityControlToken,
                                       startTime: Int64,
                                       endTime: Int64,
                                       filterHidden: Bool,
                                       timeZone: String?) -> Observable<[Local.Instance]> {
        guard LocalCalendarManager.isVisible() else { return .just([Local.Instance]()) }
        let localInstance = Observable.just(LocalCalendarManager.getLocalEventInstanceBetween(
            for: token,
            starttime: Date(timeIntervalSince1970: TimeInterval(startTime)),
            endtime: Date(timeIntervalSince1970: TimeInterval(endTime)),
            filterHidden: filterHidden,
            timeZone: timeZone))
        return localInstance
    }

    // MARK: 可见性相关

    static func getVisibiltyItems(scenarioToken: SensitivityControlToken) -> [LocalCalendarSettingControllerItem] {
        let sources = eventStore.value.sources.filter { (source) -> Bool in
            isPublicSource(source, serverHost: LocalCalendarManager.serverHost.value)
        }
        
        guard let statusDic = KVValues.localCalendarSource, !statusDic.isEmpty else {
            //初次使用
            var dic: [String: Bool] = [:]
            var calDic: [String: Bool] = [:]
            for source in sources {
                if source.sourceType == .birthdays || source.sourceType == .subscribed {
                    continue
                }
                dic[source.sourceIdentifier] = false
                if let realSource = tryGetLocalCalendarsBySource(for: scenarioToken, eventSource: source) {
                    for cal in realSource {
                        calDic[cal.calendarIdentifier] = true
                    }
                }
            }
            KVValues.localCalendarVisible = calDic
            KVValues.localCalendarSource = dic
            return sourceVisivilityConverter(visDic: dic, sources: sources)
        }
        return sourceVisivilityConverter(visDic: statusDic, sources: sources)
    }

    private static func updateCalSource(with visibiltyItems: [LocalCalendarSettingControllerItem]) {
        let newStatusDic = sourceVisivilityConverter(localItems: visibiltyItems)
        KVValues.localCalendarSource = newStatusDic
    }

    static func updateLocalCalSourceVisibilty(for token: SensitivityControlToken) {

        guard let statusDic = KVValues.localCalendarSource,
              let calDic = KVValues.localCalendarVisible else {
                //not inited, so no need to update, return
                return
        }

        let sources = eventStore.value.sources.filter { (source) -> Bool in
            isPublicSource(source, serverHost: serverHost.value) && source.sourceType != .subscribed
        }

        var newStatusDic: [String: Bool] = [:]
        var newCalDic: [String: Bool] = [:]
        for source in sources {
            if source.sourceType == .birthdays || source.sourceType == .subscribed {
                continue
            }
            newStatusDic[source.sourceIdentifier] = statusDic[source.sourceIdentifier] ?? false

            if let realSource = tryGetLocalCalendarsBySource(for: token, eventSource: source) {
                for cal in realSource {
                    newCalDic[cal.calendarIdentifier] = calDic[cal.calendarIdentifier] ?? true
                }
            }
        }
        KVValues.localCalendarVisible = newCalDic
        KVValues.localCalendarSource = newStatusDic
    }

    private static func getlocalCalVisibility() -> [LocalCalSidebarModel] {
        guard let sourceDic = KVValues.localCalendarSource,
            let calDic = KVValues.localCalendarVisible else {
            return []
        }
        let cals = LocalCalendarManager.getAllEKCalendars().filter { $0.type != .birthday }
        let result = cals.compactMap { (calendar) -> LocalCalSidebarModelImpl? in
            //订阅日历源和生日日历源不可见
            guard let source = calendar.source else {
                return nil
            }
            if source.sourceType == .subscribed || source.sourceType == .birthdays {
                return nil
            }
            if sourceDic[source.sourceIdentifier] == false {
                return nil
            }
            let selected = calDic[calendar.calendarIdentifier] == true
            let colorIndex = LocalCalHelper.getColor(color: calendar.cgColor ?? UIColor.ud.udtokenColorpickerCarmine.cgColor)
            let color = SkinColorHelper.pickerColor(of: colorIndex.rawValue)

            return LocalCalSidebarModelImpl(title: calendar.title,
                                            sourceTitle: source.title,
                                            color: color,
                                            selected: selected,
                                            calIdentifier: calendar.calendarIdentifier,
                                            calSourceIdentifier: source.sourceIdentifier)
        }
        return result
    }

    static func isVisible() -> Bool {
        guard let sourceDic = KVValues.localCalendarSource,
              let calDic = KVValues.localCalendarVisible else {
            return false
        }
        let hasSource = !sourceDic.filter { (_, value) -> Bool in
            return value == true
        }.isEmpty

        let hasCalendar = !calDic.filter { (_, value) -> Bool in
            return value == true
        }.isEmpty

        return hasSource && hasCalendar
    }

    static func isVisible(localCal: EKCalendar) -> Bool {
        guard let sourceDic = KVValues.localCalendarSource,
            let calDic = KVValues.localCalendarVisible else {
                return false
        }
        return (sourceDic[localCal.source.sourceIdentifier] ?? false) && (calDic[localCal.calendarIdentifier] ?? false)
    }

    static func getLocalCalendarGroupedVisibility()
        -> [LocalCalSideBarSourceModel: [LocalCalSidebarModel]] {
        let ogData = getlocalCalVisibility()
        if ogData.isEmpty {
            return [:]
        }
        var dic: [LocalCalSideBarSourceModel: [LocalCalSidebarModel]] = [:]
        for model in ogData {
            let localCalSideBarSourceModel = LocalCalSideBarSourceModel(title: model.sourceTitle,
                                                                        id: model.calSourceIdentifier)
            if var models = dic[localCalSideBarSourceModel] {
                models.append(model)
                dic[localCalSideBarSourceModel] = models
            } else {
                dic[localCalSideBarSourceModel] = [model]
            }
        }
        return dic
    }

    static func changeCalVisibility(calID: String, visible: Bool) -> Observable<Bool> {
        return Observable.create({ (observer) -> Disposable in
            guard var calDic = KVValues.localCalendarVisible else {
                assertionFailureLog()
                observer.onNext((false))
                return Disposables.create()
            }
            calDic[calID] = visible
            KVValues.localCalendarVisible = calDic
            observer.onNext((true))
            return Disposables.create()
        })
    }

    static func hideAllIfVisible() -> Observable<Bool> {
        return Observable.create({ (observer) -> Disposable in
            guard var calDic = KVValues.localCalendarVisible else {
                assertionFailureLog()
                observer.onNext((false))
                return Disposables.create()
            }
            KVValues.localCalendarVisible = calDic.mapValues { _ in false }
            observer.onNext((true))
            return Disposables.create()
        })
    }

    private static func sourceVisivilityConverter(visDic: [String: Bool], sources: [EKSource]) -> [LocalCalendarSettingControllerItem] {
        var result: [LocalCalendarSettingControllerItem] = []
        for (identifier, status) in visDic {
            if let source = sources.first(where: { $0.sourceIdentifier == identifier }) {
                let impl = LocalCalendarSettingControllerItemImpl(title: source.title, isSelected: status, sourceIdentifier: identifier)
                result.append(impl)
            }
        }
        return result
    }

    private static func sourceVisivilityConverter(localItems: [LocalCalendarSettingControllerItem]) -> [String: Bool] {
        guard var statusDic = KVValues.localCalendarSource else {
            assertionFailureLog()
            return [:]
        }
        for item in localItems {
            statusDic[item.sourceIdentifier] = item.isSelected
        }
        return statusDic
    }

    /// signal for notification
    static let eventStoreChangedSubject = PublishSubject<Void>()

    @objc
    static func receiveNotification() {
        guard self.authStatus == .authorized else {
            return
        }
        // 本地日程更新
        eventStoreChangedSubject.onNext(())
        updateLocalCalSourceVisibilty(for: .updateCalendarSourceVisibilityWhenSystemNotified)
        LocalCalendarManager.updateEKCalendars(for: .updateLocalCalendarWhenSystemNotified)
    }

    static func updateEKCalendars(for token: SensitivityControlToken) {
        let taskHandler: (ViewPageDowngradeTaskManager.TaskResult) -> Void = { _ in
            if let calendars = tryGetLocalCalendarsByStore(for: token) {
                LocalCalendarManager.allEKCalendars.value = calendars
            }
        }
        // 低端机延迟
        ViewPageDowngradeTaskManager.addTask(scene: .updateEKCalendars,
                                             way: .delay1s,
                                            taskHandler)
    }

    // 敏感 API 管控封装
    private static func tryGetLocalCalendarsByStore(for token: SensitivityControlToken,
        eventStore: EKEventStore = LocalCalendarManager.eventStore.value) -> [EKCalendar]? {
        do {
            return try CalendarEntry.calendars(forToken: token.LSCToken, eventStore: eventStore, forEntityType: .event)
        } catch {
            SensitivityControlToken.logFailure("Failed to read local calendars, because SensitivityControl for \(token), error: \(error)")
            return nil
        }
    }

    // 敏感 API 管控封装
    private static func tryGetLocalCalendarsBySource(for token: SensitivityControlToken,
                                                     eventSource: EKSource) -> Set<EKCalendar>? {
        do {
            return try CalendarEntry.calendars(forToken: token.LSCToken, source: eventSource, entityType: .event)
        } catch {
            SensitivityControlToken.logFailure("Failed to read local calendars, because SensitivityControl for \(token), error: \(error)")
            return nil
        }
    }


    static func getEvent(for token: SensitivityControlToken, by identifier: String) -> CalendarEventEntity? {
        do {
            if let event = try CalendarEntry.event(forToken: token.LSCToken, eventStore: eventStore.value, identifier: identifier) {
                return CalendarEventEntityFromLocal(event: event)
            } else {
                return nil
            }
        } catch {
            SensitivityControlToken.logFailure("Failed to read local event by \(identifier), because SensitivityControl for \(token), error: \(error)")
            return nil
        }
    }

}

extension LocalCalendarManager {
    static func setCalDavDomain(_ calDavDomain: String) {
        LocalCalendarManager.serverHost.value = calDavDomain
    }
}

extension Span {
    func toEKSpan() -> EKSpan? {
        switch self {
        case .noneSpan:
            return EKSpan.thisEvent
        case .thisEvent:
            return EKSpan.thisEvent
        case .futureEvents:
            return EKSpan.futureEvents
        case .allEvents:
            assertionFailureLog()
            return nil
        @unknown default:
            return nil
        }
    }
}

extension LocalCalendarManager{
    
    static var hasBlockedLoad = false
    
    // 如果当前状态是非活跃或者是后台状态，则进行阻塞加载
    static var blockedLoad = false

}
