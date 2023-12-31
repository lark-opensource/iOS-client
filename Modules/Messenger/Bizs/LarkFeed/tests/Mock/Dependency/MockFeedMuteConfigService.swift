//
//  MockMuteConfig.swift
//  LarkFeed-Unit-Tests
//
//  Created by 白镜吾 on 2023/9/7.
//

import Foundation
import LarkSDKInterface
import LarkOpenFeed
import LarkContainer
import RustPB
import RxSwift
import RxRelay
import LarkModel
@testable import LarkFeed

typealias MockFeedMuteConfigServiceProvider = () -> FeedMuteConfigService

// MARK: 免打扰筛选器配置
final class MockFeedMuteConfig: FeedMuteConfigService {
    private var showMute: Bool = true

    func getShowMute() -> Bool { return showMute }

    func updateShowMute(_ showMute: Bool) {}

    func addMuteGroupEnable() -> Bool { return true}

    static func localShowMute(userResolver: UserResolver, _ filtersEnable: Bool, _ filterShowMute: Bool) -> Bool { return true }
}
