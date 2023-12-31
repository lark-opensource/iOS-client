//
//  PathConfig.swift
//  LarkBadge
//
//  Created by KT on 2020/3/4.
//

import Foundation

// swiftlint:disable missing_docs

// 更新Node配置的优先级
public enum ConfigPriorty: Int {
    case none = 0
    case initial    // 初始化
    case locoal     // 本地指定
    case force      // 强制刷新，忽略本地配置
}

// 隐藏逻辑
public enum HiddenStrategy {
    case strong     // 子路径清空才消除 -> 强提醒
    case weak       // 点击消除 -> 弱提醒
}

public extension BadgeType {
    var strategy: HiddenStrategy {
        switch self {
        default: return .strong
        }
    }

    // 父节点下有多个子节点，排序优先级
    var childPriority: Int {
        switch self {
        case .clear:          return 0
        case .none:           return 1
        case .dot:            return 2
        case .label(.plusNumber): return 3
        case .label(.number): return 4
        case .label(.text):   return 5
        case .image(.default): return 6
        case .image(.locol):  return 7
        case .image(.web):    return 8
        case .icon:           return 9
        case .image(.image):  return 10
        case .image(.key):    return 11
        case .view:           return 12
        }
    }
}
// swiftlint:enable missing_docs
