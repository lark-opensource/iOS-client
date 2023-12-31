//
//  DetailTimeViewModel.swift
//  Todo
//
//  Created by 张威 on 2021/10/18.
//

import Foundation
import RxSwift
import RxCocoa
import LarkContainer
import CTFoundation

/// Detail - Follower - ViewModel

final class DetailTimeViewModel: UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver
    let rxViewData: BehaviorRelay<DetailDueTimeViewData?>
    let store: DetailModuleStore

    private let disposeBag = DisposeBag()
    private let rxPerferQuick = BehaviorRelay(value: false)
    @ScopedInjectedLazy private var timeService: TimeService?
    @ScopedInjectedLazy private var settingService: SettingService?

    private var timeZone: TimeZone { timeService?.rxTimeZone.value ?? .current }
    private var is12HourStyle: Bool { timeService?.rx12HourStyle.value ?? false }
    private var defaultDueTimeDayOffset: Int64 { settingService?.defaultDueTimeDayOffset ?? 0 }
    private var dueReminderOffset: Int64 { settingService?.value(forKeyPath: \.dueReminderOffset) ?? 0 }

    init(resolver: UserResolver, store: DetailModuleStore) {
        self.userResolver = resolver
        self.store = store
        self.rxViewData = .init(value: nil)
    }

    func setup() {
        bindViewData()
    }

    private func bindViewData() {
        let transform = { [weak self] (startTime: Int64?, dueTime: Int64?, preferQuick: Bool, reminder: Reminder?, rrule: String?, isAllDay: Bool, permission: PermissionOption) -> DetailDueTimeViewData? in
            guard let self = self else { return nil }
            var startTimeText: String?, dueTimeText: String?
            var textColor = UIColor.ud.textTitle, iconColor = UIColor.ud.iconN1
            if FeatureGating(resolver: self.userResolver).boolValue(for: .startTime), let start = startTime, start > 0, let due = dueTime, due > 0 {
                startTimeText = self.formatTime(start, isAllDay)
                dueTimeText = self.formatTime(due, isAllDay)
            } else if FeatureGating(resolver: self.userResolver).boolValue(for: .startTime), let start = startTime, start > 0 {
                startTimeText = I18N.Todo_TaskStartsFrom_Text(self.formatTime(start, isAllDay))
            } else if let due = dueTime, due > 0 {
                dueTimeText = I18N.Todo_Task_TimeDue(self.formatTime(due, isAllDay))
            }
            if let due = dueTime, due > 0, let color = self.timeColor(due, isAllDay) {
                textColor = color
                iconColor = color
            }

            let hasReminder = reminder?.hasReminder ?? false
            let isFromDoc = (self.store.state.todo?.source == .doc)
            var hasRepeat = false
            if let rrule = rrule {
                hasRepeat = !rrule.isEmpty
            }
            let hasClearBtn = permission.isEditable || isFromDoc
            let isClearBtnDisable = !permission.isEditable
            let hasQuick = preferQuick ? preferQuick : (dueTimeText.isEmpty && permission.isEditable)
            return DetailDueTimeViewData(
                startTimeText: startTimeText,
                dueTimeText: dueTimeText,
                preferQuick: hasQuick,
                hasReminder: hasReminder,
                hasRepeat: hasRepeat,
                hasClearBtn: hasClearBtn,
                isClearBtnDisable: isClearBtnDisable,
                textColor: textColor,
                iconColor: iconColor
            )
        }
        Observable.combineLatest(
            store.rxValue(forKeyPath: \.startTime),
            store.rxValue(forKeyPath: \.dueTime),
            rxPerferQuick,
            store.rxValue(forKeyPath: \.reminder),
            store.rxValue(forKeyPath: \.rrule),
            store.rxValue(forKeyPath: \.isAllDay),
            store.rxValue(forKeyPath: \.permissions).distinctUntilChanged(\.dueTime)
        )
        .compactMap { transform($0.0, $0.1, $0.2, $0.3, $0.4, $0.5, $0.6.dueTime) }
        .bind(to: rxViewData)
        .disposed(by: disposeBag)
    }

    private func formatTime(_ time: Int64, _ isAllDay: Bool) -> String {
       return Utils.DueTime.formatedString(
            from: time,
            in: timeZone,
            isAllDay: isAllDay,
            is12HourStyle: is12HourStyle
        )
    }

    private func timeColor(_ dueTime: Int64, _ isAllDay: Bool) -> UIColor? {
        let context = TimeContext(
            currentTime: Int64(Date().timeIntervalSince1970),
            timeZone: timeZone,
            is12HourStyle: is12HourStyle
        )
        var time = dueTime
        if isAllDay {
            time = Utils.TimeFormat.lastSecondForAllDay(dueTime, timeZone: context.timeZone)
        }
        switch V3ListTimeGroup.dueTime(dueTime: time, timeContext: context) {
        case .overDue: return UIColor.ud.functionDangerContentDefault
        case .today: return UIColor.ud.primaryContentDefault
        default: return nil
        }
    }

    /// 内容被点击
    enum ClickContentViewMessage {
        /// tip
        case alert(String)
        /// 新版时间选择页
        case picker(TimeComponents?)
        /// 无反应
        case none
    }

    func clickContentViewMessage() -> ClickContentViewMessage {
        let state = store.state
        if !state.permissions.dueTime.isEditable {
            if case .doc = state.todo?.source {
                return .alert(I18N.Todo_Task_UnableEditTaskFromDocs)
            } else {
                return .alert(I18N.Todo_Task_NoEditAccess)
            }
        } else {
            // do track
            if state.scene.isForCreating {
                Detail.tracker(.todo_create_date_click)
            }
            Detail.tracker(
                .todo_date_click,
                params: [
                    "source": state.scene.isForCreating ? "create" : "detail",
                    "task_id": state.scene.todoId ?? "",
                    "state": state.dueTime == nil ? "no" : "yes",
                    "time_type": state.dueTime == nil ? "other" : ""
                ]
            )
            if (state.startTime ?? 0) <= 0, (state.dueTime ?? 0) <= 0 {
                return .picker(nil)
            }

            let comps = TimeComponents(
                startTime: (state.startTime ?? 0) > 0 ? state.startTime : nil,
                dueTime: (state.dueTime ?? 0) > 0 ? state.dueTime : nil,
                reminder: state.reminder,
                isAllDay: state.isAllDay,
                rrule: state.rrule
            )
            return .picker(comps)
        }
    }

    /// 空白被点击
    enum ClickEmptyViewMessage {
        /// 展示快速入口
        case showQuick
        /// 展示 disable alert
        case alertDisable(String)
    }

    func emptyContentViewMessage() -> ClickEmptyViewMessage {
        if store.state.permissions.dueTime.isEditable {
            return .showQuick
        } else {
            let isFromDoc = (store.state.todo?.source == .doc)
            let tip = isFromDoc ? I18N.Todo_Task_UnableEditTaskFromDocs : I18N.Todo_Task_NoEditAccess
            return .alertDisable(tip)
        }
    }

    func updatePickedTimeComponents(_ timeComps: TimeComponents) {
        // track
        if store.state.scene.isForCreating {
            Detail.tracker(.todo_create_date_select)
        }
        store.dispatch(.updateTime(timeComps))
    }

    func showQuickSelect() {
        rxPerferQuick.accept(true)
    }

    /// 删除时间
    func clearTime() {
        Detail.tracker(
            .todo_task_date_delete,
            params: ["task_id": store.state.scene.todoId ?? ""]
        )
        rxPerferQuick.accept(false)
        store.dispatch(.clearTime)
    }

    /// 快速选择今天
    func quickSelectToday() {
        trackQuickSelect(type: "today")
        quickSelect(.today)
    }

    /// 快速选择明天
    func quickSelectTomorrow() {
        trackQuickSelect(type: "tomorrow")
        quickSelect(.tomorrow)
    }

    private func quickSelect(_ type: V3ListTimeGroup.DueTime) {
        let timestamp = type.defaultDueTime(
            by: defaultDueTimeDayOffset,
            timeZone: timeZone,
            isAllDay: FeatureGating(resolver: userResolver).boolValue(for: .startTime)
        )
        var offset = dueReminderOffset
        if FeatureGating(resolver: userResolver).boolValue(for: .startTime) {
            offset = AllDayReminder.onDayofEventAt6pm.rawValue
        }
        offset = Utils.Reminder.fixReminder(by: timestamp, offset: offset)

        var timeComps = TimeComponents(
            startTime: nil,
            dueTime: timestamp,
            reminder: .relativeToDueTime(offset),
            isAllDay: FeatureGating(resolver: userResolver).boolValue(for: .startTime)
        )
        if Utils.Reminder.isReminderInValid(timeComps, timeZone: timeZone) {
            timeComps.reminder = nil
        }
        store.dispatch(.updateTime(timeComps))
    }

    private func trackQuickSelect(type: String) {
        let state = store.state
        Detail.tracker(
            .todo_date_click,
            params: [
                "source": state.scene.isForCreating ? "create" : "detail",
                "task_id": state.scene.todoId ?? "",
                "state": state.dueTime == nil ? "no" : "yes",
                "time_type": type
            ]
        )
    }

}
