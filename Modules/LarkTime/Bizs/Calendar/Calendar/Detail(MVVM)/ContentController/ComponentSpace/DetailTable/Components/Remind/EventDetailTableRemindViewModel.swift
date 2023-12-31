//
//  EventDetailTableRemindViewModel.swift
//  Calendar
//
//  Created by Rico on 2021/4/7.
//

import Foundation
import LarkContainer
import LarkCombine
import RxSwift

final class EventDetailTableRemindViewModel: EventDetailComponentViewModel {

    @ScopedInjectedLazy
    var calendarDependency: CalendarDependency?

    var model: EventDetailModel { context.rxModel.value }
    let viewData = CurrentValueSubject<EventDetailTableRemindViewDataType?, Never>(nil)
    private let disposeBag = DisposeBag()

    @ContextObject(\.rxModel) var rxModel

    override init(context: EventDetailContext, userResolver: UserResolver) {
        super.init(context: context, userResolver: userResolver)

        bindRx()
    }

    private func bindRx() {
        rxModel.subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            self.buildViewData()
        })
        .disposed(by: disposeBag)
    }

    var is12HourStyle: Bool {
        calendarDependency?.is12HourStyle.value ?? true
    }
}

extension EventDetailTableRemindViewModel {
    struct ViewData: EventDetailTableRemindViewDataType {
        let remind: String
    }

    private func buildViewData() {
        let data = ViewData(remind: getRemindString())
        EventDetail.logInfo("remind info: \(data.remind)")
        viewData.send(data)
    }
}

extension EventDetailTableRemindViewModel {
    func getRemindString() -> String {
        let reminders: [Reminder]
        let isAllDay: Bool
        switch model {
        case let .local(event):
            reminders = event.alarms?.map { (alarm) -> Reminder in
                return Reminder(minutes: Int32(-1 * alarm.relativeOffset / 60), isAllDay: event.isAllDay)
            } ?? []
            isAllDay = event.isAllDay
        case let .pb(event, _):
            reminders = event.reminders.map { Reminder(pb: $0, isAllDay: event.isAllDay) }
            isAllDay = event.isAllDay
        case .meetingRoomLimit:
            EventDetail.logUnreachableLogic()
            reminders = []
            isAllDay = false
        }
        return Reminder.description(of: reminders, isAllDay: isAllDay, is12HourStyle: is12HourStyle)
    }
}
