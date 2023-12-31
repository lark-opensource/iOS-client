//
//  MeetingCollectionViewModel.swift
//  ByteViewTab
//
//  Created by fakegourmet on 2022/6/7.
//

import Foundation
import RxSwift
import RxCocoa
import Action
import ByteViewNetwork
import UIKit
import UniverseDesignColor

class MeetingCollectionViewModel {

    static let loadCount: Int = 50
    static let preLoadBuffer: Int = 20

    lazy var historyDataSource: MeetTabEventDataSource = {
        return MeetTabEventDataSource(eventObservable: .empty(), loader: historyAllLoadAction, preLoader: preloadAction)
    }()

    var historyAllLoadAction: MeetTabLoadAction {
        return historyActionMaker()
    }

    var preloadAction: MeetTabLoadAction {
        return MeetTabLoadAction { _ -> Observable<([MeetTabCellViewModel], Bool)> in
            return .just(([], false))
        }
    }

    var loadMoreHistoryAction: CocoaAction {
        return CocoaAction(workFactory: { [weak self] _ in
            self?.historyDataSource.loadMore()
            return .empty()
        })
    }

    var historySectionItem: MeetTabSectionViewModel {
        return MeetTabSectionViewModel(title: "",
                                       showSeparator: false,
                                       loadStatus: .loading,
                                       loadAction: loadMoreHistoryAction,
                                       padSectionHeaderIdentifier: String(describing: MeetingCollectionPadSectionHeaderView.self),
                                       padLoadMoreSectionFooterIdentifier: String(describing: MeetingCollectionPadLoadMoreSectionFooterView.self),
                                       headerHeightGetter: { _ in 8.0 },
                                       footerHeightGetter: { loadStatus, isRegular in
            if loadStatus != .result {
                // nolint-next-line: magic number
                return isRegular ? 50.0 : 42.0
            } else {
                return .leastNonzeroMagnitude
            }
        })
    }

    var historySectionObservable: Observable<[MeetTabHistorySectionViewModel]> {
        return historyDataSource.result.map { [weak self] result -> [MeetTabHistorySectionViewModel] in
            guard var sectionItem = self?.historySectionItem else { return [] }
            let historyItems: [MeetTabCellViewModel]
            switch result {
            case let .eventResults(items):
                historyItems = items
                sectionItem.loadStatus = .result
            case let .loadError(items, _):
                historyItems = items
                sectionItem.loadStatus = .loadError
            case let .loadResults(items, hasMore):
                historyItems = items
                sectionItem.loadStatus = hasMore ? .loading : .result
            case let .loadingResults(items):
                historyItems = items
            }
            guard !historyItems.isEmpty else { return [] }
            return [MeetTabHistorySectionViewModel(sectionItem: sectionItem, items: historyItems)]
        }
    }

    // disable-lint: magic number
    var bgAlphaDark: CGFloat {
        if collectionType == .ai {
            return 0.15
        } else if collectionType == .calendar {
            return 0.05
        } else {
            return 1.0
        }
    }
    // enable-lint: magic number

    var bgImage: UIImage? {
        if collectionType == .ai {
            return BundleResources.ByteViewTab.Collection.collectionAIBg
        } else if collectionType == .calendar {
            return BundleResources.ByteViewTab.Collection.collectionCalendarBg
        } else {
            return nil
        }
    }

    var bgColorSet: [UIColor] {
        if collectionType == .ai {
            return [UDColor.rgb(0xF6F0E8), UDColor.rgb(0xFBF7F2)]
        } else if collectionType == .calendar {
            return [UDColor.rgb(0xDAE3ED), UDColor.rgb(0xF7F8FB)]
        } else {
            return []
        }
    }

    var bgDarkColorSet: [UIColor] {
        if collectionType == .ai {
            return [UDColor.rgb(0x58442D), UDColor.rgb(0x1B1B1B)]
        } else if collectionType == .calendar {
            return [UDColor.rgb(0x293747), UDColor.rgb(0x232932)]
        } else {
            return []
        }
    }

    var collectionObservable: Observable<CollectionInfo> {
        collectionRelay.asObservable()
    }
    private lazy var collectionRelay = BehaviorRelay<CollectionInfo>(value: startInfo)

    var monthLimitObservable: Observable<Int> {
        monthLimitRelay.asObservable()
    }
    private var monthLimitRelay = BehaviorRelay<Int>(value: 6)

    var isRegularGetter: (() -> Bool)?

    let startInfo: CollectionInfo
    let collectionID: String
    let collectionType: CollectionInfo.CollectionType
    let httpClient: HttpClient
    let userId: String
    let tabViewModel: MeetTabViewModel
    init(tabViewModel: MeetTabViewModel, collection: CollectionInfo) {
        self.tabViewModel = tabViewModel
        self.userId = tabViewModel.userId
        self.startInfo = collection
        self.collectionID = collection.collectionID
        self.collectionType = collection.collectionType
        self.httpClient = tabViewModel.httpClient
    }

    func historyActionMaker() -> MeetTabLoadAction {
        var lastTime: CollectionTimeProtocol?
        let thisYear: Int = Date().get(.year)
        let httpClient = self.httpClient
        return MeetTabLoadAction { [weak self] last -> Observable<([MeetTabCellViewModel], Bool)> in
            guard let self = self else { return .just(([], false)) }
            lastTime = last as? CollectionTimeProtocol
            let historyID = last?.matchKey.filter { $0.isNumber }
            let maxNum = Self.loadCount
            return RxTransform.single {
                let request = GetVCTabCollectionInfoListRequest(collectionID: self.collectionID, pageNum: maxNum, fromHistoryID: historyID)
                httpClient.getResponse(request, completion: $0)
            }
            .asObservable()
            .filter { !$0.collectionInfo.items.isEmpty }
            .flatMapLatest { (response: GetVCTabCollectionInfoListResponse) -> Observable<GetVCTabCollectionInfoListResponse> in
                let o1: Observable<GetVCTabCollectionInfoListResponse> = .just(response)
                let minutesIDs = response.collectionInfo.items.filter { $0.contentLogos.contains(.larkMinutes) }.map { $0.meetingID }
                let recordIDs = response.collectionInfo.items.filter { $0.contentLogos.contains(.record) && !$0.contentLogos.contains(.larkMinutes) }.map { $0.meetingID }
                let o2 = RxTransform.single { (completion: @escaping (Result<GetRecordInfoResponse, Error>) -> Void) in
                    let request = GetRecordInfoRequest(recordMeetingIDs: recordIDs, minutesMeetingIDs: minutesIDs)
                    httpClient.getResponse(request, completion: completion)
                }.asObservable().map { $0.recordInfo }.map { recordMap -> GetVCTabCollectionInfoListResponse in
                    var r = response
                    r.collectionInfo.items = response.collectionInfo.items.map {
                        var item = $0
                        if let recordInfo = recordMap[item.meetingID] {
                            item.recordInfo = recordInfo
                            item.hasRecordInfo = true
                        }
                        return item
                    }
                    return r
                }.catchError({ _ in .empty() })
                return Observable.merge(o1, o2)
            }
            .observeOn(MainScheduler.asyncInstance)
            .map { [weak self] in
                ($0, self?.isRegularGetter?() ?? false)
            }
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .map { [weak self] response, isRegular -> ([MeetTabCellViewModel], Bool) in
                guard let self = self else { return ([], false) }
                self.collectionRelay.accept(response.collectionInfo)
                self.monthLimitRelay.accept(response.monthsLimit)
                let array = response.collectionInfo.items.map {
                    MeetingCollectionCellViewModel(viewModel: self.tabViewModel, vcInfo: $0, user: nil)
                }

                // 年份、月份仅在 regular 下展示
                guard isRegular else {
                    return (array, response.hasMore)
                }
                // 按年 + 月分组
                let groupYM = Dictionary(grouping: array, by: { Date(timeIntervalSince1970: TimeInterval($0.vcInfo.sortTime)).get(.year, .month) })
                // 按年分组
                let groupY = Dictionary(grouping: groupYM, by: { $0.key.year })
                var groupedItems: [MeetTabCellViewModel] = []
                for (y, g) in groupY {
                    let firstItem: TabListItem = g[0].1[0].vcInfo
                    // 计算新年份要小于当前显示年份
                    if let year = lastTime?.year {
                        // 若已存在数据，则与最后一条年份对比是否需要新加年份
                        if let y = y, year <= y {} else {
                            let yearModel = MeetingCollectionYearCellViewModel(vcInfo: firstItem)
                            groupedItems.append(yearModel)
                        }
                    } else {
                        // 若没有数据，则判断第一条的年份，今年不展示
                        let firstYear: Int = Date(timeIntervalSince1970: TimeInterval(firstItem.sortTime)).get(.year)
                        if firstYear < thisYear {
                            let yearModel = MeetingCollectionYearCellViewModel(vcInfo: firstItem)
                            groupedItems.append(yearModel)
                        }
                    }
                    for (ym, items) in g {
                        if let year = lastTime?.year, let y = ym.year, let m = ym.month, year <= y, let month = lastTime?.month, month <= m {} else {
                            let monthModel = MeetingCollectionMonthCellViewModel(vcInfo: items[0].vcInfo)
                            groupedItems.append(monthModel)
                        }
                        groupedItems.append(contentsOf: items)
                    }
                }
                return (groupedItems, response.hasMore)
            }
        }
    }

    func loadData(_ isPreLoad: Bool = true) {
        historyDataSource.force(isPreLoad: isPreLoad)
    }
}

extension Date {
    func get(_ components: Calendar.Component..., calendar: Calendar = Calendar.current) -> DateComponents {
        return calendar.dateComponents(Set(components), from: self)
    }

    func get(_ component: Calendar.Component, calendar: Calendar = Calendar.current) -> Int {
        return calendar.component(component, from: self)
    }
}
