//
//  CalendarViewStyle.swift
//  Calendar
//
//  Created by linlin on 2017/11/21.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import UIKit
// swiftlint:disable nesting
import CalendarFoundation
final class CalendarViewStyle {
    final class Background {
        /// 顶部空白高度
        static let topGridMargin: CGFloat = 20
        /// 一个小时的高度
        static let hourGridHeight: CGFloat = 50
        /// 底部空白高度
        static let bottomGridMargin: CGFloat = 20

        static let currentDataBackgroundColor = UIColorRGBAToRGB(rgbBackground: UIColor.ud.bgBase, rgbaColor: UIColor.ud.N100.withAlphaComponent(0.3))
        /// 一整天对应的高度
        static var wholeDayHeight: CGFloat {
            return topGridMargin + Background.hourGridHeight * 24 + Background.bottomGridMargin
        }

        static let timeLineRightPandding: CGFloat = 5

    }

    final class TimeRuler {
        final class TimeLabel {
            static let textFont = UIFont.cd.dinBoldFont(ofSize: 11)
            static let textColor = UIColor.ud.textPlaceholder
            static let textMoveColor = UIColor.ud.primaryFillHover
        }
    }

    final class AddNewEventButton {
        static let buttonHeight: CGFloat = 48.0
        static let rightMargin: CGFloat = -16.0
        static let bottomMargin: CGFloat = -4
    }
}
// swiftlint:enable nesting
