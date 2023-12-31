//
//  NormalCell.swift
//  LarkMine
//
//  Created by panbinghua on 2021/12/1.
//

import Foundation
import UIKit
import UniverseDesignIcon

open class NormalCellProp: BaseNormalCellProp, CellClickable {
    public var onClick: ClickHandler?
    var accessories: [NormalCellAccessory]

    public init(title: String,
         detail: String? = nil,
         accessories: [NormalCellAccessory] = [],
         cellIdentifier: String = "NormalCell",
         separatorLineStyle: CellSeparatorLineStyle = .normal,
         selectionStyle: CellSelectionStyle = .normal,
         id: String? = nil,
         onClick: ClickHandler? = nil) {
        self.onClick = onClick
        self.accessories = accessories
        super.init(title: title,
                   detail: detail,
                   cellIdentifier: cellIdentifier,
                   separatorLineStyle: separatorLineStyle,
                   selectionStyle: selectionStyle,
                   id: id)
    }
    public convenience init(title: String,
                     detail: String? = nil,
                     showArrow: Bool = false,
                     cellIdentifier: String = "NormalCell",
                     separatorLineStyle: CellSeparatorLineStyle = .normal,
                     selectionStyle: CellSelectionStyle = .normal,
                     id: String? = nil,
                     onClick: ClickHandler? = nil) {
        self.init(title: title, detail: detail, accessories: [.arrow(isShown: showArrow)],
                  cellIdentifier: cellIdentifier, separatorLineStyle: separatorLineStyle, selectionStyle: selectionStyle,
                  id: id, onClick: onClick)
    }
}

public struct NormalCellAccessory {
    let type: AccessoryType
    let spacing: CGFloat

    public init(_ type: AccessoryType, spacing: CGFloat = 0) {
        self.type = type
        self.spacing = spacing
    }

    public enum AccessoryType {
        case placeholder(CGSize = CGSize(width: 16, height: 16))
        case arrow
        case checkMark
        case text(String)
        case custom((() -> UIView))

        func getAccessoryView() -> UIView {
            switch self {
            case .placeholder(let size):
                return ViewHelper.createSizedView(size: size)
            case .arrow:
                let size = CGSize(width: 16, height: 16)
                let icon = UDIcon.getIconByKey(.rightOutlined, iconColor: .ud.iconN3, size: size)
                let view = ViewHelper.createSizedImageView(size: size, image: icon)
                return view
            case .checkMark:
                let size = CGSize(width: 20, height: 20)
                let icon = UDIcon.getIconByKey(.listCheckOutlined, iconColor: .ud.primaryContentDefault, size: size)
                let view = ViewHelper.createSizedImageView(size: size, image: icon)
                return view
            case .text(let text):
                let label = UILabel()
                label.font = UIFont.systemFont(ofSize: 14)
                label.textColor = UIColor.ud.textPlaceholder
                label.numberOfLines = 1
                label.setContentHuggingPriority(.required, for: .horizontal) // 不要被拉升
                label.setContentCompressionResistancePriority(.required, for: .horizontal) // 不要被拉升
                label.setFigmaText(text)
                return label
            case .custom(let provider):
                return provider()
            }
        }
    }
    
    public static func arrow(isShown: Bool = true, spacing: CGFloat = 0) -> NormalCellAccessory {
        let size = CGSize(width: 16, height: 16)
        return isShown ? .init(.arrow, spacing: spacing) : .init(.placeholder(size), spacing: spacing)
    }
    public static func checkMark(isShown: Bool = true, spacing: CGFloat = 0) -> NormalCellAccessory {
        let size = CGSize(width: 20, height: 20)
        return isShown ? .init(.checkMark, spacing: spacing) : .init(.placeholder(size), spacing: spacing)
    }
    public static func text(_ str: String, spacing: CGFloat = 0) -> NormalCellAccessory {
        return .init(.text(str), spacing: spacing)
    }
    public static func custom(_ provider: @escaping (() -> UIView), spacing: CGFloat = 0) -> NormalCellAccessory {
        return .init(.custom(provider), spacing: spacing)
    }
    public static func placeholder(size: CGSize = CGSize(width: 16, height: 16), spacing: CGFloat = 0) -> NormalCellAccessory {
        return .init(.placeholder(size), spacing: spacing)
    }
}

open class NormalCell: BaseNormalCell {

    open override func update(_ info: CellProp) {
        super.update(info)
        guard let info = info as? NormalCellProp else { return }

        trailingContainer.arrangedSubviews.forEach { sub in
            trailingContainer.removeArrangedSubview(sub)
            sub.removeFromSuperview()
        }
        info.accessories.forEach { accessory in
            let view = accessory.type.getAccessoryView()
            trailingContainer.addArrangedSubview(view)
            trailingContainer.setCustomSpacing(accessory.spacing, after: view)
        }
    }

    lazy var trailingContainer: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = horizontalSpacing
        return stack
    }()

    open override func getTrailingView() -> UIView? {
        return trailingContainer
    }
}
