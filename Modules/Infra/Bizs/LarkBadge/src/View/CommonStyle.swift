//
//  CommonStyle.swift
//  LarkBadge
//
//  Created by KT on 2020/3/4.
//

import UIKit
import Foundation
import UniverseDesignFont

// swiftlint:disable missing_docs
// Badge 基本样式
public extension BadgeType {
    /// 中心偏移
    var offset: CGPoint {
        switch self {
        case .image(.default(.new)): return CGPoint(x: -15, y: 15)
        default: return .zero
        }
    }

    var size: CGSize {
        switch self {
        case .image(.default(.more)):
            return CGSize(width: 24, height: 19)
        case .image(.default(.new)):
            return CGSize(width: 30, height: 30)
        case .image(.default(.edit)):
            return CGSize(width: 16, height: 16)
        case .dot(.lark):
            return CGSize(width: 10, height: 10)
        case .dot(.pin):
            return CGSize(width: 10, height: 10)
        case .dot(.web):
            return CGSize(width: 8, height: 8)
        case .image:
            return CGSize(width: 16, height: 16)
        case .none:
            return .zero
        default:
            return CGSize(width: 16, height: 16)
        }
    }

    var autoSize: CGSize {
        return size.auto()
    }

    var cornerRadius: CGFloat {
        switch self {
        case .none, .view: return 0
        default: return self.size.height / 2.0
        }
    }

    var autoCornerRadius: CGFloat {
        switch self {
        case .none, .view: return 0
        default: return autoSize.height / 2.0
        }
    }

    var horizontalMargin: CGFloat {
        switch self {
        case .label: return 6
        default: return 0
        }
    }

    var backgroundColor: UIColor {
        switch self {
        case .dot(.web): return UIColor.ud.functionDangerContentDefault
        case .dot(.lark): return UIColor.ud.functionDangerContentDefault
        case .dot(.pin): return UIColor.ud.functionDangerContentDefault
        case .label: return UIColor.ud.functionDangerContentDefault
        case .icon(_, let color): return color
        default: return .clear
        }
    }

    var borderColor: UIColor {
        switch self {
        case .label, .dot(.lark), .dot(.pin): return UIColor.ud.bgBody
        default: return .clear
        }
    }

    var borderWidth: CGFloat { 0.0 }

    var textSize: CGFloat {
        switch self {
        case .label:    return 12
        default:        return 0
        }
    }

    var autoTextSize: CGFloat {
        return textSize.auto()
    }
}
// swiftlint:enable missing_docs
