//
//  TipView.swift
//  ByteView
//
//  Created by fakegourmet on 2022/3/18.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import UniverseDesignIcon
import UniverseDesignNotice
import ByteViewCommon

protocol TipViewDelegate: AnyObject {
    func tipViewDidClickLeadingButton(_ sender: UIButton, tipInfo: TipInfo)
    func tipViewDidClickClose(_ sender: UIButton, tipInfo: TipInfo)
    func tipViewDidTapLeadingButton(tipInfo: TipInfo)
    func tipViewDidTapLink(tipInfo: TipInfo)
}

final class TipView: UIView {

    private lazy var noticeConfig = UDNoticeUIConfig(type: .info, attributedText: NSAttributedString(string: "", attributes: [.font: UIFont.systemFont(ofSize: 14)]))
    private lazy var noticeView: UDNotice = {
        let noticeView = UDNotice(config: noticeConfig)
        noticeView.delegate = self
        return noticeView
    }()
    private(set) var tipInfo: TipInfo?
    weak var delegate: TipViewDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.alpha = 0.94
        addSubview(noticeView)
        noticeView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        InMeetOrientationToolComponent.isLandscapeModeRelay
            .subscribe(onNext: { [weak self] isLandscape in
                guard let self = self else {
                    return
                }
                self.noticeConfig.alignment = isLandscape ? .center : .left
                self.noticeView.updateConfigAndRefreshUI(self.noticeConfig)
            })
            .disposed(by: rx.disposeBag)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setBackgroundColor(_ color: UIColor?) {
        guard let color = color else { return }
        noticeConfig.backgroundColor = color
    }

    private func setImage(_ image: UIImage?) {
        noticeConfig.leadingIcon = image
    }

    private func setCanClose(_ canClose: Bool) {
        noticeConfig.trailingButtonIcon = canClose ? UDIcon.getIconByKey(.closeOutlined, iconColor: .ud.iconN2, size: CGSize(width: 16, height: 16)) : nil
    }

    private func setButtonTextByInfo(_ tipInfo: TipInfo) {
        switch tipInfo.type {
        case .autoRecordSettingJump:
            noticeConfig.leadingButtonText = I18n.View_G_ClickToEdit_RecordingSetting
        case .interviewerTipsAddDisappear:
            noticeConfig.leadingButtonText = I18n.View_MV_NamePhotoResumeOnly_NoMore
        case .callmePhone:
            noticeConfig.leadingButtonText = I18n.View_G_CancelButton
        case .largeMeeting:
            noticeConfig.leadingButtonText = I18n.View_MV_SettingsClick
        case .ccmExternalPermChange:
            noticeConfig.leadingButtonText = I18n.View_G_TurnOff
        default:
            noticeConfig.leadingButtonText = nil
        }
    }

    private func setContent(_ tipInfo: TipInfo) {
        var labelStyle: VCFontConfig = .bodyAssist
        labelStyle.lineHeight = 18
        labelStyle.lineHeightMultiple = 1.02
        let attributedText = NSMutableAttributedString(string: tipInfo.content, config: labelStyle)
        let fullRange = NSRange(location: 0, length: attributedText.length)
        attributedText.addAttributes([.foregroundColor: UIColor.ud.textTitle],
                                     range: fullRange)
        if let highLightRange = tipInfo.highLightRange,
            let range = fullRange.intersection(highLightRange) {
            attributedText.addAttributes([
                .foregroundColor: UIColor.ud.primaryContentDefault,
                .link: ""
            ], range: range)
        }
        if let digitRange = tipInfo.digitRange, let range = fullRange.intersection(digitRange) {
            attributedText.addAttributes([.font: UIFont.monospacedDigitSystemFont(ofSize: labelStyle.fontSize,
                                                                                  weight: labelStyle.fontWeight)],
                                         range: range)
        }
        noticeConfig.attributedText = attributedText
        if let alignment = tipInfo.alignment {
            noticeConfig.alignment = alignment
        }
    }

    func presentTipInfo(tipInfo: TipInfo, animated: Bool = true) {
        tipInfo.presentedTime = Date().timeIntervalSince1970
        self.tipInfo = tipInfo
        self.setContent(tipInfo)
        self.setImage(tipInfo.icon)
        self.setBackgroundColor(tipInfo.backgroundColor)
        self.setButtonTextByInfo(tipInfo)
        self.superview?.bringSubviewToFront(self)
        self.setCanClose(tipInfo.canClosedManually)
        self.noticeView.layer.cornerRadius = self.layer.cornerRadius
        self.noticeView.updateConfigAndRefreshUI(noticeConfig)

        self.isHidden = false
        if animated {
            self.alpha = 0.0
            self.transform = CGAffineTransform(translationX: 0.0, y: 36.0)
            // nolint-next-line: magic number
            UIView.animate(withDuration: 0.3, animations: {
                self.transform = .identity
                self.alpha = 0.94
            })
        }
    }

    func dismissTipView() {
        self.tipInfo = nil
        self.isHidden = true
    }
}

extension TipView: UDNoticeDelegate {
    func handleLeadingButtonEvent(_ button: UIButton) {
        guard let info = self.tipInfo else {
            return
        }
        delegate?.tipViewDidClickLeadingButton(button, tipInfo: info)
    }

    func handleTrailingButtonEvent(_ button: UIButton) {
        if let info = self.tipInfo {
            delegate?.tipViewDidClickClose(button, tipInfo: info)
        } else {
            dismissTipView()
        }
    }

    func handleTextButtonEvent(URL: URL, characterRange: NSRange) {
        if let info = self.tipInfo, info.highLightRange?.intersection(characterRange) == characterRange {
            delegate?.tipViewDidTapLink(tipInfo: info)
        }
    }
}
