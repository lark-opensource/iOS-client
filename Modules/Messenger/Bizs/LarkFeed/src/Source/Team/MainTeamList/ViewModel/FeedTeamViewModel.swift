//
//  FeedTeamViewModel.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/7/13.
//

import Foundation
import RxSwift
import RxCocoa
import RxDataSources
import LarkSDKInterface
import RustPB
import LarkModel
import LarkOpenFeed
import LarkAccountInterface
import LarkContainer

final class FeedTeamViewModel: FeedTeamViewModelInterface {

    var userResolver: UserResolver { dependency.userResolver }

    var context: FeedContextService?
    let dataQueue: OperationQueue
    let dependency: FeedTeamDependency
    let disposeBag: DisposeBag
    var dataSourceCache: FeedTeamDataSourceInterface
    let dataSourceRelay: BehaviorRelay<FeedTeamDataSourceInterface>
    var dataSourceObservable: Observable<FeedTeamDataSourceInterface> {
        return dataSourceRelay.asObservable()
    }
    let loadingStateRelay: BehaviorRelay<Bool>
    var loadingStateObservable: Observable<Bool> {
        return loadingStateRelay.asObservable().distinctUntilChanged()
    }
    var shouldLoading: Bool {
        return loadingStateRelay.value
    }
    var selectedID: String?
    var teamUIModel: FeedTeamDataSourceInterface {
        assert(Thread.isMainThread, "dataSource is only available on main thread")
        return dataSourceRelay.value
    }
    var isActive: Bool = false
    var isReGetData: Bool = false

    var isExpanded: Bool = true
    func setExpanded(_ expanded: Bool) {
        isExpanded = expanded
    }

    var subTeamId: String?
    func setSubTeamId(_ id: String?) {
        subTeamId = id
    }
    var userId: String { userResolver.userID }
    let muteActionSetting: FeedSetting.FeedGroupActionSetting
    let clearBadgeActionSetting: FeedSetting.FeedGroupActionSetting
    let atAllSetting: FeedAtAllSetting
    init(dependency: FeedTeamDependency,
         context: FeedContextService) {
        let userResolver = dependency.userResolver
        self.dependency = dependency
        self.context = context
        self.dataSourceCache = FeedTeamDataSource()
        self.disposeBag = DisposeBag()
        self.dataQueue = OperationQueue()
        self.dataSourceRelay = BehaviorRelay<FeedTeamDataSourceInterface>(value: FeedTeamDataSource())
        self.loadingStateRelay = BehaviorRelay<Bool>(value: true)
        self.muteActionSetting = FeedSetting(userResolver).getFeedMuteActionSetting()
        self.clearBadgeActionSetting = FeedSetting(userResolver).gettGroupClearBadgeSetting()
        self.atAllSetting = FeedAtAllSetting.get(userResolver: userResolver)
        setup()
    }

    func setup() {
        dataQueue.maxConcurrentOperationCount = 1
        dataQueue.qualityOfService = .userInteractive
        bind()
    }

    func willActive() {
        self.isActive = true
        // 切换后的vm强制resume queue，防止数据不上屏
        resumeDataQueue(.switchFilterTab)
    }

    func willResignActive() {
        self.isActive = false
        storeSelectedId()
    }
}
