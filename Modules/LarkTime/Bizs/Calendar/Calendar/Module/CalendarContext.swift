//
//  CalendarContext.swift
//  Calendar
//
//  Created by zhuheng on 2021/3/10.
//

import UIKit
import Foundation
import CalendarFoundation
import EventKit

// calendar 内部使用，以后会逐渐废弃
// 使用的地方先用 interface 替代
protocol CalendarContext {
    /// 日程详情页
    func getEventContentController(with key: String,
                                        calendarId: String,
                                        originalTime: Int64,
                                        startTime: Int64?,
                                        endTime: Int64?,
                                        instanceScore: String,
                                        isFromChat: Bool,
                                        isFromNotification: Bool,
                                        isFromMail: Bool,
                                        isFromTransferEvent: Bool,
                                        isFromInviteEvent: Bool,
                                   scene: EventDetailScene) -> UIViewController

    func getLocalDetailController(ekEvent: EKEvent) -> UIViewController

}
