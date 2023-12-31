//
//  EventAttendeeGroupMembersListViewModel.swift
//  Calendar
//
//  Created by 白言韬 on 2020/11/10.
//

import UIKit
import Foundation
import RoundedHUD
import RxSwift
import RxCocoa
import LarkContainer

final class EventAttendeeGroupMembersListViewModel: UserResolverWrapper {
    typealias CellData = EventAttendeeListViewModel.NonGroupCellData
    private(set) var rxCellDataList: BehaviorRelay<[CellData]>
    private(set) var title: String?
    private let chatId: String
    private let disposeBag = DisposeBag()
    private(set) var rxHasMore: BehaviorRelay<Bool>
    private var simpleAttendeeList: [Rust.IndividualSimpleAttendee]
    @ScopedInjectedLazy var rustApi: CalendarRustAPI?
    private let pageSize = 20
    var eventTitle: String?

    // 用于hud展示
    weak var viewController: UIViewController?

    let userResolver: UserResolver

    init(
        title: String?,
        chatId: String,
        attendees: [EventEditUserAttendee],
        simpleAttendeeList: [Rust.IndividualSimpleAttendee],
        userResolver: UserResolver
    ) {
        self.title = title
        self.chatId = chatId
        self.userResolver = userResolver
        self.rxCellDataList = .init(value: Self.produceCellData(with: attendees))

        let idSet = Set(attendees.map { $0.deduplicatedKey })
        // simple是全量数据，attendees 是非全量，需要去重
        self.simpleAttendeeList = simpleAttendeeList.filter { !idSet.contains($0.deduplicatedKey) }

        let hasMore = !self.simpleAttendeeList.isEmpty
        self.rxHasMore = .init(value: hasMore)

    }

    func numberOfCells() -> Int {
        return rxCellDataList.value.count
    }

    func cellData(at indexPath: IndexPath) -> CellData? {
        return rxCellDataList.value[indexPath.section]
    }

    func loadData() {
        let hasMore = pageSize < simpleAttendeeList.count
        let requestAttendees = simpleAttendeeList.prefix(pageSize)
        let chatterIds: [String] = requestAttendees.map { $0.user.chatterID }

        guard let api = self.rustApi else {
            self.rxHasMore.accept(false)
            return
        }
        api.pullEventEditUserAttendee(with: requestAttendees).subscribe(onNext: { [weak self] attendees in
            guard let self = self else { return }
            self.simpleAttendeeList = self.simpleAttendeeList.filter { !requestAttendees.contains($0) }

            var cellDataList = self.rxCellDataList.value
            cellDataList.append(contentsOf: Self.produceCellData(with: attendees))
            self.rxCellDataList.accept(cellDataList)
            self.rxHasMore.accept(hasMore)
        }, onError: { [weak self] (_) in
            self?.rxHasMore.accept(false)
            if let controller = self?.viewController {
                RoundedHUD.showFailure(with: BundleI18n.Calendar.Calendar_Edit_FindTimeFailed, on: controller.view)
            }
        }).disposed(by: disposeBag)

    }

    private static func produceCellData(with attendees: [EventEditUserAttendee]) -> [CellData] {
        return attendees
            .filter { attendee -> Bool in
                return attendee.status != .removed
            }
            .map { attendee -> CellData in
                var cellData = CellData(identifier: attendee.avatar.identifier)
                cellData.status = attendee.status
                cellData.name = attendee.name
                cellData.avatarKey = attendee.avatar.avatarKey
                cellData.calendarId = attendee.calendarId
                return cellData
            }
    }
}
