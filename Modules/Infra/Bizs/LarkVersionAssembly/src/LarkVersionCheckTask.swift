//
//  LarkVersionCheckTask.swift
//  LarkVersionAssembly
//
//  Created by 张威 on 2022/1/19.
//

import Foundation
import BootManager
import Swinject
import LarkContainer
import LarkFeatureGating
import LarkVersion
#if canImport(LarkOpenFeed)
import LarkOpenFeed
#endif

final class LarkVersionCheckTask: FlowBootTask, Identifiable {
    static var identify = "VersionCheckTask"

    override var scheduler: Scheduler { return .async }

#if canImport(LarkMessengerInterface)
    @Provider private var feedContextService: FeedContextService
#endif
    @Provider private var versionService: VersionUpdateService

    override func execute(_ context: BootContext) {
        // lint:disable lark_storage_check
        // TODO: 待清理出去 @yangjing
        /// FG 打开 关闭之前强制返回 updateVisibleItemsAnimated == 1的问题
        UserDefaults.standard.set(LarkFeatureGating.shared.getFeatureBoolValue(for: "lark.menu.forbid.force.show"), forKey: "lark.menu.forbid.force.show")
        /// FG 打开 当Menu的上的按钮都是无效的时候，自动隐藏 updateVisibleItemsAnimated == 0
        UserDefaults.standard.set(LarkFeatureGating.shared.getFeatureBoolValue(for: "lark.menu.hide.invalid.items"), forKey: "lark.menu.hide.invalid.items")
        // lint:enable lark_storage_check

        versionService.setup()

#if canImport(LarkMessengerInterface)
        // feed appear 后，检查是否需要展示版本升级提示弹窗
        let feedViewDidAppear: FeedPageState = .viewDidAppear
        let observable = feedContextService.pageAPI.pageStateObservable.asObservable()
            .filter { $0.rawValue == feedViewDidAppear.rawValue }
            .map { _ in () }
        let trigger = VersionCheckTrigger(observable: observable, source: .feedDidAppear)
        versionService.addCheckTrigger(trigger)
#endif
    }

}
