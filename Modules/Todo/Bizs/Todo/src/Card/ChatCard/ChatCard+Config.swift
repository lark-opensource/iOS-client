//
//  ChatCard+Config.swift
//  Todo
//
//  Created by wangwanxin on 2022/2/28.
//

import Foundation
import UniverseDesignFont

// UI 配置文件，忽略魔法数检查
// nolint: magic number
extension ChatCard {

    enum TimeComponentStyle {
        case dailyRemind /// 每日提醒
        case normal // 常规卡片
    }

}

extension ChatCard.TimeComponentStyle {

    var font: UIFont {
        switch self {
        case.dailyRemind:
            return UDFont.caption1
        case.normal:
            return  UDFont.body2
        }
    }

    var numberOfLines: Int {
        switch self {
        case.dailyRemind:
            return 1
        case.normal:
            return 2
        }
    }

    var textMarginTop: CGFloat {
        switch self {
        case.dailyRemind:
            return 2
        case.normal:
            return 12
        }
    }

    var textHeight: CGFloat {
        switch self {
        case.dailyRemind:
            return 20
        case.normal:
            return 22
        }
    }

    var isDisplayIcon: Bool {
        switch self {
        case.dailyRemind:
            return false
        case.normal:
            return true
        }
    }

    var squareIconWidth: CGFloat {
        switch self {
        case.dailyRemind:
            return 14
        case.normal:
            return 16
        }
    }

    var iconMarginTop: CGFloat {
        // 为减少计算直接写死3，计算方式为(textHeight - squareIconWidth) * 0.5 = 3
        return textMarginTop + 3
    }

}
