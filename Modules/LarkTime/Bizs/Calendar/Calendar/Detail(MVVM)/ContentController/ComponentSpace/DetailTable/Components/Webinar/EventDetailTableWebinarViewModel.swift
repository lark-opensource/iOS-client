//
//  EventDetailTableWebinarViewModel.swift
//  Calendar
//
//  Created by tuwenbo on 2022/11/1.
//

import UIKit
import RxSwift
import LarkCombine
import LarkContainer
import LarkLocalizations

class EventDetailTableWebinarViewModel: EventDetailComponentViewModel {

    var model: EventDetailModel { rxModel.value }
    let viewData = CurrentValueSubject<ViewData, Never>(.loading)
    let route = PassthroughSubject<Route, Never>()
    var calendar: EventDetail.Calendar?
    let disposeBag = DisposeBag()

    @ScopedInjectedLazy var calendarManager: CalendarManager?
    @ScopedInjectedLazy var calendarDependency: CalendarDependency?
    @ScopedInjectedLazy var calendarApi: CalendarRustAPI?
    @ContextObject(\.rxModel) var rxModel

    override init(context: EventDetailContext, userResolver: UserResolver) {
        super.init(context: context, userResolver: userResolver)
        calendar = calendarManager?.calendar(with: context.rxModel.value.calendarId)
        bindRx()
    }

    private func bindRx() {
        rxModel.subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            self.buildViewData()
        })
        .disposed(by: disposeBag)
    }

    // 必须被 override
    func buildWebinarViewData() -> ViewData {
        assert(false, "buildWebinarViewData() has not been implemented")
        return .hidden
    }

    // 必须被 override
    func buildAttendeeListViewModel() -> EventAttendeeListViewModel? {
        assert(false, "buildAttendeeListViewModel() has not been implemented")
        return EventAttendeeListViewModel(userResolver: self.userResolver, attendees: [], isLarkEvent: false, currentTenantId: "", currentUserCalendarId: "", organizerCalendarId: "", creatorCalendarId: "", eventTitle: "", rustAllAttendeeCount: 0, eventTuple: nil, eventID: "", startTime: 0, rrule: "", pageContext: .noMore, isDirtyFromDetail: false, attendeeType: .normal)
    }

    // 必须被 override
    func canViewWebinarAttendees() -> Bool {
        assert(false, "canViewWebinarAttendees() has not been implemented")
        return false
    }

    var webinar: EventDetailWebinarContext? {
        return context.state.webinarContext
    }
}

extension EventDetailTableWebinarViewModel {
    enum ViewData {
        case loading
        case hidden
        case attendee(EventDetailTableWebinarViewDataType)
    }

    private func buildViewData() {
        let data = buildWebinarViewData()
        viewData.send(data)
    }
}

extension EventDetailTableWebinarViewModel {
    enum Route {
        case attendees(viewModel: EventAttendeeListViewModel)
    }

    func tap() {
        if let attendeeViewModel = buildAttendeeListViewModel(), canViewWebinarAttendees() {
            route.send(.attendees(viewModel: attendeeViewModel))
        }
    }
}

extension EventDetailTableWebinarViewModel {
    func isDirtyFromDetail() -> Bool {
        guard let event = model.event else { return false }
        return event.dirtyType != .noneDirtyType
    }
}

struct EventDetailTableWebinarViewData: EventDetailTableWebinarViewDataType {
    var countText: String?
    var statusText: String?
    var avatars: [(avatar: Avatar, statusImage: UIImage?)]
    var withEllipsisIcon: Bool
}

extension EventDetailTableWebinarViewModel {
    struct AttendeesStatisticsInfo: ExpressibleByDictionaryLiteral {
        typealias Key = Int32

        typealias Value = (_ acceptNum: Int32, _ lang: Lang?) -> String

        var text: String
        init(dictionaryLiteral elements: (Int32, (_ acceptNum: Int32, _ lang: Lang?) -> String)...) {
            text = elements.compactMap { (attendeeNumber, textParse) -> String? in
                return attendeeNumber == 0 ? nil : textParse(attendeeNumber, nil)
            }.joined(separator: BundleI18n.Calendar.Calendar_Common_DivideSymbol)
        }
    }

    func getAttendeeStatisticText(acceptedNo: Int32, declinedNo: Int32, tentativeNo: Int32, needActionNo: Int32) -> String {
        var statusNums: AttendeesStatisticsInfo = [:]
        statusNums = [acceptedNo: BundleI18n.Calendar.Calendar_Detail_NumberOfGuestAcccepted,
                      declinedNo: BundleI18n.Calendar.Calendar_Detail_NumberOfGuestRejected,
                     tentativeNo: BundleI18n.Calendar.Calendar_Detail_NumberOfGuestTentative,
                    needActionNo: BundleI18n.Calendar.Calendar_Detail_NumberOfGuestNoAction]
        return statusNums.text
    }
}
