//
//  AllFeedListViewModel+PullConfig.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/8/25.
//

import Foundation

extension AllFeedListViewModel {
    /// 拉取LoadConfig，且只需要拉一次即可
    func pullConfig() {
        loadConfig.pull(dependency)
    }
}
