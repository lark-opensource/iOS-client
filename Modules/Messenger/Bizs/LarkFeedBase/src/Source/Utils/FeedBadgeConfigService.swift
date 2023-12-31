//
//  FeedBadgeConfigService.swift
//  LarkFeedBase
//
//  Created by xiaruzhen on 2023/9/6.
//

import Foundation
import RxSwift
import RxRelay
import RustPB

// MARK: Feed Badge 配置

public protocol FeedBadgeConfigService {

    // feed badge style
    static var badgeStyle: Settings_V1_BadgeStyle { get }
    var badgeStyleObservable: Observable<Settings_V1_BadgeStyle> { get }

    // 是否显示主导航免打扰badge
    static var showTabMuteBadge: Bool { get }
    var tabMuteBadgeObservable: Observable<Bool> { get }
}

public struct FeedBadgeBaseConfig {
    // feed badge style
    public static var badgeStyle: Settings_V1_BadgeStyle = .weakRemind
    // 是否显示主导航免打扰badge
    public static var showTabMuteBadge: Bool = true
}
