//
//  WPInternalDependency.swift
//  LarkWorkplace
//
//  Created by Meng on 2022/6/11.
//

import EENavigator
import Foundation
import LarkAccountInterface
import LarkContainer
import LarkFeatureGating
import LarkFoundation
import LarkGuide
import LarkNavigation
import LarkReleaseConfig
import LarkRustHTTP
import LarkSetting
import LarkTab
import LarkUIKit
import LKCommonsLogging
import LKCommonsTracker
import Photos
import WebBrowser

/// 原 WPDependency 部分内容迁移至此。
///
/// 原来当作模块外部依赖，其实可以在内部直接依赖，后续逐渐迁移消化掉。
/// 长期这里不再增加新的内部依赖。
final class WPInternalDependency {
    static let logger = Logger.log(WPInternalDependency.self)

    private let newGuideService: NewGuideService
    private let guideService: GuideService
    private let navigationService: NavigationService

    init(
        newGuideService: NewGuideService,
        guideService: GuideService,
        navigationService: NavigationService
    ) {
        self.newGuideService = newGuideService
        self.guideService = guideService
        self.navigationService = navigationService
    }
}

extension WPInternalDependency: WorkPlaceDependencyGuide {
    func shouldShow(key: String) -> Bool {
        newGuideService.checkShouldShowGuide(key: key)
    }

    func finishShow(key: String) {
        newGuideService.didShowedGuide(guideKey: key)
    }
}

extension WPInternalDependency: WorkplaceInternalDependencyNavation {
    /// 给定的 nativeKey 对应的 Tab 是否在 mainTabs 或 quickTabs 当中
    func isInTabs(for nativeKey: String) -> Bool {
        guard let tab = Tab.getTab(appType: .native, key: nativeKey) else {
            return false
        }
        return navigationService.checkInTabs(for: tab)
    }
}
