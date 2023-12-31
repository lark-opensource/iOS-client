//
//  FocusListFooterView.swift
//  ExpandableTable
//
//  Created by Hayden Wang on 2021/8/26.
//

import Foundation
import UIKit
import LarkInteraction
import UniverseDesignIcon

final class FocusListFooterView: UIView {

    lazy var settingButton: UIButton = {
        let button = ExtendedButton()
        button.extendInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        setupSubviews()
        setupConstraints()
        setupAppearance()
    }

    private func setupSubviews() {
        addSubview(settingButton)
    }

    private func setupConstraints() {
        settingButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(4)
            make.height.equalTo(22)
            make.centerX.equalToSuperview()
            make.width.equalTo(Cons.buttonWidth)
        }
    }

    private func setupAppearance() {
        settingButton.titleLabel?.font = Cons.buttonFont
        settingButton.setTitleColor(UIColor.ud.textCaption, for: .normal)
        settingButton.setTitle(Cons.buttonText, for: .normal)
        settingButton.setImage(Cons.buttonIcon.ud.resized(to: Cons.iconSize).ud.withTintColor(UIColor.ud.iconN2), for: .normal)
        settingButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: Cons.spacing)
        settingButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: Cons.spacing, bottom: 0, right: 0)

        if #available(iOS 13.4, *) {
            let pointer = PointerInteraction(
                style: .init(
                    effect: .highlight,
                    shape: .roundedSize({ (interaction, _) -> (CGSize, CGFloat) in
                        guard let view = interaction.view else {
                            return (.zero, 0)
                        }
                        return (CGSize(width: view.bounds.width + 24, height: view.bounds.height + 12), 16)
                    })
                )
            )
            settingButton.addLKInteraction(pointer)
        }
    }
}

extension FocusListFooterView {

    enum Cons {
        static var buttonFont: UIFont {
            UIFont.systemFont(ofSize: 14)
        }

        static var iconSize: CGSize {
            CGSize(width: 16, height: 16)
        }

        static var buttonIcon: UIImage {
            UDIcon.settingOutlined
        }

        static var buttonText: String {
            BundleI18n.LarkFocus.Lark_Profile_StatusSettings
        }

        static var spacing: CGFloat {
            4
        }

        static var buttonWidth: CGFloat {
            buttonText.getWidth(withConstrainedHeight: .infinity, font: buttonFont) + iconSize.width + spacing + 10
        }
    }
}
