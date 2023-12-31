//
//  TagView.swift
//  Social
//
//  Created by Hayden on 2019/9/10.
//  Copyright © 2019 shengsheng. All rights reserved.
//

import Foundation
import UIKit
import LarkInteraction
import UniverseDesignIcon

open class TagView: UIButton {

    // MARK: Tag View Appearance

    public var title: String? {
        return titleLabel?.text
    }

    public var tagCornerRadius: CGFloat = 0 {
        didSet {
            layer.cornerRadius = tagCornerRadius
            layer.masksToBounds = tagCornerRadius > 0
        }
    }

    public var tagBorderWidth: CGFloat = 0 {
        didSet {
            layer.borderWidth = tagBorderWidth
        }
    }

    public var tagBorderColor: UIColor? {
        didSet {
            reloadStyles()
        }
    }

    public var textColor: UIColor = UIColor.white {
        didSet {
            reloadStyles()
        }
    }

    public var selectedTextColor: UIColor = UIColor.white {
        didSet {
            reloadStyles()
        }
    }

    public var titleLineBreakMode: NSLineBreakMode = .byTruncatingMiddle {
        didSet {
            titleLabel?.lineBreakMode = titleLineBreakMode
        }
    }

    public var paddingY: CGFloat = 2 {
        didSet {
            titleEdgeInsets.top = paddingY
            titleEdgeInsets.bottom = paddingY
        }
    }

    public var paddingX: CGFloat = 5 {
        didSet {
            titleEdgeInsets.left = paddingX
            updateRightInsets()
        }
    }

    public var spacing: CGFloat = 3 {
        didSet {
            updateLeftInsets()
        }
    }

    public var tagBackgroundColor: UIColor = UIColor.gray {
        didSet {
            reloadStyles()
        }
    }

    public var highlightedBackgroundColor: UIColor? {
        didSet {
            reloadStyles()
        }
    }

    public var selectedBackgroundColor: UIColor? {
        didSet {
            reloadStyles()
        }
    }

    public var tagSelectedBorderColor: UIColor? {
        didSet {
            reloadStyles()
        }
    }

    public var textFont: UIFont = .systemFont(ofSize: 12) {
        didSet {
            titleLabel?.font = textFont
        }
    }

    private func reloadStyles() {
        if isHighlighted {
            if let highlightedBackgroundColor = highlightedBackgroundColor {
                // For highlighted, if it's nil, we should not fallback to backgroundColor.
                // Instead, we keep the current color.
                backgroundColor = highlightedBackgroundColor
            }
        } else if isSelected {
            backgroundColor = selectedBackgroundColor ?? tagBackgroundColor
            layer.borderColor = tagSelectedBorderColor?.cgColor ?? tagBorderColor?.cgColor
            setTitleColor(selectedTextColor, for: UIControl.State())
            removeButton.tintColor = selectedTextColor
        } else {
            backgroundColor = tagBackgroundColor
            layer.borderColor = tagBorderColor?.cgColor
            setTitleColor(textColor, for: UIControl.State())
            removeButton.tintColor = textColor
        }
    }

    override public var isHighlighted: Bool {
        didSet {
            reloadStyles()
        }
    }

    override public var isSelected: Bool {
        didSet {
            reloadStyles()
        }
    }

    // MARK: tag icon

    let tagIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    public var isTagIconEnabled: Bool = false {
        didSet {
            tagIconView.isHidden = !isTagIconEnabled
            updateLeftInsets()
        }
    }

    public var tagIconSize: CGFloat = 12 {
        didSet {
            updateLeftInsets()
        }
    }

    public var tagIconImage: UIImage? {
        didSet {
            tagIconView.image = tagIconImage?.withRenderingMode(.alwaysTemplate)
        }
    }

    public var tagIconTintColor: UIColor = .black {
        didSet {
            tagIconView.tintColor = tagIconTintColor
        }
    }

    // MARK: remove button

    let removeButton = CloseButton()

    public var isRemoveButtonEnabled: Bool = false {
        didSet {
            removeButton.isHidden = !isRemoveButtonEnabled
            updateRightInsets()
        }
    }

    public var removeIconSize: CGFloat = 12 {
        didSet {
            removeButton.iconSize = removeIconSize
            updateRightInsets()
        }
    }

    public var removeIconLineWidth: CGFloat = 3 {
        didSet {
            removeButton.lineWidth = removeIconLineWidth
        }
    }

    public var removeIconColor: UIColor = UIColor.white.withAlphaComponent(0.54) {
        didSet {
            removeButton.lineColor = removeIconColor
        }
    }

    /// Handles Tap (TouchUpInside)
    public var onTap: ((TagView) -> Void)?
    public var onLongPress: ((TagView) -> Void)?

    // MARK: init

    public init(title: String) {
        super.init(frame: CGRect.zero)
        setTitle(title, for: UIControl.State())
        setupView()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }

    private func setupView() {
        titleLabel?.lineBreakMode = titleLineBreakMode

        frame.size = intrinsicContentSize
        addSubview(removeButton)
        addSubview(tagIconView)
        removeButton.tagView = self

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(self.longPress))
        self.addGestureRecognizer(longPress)

        if #available(iOS 13.4, *) {
            let action = PointerInteraction(style: PointerStyle(effect: .highlight))
            self.addLKInteraction(action)
        }
    }

    @objc
    func longPress() {
        onLongPress?(self)
    }

    // MARK: layout

    override public var intrinsicContentSize: CGSize {
        var size = titleLabel?.attributedText?.size() ?? .zero
        size.width = ceil(size.width)
        size.height = textFont.pointSize + paddingY * 2
        size.width += paddingX * 2
        if size.width < size.height {
            size.width = size.height
        }
        if isTagIconEnabled {
            size.width += tagIconSize + spacing
        }
        if isRemoveButtonEnabled {
            size.width += removeIconSize + paddingX
        }
        if size.width < 60 {
            size.width = 60
        }
        return size
    }

    private func updateLeftInsets() {
        if isTagIconEnabled {
            titleEdgeInsets.left = paddingX + tagIconSize + spacing
        } else {
            titleEdgeInsets.left = paddingX
        }
    }

    private func updateRightInsets() {
        if isRemoveButtonEnabled {
            titleEdgeInsets.right = paddingX + removeIconSize + spacing
        } else {
            titleEdgeInsets.right = paddingX
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        if isTagIconEnabled {
            tagIconView.frame.size.width = tagIconSize
            tagIconView.frame.size.height = tagIconSize
            tagIconView.frame.origin.x = paddingX
            tagIconView.frame.origin.y = (self.frame.height - tagIconSize) / 2
        }
        if isRemoveButtonEnabled {
            removeButton.frame.size.width = paddingX + removeIconSize + paddingX
            removeButton.frame.size.height = self.frame.height
            removeButton.frame.origin.x = self.frame.width - removeButton.frame.width
            removeButton.frame.origin.y = 0
        }
    }
}

// MARK: -

internal final class CloseButton: UIButton {

    var iconSize: CGFloat = 12
    var lineWidth: CGFloat = 1
    var lineColor: UIColor = UIColor.white.withAlphaComponent(0.54)

    weak var tagView: TagView?

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setImage(UDIcon.rightOutlined.ud.resized(to: CGSize(width: iconSize, height: iconSize)).withRenderingMode(.alwaysTemplate), for: .normal)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

//    override func draw(_ rect: CGRect) {
//        let path = UIBezierPath()
//
//        path.lineWidth = lineWidth
//        path.lineCapStyle = .round
//
//        let iconFrame = CGRect(
//            x: (rect.width - iconSize) / 2.0,
//            y: (rect.height - iconSize) / 2.0,
//            width: iconSize,
//            height: iconSize
//        )
//
//        path.move(to: iconFrame.origin)
//        path.addLine(to: CGPoint(x: iconFrame.maxX, y: iconFrame.maxY))
//        path.move(to: CGPoint(x: iconFrame.maxX, y: iconFrame.minY))
//        path.addLine(to: CGPoint(x: iconFrame.minX, y: iconFrame.maxY))
//
//        lineColor.setStroke()
//
//        path.stroke()
//    }
}
