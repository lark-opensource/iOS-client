//
//  FeedMainViewController+Header.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/12/22.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa

extension FeedMainViewController {

    // MARK: bind
    func bindHeaderViewModels() {
        headerView.updateHeightDriver.drive(onNext: { [weak self] (height, updateHeightStyle) in
            guard let self = self else { return }
            FeedContext.log.info("feedlog/header/height. height: \(height), style: \(updateHeightStyle)")
            switch updateHeightStyle {
            case .normal:
                self.updateHeightForNormal(height)
            case .expandByScrollForShortcut:
                self.updateHeightWithAnimate(height, isForceOffset: true)
            case .collapseByScrollForShortcut:
                self.updateHeightByCollapseForShortcut(height)
            case .expandCollapseByClickForShortcut:
                self.updateHeightWithAnimate(height)
            }
            self.setVibrateStatus()
        }).disposed(by: disposeBag)

        bindFeedPreviewForShortcut()
    }

    func bindFeedPreviewForShortcut() {
        mainViewModel.allFeedsViewModel.feedPreviewSubject.asObservable().subscribe(onNext: { [weak self] feeds in
            guard !feeds.isEmpty else { return }
            self?.headerView.updateShortcut(feeds: feeds)
        }).disposed(by: disposeBag)
    }

    /// 更新header高度 - 不带动画
    private func updateHeightForNormal(_ height: CGFloat) {
        updateHeaderHeight(height)
        self.headerView.layout()
        self.view.layoutIfNeeded()
    }

    /// 更新header高度 - 带动画
    private func updateHeightWithAnimate(_ height: CGFloat, isForceOffset: Bool = false) {
        updateHeaderHeight(height)
        mainScrollView.bounces = false
        UIView.animate(withDuration: 0.25) {
            self.headerView.layout()
            self.view.layoutIfNeeded()
            //当下拉展开时，需要重置为默认offset，避免展开时出现上移的现象
            if isForceOffset {
                self.setContentOffset(.zero, animated: false)
            }
        } completion: { _ in
            self.mainScrollView.bounces = true
        }
    }

    /// 更新header高度：shortcut 通过 上滑操作 进行收起的特化
    private func updateHeightByCollapseForShortcut(_ height: CGFloat) {
        updateHeaderHeight(height)
        self.setContentOffset(CGPoint(x: 0, y: headerView.heightAboveShortcut), animated: false)
        self.headerView.layout()
    }

    private func updateHeaderHeight(_ height: CGFloat) {
        headerView.snp.updateConstraints { (make) in
            make.height.equalTo(height)
        }
    }

    /// 设置是否可以震动
    private func setVibrateStatus() {
        isAllowVibrate = headerView.preAllowVibrate
    }
}
