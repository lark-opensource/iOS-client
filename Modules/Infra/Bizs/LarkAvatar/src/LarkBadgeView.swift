//
//  LarkBadgeView.swift
//  LarkAvatar
//
//  Created by qihongye on 2020/2/12.
//

import UIKit
import Foundation
import ByteWebImage

public struct SetBadgeIcon {
    let expectSize: CGSize?
    let iconKey: String?
    let iconURL: String?
    let icon: UIImage?

    public init(iconKey: String? = nil,
                iconURL: String? = nil,
                icon: UIImage? = nil,
                expectSize: CGSize? = nil) {
        self.iconKey = iconKey
        self.iconURL = iconURL
        self.icon = icon
        self.expectSize = expectSize
    }
}

public struct Badge {
    public enum TypeEnum {
        case text(String)
        case icon(SetBadgeIcon)
    }

    public var type: TypeEnum
    public var border: Border?
    public var textColor: UIColor
    public var textFont: UIFont?
    public var backgroundColor: UIColor?

    public init(type: TypeEnum, border: Border? = nil, textColor: UIColor = .black, textFont: UIFont? = nil, backgroundColor: UIColor? = nil) {
        self.type = type
        self.border = border
        self.textColor = textColor
        self.textFont = textFont
        self.backgroundColor = backgroundColor
    }
}

open class LarkBadgeView: UIView {
    private var _badge: Badge?

    private lazy var iconLayer: UIImageView = {
        let iconLayer = UIImageView()
        return iconLayer
    }()
    private lazy var textLayer: UILabel = {
        let textLayer = UILabel()
        textLayer.font = textFont
        textLayer.textColor = textColor
        return textLayer
    }()

    /// Some system function such as `selected` and `highlighted` will
    /// change backgroundColor, this property avoid this happen.
    public var backgroundColorStable = false

    public override var backgroundColor: UIColor? {
        didSet {
            if backgroundColorStable,
                backgroundColor != _badge?.backgroundColor {
                backgroundColor = _badge?.backgroundColor
            }
        }
    }

    public var textFont: UIFont = .systemFont(ofSize: UIFont.systemFontSize) {
        didSet {
            textLayer.font = textFont
            invalidateIntrinsicContentSize()
            setNeedsLayout()
        }
    }
    public var textColor: UIColor = .black {
        didSet {
            textLayer.textColor = textColor
            invalidateIntrinsicContentSize()
            setNeedsLayout()
        }
    }

    public var textAlignment: NSTextAlignment {
        get {
            return textLayer.textAlignment
        } set {
            textLayer.textAlignment = newValue
        }
    }

    public var textEdgeInsets: UIEdgeInsets = .zero {
        didSet {
            invalidateIntrinsicContentSize()
            setNeedsLayout()
        }
    }

    public var type: Badge.TypeEnum = .text("") {
        didSet {
            invalidateIntrinsicContentSize()
            setNeedsLayout()
            render()
        }
    }

    public convenience init() {
        self.init(frame: .zero)
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(textLayer)
        addSubview(iconLayer)
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        let borderWidth = _badge?.border?.width ?? 0
        let borderEdgeInsets = UIEdgeInsets(
            top: borderWidth,
            left: borderWidth,
            bottom: borderWidth,
            right: borderWidth
        )
        iconLayer.frame = bounds.inset(by: borderEdgeInsets)
        textLayer.frame = bounds.inset(by: textEdgeInsets).inset(by: borderEdgeInsets)
    }

    public override var intrinsicContentSize: CGSize {
        return sizeThatFits(super.intrinsicContentSize)
    }

    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        switch type {
        case .icon(let task):
            guard let expectSize = task.expectSize else {
                return bounds.size
            }
            let borderWidth = _badge?.border?.width ?? 0
            var size = size
            if size.height > 0 {
                size.width = expectSize.width / expectSize.height * (size.height - 2 * borderWidth)
            } else if size.width > 0 {
                size.height = expectSize.height / expectSize.width * (size.width - 2 * borderWidth)
            } else {
                size = CGSize(
                    width: expectSize.width + 2 * borderWidth,
                    height: expectSize.height + 2 * borderWidth
                )
            }
            return size
        case .text(let string):
            textLayer.text = string
            var size = textLayer.sizeThatFits(size)
            let borderWidth = _badge?.border?.width ?? 0
            size.width += textEdgeInsets.left + textEdgeInsets.right + 2 * borderWidth
            size.height += textEdgeInsets.top + textEdgeInsets.bottom + 2 * borderWidth
            return size
        }
    }

    public func setBadge(_ badge: Badge) {
        self._badge = badge
        type = badge.type
        if let font = badge.textFont {
            textFont = font
        }
        textColor = badge.textColor
        backgroundColor = badge.backgroundColor
        clipsToBounds = badge.border != nil
        layer.borderWidth = badge.border?.width ?? 0
        layer.borderColor = badge.border?.color.cgColor ?? nil
    }

    private func render() {
        switch type {
        case .text(let string):
            iconLayer.isHidden = true
            textLayer.isHidden = false
            textLayer.text = string
        case .icon(let task):
            textLayer.isHidden = true
            iconLayer.isHidden = false
            if let key = task.iconKey {
                iconLayer.bt.setLarkImage(with: .default(key: key),
                                          placeholder: task.icon,
                                          cacheName: LarkImageService.shared.thumbCache.name)
            } else if let url = task.iconURL {
                iconLayer.bt.setLarkImage(with: .default(key: url),
                                          placeholder: task.icon)
            } else {
                iconLayer.bt.setLarkImage(with: .default(key: ""), placeholder: task.icon)
            }
        }
    }
}
