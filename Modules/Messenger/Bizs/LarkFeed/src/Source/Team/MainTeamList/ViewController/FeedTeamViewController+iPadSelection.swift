//
//  FeedTeamViewController+iPadSelection.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/7/13.
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
extension FeedTeamViewController {
    /// 选中态
    func subscribeSelect() {
        guard FeedSelectionEnable else {
            return
        }
        self.viewModel.observeSelect()
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: nil)
            .drive(onNext: { [weak self] feedId in
                guard let self = self else { return }
                // R视图下且feedId为nil, 需要展示占位VC
                var isCollapsed: Bool
                if let larkSplitViewController = self.larkSplitViewController {
                    isCollapsed = larkSplitViewController.isCollapsed
                } else {
                    isCollapsed = self.view.horizontalSizeClass != .regular
                }
                if !isCollapsed, feedId == nil {
                    self.navigator.showDetail(SplitViewController.defaultDetailController(), from: self.parent ?? self)
                }
                self.viewModel.updateChatSelected(feedId)
                self.viewModel.reload()
            }).disposed(by: disposeBag)

        // 监听 split 切换 detail 页面信号
        NotificationCenter.default.rx
            .notification(SplitViewController.SecondaryControllerChange).subscribe(onNext: { [weak self] (noti) in
            if let splitVC = noti.object as? SplitViewController,
               let currentSplitVC = self?.larkSplitViewController,
               splitVC == currentSplitVC,
               let detail = splitVC.viewController(for: .secondary) {
                var topVC = detail
                if let nav = detail as? UINavigationController,
                   let firstVC = nav.viewControllers.first {
                    topVC = firstVC
                }
                /// 首页为默认 default 页面, 取消选中态
                if topVC is DefaultDetailVC {
                    self?.viewModel.setSelected(feedId: nil)
                }
            }
        }).disposed(by: disposeBag)
    }

    // 切换type之后，需要将右侧设置为之前选中的状态
    func recoverSelectChat() {
        guard FeedSelectionEnable else {
            return
        }
        guard let indexPath = viewModel.findSelectedIndexPath() else {
            viewModel.setSelected(feedId: nil)
            return
        }
        self.tableView.delegate?.tableView?(self.tableView, didSelectRowAt: indexPath)
    }

    // CR切换, 触发刷新
    func viewWillTransitionForPad(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        if FeedSelectionEnable {
            viewModel.reload()
        }
    }
}
