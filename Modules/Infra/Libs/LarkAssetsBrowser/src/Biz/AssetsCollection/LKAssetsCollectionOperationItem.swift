//
//  LKAssetsCollectionOperationItem.swift
//  LarkAssetsBrowser
//
//  Created by Hayden Wang on 2021/11/9.
//

import Foundation
import UIKit

final class LKAssetsCollectionOperationItem: UIView {

    private let tapHandler: () -> Void

    private lazy var button: UIButton = {
        let button = UIButton()
        button.layer.masksToBounds = true
        button.layer.ux.setSmoothCorner(radius: 12)
        button.setBackgroundImage(UIImage.ud.fromPureColor(UIColor.ud.bgFloat), for: .normal)
        button.setBackgroundImage(UIImage.ud.fromPureColor(UIColor.ud.bgFloat), for: .disabled)
        button.setBackgroundImage(UIImage.ud.fromPureColor(UIColor.ud.fillPressed), for: .highlighted)
        return button
    }()

    private lazy var label: UILabel = {
        let label = UILabel()
        label.font = UIFont.ud.caption3(.fixed)
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.textAlignment = .center
        return label
    }()

    init(icon: UIImage, title: String, tapHandler: @escaping () -> Void) {
        self.tapHandler = tapHandler
        super.init(frame: .zero)

        self.label.text = title
        let image = icon.ud.resized(to: CGSize(width: 24, height: 24))
        self.button.setImage(image.ud.withTintColor(UIColor.ud.iconN1), for: .normal)
        self.button.setImage(image.ud.withTintColor(UIColor.ud.iconDisabled), for: .disabled)
        self.button.addTarget(self, action: #selector(buttonDidTapped), for: .touchUpInside)

        self.addSubview(button)
        self.addSubview(label)

        button.snp.makeConstraints { make in
            make.width.height.equalTo(52)
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview()
        }
        label.snp.makeConstraints { make in
            make.centerX.equalTo(button)
            make.top.equalTo(button.snp.bottom).offset(2)
            make.height.greaterThanOrEqualTo(14)
            make.width.equalTo(80)
            make.bottom.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func buttonDidTapped() {
        tapHandler()
    }

    func setButtonEnable(_ enabled: Bool) {
        self.button.isEnabled = enabled
        self.label.textColor = enabled ? UIColor.ud.textCaption : UIColor.ud.textDisabled
    }
}
