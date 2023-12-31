//
//  UIView+Search.swift
//  LarkSearchCore
//
//  Created by SolaWing on 2020/12/29.
//

import Foundation
import UIKit
import LarkListItem
import LarkSDKInterface

public extension Search {
    /// iterator for responder chain. start is not include in iterator sequence
    public struct UIResponderIterator: LazySequenceProtocol, IteratorProtocol {
        public var current: UIResponder?
        public init(start: UIResponder?) { current = start }
        public mutating func next() -> UIResponder? {
            current = current?.next
            return current
        }
    }
    struct ParentControllerIterator: LazySequenceProtocol, IteratorProtocol {
        public var current: UIViewController?
        public init(start: UIViewController?) { current = start }
        public mutating func next() -> UIViewController? {
            current = current?.parent
            return current
        }
    }
}

extension ListItem {
    // nolint: duplicated_code 不同cell的代码,后续废弃走统一的ListItem
    public func splitNameLabel(additional label: UILabel) {
        let nameLabel = self.nameLabel
        guard let stack = nameLabel.superview as? UIStackView, let index = stack.arrangedSubviews.firstIndex(of: nameLabel) else {
            assertionFailure("should insert count label to name label")
            return
        }

        // 在nameLabel后面显示群成员数，保证显示，强依赖组件目前实现
        label.textColor = nameLabel.textColor
        label.font = nameLabel.font
        label.setContentCompressionResistancePriority(.defaultHigh + 10, for: .horizontal)
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        let container = UIView()
        container.addSubview(nameLabel)
        container.addSubview(label)

        nameLabel.snp.makeConstraints { $0.left.top.bottom.equalToSuperview() }
        label.snp.makeConstraints {
            $0.left.equalTo(nameLabel.snp.right)
            $0.right.equalToSuperview()
            $0.centerY.equalToSuperview()
        }

        stack.insertArrangedSubview(container, at: index)
    }
    // enable-lint: duplicated_code
}

extension PickerItemInfoView {
    // nolint: duplicated_code 不同cell的代码,后续废弃走统一的ListItem
    public func splitNameLabel(additional label: UILabel) {
        let nameLabel = self.nameLabel
        guard let stack = nameLabel.superview as? UIStackView, let index = stack.arrangedSubviews.firstIndex(of: nameLabel) else {
            assertionFailure("should insert count label to name label")
            return
        }

        // 在nameLabel后面显示群成员数，保证显示，强依赖组件目前实现
        label.textColor = nameLabel.textColor
        label.font = nameLabel.font
        label.setContentCompressionResistancePriority(.defaultHigh + 10, for: .horizontal)
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        let container = UIView()
        container.addSubview(nameLabel)
        container.addSubview(label)

        nameLabel.snp.makeConstraints { $0.left.top.bottom.equalToSuperview() }
        label.snp.makeConstraints {
            $0.left.equalTo(nameLabel.snp.right)
            $0.right.equalToSuperview()
            $0.centerY.equalToSuperview()
        }

        stack.insertArrangedSubview(container, at: index)
    }
    // enable-lint: duplicated_code
}
