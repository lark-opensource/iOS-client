//
//  FeedTeamViewController+FeedModuleVCInterface.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/7/13.
//

import Foundation
import LarkOpenFeed

extension FeedTeamViewController: FeedModuleVCInterface {
    func willActive() {
        viewModel.willActive()
        recoverSelectChat()
        preloadDetail()
    }

    func willResignActive() {
        viewModel.willResignActive()
    }

    func willDestroy() {}

    func doubleClickTabbar() {
        self.delegate?.backFirstList()
    }
}
