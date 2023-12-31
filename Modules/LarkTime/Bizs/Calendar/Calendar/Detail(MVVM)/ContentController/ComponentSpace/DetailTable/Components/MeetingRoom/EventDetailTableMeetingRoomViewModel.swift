//
//  EventDetailTableMeetingRoomViewModel.swift
//  Calendar
//
//  Created by Rico on 2021/4/8.
//

import Foundation
import LarkContainer
import LarkCombine
import RxSwift

final class EventDetailTableMeetingRoomViewModel: EventDetailComponentViewModel {

    var model: EventDetailModel { rxModel.value }
    let viewData = CurrentValueSubject<DetailMeetingRoomCellContent?, Never>(nil)
    let route = PassthroughSubject<Route, Never>()
    private let disposeBag = DisposeBag()

    @ScopedInjectedLazy var calendarApi: CalendarRustAPI?
    @ScopedInjectedLazy var calendarDependency: CalendarDependency?

    @ContextObject(\.rxModel) var rxModel
    @ContextObject(\.refreshHandle) var refreshHandle

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

extension EventDetailTableMeetingRoomViewModel {
    private func buildViewData() {
        let roomInfo = getMeetingRoomInfos()
        EventDetail.logInfo("show meeting room: \(roomInfo.items.map { $0.calendarID + ($0.statusTitle ?? "") })")
        viewData.send(roomInfo)
    }
}

// MARK: - Action
extension EventDetailTableMeetingRoomViewModel {

    enum Route {
        case roomInfo(detailRoomVM: MeetingRoomDetailViewModel)
        case appLink(appLink: URL)
        case showAll(vm: SelectedMeetingRoomViewModel)
    }

    func click(with index: Int, clickIcon: Bool) {
        guard let room = viewData.value?.items[safeIndex: index] else {
            return
        }
        if clickIcon {
            CalendarTracer.shared.calClickMeetingRoomInfoFromDetail()
            var context = DetailOnlyContext()
            context.calendarID = room.calendarID
            context.eventUniqueFields = getEventUniqueFields()
            let viewModel = MeetingRoomDetailViewModel(input: .detailOnly(context), userResolver: self.userResolver)

            route.send(.roomInfo(detailRoomVM: viewModel))
            EventDetail.logInfo("click meeting room. calendarID: \(room.calendarID)")
        } else {
            if let appLink = room.appLink.flatMap({ URL(string: $0) }) {
                route.send(.appLink(appLink: appLink))
            }
        }
    }

    // 获取日程三元组信息，用于跨租户鉴权
    private func getEventUniqueFields() -> CalendarEventUniqueField? {
        // 非本地普通PB日程有日程三元组
        if case .pb(let event, _) = model {
            var eventUniqueFields = CalendarEventUniqueField()
            eventUniqueFields.calendarID = event.calendarID
            eventUniqueFields.originalTime = event.originalTime
            eventUniqueFields.key = event.key
            return eventUniqueFields
        }
        return nil
    }

    func clickShowAll() {
        if let value = viewData.value,
           let data = value as? MeetingRoomInfo {
            let vm = SelectedMeetingRoomViewModel(contents: .detail(DetailMeetingRoomCellModel(items: data.items)))
            route.send(.showAll(vm: vm))
            return
        }
    }
}

extension EventDetailTableMeetingRoomViewModel {

    struct MeetingRoomInfo: DetailMeetingRoomCellContent {
        let items: [DetailMeetingRoomItemContent]
    }

    func getMeetingRoomInfos() -> DetailMeetingRoomCellContent {
        if let roomInstance = model.roomLimitInstance,
           let tenantID = calendarDependency?.currentUser.tenantId,
           let meetingRoom = roomInstance.meetingRoom {
            /// 会议室无权限日程
            var meetingRoomModel = CalendarMeetingRoom.makeMeetingRoom(fromResource: meetingRoom,
                                                                        buildingName: roomInstance.buildingName,
                                                                        tenantId: tenantID)
            meetingRoomModel.status = roomInstance.selfAttendeeStatus
            let cellItem = DetailMeetingRoomCellModel.Item(statusTitle: nil,
                                                           title: meetingRoomModel.fullName,
                                                           isAvailable: roomInstance.selfAttendeeStatus != .decline,
                                                           isDisabled: meetingRoomModel.isDisabled,
                                                           appLink: nil,
                                                           calendarID: meetingRoom.calendarID)
            return MeetingRoomInfo(items: [cellItem])
        }

        let meetingRoomInfos = meetingRooms
            .filter { $0.status != .removed }
            .map(convertAttendeePBToMeetingRoomInfo)
        return MeetingRoomInfo(items: meetingRoomInfos)
    }

    private func convertAttendeePBToMeetingRoomInfo(_ meetingRoom: CalendarMeetingRoom) -> DetailMeetingRoomItemContent {
        var appLink = meetingRoom.approvalLink
        let isInRequi = meetingRoom.isInRequiRangeOn(start: model.startTime, end: model.endTime)
        if let applicantChatterId = meetingRoom.applicantChatterId {
            if applicantChatterId != self.userResolver.userID || meetingRoom.status == .decline || isInRequi {
                appLink = nil
            }
        } else {
            appLink = nil
        }
        return DetailMeetingRoomCellModel.Item(
            statusTitle: meetingRoom.getPBModel().dt.statusSummary(isInRequi: isInRequi),
            title: meetingRoom.fullName,
            isAvailable: meetingRoom.isAvailable,
            isDisabled: meetingRoom.isDisabled,
            appLink: appLink,
            calendarID: meetingRoom.uniqueId
        )
    }

    var meetingRooms: [CalendarMeetingRoom] {
        var rooms = [CalendarMeetingRoom]()
        switch model {
        // 未能找到本地日程添加会议室的方式，但考虑 EKEntity 中有相关字段，暂保留逻辑
        case let .local(event):
            var organizerHashValue = "0"
            if let organizer = event.organizer {
                organizerHashValue = "\(organizer.url)"
            }
            rooms = event.attendees?.compactMap({ (attendee) -> CalendarMeetingRoom? in
                let attendee = AttendeeFromLocal(localAttendee: attendee, organizerHash: organizerHashValue)
                guard attendee.isResource else { return nil }
                var mockPB = CalendarEventAttendee()
                mockPB.displayName = attendee.localizedDisplayName
                mockPB.status = attendee.status
                mockPB.resource.tenantID = attendee.tenantId
                return CalendarMeetingRoom(from: mockPB)
            }) ?? []
        case .pb(let event, let instance):
            rooms = event.attendees.filter { $0.category == .resource }
            .map({ (resourcePB) -> CalendarMeetingRoom in
                var room = CalendarMeetingRoom(from: resourcePB)
                room.resetAvailableStateWith(insStart: instance.startTime, insEnd: instance.endTime)
                return room
            })
        default:
            EventDetail.logUnreachableLogic()
        }
        return rooms.sorted(by: {
            if $0.isAvailable != $1.isAvailable {
                return $0.isAvailable
            } else {
                return true
            }
        })
    }
}
