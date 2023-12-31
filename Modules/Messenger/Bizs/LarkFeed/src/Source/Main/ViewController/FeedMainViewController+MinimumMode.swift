//
//  FeedMainViewController+MinimumMode.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/5/10.
//

import UIKit
import Foundation
import AnimatedTabBar

// 基本功能模式
extension FeedMainViewController: MinimumModeTipViewDelegate {

    func showMinimumModeTipView() {
        guard minimumModeTipView == nil else {
            return
        }
        let minimumModeTipView = MinimumModeTipView()
        self.minimumModeTipView = minimumModeTipView
        minimumModeTipView.delegate = self
        view.addSubview(minimumModeTipView)
        let bottom = animatedTabBarController?.tabbarHeight ?? MiniModeCons.tabbarHeight
        minimumModeTipView.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
            make.bottom.equalToSuperview().offset(-(bottom + 24))
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 7) {
            self._removeMinimumModeTipView()
        }
    }

    func minimumModeTipViewDismiss(_ minimumModeTipView: MinimumModeTipView) {
        _removeMinimumModeTipView()
    }

    func _removeMinimumModeTipView() {
        guard minimumModeTipView != nil else { return }
        UIView.animate(withDuration: 0.15) {
            self.minimumModeTipView?.alpha = 0
        } completion: { _ in
            self.minimumModeTipView?.removeFromSuperview()
        }
    }

    func showMinimumModeTipViewIfNeed() {
        guard mainViewModel.dependency.showMinimumModeTipViewEnable() else { return }
        mainViewModel.feedDependency.showMinimumModeChangeTip { [weak self] in
            DispatchQueue.main.async {
                self?.showMinimumModeTipView()
            }
        }
    }

    enum MiniModeCons {
        static let tabbarHeight: CGFloat = 52.0
    }
}
