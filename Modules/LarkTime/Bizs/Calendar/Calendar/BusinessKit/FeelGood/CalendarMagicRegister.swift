//
//  CalendarMagicRegister.swift
//  Calendar
//
//  Created by Rico on 2021/4/13.
//

import Foundation
import LarkContainer
import LarkMagic

/// 满意度调研
final class CalendarMagicRegister: UserResolverWrapper {
    static let scenarioID = "calendar"
    var magicInterceptor = CalendarMagicInterceptor()
    @ScopedProvider private var larkMagicService: LarkMagicService?

    let userResolver: UserResolver

    init(userResolver: UserResolver, containerProvider: @escaping ContainerProvider) {
        self.userResolver = userResolver
        larkMagicService?.register(scenarioID: CalendarMagicRegister.scenarioID,
                                  interceptor: magicInterceptor,
                                  containerProvider: containerProvider)
    }

    deinit {
        larkMagicService?.unregister(scenarioID: CalendarMagicRegister.scenarioID)
    }
}

final class CalendarMagicInterceptor: ScenarioInterceptor {
    var isAlterShowing: Bool = false
    var isPopoverShowing: Bool = false
    var isDrawerShowing: Bool = false
    var isModalShowing: Bool = false
    var otherInterceptEvent: Bool = false

    init() {
    }
}
