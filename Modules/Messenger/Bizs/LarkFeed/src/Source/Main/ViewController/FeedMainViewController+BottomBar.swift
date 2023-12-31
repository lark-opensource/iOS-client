//
//  FeedMainViewController+BottomBar.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/9/28.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa

extension FeedMainViewController {
    func bindBottomBar() {
        bottomBarView.updateHeightDriver.distinctUntilChanged().drive(onNext: { [weak self] (height) in
            guard let self = self else { return }
            FeedContext.log.info("feedlog/bottomBar/updateBottomConstraint \(height)")
            self.updateBottomBarViewBottomConstraint(height)
        })
    }

    private func updateBottomBarViewBottomConstraint(_ height: CGFloat) {
        bottomBarView.snp.updateConstraints { (make) in
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(height)
        }
        self.bottomBarView.layoutIfNeeded()
    }
}
