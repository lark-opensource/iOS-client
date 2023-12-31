//
//  SpinButton.swift
//  LarkUIKit
//
//  Created by bytedance on 2021/5/13.
//

import Foundation
import UIKit
import LarkInteraction

public extension SpinButton {
    typealias TapCallback = (SpinButton) -> Void
    typealias SetImageTask = (UIImageView) -> Void

    static var defaultFont: UIFont { return UIFont.ud.body2 }
    static var defaultTitleColor: UIColor { UIColor.ud.B600 }
    static let iconLabelSpcaing: CGFloat = 5
    static var iconWidth: CGFloat { 10.auto() }
}

public final class SpinButton: UIControl {
    var isDown = false

    private var titileStr: String

    public class func sizeToFit(_ size: CGSize, title: String = "", titleFont: UIFont = SpinButton.defaultFont) -> CGSize {
        if title.isEmpty {
            return CGSize(width: iconWidth, height: iconWidth)
        }
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        /// 这里只展示一行，尽可能多的展示内容
        // swiftlint:disable ban_linebreak_byChar
        paragraphStyle.lineBreakMode = .byCharWrapping
        // swiftlint:enable ban_linebreak_byChar
        let size = NSAttributedString(
            string: title,
            attributes: [
                .font: titleFont,
                .paragraphStyle: paragraphStyle
            ]
        ).componentTextSize(for: size, limitedToNumberOfLines: 1)

        return CGSize(
            width: Self.iconWidth + Self.iconLabelSpcaing + size.width,
            height: size.height
        )
    }

    lazy var icon: UIImageView = {
        let icon = UIImageView()
        icon.contentMode = .scaleAspectFill
        return icon
    }()

    lazy var label: UILabel = {
        let label = UILabel(frame: .zero)
        label.numberOfLines = 1
        /// 这里只展示一行，尽可能多的展示内容
        // swiftlint:disable ban_linebreak_byChar
        label.lineBreakMode = .byCharWrapping
        // swiftlint:enable ban_linebreak_byChar
        label.textColor = titleColor
        label.text = self.titileStr
        return label
    }()

    private var tapGesture: UITapGestureRecognizer?
    public var onTapped: TapCallback? {
        didSet {
            if onTapped == nil, let tap = tapGesture {
                self.removeGestureRecognizer(tap)
                self.tapGesture = nil
            } else if onTapped != nil {
                if let tap = self.tapGesture {
                    self.addGestureRecognizer(tap)
                } else {
                    self.tapGesture = self.lu.addTapGestureRecognizer(action: #selector(selfTapped), target: self)
                }
            }
        }
    }

    public var setImageTask: SetImageTask? {
        didSet {
            if setImageTask == nil {
                self.icon.image = nil
            } else {
                setImageTask?(self.icon)
            }
        }
    }

    public var titleColor: UIColor = SpinButton.defaultTitleColor {
        didSet {
            label.textColor = titleColor
        }
    }

    public override var frame: CGRect {
        didSet {
            layout()
        }
    }

    public init(frame: CGRect, title: String) {
        titileStr = title
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func update(title: String, titleFont: UIFont = SpinButton.defaultFont) {
        self.label.text = title
        self.label.font = titleFont
        layout()
    }

    public func rotateIcon(animated: Bool) {
        let animationBlock = {
            if self.isDown {
                self.icon.transform = CGAffineTransform(rotationAngle: 0)
                self.isDown = false
            } else {
                self.icon.transform = CGAffineTransform(rotationAngle: CGFloat.pi - 0.001)
                self.isDown = true
            }
        }

        if animated {
            UIView.animate(withDuration: 0.15) {
                animationBlock()
            }
        } else {
            animationBlock()
        }
    }

    private func commonInit() {
        self.addSubview(icon)
        icon.frame = CGRect(origin: .zero, size: CGSize(width: Self.iconWidth, height: Self.iconWidth))
        icon.center.y = self.frame.height / 2
        self.addSubview(label)
        label.frame = CGRect(x: Self.iconWidth + Self.iconLabelSpcaing, y: 0, width: 0, height: 0)

        if #available(iOS 13.4, *) {
            let pointer = PointerInteraction(
                style: .init(effect: .highlight)
            )
            self.addLKInteraction(pointer)
        }
    }

    @objc
    private func selfTapped() {
        rotateIcon(animated: true)
        self.onTapped?(self)
    }

    private func layout() {
        let x = Self.iconWidth + Self.iconLabelSpcaing

        if (label.text ?? "").isEmpty {
            label.isHidden = true
        } else {
            label.isHidden = false
            label.frame = CGRect(x: 0, y: 0, width: frame.width - x, height: frame.height)
            label.center.y = frame.height / 2
        }
        icon.frame.origin = CGPoint(x: frame.width - Self.iconWidth, y: 0)
        icon.center.y = self.frame.height / 2
    }
}
