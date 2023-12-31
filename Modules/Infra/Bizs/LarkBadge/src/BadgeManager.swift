//
//  BadgeManager.swift
//  LarkBadge
//
//  Created by KT on 2019/4/22.
//

import Foundation

/// Badge路径统一方法
public struct BadgeManager {

    // 设置依赖
    public static func setDependancy(with dependancy: BadgeDependancy) {
        shared.dependancy = dependancy
    }

    /// 设置Badgey类型
    ///
    /// - Parameters:
    ///   - path: 目标节点完整路径
    ///   - type: 目标节点类型 (默认红点)
    ///   - strategy: 隐藏逻辑（依赖消除/点击消除）
    public static func setBadge(_ path: Path, type: BadgeType = .dot(.lark), strategy: HiddenStrategy = .strong) {
        NodeTrie.setBadge(path.nodeNames, type: type, strategy: strategy)
    }

    /// 设置Badgey类型 - 自定义Node
    ///
    /// - Parameters:
    ///   - path: 目标节点完整路径
    ///   - type: 目标节点类型 (默认红点)
    ///   - nodeConfig: 自定义样式
    public static func setBadge(_ path: Path, type: BadgeType = .dot(.lark), nodeConfig: (inout NodeInfo) -> Void) {
        var info = NodeInfo(type)
        info.type = type // call didSet
        nodeConfig(&info)
        NodeTrie.setBadge(path.nodeNames, info)
    }

    /// 删除目标节点
    ///
    /// - Parameters:
    ///   - path: 目标节点完整路径
    ///   - force: 是否强制删除
    public static func clearBadge(_ path: Path, force: Bool = false) {
        NodeTrie.clearBadge(path: path.nodeNames, force: force)
    }

    /// 隐藏/显示目标节点
    ///
    /// - Parameters:
    ///   - path: 目标节点完整路径
    ///   - hidden: 是否隐藏
    public static func hideBdage(_ path: Path, hidden: Bool) {
        NodeTrie.updateBadge(path.nodeNames, hidden: hidden)
    }

    /// 强制清空所有Badge
    public static func forceClearAll() {
        NodeTrie.forceClearAll()
    }

    static var shared = BadgeManager()
    var dependancy: BadgeDependancy?
}
