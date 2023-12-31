//
//  AllFeedListViewController.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/7/8.
//

import Foundation
import RxCocoa
import RxSwift
import SnapKit
import RxDataSources
import LarkNavigation
import AnimatedTabBar
import LKCommonsLogging
import RunloopTools
import LarkSDKInterface
import RustPB
import AppContainer
import LarkPerf
import LarkOpenFeed
import EENavigator
import LarkKeyCommandKit
import LarkUIKit
import UniverseDesignTabs
import LarkContainer
import LarkFoundation
import Heimdallr
import AppReciableSDK
import LarkAccountInterface

final class AllFeedListViewController: FeedListViewController {

    let allFeedsViewModel: AllFeedListViewModel
    var onViewAppeared = BehaviorRelay<Bool>(value: false)

    init(allFeedsViewModel: AllFeedListViewModel) throws {
        self.allFeedsViewModel = allFeedsViewModel
        try super.init(listViewModel: allFeedsViewModel)
        self.context = allFeedsViewModel.feedContext
    }

    required init?(coder: NSCoder) {
        fatalError("Not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        binds()
        FeedContext.log.info("feedlog/asyncBind/allFeedsVC. start")
        RunloopDispatcher.shared.addTask(priority: .emergency) {
            FeedContext.log.info("feedlog/asyncBind/allFeedsVC. end")
            self.asyncBinds()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        onViewAppeared.accept(true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        onViewAppeared.accept(false)
    }

    private func binds() {
        // 监听首屏渲染完成
        observeFirstRendered()

        // 监听启动页消失，判断Feed是否显示，上报Slardar
        trackLaunchTransition()

        // 冷启动时，Feed数据未拉回来，需要显示Loading
        observeLoading()
    }

    // 只关联allFeeds，不涉及各个subVM的隔离逻辑
    private func asyncBinds() {
        // Feed引导(At/At All/Badge)
        observeFeedGuide()

        // 监听Application通知
        observeApplicationNotification()

        // 获取所有bagde：这个接口会触发pushFeed，以pushFeed的通道返回给端上filter badge数据
        allFeedsViewModel.allFeedsDependency.getAllBadge().subscribe(onNext: { _ in
        }).disposed(by: disposeBag)
    }
}
