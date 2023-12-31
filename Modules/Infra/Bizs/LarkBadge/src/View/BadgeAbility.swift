//
//  BadgeAbility.swift
//  LarkBadge
//
//  Created by KT on 2019/4/18.
//

import Foundation
import UIKit

extension Badge: BadgeUIInitialization where Base: BadgeAddable {

    public func set(type: BadgeType) {
        initialInfo.type = type
        switch type {
        case let .image(.locol(name)): set(locoalName: name)
        case let .image(.web(url)): set(webImageURL: url.absoluteString)
        case let .label(.number(num)): set(number: num)
        case let .label(.text(text)): set(text: text)
        default: updateInitialConfig()
        }
    }

    public func set(offset: CGPoint) {
        updateInitialConfig { self.initialInfo.offset = offset }
    }

    public func set(locoalName: String) {
        updateInitialConfig { self.initialInfo.locoalImage = locoalName }
    }

    public func set(webImageURL: String) {
        updateInitialConfig { self.initialInfo.webImage = webImageURL }
    }

    public func set(size: CGSize) {
        updateInitialConfig { self.initialInfo.size = size }
    }

    public func set(cornerRadius: CGFloat) {
        updateInitialConfig { self.initialInfo.cornerRadius = cornerRadius }
    }

    public func set(backgroundColor: UIColor) {
        updateInitialConfig { self.initialInfo.backgroundColor = backgroundColor }
    }

    public func set(textColor: UIColor) {
        updateInitialConfig { self.initialInfo.textColor = textColor }
    }

    public func set(textSize: CGFloat) {
        updateInitialConfig { self.initialInfo.textSize = textSize }
    }

    public func set(horizontalMargin: CGFloat) {
        updateInitialConfig { self.initialInfo.horizontalMargin = horizontalMargin }
    }

    public func set(text: String) {
        updateInitialConfig { self.initialInfo.text = text }
    }

    public func set(number: Int) {
        nodeGuarantee { path, _  in NodeTrie.setBadge(path, count: number) }
    }

    public func set(borderColor: UIColor) {
        updateInitialConfig { self.initialInfo.borderColor = borderColor }
    }

    public func set(borderWidth: CGFloat) {
        updateInitialConfig { self.initialInfo.borderWidth = borderWidth }
    }

    public func set(style: BadgeStyle) {
        updateInitialConfig { self.initialInfo.style = style }
    }

    private func updateInitialConfig(_ call: (() -> Void)? = nil) {
        guard let path = viewPath else {
            assert(false, "Call `observePath()` first")
            return
        }
        call?()
        ObserveTrie.call(path)
    }
}

extension Badge: BadgeAbility where Base: BadgeAddable {
    public var isHidden: Bool {
        get { return nodeGuarantee { _, node in node.info.isHidden } ?? false }
        set { nodeGuarantee { path, _ in NodeTrie.updateBadge(path, hidden: newValue) } }
    }

    public var badgeView: BadgeView? {
        return base.badgeTarget?.lkBadgeView
    }

    public func isHidden(_ isHidden: Bool) {
        nodeGuarantee { path, _ in NodeTrie.updateBadge(path, hidden: isHidden) }
    }

    public var bodyCount: Int {
        return nodeGuarantee { _, node in node.info.count } ?? 0
    }

    public var totalCount: Int {
        return nodeGuarantee { path, _ in NodeTrie.totalCount(path) } ?? 0
    }

    public func clearBadge(force: Bool = false) {
        nodeGuarantee { path, _ in NodeTrie.clearBadge(path: path, force: force) }
    }

    @discardableResult
    private func nodeGuarantee<T>(_ call: ([NodeName], BadgeNode) -> T) -> T? {
        guard let path = viewPath else {
            assert(false, "Call `observePath` first")
            return nil
        }

        // 更新 NodeTrie
        NodeTrie.insertWhenNotExist(path)
        guard let node = NodeTrie.shared.node(path) else { return nil }
        return call(path, node)
    }
}

// 纯UI操作，不和 path 绑定
extension UIBadge where Base: BadgeAddable {

    /// 添加纯UI Badge（没有路径概念）
    /// - Parameter type: BadgeType
    public func addBadge(type: BadgeType) {
        guard let target = self.base.badgeTarget else { return }
        _ = BadgeView(with: type, in: target)
    }

    /// 获取已经初始化过多BadgeView
    public var badgeView: BadgeView? {
        return self.base.badgeTarget?.lkBadgeView
    }
}
