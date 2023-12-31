//
//  CalendarApplicationDelegate.swift
//  Calendar
//
//  Created by zhuheng on 2021/3/10.
//

import Foundation
import Swinject
import RxSwift
import LarkAccountInterface
import LarkContainer
import AppContainer
import LKCommonsLogging
import NotificationUserInfo

final class CalendarApplicationDelegate: ApplicationDelegate {
    static public let config = AppContainer.Config(name: "Calendar", daemon: true)

    static let logger = Logger.log(CalendarApplicationDelegate.self, category: "calendar.launcher.delegate")

    required init(context: AppContext) {
    }
}
