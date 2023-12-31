//
//  ActionButton.swift
//  Moments
//
//  Created by liluobin on 2020/1/10
//

import Foundation
import UIKit

private let iconLabelSpcaing: CGFloat = 3

public final class ActionButton: UIControl {
    public typealias TapCallback = (ActionButton) -> Void
    private var iconSize: CGFloat
    private var iconColor: UIColor
    private var titleColor: UIColor
    public override var isEnabled: Bool {
        didSet {
            icon.tintColor = isEnabled ? iconColor : .ud.iconDisabled
            label.textColor = isEnabled ? titleColor : UIColor.ud.textDisabled
        }
    }
    var isRotate: Bool? {
        didSet {
            changeState()
        }
    }
    public class func sizeToFit(_ size: CGSize, iconSize: CGFloat, title: String = "", titleFont: UIFont = UIFont.systemFont(ofSize: 14)) -> CGSize {
        if title.isEmpty {
            return CGSize(width: iconSize, height: iconSize)
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
        ).boundingRect(
            with: CGSize(width: size.width - iconSize - iconLabelSpcaing, height: size.height),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        ).size

        return CGSize(
            width: iconSize + iconLabelSpcaing + size.width,
            height: iconSize
        )
    }

    public lazy var icon: UIImageView = {
        let icon = UIImageView(frame: .zero)
        icon.tintColor = isEnabled ? iconColor : .ud.iconDisabled
        return icon
    }()

    public lazy var label: UILabel = {
        let label = UILabel(frame: .zero)
        label.numberOfLines = 1
        /// 这里只展示一行，尽可能多的展示内容
        // swiftlint:disable ban_linebreak_byChar
        label.lineBreakMode = .byCharWrapping
        // swiftlint:enable ban_linebreak_byChar
        label.textColor = titleColor
        return label
    }()

    public var onTapped: TapCallback?

    public override var frame: CGRect {
        didSet {
            layout()
        }
    }

    public init(frame: CGRect, iconSize: CGFloat, iconColor: UIColor, titleColor: UIColor) {
        self.iconSize = iconSize
        self.iconColor = iconColor
        self.titleColor = titleColor
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func update(title: String, icon: UIImage, titleFont: UIFont = UIFont.systemFont(ofSize: 14)) {
        self.label.text = title
        self.label.font = titleFont
        self.icon.image = icon.withRenderingMode(.alwaysTemplate)
        self.label.textColor = isEnabled ? titleColor : UIColor.ud.textDisabled
        layout()
    }

    private func commonInit() {
        self.addSubview(icon)
        icon.frame = CGRect(origin: .zero, size: CGSize(width: iconSize, height: iconSize))
        icon.center.y = self.frame.height / 2
        self.addSubview(label)
        label.frame = CGRect(x: iconSize + iconLabelSpcaing, y: 0, width: 0, height: 0)
        self.addTarget(self, action: #selector(selfTapped), for: .touchUpInside)
    }

    @objc
    private func selfTapped() {
        self.onTapped?(self)
    }

    private func layout() {
        icon.frame = CGRect(origin: .zero, size: CGSize(width: iconSize, height: iconSize))
        icon.center.y = self.frame.height / 2
        if (label.text ?? "").isEmpty {
            label.isHidden = true
        } else {
            label.isHidden = false
            let x = iconSize + iconLabelSpcaing
            label.frame = CGRect(x: x, y: 0, width: frame.width - x, height: frame.height)
            label.center.y = frame.height / 2
        }
    }

    func changeState() {
        guard let isRotate = isRotate else { return }
        if isRotate {
            self.icon.lu.addRotateAnimation()
        } else {
            self.icon.lu.removeRotateAnimation()
        }
    }
}
