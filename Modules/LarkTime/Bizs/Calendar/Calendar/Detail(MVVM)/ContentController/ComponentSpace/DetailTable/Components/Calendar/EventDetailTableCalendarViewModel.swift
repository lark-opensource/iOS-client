//
//  EventDetailTableCalendarViewModel.swift
//  Calendar
//
//  Created by Rico on 2021/3/27.
//

import Foundation
import LarkCombine
import LarkContainer
import RxSwift
import RxRelay
import RustPB

final class EventDetailTableCalendarViewModel: EventDetailComponentViewModel {

    @ScopedInjectedLazy var calendarManager: CalendarManager?

    private var model: EventDetailModel { context.rxModel.value }
    private var calendar: EventDetail.Calendar {
        guard let calendar = model.getCalendar(calendarManager: calendarManager) else {
            EventDetail.logError("can not get calendar")
            return CalendarModelFromPb(pb: Calendar_V1_Calendar())
        }
        return calendar
    }

    private let disposeBag = DisposeBag()

    @ContextObject(\.rxModel) var rxModel

    let viewData = CurrentValueSubject<EventDetailTableCalendarViewDataType?, Never>(ViewData(calendarName: "", isResigned: false))

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
}

extension EventDetailTableCalendarViewModel {
    struct ViewData: EventDetailTableCalendarViewDataType {
        let calendarName: String
        let isResigned: Bool
    }

    private func buildViewData() {

        viewData.send(getCalendarViewData())
    }

    private func getCalendarViewData() -> ViewData? {
        switch model {
        case let .local(ekEvent):
            return ViewData(calendarName: ekEvent.calendar?.title ?? "", isResigned: false)
        case let .pb(event, _):
            let successorChatterID = calendar.getCalendarPB().successorChatterID
            let normalIsResigned = !(successorChatterID.isEmpty || successorChatterID == "0") && calendar.getCalendarPB().type == .other

            let calendarName = isResourceEvent ? calendar.summary : calendar.displayName()
            let isResigned = (isResourceEvent || event.dt.isThirdParty) ? false : normalIsResigned

            return ViewData(calendarName: calendarName, isResigned: isResigned)
        case .meetingRoomLimit: return nil
        }
    }

    private var isResourceEvent: Bool {
        // 历史代码缺失相关逻辑，对齐安卓
        let isLimited: Bool
        switch model {
        case let .pb(event, _): isLimited = event.displayType == .limited
        case let .local(ekEvent): isLimited = (ekEvent.calendar?.type ?? .subscription == .subscription ? true : false)
        case .meetingRoomLimit: isLimited = true
        }
        return isLimited && (calendar.type == .resources || calendar.type == .googleResource)
    }
}
