//
//  SkinSettingController.swift
//  Calendar
//
//  Created by zhouyuan on 2019/1/23.
//  Copyright © 2019 EE. All rights reserved.
//

import Foundation
import CalendarFoundation
import UIKit
import UniverseDesignTheme
import UniverseDesignColor
import FigmaKit
import LarkUIKit

final class SkinSettingController: BaseUIViewController {
    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }

    private let containerView = UIView()
    private let lightSkinImageView = SkinTypeView(
        image: UIImage.cd.image(named: "new_setting_skin_light") & UIImage.cd.image(named: "new_setting_skin_light_dm"),
        title: BundleI18n.Calendar.Calendar_Settings_Modern
    )

    private let darkSkinImageView = SkinTypeView(
        image: UIImage.cd.image(named: "new_setting_skin_dark") & UIImage.cd.image(named: "new_setting_skin_dark_dm"),
        title: BundleI18n.Calendar.Calendar_Settings_Classic
    )

    private let skinType: CalendarSkinType
    private let selectCallBack: (CalendarSkinType) -> Void
    init(skinType: CalendarSkinType,
         selectCallBack: @escaping (CalendarSkinType) -> Void) {
        self.skinType = skinType
        self.selectCallBack = selectCallBack
        super.init(nibName: nil, bundle: nil)
        self.title = BundleI18n.Calendar.Calendar_NewSettings_EventColor
        view.backgroundColor = UIColor.ud.bgFloatBase
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.addBackItem()
        containerView.backgroundColor = UIColor.ud.bgFloat
        layoutContainerView(containerView)

        containerView.addSubview(lightSkinImageView)
        containerView.addSubview(darkSkinImageView)

        lightSkinImageView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(30)
            make.left.equalToSuperview().offset(24)
            make.width.equalTo(darkSkinImageView)
            make.right.equalTo(darkSkinImageView.snp.left).offset(-27)
            make.bottom.equalToSuperview().offset(-30)
        }
        lightSkinImageView.isSelected = (self.skinType == .light)

        darkSkinImageView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(30)
            make.right.equalToSuperview().offset(-24)
        }
        darkSkinImageView.isSelected = (self.skinType == .dark)

        lightSkinImageView.didSelected = { [weak self] in
            self?.darkSkinImageView.isSelected = false
            if self?.skinType != .light {
                self?.selectCallBack(.light)
            }
        }

        darkSkinImageView.didSelected = { [weak self] in
            self?.lightSkinImageView.isSelected = false
            if self?.skinType != .dark {
                self?.selectCallBack(.dark)
            }
        }
    }

    private func layoutContainerView(_ containerView: UIView) {
        view.addSubview(containerView)
        containerView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(16)
            make.top.equalToSuperview().offset(14)
        }
        containerView.layer.cornerRadius = 10
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class SkinTypeView: UIView {
    private let skinImageView = UIImageView()

    private let titleLabel: UILabelWithInset = {
        let label = UILabelWithInset(insets: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16))
        label.layer.cornerRadius = 16.0
        label.layer.borderWidth = 1.0
        label.textAlignment = .center
        label.font = UIFont.cd.mediumFont(ofSize: 14)
        label.layer.masksToBounds = true
        label.layer.ud.setBorderColor(UIColor.ud.primaryContentDefault)
        return label
    }()

    var isSelected: Bool = false {
        didSet {
            setSelected(isSelected: isSelected)
        }
    }

    private let image: UIImage
    private let skinImageViewMask = CAShapeLayer()

    var didSelected: (() -> Void)?

    init(image: UIImage, title: String) {
        self.image = image

        super.init(frame: .zero)
        layoutSkinImageView(skinImageView)
        skinImageView.layer.borderWidth = 1
        skinImageView.layer.cornerRadius = 4
        skinImageView.clipsToBounds = true
        setupTitleLabel(titleLabel, title: title, topView: skinImageView)

        setSelected(isSelected: false)
        addTapGesture()

        skinImageView.layer.addSublayer(skinImageViewMask)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        skinImageViewMask.frame = skinImageView.bounds
        skinImageViewMask.backgroundColor = UIColor.ud.fillImgMask.cgColor
    }

    private func layoutSkinImageView(_ imageView: UIImageView) {
        self.addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(imageView.snp.width).multipliedBy(183.0 / 150.0)
        }
    }

    private func setupTitleLabel(_ titleLabel: UILabel, title: String, topView: UIView) {
        titleLabel.text = title
        self.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.bottom.centerX.equalToSuperview()
            make.top.equalTo(topView.snp.bottom).offset(20)
            make.height.equalTo(32)
        }
    }

    private func addTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTaped))
        self.addGestureRecognizer(tapGesture)
    }

    @objc
    private func didTaped() {
        setSelected(isSelected: true)
        didSelected?()
    }

    private func setSelected(isSelected: Bool) {
        if !isSelected {
            titleLabel.textColor = UIColor.ud.primaryContentDefault
            titleLabel.backgroundColor = UIColor.ud.bgBody
            skinImageView.image = image
            skinImageView.ud.setLayerBorderColor(UIColor.clear)
        } else {
            titleLabel.textColor = UIColor.white
            titleLabel.backgroundColor = UIColor.ud.primaryContentDefault
            skinImageView.image = image
            skinImageView.ud.setLayerBorderColor(UDColor.primaryContentDefault)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
