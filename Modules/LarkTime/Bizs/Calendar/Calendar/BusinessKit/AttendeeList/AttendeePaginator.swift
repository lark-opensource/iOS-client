//
//  AttendeePaginator.swift
//  Calendar
//
//  Created by Rico on 2021/5/23.
//

import Foundation
import RxSwift
import RustPB
import LarkContainer

protocol AttendeePaginator {
    func loadNextPage() -> Single<PageResult>
    func loadWebinarAttendeeNextPage(serverID: String, webinarAttendeeType: WebinarAttendeeType) -> Single<PageResult>
}

struct PageResult {
    let hasMore: Bool
    let attendees: [EventEditAttendee]
}

typealias EventTuple = (calendarId: String, key: String, originalTime: Int64)
typealias Token = String
typealias EventVersion = String

enum PageIdentifier {
    case token(Token, EventTuple, EventVersion)
    case index
    case waiting // SDK 脏 attendee 未同步完成，显示loading等待push刷新
}

final class AttendeePaginatorImpl: AttendeePaginator, UserResolverWrapper {
    static let pageSize: Int = 20
    private(set) var pageIdentifier: PageIdentifier
    private var hasMore = true
    // 只需要传参与人，参与群在日程同步或新增时会拉到全量信息
    private(set) var simpleAttendeeList: [Rust.IndividualSimpleAttendee]
    private(set) var originalAttendeeList: [EventEditAttendee]

    let userResolver: UserResolver
    @ScopedInjectedLazy private var api: CalendarRustAPI?

    init(userResolver: UserResolver,
         initialPageIdentifier: PageIdentifier,
         originalAttendeeList: [EventEditAttendee] = [],
         simpleAttendeeList: [Rust.IndividualSimpleAttendee] = []) {
        self.userResolver = userResolver
        self.simpleAttendeeList = simpleAttendeeList
        self.originalAttendeeList = originalAttendeeList
        self.pageIdentifier = initialPageIdentifier
    }

    func append(simpleAttendee: [Rust.IndividualSimpleAttendee]) {
        let simpleAttendee = simpleAttendee.filter { !simpleAttendeeList.contains($0) }
        simpleAttendeeList.append(contentsOf: simpleAttendee)
    }

}

extension AttendeePaginatorImpl {

    /// 加载下一页参与人，内部有副作用，pageToken会自增
    /// - Returns: Single<PageResult>
    func loadNextPage() -> Single<PageResult> {
        guard let rustApi = self.api else {
            return .error(CError.userContainer("attendee loadNextPage failed, can not get rust api from larkcontainer"))
        }
        switch pageIdentifier {
        case .token(let token, let tuple, let eventVersion):
            var nextToken: String = ""
            let originalAttendeeKeys: Set<String> = Set(originalAttendeeList.map { $0.deduplicatedKey })
            let map = { (response: PullEventIndividualAttendeesResponse) -> PageResult in
                nextToken = response.nextPageToken
                let attendees = response.attendees
                    .filter {
                        let key = EventEditAttendee.makeAttendee(from: $0)?.deduplicatedKey ?? ""
                        return !originalAttendeeKeys.contains(key)
                    }
                return PageResult(hasMore: response.hasMore_p,
                                  attendees: EventEditAttendee.makeAttendees(from: attendees))
            }

            return rustApi.pullEventIndividualAttendees(calendarID: tuple.calendarId,
                                                         originalTime: tuple.originalTime,
                                                         key: tuple.key,
                                                         eventVersion: eventVersion,
                                                         pageToken: token,
                                                         pageSize: Int32(AttendeePaginatorImpl.pageSize))
                .map(map)
                .asSingle()
                .do(onSuccess: { [weak self] _ in
                    guard let self = self else { return }
                    self.pageIdentifier = .token(nextToken, tuple, eventVersion)
                })
        case .index:
            let hasMore = AttendeePaginatorImpl.pageSize < simpleAttendeeList.count
            let requestSeeds = simpleAttendeeList.prefix(AttendeePaginatorImpl.pageSize)

            let map = { (attendees: [EventEditAttendee]) -> PageResult in
                return PageResult(hasMore: hasMore,
                                  attendees: attendees)
            }

            return rustApi.pullEventEditAttendee(with: requestSeeds)
                .map(map)
                .asSingle()
                .do(onSuccess: { [weak self] _ in
                    guard let self = self else { return }
                    self.simpleAttendeeList = self.simpleAttendeeList.filter {
                        !requestSeeds.contains($0)
                    }
                })
        case .waiting:
            return .just(PageResult(hasMore: hasMore,
                                    attendees: []))
        }

    }

    /// 加载 Webinar 下一页参与人，内部有副作用，pageToken会自增
    /// - Returns: Single<PageResult>
    func loadWebinarAttendeeNextPage(serverID: String, webinarAttendeeType: WebinarAttendeeType) -> Single<PageResult> {
        guard let rustApi = self.api else {
            return .error(CError.userContainer("loadWebinarAttendeeNextPage failed, can not get rust api from larkcontainer"))
        }
        switch pageIdentifier {
        case .token(let token, let tuple, let eventVersion):
            var nextToken: String = ""
            let originalAttendeeKeys: Set<String> = Set(originalAttendeeList.map { $0.deduplicatedKey })
            let map = { (response: GetWebinarIndividualAttendeesByPageResponse) -> PageResult in
                nextToken = response.nextPageToken
                let attendees = response.attendees
                    .filter {
                        let key = EventEditAttendee.makeAttendee(from: $0)?.deduplicatedKey ?? ""
                        return !originalAttendeeKeys.contains(key)
                    }
                return PageResult(hasMore: response.hasMore_p,
                                  attendees: EventEditAttendee.makeAttendees(from: attendees))
            }

            return rustApi.getWebinarIndividualAttendees(calendarID: serverID, webinarType: webinarAttendeeType, pageToken: token, pageSize: Int32(AttendeePaginatorImpl.pageSize))
                .map(map)
                .asSingle()
                .do(onSuccess: { [weak self] _ in
                    guard let self = self else { return }
                    self.pageIdentifier = .token(nextToken, tuple, eventVersion)
                })
        case .index:
            let hasMore = AttendeePaginatorImpl.pageSize < simpleAttendeeList.count
            let requestSeeds = simpleAttendeeList.prefix(AttendeePaginatorImpl.pageSize)

            let map = { (attendees: [EventEditAttendee]) -> PageResult in
                return PageResult(hasMore: hasMore,
                                  attendees: attendees)
            }

            return rustApi.pullEventEditAttendee(with: requestSeeds)
                .map(map)
                .asSingle()
                .do(onSuccess: { [weak self] _ in
                    guard let self = self else { return }
                    self.simpleAttendeeList = self.simpleAttendeeList.filter {
                        !requestSeeds.contains($0)
                    }
                })
        case .waiting:
            return .just(PageResult(hasMore: hasMore,
                                    attendees: []))
        }
    }
}
