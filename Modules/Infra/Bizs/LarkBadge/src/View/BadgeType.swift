//
//  BadgeType.swift
//  LarkBadge
//
//  Created by KT on 2019/4/18.
//

import Foundation
import UIKit
import UniverseDesignColor
import UniverseDesignTheme

// swiftlint:disable missing_docs
// 文本资源
public enum BadgeLabel {
    case text(String)
    case number(Int)
    case plusNumber(Int) // "前面带+号"

    public static let plus = "+"

    public var description: String {
        switch self {
        case .text(let text):
            return "text \(text)"
        case .number(let number):
            return "number \(number)"
        case .plusNumber(let number):
            return "plusNumber \(number)"
        }
    }
}

// 纯红点类型
public enum DotType {
    case lark // Lark统一红点，外面有圈圈
    case pin
    case web  // h5红点
    case todo // Todo红点

    public var description: String {
        switch self {
        case .lark:
            return "lark"
        case .pin:
            return "pin"
        case .web:
            return "web"
        case .todo:
            return "todo"
        }
    }
}

public enum BadgeType {
    case none                     // 默认值，如果没有设置类型，会取第一个子节点类型
    case clear                    // 指定没有 Badge
    case dot(DotType)             // 纯红点
    case label(BadgeLabel)        // Label
    case image(ImageSource)       // UIImageView
    case view(UIView)             // 自定义UIView
    case icon(UIImage, backgroundColor: UIColor = UIColor.ud.functionDangerContentDefault)   // 本地的icon图标，支持自定义背景颜色

    public var description: String {
        switch self {
        case .none:
            return "none"
        case .clear:
            return "clear"
        case .dot(let dot):
            return "dot \(dot.description)"
        case .label(let label):
            return "label \(label.description)"
        case .image(_):
            return "image"
        case .view(_):
            return "view"
        case .icon(_, _):
            return "icon"
        }
    }
}

public extension BadgeType {
    static var maxNumber: Int = 999
}

extension BadgeType: Equatable {
    public static func == (lhs: BadgeType, rhs: BadgeType) -> Bool {
        switch (lhs, rhs) {
        case (.image, .image): return true
        case (.icon, .icon): return true
        case (.label, .label): return true
        case (.view, .view): return true
        case (.dot, .dot): return true
        case (.none, .none): return true
        case (.clear, .clear): return true
        default: return false
        }
    }
}
// swiftlint:enable missing_docs
