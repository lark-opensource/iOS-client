//
//  CalendarLauncherDelegate.swift
//  Calendar
//
//  Created by zhuheng on 2022/2/17.
//
import LarkAccountInterface
import Foundation
import LarkContainer

public final class CalendarLauncherDelegate: PassportDelegate {
    public var name: String = "CalendarLauncherDelegate"

    public func userDidOnline(state: LarkAccountInterface.PassportState) {
        guard let userID = state.user?.userID,
              let userResolver = try? Container.shared.getUserResolver(userID: userID) else { return }
        // 切租户后更新一次 calendar，避免缓存失效
        if case PassportUserAction.switch = state.action {
            let manager = try? userResolver.resolve(assert: CalendarManager.self)
            manager?.updateRustCalendar()
        }
    }
}
