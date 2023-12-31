//
//  HiddenChatListViewModel.swift
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
import LarkMessengerInterface
import LarkContainer

final class HiddenChatListViewModel: UserResolverWrapper {
    var userResolver: UserResolver { dependency.userResolver }

    let dataQueue: OperationQueue
    let dependency: FeedTeamDependency
    let disposeBag: DisposeBag
    var dataSourceCache: FeedTeamItemViewModel
    let dataSourceRelay: BehaviorRelay<FeedTeamItemViewModel>
    var dataSourceObservable: Observable<FeedTeamItemViewModel> {
        return dataSourceRelay.asObservable()
    }
    let loadingStateRelay: BehaviorRelay<Bool>
    var loadingStateObservable: Observable<Bool> {
        return loadingStateRelay.asObservable().distinctUntilChanged()
    }
    var shouldLoading: Bool {
        return loadingStateRelay.value
    }
    var teamUIModel: FeedTeamItemViewModel {
        assert(Thread.isMainThread, "dataSource is only available on main thread")
        return dataSourceRelay.value
    }
    let teamItemId: Int

    init(teamViewModel: FeedTeamItemViewModel,
         dependency: FeedTeamDependency) {
        self.teamItemId = Int(teamViewModel.teamItem.id)
        self.dependency = dependency
        let dataSourceCache = teamViewModel
        self.dataSourceCache = dataSourceCache
        self.disposeBag = DisposeBag()
        self.dataQueue = OperationQueue()
        self.dataSourceRelay = BehaviorRelay<FeedTeamItemViewModel>(value: dataSourceCache)
        self.loadingStateRelay = BehaviorRelay<Bool>(value: true)
        setup()
    }

    func setup() {
        dataQueue.maxConcurrentOperationCount = 1
        dataQueue.qualityOfService = .userInteractive
        bind()
    }
}
