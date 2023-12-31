//
//  BadgeStyle.swift
//  LarkBadge
//
//  Created by KT on 2020/3/4.
//

import UIKit
import Foundation

// swiftlint:disable missing_docs
/// Badge样式  优先级 > CommonStyle
public enum BadgeStyle {
    case strong // 强提醒 红色
    case middle // 中等提醒 粉红 目前只用于Feed Done
    case weak   // 弱提醒 灰色

    var textColor: UIColor {
        switch self {
        case .strong: return UIColor.ud.primaryOnPrimaryFill
        case .weak: return UIColor.ud.primaryOnPrimaryFill
        case .middle: return UIColor.ud.functionDangerContentDefault
        }
    }

    var backgroundColor: UIColor {
        switch self {
        case .strong: return UIColor.ud.functionDangerContentDefault
        case .weak: return UIColor.ud.iconDisabled
        case .middle: return UIColor.ud.R100
        }
    }

    var moreImage: DefaultImage {
        switch self {
        case .strong: return .more(.strong)
        case .weak: return .more(.weak)
        case .middle: return .more(.middle)
        }
    }

    public var description: String {
        switch self {
        case .strong:
            return "strong"
        case .middle:
            return "middle"
        case .weak:
            return "weak"
        }
    }
}

public extension BadgeType {
    /// 上面stong/weak的Style，可以作用于哪些type
    var enableBadgeStyle: Bool {
        switch self {
        case .label, .dot(.lark), .dot(.pin): return true
        default: return false
        }
    }
}
// swiftlint:enable missing_docs
