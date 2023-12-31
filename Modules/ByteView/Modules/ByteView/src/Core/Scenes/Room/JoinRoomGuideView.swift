//
//  JoinRoomGuideView.swift
//  ByteView
//
//  Created by kiri on 2023/7/24.
//

import Foundation
import ByteViewUI
import UniverseDesignColor

final class JoinRoomGuideView: UIView {
    var systemAudioAction: (() -> Void)?

    private let contentView = UIView()
    private let hintLabel = UILabel()
    private lazy var systemAudioButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(I18n.View_G_UseDeviceAudio_Button_PhoneAndPad, for: .normal)
        button.setTitleColor(.ud.textTitle, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14)
        button.vc.setBackgroundColor(UIColor.ud.bgFloat, for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.udtokenBtnSeBgNeutralPressed, for: .highlighted)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        button.layer.ud.setBorderColor(UIColor.ud.lineBorderComponent)
        button.addInteraction(type: .lift)
        button.layer.cornerRadius = 6.0
        button.layer.borderWidth = 1.0
        button.layer.masksToBounds = true
        button.addTarget(self, action: #selector(didClickSystemAudio(_:)), for: .touchUpInside)
        return button
    }()

    private lazy var sureButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(I18n.View_G_GotItButton, for: .normal)
        button.setTitleColor(.ud.primaryOnPrimaryFill, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14)
        button.vc.setBackgroundColor(UIColor.ud.primaryContentDefault, for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.primaryContentPressed, for: .highlighted)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        button.addInteraction(type: .lift)
        button.layer.cornerRadius = 6.0
        button.layer.masksToBounds = true
        button.addTarget(self, action: #selector(didClickSure(_:)), for: .touchUpInside)
        return button
    }()

    private lazy var arrowView: TriangleView = {
        let view = TriangleView()
        view.direction = .top
        view.backgroundColor = UIColor.clear
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        self.backgroundColor = .clear
        contentView.backgroundColor = .ud.bgFloat
        arrowView.color = .ud.bgFloat
        contentView.layer.cornerRadius = 8
        contentView.layer.ud.setShadow(type: .s4Down)

        addSubview(contentView)
        addSubview(arrowView)

        contentView.addSubview(hintLabel)
        contentView.addSubview(systemAudioButton)
        contentView.addSubview(sureButton)

        hintLabel.numberOfLines = 0
        hintLabel.preferredMaxLayoutWidth = 248
        hintLabel.attributedText = NSAttributedString(string: I18n.View_G_DeviceAudioDisconnectedToAvoidEcho_Description, config: .hAssist, textColor: .ud.textTitle)
        let hintHeight = hintLabel.sizeThatFits(CGSize(width: hintLabel.preferredMaxLayoutWidth, height: .greatestFiniteMagnitude)).height
        hintLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(20)
            make.top.equalToSuperview().inset(18)
            make.size.equalTo(CGSize(width: 248, height: hintHeight))
        }

        systemAudioButton.snp.makeConstraints { make in
            make.left.greaterThanOrEqualTo(hintLabel)
            make.top.equalTo(hintLabel.snp.bottom).offset(20)
            make.height.equalTo(28)
            make.bottom.equalToSuperview().inset(20)
        }

        sureButton.snp.makeConstraints { make in
            make.left.equalTo(systemAudioButton.snp.right).offset(12)
            make.top.height.equalTo(systemAudioButton)
            make.right.equalTo(hintLabel)
        }

        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapBackground(_:))))
    }

    @objc private func didClickSystemAudio(_ sender: Any?) {
        self.dismiss(animated: true, completion: self.systemAudioAction)
    }

    @objc private func didClickSure(_ sender: Any?) {
        self.dismiss(animated: true)
    }

    @objc private func didTapBackground(_ gr: UITapGestureRecognizer) {
        self.dismiss(animated: true)
    }

    private var rootParentView: UIView? {
        var v = self.superview
        while v?.superview != nil {
            v = v?.superview
        }
        return v
    }

    /// 默认self大小等于superview
    func show(animated: Bool, anchor: UIView, completion: (() -> Void)? = nil) {
        guard let root = self.rootParentView, anchor.isDescendant(of: root) else { return }
        let margin: CGFloat = 8
        let anchorFrame = anchor.convert(anchor.bounds, to: self)
        let isLeft = anchorFrame.midX <= self.bounds.midX
        self.contentView.snp.remakeConstraints { make in
            make.centerX.equalTo(arrowView).priority(.low)
            make.left.greaterThanOrEqualToSuperview().offset(margin)
            make.right.lessThanOrEqualToSuperview().offset(-8)
            make.bottom.equalTo(arrowView.snp.top)
        }

        self.arrowView.snp.remakeConstraints { make in
            make.size.equalTo(CGSize(width: 24, height: 10))
            make.centerX.equalTo(anchor)
            make.bottom.equalTo(anchor.snp.top).offset(-3)
        }

        arrowView.setNeedsDisplay()
        self.layoutIfNeeded()
        self.isHidden = false
        if animated {
            // nolint-next-line: magic number
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: { [weak self] in
                self?.alpha = 1.0
            })
        } else {
            self.alpha = 1.0
        }
    }

    func dismiss(animated: Bool, completion: (() -> Void)? = nil) {
        if self.isHidden { return }
        if animated {
            // nolint-next-line: magic number
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: { [weak self] in
                self?.alpha = 0
            }, completion: { [weak self] _ in
                self?.isHidden = true
                completion?()
            })
        } else {
            self.alpha = 0
            self.isHidden = true
            completion?()
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 12, *), traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
            arrowView.setNeedsDisplay()
        }
    }
}
