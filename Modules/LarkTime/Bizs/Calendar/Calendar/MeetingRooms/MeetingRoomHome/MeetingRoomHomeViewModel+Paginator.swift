//
//  MeetingRoomHomeViewModel+Paginator.swift
//  Calendar
//
//  Created by huoyunjie on 2022/5/17.
//

import Foundation
import LarkContainer
import RustPB
import RxSwift

struct MeetingRoomHomeListPageResult {
    var resources: [Rust.MeetingRoom] = []
    var hasMore: Bool = false
}

// 用于会议室视图页列表数据分页加载
class MeetingRoomHomeListPaginator: UserResolverWrapper {

    @ScopedInjectedLazy var rustAPI: CalendarRustAPI?

    let userResolver: UserResolver

    private var config: Rust.HierarchicalRoomViewFilterConfigs
    private var cursor: String?
    private var isFinished: Bool = true

    init(config: Rust.HierarchicalRoomViewFilterConfigs, userResolver: UserResolver) {
        self.config = config
        self.userResolver = userResolver
    }

    func pullHierarchicalRoomViewResourceList() -> Observable<MeetingRoomHomeListPageResult> {
        guard let rustAPI = self.rustAPI else {
            return .empty()
        }
        return rustAPI.pullHRoomViewResourceList(config: config)
            .map({ [weak self] (response: Calendar_V1_PullHierarchicalRoomViewResourceListResponse) in
                guard let self = self else { return MeetingRoomHomeListPageResult() }
                self.isFinished = response.isFinished
                self.cursor = response.cursor
                return MeetingRoomHomeListPageResult(resources: response.resources,
                                                     hasMore: !response.isFinished)
            })
    }

    func loadMoreHierarchicalRoomViewResourceList(count: Int32) -> Observable<MeetingRoomHomeListPageResult?> {
        guard let _cursor = cursor,
              let rustAPI = self.rustAPI,
              !isFinished else { return .just(nil) }
        return rustAPI.pullHRoomViewResourceList(config: config, cursor: _cursor, count: count)
            .map { [weak self] response in
                guard let self = self else { return MeetingRoomHomeListPageResult() }
                guard  self.cursor != response.cursor else { return nil }
                self.isFinished = response.isFinished
                self.cursor = response.cursor
                return MeetingRoomHomeListPageResult(resources: response.resources,
                                                     hasMore: !response.isFinished)
            }
    }

    func updateConfig(config: Rust.HierarchicalRoomViewFilterConfigs) {
        self.config = config
    }
}
