//
//  MeetTabListViewModel.swift
//  ByteView
//
//  Created by fakegourmet on 2021/7/4.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Action
import LKCommonsLogging
import ByteViewCommon
import ByteViewNetwork
import ByteViewSetting

typealias MeetTabLoadAction = Action<MeetTabCellViewModel?, ([MeetTabCellViewModel], Bool)>
typealias MeetTabEventDataSource = DiffDataSource<MeetTabCellViewModel>
typealias MeetTabUpdateEvent = MeetTabEventDataSource.UpdateEvent

class MeetTabListViewModel {
    static let logger = Logger.meetingList

    static let loadHistoryCount: Int64 = 50
    static let preLoadBuffer: Int = 20
    /// 拉取日程条数 N，由于需要判断是否更多因此实际拉取 N+1
    static let loadUpcomingCount: Int64 = 2

    let disposeBag = DisposeBag()
    weak var hostViewController: UIViewController?

    // ====== Input ======
    let tabViewModel: MeetTabViewModel

    // ====== Output ======
    @RwAtomic
    var calendarID: String = ""

    private(set) var recordCompletedInfoRelay = PublishRelay<RecordCompletedInfo>()

    lazy var historyDataSource: MeetTabEventDataSource = {
        return MeetTabEventDataSource(eventObservable: historyAllEventsObservable, loader: historyAllLoadAction, preLoader: preloadAction)
    }()

    lazy var upcomingDataSource: MeetTabEventDataSource = {
        return MeetTabEventDataSource(eventObservable: upcomingAllEventsObservable, loader: upcomingAllLoadAction, preLoader: preloadAction, sort: .asc)
    }()

    @RwAtomic
    var historySectionViewModel: [MeetTabHistorySectionViewModel] = []
    @RwAtomic
    var ongoingSectionViewModel: [MeetTabHistorySectionViewModel] = []
    @RwAtomic
    var upComingSectionViewModel: [MeetTabHistorySectionViewModel] = []

    var userId: String { tabViewModel.userId }
    var httpClient: HttpClient { tabViewModel.httpClient }
    var router: TabRouteDependency? { tabViewModel.router }
    var setting: UserSettingManager { tabViewModel.setting }
//    var meetingService: MeetingService? { tabViewModel.meetingService }
    var globalDependency: TabGlobalDependency { tabViewModel.dependency.global }
    var fg: TabFeatureGating { tabViewModel.fg }

    init(dependency: TabDependency) {
        self.tabViewModel = MeetTabViewModel(dependency: dependency)
        fetchCalendarID()
        TabPush.syncUpcomingInstances.inUser(userId).addObserver(self) { [weak self] _ in
            self?.didReceiveSyncUpcomingInstances()
        }
        TabServerPush.recordInfo.inUser(userId).addObserver(self) { [weak self] in
            self?.didNotifyRecordCompletedInfo($0)
        }
    }

    deinit {
    }

    func fetchCalendarID() {
        httpClient.getResponse(GetPrimaryCalendarRequest()) { [weak self] result in
            if case .success(let resp) = result {
                self?.calendarID = resp.calendar.serverID
            }
        }
    }

    func loadTabData(_ isPreLoad: Bool = true) {
        loadHistoryData(isPreLoad)
        loadUpcomingData(isPreLoad)
    }

    func loadHistoryData(_ isPreLoad: Bool = true) {
        historyDataSource.force(isPreLoad: isPreLoad)
    }

    func loadUpcomingData(_ isPreLoad: Bool = true) {
        upcomingDataSource.force(isPreLoad: isPreLoad)
    }

    func resetDataIfNeeded() {
        if historyDataSource.current.count < MeetTabListViewModel.loadHistoryCount {
            historyDataSource.force()
        }
    }

    /// 比较app版本，v1>v2返回1，等于返回0，小于返回-1，无法比较返回-2
    /// version格式："5.21.0"
    static func compareVersion(_ v1: String, _ v2: String) -> Int {
        var version1 = v1.split(separator: ".")
        var version2 = v2.split(separator: ".")
        if version1.count != 3 || version2.count != 3 {
            return -2
        }
        while !version1.isEmpty && !version2.isEmpty {
            if let val1 = Float(version1.removeFirst()), let val2 = Float(version2.removeFirst()) {
                if val1 > val2 {
                    return 1
                } else if val1 == val2 {
                    continue
                } else {
                    return -1
                }
            } else {
                return -2
            }
        }
        return 0
    }
}

extension MeetTabListViewModel {
    func getSuiteQuota(completion: @escaping (Result<GetSuiteQuotaResponse, Error>) -> Void) {
        self.httpClient.getResponse(GetSuiteQuotaRequest(meetingID: nil)) { r in
            DispatchQueue.main.async {
                completion(r)
            }
        }
    }
}

extension MeetTabListViewModel {
    func didReceiveSyncUpcomingInstances() {
        Self.logger.debug("receive PushVcSyncUpcomingInstances and ready to reload upcoming data")
        loadUpcomingData(false)
    }
}

extension MeetTabListViewModel {
    func didNotifyRecordCompletedInfo(_ info: RecordCompletedInfo) {
        Self.logger.debug("receive RecordCompletedInfo")
        recordCompletedInfoRelay.accept(info)
    }
}
