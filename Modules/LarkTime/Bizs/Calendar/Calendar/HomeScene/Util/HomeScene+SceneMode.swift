//
//  HomeScene+SceneMode.swift
//  Calendar
//
//  Created by 张威 on 2020/10/12.
//

import UIKit
import LarkUIKit

/// Home Scene Mode

extension HomeScene {
    enum SceneMode {
        /// day 视图的类型
        enum DayCategory {
            /// 单日
            case single
            /// 三日
            case three
            /// 周
            case week

            /// 每个 scene 显示的天数
            var daysPerScene: Int {
                switch self {
                case .single: return 1
                case .three: return 3
                case .week: return 7
                }
            }
        }

        /// 日/三日/周视图
        case day(DayCategory)

        /// 月视图
        case month

        /// 列表视图
        case list
    }
}

typealias HomeSceneMode = HomeScene.SceneMode

// MARK: - RawRepresentable & Equatable

extension HomeSceneMode.DayCategory: RawRepresentable {
    var rawValue: Int {
        switch self {
        case .single: return DayViewSwitcherMode.singleDay.rawValue
        case .three: return DayViewSwitcherMode.threeDay.rawValue
        case .week: return DayViewSwitcherMode.week.rawValue
        }
    }

    init?(rawValue: Int) {
        switch rawValue {
        case Self.single.rawValue: self = .single
        case Self.three.rawValue: self = .three
        case Self.week.rawValue: self = .week
        default: return nil
        }
    }
}

extension HomeSceneMode: RawRepresentable, Equatable {

    var rawValue: Int {
        switch self {
        case .day(let cate): return cate.rawValue
        case .list: return DayViewSwitcherMode.schedule.rawValue
        case .month: return DayViewSwitcherMode.month.rawValue
        }
    }

    init?(rawValue: Int) {
        if let dayCate = DayCategory(rawValue: rawValue) {
            self = .day(dayCate)
            return
        }
        if Self.month.rawValue == rawValue {
            self = .month
            return
        }
        if Self.list.rawValue == rawValue {
            self = .list
            return
        }
        return nil
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }

}

// MARK: - main property

extension HomeSceneMode {

    private static func initMode() -> Self {
        if let sceneMode = HomeSceneMode(rawValue: KVValues.calendarDayViewMode) {
           return sceneMode
        }
        return .day(.three)
    }

    static var current = initMode() {
        didSet {
            assert(Thread.isMainThread)
            guard oldValue != current else { return }
            KVValues.calendarDayViewMode = current.rawValue
            NotificationCenter.default.post(sceneModeChangedNotification)
        }
    }

    // sceneMode 变化了
    static let sceneModeChangedNotification = Notification(name: .init("lark.calendar.sceneModeChanged"))
}

extension HomeSceneMode {

    private static let isPad = Display.pad

    /// 视图页 scene mode 说明：
    /// - phone
    ///   - 列表视图，月视图，日视图，三日视图（排名不分先后）
    /// - pad
    ///   - regular
    ///     - 列表视图，月视图，日视图，周视图（排名不分先后）
    ///   - compact
    ///     - width 小于等于 320
    ///       - 列表视图，月视图，日视图（排名不分先后）
    ///     - width 大于 320
    ///       - 列表视图，月视图，日视图，三日视图（排名不分先后）
    ///
    /// Ref:
    ///   - https://developer.apple.com/design/human-interface-guidelines/ios/visual-design/adaptivity-and-layout/
    ///   - https://developer.apple.com/documentation/uikit/uitraitcollection
    ///

    /// 当前可用的 scene modes
    static func availableModes(
        withSizeClass horizontalSizeClass: UIUserInterfaceSizeClass,
        displayWidth: CGFloat
    ) -> [HomeSceneMode] {
        guard isPad else {
            return [.list, .day(.single), .day(.three), .month]
        }
        if horizontalSizeClass == .regular {
            return [.list, .day(.single), .day(.week), .month]
        }
        if displayWidth >= 320.1 {
            return [.list, .day(.single), .day(.three), .month]
        } else {
            return [.list, .day(.single), .month]
        }
    }

    static func fixedMode(
        from mode: HomeSceneMode,
        withSizeClass horizontalSizeClass: UIUserInterfaceSizeClass,
        displayWidth: CGFloat
    ) -> HomeSceneMode {
        let modes = self.availableModes(withSizeClass: horizontalSizeClass, displayWidth: displayWidth)
        guard !modes.contains(mode) else { return mode }
        guard case .day = mode else { return mode }
        let dayCates: [DayCategory] = [.week, .three, .single]
        guard let targetCate = dayCates.first(where: { modes.contains(.day($0)) }) else {
            assertionFailure()
            return mode
        }
        return .day(targetCate)
    }

}

// MARK: Compatible

enum DayViewSwitcherMode: Int {
    case singleDay = 1
    case schedule = 2
    case threeDay = 3
    case month = 4
    case week = 5
}

final class CalendarDayViewSwitcher {
    let mode: DayViewSwitcherMode

    init() {
        mode = HomeSceneMode.current.convertToOldType()
    }
}

extension HomeSceneMode {

    typealias OldType = DayViewSwitcherMode

    init(from oldType: OldType) {
        self = HomeSceneMode(rawValue: oldType.rawValue) ?? .day(.three)
    }

    func convertToOldType() -> OldType {
        OldType(rawValue: rawValue)!
    }

}
