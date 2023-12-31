//
//  SingleVideoNavigationBar.swift
//  ByteView
//
//  Created by kiri on 2020/11/8.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import UIKit
import UniverseDesignIcon
import ByteViewUI

class SingleVideoNavigationBar: UIView {

    private let contentView = UIView()

    private let backButtonImage: UIImageView = {
        let imageView = UIImageView(image: UDIcon.getIconByKey(.minimizeOutlined, iconColor: .ud.primaryOnPrimaryFill, size: CGSize(width: 20.0, height: 20.0)))
        imageView.ud.setLayerShadowColor(UIColor.ud.vcTokenVCShadowSm)
        imageView.layer.shadowOpacity = 1
        imageView.layer.shadowRadius = 1
        imageView.layer.shadowOffset = CGSize(width: 0, height: 1)
        return imageView
    }()

    private(set) lazy var backButton: UIButton = {
        var button = UIButton(type: .custom)
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        button.addInteraction(type: .hover)
        button.vc.setBackgroundColor(UIColor.ud.vcTokenMeetingBtnBgOnGray.withAlphaComponent(0.5), for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.vcTokenMeetingBtnBgOnGray.withAlphaComponent(0.7), for: .highlighted)
        return button
    }()

    private let cameraButtonImage: UIImageView = {
        let imageView = UIImageView(image: UDIcon.getIconByKey(.cameraFlipOutlined, iconColor: .ud.primaryOnPrimaryFill, size: CGSize(width: 20.0, height: 20.0)))
        imageView.ud.setLayerShadowColor(UIColor.ud.vcTokenVCShadowSm)
        imageView.layer.shadowOpacity = 1
        imageView.layer.shadowRadius = 1
        imageView.layer.shadowOffset = CGSize(width: 0, height: 1)
        return imageView
    }()

    private(set) lazy var cameraButton: UIButton = {
        var button = UIButton(type: .custom)
        button.isHidden = true
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        button.addInteraction(type: .hover)
        button.vc.setBackgroundColor(UIColor.ud.vcTokenMeetingBtnBgOnGray.withAlphaComponent(0.5), for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.vcTokenMeetingBtnBgOnGray.withAlphaComponent(0.7), for: .highlighted)
        return button
    }()

    lazy var moreButtonImage: UIImageView = {
        let imageView = UIImageView(image: UDIcon.getIconByKey(.moreBoldOutlined, iconColor: .ud.primaryOnPrimaryFill, size: CGSize(width: 20.0, height: 20.0)))
        imageView.ud.setLayerShadowColor(UIColor.ud.vcTokenVCShadowSm)
        imageView.layer.shadowOpacity = 1
        imageView.layer.shadowRadius = 1
        imageView.layer.shadowOffset = CGSize(width: 0, height: 1)
        return imageView
    }()

    lazy var moreButton: UIButton = {
        let button = UIButton(type: .custom)
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        button.addInteraction(type: .hover)
        button.vc.setBackgroundColor(UIColor.ud.vcTokenMeetingBtnBgOnGray.withAlphaComponent(0.5), for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.vcTokenMeetingBtnBgOnGray.withAlphaComponent(0.7), for: .highlighted)
        return button
    }()

    func makeLandscapeContraints() {
        backButton.snp.remakeConstraints { maker in
            if VCScene.safeAreaInsets.bottom == 0 {
                maker.left.equalToSuperview().offset(16.0)
            } else {
                maker.left.equalTo(safeAreaLayoutGuide)
            }
            maker.top.equalTo(self).offset(16.0)
            maker.size.equalTo(CGSize(width: 32.0, height: 32.0))
        }

        backButtonImage.snp.remakeConstraints { maker in
            maker.center.equalToSuperview()
            maker.size.equalTo(CGSize(width: 20.0, height: 20.0))
        }

        cameraButton.snp.remakeConstraints { (maker) in
            maker.centerY.equalTo(backButton)
            maker.left.equalTo(backButton.snp.right).offset(12.0)
            maker.size.equalTo(CGSize(width: 32.0, height: 32.0))
        }

        cameraButtonImage.snp.remakeConstraints { maker in
            maker.center.equalToSuperview()
            maker.size.equalTo(CGSize(width: 20.0, height: 20.0))
        }

        moreButton.snp.remakeConstraints { (maker) in
            if VCScene.safeAreaInsets.bottom == 0 {
                maker.right.equalToSuperview().inset(16.0)
            } else {
                maker.right.equalTo(safeAreaLayoutGuide)
            }
            maker.centerY.equalTo(backButton)
            maker.size.equalTo(CGSize(width: 32.0, height: 32.0))
        }
        moreButtonImage.snp.remakeConstraints { maker in
            maker.center.equalToSuperview()
            maker.size.equalTo(CGSize(width: 20.0, height: 20.0))
        }
    }

    func makePortraitContraints() {
        backButton.snp.remakeConstraints { (maker) in
            maker.left.equalToSuperview().offset(16.0)
            maker.centerY.equalToSuperview()
            maker.size.equalTo(CGSize(width: 32.0, height: 32.0))
        }

        backButtonImage.snp.remakeConstraints { maker in
            maker.center.equalToSuperview()
            maker.size.equalTo(CGSize(width: 20.0, height: 20.0))
        }

        cameraButton.snp.remakeConstraints { (maker) in
            maker.centerY.equalTo(backButton)
            maker.left.equalTo(backButton.snp.right).offset(12.0)
            maker.size.equalTo(CGSize(width: 32.0, height: 32.0))
        }

        cameraButtonImage.snp.remakeConstraints { maker in
            maker.center.equalToSuperview()
            maker.size.equalTo(CGSize(width: 20.0, height: 20.0))
        }

        moreButton.snp.remakeConstraints { (maker) in
            maker.right.equalToSuperview().offset(-16)
            maker.centerY.equalTo(backButton)
            maker.size.equalTo(CGSize(width: 32.0, height: 32.0))
        }
        moreButtonImage.snp.remakeConstraints { maker in
            maker.center.equalToSuperview()
            maker.size.equalTo(CGSize(width: 20.0, height: 20.0))
        }

    }

    var isLandscapeMode: Bool = false {
        didSet {
            guard isLandscapeMode != oldValue else {
                return
            }
            if isLandscapeMode {
                makeLandscapeContraints()
            } else {
                makePortraitContraints()
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(contentView)
        contentView.snp.makeConstraints { (maker) in
            maker.left.right.bottom.equalToSuperview()
            maker.top.equalTo(safeAreaLayoutGuide)
            maker.height.equalTo(64)
        }

        contentView.addSubview(backButton)
        contentView.addSubview(cameraButton)
        contentView.addSubview(moreButton)
        backButton.addSubview(backButtonImage)
        cameraButton.addSubview(cameraButtonImage)
        moreButton.addSubview(moreButtonImage)
        if isLandscapeMode {
            makeLandscapeContraints()
        } else {
            makePortraitContraints()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        isLandscapeMode = isPhoneLandscape
    }

    func resetSafeAreaLayoutGuide(_ layout: UILayoutGuide) {
        contentView.snp.remakeConstraints { (maker) in
            maker.left.right.bottom.equalToSuperview()
            maker.top.equalTo(layout)
            maker.height.equalTo(64)
        }
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        return (view == self || view == contentView) ? nil : view
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
