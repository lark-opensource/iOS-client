//
//  NewEventViewUIStyle.swift
//  Calendar
//
//  Created by zhuchao on 2017/12/14.
//  Copyright © 2017年 EE. All rights reserved.
//

import UniverseDesignIcon
import UIKit
import CalendarFoundation
final class NewEventViewUIStyle {
    static let animationDuration: TimeInterval = 0.3
    // font
    final class Font {
        static let save = UIFont.cd.regularFont(ofSize: 16)
        static let content = UIFont.cd.mediumFont(ofSize: 22)
        static let date = UIFont.cd.dinBoldFont(ofSize: 17)
        static let subDate = UIFont.cd.regularFont(ofSize: 14)
        static let week = UIFont.cd.regularFont(ofSize: 14)
        static let normalText = UIFont.cd.regularFont(ofSize: 16)
        static let tabBar = UIFont.cd.regularFont(ofSize: 11)
        static let attendeeCount = UIFont.cd.regularFont(ofSize: 14)
    }

    final class Color {
        static let background = UIColor.ud.bgBase
        static let normalText = UIColor.ud.textTitle
        static let grayText = UIColor.ud.textPlaceholder
        static let blueBackground = UIColor.ud.primaryContentDefault
        static let redBackground = UIColor.ud.functionDangerContentPressed
        static let tabBarText = UIColor.ud.textCaption
        static let tabBarTextRed = redBackground
    }

    // image
    final class Image {
        private static let grayColor = UIColor.ud.textDisable
        static let close = UDIcon.getIconByKeyNoLimitSize(.closeOutlined).renderColor(with: .n1)
        static let increaseContacts = UDIcon.getIconByKeyNoLimitSize(.addOutlined).renderColor(with: .n3)
        static let littleClose = UDIcon.getIconByKeyNoLimitSize(.closeOutlined).renderColor(with: .n2)
        static let access = UDIcon.getIconByKeyNoLimitSize(.rightOutlined).renderColor(with: .n3)
        static let alarmIcon = UDIcon.getIconByKeyNoLimitSize(.bellOutlined).renderColor(with: .n3)
        static let meetingRoomIcon = UDIcon.getIconByKeyNoLimitSize(.roomOutlined).renderColor(with: .n3)
        static let repeatIcon = UDIcon.getIconByKeyNoLimitSize(.repeatOutlined).renderColor(with: .n3)
        static let noteIcon = UDIcon.getIconByKeyNoLimitSize(.describeOutlined).renderColor(with: .n3)
//        static let eventLocationIcon = UIImage.cd.image(named: "newEventLocation").withRenderingMode(.alwaysOriginal)
        static let currentLocationIcon = UIImage.cd.image(named: "location_icon").withRenderingMode(.alwaysOriginal)
        static let meetingRoomIconGray = UDIcon.getIconByKeyNoLimitSize(.roomUnavailableOutlined).renderColor(with: .n3)

        static let calendarIcon =
            UDIcon.getIconByKeyNoLimitSize(.calendarOutlined).renderColor(with: .n3)

        // 有内容，左侧
        static let locationLightgrayIcon = UDIcon.getIconByKeyNoLimitSize(.localOutlined).renderColor(with: .n3)

        // 无内容，下方
    }

    final class Margin {
        static let cellHeight: CGFloat = 52.0
        static let cellTextLeftMargin: CGFloat = 45.0
        static let leftMargin: CGFloat = 16.0
        static let rightMargin: CGFloat = -15.0
        static let blankCellHeight: CGFloat = 8.0
        static let subModuleHeaderHeight: CGFloat = 71.0
        static let navgationBarHeight: CGFloat = 44.0
        static let datePickerHeight: CGFloat = 156.0
        static let tabBarHeight: CGFloat = 70.0
        static let tableViewHeaderHeight: CGFloat = 52.0
        static let attendeeViewHeight: CGFloat = 56.0
        static let attendeeArrangementHeight: CGFloat = 52.0
        static let timeRangeViewHeight: CGFloat = 68.0
        static let attendeeAvatarSize: CGSize = CGSize(width: 32, height: 32)
        static let locationCellHeight: CGFloat = 70.0
        static let timeItemLeftMargin: CGFloat = 15.0
    }
}
