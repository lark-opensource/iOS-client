//
//  LabelMainListDataState.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2022/4/20.
//

import Foundation
import LarkOpenFeed

enum LabelMainListDataState {

    /** TODO:  数据状态、view状态
     1. 暂时将state和数据分开，预期是将数据挂到state（枚举）上：Loading、空态
     2. 暂时描述的是整体的数据状态，并没有细致到描述每个子列表的数据状态
     */
    enum DataState: Int {
        case idle,
             loading,
             loaded,
             error
    }

    case idle
    case loading(StoreInfo?)
    case loaded(StoreInfo)
    case error(Error, StoreInfo?)

    enum DataFrom {
        case none,
             loadMoreFeed(Int)
    }

    struct ExtraInfo {
        public static func `default`() -> ExtraInfo {
            return LabelMainListDataState.ExtraInfo(render: .fullReload, dataFrom: .none)
        }
        let render: LabelMainListViewDataStateModule.Render
        let dataFrom: DataFrom
    }

    struct DataInfo {
        let data: [UpdatedData]
        let extraInfo: ExtraInfo
    }

    struct StoreInfo {
        let store: DataStoreInterface
        let extraInfo: ExtraInfo
    }

    enum UpdatedData {
        case reload,
             updateLabelByGet(GetLabelsResult),
             updateFeedByGet(GetLabelFeedsResult),
             updateLabel([LabelViewModel]),
             removeLabel([Int]),
             updateFeedEntity([FeedCardViewModelInterface]),
             updateFeedRelation([EntityItem]),
             removeFeed([IndexDataInterface])
    }

    struct GetLabelsResult {
        let labels: [LabelViewModel]
        let hasMore: Bool
        let nextCursor: IndexCursor
    }

    struct GetLabelFeedsResult {
        let labelId: Int
        let entitys: [LabelFeedViewModel]
        let relations: [EntityItem]
        let hasMore: Bool
        let nextCursor: IndexCursor
    }
}

// Queries
extension LabelMainListDataState {
    var data: StoreInfo? {
        switch self {
        case .idle:
            return nil
        case .loaded(let data):
            return data
        case .loading(let data),
             .error(_, let data):
            return data
        }
    }

    var isLoading: Bool {
        switch self {
        case .loading:
            return true
        case .idle, .loaded, .error:
            return false
        }
    }
}

// Commands
extension LabelMainListDataState {
    mutating func toLoading() {
        switch self {
        case .loading: break
        case .idle, .loaded, .error:
            self = .loading(data)
        }
    }

    mutating func toLoaded(with data: StoreInfo) {
        switch self {
        case .idle, .error, .loaded: break
        case .loading:
            self = .loaded(data)
        }
    }

    mutating func toError(with error: Error) {
        switch self {
        case .idle, .error, .loaded: break
        case .loading:
            self = .error(error, data)
        }
    }

    mutating func update(_ data: StoreInfo) {
        switch self {
        case .idle:
            self = .loaded(data)
        case .loading:
            self = .loading(data)
        case .loaded:
            self = .loaded(data)
        case .error(let err, _):
            self = .error(err, data)
        }
    }
}
