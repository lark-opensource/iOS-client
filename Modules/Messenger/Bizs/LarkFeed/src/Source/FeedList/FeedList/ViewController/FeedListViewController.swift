//
//  FeedListViewController.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/12/22.
//

import UIKit
import Foundation
import SnapKit
import RxDataSources
import RxSwift
import RxCocoa
import LarkNavigation
import AnimatedTabBar
import LKCommonsLogging
import RunloopTools
import LarkSDKInterface
import RustPB
import AppContainer
import LarkPerf
import EENavigator
import LarkKeyCommandKit
import LarkUIKit
import UniverseDesignTabs
import LarkFoundation
import Heimdallr
import AppReciableSDK
import LarkAccountInterface
import LarkOpenFeed
import LarkContainer

class FeedListViewController: BaseFeedsViewController, FeedModuleVCInterface {
    let listViewModel: FeedListViewModel
    weak var delegate: FeedModuleVCDelegate?

    lazy var feedFindUnreadPlugin: FeedFinderPlugin = {
        return FeedFinderPlugin(delegate: self)
    }()

    init(listViewModel: FeedListViewModel) throws {
        self.listViewModel = listViewModel
        try super.init(feedsViewModel: listViewModel)
        self.context = listViewModel.feedContext
        self.isNavigationBarHidden = true
    }

    required init?(coder: NSCoder) {
        fatalError("Not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubViews()
    }

    func willActive() {
        listViewModel.willActive()
        resetSelect()
        sendFeedListState(state: .switchFilterTab)
    }

    func willResignActive() {
        listViewModel.willResignActive()
    }

    func willDestroy() {}

    // MARK: UIScrollViewDelegate
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        super.scrollViewDidEndDecelerating(scrollView)
        loadMoreForDiscontinuousWhenScrollStop()
    }

    // 负责在双击Tabbar调用scrollToRow后解禁NaviBar显示/隐藏逻辑
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        listViewModel.changeQueueState(false, taskType: .setOffset)
        onlyFullReloadWhenScrolling(false, taskType: .setOffset)
    }

    override func markForFlagAction(vm: FeedCardCellViewModel) {
        _markForFlag(vm)
    }

    // 切换type之后，需要将右侧设置为之前选中的状态
    private func resetSelect() {
        guard FeedSelectionEnable else {
            return
        }
        // 仅在Pad的R视图下消费feedSelection跳转
        guard listViewModel.dependency.styleService.currentStyle == .padRegular else {
            return
        }
        guard let selectedID = listViewModel.selectedID,
              let index = listViewModel.allItems().firstIndex(where: { $0.feedPreview.id == selectedID }) else {
            listViewModel.setSelected(feedId: nil)
            return
        }
        self.tableView.delegate?.tableView?(self.tableView, didSelectRowAt: IndexPath(row: index, section: 0))
    }
}
