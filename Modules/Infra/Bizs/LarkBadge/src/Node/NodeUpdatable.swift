//
//  NodeUpdatable.swift
//  LarkBadge
//
//  Created by KT on 2019/4/18.
//

import UIKit
import Foundation

// Node可更新的内容
protocol NodeUpdatable {
    var type: BadgeType { get }

    var isHidden: Bool { get set }
    var strategy: HiddenStrategy { get set }
    var size: CGSize { get set }
    var offset: CGPoint { get set }
    var cornerRadius: CGFloat { get set }
    var backgroundColor: UIColor { get set }
    var borderColor: UIColor { get set }
    var borderWidth: CGFloat { get set }

    // Label
    var textColor: UIColor { get set }
    var textSize: CGFloat { get set }
    var text: String { get set }
    var count: Int { get set }
    var horizontalMargin: CGFloat { get set }

    // UIImageView
    var webImage: String { get set }
    var locoalImage: String { get set }

    // 更新优先级
    // Force > 本地配置 > 初始化配置 > none
    var configPriorty: ConfigPriorty { get set }
}

public struct NodeInfo: NodeUpdatable {
    public var configPriorty: ConfigPriorty = .none

    init(_ type: BadgeType) {
        self.type = type
    }

    var type: BadgeType {
        didSet {
            horizontalMargin = type.horizontalMargin
            size = type.size
            offset = type.offset
            cornerRadius = type.cornerRadius
            backgroundColor = type.backgroundColor
            borderColor = type.borderColor
            borderWidth = type.borderWidth
            textSize = type.textSize

            switch type {
            case let .label(.plusNumber(count)): self.count = count
            case let .label(.number(count)): self.count = count
            case let .label(.text(text)): self.text = text
            case let .image(.locol(locoal)): self.locoalImage = locoal
            case let .image(.web(url)): self.webImage = url.absoluteString
            default: break
            }
        }
    }

    public var horizontalMargin: CGFloat = BadgeType.none.horizontalMargin

    public var locoalImage: String = ""

    public var webImage: String = ""

    public var backgroundColor: UIColor = BadgeType.none.backgroundColor

    public var textColor: UIColor = .white

    public var textSize: CGFloat = BadgeType.none.textSize

    public var text: String = ""

    public var isHidden: Bool = false

    public var strategy: HiddenStrategy = BadgeType.none.strategy

    public var size: CGSize = BadgeType.none.size

    public var offset: CGPoint = BadgeType.none.offset

    public var cornerRadius: CGFloat = BadgeType.none.cornerRadius

    public var borderColor: UIColor = BadgeType.none.borderColor

    public var borderWidth: CGFloat = BadgeType.none.borderWidth

    public var style: BadgeStyle = BadgeStyle.strong

    public var count: Int = 0 {
        didSet {
            // min -> 0
            // swiftlint:disable empty_count
            if count < 0 { count = 0 }
            // swiftlint:enable empty_count
        }
    }

    // 根据优先级，获得合并后的NodeInfo
    // swiftlint:disable cyclomatic_complexity
    mutating func merge(_ info: NodeInfo) -> NodeInfo {
        // 网络配置优先级最高，直接返回
        if case .force = self.configPriorty {
            return self
        }

        let initial = NodeInfo(.none)

        // swiftlint:disable operator_usage_whitespace
        if info.type             != initial.type { self.type = info.type }
        if info.backgroundColor  != initial.backgroundColor { self.backgroundColor = info.backgroundColor }
        if info.cornerRadius     != initial.cornerRadius { self.cornerRadius = info.cornerRadius }
        if info.offset           != initial.offset { self.offset = info.offset }
        if info.size             != initial.size { self.size = info.size }
        if info.textSize         != initial.textSize { self.textSize = info.textSize }
        if info.textColor        != initial.textColor { self.textColor = info.textColor }
        if info.style            != initial.style { self.style = info.style }
        if info.horizontalMargin != initial.horizontalMargin { self.horizontalMargin = info.horizontalMargin }
        if info.borderWidth != initial.borderWidth { self.borderWidth = info.borderWidth }
        if info.borderColor != initial.borderColor { self.borderColor = info.borderColor }
        // swiftlint:enable operator_usage_whitespace
        return self
    }
}
