//
//  CalendarClean.swift
//  Calendar
//
//  Created by Rico on 2023/7/12.
//

import LarkClean
import LarkStorage

extension CleanRegistry {
    @_silgen_name("Lark.LarkClean_CleanRegistry.Calendar")
    public static func registerCalendar() {
        registerPaths(forGroup: "calendar") { ctx in
            let users = ctx.userList
            return users.flatMap { user -> [CleanIndex.Path] in
                let basePath: IsoPath = .in(space: .user(id: user.userId), domain: Domain.biz.calendar)
                    .build(forType: .library, relativePart: "home")
                return [
                    .abs((basePath + "instance").absoluteString),
                    .abs((basePath + "calendar").absoluteString),
                    .abs((basePath + "setting").absoluteString)
                ]
            }
        }
    }
}
