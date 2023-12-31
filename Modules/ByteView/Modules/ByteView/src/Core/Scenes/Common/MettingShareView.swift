//
//  MettingShareView.swift
//  ByteView
//
//  Created by wlwy on 2020/8/3.
//

import UIKit
import RxSwift
import RxCocoa

class MeetingShareView: UIView {

    struct Layout {
        static let cornerRadius: CGFloat = 4
        static let imageTitlePadding: CGFloat = 12
    }

    var buttonPadding: CGFloat {
        12
    }

    var shouldFixHeight: Bool = false

    init() {
        super.init(frame: .zero)
        setUpUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    let copyMeetingInfoButton: VisualButton = {
        let button = VisualButton(type: .custom)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.setTitle(I18n.View_M_CopyJoiningInfo, for: .normal)
        button.setTitleColor(UIColor.ud.textTitle, for: .normal)
        button.titleLabel?.numberOfLines = 1
        button.setTitleColor(UIColor.ud.textTitle, for: .highlighted)
        button.setTitleColor(UIColor.ud.textTitle.withAlphaComponent(0.3), for: .disabled)
        button.setBGColor(UIColor.ud.udtokenComponentOutlinedBg, for: .normal)
        button.setBGColor(UIColor.ud.udtokenBtnSeBgNeutralHover, for: .highlighted)
        button.titleLabel?.lineBreakMode = .byTruncatingTail
        button.clipsToBounds = true
        button.titleEdgeInsets = UIEdgeInsets(top: 7,
                                              left: 16,
                                              bottom: 7,
                                              right: 16)
        button.layer.borderWidth = 1
        button.layer.cornerRadius = Layout.cornerRadius
        button.setBorderColor(UIColor.ud.lineBorderComponent, for: .normal)
        button.setBorderColor(UIColor.ud.lineBorderComponent, for: .highlighted)
        return button
    }()

    let shareButton: VisualButton = {
        let button = VisualButton(type: .custom)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.setTitle(I18n.View_M_ShareToChat, for: .normal)
        button.titleLabel?.numberOfLines = 1
        button.setTitleColor(UIColor.ud.textTitle, for: .normal)
        button.setTitleColor(UIColor.ud.textTitle, for: .highlighted)
        button.setTitleColor(UIColor.ud.textTitle.withAlphaComponent(0.3), for: .disabled)
        button.setBGColor(UIColor.ud.udtokenComponentOutlinedBg, for: .normal)
        button.setBGColor(UIColor.ud.udtokenBtnSeBgNeutralHover, for: .highlighted)
        button.titleLabel?.lineBreakMode = .byTruncatingTail
        button.clipsToBounds = true
        button.titleEdgeInsets = UIEdgeInsets(top: 7,
                                              left: 16,
                                              bottom: 7,
                                              right: 16)
        button.layer.borderWidth = 1
        button.layer.cornerRadius = Layout.cornerRadius
        button.setBorderColor(UIColor.ud.lineBorderComponent, for: .normal)
        button.setBorderColor(UIColor.ud.lineBorderComponent, for: .highlighted)
        return button
    }()

    private func setUpUI() {
        backgroundColor = .clear
        addSubview(copyMeetingInfoButton)
        addSubview(shareButton)
        makeButtonsConstraints()
    }

    func update(shareCardEnabled: Bool, isHorizontal: Bool = true) {
        shareButton.isHidden = !shareCardEnabled

        if shareCardEnabled {
            if shouldFixHeight || isHorizontal {
                copyMeetingInfoButton.snp.remakeConstraints { (make) in
                    make.right.equalTo(shareButton.snp.left).offset(-buttonPadding)
                    make.left.top.bottom.equalToSuperview()
                    make.width.equalTo(shareButton)
                    make.centerY.equalToSuperview()
                }
                shareButton.snp.remakeConstraints { (make) in
                    make.right.top.bottom.equalToSuperview()
                    make.centerY.equalToSuperview()
                }
            } else {
                copyMeetingInfoButton.snp.remakeConstraints { make in
                    make.right.left.top.equalToSuperview()
                    make.height.equalTo(36)
                }
                shareButton.snp.remakeConstraints { make in
                    make.left.right.bottom.equalToSuperview()
                    make.top.equalTo(copyMeetingInfoButton.snp.bottom).offset(buttonPadding)
                    make.height.equalTo(36)
                }
            }
        } else {
            copyMeetingInfoButton.snp.remakeConstraints { (make) in
                make.left.top.bottom.right.equalToSuperview()
                make.width.equalTo(shareButton)
                make.centerY.equalToSuperview()
            }
            shareButton.snp.removeConstraints()
        }
    }

    private func makeButtonsConstraints() {
        copyMeetingInfoButton.snp.remakeConstraints { (make) in
            make.right.equalTo(shareButton.snp.left).offset(-buttonPadding)
            make.left.top.bottom.equalToSuperview()
            make.width.equalTo(shareButton)
            make.centerY.equalToSuperview()
        }
        shareButton.snp.remakeConstraints { (make) in
            make.right.top.bottom.equalToSuperview()
            make.centerY.equalToSuperview()
        }
    }
}
