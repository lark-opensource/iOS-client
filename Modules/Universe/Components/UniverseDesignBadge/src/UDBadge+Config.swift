//
//  UDBadge+Config.swift
//  UniverseDesignBadge
//
//  Created by Meng on 2020/10/27.
//

import UIKit
import Foundation

/// UDBadgeMaxType
public enum UDBadgeMaxType {
    /// number overflow maxNumber, use ellipsis icon
    case ellipsis
    /// number overflow maxNumber, use maxNumber with plus
    case plus
}

/// UDBadgeConfig
public struct UDBadgeConfig {

    /// global default max number for number badge type
    public static var defaultMaxNumber: Int = 99

    /// BadgeType, default value is dot
    public var type: UDBadgeType

    /// BadgeColorStyle, default value is red
    public var style: UDBadgeColorStyle

    /// BadgeBorder, default value is none
    public var border: UDBadgeBorder

    /// BadgeBorderStyle, default value is clear
    public var borderStyle: UDBadgeColorStyle

    /// BadgeDotSize, default value is middle
    /// only for dot badge type
    ///
    public var dotSize: UDBadgeDotSize

    /// BadgeAnchor, default value is topRight
    /// only for anchorType is not none
    ///
    public var anchor: UDBadgeAnchor

    /// BadgeAnchorType, default value is none
    ///
    public var anchorType: UDBadgeAnchorType

    /// BadgeAnchorExtendType, default value is leading
    ///
    public var anchorExtendType: UDBadgeAnchorExtendType

    /// badge anchor offset, default is zero
    ///
    public var anchorOffset: CGSize

    /// badge text content, default value is empty string
    /// only for text badge type
    ///
    public var text: String

    /// show badge when text value is empty
    /// onlye for text badge type
    ///
    public var showEmpty: Bool

    /// badge number content, default value is 0
    /// only for number badge type
    ///
    public var number: Int

    /// show badge when number badge value is zero
    /// only for number badge type
    ///
    public var showZero: Bool

    /// badge max number, default value use `UDBadgeConfig.defaultMaxNumber`
    /// only for number badge type
    ///
    public var maxNumber: Int

    /// badge number overflow type, default value is ellipsis
    /// only for number badge type
    ///
    public var maxType: UDBadgeMaxType

    /// badge content color style, default value is white
    /// onlye for number/text badge type
    ///
    public var contentStyle: UDBadgeColorStyle

    /// badge icon
    /// only for icon badge type
    /// if set nil, will not appear
    ///
    public var icon: ImageSource?

    /// default init
    public init(
        type: UDBadgeType = .dot,
        style: UDBadgeColorStyle = .dotBGRed,
        border: UDBadgeBorder = .none,
        borderStyle: UDBadgeColorStyle = .custom(.clear),
        dotSize: UDBadgeDotSize = .middle,
        anchor: UDBadgeAnchor = .topRight,
        anchorType: UDBadgeAnchorType = .none,
        anchorExtendType: UDBadgeAnchorExtendType = .leading,
        anchorOffset: CGSize = .zero,
        text: String = "",
        showEmpty: Bool = false,
        number: Int = 0,
        showZero: Bool = false,
        maxNumber: Int = Self.defaultMaxNumber,
        maxType: UDBadgeMaxType = .ellipsis,
        contentStyle: UDBadgeColorStyle = .dotCharacterText,
        icon: ImageSource? = nil
    ) {
        self.type = type
        self.style = style
        self.border = border
        self.borderStyle = borderStyle
        self.dotSize = dotSize
        self.anchor = anchor
        self.anchorType = anchorType
        self.anchorExtendType = anchorExtendType
        self.anchorOffset = anchorOffset
        self.text = text
        self.showEmpty = showEmpty
        self.number = number
        self.showZero = showZero
        self.maxNumber = maxNumber
        self.maxType = maxType
        self.contentStyle = contentStyle
        self.icon = icon
    }
}

extension UDBadgeConfig {
    /// default dot badge config
    public static var dot: UDBadgeConfig {
        return UDBadgeConfig(type: .dot, style: .dotBGRed, dotSize: .middle)
    }

    /// default text badge config
    public static var text: UDBadgeConfig {
        return UDBadgeConfig(
            type: .text,
            style: .characterBGRed,
            text: "",
            showEmpty: false,
            contentStyle: .dotCharacterText
        )
    }

    /// default number badge config
    public static var number: UDBadgeConfig {
        return UDBadgeConfig(
            type: .number,
            style: .characterBGRed,
            number: 0,
            showZero: false,
            maxNumber: Self.defaultMaxNumber,
            maxType: .ellipsis,
            contentStyle: .dotCharacterText
        )
    }

    /// default icon badge config
    public static var icon: UDBadgeConfig {
        return UDBadgeConfig(type: .icon, style: .dotBGRed, icon: nil)
    }
}

extension UDBadgeConfig {
    var refreshId: AnyHashable {
        var hasher = Hasher()
        hasher.combine(style.color.hashValue)
        hasher.combine(border.width)
        hasher.combine(borderStyle.color.hashValue)
        hasher.combine(contentStyle.color.hashValue)
        if hasAnchor {
            hasher.combine(anchor.hashValue)
            hasher.combine(anchorType.hashValue)
            hasher.combine(anchorExtendType.sign)
            hasher.combine(anchorOffset.width * anchorOffset.height)
        }
        switch type {
        case .dot:
            hasher.combine("dot")
            hasher.combine(dotSize.size.width * dotSize.size.height)
        case .text:
            hasher.combine(text)
            hasher.combine(showEmpty)
        case .number:
            hasher.combine(number)
            hasher.combine(showZero)
            hasher.combine(maxNumber)
            hasher.combine(maxType)
        case .icon:
            hasher.combine("icon")
            hasher.combine(icon?.image?.hashValue ?? icon?.image?.placeHolderImage?.hashValue)
        }
        return hasher.finalize()
    }

    var cornerRadius: CGFloat {
        switch type {
        case .dot:
            return (dotSize.size.height + border.padding) / 2.0
        case .text, .number, .icon:
            return (type.defaultSize.height + border.padding) / 2.0
        }
    }

    var minSize: CGSize {
        switch type {
        case .dot:
            return dotSize.size
        case .text, .number, .icon:
            return type.defaultSize
        }
    }

    var hasAnchor: Bool {
        switch anchorType {
        case .none:
            return false
        case .circle, .rectangle:
            return true
        }
    }

    func centerPoint(for targetRect: CGRect, with badgeSize: CGSize) -> CGPoint {
        let anchor = anchorPoint(for: targetRect)
        let offset = anchorPointOffset(for: badgeSize)
        let size = CGPoint(x: anchor.x + offset.width + anchorOffset.width,
                           y: anchor.y + offset.height + anchorOffset.height)
        let scale = UIScreen.main.scale
        // 像素取整
        return CGPoint(x: ceil(size.x * scale) / scale, y: ceil(size.y * scale) / scale)
    }

    private func anchorPointOffset(for badgeSize: CGSize) -> CGSize {
        assert(badgeSize.height >= minSize.height && badgeSize.width >= minSize.width)
        let absWidth = abs((minSize.width / 2) - (badgeSize.width / 2))
        let width = ceil(anchorExtendType.sign * absWidth)
        return CGSize(width: width, height: 0.0)
    }

    private func anchorPoint(for targetRect: CGRect) -> CGPoint {
        switch anchorType {
        case .none:
            return .zero
        case .rectangle:
            return rectangleAnchor(for: targetRect)
        case .circle:
            return circleAnchor(for: targetRect)
        }
    }

    private func rectangleAnchor(for targetRect: CGRect) -> CGPoint {
        switch anchor {
        case .topLeft:
            return CGPoint(x: targetRect.minX, y: targetRect.minY)
        case .topRight:
            return CGPoint(x: targetRect.maxX, y: targetRect.minY)
        case .bottomLeft:
            return CGPoint(x: targetRect.minX, y: targetRect.maxY)
        case .bottomRight:
            return CGPoint(x: targetRect.maxX, y: targetRect.maxY)
        }

    }

    private func circleAnchor(for targetRect: CGRect) -> CGPoint {
        guard targetRect.width == targetRect.height else {
            assertionFailure("rect is not square, circle anchor cannot find.")
            return rectangleAnchor(for: targetRect)
        }
        let anchorX = cos(45.0 * CGFloat.pi / 180.0) * targetRect.width / 2.0
        let anchorY = sin(45.0 * CGFloat.pi / 180.0) * targetRect.height / 2.0
        switch anchor {
        case .topLeft:
            return CGPoint(x: targetRect.width / 2.0 - anchorX, y: targetRect.height / 2.0 - anchorY)
        case .topRight:
            return CGPoint(x: targetRect.width / 2.0 + anchorX, y: targetRect.height / 2.0 - anchorY)
        case .bottomLeft:
            return CGPoint(x: targetRect.width / 2.0 - anchorX, y: targetRect.height / 2.0 + anchorY)
        case .bottomRight:
            return CGPoint(x: targetRect.width / 2.0 + anchorX, y: targetRect.height / 2.0 + anchorY)
        }
    }
}
