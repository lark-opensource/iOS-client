//
//  FeedThreeBarServiceImpl.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/10/8.
//

import Foundation
import LarkOpenFeed

final class FeedThreeBarServiceImpl: FeedThreeBarService {
    let feed3BarStyleService: Feed3BarStyleService
    init(feed3BarStyleService: Feed3BarStyleService) {
        self.feed3BarStyleService = feed3BarStyleService
    }

    var padUnfoldStatus: Bool? {
        return feed3BarStyleService.padUnfoldStatus
    }

    var currentStyle: Feed3BarStyle {
        return feed3BarStyleService.currentStyle
    }
}
