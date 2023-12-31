//
//  IconButton.swift
//  LarkThread
//
//  Created by liuwanlin on 2019/2/15.
//

import Foundation
import UIKit

private let iconLabelSpcaing: CGFloat = 3

class IconButton: UIControl {
    typealias TapCallback = (IconButton) -> Void
    private var iconSize: CGFloat

    class func sizeToFit(_ size: CGSize, iconSize: CGFloat, title: String = "", titleFont: UIFont = UIFont.systemFont(ofSize: 14)) -> CGSize {
        if title.isEmpty {
            return CGSize(width: iconSize, height: iconSize)
        }
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        // 根据 https://bytedance.feishu.cn/docx/VpZTdl1IioCrENxfWakcPcrwnFo 替换为 byWordWrapping
        paragraphStyle.lineBreakMode = .byWordWrapping

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

    lazy var icon: UIImageView = {
        let icon = UIImageView(frame: .zero)
        return icon
    }()

    lazy var label: UILabel = {
        let label = UILabel(frame: .zero)
        label.numberOfLines = 1
        // 根据 https://bytedance.feishu.cn/docx/VpZTdl1IioCrENxfWakcPcrwnFo 替换为 byWordWrapping
        label.lineBreakMode = .byWordWrapping
        label.textColor = UIColor.ud.textPlaceholder
        return label
    }()

    var onTapped: TapCallback?

    override var frame: CGRect {
        didSet {
            layout()
        }
    }

    init(frame: CGRect, iconSize: CGFloat) {
        self.iconSize = iconSize
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(title: String, icon: UIImage?, titleFont: UIFont = UIFont.systemFont(ofSize: 14)) {
        self.label.text = title
        self.label.font = titleFont
        self.icon.image = icon

        layout()
    }

    private func commonInit() {
        self.addSubview(icon)
        icon.frame = CGRect(origin: .zero, size: CGSize(width: iconSize, height: iconSize))
        icon.center.y = self.frame.height / 2
        self.addSubview(label)
        label.frame = CGRect(x: iconSize + iconLabelSpcaing, y: 0, width: 0, height: 0)

        self.hitTestEdgeInsets = UIEdgeInsets(top: -15, left: -15, bottom: -15, right: -15)
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
}
