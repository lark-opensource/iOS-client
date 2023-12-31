//
//  DockHeaderView.swift
//  LarkSuspendable
//
//  Created by Hayden on 2021/5/31.
//

import Foundation
import UIKit
import UniverseDesignColor
import UniverseDesignIcon

final class DockHeaderView: UIView {

    private lazy var container = UIView()

    lazy var label: UILabel = {
        let label = UILabel()
        label.font = UIFont.ud.title4
        label.text = BundleI18n.LarkSuspendable.Lark_Floating_FloatingTitle
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    private lazy var clearButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = Cons.buttonFont
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        button.setTitle(BundleI18n.LarkSuspendable.Lark_Floating_Clear, for: .normal)
        return button
    }()

    lazy var confirmClearButton: UIButton = {
        let button = UIButton()
        let font = Cons.buttonFont
        let iconSize = CGSize(width: font.pointSize, height: font.pointSize)
        let icon = UDIcon.getIconByKey(.closeOutlined, iconColor: UIColor.ud.primaryContentDefault, size: iconSize)
        let spacing: CGFloat = 4
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: spacing, bottom: 0, right: -spacing)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: spacing)
        button.titleLabel?.font = Cons.buttonFont
        button.titleLabel?.lineBreakMode = .byTruncatingTail
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.setImage(icon, for: .normal)
        button.setTitle(BundleI18n.LarkSuspendable.Lark_Floating_ConfirmClear, for: .normal)
        button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(container)
        container.addSubview(label)
        container.addSubview(clearButton)
        container.addSubview(confirmClearButton)
        container.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-20)
            make.leading.equalTo(safeAreaLayoutGuide).offset(Cons.hMargin)
            make.trailing.equalTo(safeAreaLayoutGuide).offset(-Cons.hMargin).priority(.high)
        }
        label.snp.makeConstraints { make in
            make.height.equalTo(UIFont.ud.title4.figmaHeight)
            make.leading.top.bottom.equalToSuperview()
            make.trailing.lessThanOrEqualTo(clearButton.snp.leading)
        }
        clearButton.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
        }
        confirmClearButton.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
        }
        confirmClearButton.alpha = 0
        clearButton.addTarget(self, action: #selector(didTapClearButton(_:)), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func showConfirmButton() {
        UIView.animateKeyframes(withDuration: 0.5, delay: 0, options: .calculationModeLinear) {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.4) {
                self.clearButton.alpha = 0
            }
            UIView.addKeyframe(withRelativeStartTime: 0.6, relativeDuration: 0.4) {
                self.confirmClearButton.alpha = 1
            }
        }
    }

    @objc
    private func didTapClearButton(_ sender: UIButton) {
        showConfirmButton()
    }
}

final class DockSectionHeaderView: UIView {

    lazy var label: UILabel = {
        let label = UILabel()
        label.font = UIFont.ud.body2
        label.textColor = UIColor.ud.N600 & UIColor.ud.N800
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(label)
        label.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.height.equalTo(UIFont.ud.body2.figmaHeight)
            make.leading.equalTo(safeAreaLayoutGuide).offset(Cons.hMargin)
            make.trailing.equalTo(safeAreaLayoutGuide).offset(-Cons.hMargin)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private enum Cons {
    static var hMargin: CGFloat { 16 }
    static var buttonFont: UIFont { UIFont.ud.body0 }
}
