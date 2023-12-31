//
//  KVValues.swift
//  Calendar
//
//  Created by zhuheng on 2021/3/4.
//

import Foundation
import LarkContainer
import LarkUIKit
import LarkStorage
import LarkSetting

struct KVValues {

    @Provider static var calendarDependency: CalendarDependency
    private static let globalStore = KVStores.udkv(space: .global, domain: Domain.biz.calendar)

    private static func userStore() -> KVStore {
        guard let userSpace = calendarDependency.userSpace else {
            assertionFailure("unexpected logic")
            return globalStore
        }
        return KVStores.in(space: userSpace).in(domain: Domain.biz.calendar).udkv()
    }

    @KVConfig(key: "CalendarDayViewMode", default: Display.pad ? 5 : 3, store: .dynamic(userStore))
    static var calendarDayViewMode: Int

    @KVConfig(key: "VISIBLECALSOURCEKEY", store: globalStore)
    static var localCalendarSource: [String: Bool]?

    @KVConfig(key: "VISIBLECALKEY", store: globalStore)
    static var localCalendarVisible: [String: Bool]?

    @KVConfig(key: "calendar_last_used_entry", store: .dynamic(userStore))
    static var lastUsedEntry: String?

    @KVConfig(key: "hasCalendarCache", default: false, store: .dynamic(userStore))
    static var hasCalendarCache: Bool

    @KVConfig(key: "calendar_has_shown_oauth_dialog", default: false, store: .dynamic(userStore))
    static var hasShownOAuthDialog: Bool
    
    @KVConfig(key: "calendar_has_shown_go_setting_dialog", default: false, store: .dynamic(userStore))
    static var hasShownGoSettingDialog: Bool

    @KVConfig(key: "calendar_selected_additional_timezone", default: "", store: .dynamic(userStore))
    static var selectedAdditionalTimeZone: String

    @KVConfig(key: "calendar_did_additional_timezone_upgrade", default: false, store: .dynamic(userStore))
    static var didAdditionalTimeZoneUpgrade: Bool

    @KVConfig(key: "calendar_is_show_additional_timezone", default: false, store: .dynamic(userStore))
    static var isShowAdditionalTimeZone: Bool

    static let externalCalendarVisibleKey = KVKey<[String: Bool]?>("ExternalCalendarVisibleKey")

    static func getExternalCalendarVisible(accountName: String) -> Bool {
        let store = userStore()
        return store[externalCalendarVisibleKey]?[accountName] ?? true
    }

    static func setExternalCalendarVisible(accountName: String, isVisible: Bool) {
        let store = userStore()
        var visibleCalendars = store[externalCalendarVisibleKey] ?? [:]
        visibleCalendars[accountName] = isVisible
        store[externalCalendarVisibleKey] = visibleCalendars
    }

}

// KKValues 用户态改造CalendarAssembly
//final class CalendarUserDefault {
//    private static let userStore = \CalendarUserDefault._userStore
//    private static let globalStore = \CalendarUserDefault._globalStore
//
//    private let _globalStore: KVStore
//    private let _userStore: KVStore
//
//    init(userResolver: UserResolver) {
//        self._userStore = userResolver.udkv(domain: Domain.biz.calendar)
//        self._globalStore = KVStores.udkv(space: .global, domain: Domain.biz.calendar)
//    }
//
//    @KVBinding(to: userStore, key: "CalendarDayViewMode", default: Display.pad ? 5 : 3)
//    var calendarDayViewMode: Int
//
//    @KVBinding(to: globalStore, key: "VISIBLECALSOURCEKEY")
//    var localCalendarSource: [String: Bool]?
//
//    @KVBinding(to: globalStore, key: "VISIBLECALKEY")
//    var localCalendarVisible: [String: Bool]?
//
//    @KVBinding(to: userStore, key: "calendar_last_used_entry")
//    var lastUsedEntry: String?
//
//    @KVBinding(to: userStore, key: "hasCalendarCache", default: false)
//    var hasCalendarCache: Bool
//
//    @KVBinding(to: userStore, key: "calendar_has_shown_oauth_dialog", default: false)
//    var hasShownOAuthDialog: Bool
//
//    @KVBinding(to: userStore, key: "calendar_has_shown_go_setting_dialog", default: false)
//    var hasShownGoSettingDialog: Bool
//
//    let externalCalendarVisibleKey = KVKey<[String: Bool]?>("ExternalCalendarVisibleKey")
//
//    func getExternalCalendarVisible(accountName: String) -> Bool {
//        return self._userStore.value(forKey: externalCalendarVisibleKey)?[accountName] ?? true
//    }
//
//    func setExternalCalendarVisible(accountName: String, isVisible: Bool) {
//        let store = _userStore
//        var visibleCalendars = store[externalCalendarVisibleKey] ?? [:]
//        visibleCalendars[accountName] = isVisible
//        store[externalCalendarVisibleKey] = visibleCalendars
//    }
//}
