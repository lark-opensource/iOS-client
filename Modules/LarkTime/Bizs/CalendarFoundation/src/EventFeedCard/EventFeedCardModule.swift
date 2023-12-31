//
//  EventFeedCardModule.swift
//  CalendarFoundation
//
//  Created by chaishenghua on 2023/8/1.
//

import LarkContainer

public struct EventFeedCardTrace {
    public let feedIsTop: Bool
    public let feedTab: String

    public init(feedIsTop: Bool = false, feedTab: String = "") {
        self.feedIsTop = feedIsTop
        self.feedTab = feedTab
    }
}

public final class EventFeedCardModule {
    private static var subModulesTypes: [EventFeedCardSubModule.Type] = []

    public var subModules: [EventFeedCardType: EventFeedCardSubModule] = [:]

    public static func register(type: EventFeedCardSubModule.Type) {
        Self.subModulesTypes.append(type)
    }

    public init(userResolver: UserResolver, trace: EventFeedCardTrace) {
        Self.subModulesTypes.forEach({
            self.subModules[$0.identifier] = $0.init(userResolver: userResolver, trace: trace)
        })
    }

    deinit {
        self.subModules.values.forEach({ $0.destroy() })
    }
}
