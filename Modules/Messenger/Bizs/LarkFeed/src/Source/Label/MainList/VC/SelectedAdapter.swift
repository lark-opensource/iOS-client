//
//  SelectedAdapter.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2022/4/21.
//

import UIKit
import Foundation
import RxSwift
import EENavigator
import LarkSplitViewController
import LarkUIKit
import RustPB
import LarkMessengerInterface

/// For iPad Selection
final class SelectedAdapter: AdapterInterface {
    private weak var page: LabelMainListViewController?
    private let vm: LabelMainListViewModel
    private let disposeBag = DisposeBag()
    private var emptyView: UIView?

    init(vm: LabelMainListViewModel) {
        self.vm = vm
    }

    func setup(page: LabelMainListViewController) {
        self.page = page
        subscribeSelect()
    }

    /// 选中态
    func subscribeSelect() {
        guard FeedSelectionEnable else { return }
        guard let page = self.page else { return }
        page.vm.dependency.selectFeedObservable
//            .distinctUntilChanged()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak page] info in
                guard let page = page, page.vm.isActive else { return }
                if let info = info, info.filterTabType != .tag {
                    return
                }
                var isCollapsed: Bool
                if let larkSplitViewController = page.larkSplitViewController {
                    isCollapsed = larkSplitViewController.isCollapsed
                } else {
                    isCollapsed = page.view.horizontalSizeClass != .regular
                }
                // R视图下且feedId为nil, 需要展示占位VC
                if !isCollapsed, info?.feedId == nil {
                    page.navigator.showDetail(SplitViewController.defaultDetailController(), from: page.parent ?? page)
                }
                let item: EntityItem?
                if let info = info, let feedId = Int(info.feedId ?? ""), let parentId = Int(info.parendId ?? "") {
                    item = EntityItem(id: feedId, parentId: parentId, position: 0, updateTime: 0)
                } else {
                    item = nil
                }
                page.vm.selectedModule.storeSelectedItem(item)
                page.vm.dataModule.trigger()
            }).disposed(by: disposeBag)

        // 监听 split 切换 detail 页面信号
        NotificationCenter.default
            .rx.notification(SplitViewController.SecondaryControllerChange)
            .subscribe(onNext: { [weak page] (noti) in
                guard let page = page, page.vm.isActive else { return }
                if let splitVC = noti.object as? SplitViewController,
                   let currentSplitVC = page.larkSplitViewController,
                   splitVC == currentSplitVC,
                   let detail = splitVC.viewController(for: .secondary) {
                    var topVC = detail
                    if let nav = detail as? UINavigationController,
                       let firstVC = nav.viewControllers.first {
                        topVC = firstVC
                    }
                    /// 首页为默认 default 页面, 取消选中态
                    if topVC is DefaultDetailVC {
                        page.vm.selectedModule.cancelSelected()
                    }
                }
        }).disposed(by: disposeBag)
    }

    /// CR切换, 触发刷新
    func viewWillTransitionForPad(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        guard FeedSelectionEnable else { return }
        guard let page = self.page else { return }
        page.vm.dataModule.trigger()
    }

    // 切换type之后，需要将右侧设置为之前选中的状态
    func recoverSelectChat() {
        guard FeedSelectionEnable else { return }
        guard let page = self.page else { return }
        guard let indexPath = page.vm.selectedModule.findSelectedIndexPath() else {
            vm.selectedModule.cancelSelected()
            return
        }
        page.tableView.delegate?.tableView?(page.tableView, didSelectRowAt: indexPath)
    }
}
