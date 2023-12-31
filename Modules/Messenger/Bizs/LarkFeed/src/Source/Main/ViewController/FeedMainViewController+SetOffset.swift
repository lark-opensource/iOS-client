//
//  FeedMainViewController+SetOffset.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/7/9.
//

import UIKit
import Foundation

extension FeedMainViewController {
    func setContentOffset(_ offset: CGPoint, animated: Bool) {
        mainScrollView.setContentOffset(offset, animated: animated)
    }

    func setSubScrollContentOffset(_ offset: CGPoint, animated: Bool) {
        self.moduleVCContainerView.currentListVC?.setContentOffset(offset, animated: animated)
    }

}
