//
//  InMeetSelfStopSharingScreenView.swift
//  ByteView
//
//  Created by Prontera on 2021/3/29.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import UIKit
import ByteViewCommon
import ByteViewUI

class InMeetSelfStopSharingScreenView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.updateStopShareButtonTopMargin()
    }

    private var stopShareButtonTopMargin: CGFloat = 56 {
        didSet {
            guard self.stopShareButtonTopMargin != oldValue else {
                return
            }
            updateStopShareButtonConstraints()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    let shareScreenLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    var isLandscapeMode: Bool = VCScene.isLandscape {
        didSet {
            guard self.isLandscapeMode != oldValue else {
                return
            }
            self.updateStopShareButtonTopMargin()
        }
    }

    var isWebinarStage: Bool = false {
        didSet {
            guard self.isWebinarStage != oldValue else {
                return
            }
            if self.isWebinarStage {
                self.shareScreenLabel.numberOfLines = 1
                self.audioView.label.numberOfLines = 1
                self.audioView.invalidateIntrinsicContentSize()
            } else {
                self.shareScreenLabel.numberOfLines = 0
                self.audioView.label.numberOfLines = 0
                self.audioView.invalidateIntrinsicContentSize()
            }
            self.updateStopShareButtonTopMargin()
        }
    }

    private let audioView = SelfSharingScreenAudioView()
    var switchView: UISwitch {
        audioView.widget
    }

    private func setupAudioView() {
        let label = self.audioView.label
        label.numberOfLines = 0
        label.textColor = UIColor.ud.textTitle
        label.attributedText = NSAttributedString(string: I18n.View_VM_ShareDeviceAudio, config: .body, lineBreakMode: .byTruncatingTail)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let aSwitch = self.audioView.widget
        aSwitch.onTintColor = UIColor.ud.primaryContentDefault
        aSwitch.isOn = true
    }

    lazy var stopSharingButton: UIButton = {
        let button = UIButton()
        button.contentEdgeInsets = UIEdgeInsets(top: 7.0, left: 16.0, bottom: 7.0, right: 16.0)
        button.vc.setBackgroundColor(UIColor.ud.colorfulRed, for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.R600, for: .highlighted)
        button.layer.cornerRadius = 6
        button.layer.masksToBounds = true
        button.addInteraction(type: .hover)
        return button
    }()


    private func setupViews() {
        addSubview(shareScreenLabel)
        addSubview(audioView)
        setupAudioView()

        addSubview(stopSharingButton)

        shareScreenLabel.snp.makeConstraints { (make) in
            make.centerX.top.equalToSuperview()
            make.left.right.equalToSuperview()
        }

        audioView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(12.0)
            make.centerX.equalToSuperview()
            make.top.equalTo(shareScreenLabel.snp.bottom).offset(20)
        }

        updateStopShareButtonTopMargin()
        updateStopShareButtonConstraints()
    }

    private func updateStopShareButtonConstraints() {
        stopSharingButton.snp.remakeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(audioView.snp.bottom).offset(stopShareButtonTopMargin)
            make.bottom.equalToSuperview()
        }
    }

    private func updateStopShareButtonTopMargin() {
        if isWebinarStage {
            if self.traitCollection.horizontalSizeClass == .regular {
                self.stopShareButtonTopMargin = 68
            } else {
                self.stopShareButtonTopMargin = 24
            }
        } else {
            self.stopShareButtonTopMargin = isLandscapeMode ? 36 : 56
        }
    }

    func updateWithOrientation(_ isLandscapeMode: Bool) {
        self.isLandscapeMode = isLandscapeMode
    }
}
