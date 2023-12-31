//
//  FeedMuteConfig.swift
//  LarkFeed
//
//  Created by liuxianyu on 2021/8/25.
//

import Foundation
import RustPB
import LarkOpenFeed
import RxSwift
import RxCocoa
import LarkAccountInterface
import LarkContainer

typealias FeedMuteConfigServiceProvider = () -> FeedMuteConfigService

// MARK: 免打扰筛选器配置

final class FeedMuteConfig: FeedMuteConfigService {
    let userResolver: UserResolver
    private var showMute: Bool = true

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    func getShowMute() -> Bool {
        return showMute
    }

    // TODO: 整个类以及涉及免打扰fg、分组fg的代码未来都会下掉，这些fg都已经全量很久
    func updateShowMute(_ showMute: Bool) {}

    func addMuteGroupEnable() -> Bool {
        return Feed.Feature(userResolver).addMuteGroupEnable
    }

    static func localShowMute(userResolver: UserResolver, _ filtersEnable: Bool, _ filterShowMute: Bool) -> Bool {
        var showMute: Bool
        if Feed.Feature(userResolver).groupSettingEnable {
            showMute = true
        } else {
            showMute = filterShowMute
        }
        FeedContext.log.info("feedlog/filter/setting/localShowMute. showMute: \(showMute)")
        return showMute
    }
}
