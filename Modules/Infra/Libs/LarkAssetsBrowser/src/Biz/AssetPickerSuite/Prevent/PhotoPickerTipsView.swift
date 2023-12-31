//
//  PhotoPickerTipsView.swift
//  LarkAssetsBrowser
//
//  Created by xiongmin on 2021/4/23.
//

import UIKit
import Foundation
import UniverseDesignColor

@objc protocol PhotoPickerTipsViewDelegate {
    func photoPickerTipsViewSettingButtonClick(_ tipsView: PhotoPickerTipsView)
}

final class PhotoPickerTipsView: UIView {

    weak var delegate: PhotoPickerTipsViewDelegate?

    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = Resources.tips_icon
        return imageView
    }()

    private lazy var tipsLabel: UILabel = {
        let label = UILabel.lu.labelWith(
            fontSize: 14,
            textColor: UIColor.ud.N900,
            text: BundleI18n.LarkAssetsBrowser.Lark_Chat_AllowAccessToAllPhotosPlease()
        )
        return label
    }()

    private lazy var goSettingButton: UIButton = {
        let button = UIButton()
        button.setTitle(BundleI18n.LarkAssetsBrowser.Lark_Chat_SettingsButton, for: .normal)
        button.setTitleColor(UIColor.ud.colorfulBlue, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.addTarget(self, action: #selector(goSetting), for: .touchUpInside)
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    init() {
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        backgroundColor = UIColor.ud.O100
        addSubview(iconImageView)
        addSubview(tipsLabel)
        addSubview(goSettingButton)
        iconImageView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.equalTo(16)
            make.height.equalTo(20)
        }
        goSettingButton.snp.makeConstraints { (make) in
            make.right.equalToSuperview()
            make.height.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.equalTo(74)
        }
        tipsLabel.snp.makeConstraints { (make) in
            make.left.equalTo(iconImageView.snp.right).offset(8)
            make.centerY.equalToSuperview()
            make.right.lessThanOrEqualTo(goSettingButton.snp.left).offset(-2)
        }
        tipsLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    @objc
    private func goSetting() {
        delegate?.photoPickerTipsViewSettingButtonClick(self)
    }
}
