//
//  WorkplaceStartUpTask.swift
//  LarkWorkplace
//
//  Created by Meng on 2023/5/5.
//

import Foundation
import BootManager
import LarkContainer
import AppContainer
import LKCommonsLogging
import RxSwift
import LarkTab
import LarkSetting
import RunloopTools

/// 工作台登录后配置逻辑
final class WorkplaceStartUpTask: UserFlowBootTask, Identifiable {
    static let logger = Logger.log(WorkplaceStartUpTask.self)

    static var identify: TaskIdentify = "WorkplaceStartUpTask"

    override class var compatibleMode: Bool { WorkplaceScope.userScopeCompatibleMode }

    override var scheduler: Scheduler { .concurrent }

    override func execute() throws {
        Self.logger.info("execute \(WorkplaceStartUpTask.self)")
        let configService = try userResolver.resolve(assert: WPConfigService.self)
        let badgeServiceContainer = try userResolver.resolve(assert: WPBadgeServiceContainer.self)
        let prefetchService = try userResolver.resolve(assert: WorkplacePrefetchService.self)

        RunloopDispatcher.shared.addTask(identify: "workplacePreFetch") {
            Self.logger.info("start prefetch service")
            prefetchService.start()
        }

        // 监听 tab badge
        badgeServiceContainer.subscribeTab()
        badgeServiceContainer.start()
    }
}
