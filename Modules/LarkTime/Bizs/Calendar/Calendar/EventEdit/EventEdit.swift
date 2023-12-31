//
//  EventEditLog.swift
//  Calendar
//
//  Created by 张威 on 2020/6/5.
//

import UIKit
import CalendarFoundation
import LKCommonsLogging
import UniverseDesignColor

// MARK: Logger

enum EventEdit {
    static let logger = Logger.log(EventEdit.self, category: "lark.calendar.edit")

    static func logUnreachableLogic(file: String = #fileID,
                                    function: String = #function,
                                    line: Int = #line) {
        assertionFailure("should not excute code!")
        logger.warn("should not excute code!")
    }
}

// MARK: ActionSource

/// 描述日程编辑来源
extension EventEdit {
    enum ActionSource {
        case detail                 // 详情页
        case timeBlock              // 视图页 - 时间块
        case addButton              // 视图页 - +按钮
        case vcMenu                 // 视图页 - 预约会议
        case profile                // Profile - 忙闲
        case chatter                // Chatter - 忙闲
        case chat(scheduleConflictNum: Int,
                  attendeeNum: Int) // Chat - 忙闲
        case appLink                // AppLink
        case qrCode                 // 二维码签到
        case unknown                // 未知
    }
}

typealias EventEditActionSource = EventEdit.ActionSource

// MARK: UIStyle

extension EventEdit {
    enum UIStyle {}
}

typealias EventEditUIStyle = EventEdit.UIStyle

// 背景：创建页做了一次改版，目前使用的UI配置统一收敛到本文件中
// 参照：https://www.figma.com/file/4Qhq9CAnFRCKmPNzkpNcfa/Calendar-Mobile-Aurora?node-id=323%3A19911&mode=dev
extension EventEditUIStyle {
    enum Font {
        static let normalText = UIFont.systemFont(ofSize: 16)
        static let smallText = UIFont.systemFont(ofSize: 14)
        static let titleText = UIFont.ud.title2
    }

    enum Color {
        static let cellBackground = UIColor.ud.bgFloat
        static let cellBackgrounds = (UIColor.ud.bgFloat, UIColor.ud.bgFloat)
        static let normalText = UIColor.ud.textTitle
        static let normalGrayText = UIColor.ud.textPlaceholder
        static let blueText = UIColor.ud.primaryContentDefault
        static let horizontalSeperator = UIColor.ud.lineDividerDefault
        static let viewControllerBackground = UIColor.ud.bgFloat
        static let dynamicGrayText = UDColor.calendarEventEditTextPlaceholder
    }

    enum Layout {
        // 编辑页场景下content的左边margin
        static let eventEditContentLeftMargin: CGFloat = 46
        static let cellLeftIconSize = CGSize(width: 18, height: 18)
        static let iconLeftMargin = CGFloat(16)
        static let contentLeftMargin = CGFloat(48)
        static let accessoryRightMargin = CGFloat(16)
        static let avatarSize = CGSize(width: 32, height: 32)
        static let avatarSpaing: CGFloat = 8
        static let avatarContainerSize = CGSize(width: avatarSize.width + avatarSpaing, height: avatarSize.height)
        static let iconSize = CGSize(width: 16, height: 16)
        static let singleLineCellHeight = CGFloat(48)
        static let meetingRoomCellHeight = CGFloat(68)
        static let buildingPlaceHolderCellHeight = CGFloat(52)
        static let buildingCellHeight = CGFloat(64)
        static let secondaryPageCellHeight = CGFloat(48)
        static let horizontalSeperatorHeight = CGFloat(1.0 / UIScreen.main.scale)
        static let contentLeftPadding = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: 0)
    }
}
