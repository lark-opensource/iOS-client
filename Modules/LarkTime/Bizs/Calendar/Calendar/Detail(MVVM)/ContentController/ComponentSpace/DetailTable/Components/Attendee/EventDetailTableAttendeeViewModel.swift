//
//  EventDetailTableAttendeeViewModel.swift
//  Calendar
//
//  Created by Rico on 2021/4/6.
//

import UIKit
import Foundation
import LarkContainer
import LarkCombine
import RxSwift
import RxCocoa
import LarkLocalizations

final class EventDetailTableAttendeeViewModel: EventDetailComponentViewModel {

    var model: EventDetailModel { rxModel.value }
    let viewData = CurrentValueSubject<ViewData, Never>(.notDecision)
    let route = PassthroughSubject<Route, Never>()
    var calendar: EventDetail.Calendar?
    private let disposeBag = DisposeBag()

    @ScopedInjectedLazy var calendarManager: CalendarManager?
    @ScopedInjectedLazy var calendarDependency: CalendarDependency?
    @ScopedInjectedLazy var calendarApi: CalendarRustAPI?
    @ScopedInjectedLazy var mailContactService: MailContactService?
    @ContextObject(\.rxModel) var rxModel

    override init(context: EventDetailContext, userResolver: UserResolver) {
        super.init(context: context, userResolver: userResolver)
        calendar = calendarManager?.calendar(with: context.rxModel.value.calendarId)

        bindRx()
    }

    private func bindRx() {
        let modelPush: Observable<Bool> = rxModel.map { _ in true }
        let mailParsedPush: Observable<Bool> = mailContactService?.rxDataChanged.map { _ in false } ?? .empty()
        Observable.merge(modelPush, mailParsedPush)
            .subscribe(onNext: { [weak self] loadMailContactParsed in
                guard let self = self else { return }
                self.buildViewData(loadMailContactParsed: loadMailContactParsed)
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - ViewData

extension EventDetailTableAttendeeViewModel {

    enum ViewData {
        // 还未决策视图类型
        case notDecision
        // 隐藏参与人
        case hidden
        // 正常参与人信息
        case attendee(DetailAttendeeCellViewDataType)
    }

    private func buildViewData(loadMailContactParsed: Bool = true) {
        if model.shouldHideAttendees(for: calendar) {
            EventDetail.logInfo("attendee hidden")
            viewData.send(.hidden)
            return
        }

        let attendees = getAttendees(loadMailContactParsed: loadMailContactParsed)
        viewData.send(.attendee(attendees))
        EventDetail.logInfo("attendee info. countLabel: \(attendees.countLabelText), statusLabel: \(attendees.statusLabelText)")
    }
}

// MARK: - Action

extension EventDetailTableAttendeeViewModel {
    enum Route {
        case attendees(viewModel: EventAttendeeListViewModel)
    }

    func tap() {
        ReciableTracer.shared.recStartCheckAttendee()
        if let attendeeViewModel = buildAttendeeViewModel() {
            route.send(.attendees(viewModel: attendeeViewModel))
        }
        ReciableTracer.shared.recEndCheckAttendee()
    }
}

// MARK: - Private

extension EventDetailTableAttendeeViewModel {

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

    func getAttendees(loadMailContactParsed: Bool) -> DetailAttendeeCellViewDataType {

        let attendees = model.sortedVisibleAttendees

        var count: Int32 = 0
        if let event = model.event {
            count = event.attendeeInfo.totalNo
        } else if model.isLocal {
            count = Int32(attendees.count)
        }

        // (dirty & 原本参与人就不全的日程 或 只有1人)不显示参与人个数
        let isDirty = model.event?.dirtyType != .noneDirtyType
        let notTotalAttendee = !(model.event?.attendeeInfo.allIndividualAttendee ?? true)
        let haveOnlyOne = count == 1
        let numLabelNil = (isDirty && notTotalAttendee) || haveOnlyOne

        let countStr = BundleI18n.Calendar.Calendar_Plural_FullDetailStringOfGuests(number: count)

        var statusNums: AttendeesStatisticsInfo = [:]
        if let event = model.event {
            let statistics = event.attendeeInfo
            statusNums = [statistics.acceptNo: BundleI18n.Calendar.Calendar_Detail_NumberOfGuestAcccepted,
                          statistics.declineNo: BundleI18n.Calendar.Calendar_Detail_NumberOfGuestRejected,
                          statistics.tentativeNo: BundleI18n.Calendar.Calendar_Detail_NumberOfGuestTentative,
                          statistics.needActionNo: BundleI18n.Calendar.Calendar_Detail_NumberOfGuestNoAction]
        }

        let statusStr = statusNums.text

        var withEllipsisIcon = false

        var prefixAttendees = Array(attendees.prefix(6))
        if prefixAttendees.count == 6 {
            _ = prefixAttendees.popLast()
            withEllipsisIcon = true
        }
        let avatars = prefixAttendees.map { (entity) -> (Avatar, UIImage?) in
            var attendee = entity
            if var entity = entity as? PBAttendee {
                entity.changeNormalMailContactPBIfNeeded(mailContactService)
                attendee = entity
            }
            let image = attendee.getStatusImage()
            return (attendee.avatar, image)
        }

        if loadMailContactParsed {
            mailContactService?.loadMailContact(mails: prefixAttendees.compactMap(\.mail))
        }

        let attendeeData = DetailAttendeeCellViewData(countLabelText: numLabelNil ? nil : countStr,
                                                      statusLabelText: numLabelNil ? nil : statusStr,
                                                      avatars: avatars,
                                                      withEllipsisIcon: withEllipsisIcon,
                                                      totalCount: count)

        return attendeeData

    }

    private func buildAttendeeViewModel() -> EventAttendeeListViewModel? {

        func getPageContext() -> EventAttendeeListViewModel.PaginationContext {
            guard let event = model.event else { return .noMore }
            let attendeeInfo = event.attendeeInfo
            let needWaitEventUpdate = event.calendarEventDisplayInfo.isIndividualAttendeeSyncing

            if attendeeInfo.allIndividualAttendee {
                return .noMore
            } else if needWaitEventUpdate {
                return .needWaitEventUpdate
            } else {
                return .needPagination(token: attendeeInfo.snapshotPageToken, version: event.version64)
            }
        }

        func getIsDirtyFromDetail() -> Bool {
            guard let event = model.event else { return false }
            return event.dirtyType != .noneDirtyType
        }

        guard let tenantID = calendarDependency?.currentUser.tenantId,
              let calendarID = calendarManager?.primaryCalendarID else { return nil }

        let viewModel = EventAttendeeListViewModel(
            userResolver: self.userResolver,
            attendees: EventEditAttendee.makeAttendees(from: model.sortedVisibleAttendees),
            isLarkEvent: isLarkEvent(),
            currentTenantId: tenantID,
            currentUserCalendarId: calendarID,
            organizerCalendarId: model.organizerCalendarId,
            creatorCalendarId: model.creatorCalendarId,
            eventTitle: model.displayTitle,
            rustAllAttendeeCount: model.visibleAttendeeCount,
            eventTuple: (model.calendarId, model.key, model.originalTime),
            eventID: model.event?.serverID ?? "",
            startTime: model.event?.startTime ?? 0,
            rrule: model.event?.rrule,
            pageContext: getPageContext(),
            isDirtyFromDetail: getIsDirtyFromDetail()
        )

        return viewModel
    }

    private func isLarkEvent() -> Bool {
        let eventIsGoogle = calendar?.isGoogleCalendar() ?? false
        let eventIsExchange = calendar?.isExchangeCalendar() ?? false
        var isLarkEvent = model.isLarkEvent
        if eventIsGoogle || eventIsExchange {
            isLarkEvent = false
        }
        return isLarkEvent
    }
}

struct DetailAttendeeCellViewData: DetailAttendeeCellViewDataType {
    var countLabelText: String?
    var statusLabelText: String?
    var avatars: [(avatar: Avatar, statusImage: UIImage?)]
    var withEllipsisIcon: Bool
    var totalCount: Int32
}
