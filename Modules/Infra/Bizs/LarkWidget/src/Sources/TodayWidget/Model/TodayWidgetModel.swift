//
//  TodayWidgetModel.swift
//  LarkWidget
//
//  Created by Hayden Wang on 2022/3/18.
//

import Foundation

public struct TodayWidgetModel: Codable, Equatable {
    public var isMinimumMode: Bool
    public var isLogin: Bool
    public var hasEvent: Bool
    public var event: CalendarEvent
    public var actions: [TodayWidgetAction]
    public init(isMinimumMode: Bool = false,
                isLogin: Bool,
                hasEvent: Bool,
                event: CalendarEvent,
                actions: [TodayWidgetAction]) {
        self.isMinimumMode = isMinimumMode
        self.isLogin = isLogin
        self.hasEvent = hasEvent
        self.event = event
        self.actions = actions
    }

    /// 未开放的Entry, 基本模式亦可使用
    public static let minimumModeModel = TodayWidgetModel(isMinimumMode: true,
                                                          isLogin: false,
                                                          hasEvent: false,
                                                          event: .emptyEvent,
                                                          actions: [])
    /// 未开放的Entry, 基本模式亦可使用
    public static let inProgressModel = TodayWidgetModel(isMinimumMode: true,
                                                         isLogin: false,
                                                         hasEvent: false,
                                                         event: .emptyEvent,
                                                         actions: [])
    /// 无日程的Entry
    public static let noEventModel = TodayWidgetModel(isLogin: true,
                                                      hasEvent: false,
                                                      event: .emptyEvent,
                                                      actions: Self.defaultActions)
    /// 添加Widget页面的Entry
    public static let snapShotModel = TodayWidgetModel(isLogin: true,
                                                       hasEvent: true,
                                                       event: .snapShotEvent,
                                                       actions: Self.defaultActions)
    /// 未登录的Entry
    public static let notLoginModel = TodayWidgetModel(isLogin: false,
                                                       hasEvent: false,
                                                       event: .emptyEvent,
                                                       actions: [])

    public static var defaultActions: [TodayWidgetAction] {
        [.searchAction, .scanAction, .workplaceMainAction]
    }
}
