//
//  HeaderButton.swift
//  Calendar
//
//  Created by harry zou on 2019/5/9.
//

import UIKit
import CalendarFoundation
import UniverseDesignIcon
import LarkInteraction

final class HeaderButton: UIButton {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    private func setupViews() {
        layer.cornerRadius = 6
        titleLabel?.font = UIFont.ud.body2(.fixed)
        imageEdgeInsets = UIEdgeInsets(top: 0, left: -2, bottom: 0, right: 2)
        titleEdgeInsets = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: -2)
        if #available(iOS 13.4, *) {
            lkPointerStyle = PointerStyle(
                effect: .lift,
                shape: .roundedSize({ (interaction, _) -> (CGSize, CGFloat) in
                    guard let width = interaction.view?.bounds.width,
                          let height = interaction.view?.bounds.height else {
                        return (.zero, 0)
                    }
                    return (CGSize(width: width, height: height), 8)
                }))
        }
    }

    private let otherStateAlpha: CGFloat = 0.4
    private let iconSize = CGSize(width: 16, height: 16)

    func updateContent(iconKey: UDIconType, title: String, color: UIColor) {
        setTitle(title, for: .normal)
        setTitleColor(color, for: .normal)
        setTitleColor(color.withAlphaComponent(otherStateAlpha), for: .disabled)
        setTitleColor(color.withAlphaComponent(otherStateAlpha), for: .highlighted)
        setImage(UDIcon.getIconByKey(iconKey, iconColor: color, size: iconSize), for: .normal)
        setImage(UDIcon.getIconByKey(iconKey, iconColor: color.withAlphaComponent(otherStateAlpha), size: iconSize), for: .disabled)
        setImage(UDIcon.getIconByKey(iconKey, iconColor: color.withAlphaComponent(otherStateAlpha), size: iconSize), for: .highlighted)
    }

    func centerContent() {
        contentHorizontalAlignment = .center
        contentEdgeInsets = .zero
    }

    override var intrinsicContentSize: CGSize {
        let baseSize = super.intrinsicContentSize
        return CGSize(width: baseSize.width + 20, height: baseSize.height)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
