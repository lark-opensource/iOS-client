//
//  LarkCalendarAssembly.swift
//  Lark
//
//  Created by Supeng on 2021/2/7.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import Swinject
import EENavigator
import RxSwift
import LarkAccountInterface
import Calendar
import LarkContainer
import AppContainer
import LKCommonsLogging
import NotificationUserInfo
import LarkAssembler
import LarkOpenFeed

public final class LarkCalendarAssembly: LarkAssemblyInterface {
    public init() {}

    public func getSubAssemblies() -> [LarkAssemblyInterface]? {
        CalendarAssembly()
    }

    public func registContainer(container: Container) {
        let userGraph = container.inObjectScope(.userV2)
        userGraph.register(CalendarDependency.self) { r -> CalendarDependency in
            try CalendarDependencyImpl(resolver: r)
        }

        userGraph.register(TodayEventDependency.self) { r -> TodayEventDependency in
            return try TodayEventDependencyImpl(userResolver: r)
        }
        
        userGraph.register(TimeBlockDependency.self) { r -> TimeBlockDependency in
            return try TimeBlockDependencyImpl(userResolver: r)
        }
    }

    @_silgen_name("Lark.Feed.FeedCard.Calendar")
    static public func registOpenFeed() {
        FeedCardModuleManager.register(moduleType: CalendarFeedCardModule.self)
        FeedActionFactoryManager.register(factory: { CalendarFeedActionJumpFactory() })
    }
}
