//
//  DayHeaderTimeZoneView.swift
//  Calendar
//
//  Created by 张威 on 2020/7/29.
//

import UIKit
import LarkExtensions

/// DayScene - Header - TimeZoneView

final class DayTimeZoneView: UIView {

    var text: String? {
        didSet {
            guard text != textLabel.text else { return }
            textLabel.text = text
            setNeedsLayout()
        }
    }

    var onClick: (() -> Void)?

    private let textLabel = UILabel()
    private let iconView = UIImageView()
    private let isShowIcon: Bool

    lazy var iconImage: UIImage? = {
        let icon = UIImage.cd.image(named: "time_zone_icon")
        if let lightIcon = icon.colorImage(UIColor.ud.iconN3.alwaysLight),
           let darkIcon = icon.colorImage(UIColor.ud.iconN3.alwaysDark) {
            return UIImage.dynamic(light: lightIcon, dark: darkIcon)
        }
        return nil
    }()

    init(isShowIcon: Bool = true) {
        self.isShowIcon = isShowIcon
        super.init(frame: .zero)
        backgroundColor = UIColor.ud.bgBody

        textLabel.font = UIFont.cd.dinBoldFont(ofSize: 11)
        textLabel.textColor = UIColor.ud.textPlaceholder
        textLabel.textAlignment = .center
        addSubview(textLabel)

        iconView.image = iconImage
        addSubview(iconView)

        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleClick)))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        var iconFrame: CGRect
        if isShowIcon {
            iconFrame = CGRect(origin: .zero, size: CGSize(width: 6, height: 10))
        } else {
            iconFrame = .zero
        }

        textLabel.sizeToFit()
        var textFrame = textLabel.frame
        textFrame.size.width = ceil(textFrame.width)
        textFrame.size.height = ceil(textFrame.height)
        if iconFrame.width != 0 {
            textFrame.left = (bounds.width - iconFrame.width - textFrame.width - 2) / 2
        } else {
            textFrame.left = (bounds.width - textFrame.width) / 2
        }
        textFrame.bottom = bounds.height
        textLabel.frame = textFrame
        if isShowIcon {
            iconFrame.left = textFrame.right + 2
            iconFrame.centerY = textFrame.centerY
            iconView.frame = iconFrame
        } else {
            iconView.isHidden = true
        }
    }

    @objc
    private func handleClick() {
        onClick?()
    }

}
