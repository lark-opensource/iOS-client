//
//  MuteAllView.swift
//  ByteView
//
//  Created by Tobb Huang on 2020/11/4.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class MuteAllView: UIView {

    enum Style {
        case normal
        case more
        case reclaimHost
    }

    struct Layout {
        static let buttonTopOffset: CGFloat = 8.0
        static var buttonLeftOffset: CGFloat = 16.0
        static let buttonSpacing: CGFloat = 17.0
    }

    lazy var muteAllMicrophone: UIButton = {
        let button = UIButton()
        button.setTitle(I18n.View_M_MuteAll, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        button.titleLabel?.numberOfLines = 1
        button.titleLabel?.lineBreakMode = .byTruncatingTail
        button.titleLabel?.textAlignment = .center
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        button.layer.ud.setBorderColor(UIColor.ud.lineBorderComponent)
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 6
        button.layer.masksToBounds = true
        button.setTitleColor(UIColor.ud.textTitle, for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.udtokenComponentOutlinedBg, for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.udtokenBtnSeBgNeutralHover, for: .highlighted)
        button.addInteraction(type: .lift)
        button.addTarget(self, action: #selector(muteAllButtonAction(_:)), for: .touchUpInside)
        return button
    }()

    var tapMuteAllButton: (() -> Void)?

    lazy var unmuteAllMicrophone: UIButton = {
        let button = UIButton()
        button.setTitle(I18n.View_G_AskAllToUnmute_Button, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        button.titleLabel?.numberOfLines = 1
        button.titleLabel?.lineBreakMode = .byTruncatingTail
        button.titleLabel?.textAlignment = .center
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        button.layer.ud.setBorderColor(UIColor.ud.lineBorderComponent)
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 6
        button.layer.masksToBounds = true
        button.setTitleColor(UIColor.ud.textTitle, for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.udtokenComponentOutlinedBg, for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.udtokenBtnSeBgNeutralHover, for: .highlighted)
        button.addInteraction(type: .lift)
        button.addTarget(self, action: #selector(unMuteAllButtonAction(_:)), for: .touchUpInside)
        return button
    }()

    var tapUnMuteAllButton: (() -> Void)?

    lazy var more: UIButton = {
        let button = UIButton()
        button.setTitle(I18n.View_G_More, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        button.titleLabel?.numberOfLines = 1
        button.titleLabel?.lineBreakMode = .byTruncatingTail
        button.titleLabel?.textAlignment = .center
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        button.layer.ud.setBorderColor(UIColor.ud.lineBorderComponent)
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 6
        button.setTitleColor(UIColor.ud.textTitle, for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.udtokenComponentOutlinedBg, for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.udtokenBtnSeBgNeutralHover, for: .highlighted)
        button.addInteraction(type: .lift)
        button.addTarget(self, action: #selector(moreButtonAction(_:)), for: .touchUpInside)
        return button
    }()

    var tapMoreButton: (() -> Void)?

    lazy var reclaimHost: UIButton = {
        let button = UIButton()
        button.setTitle(I18n.View_M_ReclaimHost, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        button.titleLabel?.numberOfLines = 1
        button.titleLabel?.lineBreakMode = .byTruncatingTail
        button.titleLabel?.textAlignment = .center
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        button.layer.ud.setBorderColor(UIColor.ud.lineBorderComponent)
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 6
        button.setTitleColor(UIColor.ud.textTitle, for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.udtokenComponentOutlinedBg, for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.udtokenBtnSeBgNeutralHover, for: .highlighted)
        button.addInteraction(type: .lift)
        button.addTarget(self, action: #selector(reclaimHostButtonAction(_:)), for: .touchUpInside)
        return button
    }()

    var tapReclaimHostButton: (() -> Void)?

    var style: Style = .normal {
        didSet {
            styleDidChange()
        }
    }

    var buttonHeight: CGFloat {
        if isPhoneLandscape {
            return 44.0
        }
        return 48.0
    }

    init() {
        super.init(frame: .zero)
        setUpUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpUI() {
        backgroundColor = .clear
        addSubview(muteAllMicrophone)
        addSubview(unmuteAllMicrophone)
        addSubview(more)
        addSubview(reclaimHost)
        remakeButtonsLayout()
    }

    private func remakeButtonsLayout() {
        muteAllMicrophone.snp.remakeConstraints { (maker) in
            maker.top.equalToSuperview().offset(Layout.buttonTopOffset)
            maker.height.equalTo(buttonHeight)
            maker.left.equalTo(safeAreaLayoutGuide).offset(Layout.buttonLeftOffset)
        }
        unmuteAllMicrophone.snp.remakeConstraints { (maker) in
            maker.top.equalToSuperview().offset(Layout.buttonTopOffset)
            maker.height.equalTo(buttonHeight)
            maker.width.equalTo(self.muteAllMicrophone)
            maker.left.equalTo(muteAllMicrophone.snp.right).offset(Layout.buttonSpacing)
            maker.right.equalTo(safeAreaLayoutGuide).offset(-Layout.buttonLeftOffset)
        }
        more.snp.remakeConstraints { (maker) in
            maker.top.equalToSuperview().offset(Layout.buttonTopOffset)
            maker.height.equalTo(buttonHeight)
            maker.width.equalTo(self.muteAllMicrophone)
            maker.left.equalTo(muteAllMicrophone.snp.right).offset(Layout.buttonSpacing)
            maker.right.equalTo(safeAreaLayoutGuide).offset(-Layout.buttonLeftOffset)
        }
        reclaimHost.snp.remakeConstraints { (maker) in
            maker.top.equalToSuperview().offset(Layout.buttonTopOffset)
            maker.height.equalTo(buttonHeight)
            maker.left.right.equalTo(safeAreaLayoutGuide).inset(Layout.buttonLeftOffset)
        }
    }

    private func styleDidChange() {
        switch style {
        case .normal:
            muteAllMicrophone.isHidden = false
            unmuteAllMicrophone.isHidden = false
            more.isHidden = true
            reclaimHost.isHidden = true
        case .more:
            muteAllMicrophone.isHidden = false
            unmuteAllMicrophone.isHidden = true
            more.isHidden = false
            reclaimHost.isHidden = true
        case .reclaimHost:
            muteAllMicrophone.isHidden = true
            unmuteAllMicrophone.isHidden = true
            more.isHidden = true
            reclaimHost.isHidden = false
        }
    }

    @objc private func muteAllButtonAction(_ b: Any) {
        tapMuteAllButton?()
    }

    @objc private func unMuteAllButtonAction(_ b: Any) {
        tapUnMuteAllButton?()
    }

    @objc private func moreButtonAction(_ b: Any) {
        tapMoreButton?()
    }

    @objc private func reclaimHostButtonAction(_ b: Any) {
        tapReclaimHostButton?()
    }
}

extension MuteAllView {

    func updateLayoutWhenOrientationDidChange() {
        muteAllMicrophone.snp.updateConstraints { (maker) in
            maker.height.equalTo(buttonHeight)
        }
        unmuteAllMicrophone.snp.updateConstraints { (maker) in
            maker.height.equalTo(buttonHeight)
        }
        more.snp.updateConstraints { (maker) in
            maker.height.equalTo(buttonHeight)
        }
        reclaimHost.snp.updateConstraints { (maker) in
            maker.height.equalTo(buttonHeight)
        }
    }
}
