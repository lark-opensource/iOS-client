//
//  InMeetSelfStartSharingScreenView.swift
//  ByteView
//
//  Created by Prontera on 2021/3/29.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import UIKit

class InMeetSelfStartSharingScreenView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private let shareScreenLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = UIColor.ud.textTitle
        label.attributedText = NSAttributedString(string: I18n.View_G_NotScreenSharingYet, config: .h2)
        label.textAlignment = .center
        return label
    }()

    private let shareScreenDetailLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = UIColor.ud.textCaption
        label.attributedText = NSAttributedString(string: I18n.View_G_NotScreenSharingYetInfo, config: .body)
        label.textAlignment = .center
        return label
    }()

    private let audioView = UIView()

    private let shareAudioLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = UIColor.ud.textTitle
        label.attributedText = NSAttributedString(string: I18n.View_VM_ShareDeviceAudio, config: .body)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()

    let switchView: UISwitch = {
        let aSwitch = UISwitch()
        aSwitch.onTintColor = UIColor.ud.primaryContentDefault
        aSwitch.isOn = true
        return aSwitch
    }()

    lazy var startSharingButton: UIButton = {
        let button = UIButton()
        button.contentEdgeInsets = UIEdgeInsets(top: 7.0, left: 16.0, bottom: 7.0, right: 16.0)
        let attributedString = NSAttributedString(string: I18n.View_G_StartSharing,
                                                  config: .body,
                                                  lineBreakMode: .byTruncatingTail,
                                                  textColor: UIColor.ud.primaryOnPrimaryFill)
        button.setAttributedTitle(attributedString, for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.primaryContentDefault, for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.primaryContentPressed, for: .highlighted)
        button.layer.cornerRadius = 6
        button.layer.masksToBounds = true
        button.addInteraction(type: .hover)
        return button
    }()

    private func setupViews() {
        addSubview(shareScreenLabel)
        addSubview(shareScreenDetailLabel)
        addSubview(audioView)
        audioView.addSubview(shareAudioLabel)
        audioView.addSubview(switchView)
        addSubview(startSharingButton)

        shareScreenLabel.snp.makeConstraints { (make) in
            make.centerX.top.equalToSuperview()
            make.left.right.equalToSuperview()
        }

        shareScreenDetailLabel.snp.makeConstraints { (make) in
            make.top.equalTo(shareScreenLabel.snp.bottom).offset(4)
            make.left.right.equalToSuperview()
            make.centerX.equalToSuperview()
        }

        audioView.snp.makeConstraints { (make) in
            make.left.greaterThanOrEqualToSuperview()
            make.right.lessThanOrEqualToSuperview()
            make.centerX.equalToSuperview()
            make.top.equalTo(shareScreenDetailLabel.snp.bottom).offset(32)
            make.height.equalTo(shareAudioLabel.snp.height).priority(.low)
            make.height.greaterThanOrEqualTo(switchView.snp.height)
        }

        shareAudioLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.centerY.equalToSuperview()
        }

        switchView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalTo(shareAudioLabel.snp.right).offset(12)
            make.right.equalToSuperview()
        }

        startSharingButton.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(audioView.snp.bottom).offset(36)
            make.bottom.equalToSuperview()
        }
    }
}
